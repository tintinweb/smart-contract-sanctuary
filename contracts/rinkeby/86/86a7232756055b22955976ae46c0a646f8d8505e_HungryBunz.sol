/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// File: primary-contract/ECDSA.sol



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

// File: primary-contract/Strings.sol



pragma solidity ^0.8.0;

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

// File: primary-contract/IERC721Receiver.sol



pragma solidity ^0.8.0;

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

// File: primary-contract/IERC165.sol



pragma solidity ^0.8.0;

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
// File: primary-contract/ERC165.sol



pragma solidity ^0.8.0;


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

// File: primary-contract/IERC721.sol



pragma solidity ^0.8.0;


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

// File: primary-contract/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: primary-contract/Address.sol



pragma solidity ^0.8.0;

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

// File: primary-contract/Context.sol



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

// File: primary-contract/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: primary-contract/PaymentSplitter.sol



pragma solidity ^0.8.0;



/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: primary-contract/Ownable.sol



pragma solidity ^0.8.0;


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

// File: primary-contract/HungryBunz.sol


pragma solidity ^0.8.0;





interface snax {
    function feed(address requester, bytes16 stats, uint256 burn) external view returns (bytes16);
}

interface item {
    function applyProperties(bytes32 properties, uint16 item) external view returns (bytes32);
}

interface nom {
    function burn(address account, uint256 amount) external;
    function unstake(uint16[] memory tokenIds, address targetAccount) external;
}

interface metadataGen {
    function generateStats(address requester, uint16 newTokenId, uint32 password) external view returns (bytes16);
    function generateAttributes(address requester, uint16 newTokenId, uint32 password) external view returns (bytes16);
}

interface IMetadataRenderer {
    function renderMetadata(uint16 tokenId, bytes16 atts, bytes16 stats) external view returns (string memory);
}

interface IEvolve {
    function evolve(uint8 next1of1, uint16 burntId, bytes32 t1, bytes32 t2) external view returns(bytes32);
}

contract HungryBunz is PaymentSplitter, Ownable, ERC721 {
    //******************************************************
    //CRITICAL CONTRACT PARAMETERS
    //******************************************************
    using ECDSA for bytes32;
    
    bool _saleStarted;
    bool _saleEnd;
    bool _bypassAPI;
    bool _metadataRevealed;
    uint8 _season; //Defines rewards season
    uint8 _1of1Index; //Currently available 1of1 piece
    uint8 _named1of1s; //Counts 1of1s which have been named.
    uint16 _totalSupply;
    uint16 _maxPerWallet;
    uint16 _maxSupply;
    uint256 _baseMintPrice;
    uint256 _nameTagPrice;
    address _thisContractAddress;
    address _nomContractAddress;
    address _snaxContractAddress;
    address _itemContractAddress;
    address _metadataAddress;
    address _arbGateway; //Will need to be populated with the L1 or L2 partner for arb messaging.
    //address _openSea = 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b; //Opensea Mainnet
    //address _openSea = 613a12b156ffa304f714cc38d6ae5d3df70d8063; //Opensea Testnet
    address _signerAddress = 0xF658480075BA1158f12524409066Ca495b54b0dD; //Signer address for the transaction
    
    string _storefrontURI;
    string _appBaseURI;
    IMetadataRenderer renderer;
    IEvolve _evolver;
    
    //******************************************************
    //GAMEPLAY MECHANICS
    //******************************************************
    uint8 _maxRank = 2; //Maximum rank setting to allow additional evolutions over time...
    mapping(uint8 => uint16) _evolveThiccness; //Required thiccness total to evolve by current rank
    mapping(uint8 => uint8) _1of1Allotted; //Allocated 1 of 1 pieces per season
    mapping(uint8 => bool) _1of1sOnThisLayer; //Permit 1/1s on this layer and season.
    
    //******************************************************
    //ANTI BOT AND FAIR LAUNCH HASH TABLES AND ARRAYS
    //******************************************************
    mapping(address => uint8) tokensMintedByAddress; //Tracks total NFTs minted to limit individual wallets.
    mapping(bytes8 => bool) _usedSalt; //Tracks salts used to mint to minimize likelihood of collisions.
    
    //******************************************************
    //METADATA HASH TABLES AND ARRAYS
    //******************************************************
    mapping(uint16 => bytes32) metadataById; //Stores critical metadata by ID
    mapping(uint16 => bool) _lockedTokens; //Tracks tokens locked for staking
    mapping(uint16 => bool) _inactiveOnThisChain; //Tracks which tokens are active on current chain
    mapping(bytes16 => bool) _usedCombos; //Stores attribute combo hashes to guarantee uniqueness
    mapping(uint16 => string) namedBunz; //Stores names for bunz
    
    //******************************************************
    //CONTRACT CONSTRUCTOR
    //******************************************************
    constructor(
        address[] memory payees,
        uint256[] memory paymentShares
    )
    ERC721("HungryBunz", "BUNZ")
    PaymentSplitter(payees, paymentShares) 
    {
        _baseMintPrice = 0.06 ether;
        _maxSupply = 8888;
        _maxPerWallet = 4;
        _nameTagPrice = 200 * 10**18;
        _evolveThiccness[1] = 5000;
        _evolveThiccness[2] = 30000;
    }
    
    //******************************************************
    //OVERRIDES TO HANDLE CONFLICTS BETWEEN IMPORTS
    //******************************************************
    function _burn(uint256 tokenId) internal virtual override(ERC721) {
        ERC721._burn(tokenId);
        delete metadataById[uint16(tokenId)];
    }
    
    function applicationOwnerOf(uint256 tokenId) public view returns (address) {
        return ERC721.ownerOf(tokenId);
    }
    
    //override ownerOf to delete OS listings without paying transfer gas
    function ownerOf(uint256 tokenId) public view virtual override(ERC721) returns (address) {
        address owner = ERC721.ownerOf(tokenId);
        if (_lockedTokens[uint16(tokenId)] || _inactiveOnThisChain[uint16(tokenId)]) {
            owner = address(0);
        }
        return owner;
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override(ERC721) returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return ((spender == owner || getApproved(tokenId) == spender ||
            spender == _arbGateway || isApprovedForAll(owner, spender) ||
            spender == _thisContractAddress) && !_lockedTokens[uint16(tokenId)] && 
            !_inactiveOnThisChain[uint16(tokenId)]);
    }
    
    //******************************************************
    //OWNER ONLY FUNCTIONS TO MANAGE CRITICAL PARAMETERS
    //******************************************************    
    function updateThisContractAddress(address contractAddress) public onlyOwner {
        _thisContractAddress = contractAddress;
    }
    
    function updateNomContractAddress(address contractAddress) public onlyOwner {
        _nomContractAddress = contractAddress;
    }
    
    function updateSnaxContractAddress(address contractAddress) public onlyOwner {
        _snaxContractAddress = contractAddress;
    }
    
    function updateItemContractAddress(address contractAddress) public onlyOwner {
        _itemContractAddress = contractAddress;
    }
    
    function updateMetadataContractAddress(address contractAddress) public onlyOwner {
        _metadataAddress = contractAddress;
    }
    
    function updateArbGateway(address contractAddress) public onlyOwner {
        _arbGateway = contractAddress;
    }
    
    function updateRenderer(IMetadataRenderer newRenderer) public onlyOwner {
        renderer = newRenderer;
    }
    
    function updateEvolutionInterface(IEvolve newEvolver) public onlyOwner {
        _evolver = newEvolver;
    }
    
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _appBaseURI = newBaseURI;
    }
    
    function startSale() public onlyOwner {
        require(_saleEnd == false, "Cannot restart sale.");
        _saleStarted = true;
    }
    
    function endSale() public onlyOwner {
        _saleStarted = false;
        _saleEnd = true;
    }
    
    function changeWalletLimit(uint16 newLimit) public onlyOwner {
        _maxPerWallet = newLimit;
    }
    
    function startNewSeason(uint8 oneOfOneCount, bool enabledOnThisLayer) public onlyOwner {
        _season++;
        //We make the allocation per season equal to specified allocation plus current supply.
        //This seems to minimize comparsion operations in the evolve function.
        _1of1Allotted[_season] = oneOfOneCount + _1of1Index;
        _1of1sOnThisLayer[_season] = enabledOnThisLayer;
    }
    
    function addRank(uint8 newRank) public onlyOwner { //Used to enable third, fourth, etc. evolution levels.
        _maxRank = newRank;
    }
    
    function updateEvolveThiccness(uint8 rank, uint16 threshold) public onlyOwner {
        //Rank as current. E.G. (1, 10000) sets threshold to evolve to rank 2
        //to 10000 pounds or thiccness points
        _evolveThiccness[rank] = threshold;
    }
    
    function setPriceToName(uint256 newPrice) public onlyOwner {
        _nameTagPrice = newPrice;
    }
    
    function bypassAPI() public onlyOwner {
        _bypassAPI = true;
    }
    
    function reveal() public onlyOwner {
        _metadataRevealed = true;
    }
    
    function setStoreFrontURI(string memory newURI) public onlyOwner {
        _storefrontURI = newURI;
    }
    
    //******************************************************
    //VIEWS FOR GETTING PRICE INFORMATION
    //******************************************************
    function baseMintPrice() public view returns (uint256) {
        return _baseMintPrice;
    }
    
    function totalMintPrice(uint8 numberOfTokens) public view returns (uint256) {
        return _baseMintPrice * numberOfTokens;
    }
    
    //******************************************************
    //ANTI-BOT PASSWORD HANDLERS
    //******************************************************
    function hashTransaction(address sender, uint256 qty, bytes8 salt) private pure returns(bytes32) {
          bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, qty, salt)))
          );
          
          return hash;
    }
    
    function matchAddresSigner(bytes32 hash, bytes memory signature) public view returns(bool) {
        return (_signerAddress == hash.recover(signature));
    }
    
    //******************************************************
    //UTILITY FUNCTIONS
    //******************************************************
    function uint2str(uint _i, uint8 dec) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        uint zeroPad;
        while (j != 0) {
            len++;
            j /= 10;
        }
        
        if (dec >= len) {
            zeroPad = dec - len + 1;
        }
        
        uint k = dec == 0 ? len : len + zeroPad + 1; //extend loop for decimals
        bytes memory bstr = new bytes(k);
        
        while (k > 0) {
            k -= 1;
            if ((k == (len + zeroPad - dec)) && dec > 0) {
                bstr[k] = bytes1(".");
            } else {
                uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
        }
        return string(bstr);
    }
    
    //For Opensea Storefront!
    function contractURI() public view returns (string memory) {
        return _storefrontURI;
    }
    
    function produceJSON(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token Doesn't Exist");
        bytes16 atts = serializeAtts(uint16(tokenId));
        bytes16 stats = serializeStats(uint16(tokenId));
        
        return renderer.renderMetadata(uint16(tokenId), atts, stats);
    }
    
    //******************************************************
    //TOKENURI OVERRIDE RELOCATED TO BE BELOW UTILITY FUNCTIONS
    //******************************************************
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Token Doesn't Exist");
        string memory output;
        
        if (_bypassAPI) {
            output = produceJSON(tokenId);
        } else {
            output = string(abi.encodePacked(_appBaseURI, uint2str(tokenId, 0)));
        }
        
        if(bytes(output).length != 0) {
            return output;
        }
        
        //fallback
        return ERC721.tokenURI(tokenId);
    }
    
    function _writeSerializedAtts(uint16 tokenId, bytes16 newAtts) internal {
        bytes16 currentStats = serializeStats(tokenId);
        metadataById[tokenId] = bytes32(abi.encodePacked(newAtts, currentStats));
    }
    
    function writeSerializedAtts(uint16 tokenId, bytes16 newAtts) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        _writeSerializedAtts(tokenId, newAtts);
    }
    
    function serializeAtts(uint16 tokenId) public view returns (bytes16) {
        return _metadataRevealed ? bytes16(metadataById[tokenId]) : bytes16(0);
    }
    
    function _writeSerializedStats(uint16 tokenId, bytes16 newStats) internal {
        bytes16 currentAtts = serializeAtts(tokenId);
        metadataById[tokenId] = bytes32(abi.encodePacked(currentAtts, newStats));
    }
    
    function writeSerializedStats(uint16 tokenId, bytes16 newStats) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        _writeSerializedStats(tokenId, newStats);
    }
    
    function serializeStats(uint16 tokenId) public view returns (bytes16) {
        return _metadataRevealed ? bytes16(metadataById[tokenId] << 128) : bytes16(0);
    }
    
    function propertiesBytes(uint16 tokenId) external view returns(bytes32) {
        return metadataById[tokenId];
    }
    
    //******************************************************
    //PSEUDO RANDOM METADATA CREATION
    //******************************************************
    function generateMetadata(address requester, uint16 newTokenId, uint32 password) internal {
        //While loop with incrementing "password" as salt ensures uniqueness.
        bytes16 newAtts;
        while(newAtts == 0 || _usedCombos[newAtts]) {
            newAtts = metadataGen(_metadataAddress).generateAttributes(requester, newTokenId, password);
            password++;
        }
        _usedCombos[newAtts] = true;
        
        bytes16 newStats = metadataGen(_metadataAddress).generateStats(requester, newTokenId, password);
        metadataById[newTokenId] = bytes32(abi.encodePacked(newAtts, newStats));
    }
    
    //******************************************************
    //STAKING LOCK / UNLOCK FUNCTION
    //******************************************************
    function lockForStaking (uint16 tokenId) external {
        //Nom contract performs owner of check to prevent malicious locking
        require(msg.sender == _nomContractAddress,
            "Unauthorized");
        _lockedTokens[tokenId] = true;
    }
    
    function unlock (uint16 tokenId) external {
        //Nom contract performs owner of check to prevent malicious unlocking
        require(msg.sender == _nomContractAddress,
            "Unauthorized");
        _lockedTokens[tokenId] = false;
    }
    
    //******************************************************
    //L2 FUNCTIONALITY
    //******************************************************
    function setInactiveOnThisChain(uint16 tokenId) external {
        //This can only be called by the gateway contract to prevent exploits.
        //Gateway will check ownership, and setting inactive is a pre-requisite
        //to issuing the message to mint token on the other chain. By verifying
        //that we aren't trying to re-teleport here, we save back and forth to
        //check the activity status of the token on the gateway contract.
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        require(!_inactiveOnThisChain[tokenId],
            "Can't re-teleport!");
        
        //Unstake token to mitigate very minimal exploit by staking then immediately
        //briding to another layer to accrue slightly more tokens in a given time.
        uint16[] memory lockedTokens = new uint16[](1);
        lockedTokens[0] = tokenId;
        nom(_nomContractAddress).unstake(lockedTokens, applicationOwnerOf(tokenId));
        _inactiveOnThisChain[tokenId] = true;
    }
    
    function setActiveOnThisChain(uint16 tokenId, bytes memory metadata, address sender) external {
        require(msg.sender == _arbGateway,
            "Not Arb Gateway!");
        _inactiveOnThisChain[tokenId] = false;
        
        if(!_exists(uint256(tokenId))) {
            _safeMint(sender, tokenId);
        } else {
            address localOwner = applicationOwnerOf(tokenId);
            if (localOwner != sender) {
                //This indicates a transaction occurred
                //on the other layer. Transfer.
                safeTransferFrom(localOwner, sender, tokenId);
            }
        }
        
        metadataById[tokenId] = bytes32(metadata);
        
        uint16 burntId = uint16(bytes2(abi.encodePacked(metadata[14], metadata[15])));
        if (_exists(uint256(burntId))) {
            _burn(burntId);
        }
    }
    
    //******************************************************
    //MINT FUNCTIONS
    //******************************************************
    function _mintToken(address to, uint32 password) internal {
        //Add logic to create metadata here.
        _totalSupply += 1;
        _safeMint(to, _totalSupply);
        generateMetadata(to, _totalSupply, password); //Using password for metadata seed can add more fairness.
    }
    
    function publicAccessMint(uint8 numberOfTokens, bytes memory signature, bytes8 salt)
        public
        payable
    {        
        bytes32 txHash = hashTransaction(msg.sender, numberOfTokens, salt);
        
        require(_saleStarted,
            "Sale not live.");
        require(_usedSalt[salt] != true,
            "Used Salt!");
        require(matchAddresSigner(txHash, signature),
            "Unauthorized!");
        require((numberOfTokens + tokensMintedByAddress[msg.sender] <= _maxPerWallet),
            "Exceeded max mint.");
        require(msg.value >= totalMintPrice(numberOfTokens),
            "Insufficient funds.");
        
        for (uint i = 0; i < numberOfTokens; i++) {
             _mintToken(msg.sender, uint32(bytes4(signature))); //Using msg.sender because we are not interested in allowing mints through proxies.    
        }
        
        _usedSalt[salt] = true;
        tokensMintedByAddress[msg.sender] += numberOfTokens;
    }
    
    //******************************************************
    //BURN NOM FOR STAT BOOSTS
    //******************************************************
    function consume(uint16 consumer, uint256 burn) public {
        //We only check that a token is active on this chain.
        //You may burn NOM to boost friends' NFTs if you wish.
        require(!_inactiveOnThisChain[consumer],
            "Not active on this chain!");
        
        //Attempt to burn requisite amount of NOM. Will revert if
        //balance insufficient. This contract is approved burner
        //on NOM contract by default.
        nom(_nomContractAddress).burn(msg.sender, burn);
        
        //Snax contract will take a tokenId, retrieve critical stats
        //and then modify stats, primarily thiccness, based on total
        //tokens burned. Output bytes are written back to struct.
        bytes16 currentStats = serializeStats(consumer);
        bytes16 transformedStats = snax(_snaxContractAddress).feed(msg.sender, currentStats, burn);
        _writeSerializedStats(consumer, transformedStats);
    }
    
    //******************************************************
    //ATTACH ITEM
    //******************************************************
    function attach(uint16 base, uint16 consumableItem) public {
        //This function will call another function on the item
        //NFT contract which will burn an item, apply its properties
        //to the base NFT, and return these values.
        require(msg.sender == applicationOwnerOf(base),
            "Don't own this token"); //Owner of check performed in item contract
        require(!_inactiveOnThisChain[base],
            "Not active on this chain!");
            
        bytes32 transformedProperties = item(_itemContractAddress).applyProperties(metadataById[base], consumableItem);
        metadataById[base] = transformedProperties;
    }
    
    //******************************************************
    //NAME BUNZ
    //******************************************************
    function getNameTagPrice() public view returns(uint256) {
        return _nameTagPrice;
    }
    
    function name(uint16 tokenId, string memory newName) public {
        //This function will call another function on the item
        //NFT contract which will burn an item, apply its properties
        //to the base NFT, and return these values.
        require(msg.sender == applicationOwnerOf(tokenId),
            "Don't own this token"); //Owner of check performed in item contract
        require(!_inactiveOnThisChain[tokenId],
            "Not active on this chain!");
            
        //Attempt to burn requisite amount of NOM. Will revert if
        //balance insufficient. This contract is approved burner
        //on NOM contract by default.
        nom(_nomContractAddress).burn(msg.sender, _nameTagPrice);
            
        namedBunz[tokenId] = newName;
    }
    
    function getTokenName(uint16 tokenId) public view returns(string memory) {
        return namedBunz[tokenId];
    }
    
    //******************************************************
    //PRESTIGE SYSTEM
    //******************************************************
    function prestige(uint16[] memory tokenIds) public {
        //This is ugly, but the gas savings elsewhere justify this spaghetti.
        for(uint16 i = 0; i < tokenIds.length; i++) {
            if (uint8(metadataById[tokenIds[i]][17]) != _season) {
                bytes16 currentAtts = serializeAtts(tokenIds[i]);
                bytes12 currentStats = bytes12(metadataById[tokenIds[i]] << 160);
                
                //Atts and rank (byte 16) stay the same. Season (byte 17) and thiccness (bytes 18 and 19) change.
                metadataById[tokenIds[i]] = bytes32(abi.encodePacked(
                        currentAtts, metadataById[tokenIds[i]][16], bytes1(_season), bytes2(0), currentStats
                    ));
            }
        }
    }
    
    //******************************************************
    //EVOLUTION MECHANISM
    //******************************************************
    function evolve(uint16 firstToken, uint16 secondToken) public {
        //Add check to see if token is staked, if it is then unstake!
        uint8 rank1 = uint8(metadataById[firstToken][16]);
        uint8 rank2 = uint8(metadataById[secondToken][16]);
        uint8 season1 = uint8(metadataById[firstToken][17]);
        uint8 season = uint8(metadataById[secondToken][17]) > season1 ? uint8(metadataById[secondToken][17]) : season1;
        uint16 thiccness1 = uint16(bytes2(abi.encodePacked(metadataById[firstToken][18], metadataById[firstToken][19])));
        uint16 thiccness2 = uint16(bytes2(abi.encodePacked(metadataById[secondToken][18], metadataById[secondToken][19])));
        
        //ownerOf will return the 0 address if tokens are on another layer, or currently staked.
        //Forcing unstake before evolve does not add enough to gas fees to justify the complex
        //logic to gracefully handle token burn while staked without introducing possible attack
        //vectors.
        require(ownerOf(firstToken) == msg.sender && ownerOf(secondToken) == msg.sender, 
            "Not called by owner.");
        require((rank1 == rank2) && (rank1 < _maxRank),
            "Can't evolve these bunz");
        require(thiccness1 + thiccness2 >= _evolveThiccness[rank1],
            "Not thicc enough.");
        
        //Below logic uses the higher season of the two tokens, since otherwise
        //tying this to global season would allow users to earn 1/1s without
        //prestiging.
        uint8 next1of1 = (_1of1Index <= _1of1Allotted[season]) ? _1of1Index : 0;
        bytes32 evolvedToken = _evolver.evolve(next1of1, secondToken, metadataById[firstToken], metadataById[secondToken]);
        
        if (uint8(evolvedToken[8]) != 0) {
            _1of1Index++;
        }
        
        metadataById[firstToken] = evolvedToken;
        _burn(secondToken);
    }
}