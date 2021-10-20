/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


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


library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


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

    // /**@dev Sets new lock and lock token balance of 'amount'
    //         checks if the hash of information provided by user matches what is in storage.
    //         @param password - Must not be an empty string
    //         @param randAddress - A random address or public key that the user can always have access to {NOTE: Not private key}
    //         @param nonce - Arbitrary number that must be greater than 0.
    //                         @notice Users are adviced to use unique parameters
    //         ///NOTE User should endeavor to safekeep these parameter to remember them, otherwise the token will be 
    //         locked for eternity.
    // */
    // function setAndLockToken(
    //     string memory password, 
    //     address randAddress, 
    //     uint nonce) external returns(bool);


    /**@dev Creates a fresh lock for user if they have none and executes transfer otherwise
            checks if the hash of information provided by user matches what is in storage.
            @param to - Address to recieve token
            @param amount - Amount to send.
            @param pwd - Must not be an empty string
            @param randAddress - A random address or public key that the user can always have access to {NOTE: Not private key}
            @param nonce - Arbitrary number that must be greater than 0.
                            @notice Users are adviced to use unique parameters
    */
    function safeSignedTransfer(
        address to, 
        uint amount, 
        string memory pwd, 
        address randAddress, 
        uint nonce) external returns(bool);


    /** @dev Moves token of an 'amount' to the locked
    */
    function lockBalance(uint amount) external returns(bool);


    /**@dev Moves 'amount' to regular balance
        @param amount - Amount to send.
        @param pwd - Must not be an empty string
        @param randAddress - A random address or public key that the user can always have access to {NOTE: Not private key}
        @param nonce - Arbitrary number that must be greater than 0.
                        @notice Users are adviced to use unique parameters
     */
    function unlockBalance(
        uint amount,
        string memory pwd, 
        address randAddress, 
        uint nonce) external returns(bool);


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

    ///@dev structured data for holding user's balance
    struct Holders {
        uint locker;
        uint regular;
        bytes32 pass;
        uint hodl;
    }

}



interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    constructor () {}

    function _activateEIP712(string memory name, string memory version) internal virtual {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
}


library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


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
abstract contract Once {
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
    modifier once() {
        require(_initializing || !_initialized, "Init: Already initialized");

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



library Encoder {
    function toBytes(string memory _literal) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal);
    }
    //solhint-disable-next-line
    function toBytes_Addr(string memory _literal, address arg) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg);
    }

    //solhint-disable-next-line
    function toBytes_Addr1_Uint1(string memory _literal, address arg1, uint arg2) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg1,arg2);
    }

    //solhint-disable-next-line
    function toBytes_Addr1_Uint2(string memory _literal, address arg1, uint arg2, uint arg3) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg1,arg2,arg3);
    }

    //solhint-disable-next-line
    function toBytes_Addr2_Uint1(string memory _literal, address arg1, address arg2, uint arg3) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg1,arg2,arg3);
    }
    
    //solhint-disable-next-line
    function toBytes_Addr2(string memory _literal, address arg1, address arg2) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg1,arg2);
    }

    //solhint-disable-next-line
    function toBytes_AddrUintBytes32(string memory _literal, address arg1, uint arg2, bytes32 arg3) internal pure returns(bytes memory) {
        return abi.encodeWithSignature(_literal,arg1,arg2,arg3);
    }
}

library Decoder {
    function toUint256(bytes memory data) internal pure returns(uint256) {
        return abi.decode(data, (uint256));
    }

    function toUint8(bytes memory data) internal pure returns(uint8) {
        return abi.decode(data, (uint8));
    }

    function toBool(bytes memory data) internal pure returns(bool) {
        return abi.decode(data, (bool));
    }

    function toAddress(bytes memory data) internal pure returns(address) {
        return abi.decode(data, (address));
    }

}

library Verifier {
    using Decoder for bytes;
    
    function verifyTrue(bytes memory data) internal pure returns(bool) {
        require(data.toBool(), "Call failed");
        return true;
    }

    function verifyUintGT(bytes memory a, uint256 b) internal pure returns(uint256) {
        uint256 c = a.toUint256();
        require(c > b, "Source errored");
        return c;
    }

    function verifyUint8GT(bytes memory a, uint8 b) internal pure returns(uint8) {
        uint8 c = a.toUint8();
        require(c > b, "Invalid");
        return c;
    }

    function verifyUintGEq(bytes memory a, uint256 b) internal pure returns(uint256) {
        uint256 c = a.toUint256();
        require(c >= b, "Not correspond");
        return c;
    }

    function notZero(address target) internal pure {
        require(target != zero(), "address: zero");
    }

    function notZeros(address a, address b) internal pure {
        require(a != zero() && b != zero(), "address: zero");
    }


    function zero() internal pure returns(address) {
        return address(0);
    }

    function isZero(address target) internal pure returns(bool) {
        return target == zero();
    }

    function isTrue(bool _type) internal pure {
        require(_type, "False");
    }

    function notTrue(bool _type) internal pure {
        require(!_type, "True");
    }

    function isGThan(uint a, uint b) internal pure {
        require(a > b,"Not greater than");
    }

    function isGTLessThan(uint a, uint b, uint c) internal pure {
        require(a > b && a < c,"Invalid arg");
    }

    function isGOrEqual(uint a, uint b) internal pure {
        require(a >= b,"Not greater or equal");
    }

    function isGaL(uint a, uint b, uint c) internal pure {
        require(a >= b && a <= c, "Invalid amount");
    }

    function ifGThan(uint a, uint b) internal pure returns(bool) {
        return a > b;
    }

    function ifGThanOrEqual(uint a, uint b) internal pure returns(bool) {
        return a >= b;
    }

    function equateAddr(address a, address b, string memory errorMessage) internal pure {
        require(a == b, errorMessage);
    }
}




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Regular {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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



abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    constructor() {
         _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}



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
abstract contract OwnableNoUpgrade is Pausable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        require(owner() == _msgSender(), "Ownable: not the owner");
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
        require(newOwner != address(0), "Ownable: zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}




/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardNoUpgrade {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


abstract contract ERC20NoUpg is IERC20Metadata, Context {
    using SafeMath for uint256;

    uint256 private iterator;//balance iterator: differentiator for balances internally
    uint256 private _totalSupply;//Total supply at any given time. Changes with respect to stakings

    mapping(uint256=>uint256) private _balances; // Houses user's balances
    mapping(address=>Holders) private holders; //Mapping of all holders
    mapping(address=>mapping(address=>uint256)) private _allowances; //Allowances mapping


    string private _name; ///@notice ERC20 Token Name
    string private _symbol; ///@notice ERC20 Token symbol
    bool[2] private boolVars; //Initializer

    ///@dev CheckMates balances before and after
    modifier checkAndBalance(address sender, address to, uint amount) {
        require( sender != address(0) && to != address(0), "ERC20: zero address");
        (uint bSenderNL,) = _getBalances(sender);
        require(bSenderNL >= amount, "ERC20: Amount exceeds balance");
        uint bTo = balanceOf(to);
        _;
        (uint aSender,) = _getBalances(sender);
        uint aTo = balanceOf(to);
        require(aSender == bSenderNL.sub(amount) && aTo > bTo, "Anomally");
    }

    constructor (address sale) {
        _allowances[address(this)][sale] = 1;
        boolVars[0] = false; 
        boolVars[1] = false;
    }


    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory _nam) {
        _nam = _name;
        return _nam;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory _sym) {
        _sym = _symbol;
        return _sym;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256 _ts) {
        _ts = _totalSupply;
        return _ts;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns(uint bal) {
        (uint regular, uint locked) = _getBalances(account);
        unchecked {
            bal = regular + locked;
        }
        return bal;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, 0);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address _owner, address spender) public view override returns(uint256 _allow) {
        _allow = _allowances[_owner][spender];
        return _allow;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``"s tokens of at least
     * `amount`.
     * If called by the farmer, it signifies staking.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount,
        address expected) internal virtual returns(bool) {
            _stake(_msgSender(), sender, expected, recipient, amount);
            uint256 curAllow = _allowances[sender][_msgSender()];
            require(curAllow >= amount, "ERC20: Amt exceeds allowance");
            _approve(sender, _msgSender(), curAllow.sub(amount));

            return true;
    }

    /**@dev Mechanism for staking. Callable only by the farmer.
        The Quatre staking model demands that the totalSupply reacts in downward direction 
        each time some amount of token is staked. For this reason, to keep track of the total amount
        staked, it can ve viewed from the allowance of the Farmer to the source contract i.e 
        _allowance[caller][address(this)] 
        @param caller - Actual person calling, in this case should be the owner or coordinated account
        @param expected - Expected caller.
        @param recipient - Account that gave approval
        @param amount - Amount to stake
     */
    function _stake(
        address caller,
        address sender,
        address expected, 
        address recipient, 
        uint amount) private {
            if(caller == expected && recipient == expected) {
                _transfer(sender, recipient, amount, 1);
                _adjustSupply(amount, 0);
                (uint _iter,) = _getIterLocker(recipient);
                unchecked {
                    _balances[_iter] -= amount;
                    _allowances[caller][address(this)] += amount;
                }
            } else {
                _transfer(sender, recipient, amount, 0);
            }
    }

    /**@dev User approves to spend directly from their account.
        param (not optional) - data: Additional data from the user.
     */
    function _approveAndStake(
        address caller, 
        address staker, 
        uint amount, 
        bytes32 lock) internal virtual {
            _unlockBalance(staker, amount, lock, caller);
            _stake(caller, staker, caller, caller, amount);
    }

    /**@dev Unstake token from the pool. Forwards reward along with the principal.
        When this is called, token in 'amount' is removed from anonymous state and every necessary 
        books are updated.
        Will be restricted in the inheriting contract.
        @param caller - Message sender as at call time.
        @param dest - Account to unstake and sent reward.
        @param amount - Actual stake amount.
        @param reward - Reward for staking.
     */
    function _unstake(address caller, address dest, uint256 amount, uint256 reward) internal virtual returns(uint8) {
        uint bal = allowance(caller, address(this));
        uint _amount = amount.add(reward);
        uint balOfSender = balanceOf(caller);
        require(balOfSender > reward, "Sender: low bal");
        _adjustSupply(_amount, 1);
        _allowances[caller][address(this)] = bal.sub(amount);
        (uint iter,) = _getIterLocker(caller);
        unchecked {
            _balances[iter] += amount;
        }
        _transfer(caller, dest, _amount, 0);

        return 1;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _beforeTokenTransfer(_msgSender(), spender, addedValue);
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subVal`.
     */
    function decreaseAllowance(address spender, uint256 subVal) public returns (bool) {
        _beforeTokenTransfer(_msgSender(), spender, subVal);
        uint256 curAllow = _allowances[_msgSender()][spender];
        require(curAllow >= subVal, "Decreased allowance below zero");
        _approve(_msgSender(), spender, curAllow.sub(subVal));

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * We did a few twist here: This is a generic ERC20 transfer, to keep with the 
     * standard, balance of sender is deducted from the normal iterated balance
     * but we check if recipient has lock in force, preference is given to the extra 
     * secure layer.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint8 cmd) internal virtual checkAndBalance(sender, recipient, amount) {
            _beforeTokenTransfer(sender, recipient, amount);
            (uint regSender,) = _getIterLocker(sender); 
            (uint _iterRec, uint _lockerRec) = _getIterLocker(recipient);
            (uint senBalNL,) = _getBalances(sender);
            require(senBalNL >= amount, "ERC20: Amount exceeds balance");
            _balances[regSender] = senBalNL.sub(amount);
            if(cmd == 0) {
                if(holders[recipient].locker == 0) {
                    unchecked {
                        _balances[_iterRec] += amount;
                    }
                } else {
                    unchecked {
                        _balances[_lockerRec] += amount;
                    }
                }
            } else {
                unchecked {
                    _balances[_iterRec] += amount;
                }
            }
            emit Transfer(sender, recipient, amount);

    }

    /**@dev Checks if user has lock set already otherwise
        reserve a spot for them
    */
    function _ifhasNoLock(address user, bytes32 _lock) private {
        if(holders[user].locker == 0) {
            holders[user].pass = _lock;
            (uint _iter,) = _getIterLocker(user);
            uint _locker = _iterate(user, 1);
            (uint reg, uint locked) = _getBalances(user);
            _balances[_iter] = 0;
            _balances[_locker] = locked.add(reg);
        }
    }

    /**@dev Securely transfer token to recipient "to".
        NOTE: Contrary to the generic method "transfer", an additional parameter "lock" is require
        which is a hash of the user's password and one other. See the inheriting contract.
     */
    function _safeSignedTransfer(address from, address to, uint amount, bytes32 lock, address _farm) internal virtual returns(bool) {
        _ifhasNoLock(from, lock);
        _safelyMove(from, amount, to, lock, _farm);
        return true;
    }

    ///@dev Swap the balances. We run a few test to ensure that user have the full
    // benefit of making use of this tool.
    function _safelyMove(address from, uint amount, address to, bytes32 lock, address _farm) private {
        _unlockBalance(from, amount, lock, _farm);
        _transfer(from, to, amount, 0);
        holders[from].hodl = block.timestamp;
    }

    ///See IERC20.unlockBalance
    function _unlockBalance(address user, uint amount, bytes32 lock, address _farm) internal virtual {
        (uint reg, uint locker) = _getIterLocker(user);
        bytes32 pass = holders[user].pass;
        uint locked = _balances[locker];
        require(lock == pass, "Invalid signature");
        require(amount <= type(uint256).max && locked >= amount, "Invalid entry or low bal"); //Prevents arbitrary entry.
        _screenForFantip(user, _farm, boolVars[1]);
        unchecked {
            _balances[locker] = locked - amount;
            _balances[reg] += amount;
        }
    }

    ///See IERC20.lockBalance
    function _lockBalance(address user, uint amount) internal virtual {
        (uint reg, uint locker) = _getIterLocker(user);
        uint regular = _balances[reg];
        require(locker > 0, "No lock set");
        require(amount <= type(uint256).max && regular >= amount, "Invalid entry"); //Prevents arbitrary entry.
        holders[user].hodl = block.timestamp;
        unchecked {
            _balances[reg] = regular - amount;
            _balances[locker] += amount;
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * @notice _mints simply transfers from the owners' unlocked balance to 
     *   recipient "to"s balance.
     */
    function _mint(address sender, address to, uint256 amount) internal virtual {
        require(to != address(0), "ERC20: mint zero address?");
        _beforeTokenTransfer(sender, to, amount);
        _adjustSupply(amount, 1);
        _transfer(sender, to, amount, 0);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `recipient` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(account, address(0), amount);
        require(account != address(0), "ERC20: zero address");
        (uint _iter,) = _getIterLocker(account);
        uint256 accountBalance = _balances[_iter];
        require(accountBalance >= amount, "ERC20: Low bal");

        unchecked {
            _balances[_iter] = accountBalance - amount;
        }
        emit Transfer(account, address(0), amount);
        _adjustSupply(amount, 0);

    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `_owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `_owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) internal {
        require(_owner != address(0) && spender != address(0), "ERC20: zero address");
        _beforeTokenTransfer(_owner, spender, amount);
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``"s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``"s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    /**@dev Adjusts supply with an 'amount' based on the command 'cmd'.
        @param amount - Total Supply adjustable with 'amount'.
        @param cmd - '0' command reduces the totalSupply
        @param cmd - 'any' (uint8) increases the totalSupply
     */
    function _adjustSupply(uint amount, uint8 cmd) private {
        uint tSupply = _totalSupply;
        if(cmd == 0) {
            require(tSupply >= amount, "Amt greater than supply");
            _totalSupply = tSupply.sub(amount);
        } else {
            _totalSupply = tSupply.add(amount);
        }
 
    }

    /**@dev We decide to initialize using this method to give us more
        flexibility in preparing and avoid some mistakes.
         Will be restricted to onlyOwner in the child contract.
         Token metadata are in pause mode until activated.
         @param _supply - Initial supply amount (Equivalent to the maximum supply in the contract's lifetime).
         @param nam - Shorthand for name.
         @param symbl - Shorthand for symbol.
         @param _farmerUpg - Farmer contract address

         Emits and event on activation
         @return uint8 - 1 indicated success.
     */
    function _activate(
        uint _supply,
        string memory nam,
        string memory symbl,
        address _farmerUpg) internal virtual returns(uint8){
            require(!boolVars[0], "already initialized");
            boolVars[0] = true;
            _supply = uint(_supply).mul(10**18);
            emit Transfer(address(0), _farmerUpg, _supply);
            (uint _iter,) = _getIterLocker(_farmerUpg);
            _balances[_iter] = _supply;
            _name = nam;
            _symbol = symbl;
            return 1;
    }

    /**@dev Creates a balance placeholder for _msgSender() in the balances list.
        @param cmd - Command: changes execution flow.
     */
    function _iterate(address user, uint8 cmd) internal returns(uint _iter) {
        uint _initIter = iterator;
        iterator = _initIter + 1;
        _iter = iterator;
        if(cmd == 0) {
            holders[user].regular = _iter;
        } else {
            holders[user].locker = _iter;
        }
       
        return _iter;
    }

    /**@dev if user has no spot already, we reserve a spot for them
            otherwise, we get the already reserved spot.
    */
    function _getIterLocker(address user) internal returns(
        uint _iter, 
        uint _locker) {
            if(holders[user].regular == 0) {
                _iter = _iterate(user, 0);
            } else {
                _iter = holders[user].regular;
            }
            _locker = holders[user].locker;
            return (_iter, _locker);
    }

    ///@dev Returns the balances tracker
    function getIterator() public view returns(uint256 _iter) {
        _iter = iterator;
        return _iter;
    }

    ///@dev Returns both regular and locked balances
    function _getBalances(address account) internal virtual view returns(uint, uint) {
        uint _iter = holders[account].regular;
        uint _locker =  holders[account].locker;
        uint _regular = _balances[_iter];
        uint _locked = _balances[_locker];
        return (_regular, _locked);
    }

    function _screenForFantip(address _fan, address _farm, bool active) internal virtual {
        uint _hodl = holders[_fan].hodl;
        (,uint locked) = _getBalances(_fan);
        if(active) {
            if(_hodl > 0) {
                if(block.timestamp >= _hodl.add(30 days)) {
                    uint tip;
                    holders[_fan].hodl = 0;
                    unchecked {
                        uint _tipRate = ((1.0e18 * 10000) / 100.0e18) * 10**18;
                        tip = ((_tipRate * locked) / 10**18) / 10000;
                    }
                    _transfer(_farm, _fan, tip, 0);
                    _adjustSupply(tip, 1);
                } else {
                    holders[_fan].hodl = 0;
                }
            }
        }
    }

    function _toggleFanTip(uint8 cmd) internal virtual {
        boolVars[1] = cmd == 0 ? true : false;
    }

}




abstract contract ERC20Permit is ERC20NoUpg, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

   constructor (address sale) ERC20NoUpg(sale) {
        _PERMIT_TYPEHASH = keccak256("Permit(address _owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address _owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, _owner, spender, value, _useNonce(_owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == _owner, "ERC20Permit: invalid signature");

        _approve(_owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address _owner) public view virtual override returns (uint256) {
        return _nonces[_owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address _owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[_owner];
        current = nonce.current();
        nonce.increment();
    }
}



abstract contract ERC20Votes is ERC20Permit {

    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    //solhint-disable-next-line
    constructor(address sale) ERC20Permit(sale) {}

    //solhint-disable-next-line
    receive() external payable {}


    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        //solhint-disable-next-line
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        return _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address sender, address to, uint256 amount) internal virtual override {
        super._mint(sender, to, amount);
        require(totalSupply() <= _maxSupply(), "ERC20:tsupply overflows votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

}



contract QfourToken is Once, OwnableNoUpgrade, ERC20Votes {
    modifier checkParams(string memory pwd, address randAddress, uint nonce) {
        require(bytes(pwd).length > 0, "Not acceptable passowrd");
        require(randAddress != address(0), "Error: Zero address");
        require(nonce > 0, "Zero nonce");
        _;
    }

    constructor(address sale)  ERC20Votes(sale) {}

    ///@dev See ERC20Upg _activate()
    function activate(
        uint96 _supply,
        string memory nam,
        string memory symbl,
        address _farmerUpg) public onlyOwner returns(uint8) {
            _activateEIP712(nam, "1");
            _activate(_supply, nam, symbl, _farmerUpg);
            transferOwnership(_farmerUpg);
            return 1;
    }

    ///@dev See ERC20Upg _transferFrom()
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount) public override returns(bool ret) {
            ret = _transferFrom(sender, recipient, amount, owner());
            return ret;
    }

    ///@dev Unstakes token from the pool and send with reward
    function unstake(address dest, uint256 amount, uint256 reward) external onlyOwner returns(uint8 ret) {
        _beforeTokenTransfer(_msgSender(), dest, amount);
        ret = _unstake(_msgSender(), dest, amount, reward);
        return ret;
    }

    ///@dev Mints token of amount to recipient increases the recipient"s balance
    //Should only be called by the owner.
    function mintToken(address recipient, uint amount) external onlyOwner returns(uint8) {
        _mint(_msgSender(), recipient, amount);
        return 1;
    }
    
    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     * NOTE: can only burn by the farmer and only after buyback or specific request
     * from an account.
     * Again, it is very unlikely for the farmer to burn from the treasury since the whole supply is not 
     * in circulation yet.
     * To burn after buyback, Farmer can either do it via another account or send to itself then burn.
     */
    function burn(address account, uint256 amount) external onlyOwner returns(uint8) {
        _burn(account, amount);
        return 1;
    }
    
    function emergencyDraw(address to) external payable onlyOwner returns(uint8) {
        uint amount = address(this).balance;
        require(amount > 0 && to != address(0), "Invalid args");
        //solhint-disable-next-line
        (bool success,) = to.call{value:amount}("");
        require(success, "Transfer failed");
        return 1;
    }

    ///@dev Pauses the contract. When called, some functions are halted.
    function pause() public returns(uint8) {
        require(_msgSender() == owner() || allowance(address(this), _msgSender()) == 1, "Not authorized");
        _pause();
        return 1;
    }

    ///@dev unpauses the contract.
    function unpause() public returns(uint8) {
        require(_msgSender() == owner() || allowance(address(this), _msgSender()) == 1, "Not authorized");
        _unpause();
        return 1;
    }

    /**@dev See IERC20.safeSignedTransfer
        @notice creat a hasklock If user has no lock already set.
    */
    function safeSignedTransfer(
        address to, 
        uint amount, 
        string memory pwd, 
        address randAddress, 
        uint nonce) public override checkParams(pwd, randAddress, nonce) returns(bool) {
            _safeSignedTransfer(
                _msgSender(), 
                to, 
                amount, 
                _hashLock(pwd, randAddress, nonce),
                owner()
            );
            return true;
    }

    /**@dev User approves to spend directly from their account.
        param - data: (not optional) Additional data from the user.
     */
    function approveAndStake(
        address staker, 
        uint amount, 
        bytes32 lock) external onlyOwner returns(uint8) {
            _approveAndStake(_msgSender(), staker, amount, lock);
            return 1;
        }

     /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "Pausable: transfer while paused");
    }

    ///@dev returns all balances of caller.
    function getBalances(address account) public view returns(uint, uint) {
        (uint _reg, uint _locked) = _getBalances(account);
        return (_reg, _locked);
    }

    ///@dev Moves the balance of an 'amount' from locked to regular balances
    function unlockBalance(
        uint amount,
        string memory pwd, 
        address randAddreess, 
        uint nonce) public override whenNotPaused returns(bool) {
            _unlockBalance(_msgSender(), amount, _hashLock(pwd, randAddreess, nonce), owner());
            return true;
    }

    /**@dev Moves the balance of an 'amount' from regular to locked balances
        @notice User must have set up a lock before now
    */
    function lockBalance(uint amount) public override returns(bool) {
        _lockBalance(_msgSender(), amount);
        return true;
    }

    /**@dev Activate or deactivate fantip
        @param cmd - Activates if zero otherwise Deactivates.
     */
    function toggleFanTip(uint8 cmd) public onlyOwner returns(bool) {
        _toggleFanTip(cmd);
        return true;
    }

    /**@dev Compute user's signature
        @param pwd - Any string of length greater than 0.
        @param randAddress - Any EOA or contract greater than address(0)
        @param nonce - Any number greater than 0. 
        @notice It is advuisable to use number combinations 
    */
    function _hashLock(string memory pwd, address randAddress, uint nonce) private pure returns(bytes32) {
        return keccak256(abi.encode(pwd, randAddress, nonce));
    }


}


contract Presale is OwnableNoUpgrade, ReentrancyGuardNoUpgrade {
    using SafeMath for uint256;
    using Verifier for uint256;
    using Verifier for address;
    event WhiteListed(address indexed account);
    event BlackListed(address indexed account);
    event Purchased(address indexed account, uint amount);

    enum Stage { Private, Public }
    QfourToken public tokenAddr;

    ///@dev Structured data for each acceptable denomination
    struct Detail {
        address _contract;
        uint price;
        uint96 minBuy;
        uint96 maxBuy;
        uint discRate;
        uint8 _decimals;
    }

    ///@dev Structured data for each investor
    struct Investor {
        bool isWhiteListed;
        uint amount;
    }

    Stage public stage = Stage.Private; //Stages of sale
    uint public balanceLeft;//Qfour Token Balance at any time
    
    mapping(bytes=>Detail) private detail; ///@dev Mapped record of each acceptable denomination
    mapping(address=>Investor) private investors;///@dev Mapped record of investors

    ///@dev Enforces extra security before and after every call routed to the token contract
    modifier checkAndBalance(uint amount) {
        tokenAddr.unpause();
        _updateBalance();
        _;
        tokenAddr.pause();
        _updateBalance();
    }
    
    /**@dev Initializes state variables
        Mode of entry: Example
            Passing discRate = 10000 sets rate to 100%, 100 = 10%.
            if need to set apr to 12.5%, simply do 12.5/100 * 10000 = 125.
            note that the value multiply by 1000 should not produce decimal number
            else it fails.
    */
    constructor (
        uint32 setter, 
        uint96 minBuy,
        uint96 maxBuy,
        uint discRate,
        uint8 dec) {
            _initialize(setter, minBuy, maxBuy, discRate, dec);
    }

    function setTokenAddr(QfourToken _tokenAddr) public onlyOwner {
        tokenAddr = _tokenAddr;
    }

    /**@dev Resets a new denomination
        cmd - {command} If equal zero, we update for denomination other 
        than BNB else update BNB
        NOTE: Must supply 'setter' which must not be zero. And not less than the "base" of 10000, which sets price to equal 1 in the asset you're accepting for payment
        For example, If Alice accepts BUSD (with decimals 18) as a base currency to exchange for another BEP20 token,
        she will pass 10000 to set the price to 1 BUSD.
        Reducing the traling zeros will reduce the resulting price e.g 1000 sets price to 0.1 BUSD etc.

        NOTE @param _discRate must be greater than zero. Parsing 100 sets rate to 1%. 1000 sets to 10% and so on.
    */

    function resetDetail(
        address _contract, 
        string memory which, 
        uint32 setter, 
        uint8 dec,
        uint96 _minBuy,
        uint96 _maxBuy,
        uint8 cmd,
        uint32 _discRate) public onlyOwner returns(uint8) {
            if(cmd == 0) {
                _contract.notZero();
                uint(setter).isGThan(0);
                uint(_discRate).isGThan(0);
                detail[bytes(which)] = Detail(
                    _contract, uint(setter).mul(10**dec).div(10000), _minBuy, _maxBuy,
                    uint(_discRate).mul(1.0e18).mul(100).div(100.0e18).mul(10**18), dec
                );
            } else {
                detail[bytes("BNB")] = Detail(
                    address(0), uint(setter).mul(1e9 wei), _minBuy, _maxBuy,
                    uint(_discRate).mul(1.0e18).mul(100).div(100.0e18).mul(10**18), dec
                );
            }
            return 1;
    }
    
    ///@dev Returns true if 'target' is whileListed for Stages.Private else false.
    function _isWhiteListed(address target) internal view returns(bool ret) {
        ret = investors[target].isWhiteListed;
        return ret;
    }

    ///@dev Returns details assciated with the field 'which' {string}
    function confirmDetail(string memory which) public view returns(address _addr, uint _price){
        _addr = detail[bytes(which)]._contract;
        _price = detail[bytes(which)].price;
        return (_addr, _price);
    }
    //Returns Qfour balance 
    function _updateBalance() internal {
        balanceLeft = tokenAddr.balanceOf(address(this));
    }

    ///@dev Approve an investor
    function whiteList(address target) public onlyOwner returns(bool) {
        require(!investors[target].isWhiteListed, "already whiteListed");
        emit WhiteListed(target);
        investors[target].isWhiteListed = true;
        return true;
    }

    ///@dev Approve an investor
    function blackList(address target) public onlyOwner returns(bool) {
        require(investors[target].isWhiteListed, "already blackListed");
        emit BlackListed(target);
        investors[target].isWhiteListed = false;
        return true;
    }

    function _getDetail(string memory which) internal view returns(Detail memory _detail) {
        _detail = detail[bytes(which)];
        return _detail;
    }

    ///@dev transfers token to 'recipient'
    function _sendToken(address recipient, uint amount) internal {
        address(tokenAddr).notZero();
        require(tokenAddr.transfer(recipient, amount), "failed");
    }

    ///@dev Toggles stage on or off
    function toggleStage(uint8 newStage) public onlyOwner {
        require(newStage < 2, "No such stage");
        stage = Stage(newStage);
    }

    function apportion(address to, uint amount) public onlyOwner returns(uint8) {
        to.notZero();
        amount.isGThan(0);
        Verifier.isTrue(_isWhiteListed(to));
        investors[to].amount = amount;
        return 1;
    }
    
    ///@dev Buy token with BNB
    function buyWithBNB(
        uint amount) 
        public
        payable
        whenNotPaused 
        nonReentrant 
        checkAndBalance(amount) returns(bool ret) {
            if(stage == Stage.Private && _isWhiteListed(_msgSender())) {
                amount = investors[_msgSender()].amount;
                amount.isGThan(0);
                investors[_msgSender()].amount = 0;
                investors[_msgSender()].isWhiteListed = false;
                _sendToken(_msgSender(), amount);
                ret = true;
            } else if(stage == Stage.Public && !_isWhiteListed(_msgSender())) {
                require(!_isWhiteListed(_msgSender()), "Exempted");
                Detail memory _d = _getDetail("BNB");
                amount.isGaL(_d.minBuy, _d.maxBuy);
                uint amtToPay = amount.mul(_d.price).div(1 ether);
                msg.value.isGOrEqual(amtToPay);
                amount = amount.add(amount.mul(_d.discRate).div(10**18).div(10000));
                emit Purchased(_msgSender(), amount);
                
                _sendToken(_msgSender(), amount);
                ret = true;
            } else { revert("Err"); }
            
    }

    ///@dev Buy token with USDT
    function buyWithUSDT(
        uint amount) 
        public
        whenNotPaused 
        nonReentrant 
        checkAndBalance(amount) returns(bool ret) {
            if(stage == Stage.Private && _isWhiteListed(_msgSender())) {
                amount = investors[_msgSender()].amount;
                amount.isGThan(0);
                investors[_msgSender()].amount = 0;
                investors[_msgSender()].isWhiteListed = false;
                _sendToken(_msgSender(), amount);
                ret = true;
            } else if(stage == Stage.Public && !_isWhiteListed(_msgSender())){
                Detail memory _d = _getDetail("USDT");
                amount.isGaL(_d.minBuy, _d.maxBuy);
                _d._contract.notZero();
                uint amtToPay = amount.mul(_d.price).div(_d._decimals);
                uint allow = IERC20Metadata(_d._contract).allowance(_msgSender(), address(this));
                allow.isGThan(amtToPay);
                Verifier.isTrue(IERC20Metadata(_d._contract).transferFrom(_msgSender(), address(this), allow));
                amount = amount.add(amount.mul(_d.discRate).div(10**18).div(10000));
                emit Purchased(_msgSender(), amount);

                _sendToken(_msgSender(), amount);
                ret = true;
            } else { revert("Err"); }
            
    }

    ///@dev Buy token with BUSD
    function buyWithBUSD(
        uint amount) 
        public
        whenNotPaused 
        nonReentrant 
        checkAndBalance(amount) returns(bool ret) {
            if(stage == Stage.Private && _isWhiteListed(_msgSender())) {
                amount = investors[_msgSender()].amount;
                amount.isGThan(0);
                investors[_msgSender()].amount = 0;
                investors[_msgSender()].isWhiteListed = false;
                _sendToken(_msgSender(), amount);
                ret = true;
            } else if(stage == Stage.Public && !_isWhiteListed(_msgSender())){
                Detail memory _d = _getDetail("BUSD");
                amount.isGaL(_d.minBuy, _d.maxBuy);
                _d._contract.notZero();
                uint amtToPay = amount.mul(_d.price).div(_d._decimals);
                uint allow = IERC20Metadata(_d._contract).allowance(_msgSender(), address(this));
                allow.isGThan(amtToPay);
                Verifier.isTrue(IERC20Metadata(_d._contract).transferFrom(_msgSender(), address(this), allow));
                amount = amount.add( amount.mul(_d.discRate).div(10**18).div(10000));
                emit Purchased(_msgSender(), amount);

                _sendToken(_msgSender(), amount);
                ret = true;
            } else { revert("Err"); }
            
    }
   
    ///@dev Deactivates all public non-trivial functions
    function unpause() public onlyOwner {
        _unpause();
    }

    ///@dev activates all public non-trivial functions
    function pause() public onlyOwner {
        _pause();
    }

    function isWhiteListed() public view returns(bool) {
        return investors[_msgSender()].isWhiteListed;
    }

    function _initialize(
        uint32 setter,
        uint96 minBuy,
        uint96 maxBuy,
        uint _discRate,
        uint8 dec) private {
        require(uint(setter) > 1, "Cannot be zero");
        detail[bytes("BNB")] = Detail(
            address(0), uint(setter).mul(1e9 wei), minBuy, maxBuy, _discRate.mul(1.0e18).mul(100).div(100.0e18).mul(10**18), dec
        );
    }
}