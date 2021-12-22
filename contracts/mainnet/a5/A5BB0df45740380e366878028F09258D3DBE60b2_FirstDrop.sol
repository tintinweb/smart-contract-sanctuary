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

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ProtectedMint.sol";
import "./IOpenSeaProxy.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, ProtectedMint {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint16) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint16 => address) internal _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // OpenSea's proxy registry address
    address proxyRegistryAddress;

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
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, uint16(tokenId));
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[uint16(tokenId)];
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
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

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
     * @dev Sets OpenSea's proxy registry address
     */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
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
        address owner = ownerOf(tokenId);
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
    function _burn(uint16 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

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
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), uint16(tokenId));

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
    function _approve(address to, uint16 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./QueensAndKingsAvatars.sol";

contract FirstDrop is Ownable {
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    address public avatarContractAddress;
    address public signerAddress;
    address public sAddress;

    uint16 public sMintLimit = 300;
    uint16 public sMintedTokens = 0;

    uint16 public totalAvatars = 2000;
    uint256 public mintPrice = 0.423 ether;

    string public ipfsAvatars;

    mapping(uint16 => uint16) private tokenMatrix;
    mapping(address => uint8) public mintsPerUser;

    // DEBUG
    function setTotalAvatars(uint16 _totalAvatars) external onlyOwner {
        totalAvatars = _totalAvatars;
    }

    // ONLY OWNER

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the avatar contract address
     */
    function setAvatarContractAddress(address _address) external onlyOwner {
        avatarContractAddress = _address;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the address that can call mintTo
     */
    function setSAddress(address _sAddress) external onlyOwner {
        sAddress = _sAddress;
    }

    /**
     * @dev Sets how many mints can the sAddress do
     */
    function setSMintLimit(uint16 _sMintLimit) external onlyOwner {
        sMintLimit = _sMintLimit;
    }

    function setIPFSAvatars(string memory _ipfsAvatars) external onlyOwner {
        ipfsAvatars = _ipfsAvatars;
    }

    // END ONLY OWNER

    /**
     * @dev Mint function
     */
    function mint(
        uint8 _quantity,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint8 _maxQuantity,
        bytes calldata _signature
    ) external payable callerIsUser {
        bytes32 messageHash = generateMessageHash(msg.sender, _fromTimestamp, _toTimestamp, _maxQuantity);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);

        require(recoveredWallet == signerAddress, "Invalid signature for the caller");
        require(block.timestamp >= _fromTimestamp, "Too early to mint");
        require(block.timestamp <= _toTimestamp, "The signature has expired");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        uint256 tokensLeft = totalAvatars - tmpTotalSupply;
        require(tokensLeft > 0, "No tokens left to be minted");

        if (_quantity + mintsPerUser[msg.sender] > _maxQuantity) {
            _quantity = _maxQuantity - mintsPerUser[msg.sender];
        }

        if (_quantity > tokensLeft) {
            _quantity = uint8(tokensLeft);
        }

        uint256 totalMintPrice = mintPrice * _quantity;
        require(msg.value >= totalMintPrice, "Not enough Ether provided to mint");

        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        require(_quantity != 0, "Address mint limit reached");

        mintsPerUser[msg.sender] += _quantity;

        for (uint16 i; i < _quantity; i++) {
            uint16 _tokenId = _getTokenToBeMinted(tmpTotalSupply);
            qakContract.mint(_tokenId, msg.sender);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev mint to address
     */
    function mintTo(address[] memory _addresses) external {
        require(msg.sender == sAddress, "Caller is not allowed to mint");
        require(_addresses.length > 0, "At least one token should be minted");
        require(sMintedTokens + _addresses.length <= sMintLimit, "Mint limit reached");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        sMintedTokens += uint16(_addresses.length);
        for (uint256 i; i < _addresses.length; i++) {
            qakContract.mint(_getTokenToBeMinted(tmpTotalSupply), _addresses[i]);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev mint to address
     */
    function mintToDev(address[] memory _addresses) external onlyOwner {
        require(_addresses.length > 0, "At least one token should be minted");

        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);
        uint16 tmpTotalSupply = qakContract.totalSupply();

        uint256 tokensLeft = totalAvatars - tmpTotalSupply;
        require(tokensLeft > 0, "No tokens left to be minted");

        for (uint256 i; i < _addresses.length; i++) {
            qakContract.mint(_getTokenToBeMinted(tmpTotalSupply), _addresses[i]);
            tmpTotalSupply++;
        }
    }

    /**
     * @dev gets the amount of available tokens left to be minted
     */
    function getAvailableTokens() external view returns (uint16) {
        QueensAndKingsAvatars qakContract = QueensAndKingsAvatars(avatarContractAddress);

        return totalAvatars - qakContract.totalSupply();
    }

    /**
     * @dev Generates the message hash for the given parameters
     */
    function generateMessageHash(
        address _address,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        uint8 _maxQuantity
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n85",
                    _address,
                    _fromTimestamp,
                    _toTimestamp,
                    _maxQuantity
                )
            );
    }

    /**
     * @dev Returns a random available token to be minted
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens) private returns (uint16) {
        uint16 maxIndex = totalAvatars + sMintLimit - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];
        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0 ? tokenMatrix[random] = maxIndex - 1 : tokenMatrix[random] = tokenMatrix[
            maxIndex - 1
        ];

        // IDs start from 1 instead of 0
        return tokenId + 1;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens) private view returns (uint16) {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return (random % _upper);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITrait is IERC721 {
    function onTraitAddedToAvatar(uint16 _tokenId, uint16 _avatarId) external;

    function onAvatarTransfer(
        address _from,
        address _to,
        uint16 _tokenId
    ) external;

    function onTraitRemovedFromAvatar(uint16 _tokenId, address _owner) external;

    function traitToAvatar(uint16) external returns (uint16);

    function mint(uint256 _tokenId, address _to) external;

    function burn(uint16 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProtectedMint is Ownable {
    address[] public minterAddresses;

    modifier onlyMinter() {
        bool isAllowed;

        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == msg.sender) {
                isAllowed = true;

                break;
            }
        }

        require(isAllowed, "Minter: caller is not an allowed minter");

        _;
    }

    /**
     * @dev Adds an address that is allowed to mint
     */
    function addMinterAddress(address _minterAddress) external onlyOwner {
        minterAddresses.push(_minterAddress);
    }

    /**
     * @dev Removes
     */
    function removeMinterAddress(address _minterAddress) external onlyOwner {
        for (uint256 i; i < minterAddresses.length; i++) {
            if (minterAddresses[i] != _minterAddress) {
                continue;
            }

            minterAddresses[i] = minterAddresses[minterAddresses.length - 1];

            minterAddresses.pop();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol";
import "./ITrait.sol";

contract QueensAndKingsAvatars is ERC721 {
    using Strings for uint256;

    modifier onlyAvatarOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");

        _;
    }

    address public signerAddress;

    string public baseURI = "ipfs://HASH/";
    uint16 public totalTokens = 6900;
    uint16 public totalSupply = 0;
    uint256 public latestExternalTokenId = totalTokens + 1;

    address[] public traitTypeToAddress;

    // TokenId => Trait => TraitId
    mapping(uint16 => mapping(uint8 => uint16)) public avatarTraits;
    mapping(uint16 => bool) public hasMintedTraits;
    mapping(uint256 => uint16) public externalToInternalMapping;
    mapping(uint16 => uint256) public internalToExternalMapping;
    mapping(uint16 => bool) public frozenAvatars;

    bool isFreezeAllowed;

    constructor() ERC721("Queens+KingsAvatars", "Q+KA") {}

    // ONLY OWNER

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Adds the contract address of a trait type
     */
    function addTraitType(address _traitAddress) external onlyOwner {
        traitTypeToAddress.push(_traitAddress);
    }

    /**
     * @dev Adds the contract address of a trait type
     */
    function resetTraitTypes() external onlyOwner {
        delete traitTypeToAddress;
    }

    function setFreezedAllowed(bool _isFreezeAllowed) external onlyOwner {
        isFreezeAllowed = _isFreezeAllowed;
    }

    // END ONLY OWNER

    // ONLY MINTER

    /**
     * @dev Mints a avatars
     */
    function mint(uint16 _tokenId, address _to) external onlyMinter {
        require(_tokenId > 0 && _tokenId <= totalTokens, "Token ID cannot be 0");
        require(totalSupply < totalTokens, "Cannot mint more avatars");

        externalToInternalMapping[_tokenId] = _tokenId;
        internalToExternalMapping[_tokenId] = _tokenId;

        totalSupply++;

        _mint(_to, _tokenId);
    }

    // END ONLY MITNER

    // ONLY AVATAR OWNER

    /**
     * @dev Adds full traits to an avatar
     */
    function setTraitsToAvatar(uint256 _tokenId, uint16[] memory _traits) external onlyAvatarOwner(_tokenId) {
        require(traitTypeToAddress.length == _traits.length, "Invalid amount of traits");
        uint16 _iTokenId = getInternalMapping(_tokenId);
        require(hasMintedTraits[_iTokenId], "Can not modify avatar until original traits are minted");

        require(!frozenAvatars[_iTokenId], "Can not change the traits of a frozen avatar");

        bool regenerate;
        uint256[] memory traitsPreviousAvatar = new uint256[](_traits.length);
        uint256 regeneratePreviousAvatarCounter;

        for (uint8 i; i < _traits.length; i++) {
            if (_traits[i] == avatarTraits[_iTokenId][i]) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);

            require(_traits[i] == 0 || trait.ownerOf(_traits[i]) == msg.sender, "Caller is not the owner of the trait");

            uint16 newTraitCurrentAvatarId = trait.traitToAvatar(_traits[i]);

            if (newTraitCurrentAvatarId != 0 && newTraitCurrentAvatarId != _iTokenId) {
                avatarTraits[newTraitCurrentAvatarId][i] = 0;

                traitsPreviousAvatar[regeneratePreviousAvatarCounter] = getExternalMapping(newTraitCurrentAvatarId);

                regeneratePreviousAvatarCounter++;
            }

            if (avatarTraits[_iTokenId][i] != 0) {
                regenerate = true;
                trait.onTraitRemovedFromAvatar(avatarTraits[_iTokenId][i], ownerOf(_tokenId));
            }

            avatarTraits[_iTokenId][i] = _traits[i];

            if (_traits[i] != 0) {
                trait.onTraitAddedToAvatar(_traits[i], _iTokenId);
            }
        }

        for (uint256 i; i < regeneratePreviousAvatarCounter; i++) {
            if (_exists(traitsPreviousAvatar[i])) {
                regenerateAvatar(traitsPreviousAvatar[i]);
            }
        }

        if (regenerate) {
            regenerateAvatar(_tokenId);
        }
    }

    /**
     * @dev mints the traits for a given avatar
     */
    function mintTraits(
        uint16 _tokenId,
        uint16[] memory _traits,
        bytes calldata _signature
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");
        require(_tokenId <= totalTokens, "Invalid token Id");
        require(!hasMintedTraits[_tokenId], "Traits already minted");

        bytes32 messageHash = generateMessageHash(_tokenId, _traits);
        address recoveredWallet = ECDSA.recover(messageHash, _signature);
        require(recoveredWallet == signerAddress, "Invalid signature for the caller");

        hasMintedTraits[_tokenId] = true;

        for (uint8 i; i < _traits.length; i++) {
            if (_traits[i] == 0) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);
            trait.mint(_traits[i], msg.sender);

            avatarTraits[_tokenId][i] = _traits[i];

            trait.onTraitAddedToAvatar(_traits[i], _tokenId);
        }
    }

    function freeze(uint256 _tokenId) external {
        require(isFreezeAllowed, "Cannot freeze at this stage");
        uint16 _iTokenId = getInternalMapping(_tokenId);

        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the avatar");
        require(hasMintedTraits[_iTokenId], "Traits have not been minted");
        require(!frozenAvatars[_iTokenId], "Avatar is already frozen");

        frozenAvatars[_iTokenId] = true;

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (avatarTraits[_iTokenId][i] == 0) {
                continue;
            }

            ITrait trait = ITrait(traitTypeToAddress[i]);
            trait.burn(avatarTraits[_iTokenId][i]);
        }
    }

    // END ONLY AVATAR OWNER

    // ONLY TRAIT CONTRACTS

    /**
     * @dev removes a single trait from an avatar
     * by it's contract type
     */
    function removeTrait(uint16 _iTokenId) external {
        require(!frozenAvatars[_iTokenId], "Avatar is already frozen");
        bool found;

        uint256 _tokenId = getExternalMapping(_iTokenId);

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (traitTypeToAddress[i] == msg.sender) {
                avatarTraits[getInternalMapping(_tokenId)][i] = 0;
                found = true;

                break;
            }
        }

        require(found, "Caller is not allowed");

        regenerateAvatar(_tokenId);
    }

    // END ONLY TRAIT CONTRACTS

    // CUSTOM ERC721

    /**
     * @dev See {ERC721}.
     *
     * Calls avatarTransfer for all the traits that the avatar has
     * in order to emit the transfer event for all the traits
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        uint16 _iTokenId = getInternalMapping(tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), uint16(tokenId));

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_iTokenId] = to;

        emit Transfer(from, to, tokenId);

        for (uint8 i; i < traitTypeToAddress.length; i++) {
            if (avatarTraits[_iTokenId][i] == 0) {
                continue;
            }

            ITrait traitContract = ITrait(traitTypeToAddress[i]);
            traitContract.onAvatarTransfer(from, to, avatarTraits[_iTokenId][i]);
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        uint16 _iTokenId;
        if (tokenId > totalTokens) {
            _iTokenId = getInternalMapping(tokenId);
        } else {
            _iTokenId = uint16(tokenId);
        }

        address owner = _owners[_iTokenId];
        require(owner != address(0), "ERC721 Avatar: owner query for nonexistent token");

        return owner;
    }

    /**
     * @dev See {IRC721-_exists}.
     */
    function _exists(uint256 tokenId) internal view override returns (bool) {
        uint16 _iTokenId = externalToInternalMapping[tokenId];

        return _owners[_iTokenId] != address(0);
    }

    /**
     * @dev See {ERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[getInternalMapping(tokenId)];
    }

    /**
     * @dev See {ERC721-_approve}.
     */
    function _approve(address to, uint16 tokenId) internal virtual override {
        _tokenApprovals[getInternalMapping(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // END CUSTOM ERC721

    /**
     * @dev Returns the traits for the given token id
     */
    function getAvatarTraits(uint256 _tokenId) external view returns (uint16[] memory) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");

        uint16 _iTokenId = getInternalMapping(_tokenId);

        uint16[] memory traits = new uint16[](traitTypeToAddress.length);
        for (uint8 i; i < traitTypeToAddress.length; i++) {
            traits[i] = avatarTraits[_iTokenId][i];
        }

        return traits;
    }

    // INTERNAL

    /**
     * @dev to avoid users receiving offers for their complete avatars, removing
     * the parts and accepting the offers; The NFT changes ID every time a part is removed
     * or replaced
     */
    function regenerateAvatar(uint256 _tokenId) internal returns (uint256) {
        address _owner = ownerOf(_tokenId);

        emit Transfer(_owner, address(0), _tokenId);
        emit Transfer(address(0), _owner, latestExternalTokenId);

        uint16 _iTokenId = getInternalMapping(_tokenId);

        externalToInternalMapping[latestExternalTokenId] = _iTokenId;
        internalToExternalMapping[_iTokenId] = latestExternalTokenId;

        delete externalToInternalMapping[_tokenId];

        latestExternalTokenId++;

        return latestExternalTokenId - 1;
    }

    /**
     * @dev returns the original id for the given avatar
     */
    function getInternalMapping(uint256 _tokenId) internal view returns (uint16) {
        require(externalToInternalMapping[_tokenId] != 0, "getInternalMapping: Invalid mapping");

        return externalToInternalMapping[_tokenId];
    }

    /**
     8 @dev returns the external id for the original given id
     */
    function getExternalMapping(uint16 _iTokenId) internal view returns (uint256) {
        require(internalToExternalMapping[_iTokenId] != 0, "getExternalMapping: Invalid mapping");

        return internalToExternalMapping[_iTokenId];
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Generate a message hash for the given parameters
     */
    function generateMessageHash(uint256 _avatarId, uint16[] memory _traitIds) internal pure returns (bytes32) {
        uint256 signatureBytes = 32 + _traitIds.length * 32;

        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n", signatureBytes.toString(), _avatarId, _traitIds)
            );
    }
}