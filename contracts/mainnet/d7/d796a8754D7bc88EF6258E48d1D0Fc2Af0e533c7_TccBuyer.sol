/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol






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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol





// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol





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

// File: contracts/ITccERC721.sol





interface ITccERC721  {

    function totalSupply() external view returns(uint256);

    function tokenCount() external view returns(uint256);

    function createCollectible(uint256 _number, address to) external;
}

// File: contracts/TccBuyer.sol









contract TccBuyer is Ownable {

    using SafeMath for uint256;
    using ECDSA for bytes32;

    address public noreERC721Address;
    address public efnERC721Address;
    address public drinkChampsERC721Address;

    ITccERC721 private _noreContract;
    ITccERC721 private _efnContract;
    ITccERC721 private _drinkChampsContract;
    mapping (address => uint256) public amountCollected;
    mapping (address => bool) public airdropped;

    bool public saleOn = false;

    uint256 public price = 5 * 10 ** 16; // 0.05 ETH
    uint256 private nonce;
    uint256 public maxAirdrop = 30;
    uint256 public airdropCount = 0;
    uint256 public buyCount = 0;

    ITccERC721[] availableContracts;
    enum Collection{NORE, EFN, DRINKCHAMPS}

    event WithdrawnToOwner(address _operator, uint256 _ethWei);
    event WithdrawnToEntities(address _operator, uint256 _ethWei);
    event SaleChanged(bool _saleIsOn);
    event NftBought(address indexed _from, uint256 _quantity);
    event NftAirdropped(address indexed _from, uint256 _quantity);

        //    Distribution  amount * rate / 1000
        uint256 private CELEBRITY_RATE = 400;
        uint256 private MAIN_RATE = 315;
        uint256 private TEAM_RATE = 235;
        uint256 private PARTNER_RATE = 50;

        address payable public noreCelebrityAddress = payable(0x6d4FBA93638175e476D24a364b51687C7D12e4CE);
        address payable public efnCelebrityAddress = payable(0xA706D17E412298b0d363B63285cCe5108517Fea1);
        address payable public drinkChampsCelebrityAddress = payable(0x6d4FBA93638175e476D24a364b51687C7D12e4CE);

        address payable public mainAddress = payable(0xd6d4d7FAf57f22830d978f793d033d115E605962);
        address payable public teamAddress = payable(0x07D409e34786467F335fF8b7A69e300Effe7E2cf);
        address payable public partnerAddress = payable(0x6d4FBA93638175e476D24a364b51687C7D12e4CE);


    constructor(
        address _noreERC721Address,
        address _efnERC721Address,
        address _drinkChampsERC721Address
    ) {
        noreERC721Address = _noreERC721Address;
        efnERC721Address = _efnERC721Address;
        drinkChampsERC721Address = _drinkChampsERC721Address;

        _noreContract = ITccERC721(noreERC721Address);
        _efnContract = ITccERC721(efnERC721Address);
        _drinkChampsContract = ITccERC721(drinkChampsERC721Address);

        availableContracts.push(_noreContract);
        availableContracts.push(_efnContract);
        availableContracts.push(_drinkChampsContract);
    }

    // Modifiers
    modifier saleIsOn() {
        require(saleOn, "cannot purchase as the sale is off");
        _;
    }

    modifier isClaimedAuthorized(uint256 quantity, bytes memory signature) {
        require(verifySignature(quantity, signature) == owner(), "caller not authorized to get airdrop");
        _;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        require(newPrice > 0, 'TccBuyer: price must be > 0');
        price = newPrice;
    }

    function setAirdropSupply(uint256 newMaxAirdrop) public onlyOwner {
        require(newMaxAirdrop >= 0, 'TccBuyer: newAirdropSupply must be >= 0');
        maxAirdrop = newMaxAirdrop;
    }

    function activateSale() public onlyOwner {
        saleOn = true;
        emit SaleChanged(saleOn);
    }

    function deactivateSale() public onlyOwner {
        saleOn = false;
        emit SaleChanged(saleOn);
    }

    function setPaymentRecipients(
        address _noreCelebrityAddress,
        address _efnCelebrityAddress,
        address _drinkChampsCelebrityAddress,
        address _mainAddress,
        address _teamAddress,
        address _partnerAddress
    ) external onlyOwner {
        noreCelebrityAddress = payable(_noreCelebrityAddress);
        efnCelebrityAddress = payable(_efnCelebrityAddress);
        drinkChampsCelebrityAddress = payable(_drinkChampsCelebrityAddress);
        mainAddress = payable(_mainAddress);
        teamAddress = payable(_teamAddress);
        partnerAddress = payable(_partnerAddress);

    }

    function buyToken(uint256 quantity) external payable saleIsOn {
        require(msg.value == price * quantity, "TccBuyer: not the right amount of ETH sent");
        require(checkIfAvailableToMint(quantity + (maxAirdrop - airdropCount)), "the quantity exceed the supply");
        randomMint(quantity, true);
        buyCount += quantity;
        emit NftBought(_msgSender(), quantity);
    }

    function claimAirdrop(uint256 quantity, bytes memory signature) external saleIsOn isClaimedAuthorized(quantity, signature) {
        require(!airdropped[msg.sender], "caller already got airdropped");
        require((quantity + airdropCount) <= maxAirdrop, "quantity requested the exceed max airdrop");
        randomMint(quantity, false);
        airdropped[msg.sender] = true;
        airdropCount += quantity;
        emit NftAirdropped(_msgSender(), quantity);
    }

    function checkIfAirdropped(address airDropAddress) public view returns(bool) {
        return airdropped[airDropAddress];
    }

    function randomMint(uint256 quantity, bool bought) internal {
        require(checkIfAvailableToMint(quantity), "the quantity exceed the supply");
        for(uint i = 0; i < quantity; i++) {
            setAvailableContracts();
            require(availableContracts.length > 0, "can't mint in any contracts");
            ITccERC721 stage2ERC721 = availableContracts[randomNumber()];
            stage2ERC721.createCollectible(1, _msgSender());
            if(bought) {
                amountCollected[address(stage2ERC721)] += price;
            }
            nonce++;
        }
    }

    function verifySignature(uint256 quantity, bytes memory signature) internal view returns(address) {
        return keccak256(abi.encodePacked(address(this), msg.sender, quantity))
        .toEthSignedMessageHash()
        .recover(signature);
    }

    function withdrawToOwner() external onlyOwner {
        uint256 _amount = address(this).balance;
        require(_amount > 0, "No ETH to Withdraw");
        payable(_msgSender()).transfer(_amount);

        emit WithdrawnToOwner(_msgSender(), _amount);
    }

    function checkIfAvailableToMint(uint256 quantity) public view returns(bool) {
        uint _totalMinted;
        uint _maxSupply;
        for (uint i = 0; i < availableContracts.length; i++) {
            _totalMinted += availableContracts[i].tokenCount();
            _maxSupply += availableContracts[i].totalSupply();
        }
        return _totalMinted + quantity <= _maxSupply;
    }

    function setAvailableContracts() internal {
        for (uint i = 0; i < availableContracts.length; i++) {
            if(availableContracts[i].tokenCount() + 1 > availableContracts[i].totalSupply()) {
                availableContracts[i] = availableContracts[availableContracts.length - 1];
                availableContracts.pop();
            }
        }
    }

    function randomNumber() internal view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, nonce))) % availableContracts.length);
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function tokenCount() external view returns (uint) {
        return _noreContract.tokenCount() + _efnContract.tokenCount() + _drinkChampsContract.tokenCount();
    }

    function totalSupply() external view returns (uint) {
        return _noreContract.totalSupply() + _efnContract.totalSupply() + _drinkChampsContract.totalSupply();
    }

    function withdrawToEntities() external onlyOwner {
        if(address(this).balance > 0) {
            multiSend();
        }
    }

    function multiSend() internal {

        uint256 noreContractBalance = amountCollected[noreERC721Address];
        uint256 efnContractBalance = amountCollected[efnERC721Address];
        uint256 drinkChampsContractBalance = amountCollected[drinkChampsERC721Address];
        uint256 totalBalance = address(this).balance;

        require(totalBalance == noreContractBalance + efnContractBalance + drinkChampsContractBalance, "problem in total amount to distribute");

        uint256 _noreCelebrityBalance = 0;
        uint256 _efnCelebrityBalance = 0;
        uint256 _drinkChampsCelebrityBalance = 0;
        uint256 _mainBalance = 0;
        uint256 _teamBalance = 0;
        uint256 _partnerBalance = 0;

        if(noreContractBalance > 0) {
            _noreCelebrityBalance += noreContractBalance.mul(CELEBRITY_RATE).div(1000);

            _mainBalance += noreContractBalance.mul(MAIN_RATE).div(1000);
            _teamBalance += noreContractBalance.mul(TEAM_RATE).div(1000);
            _partnerBalance += noreContractBalance.mul(PARTNER_RATE).div(1000);
        }

        if(efnContractBalance > 0) {
            _efnCelebrityBalance += efnContractBalance.mul(CELEBRITY_RATE).div(1000);

            _mainBalance += efnContractBalance.mul(MAIN_RATE).div(1000);
            _teamBalance += efnContractBalance.mul(TEAM_RATE).div(1000);
            _partnerBalance += efnContractBalance.mul(PARTNER_RATE).div(1000);
        }

        if(drinkChampsContractBalance > 0) {
            _drinkChampsCelebrityBalance += drinkChampsContractBalance.mul(CELEBRITY_RATE).div(1000);

            _mainBalance += drinkChampsContractBalance.mul(MAIN_RATE).div(1000);
            _teamBalance += drinkChampsContractBalance.mul(TEAM_RATE).div(1000);
            _partnerBalance += drinkChampsContractBalance.mul(PARTNER_RATE).div(1000);
        }

        transferToAddressETH(noreCelebrityAddress, _noreCelebrityBalance);
        transferToAddressETH(efnCelebrityAddress, _efnCelebrityBalance);
        transferToAddressETH(drinkChampsCelebrityAddress, _drinkChampsCelebrityBalance);
        transferToAddressETH(mainAddress, _mainBalance);
        transferToAddressETH(teamAddress, _teamBalance);
        transferToAddressETH(partnerAddress, _partnerBalance);

        amountCollected[noreERC721Address] -= noreContractBalance;
        amountCollected[efnERC721Address] -= efnContractBalance;
        amountCollected[drinkChampsERC721Address] -= drinkChampsContractBalance;

        emit WithdrawnToEntities(_msgSender(), totalBalance);
    }
}