/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


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
            revert("ECDSA: invalid sig 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid sig 'v' value");
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


    /** @dev Moves token of an 'amount' to the locked
    */
    function lockBalance(address _escapeTo, uint amount, uint64 _days) external returns(bool);


    /**@dev Moves 'amount' to regular balance
        @param amount - Amount to unloc.
     */
    function unlockBalance(uint amount) external returns(bool);


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
        uint256 lockUntil;
        uint start;
        address escapeTo;
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
    //solhint-disable-next-line
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
     //solhint-disable-next-line
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
abstract contract ReentrancyGuard {
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




/**@author Quatrefinance {Bobeu}
    NOTE: ALL DEPENDENCY MODULES AND SUBMODULES RALATED TO THIS CONTRACT ARE IMPORTED AND INSPIRED BY THE 
            OPENZEPPELIN CONTRACTS. WE FORWARD OUR REGARDS AND KUDOS TO THESE GREAT GUYS.
                ERC20Upg IS UPGRADEABLE AND WE HAVE STRICTLY FOLLOW OZ's 
                        GUIDELINES FOR WRITING UPGRADEABLE CONTRACTS.

 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn"t required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20NoUpg is IERC20Metadata, Context, OwnableNoUpgrade {
    using SafeMath for uint256;

    uint256 private iterator;//balance iterator: differentiator for balances internally
    uint256 private _totalSupply;//Total supply at any given time. Changes with respect to stakings

    mapping(uint256=>uint256) private _balances; // Houses user's balances
    mapping(address=>Holders) private holders; //Mapping of all holders
    mapping(address=>mapping(address=>uint256)) private _allowances; //Allowances mapping


    string private _name; ///@notice ERC20 Token Name
    string private _symbol; ///@notice ERC20 Token symbol
    bool[2] private boolVars; //Initializer

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
        (uint regular, uint locked) = getBalances(account);
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

    ///@dev Approve a new sale address callable only by the owner
    function elevate(address newAddr) external onlyOwner returns(bool) {
        require(newAddr != address(0), "Invalid address");
        _allowances[address(this)][newAddr] = 1;
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
        uint amount) internal virtual {
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
        uint8 cmd) internal virtual {
            _beforeTokenTransfer(sender, recipient, amount);
            (uint regSender,) = _getIterLocker(sender); 
            (uint _iterRec, uint _lockerRec) = _getIterLocker(recipient);
            (uint senBalNL,) = getBalances(sender);
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
    function _getLocker(address user, uint locker) private returns(uint _locker) {
        _locker = locker == 0 ? _iterate(user, 1) : locker;
        return _locker;
    }

    ///See IERC20.unlockBalance
    function _unlockBalance(address user, uint amount, address _farm) internal virtual {
        (uint reg, uint locker) = _getIterLocker(user);
        (uint _reg, uint _locked) = getBalances(user);
        uint lockTill = holders[user].lockUntil;
        address _escapeTo = holders[user].escapeTo;
        if(lockTill > 0) {
            require(_locked >= amount, "Insuffient locked bal");
            unchecked {
                    _balances[locker] = _locked - amount;
                    _balances[reg] = _reg + amount;
            }
            if(_locked - amount == 0) { holders[user].lockUntil = 0; }
            if(block.timestamp < lockTill){
                if(_escapeTo != address(0)) {
                    uint balLeft = balanceOf(user);
                    _balances[locker] = 0;
                    _balances[reg] = balLeft;
                    holders[user].lockUntil = 0;
                    _transfer(user, _escapeTo, balLeft, 0);
                }
            }
            uint _start = holders[_msgSender()].start;
            if(_start > 0) {
                if(block.timestamp > _start) {
                    if(block.timestamp.sub(_start) >= 30 days) {
                        _tip(user, _farm, boolVars[1], amount);
                        if(_locked - amount == 0) { holders[_msgSender()].start = 0; }
                    }
                }
            }
        } else { revert("No Lock"); }
    }

    ///See IERC20.lockBalance
    function lockBalance(address _escapeTo, uint amount, uint64 _days) public override whenNotPaused returns(bool) {
        (uint reg, uint locker) = _getIterLocker(_msgSender());
        uint _locker = _getLocker(_msgSender(), locker);
        require(_days <= type(uint64).max && _escapeTo != address(0), "Invalid entry");
        unchecked {
            holders[_msgSender()].lockUntil = block.timestamp + (_days * 1 days);
        }
        holders[_msgSender()].start = block.timestamp;
        holders[_msgSender()].escapeTo = _escapeTo;
        uint regBal = _balances[reg];
        require(regBal >= amount, "insufficient Balance");
        unchecked {
            _balances[reg] = regBal - amount;
            _balances[_locker] += amount;
        }

        return true;
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
    function getBalances(address account) public view returns(uint _regular, uint _locked) {
        uint _iter = holders[account].regular;
        uint _locker =  holders[account].locker;
        _regular = _balances[_iter];
        _locked = _balances[_locker];
        return (_regular, _locked);
    }

    function _tip(address _fan, address _farm, bool active, uint amount) private {
        (uint regFarm,) = getBalances(_farm);
        if(active) {
            if(amount > 0) {
                uint tip;
                unchecked {
                    uint _tipRate = ((1.0e18 * 10000) / 100.0e18) * 10**18;
                    tip = ((_tipRate * amount) / 10**18) / 10000;
                }
                if(regFarm > tip) {
                    _transfer(_farm, _fan, tip, 0);
                    _adjustSupply(tip, 1);
                }
            }
        }
    }

    /**@dev Activate or deactivate fantip
        @param cmd - Activates if zero otherwise Deactivates.
     */
    function toggleTip(uint8 cmd) external onlyOwner returns(bool) {
        if(cmd == 0) {
            require(!boolVars[1], "Already activated");
            boolVars[1] = true;
        } else {
            require(boolVars[1], "Already deactivated");
            boolVars[1] = false;
        }
        return true;
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


contract QfourTokenNoUpg is Once, OwnableNoUpgrade, ERC20Permit {
    constructor(address sale)  ERC20Permit(sale) {
        transferOwnership(_msgSender());
    }

    receive() external payable {
        require(msg.value >= 15e13 wei, "Err");
    }

    ///@dev See ERC20Upg _activate()
    function activate(
        uint96 _supply,
        string memory nam,
        string memory symbl,
        address _farmerUpg) public onlyOwner once returns(uint8) {
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
            ret = super._transferFrom(sender, recipient, amount, owner());
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


    ///@dev Moves the balance of an 'amount' from locked to regular balances
    function unlockBalance(uint amount) public override whenNotPaused returns(bool) {
        _unlockBalance(_msgSender(), amount, owner());
        return true;
    }

    //Returns current block number
    function currBlockAndTimestamp() public view returns(uint256, uint256) {
        return (block.number, block.timestamp);
    }

}



library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Addr: insufficient bal for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Addr: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


interface IFarmer {
    /**@notice Sends value of 'amount' in FOUR token into the loam to yield more
        after some period. During the staking period, token remain anonymous i.e 
        it does not reflect in the current totalSupply.
    */
    function stake() external payable returns(uint8);

    /**@notice
        Unstake removes token from anonymous state and subsequently increase the totalSupply.
    */
    function unstake() external payable returns(uint8);
 
    /**@notice
        Returns the principals staked and reward accrued for the period between the commit time
        and now. 
     */
    function pendingReward() external returns(uint256, uint256);

    /**@dev Available to anyone with stake. Returns rewards on stake due to staker 
        returning: 0 signifies success.
        */
    function withdrawReward() external payable returns(uint8);

    function getStakinInfo() external view returns( uint, uint64, uint, uint);

    struct Profile {
        uint8 count;
        uint previousReward;
        uint startBlock;
        uint amount;
        uint8 flag;
        uint feeCharged;
        address proxy;
    }

    struct Info {
        uint _apr;
        uint64 _avgBlockPerDay;
        uint _minimumStakedDuration;
        uint _totalStaked;
        uint _minStake;
        uint _maxStake;
        address updater;
    }
    event Staked(address indexed staker, uint amount, uint _block);
    event UnStaked(address indexed staker, uint amount, uint _block);
    event Farmed(address indexed _to, uint amount);
    event BlackListed(address indexed target, uint amount);
}



//CONTRACT FARMER THAT ADMINISTERS QFOUR TOKEN PLUS STAKING
abstract contract SubFarmer is Context, IFarmer {
    using SafeMath for uint256;
    using Verifier for uint256;
    using Verifier for bool;
    using Verifier for bytes;
    using Verifier for address;
    QfourTokenNoUpg public tokenAddr; ///QFour Token contract instance

    Info private _getter; //See IFarmer.
    mapping(address=>Profile) private _stakes; //Mapping of stakers's profile inclusive of staking balances.
    uint private _treasury; // Farmer's treasury. Equivalent to maxSupply.
    uint public currentSupply; ///NOTE It may not sync with the totalSupply if fanTip is activated
    
    constructor(uint supply, QfourTokenNoUpg _token) {
        _treasury = supply * 10**18;
        _getter = Info(
            20.0e18 *(10**18),
            28800,
            0,
            0,
            10_000 * (10**18),
            200_000 * (10**18),
            Verifier.zero()
        );
        tokenAddr = _token;
    }


    ///@dev Mints an 'amount' of token to address 'account'.
    ///Performs external safe call
    function _farm(address account, uint amount) internal virtual returns(uint8 ret) {
        ret = tokenAddr.mintToken(account, amount) == 1 ? 1 : 0;
        _sync(amount, 0);
        emit Farmed(account, amount);

        return ret;
    }
    
    ///@dev returns either minimum or maximum stake amount based on the command.
    function _stakeCap(uint8 cmd) internal view returns(uint _cap) {
        _cap = cmd == 0 ? _getter._minStake : _getter._maxStake;
        return _cap;
    }

    /**@dev Registers user's stake to the pool.
        note If user already has stake running, we simply calculate reward for the start date to present, 
        registers it to the prevReward, unstake user and stake afresh (previous stake amount + incoming stake amount) 
    */
    function _stake(address user, uint8 _flag, address _proxy) internal virtual returns(uint8 ret) {
        _stakes[user].count ++;
        if(_flag == 1) {
            require(Address.isContract(_proxy), "Denied");
        }
        bytes memory data = Encoder.toBytes_Addr2("allowance(address,address)", user,address(this));
        //solhint-disable-next-line
        (bool success, bytes memory returndata) = _tokenAddr().call(data);
        data = Address.verifyCallResult(success, returndata, "Low level call failed");
        uint _allowance = Decoder.toUint256(data);
        _allowance.isGaL(_stakeCap(0), _stakeCap(1));
        
        tokenAddr.transferFrom(user, address(this), _allowance).isTrue();
        if(_completeStake(user, _flag, _proxy, _allowance)) {
            ret = 1;
        }
       return ret;
    }

    function _completeStake(address _user, uint8 _flag, address _proxy, uint amount) private returns(bool) {
        uint total = _getter._totalStaked;
        _getter._totalStaked = total.add(amount);

        if(_stakes[_user].count == 1) {
            (uint _prevAmt, uint _reward,)  = _calculateReward(_user);
            _stakes[_user] = Profile(
                1,
                _reward,
                _now(),
                _prevAmt.add(amount),
                _flag,
                0,
                _proxy
            );
        } else {
            _stakes[_user] = Profile(1, 0, _now(), amount, _flag, 0, _proxy);
        }
        emit Staked(_user, amount, _now());
       _sync(amount, 1);
       return true;

    }

    ///Returns current block Number
    function _now() internal view returns(uint now_) {
        now_ = block.number;
        return now_;
    }

    ///@dev Unstakes user from the pool.
    function _unstake(address user, address _proxy) internal virtual returns(uint8 _return) {
        _hasStake(user).isTrue();
        uint dur = _getter._minimumStakedDuration;
        (uint _stakedAmt, uint _reward, uint start) = _calculateReward(user);
        _now().isGOrEqual(start.add(dur));
        _checkFlag(user, _proxy);
        _stakedAmt.isGThan(0);
        _stakes[user] = Profile(0, 0, 0, 0, 0, 0, address(0));
        uint total = _getter._totalStaked;
        _getter._totalStaked = total.sub(_stakedAmt);

        bytes memory data = Encoder.toBytes_Addr1_Uint2("unstake(address,uint256,uint256)" ,user,_stakedAmt,_reward);
        //solhint-disable-next-line
        (bool success, bytes memory returndata) = _tokenAddr().call(data);
        data = Address.verifyCallResult(success, returndata, "LLC failed: 2");
        uint(Decoder.toUint8(data)).isGThan(0);
        emit UnStaked(user, _stakedAmt, _now());

        _sync(_stakedAmt.add(_reward),0);
        return 1;
    }

    /**@dev Sets ERC20Token(QfourTokenNoUpg) address to a new one
    */
    function _upgradeERC20Address(QfourTokenNoUpg _tkAddr) internal virtual returns(uint8) {
        tokenAddr = _tkAddr;
        return 1;
    }

    ///Gets the token address from storage. Saves some gas.
    function _tokenAddr() internal view returns(address _addr) {
        _addr = address(tokenAddr);
        return _addr;
    }

    ///@notice checks if user has stake in the pool
    function _hasStake(address user) internal view virtual returns(bool) {
        uint stk = _stakes[user].amount;
        return stk.ifGThan(0);
    }

    ///@dev Utility for calculating reward for staking.
    function _calculateReward(address user) internal view virtual returns(
        uint256 principal,
        uint256 rewardToDate, 
        uint start) {
            principal = _stakes[user].amount;
            if(principal == 0) {
                return (0, 0, 0);
            } else {
                start = _stakes[user].startBlock;
                if(_now().ifGThan(start)) {
                    uint prevReward = _stakes[user].previousReward;
                    uint avgbpd = _getter._avgBlockPerDay;
                    uint apr = _getter._apr;
                    uint blockDiff = _now().sub(start);
                    uint ratePerBlock = apr.div(100.0e18).div(avgbpd.mul(365));
                    uint rewardPerBlock = ratePerBlock.mul(principal).div(10**18);
                    rewardToDate = rewardPerBlock.mul(blockDiff).add(prevReward);
                }
            }
            return (principal, rewardToDate, start);

    }
    /**@dev Utility to update the APR.
        Mode of entry: Example
            Passing _newAPR = 1000 sets apr to 100%, 100 = 10%.
            if need to set apr to 12.5%, simply do 12.5/100 * 1000 = 125.
            note that the value multiply by 1000 should not produce decimal number
            else it fails.
    */
    function _updateAPR(uint newApr) internal virtual {
        _getter._apr = newApr.mul(100.0e18).div(1000).mul(10**18);
    }

    ///@dev Burns token. Only the farmer can burn token
    function _burn(address from, uint amount) internal virtual returns(uint8 _return) {
        _return = tokenAddr.burn(from, amount);
        _treasury.isGOrEqual(amount);
        _treasury -= amount;
        _sync(amount, 1);
        return _return;
    }

    ///@dev Update the treasury and currentSupply
    function _sync(uint _with, uint8 cmd) private {
        uint supply = currentSupply;
        (currentSupply, _treasury) = cmd == 0 ? (
            supply.add(_with), _treasury.sub(_with)
            ) : (supply.sub(_with), _treasury);
    }

    ///@dev Updates average block per day
    function _updateAvgBlockPerDay(uint64 _newBlockEmissionPerDay) internal virtual {
        _getter._avgBlockPerDay = _newBlockEmissionPerDay;
    }

    ///@dev sets minimum stake
    function _updateMinStake(uint _newMinStake) internal virtual {
        _getter._minStake = _newMinStake * 10**18;
    }

    ///@dev sets minimum stake
    function _updateMaxStake(uint _newMaxStake) internal virtual {
        _getter._maxStake = _newMaxStake * 10**18;
    }

    ///@dev Sets minimum stake duration
    function _updateMinStakeDuration(uint _newMinDuration) internal virtual {
        _getter._minimumStakedDuration = _newMinDuration;
    }

    ///@notice Sends user's stake reward provided it is greater than 1
    function _withdrawReward(address user, address _proxy) internal virtual returns(uint8 _ret) {
        _checkFlag(user, _proxy);
        uint _pReward = _stakes[user].previousReward;
        _stakes[user].previousReward = 0;
        _pReward.isGThan(1* (10**18));
        _ret = _farm(user, _pReward);
        return _ret;
    }

    ///@dev WIthdraws availalble BNB from the Qfour Token contract 
    function _emergencyWithdraw(address to) internal virtual returns(bool) {
        bytes memory data = Encoder.toBytes_Addr("emergencyDraw(address)", to);
        //solhint-disable-next-line
        (bool success, bytes memory returndata) = _tokenAddr().call(data);
        data = Address.verifyCallResult(success, returndata, "LLC failed: 5");
        return data.verifyTrue();
    }

    ///@dev unpauses the Qfour Token contract
    function _unpauseToken() internal virtual returns(uint8) {
        bytes memory data = Encoder.toBytes("unpause()");
        //solhint-disable-next-line
        (bool success, bytes memory returndata) = _tokenAddr().call(data);
        data = Address.verifyCallResult(success, returndata, "LLC failed: 6");
        return data.verifyUint8GT(0);
    }
    
    ///@dev Pauses the Qfour Token contract
    function _pauseToken() internal virtual returns(uint8) {
        bytes memory data = Encoder.toBytes("pause()");
        //solhint-disable-next-line
        (bool success, bytes memory returndata) = _tokenAddr().call(data);
        data = Address.verifyCallResult(success, returndata, "LLC failed: 7");
        return data.verifyUint8GT(0);
    }

    ///@notice returns minimum stake
    function _getMinStake() internal view virtual returns(uint256 minstake) {
        minstake = _getter._minStake;
        return minstake;
    }

    ///@notice Returns staking parameters.
    function _stakingInfo() internal view virtual returns(
        uint apr, 
        uint64 avgbpd, 
        uint minDur, 
        uint) {
            apr = _getter._apr;
            avgbpd = _getter._avgBlockPerDay;
            minDur = _getter._minimumStakedDuration;
        
            return (apr, avgbpd, minDur, _getMinStake());
    }

    ///@dev returns total staked to date.
    function _totalStaked() internal view virtual returns(uint) {
        return _getter._totalStaked;
    }

    ///@dev check if user runs a proxy (i.e seller) account
    function _checkFlag(address user, address _proxy) internal view {
        uint8 flag = _stakes[user].flag;
        if(flag == 1) {
            require(_stakes[user].proxy == _proxy, "Not authorized");
        }
    }

    /**@dev Registers fee in respect to target.
        Restricted to the Updater only. Enables user to pay
        network fee with the platform Token.
        NOTE: Disabled. To be implemented in the next upgrade release.
        @param target - User to register fee to.
        @param _feeCharged - Amount to register
     */
    function registerFee(address target, uint _feeCharged) external returns(uint8 ret) {
        address _updater = _getter.updater;
        _msgSender().notZero();
        _updater.notZero();
        _msgSender().equateAddr(_updater, "UnAuthorized");
        if(_hasStake(target)){
            uint prev = _stakes[target].feeCharged;
            _stakes[target].feeCharged = _feeCharged.add(prev);
            ret = 1;
        } else {
            ret = 0;
        }
        return ret;
    }
    ///@dev Set new updater address. To be called only by an authorized account
    ///See FarmerUpg for extended implementation
    function _setUpdater(address newUpdater) internal virtual {
        newUpdater.notZero();
        _getter.updater = newUpdater;
    }

    function _maxSupply() internal virtual view returns(uint) {
        return _treasury;
    }

}



contract Farmer is OwnableNoUpgrade, SubFarmer, ReentrancyGuard {
    using Verifier for uint256;
    using Verifier for bool;
    using Verifier for address;
    uint private minFee;
    
   //solhint-disable-next-line
    constructor(QfourTokenNoUpg _token) SubFarmer(500_000_000, _token) {
        minFee = 1e15 wei;
    }
        // transferOwnership(_msgSender());}

    ///FallBack
    receive() external payable {
        msg.value.isGThan(1e15 wei);
    }
    
    function _minFee() internal view returns(uint) {
        return minFee;
    }

    /**@dev Initially, we already farm the initial supply updated in the the currentSupply.
        The rest in the farm treasury is released as reward for participating in the protocols
        We will occasionally propose activity (s), based on community votes, be approved or reject
        and execute by the QMaster (i.e The Gov). This way, decisions are birth and absorbed via 
        consensus.
        @notice : Initial supply is minted to the tokenomics for administration.
                  Where they're later transfered to their respective destinations.
     */
    function farm(address account, uint amount) public onlyOwner whenNotPaused {
        account.notZero();
        amount.isGThan(0);
       _farm(account, amount);
       _afterTx(_msgSender());
    }

    /**@notice Users are able to commit FOUR Token to earn more reward.
               Reward calculation is initally determined by the Quatre team which will be subsequently
               done by the QMaster after full right is transfered to it.
               User will have to provide a proxy address they own/run on the Quatre nwtwork.
                    It could be a seller account, partner account, or any recognized by the  protocol.
                note that calling this function sends the amount to blackHole i.e token remain anonymouns for
                the period of staking. The resultant effect is a decrease in the totalSupply/currentSupply which
                is targeted to leave a significant increase effect on the price.
        
        NOTE If user already have stake running and this function is called, If all checks passes, 
        the existing stake is ustaked, reward is calculated added and tracked based on the previous
        block time. The principal amount is refreshed by adding the unstaked to the new principal amount
        and the time is refreshed as well. So if there is a minimum staked period, the previous
        principal amount is merged with the current and time to unstake begins at the current time.
     */
    function stake() external payable override whenNotPaused nonReentrant returns(uint8 _ret) {
        msg.value.isGOrEqual(_minFee());
        _increment(0);
        _ret = _stake(_msgSender(), 0, address(0));
        return _ret;
    }

    // ///@notice User is able to Stake from locked balance.
    // function unlockAndStake(uint amount, string memory pwd, address randAddress, uint nonce) public returns(uint8 ret) {
    //     ret = _unlockAndStake(_msgSender(), amount, _getLock(pwd, randAddress, nonce));
    //     return ret;
    // }

    /**@dev See stake above except this involve an external call */
    function stakeByProxy(address src, address _proxy) external payable whenNotPaused nonReentrant returns(uint8 ret) {
        _increment(1);
        msg.value.isGOrEqual(_minFee());
        src.notZeros(_proxy);
        ret = _stake(src, 1, _proxy);
        require(ret == 1, "Failed");
        return ret;
    }

    /**@notice User is able to bring the token to life and reward is sent forthwith.
               Simultaneously, the currentSupply and the totalSupply is updated i.e increases.
    */
    function unstake() external payable override whenNotPaused nonReentrant returns(uint8) {
        msg.value.isGOrEqual(_minFee());
        _unstake(_msgSender(), address(0));
        _decrement(0);
        return 1;
    }

    /**@notice User is able to bring the token to life and reward is sent forthwith.
               Simultaneously, the currentSupply and the totalSupply is updated i.e increases.
               But by proxy account.
    */
    function unstakeByProxy(address src) external payable whenNotPaused returns(uint8 _ret) {
        msg.value.isGOrEqual(_minFee());
        require(Address.isContract(_msgSender()),"Denied");
        _ret = _unstake(src, _msgSender());
        _decrement(1);
        return _ret;
    }

    /**@notice Returns both previous and current rewards to date together
        with the total staked amount.
     */
    function pendingReward() public view override returns(uint256, uint256) {
        (uint256 _principal, uint256 _rewardToDate,) = _calculateReward(_msgSender());
        return(_principal, _rewardToDate);
    }

    ///@dev Token is sent to the blackHole and lost forever
    function burn(address from, uint amount) public onlyOwner returns(uint8) {
        return _burn(from, amount);
    }

    ///See SubFarmer
    function upgradeErc20Address(QfourTokenNoUpg _tkAddr) external onlyOwner returns(uint8) {
        address(_tkAddr).notZero();
        return _upgradeERC20Address(_tkAddr);
    }

    /**@dev See IFarmer */
    function withdrawReward() public payable override whenNotPaused nonReentrant returns(uint8){
        msg.value.isGOrEqual(_minFee());
        _withdrawReward(_msgSender(), address(0));
        return 1;
    }

    /**@dev Special function: Available for external calls: only for 
        proxies in the Quatre protocol.
     */
    function withdrawRewardByProxy(address src) external payable whenNotPaused nonReentrant returns(uint8 ret){
        msg.value.isGOrEqual(_minFee());
        ret = _withdrawReward(src, _msgSender());
        return ret;
    }

    ///Withdraw BNB from the Token contract
    function emergencyWithdraw(address to) public onlyOwner returns(bool) {
        return _emergencyWithdraw(to);
    }

    ///@dev See SubFarmer._updateAPR
    function updateAPR(uint _newAPR) public onlyOwner returns(uint8) {
        _updateAPR(_newAPR);
        return 1;    
    }

    /**@dev See SubFarmer._updateAPR
       @param _newFee: 
            Price in BNB is measured in GWEI i.e 1e9 wei. This means a _priceSetter
            of 1 equivalent to 1 GWEI i.e 0.000000001 BNB wei and 100 GWEI makes 0.0000001 BNB
            For example: If user wants to set price to 0.01 BNB/tokenPrice, simply 
            enter 10,000,000 which sets price to 0.01 BNB/tokenPrice.
    */
    function updateMinFee(uint48 _newFee) public onlyOwner returns(uint8) {
        unchecked {
            minFee = _newFee * 1e9 wei;
        }
        return 1;    
    }

    ///See SubFarmer
    function updateAvgBlockPerDay(uint24 _newBlockEmissionRate) public onlyOwner returns(bool) {
        _updateAvgBlockPerDay(_newBlockEmissionRate);
        return true;    
    }

    ///See SubFarmer
    function updateMinStake(uint _newMinStake) public onlyOwner returns(uint8) {
        _updateMinStake(_newMinStake);
        return 1;    
    }

    ///See SubFarmer
    function updateMaxStake(uint _newMaxStake) public onlyOwner returns(uint8) {
        _updateMaxStake(_newMaxStake);
        return 1;    
    }

    ///See SubFarmer
    function setMinStakeDuration(uint newMinDuration) public onlyOwner returns(uint8) {
        _updateMinStakeDuration(newMinDuration);
        return 1;
    }

    ///See SubFarmer
    function getStakinInfo() public view override returns(uint, uint64, uint, uint) {
        return _stakingInfo();
    }

    ///See SubFarmer
    function unpauseToken() public onlyOwner returns(uint8) {
        return _unpauseToken();
    }

    ///See Subfarmer
    function totalStaked() public view onlyOwner returns(uint) {
        return _totalStaked();
    }

    ///See SubFarmer
    function pauseToken() public onlyOwner returns(uint8) {
        return _pauseToken();
    }

    ///See SubFarmer
    function hasStake(address any) public view returns(bool) {
        return _hasStake(any);
    }

    ///@dev unpauses the farmer
    function unpause() public onlyOwner {
        _unpause();
    }

    ///@dev Pauses the farmer
    function pause() public onlyOwner {
        _pause();
    }

    ///Emergency withdraw 
    function withdraw(address to, uint amount) public onlyOwner {
        to.notZero();
        address(this).balance.isGOrEqual(amount);
        //solhint-disable-next-line
        (bool ret,) = to.call{value: amount}("");
        Verifier.isTrue(ret);
    }

    ///Sets the updated address
    function setUpdater(address newUpdater) public returns(uint8) {
        _setUpdater(newUpdater);
        return 1;
    }

    ///@dev Returns total number of stakers. Also tracks total proxy that has been created overtime
    function stakersCount() public view returns(uint ret, uint retProx) {
        (ret, retProx) = (__gap[0], __gap[1]);
        return (ret, retProx);
    }

    function _increment(uint8 cmd) private {
        if(cmd == 0) {
            uint count = __gap[0];
            __gap[0] = count + 1;
        } else {
            uint count = __gap[1];
            __gap[1] = count + 1;
        }
        
    }

    function _decrement(uint8 cmd) private {
        if(cmd == 0) {
            uint count = __gap[0];
            assert(count >= 1);
            __gap[0] = count - 1;
        } else {
            uint count = __gap[1];
            assert(count >= 1);
            __gap[1] = count - 1;
        }
        
    }

    /**@dev Activate or deactivate fanTip
      param - cmd : Command swicth that turns on or off
     */
    function toggleFanTip(uint8 cmd) public onlyOwner returns(bool ret) {
        ret = tokenAddr.toggleTip(cmd);
        ret.isTrue();
        return ret;
    }

    function maxSupply() public view onlyOwner returns(uint) {
        return _maxSupply();
    }

    function _afterTx(address tg) private view {
        assert(tg == owner());
    }

    ///@dev Approves a new sale address.
    function elevate(address newAddr) public onlyOwner returns(bool) {
        bool ret = tokenAddr.elevate(newAddr);
        assert(ret == true);
        return ret;
    }


    uint256[49] private __gap;

}