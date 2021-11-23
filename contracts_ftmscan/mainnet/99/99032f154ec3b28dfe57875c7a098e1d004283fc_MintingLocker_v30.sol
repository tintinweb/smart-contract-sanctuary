//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./AbstractLocker_v30.sol";

interface IERC20MintBurnUpgradeable is IERC20Upgradeable {
    function burnFrom(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external returns (bool);
}

contract MintingLocker_v30 is AbstractLocker_v30 {

    function initialize(
        uint256 _chainGuid,
        address _token,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) public initializer {
        __MintingLocker_init(_chainGuid, _token, _oracleAddress, _feeAddress, _feeBP);
    }

    function __MintingLocker_init(
        uint256 _chainGuid,
        address _token,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AbstractLocker_init_unchained(_chainGuid, _token, _oracleAddress, _feeAddress, _feeBP);
        __MintingLocker_init_unchained();
    }

    function __MintingLocker_init_unchained(
    ) internal initializer {
    }

    function _receiveTokens(
        address _fromAddress,
        uint256 _amount
    ) virtual internal override {
        // burn tokens
        IERC20MintBurnUpgradeable(lockerToken).burnFrom(_fromAddress, _amount);
    }

    function _sendTokens(
        address _toAddress,
        uint256 _amount
    ) virtual internal override {
        // mint tokens
        IERC20MintBurnUpgradeable(lockerToken).mint(_toAddress, _amount);
    }

    function _sendFees(
        uint256 _feeAmount
    ) virtual internal override {
        _sendTokens(feeAddress, _feeAmount);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Decimals {
    function decimals() external returns (uint8);
}

abstract contract AbstractLocker_v30 is Initializable, OwnableUpgradeable {
    string constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
    bytes32 constant EIP712_DOMAIN_TYPEHASH=keccak256(abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    ));
    bytes32 private constant BRIDGE_WITHDRAW_TYPEHASH=keccak256(abi.encodePacked(
        "BridgeWithdraw(uint256 claimId,uint256 targetChainGuid,address targetLockerAddress,address targetAddress,uint256 amount,uint256 deadline)"
    ));
    bytes32 private constant BRIDGE_REFUND_TYPEHASH=keccak256(abi.encodePacked(
        "BridgeRefund(uint256 claimId,uint256 sourceChainGuid,address sourceLockerAddress,address sourceAddress,uint256 amount)"
    ));
    bytes32 private constant LIQUIDITY_WITHDRAW_TYPEHASH=keccak256(abi.encodePacked(
        "LiquidityWithdraw(uint256 claimId,uint256 targetChainGuid,address targetLockerAddress,address targetAddress,uint256 amount,uint256 deadline,bool bypassFee)"
    ));
    bytes32 private ORACLE_DOMAIN_SEPARATOR;
    uint256 public chainGuid;
    uint256 public evmChainId;
    address public lockerToken;
    address public feeAddress;
    uint16 public feeBP;
    bool public maintenanceMode;
    mapping(address => bool) public oracles;
    mapping(uint256 => bool) public claims;
    uint8 public tokenDecimals;

    event BridgeDeposit(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event BridgeWithdraw(address indexed sender, address indexed targetAddress,  uint256 amount);
    event BridgeRefund(address indexed sender, address indexed sourceAddress, uint256 amount);

    event LiquidityAdd(address indexed sender, address indexed to, uint256 amount);
    event LiquidityRemove(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event LiquidityWithdraw(address indexed sender, uint256 indexed targetChainGuid, address targetLockerAddress, address indexed targetAddress, uint256 amount);
    event LiquidityRefund(address indexed sender, address indexed sourceAddress, uint256 amount);

    function __AbstractLocker_init(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __AbstractLocker_init_unchained(_chainGuid, _lockerToken, _oracleAddress, _feeAddress, _feeBP);
    }

    function __AbstractLocker_init_unchained(
        uint256 _chainGuid,
        address _lockerToken,
        address _oracleAddress,
        address _feeAddress,
        uint16 _feeBP
    ) internal initializer {
        require(_feeBP <= 10000, "initialize: invalid fee");

        uint256 _evmChainId;
        assembly {
            _evmChainId := chainid()
        }
        chainGuid = _chainGuid;
        evmChainId = _evmChainId;
        lockerToken = _lockerToken;
        feeAddress = _feeAddress;
        feeBP = _feeBP;
        maintenanceMode = false;
        oracles[_oracleAddress] = true;

        bytes32 _ORACLE_DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("BAG Locker Oracle"),
            keccak256("2"),
            _evmChainId,
            address(this)
        ));
        ORACLE_DOMAIN_SEPARATOR = _ORACLE_DOMAIN_SEPARATOR;

        setupTokenDecimals();
    }

    modifier live {
        require(!maintenanceMode, "locker: maintenance mode");
        _;
    }

    function setupTokenDecimals() public virtual onlyOwner {
        tokenDecimals = IERC20Decimals(lockerToken).decimals();
    }

    // Update fee address
    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: not authorized");
        feeAddress = _feeAddress;
    }

    // Update fee bps
    function setFeeBP(uint16 _feeBP) external onlyOwner {
        require(_feeBP <= 10000, "setFeeBP: invalid fee");
        feeBP = _feeBP;
    }

    // Update oracle address
    function addOracleAddress(address _oracleAddress) external onlyOwner {
        oracles[_oracleAddress] = true;
    }

    function removeOracleAddress(address _oracleAddress) external onlyOwner {
        oracles[_oracleAddress] = false;
    }

    // Update maintenance mode
    function setMaintenanceMode(bool _maintenanceMode) external onlyOwner {
        maintenanceMode = _maintenanceMode;
    }

    // Check if the claim has been processed and return current block time and number
    function isClaimed(uint256 _claimId) external view returns (bool, uint256, uint256) {
        return (claims[_claimId], block.timestamp, block.number);
    }

    // Deposit funds to locker from transfer to another chain
    function bridgeDeposit(
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline
    ) external live {
        // Checks
        require(_targetChainGuid != chainGuid || _targetLockerAddress != address(this), 'bridgeDeposit: same locker');
        require(_amount > 0, 'bridgeDeposit: zero amount');
        require(_deadline >= block.timestamp, 'bridgeDeposit: invalid deadline');

        // Effects

        // Interaction
        _receiveTokens(msg.sender, _amount);

        emit BridgeDeposit(msg.sender, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount);
    }

    // Withdraw tokens on a new chain with a valid claim from the oracle
    function bridgeWithdraw(
        uint256 _claimId,
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require(chainGuid == _targetChainGuid, 'bridgeWithdraw: wrong chain');
        require(address(this) == _targetLockerAddress, 'bridgeWithdraw: wrong locker');
        require(_deadline >= block.timestamp, 'bridgeWithdraw: claim expired');
        require(claims[_claimId] == false, 'bridgeWithdraw: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'bridgeWithdraw: bad decimals');

        uint256 feeAmount = _amount * feeBP / 10000;
        uint256 netAmount = _amount - feeAmount;

        // values must cover all non-signature arguments to the external function call
        bytes32 values = keccak256(abi.encode(
            BRIDGE_WITHDRAW_TYPEHASH,
            _claimId, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount, _deadline
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        if (feeAmount > 0) {
            _sendFees(feeAmount);
        }
        _sendTokens(_targetAddress, netAmount);

        emit BridgeWithdraw(msg.sender, _targetAddress, _amount);
    }

    // Refund tokens on the original chain with a valid claim from the oracle
    function bridgeRefund(
        uint256 _claimId,
        uint256 _sourceChainGuid,
        address _sourceLockerAddress,
        address _sourceAddress,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require((chainGuid == _sourceChainGuid) && (address(this) == _sourceLockerAddress), 'bridgeRefund: wrong chain');
        require(claims[_claimId] == false, 'bridgeRefund: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'bridgeRefund: bad decimals');

        // values must cover all non-signature arguments to the external function call
        bytes32 values = keccak256(abi.encode(
            BRIDGE_REFUND_TYPEHASH,
            _claimId, _sourceChainGuid, _sourceLockerAddress, _sourceAddress, _amount
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        _sendTokens(_sourceAddress, _amount);

        emit BridgeRefund(msg.sender, _sourceAddress, _amount);
    }


    // Withdraw tokens on a new chain with a valid claim from the oracle
    function liquidityWithdraw(
        uint256 _claimId,
        uint256 _targetChainGuid,
        address _targetLockerAddress,
        address _targetAddress,
        uint256 _amount,
        uint256 _deadline,
        bool _bypassFee,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // Checks
        require(chainGuid == _targetChainGuid, 'liquidityWithdraw: wrong chain');
        require(address(this) == _targetLockerAddress, 'liquidityWithdraw: wrong locker');
        require(_deadline >= block.timestamp, 'liquidityWithdraw: claim expired');
        require(claims[_claimId] == false, 'liquidityWithdraw: claim used');
        require(IERC20Decimals(lockerToken).decimals() == tokenDecimals, 'liquidityWithdraw: bad decimals');

        // values must cover all non-signature arguments to the publexternalic function call
        bytes32 values = keccak256(abi.encode(
            LIQUIDITY_WITHDRAW_TYPEHASH,
            _claimId, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount, _deadline, _bypassFee
        ));
        _verify(values, _v, _r, _s);

        // Effects
        claims[_claimId] = true;

        // Interactions
        uint256 feeAmount = _bypassFee ? 0 : _amount * feeBP / 10000;
        uint256 netAmount = _amount - feeAmount;
        if (feeAmount > 0) {
            _sendFees(feeAmount);
        }
        _sendTokens(_targetAddress, netAmount);

        emit LiquidityWithdraw(msg.sender, _targetChainGuid, _targetLockerAddress, _targetAddress, _amount);
    }

    // Verifies that the claim signature is from a trusted source
    function _verify(
        bytes32 _values,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked(
            EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
            ORACLE_DOMAIN_SEPARATOR,
            _values
        ));
        address recoveredAddress = ECDSAUpgradeable.recover(digest, _v, _r, _s);
        require(oracles[recoveredAddress], 'verify: tampered sig');
    }

    function _receiveTokens(
        address _fromAddress,
        uint256 _amount
    ) virtual internal;

    function _sendTokens(
        address _toAddress,
        uint256 _amount
    ) virtual internal;

    function _sendFees(
        uint256 _feeAmount
    ) virtual internal;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}