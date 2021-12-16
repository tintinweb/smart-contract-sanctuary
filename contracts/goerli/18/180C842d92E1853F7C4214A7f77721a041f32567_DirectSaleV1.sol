/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

/*
 * Direct Sale V1 Prototype for cryptoWine project
 *
 * Developed by Capacity Blockchain Solutions GmbH <capacity.at>
 * for Cryptoagri GmbH <cryptowine.at>
 *
 * Any usage of or interaction with this set of contracts is subject to the
 * Terms & Conditions available at https://cryptowine.at/
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: contracts/ENSReverseRegistrarI.sol

/*
 * Interfaces for ENS Reverse Registrar
 * See https://github.com/ensdomains/ens/blob/master/contracts/ReverseRegistrar.sol for full impl
 * Also see https://github.com/wealdtech/wealdtech-solidity/blob/master/contracts/ens/ENSReverseRegister.sol
 *
 * Use this as follows (registryAddress is the address of the ENS registry to use):
 * -----
 * // This hex value is caclulated by namehash('addr.reverse')
 * bytes32 public constant ENS_ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;
 * function registerReverseENS(address registryAddress, string memory calldata) external {
 *     require(registryAddress != address(0), "need a valid registry");
 *     address reverseRegistrarAddress = ENSRegistryOwnerI(registryAddress).owner(ENS_ADDR_REVERSE_NODE)
 *     require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * or
 * -----
 * function registerReverseENS(address reverseRegistrarAddress, string memory calldata) external {
 *    require(reverseRegistrarAddress != address(0), "need a valid reverse registrar");
 *     ENSReverseRegistrarI(reverseRegistrarAddress).setName(name);
 * }
 * -----
 * ENS deployments can be found at https://docs.ens.domains/ens-deployments
 * E.g. Etherscan can be used to look up that owner on those contracts.
 * namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
 * Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
 * Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
 */

interface ENSRegistryOwnerI {
    function owner(bytes32 node) external view returns (address);
}

interface ENSReverseRegistrarI {
    event NameChanged(bytes32 indexed node, string name);
    /**
     * @dev Sets the `name()` record for the reverse ENS record associated with
     * the calling account.
     * @param name The name to set for this address.
     * @return The ENS node hash of the reverse record.
     */
    function setName(string calldata name) external returns (bytes32);
}

// File: contracts/AgriDataI.sol

/*
 * Interface for data storage of the cryptoAgri system.
 */

interface AgriDataI {

    event AddressChanged(string name, address previousAddress, address newAddress);

    /**
     * @dev Set an address for a name.
     */
    function setAddress(string memory name, address newAddress) external;

    /**
     * @dev Get an address for a name.
     */
    function getAddress(string memory name) external view returns (address);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/ERC721SignedTransferI.sol

/*
 * Interface for ERC721 Signed Transfers.
 */

/**
 * @dev Outward-facing interface of a Collections contract.
 */
interface ERC721SignedTransferI is IERC721 {

    /**
     * @dev Emitted when a signed transfer is being executed.
     */
    event SignedTransfer(address operator, address indexed from, address indexed to, uint256 indexed tokenId, uint256 signedTransferNonce);

    /**
     * @dev The signed transfer nonce for an account.
     */
    function signedTransferNonce(address account) external view returns (uint256);

    /**
     * @dev Outward-facing function for signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can called by anyone knowing about the right signature, but can only transfer to the given specific target.
     */
    function signedTransfer(uint256 tokenId, address to, bytes memory signature) external;

    /**
     * @dev Outward-facing function for operator-driven signed transfer: assembles the expected data and then calls the internal function to do the rest.
     * Can transfer to any target, but only be called by the trusted operator contained in the signature.
     */
    function signedTransferWithOperator(uint256 tokenId, address to, bytes memory signature) external;

}

// File: contracts/ERC721ExistsI.sol

/*
 * Interface for an ERC721 compliant contract with an exists() function.
 */

/**
 * @dev ERC721 compliant contract with an exists() function.
 */
interface ERC721ExistsI is IERC721 {

    // Returns whether the specified token exists
    function exists(uint256 tokenId) external view returns (bool);

}

// File: contracts/CryptoWineTokenI.sol

/*
 * Interface for functions of the cryptoWine token that need to be accessed by
 * other contracts.
 */

interface CryptoWineTokenI is IERC721Enumerable, ERC721ExistsI, ERC721SignedTransferI {

    /**
     * @dev The base URI of the token.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev The storage fee per year in EUR cent.
     */
    function storageFeeYearlyEurCent() external view returns (uint256);

    /**
     * @dev The wine ID for a specific asset / token ID.
     */
    function wineID(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The deposit in EUR cent that is available for storage, shipping, etc.
     */
    function depositEurCent(uint256 tokenId) external view returns (uint256);

    /**
     * @dev The start timestamp (unix format, seconds) for storage.
     */
    function storageStart(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Start storage for a specific asset / token ID, with an initial deposit.
     */
    function startStorage(uint256 tokenId, uint256 depositEurCent) external;

    /**
     * @dev The timestamp (unix format, seconds) until which that storage is paid with the deposit.
     */
    function storageValidUntil(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via native currency.
     */
    function depositStorageFunds(uint256[] memory _tokenIds, uint256[] memory _amounts) external payable;

    /**
     * @dev Prolong storage for specific assets / token IDs by depositing more funds via an ERC20 token.
     */
    function depositStorageFundTokens(address _payTokenAddress, uint256[] memory _tokenIds, uint256[] memory _payTokenAmounts) external;

}

// File: contracts/MultiOracleRequestI.sol

/*
 * Interface for requests to the multi-rate oracle (for EUR/ETH and ERC20)
 * Copy this to projects that need to access the oracle.
 * This is a strict superset of OracleRequestI to ensure compatibility.
 * See rate-oracle project for implementation.
 */

interface MultiOracleRequestI {

    /**
     * @dev Number of wei per EUR
     */
    function EUR_WEI() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Timestamp of when the last update for the ETH rate occurred
     */
    function lastUpdate() external view returns (uint256);

    /**
     * @dev Number of EUR per ETH (rounded down!)
     */
    function ETH_EUR() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev Number of EUR cent per ETH (rounded down!)
     */
    function ETH_EURCENT() external view returns (uint256); // solhint-disable func-name-mixedcase

    /**
     * @dev True for ERC20 tokens that are supported by this oracle, false otherwise
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Number of token units per EUR
     */
    function eurRate(address tokenAddress) external view returns(uint256);

    /**
     * @dev Timestamp of when the last update for the specific ERC20 token rate occurred
     */
    function lastRateUpdate(address tokenAddress) external view returns (uint256);

    /**
     * @dev Emitted on rate update - using address(0) as tokenAddress for ETH updates
     */
    event RateUpdated(address indexed tokenAddress, uint256 indexed eurRate);

}

// File: contracts/ShippingManagerI.sol

/*
 * Interface for shipping manager.
 */

interface ShippingManagerI {

    enum ShippingStatus{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    /**
     * @dev Emitted when an authorizer is set (or unset).
     */
    event AuthorizerSet(address indexed tokenAddress, address indexed authorizerAddress, bool enabled);

    /**
     * @dev Emitted when a token gets enabled (or disabled).
     */
    event TokenSupportSet(address indexed tokenAddress, bool enabled);

    /**
     * @dev Emitted when a shop authorization is set (or unset).
     */
    event ShopAuthorizationSet(address indexed tokenAddress, address indexed shopAddress, bool authorized);

    /**
     * @dev Emitted when the shipping status is set directly.
     */
    event ShippingStatusSet(address indexed tokenAddress, uint256 indexed tokenId, ShippingStatus shippingStatus);

    /**
     * @dev Emitted when the owner submits shipping data.
     */
    event ShippingSubmitted(address indexed owner, address[] tokenAddresses, uint256[][] tokenIds, uint256 shippingId, uint256 shippingPaymentWei);

    /**
     * @dev Emitted when the shipping service failed to ship the physical item and re-set the status.
     */
    event ShippingFailed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId, string reason);

    /**
     * @dev Emitted when the shipping service confirms they can and will ship the physical item with the provided delivery information.
     */
    event ShippingConfirmed(address indexed owner, address indexed tokenAddress, uint256 indexed tokenId);

    /**
     * @dev True if the given `authorizerAddress` can authorize shops for the given `tokenAddress`.
     */
    function isAuthorizer(address tokenAddress, address authorizerAddress) external view returns(bool);

    /**
     * @dev Set an address as being able to authorize shops for the given token.
     */
    function setAuthorizer(address tokenAddress, address authorizerAddress, bool enabled) external;

    /**
     * @dev True for ERC-721 tokens that are supported by this shipping manager, false otherwise.
     */
    function tokenSupported(address tokenAddress) external view returns(bool);

    /**
     * @dev Set a token as (un)supported.
     */
    function setTokenSupported(address tokenAddress, bool enabled) external;

    /**
     * @dev True if the given `shopAddress` is authorized as a shop for the given `tokenAddress`.
     */
    function authorizedShop(address tokenAddress, address shopAddress) external view returns(bool);

    /**
     * @dev Set a shop as (un)authorized for a specific token. When enabling, also sets token as supported if it is not yet.
     */
    function setShopAuthorized(address tokenAddress, address shopAddress, bool authorized) external;

    /**
     * @dev The current delivery status for the given asset.
     */
    function deliveryStatus(address tokenAddress, uint256 tokenId) external view returns(ShippingStatus);

    /**
     * @dev Set the shipping status directly. Can only be called by an authorized on-chain shop.
     */
    function setShippingStatus(address tokenAddress, uint256 tokenId, ShippingStatus newStatus) external;

    /**
     * @dev For token owner (after successful purchase): Request shipping.
     * To make sure the correct amount of currency is being paid here (or has already been paid via other means),
     * a signature from shippingControl is required.
     */
    function shipToMe(address[] memory tokenAddresses, uint256[][] memory tokenIds, uint256 shippingId, bytes memory signature) external payable;

    /**
     * @dev For shipping service: Mark shipping as completed/confirmed.
     */
    function confirmShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds) external;

    /**
     * @dev For shipping service: Mark shipping as failed/rejected (due to invalid address).
     */
    function rejectShipping(address[] memory tokenAddresses, uint256[][] memory tokenIds, string memory reason) external;

}

// File: contracts/TaxRegionsI.sol

/*
 * Interface for tax regions list.
 */

interface TaxRegionsI {

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionId(string memory taxRegionIdentifier) external view returns(uint256);

    /**
     * @dev Return the VAT permil rate for a given tax region.
     */
    function vatPermilForRegionHash(bytes32 taxRegionHash) external view returns(uint256);

    /**
     * @dev Get Region Hash for a region identifier string.
     */
    function getRegionHash(string memory taxRegionIdentifier) external view returns(bytes32);

}

// File: contracts/DirectSaleV1FactoryI.sol

/*
 * Interface for cryptoWine direct sales V1 Factory.
 */

interface DirectSaleV1FactoryI {

    /**
     * @dev Emitted when a new direct sale is created.
     */
    event NewSale(address saleAddress);

    /**
     * @dev The agri data contract used with the tokens.
     */
    function agriData() external view returns (AgriDataI);

}

// File: contracts/DirectSaleV1DeployI.sol

/*
 * cryptoWine Direct Sale V1 deployment interface
 */

interface DirectSaleV1DeployI {

    function initialRegister() external;

}

// File: contracts/DirectSaleV1.sol

/*
 * cryptoWine Direct Sale V1 contract, can own currency and wine NFTs.
 *
 * Preparation steps:
 *   1. Create new direct sale via the factory.
 *   2. Transfer NFTs to sale
 *   3. start sale (no NFTs accepted after this!)
 */

contract DirectSaleV1 is ERC165, DirectSaleV1DeployI, ReentrancyGuard {
    using Address for address payable;
    using Address for address;

    bool public isPrototype;

    AgriDataI public agriData;

    uint256 public startTimestamp;
    uint256 public netSalePriceEurCent;
    uint256 public wineID;

    uint256 public apiReserveLimit;
    mapping (uint256 => bool) public signatureNonceUsed;

    event SaleStartSet(uint256 startTimestamp, uint256 apiReserveLimit, uint256 netSalePriceEurCent);
    event NetSalePriceChanged(uint256 previousPriceEurCent, uint256 newPriceEurCent);
    event ApiReserveLimitChanged(uint256 previousApiReserveLimit, uint256 newApiReserveLimit);
    event AssetsPurchased(address indexed buyer, uint256 amount, uint256 netWeiPerAsset, uint256 paymentAmountWei, uint256 eurRate, string taxRegionIdentifier, uint256 signatureNonce);
    event AssetSold(address indexed buyer, address indexed recipient, uint256 indexed tokenId, uint256 netWeiPerAsset, string taxRegionIdentifier);
    event PaymentForwarded(address indexed recipient, uint256 paymentAmountWei, uint256 amountAssets, uint256 netWeiPerAsset, uint256 vatPermil);

    modifier requireActive {
        require(!isPrototype, "Needs an active contract, not the prototype.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == agriData.getAddress("tokenAssignmentControl"), "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == agriData.getAddress("directsaleCreateControl"), "Admin key required for this function.");
        _;
    }

    modifier onlyAPI() {
        require(msg.sender == agriData.getAddress("cryptoAgriAPI"), "API key required for this function.");
        _;
    }

    modifier requireStarted() {
        require(startTimestamp > 0 && startTimestamp <= block.timestamp, "Sale has to be started.");
       _;
    }

    constructor(address _agriDataAddress)
    {
        agriData = AgriDataI(_agriDataAddress);
        require(address(agriData) != address(0x0), "You need to provide an actual agri data contract.");
        // The initially deployed contract is just a prototype and code holder.
        // Clones will proxy their commends to this one and actually work.
        isPrototype = true;
    }

    function initialRegister()
    external
    requireActive
    {
        // Make sure that this function has not been called on this contract yet.
        require(address(agriData) == address(0), "Cannot be initialized twice.");
        agriData = DirectSaleV1FactoryI(msg.sender).agriData();
    }

    /*** ERC165 ***/

    function supportsInterface(bytes4 interfaceId)
    public view override
    returns (bool)
    {
        return interfaceId == type(IERC721Receiver).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    /*** Get contracts with their ABI ***/

    function oracle()
    public view
    returns (MultiOracleRequestI)
    {
        return MultiOracleRequestI(agriData.getAddress("Oracle"));
    }

    function shippingManager()
    public view
    returns (ShippingManagerI)
    {
        return ShippingManagerI(agriData.getAddress("ShippingManager"));
    }

    function taxRegions()
    public view
    returns (TaxRegionsI)
    {
        return TaxRegionsI(agriData.getAddress("TaxRegions"));
    }

    function assetToken()
    public view
    returns (CryptoWineTokenI)
    {
        return CryptoWineTokenI(agriData.getAddress("CryptoWineToken"));
    }

    /*** Deal with ERC721 tokens we receive ***/

    // Override ERC721Receiver to record receiving of ERC721 tokens.
    // Also, comment out all params that are in the interface but not actually used, to quiet compiler warnings.
    function onERC721Received(address /*_operator*/, address /*_from*/, uint256 /*_tokenId*/, bytes memory /*_data*/)
    public
    requireActive
    returns (bytes4)
    {
        address _tokenAddress = msg.sender;
        // Make sure whoever called this plays nice, check for token being from the contract we need.
        require(_tokenAddress == address(assetToken()), "Actually needs to be a correct token!");
        // Note: Unfortunately, our token only sets the wineID AFTER minting, so it's not available here for the current ID!
        if (wineID == 0 && CryptoWineTokenI(_tokenAddress).balanceOf(address(this)) > 0) {
            // If we own any tokens but have no wine ID, set our ID to that of the first token.
            wineID = CryptoWineTokenI(_tokenAddress).wineID(CryptoWineTokenI(_tokenAddress).tokenOfOwnerByIndex(address(this), 0));
        }
        return this.onERC721Received.selector;
    }

    /*** Sale-realted properties / view functions ***/

    // Get EUR rate in wei - dynamic until first bid comes in, fixed after that point.
    function eurRate()
    public view
    requireActive
    returns (uint256)
    {
        return oracle().eurRate(address(0));
    }

    // Amount of tokens available for sale in total.
    function availableAmount()
    public view
    requireActive
    returns (uint256)
    {
        return assetToken().balanceOf(address(this));
    }

    // Amount of tokens reserved to be sold via the API.
    function apiReservedAmount()
    public view
    requireActive
    returns (uint256)
    {
        uint256 currentBalance = availableAmount();
        if (currentBalance > apiReserveLimit) {
            return apiReserveLimit;
        }
        return currentBalance;
    }

    // Amount of tokens availabnle to be sold on chain.
    function onchainAvailableAmount()
    public view
    requireActive
    returns (uint256)
    {
        return availableAmount() - apiReservedAmount();
    }

    // Calculate current minimal bid in "wei" (subunits of the native chain currency).
    function netSalePriceWei()
    public view
    requireActive
    returns (uint256)
    {
        return netSalePriceEurCent * eurRate() / 100;
    }

    /*** Actual sale functionality ***/

    // Start the sale. At this point, NFTs already need to be owned by this sale.
    function startSale(uint256 _startTimestamp, uint256 _apiReserveLimit, uint256 _netSalePriceEurCent)
    public
    requireActive
    onlyAdmin
    {
        require(assetToken().balanceOf(address(this)) > 0, "The sale needs to own tokens to be started.");
        require(_startTimestamp >= block.timestamp, "Start needs to be in the future.");
        startTimestamp = _startTimestamp;
        apiReserveLimit = _apiReserveLimit;
        netSalePriceEurCent = _netSalePriceEurCent;
        emit SaleStartSet(startTimestamp, apiReserveLimit, netSalePriceEurCent);
    }

    // Close the sale. Will re-set the start date to 0.
    function closeSale()
    public
    requireActive
    onlyAdmin
    {
        startTimestamp = 0;
        emit SaleStartSet(startTimestamp, apiReserveLimit, netSalePriceEurCent);
    }

    // Adjust the minimum bid of the sale, potentially while it's already running.
    function setNetPrice(uint256 _netSalePriceEurCent)
    public
    requireActive
    onlyAdmin
    {
        emit NetSalePriceChanged(netSalePriceEurCent, _netSalePriceEurCent);
        netSalePriceEurCent = _netSalePriceEurCent;
    }

    // Adjust the API reserve. Be careful with this, ideally only use it when the shop is closed and no API reservations are open.
    function setApiReserveLimit(uint256 _newApiReserveLimit)
    public
    requireActive
    onlyAdmin
    {
        emit ApiReserveLimitChanged(apiReserveLimit, _newApiReserveLimit);
        apiReserveLimit = _newApiReserveLimit;
    }

    // Buy NFTs with native currency, potentially with someone else as the recipient.
    function buyFor(address _recipient, uint256 _assetCount, string memory _taxRegionIdentifier, bool _acceptTerms, string memory _acceptanceText)
    public payable
    requireActive
    requireStarted
    {
        _buyOnChain(_recipient, _assetCount, _taxRegionIdentifier, _acceptTerms, _acceptanceText, false, 0);
    }

    // Buy NFTs with native currency, using a signature from the API to tap into the API-reserved assets.
    function buyApiReserve(address _recipient, uint256 _assetCount, string memory _taxRegionIdentifier, bool _acceptTerms, string memory _acceptanceText,
                           uint256 _signatureNonce, uint256 _expirationTimestamp, bytes memory _signature)
    public payable
    requireActive
    requireStarted
    {
        require(_signatureNonce > 0, "Signature nonce needs to be non-zero.");
        require(signatureNonceUsed[_signatureNonce] == false, "Signature nonce has been used before.");
        require(_expirationTimestamp > block.timestamp, "Signature is expired.");
        bytes32 data = keccak256(abi.encodePacked(address(this), block.chainid, this.buyApiReserve.selector, _signatureNonce, _expirationTimestamp, _assetCount, msg.sender));
        bytes32 hash = ECDSA.toEthSignedMessageHash(data);
        address signer = ECDSA.recover(hash, _signature);
        require(signer == agriData.getAddress("cryptoAgriAPI"), "Signature needs to match sent currency value, parameters and API address.");
        signatureNonceUsed[_signatureNonce] = true;
        // Now that we checked that the signature is correct, do the actual purchase.
        _buyOnChain(_recipient, _assetCount,_taxRegionIdentifier, _acceptTerms, _acceptanceText, true, _signatureNonce);
    }

    // Buy NFTs via the API, potentially with someone else as the recipient.
    function buyViaApi(address _recipient, uint256 _assetCount, string memory _taxRegionIdentifier)
    public
    onlyAPI
    requireActive
    requireStarted
    {
        uint256 vatPermil = taxRegions().vatPermilForRegionId(_taxRegionIdentifier);
        require(vatPermil > 0, "The region is not supported.");
        require(_assetCount <= availableAmount(), "Not enough assets available for purchase.");
        // No danger of re-entrancy with recipients' onERC721Received functions as only the API can call this.
        _transferAssets(_recipient, _assetCount, 0, 0, _taxRegionIdentifier, 0);
    }

    function _buyOnChain(address _recipient, uint256 _assetCount, string memory _taxRegionIdentifier, bool _acceptTerms, string memory _acceptanceText, bool canUseApiReserve, uint256 _signatureNonce)
    internal
    {
        require(_acceptTerms, "You need to accept the terms.");
        require(bytes(_acceptanceText).length > 0, "You need to send the acceptance text.");
        uint256 vatPermil = taxRegions().vatPermilForRegionId(_taxRegionIdentifier);
        require(vatPermil > 0, "The region is not supported.");
        if (canUseApiReserve) {
            require(_assetCount <= availableAmount(), "Not enough assets available for purchase.");
        }
        else {
            require(_assetCount <= onchainAvailableAmount(), "Not enough assets available for on-chain purchase.");
        }
        uint256 netWeiPerAsset = netSalePriceWei();
        uint256 totalWeiPerAsset = netWeiPerAsset * (1000 + vatPermil) / 1000;
        // Determine actual price to pay.
        uint256 payAmountWei = _assetCount * totalWeiPerAsset;
        require(msg.value >= payAmountWei, "Not enough currency sent to pay for the assets.");
        // We cannot run into re-entrancy with recipients' onERC721Received functions as forwarding the payment multiple times would fail.
        _transferAssets(_recipient, _assetCount, netWeiPerAsset, payAmountWei, _taxRegionIdentifier, _signatureNonce);
        // Transfer the actual payment amount to the beneficiary.
        // Our own account so no reentrancy here but put at end to be sure.
        emit PaymentForwarded(agriData.getAddress("beneficiary"), payAmountWei, _assetCount, netWeiPerAsset, vatPermil);
        payable(agriData.getAddress("beneficiary")).sendValue(payAmountWei);
        // Send back change money. Do this last. Also send to original sender, not to recipient.
        if (msg.value > payAmountWei) {
            payable(msg.sender).sendValue(msg.value - payAmountWei);
        }
    }

    function _transferAssets(address _recipient, uint256 _amount, uint256 _netWeiPerAsset, uint256 _payAmountWei, string memory _taxRegionIdentifier, uint256 _signatureNonce)
    internal
    {
        emit AssetsPurchased(msg.sender, _amount, _netWeiPerAsset, _payAmountWei, eurRate(), _taxRegionIdentifier, _signatureNonce);
        uint256 availAmount = availableAmount();
        for (uint256 i = 0; i < _amount; i++) {
            // Find the next asset (last owned by the contract) and transfer it.
            uint256 tokenId = assetToken().tokenOfOwnerByIndex(address(this), availAmount - i - 1);
            assetToken().startStorage(tokenId, assetToken().storageFeeYearlyEurCent());
            shippingManager().setShippingStatus(address(assetToken()), tokenId, ShippingManagerI.ShippingStatus.Sold);
            emit AssetSold(msg.sender, _recipient, tokenId, _netWeiPerAsset, _taxRegionIdentifier);
            assetToken().safeTransferFrom(address(this), _recipient, tokenId);
        }
    }

    /*** Enable reverse ENS registration ***/

    // Call this with the address of the reverse registrar for the respecitve network and the ENS name to register.
    // The reverse registrar can be found as the owner of 'addr.reverse' in the ENS system.
    // See https://docs.ens.domains/ens-deployments for address of ENS deployments, e.g. Etherscan can be used to look up that owner on those.
    // namehash.hash("addr.reverse") == "0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2"
    // Ropsten: ens.owner(namehash.hash("addr.reverse")) == "0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c"
    // Mainnet: ens.owner(namehash.hash("addr.reverse")) == "0x084b1c3C81545d370f3634392De611CaaBFf8148"
    function registerReverseENS(address _reverseRegistrarAddress, string memory _name)
    public
    onlyTokenAssignmentControl
    {
        require(_reverseRegistrarAddress != address(0), "Need valid reverse registrar.");
        ENSReverseRegistrarI(_reverseRegistrarAddress).setName(_name);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTrescue(IERC721 _foreignNFT, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignNFT.setApprovalForAll(_to, true);
    }

}