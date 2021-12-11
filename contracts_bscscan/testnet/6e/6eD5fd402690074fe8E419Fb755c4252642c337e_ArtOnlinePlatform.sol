/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

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


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)



/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)



/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


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


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


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
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

    /**
     * @dev Initializes the contract in unpaused state.
     */
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





contract ArtOnlinePlatformStorage {

  uint256 internal _blockTime = 60;
  string internal _uri;
  uint internal unlocked = 1;

  string[] internal _tokens;
  uint256[] internal _items;
  uint256[] internal _pools;

  mapping(uint256 => string) public tokenNames;

  mapping(uint256 => uint256) internal _totalMiners;
  mapping(uint256 => uint256) internal _maxReward;
  mapping(uint256 => mapping(address => uint256)) internal _balances;
  mapping(address => mapping(address => bool)) internal _operatorApprovals;
  // _miners[id][address] = balance
  mapping(uint256 => mapping(address => uint256)) internal _miners;
  mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _bonuses;

  mapping(uint256 => mapping(uint256 => uint256)) internal _mining;
  mapping(uint256 => mapping(uint256 => uint256)) internal _activated;
  mapping(uint256 => mapping(uint256 => address)) internal _owners;
  mapping(uint256 => mapping(address => uint256)) internal _rewards;
  mapping(uint256 => mapping(address => uint256)) internal _startTime;
  mapping(uint256 => uint256) internal _totalSupply;
  mapping(uint256 => uint256) internal _halvings;
  mapping(uint256 => uint256) internal _nextHalving;
  mapping(address => uint256) internal _blacklist;

  mapping(uint256 => uint256) internal _cap;
  mapping(uint256 => uint256) internal _activationPrice;

  event AddToken(string name, uint256 id);
  event AddItem(string name, uint256 id, uint256 bonus);
  event AddPool(string name, uint256 id, uint256 bonus);
  event Activate(address indexed account, uint256 id, uint256 tokenId);
  event Deactivate(address indexed account, uint256 id, uint256 tokenId);
  event ActivateItem(address indexed account, uint256 id, uint256 itemId, uint256 tokenId);
  event DeactivateItem(address indexed account, uint256 id, uint256 itemId, uint256 tokenId);
  event Reward(address account, uint256 id, uint256 reward);
}




contract EIP712 {
  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;

  bytes32 private immutable _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;

  constructor(string memory name, string memory version) {
    bytes32 hashedName = keccak256(bytes(name));
    bytes32 hashedVersion = keccak256(bytes(version));
    bytes32 typeHash = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    _HASHED_NAME = hashedName;
    _HASHED_VERSION = hashedVersion;
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
    _TYPE_HASH = typeHash;
  }

  function _domainSeparatorV4() internal view returns (bytes32) {
    if (block.chainid == _CACHED_CHAIN_ID) {
      return _CACHED_DOMAIN_SEPARATOR;
    } else {
      return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }
  }

  function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash, bytes32 versionHash) private view returns (bytes32) {
    return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
  }

  function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
    return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
  }
}





interface IArtOnline {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}




interface IArtOnlineBridger {
  function setArtOnline(address _address) external;
  function artOnline() external view returns (address);

  function setArtOnlineExchange(address _address) external;
  function artOnlineExchange() external view returns (address);

  function setArtOnlinePlatform(address _address) external;
  function artOnlinePlatform() external view returns (address);

  function setArtOnlineBlacklist(address _address) external;
  function artOnlineBlacklist() external view returns (address);

  function setArtOnlineMining(address _address) external;
  function artOnlineMining() external view returns (address);

  function setArtOnlineBridge(address _address) external;
  function artOnlineBridge() external view returns (address);

  function setArtOnlineFactory(address _address) external;
  function artOnlineFactory() external view returns (address);

  function setArtOnlineStaking(address _address) external;
  function artOnlineStaking() external view returns (address);

  function setArtOnlineAccess(address _address) external;
  function artOnlineAccess() external view returns (address);
}





interface IArtOnlineMining {
  function setTax(uint256 tax_) external;
  function tax() external view returns (uint256);
  function mining(uint256 id, uint256 tokenId) external view returns (uint256);
  function getReward(address sender, uint256 id) external;
  function stakeReward(address sender, uint256 id) external returns (bytes32 stakeId);
  function getRewardBatch(address sender, uint256[] memory ids) external;
  function stakeRewardBatch(address sender, uint256[] memory ids) external returns (bytes32[] memory stakeIds);
  function activateGPU(address sender, uint256 id, uint256 tokenId) external;
  function deactivateGPU(address sender, uint256 id, uint256 tokenId) external;
  function activateGPUBatch(address sender, uint256[] memory ids, uint256[] memory amounts) external;
  function deactivateGPUBatch(address sender, uint256[] memory ids, uint256[] memory amounts) external;
  function activateItem(address sender, uint256 id, uint256 itemId, uint256 tokenId) external;
  function deactivateItem(address sender, uint256 id, uint256 itemId, uint256 tokenId) external;
}




interface IArtOnlineStaking {
  function totalSupply() external view returns (uint256);
  function balanceOf(address, address account) external view returns (uint256);
  function setReleaseTime(uint256 releaseTime_) external;
  function releaseTime() external view returns (uint256);
  function stake(address account, uint256 amount, address) external returns (bytes32);
  function withdraw(address account, bytes32 id) external;
  function holders(address) external returns (address[] memory);
  function readyToRelease(address account, bytes32 id) external view returns (bool);
}




interface IArtOnlineAccess {
  function isAdmin(address account) external returns (bool);
  function isMinter(address account) external returns (bool);
}




interface IArtOnlineBlacklist {
  function blacklist(address account, bool blacklist_) external;
  function blacklisted(address account) external view returns (bool);
}








contract SetArtOnlinePlatform {

  IArtOnline internal _artOnlineInterface;
  IArtOnlineBridger internal _artOnlineBridgerInterface;
  IArtOnlineMining internal _artOnlineMiningInterface;
  IArtOnlineStaking internal _artOnlineStakingInterface;
  IArtOnlineAccess internal _artOnlineAccessInterface;
  IArtOnlineBlacklist internal _artOnlineBlacklistInterface;

  modifier isWhiteListed(address account) {
    require(_artOnlineBlacklistInterface.blacklisted(account) == false, 'BLACKLISTED');
    _;
  }

  modifier onlyAdmin() {
    require(_artOnlineAccessInterface.isAdmin(msg.sender) == true, 'NO_PERMISSION');
    _;
  }

  modifier onlyMinter() {
    require(_artOnlineAccessInterface.isMinter(msg.sender) == true, 'NO_PERMISSION');
    _;
  }

  modifier onlyExchange() {
    require(msg.sender == _artOnlineBridgerInterface.artOnlineExchange(), 'NO PERMISSION');
    _;
  }

  constructor(address artOnlineBridger_, address artOnlineAccess_) {
    _artOnlineBridgerInterface = IArtOnlineBridger(artOnlineBridger_);
    _artOnlineAccessInterface = IArtOnlineAccess(artOnlineAccess_);
  }

  function artOnlineBridgerInterface() external view returns (address) {
    return address(_artOnlineBridgerInterface);
  }

  function artOnlineInterface() external view  returns (address) {
    return address(_artOnlineInterface);
  }

  function artOnlineMiningInterface() external view  returns (address) {
    return address(_artOnlineMiningInterface);
  }

  function artOnlineStakingInterface() external view  returns (address) {
    return address(_artOnlineStakingInterface);
  }

  function artOnlineAccessInterface() external view  returns (address) {
    return address(_artOnlineAccessInterface);
  }

  function setArtOnlineBridgerInterface(address _artOnlineBridger) external onlyAdmin() {
    _artOnlineBridgerInterface = IArtOnlineBridger(_artOnlineBridger);
    address _artOnline = _artOnlineBridgerInterface.artOnline();
    address _artOnlineMining = _artOnlineBridgerInterface.artOnlineMining();
    address _artOnlineStaking = _artOnlineBridgerInterface.artOnlineStaking();
    address _artOnlineAccess = _artOnlineBridgerInterface.artOnlineAccess();
    address _artOnlineBlacklist = _artOnlineBridgerInterface.artOnlineBlacklist();

    if (address(_artOnlineInterface) != _artOnline) {
      _setArtOnlineInterface(_artOnline);
    }
    if (address(_artOnlineMiningInterface) != _artOnlineMining) {
      _setArtOnlineMiningInterface(_artOnlineMining);
    }
    if (address(_artOnlineStakingInterface) != _artOnlineStaking) {
      _setArtOnlineStakingInterface(_artOnlineStaking);
    }
    if (address(_artOnlineAccessInterface) != _artOnlineAccess) {
      _setArtOnlineAccessInterface(_artOnlineAccess);
    }

    if (address(_artOnlineBlacklistInterface) != _artOnlineBlacklist) {
      _setArtOnlineBlacklistInterface(_artOnlineBlacklist);
    }
  }

  function _setArtOnlineInterface(address _artOnline) internal {
    _artOnlineInterface = IArtOnline(_artOnline);
  }

  function _setArtOnlineMiningInterface(address _artOnlineMining) internal {
    _artOnlineMiningInterface = IArtOnlineMining(_artOnlineMining);
  }

  function _setArtOnlineStakingInterface(address _artOnlineStaking) internal {
    _artOnlineStakingInterface = IArtOnlineStaking(_artOnlineStaking);
  }

  function _setArtOnlineAccessInterface(address _artOnlineAccess) internal {
    _artOnlineAccessInterface = IArtOnlineAccess(_artOnlineAccess);
  }

  function _setArtOnlineBlacklistInterface(address _artOnlineBlacklist) internal {
    _artOnlineBlacklistInterface = IArtOnlineBlacklist(_artOnlineBlacklist);
  }

  function setArtOnlineInterface(address _address) external onlyAdmin() {
    _setArtOnlineInterface(_address);
  }

  function setArtOnlineMiningInterface(address _address) external onlyAdmin() {
    _setArtOnlineMiningInterface(_address);
  }

  function setArtOnlineStakingInterface(address _address) external onlyAdmin() {
    _setArtOnlineStakingInterface(_address);
  }

  function setArtOnlineAccessInterface(address _address) external onlyAdmin() {
    _setArtOnlineAccessInterface(_address);
  }

  function setArtOnlineBlacklistInterface(address _address) external onlyAdmin() {
    _setArtOnlineBlacklistInterface(_address);
  }
}














contract ArtOnlinePlatform is Context, ERC165, IERC1155, IERC1155MetadataURI, Pausable, EIP712, SetArtOnlinePlatform, ArtOnlinePlatformStorage {
  using Address for address;

  modifier lock() {
    require(unlocked == 1, 'LOCKED');
    unlocked = 0;
    _;
    unlocked = 1;
  }

  constructor(string memory uri_, string memory name, string memory version, address bridger, address access)
    EIP712(name, version)
    SetArtOnlinePlatform(bridger, access)
  {
    _uri = uri_;
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
        k = k-1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
  }

  function cap(uint256 id) external view virtual returns (uint256) {
    return _cap[id];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(_uri, uint2str(_tokenId), ".json"));
  }

  function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
    require(account != address(0), "balance query for the zero address");
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
  public
  view
  virtual
  override
  returns (uint256[] memory) {
    require(accounts.length == ids.length, "accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    require(_msgSender() != operator, "setting approval status for self");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[account][operator];
  }

  function safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  ) external virtual override isWhiteListed(from) isWhiteListed(to) {
    require(
        from == _msgSender() || isApprovedForAll(from, _msgSender()),
        "caller is not owner nor approved"
    );
    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) external virtual override isWhiteListed(from) isWhiteListed(to) {
    require(
        from == _msgSender() || isApprovedForAll(from, _msgSender()),
        "transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _safeTransferFrom(
      address from,
      address to,
      uint256 id,
      uint256 amount,
      bytes memory data
  ) internal virtual {
    require(to != address(0), "transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
    _removeBalance(from, id, amount, 0);
    _addBalance(to, id, amount, 0);

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeBatchTransferFrom(
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ids and amounts length mismatch");
    require(to != address(0), "transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      _removeBalance(from, ids[i], amounts[i], 0);
      _addBalance(to, ids[i], amounts[i], 0);
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function totalSupply(uint256 id) public view returns (uint256) {
    return _totalSupply[id];
  }

  function addToken(string memory name, uint256 cap_) public virtual onlyAdmin() {
    uint256 id = _tokens.length;
    require(bytes(tokenNames[id]).length == 0, 'token exists');
    _tokens.push(name);
    _cap[id] = cap_;
    tokenNames[id] = name;
    emit AddToken(name, id);
  }

  function mint(address to, uint256 id, uint256 amount) public whenNotPaused virtual onlyMinter() {
    _mint(to, id, amount, "");
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused virtual onlyMinter() {
    _mintBatch(to, ids, amounts, "");
  }

  function burn(address from, uint256 id, uint256 amount) public virtual whenNotPaused onlyMinter() {
    _burn(from, id, amount, "");
  }

  function burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) public whenNotPaused virtual onlyMinter() {
    _burnBatch(from, ids, amounts, "");
  }

  function _beforeMint(address to, uint256 id, uint256 amount) internal virtual {
    require(_cap[id] >= amount, 'exceeds token cap');
    require(_owners[id][amount] == address(0), 'already exists');
    require(to != address(0), "mint to the zero address");
  }

  function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
    require(ids.length == amounts.length, "ids and amounts length mismatch");
    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _beforeMint(to, ids[i], amounts[i]);
      _addBalance(to, ids[i], amounts[i], 1);
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);
    _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
  }

  function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
    _beforeMint(to, id, amount);
    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    _addBalance(to, id, amount, 1);
    emit TransferSingle(operator, address(0), to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
  }

  function _addBalance(address to, uint256 id, uint256 amount, uint256 mints) internal {
    _balances[id][to] += 1;
    if (mints == 1) {
      _totalSupply[id] += 1;
    }
    _owners[id][amount] = to;
  }

  function _removeBalance(address from, uint256 id, uint256 amount, uint256 burns) internal {
    require(_owners[id][amount] == from || isApprovedForAll(_owners[id][amount], _msgSender()), "not an owner or approved");

    if (burns == 1) {
      unchecked {
        _totalSupply[id] -= 1;
      }
    }
    unchecked {
      _balances[id][from] -= 1;
    }
    _owners[id][amount] = address(0);
  }

  function _beforeTokenTransfer(
      address operator,
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) internal virtual {
      for (uint256 i = 0; i < ids.length; i++) {
        if (from != address(0)) {
          uint256 id = ids[i];
          uint256 amount = amounts[i];
          require(_artOnlineMiningInterface.mining(id, amount) == 0, "DEACTIVATE_FIRST");
          require(_owners[id][amount] == from || isApprovedForAll(_owners[id][amount], _msgSender()), "not an owner or approved");
        }
      }
    }

    function _burn(address from, uint256 id, uint256 amount, bytes memory data) internal virtual {
      require(from != address(0), "burn from the zero address");

      address operator = _msgSender();

      _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
      _removeBalance(from, id, amount, 1);

      emit TransferSingle(operator, from, address(0), id, amount);
    }
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
      require(from != address(0), "burn from the zero address");
      require(ids.length == amounts.length, "ids and amounts length mismatch");

      address operator = _msgSender();

      _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

      for (uint256 i = 0; i < ids.length; i++) {
        _removeBalance(from, ids[i], amounts[i], 1);
      }
      emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
      if (to.isContract()) {
        try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
            if (response != IERC1155Receiver.onERC1155Received.selector) {
                revert("ERC1155Receiver rejected tokens");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC1155Receiver implementer");
        }
      }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
      if (to.isContract()) {
        try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
            bytes4 response
        ) {
            if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                revert("ERC1155Receiver rejected tokens");
            }
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer to non ERC1155Receiver implementer");
        }
      }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
      uint256[] memory array = new uint256[](1);
      array[0] = element;

      return array;
    }

    function activateGPUBatch(uint256[] memory ids, uint256[] memory tokenIds) external {
      _artOnlineMiningInterface.activateGPUBatch(msg.sender, ids, tokenIds);
    }

    function deactivateGPUBatch(uint256[] memory ids, uint256[] memory tokenIds) external {
      _artOnlineMiningInterface.deactivateGPUBatch(msg.sender, ids, tokenIds);
    }

    function activateGPU(uint256 id, uint256 tokenId) public {
      _artOnlineMiningInterface.activateGPU(msg.sender, id, tokenId);
    }

    function deactivateGPU(uint256 id, uint256 tokenId) public {
      _artOnlineMiningInterface.deactivateGPU(msg.sender, id, tokenId);
    }

    function activateItem(uint256 id, uint256 itemId, uint256 tokenId) public {
      _artOnlineMiningInterface.activateItem(msg.sender, id, itemId, tokenId);
    }

    function deactivateItem(uint256 id, uint256 itemId, uint256 tokenId) public {
      _artOnlineMiningInterface.deactivateItem(msg.sender, id, itemId, tokenId);
    }

    function stakeReward(uint256 id) public {
      _artOnlineMiningInterface.stakeReward(msg.sender, id);
    }

    function getReward(uint256 id) public {
      _artOnlineMiningInterface.getReward(msg.sender, id);
    }

    function stakeRewardBatch(uint256[] memory ids) public {
      _artOnlineMiningInterface.getRewardBatch(msg.sender, ids);
    }

    function getRewardBatch(uint256[] memory ids) public {
      _artOnlineMiningInterface.getRewardBatch(msg.sender, ids);
    }

    function ownerOf(uint256 id, uint256 tokenId) public view virtual returns (address) {
      address owner = _owners[id][tokenId];
      require(owner != address(0), "NONEXISTENT_TOKEN");
      return owner;
    }

    function ownerOfBatch(uint256[] memory ids, uint256[] memory tokenIds) public view virtual returns (address[] memory) {
      require(ids.length == tokenIds.length, "ids and tokenIds length mismatch");

      address[] memory batchOwners = new address[](ids.length);

      for (uint256 i = 0; i < ids.length; ++i) {
        batchOwners[i] = ownerOf(ids[i], tokenIds[i]);
      }

      return batchOwners;
    }

    function tokensLength() external view virtual returns (uint256) {
      return _tokens.length;
    }

    function tokens() external view virtual returns (string[] memory) {
      return _tokens;
    }

    function token(uint256 id) external view virtual returns (string memory) {
      return _tokens[id];
    }

    function mintAsset(address to, uint256 id) external onlyExchange() returns (uint256) {
      uint256 tokenId = _totalSupply[id] + 1;
      _mint(to, id, tokenId, "");
      return tokenId;
    }

    function mintAssets(address to, uint256 id, uint256 amount) external onlyExchange() returns (uint256[] memory) {
      return __mintAssets(to, id, amount);
    }

    function _mintAssets(address to, uint256 id, uint256 amount) external onlyAdmin() returns (uint256[] memory) {
      return __mintAssets(to, id, amount);
    }

    function __mintAssets(address to, uint256 id, uint256 amount) internal returns (uint256[] memory) {
      uint256[] memory tokenIds = new uint256[](amount);
      for (uint256 i = 0; i < amount; i++) {
        uint256 tokenId = _totalSupply[id] + 1;
        _mint(to, id, tokenId, "");
        tokenIds[i] = tokenId;
      }
      return tokenIds;
    }
}