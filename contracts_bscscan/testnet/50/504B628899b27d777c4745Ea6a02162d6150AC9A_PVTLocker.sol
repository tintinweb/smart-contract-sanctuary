// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PVTLocker is Ownable {
    using ECDSA for bytes32;

    struct Lock {
        uint256 totalLocked;
        uint256 reservedAmount;
        uint256 startTimestamp;
        uint256 endTimestamp;
        address lockOwner;
        uint256 dropCount;
    }

    // lockerOwner => lockedTokenAddresses
    mapping(address => address[]) public tokensByLockOwner;
    mapping(address => mapping(address => bool)) addressWithdrawn;

    address whitelistSigner;
    address public feeReceiver;
    uint256 public lockFee;
    //          token   => locked
    mapping(address => bool) public tokenLocked;
    //          token address  => Lock struct
    mapping(address => Lock) public locks;

    modifier onlyLockOwner(address _token) {
        require(msg.sender == locks[_token].lockOwner, "Only lock owner!");
        _;
    }

    constructor() {}

    function lockedPercent(address token) public view returns(uint256) {
        uint256 locked = IERC20(token).balanceOf(address(this));
        uint256 totalSupply = IERC20(token).totalSupply();
        return locked * 10000 / totalSupply;
    }

    function setFeeReceiver(address newAddress) public onlyOwner {
        emit FeeReceiverUpdate(feeReceiver, newAddress);
        feeReceiver = newAddress;
    }

    function setLockFee(uint256 bnbAmount) public onlyOwner {
        emit FeeUpdate(lockFee, bnbAmount);
        lockFee = bnbAmount;
    }

    function createLock(address _token, uint256 _amount, uint256 _startTimestamp, uint256 _endTimestamp) public payable {
        require(msg.value >= lockFee, "Sender value is not enough");
        require(!tokenLocked[_token], "Token is already in locking");
        require(locks[_token].lockOwner == address(0), "Lock already created");
        if (_startTimestamp < block.timestamp) {
            _startTimestamp = block.timestamp;
        }
        require(_startTimestamp < _endTimestamp, "End time should be greater than start time");
        uint256 transferredAmount = _addTokensToLock(_token, _amount);
        locks[_token] = Lock(transferredAmount, 0, _startTimestamp, _endTimestamp, msg.sender, 0);
        tokenLocked[_token] = true;
        // todo проверить норм ли так пушить
        tokensByLockOwner[msg.sender].push(_token);
        emit LockCreated(_token, transferredAmount, _startTimestamp, _endTimestamp);
    }

    function addTokensToLock(address _token, uint256 _amount) public {
        require(_amount > 0, "Zero amount provided");
        uint256 transferredAmount = _addTokensToLock(_token, _amount);
        locks[_token].totalLocked += transferredAmount;
        emit TokensAdded(_token, transferredAmount);
    }

    function _addTokensToLock(address _token, uint256 _amount) internal returns(uint256) {
        uint256 tokenBalanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        return IERC20(_token).balanceOf(address(this)) - tokenBalanceBefore;
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }


    function withdraw(address _token, uint256 _amount, bytes memory _signature) external {
        (bool success, string memory reason) = canWithdraw(msg.sender, _token, _amount, _signature);
        require(success, reason);
        _withdraw(_token, _amount, msg.sender);
    }

    function canWithdraw(address _address, address _token, uint256 _amount, bytes memory _signature) public view returns (bool, string memory) {
        if (locks[_token].startTimestamp > block.timestamp || locks[_token].endTimestamp < block.timestamp) {
            return (false, "Claim not started or ended");
        }
        if (addressWithdrawn[_token][_address]) {
            return (false, "Already withdrawn");
        }
        bytes32 hash = keccak256(abi.encodePacked(whitelistSigner, _address, _token, _amount));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(_signature);
        if (signer != whitelistSigner) {
            return (false, "Invalid signature");
        }

        return (true, "");
    }

    function _withdraw(address _token, uint256 _amount, address _account) private {
        locks[_token].reservedAmount -= _amount;
        addressWithdrawn[_token][_account] = true;
        try IERC20(_token).transfer(_account, _amount) {} catch {}
        emit Withdrawn(_token, _account, _amount);
    }

    function drop(
        address _token,
        address[] calldata _accounts,
        uint256[] calldata _amounts,
        bytes memory _accountsHash,
        bytes memory _amountsHash,
        bytes memory _signature
    ) public onlyLockOwner(_token) {
        require(_accounts.length == _amounts.length, "Different lengths");
        bytes32 hash = keccak256(abi.encodePacked(whitelistSigner, _token, _accountsHash, _amountsHash));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        address signer = messageHash.recover(_signature);
        require(signer != whitelistSigner, "Invalid signature");
        address account;
        for(uint256 i = 0; i < _accounts.length; i++) {
            account = _accounts[i];
            locks[_token].dropCount ++;
            if (!addressWithdrawn[_token][account]) {
                _withdraw(_token, _amounts[i], account);
            }
        }
    }

    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        require(!tokenLocked[_token], "Token is already in locking");
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    function withdrawRestTokens(address _token, uint256 _amount) public onlyOwner {
        require(locks[_token].endTimestamp < block.timestamp, "Token in claim stage");
        if (_amount > locks[_token].reservedAmount || _amount == 0) {
            _amount = locks[_token].reservedAmount;
        }
        locks[_token].reservedAmount -= _amount;
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    function withdrawRestLockTokens(address _token, uint256 _amount) public onlyLockOwner(_token) {
        require(locks[_token].endTimestamp < block.timestamp, "Token in claim stage");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 claimable = balance - locks[_token].reservedAmount;
        if (_amount > claimable || _amount == 0) {
            _amount = claimable;
        }
        IERC20(_token).transfer(address(msg.sender), _amount);
    }

    function withdrawBnb(uint256 amount) external onlyOwner {
        (bool sent,) = feeReceiver.call{value: amount}("");
        require(sent, 'Error on withdraw BNB from contract');
    }

    //  events
    event LockCreated(address token, uint256 amount, uint256 startTimestamp, uint256 endTimestamp);
    event Withdrawn(address token, address receipent, uint256 amount);
    event TokensAdded(address token, uint256 amount);
    event FeeReceiverUpdate(address oldAddress, address newAddress);
    event FeeUpdate(uint256 oldFee, uint256 newFee);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}