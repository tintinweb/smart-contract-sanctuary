/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// File: contracts/AnonymiceLibrary.sol


pragma solidity ^0.8.2;

library AnonymiceLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

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
}
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: contracts/ERC721A.sol


// Creators: locationtba.eth, 2pmflow.eth

pragma solidity ^0.8.0;









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;
  uint256 private currentChildIndex = 1025;
  uint256 private burnedCount = 0;

  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return totalGenesisSupply() + totalChildSupply();
  }

  function totalGenesisSupply() public view returns (uint256) {
    return currentIndex;
  }

  function totalChildSupply() public view returns (uint256) {
    return currentChildIndex - 1025 - burnedCount;
  }

  function burn() internal {
    burnedCount++;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalGenesisSupply() || (index >= 1025 && index < totalChildSupply() + 1025) , "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    address currOwnershipAddr = address(0);
    uint256 tokenIdsIdx = 0;
    for(uint8 j = 0; j < 2; j++) {
      uint256 numMintedSoFar = j < 1 ? totalGenesisSupply() : totalChildSupply() + 1025 + burnedCount;
      for (uint256 i = j < 1 ? 0 : 1025; i < numMintedSoFar; i++) {
        TokenOwnership memory ownership = _ownerships[i];
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == owner) {
          if (tokenIdsIdx == index) {
            return i;
          }
          tokenIdsIdx++;
        }
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
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
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex || tokenId >= 1025 && tokenId < currentChildIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    bool child = _data.length > 0;
    uint256 startTokenId = child ? currentChildIndex : currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity, _data);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = child ? currentIndex : updatedIndex;
    currentChildIndex = child ? updatedIndex : currentChildIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
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
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1, "");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > currentIndex - 1) {
      endIndex = currentIndex - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
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
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity,
    bytes memory data
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// File: contracts/nodes.sol


pragma solidity ^0.8.2;





/// @custom:security-contact [email protected]
contract Nodes is ERC721A, Ownable {
    using AnonymiceLibrary for uint8;

    struct Trait {
        string traitName;
        string traitType;
    }

    // Mint enable
    bool public MINT_ENABLE = false;

    // Should be set with functions.
    string private p5Url;
    string private p5Integrity;
    string private pakoUrl;
    string private pakoIntegrity;
    string private imageUrl;
    string private animationUrl;
    string private gzip;
    string private description;

    string private constant traitType = "{\"trait_type\":\"";
    string private constant traitValue = "\",\"value\":\"";
    string private constant terminator = "\"}";
    uint8[9] private seq = [2, 2, 1, 1, 1, 2, 1, 1, 1];
    uint8[9] private costs = [0,3,4,0,5,3,4,0,5];
    uint8 private constant fuseCost = 2;
    uint private constant ONE_DAY = 86400; // in secs
    uint8 private constant TRAIT_COUNT = 5;
    uint8 private constant PADDED_TRAIT_COUNT = 2;

    uint private immutable TRAIT_TOKEN_EPOCH = 20;//ONE_DAY;
    uint private immutable FUSE_COOLDOWN = 60;//ONE_DAY * 3;
    uint private immutable PRICE;
    uint16 public immutable GENISIS_CAP;
    bytes32 public generalMerkleRoot;
    bytes32 public devMerkleRoot;
    uint16 public immutable CHILD_CAP;
    
    // Nonce used to salt hash string
    uint256 private seedNonce = 0;
    // n options per trait.
    uint16[][TRAIT_COUNT] private rarityTree;

    // Expensive Mappings delete this if you can.
    mapping(address => uint) private addrToMintedQ;
    mapping(string => bool) private hashToMinted;
    mapping(uint => string) private tokenIdToHash;
    mapping(uint => uint) private tokenIdToTimestamp;
    mapping(uint => uint) private tokenIdToCooldown;
    mapping(uint => uint) private tokenIdToSpent;
    mapping(uint256 => Trait[]) private traitTypes;

    // team mints
    uint8 public teamMints = 0;


    constructor(bytes32 _generalMerkleRoot, bytes32 _devMerkleRoot, uint16 genesisCap) ERC721A("NODES", "NODE", 2) {
        // Palette
        rarityTree[0] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 500, 500];
        // Connectivity (N/R) - 1&2
        rarityTree[1] = [1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 1000, 500, 500];
        // Node Size - 1&2
        rarityTree[2] = [1000, 8000, 1000];
        // Symmetry
        rarityTree[3] = [4000, 4000, 2000];
        // Node Type - 1&2
        rarityTree[4] = [1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100, 1200];
        generalMerkleRoot = _generalMerkleRoot;
        devMerkleRoot = _devMerkleRoot;
        // price in Wei, this is 0.05 ETH.
        PRICE = 50000000000000000;
        GENISIS_CAP = genesisCap;
        CHILD_CAP = genesisCap * 2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier noContract() {
        require(!AnonymiceLibrary.isContract(msg.sender), "c0");
        _;
    }

    /**
    ______  ___ _____ ___      ___   _______ _____    
    |  _  \/ _ \_   _/ _ \    / / | | | ___ \_   _|   
    | | | / /_\ \| |/ /_\ \  / /| | | | |_/ / | | ___ 
    | | | |  _  || ||  _  | / / | | | |    /  | |/ __|
    | |/ /| | | || || | | |/ /  | |_| | |\ \ _| |\__ \
    |___/ \_| |_/\_/\_| |_/_/    \___/\_| \_|\___/___/                                           
    */

    /**
     * @dev Hash to HTML function
     */
    function tokenHTML(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        _exists(tokenId);
        return string(
            abi.encodePacked(
                'data:text/html,%3Chtml%3E%3Chead%3E%3Cscript%20src%3D%22',
                p5Url,
                '%22%20integrity%3D%22',
                p5Integrity,
                '%22%20crossorigin%3D%22anonymous%22%20referrerpolicy%3D%22no-referrer%22%3E%3C%2Fscript%3E%3Cscript%20src%3D%22',
                pakoUrl,
                '%22%20integrity%3D%22',
                pakoIntegrity,
                '%22%20crossorigin%3D%22anonymous%22%20referrerpolicy%3D%22no-referrer%22%3E%3C%2Fscript%3E%3C%2Fhead%3E%3C%2Fbody%3E%3Cscript%3Econst%20h%20%3D%20%27',
                tokenIdToHash[tokenId],
                '%27%3B%20const%20g%20%3D%20%27',
                gzip,
                '%27%3B%20const%20e%20%3D%20Function(%27%22use%20strict%22%3Breturn%20(%27%20%2B%20pako.inflate(new%20Uint8Array(atob(g).split(%27%27).map(function(x)%7Breturn%20x.charCodeAt(0)%3B%20%7D))%2C%20%7B%20to%3A%20%27string%27%20%7D)%2B%20%27)%27)()%3B%20new%20p5(e.nodes%2C%20%27nodes%27)%3B%20%3C%2Fscript%3E%3Cdiv%20id%3D%22nodes%22%20name%3D%22nodes%22%3E%3C%2Fdiv%3E%3C%2Fbody%3E'
            )
        );
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    "{\"name\": \"NODES #",
                                    AnonymiceLibrary.toString(_tokenId),
                                    "\",\"description\": \"",
                                    description,
                                    "\",\"animation_url\": \"",
                                    animationUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    "\",\"image\": \"",
                                    imageUrl,
                                    AnonymiceLibrary.toString(_tokenId),
                                    "\",\"attributes\": ",
                                    hashToMetadata(getTokenHash(_tokenId)),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
    ___  ________ _   _ _____ _____ _   _ _____ 
    |  \/  |_   _| \ | |_   _|_   _| \ | |  __ \
    | .  . | | | |  \| | | |   | | |  \| | |  \/
    | |\/| | | | | . ` | | |   | | | . ` | | __ 
    | |  | |_| |_| |\  | | |  _| |_| |\  | |_\ \
    \_|  |_/\___/\_| \_/ \_/  \___/\_| \_/\____/                                          
    */
    function mintNodes(uint256 quantity, bytes32[] calldata merkleProof) public payable noContract {
        require(msg.value >= PRICE * quantity,"m1");
        mint(quantity, merkleProof, false); 
    }

    function mintNodesTeam(uint256 quantity, bytes32[] calldata merkleProof) public noContract {
        mint(quantity, merkleProof, true);
    }

    function mint(uint256 quantity, bytes32[] calldata merkleProof, bool isTeamMint) private {
        uint8 limit = isTeamMint ? 12 : 2;
        require(addrToMintedQ[msg.sender] + quantity <= limit, "m2");
        require((totalGenesisSupply() + quantity) <= (GENISIS_CAP + teamMints), "m3");
        require(MerkleProof.verify(merkleProof, isTeamMint ? devMerkleRoot : generalMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "m4");
        seedNonce++;
        _safeMint(msg.sender, quantity);
        if(isTeamMint) {
            teamMints += uint8(quantity);
        }
        addrToMintedQ[msg.sender] += quantity;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory data
    ) internal override {
        if(from == address(0)) {
            if(data.length > 0) {
                // THIS IS NOT A BATCH CAPABLE FUNCTION BECAUSE FUSING DOES NOT SUPPORT THIS
                require(quantity == 1, "btt0");
                tokenIdToHash[startTokenId] = string(data);
            } else {
                // This is batch capabable.
                string memory hashi = hash(startTokenId, to, 0, uint8(quantity));
                for(uint i = 0; i < quantity; i++) {
                    tokenIdToHash[startTokenId + i] = string(abi.encodePacked(AnonymiceLibrary.substring(hashi, 0 + i*12, 12 + i*12),"0"));
                }
            }
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
      // Nuke token counters
      for(uint i = 0; i < quantity; i++) {
          tokenIdToTimestamp[startTokenId + i] = block.timestamp;
          tokenIdToSpent[startTokenId + i] = 0;
          tokenIdToCooldown[startTokenId + i] = block.timestamp + FUSE_COOLDOWN;
      }
    }

    /**
    ______ _   _ _____ _____ _   _ _____ 
    |  ___| | | /  ___|_   _| \ | |  __ \
    | |_  | | | \ `--.  | | |  \| | |  \/
    |  _| | | | |`--. \ | | | . ` | | __ 
    | |   | |_| /\__/ /_| |_| |\  | |_\ \
    \_|    \___/\____/ \___/\_| \_/\____/
    */
    function fuse(
        uint256 tokenId0,
        uint256 tokenId1,
        int8[9] memory phenotype,
        uint256 tokenCostPreference
    ) public noContract {
        // Error messages require code data :(
        require(ownerOf(tokenId0) == ownerOf(tokenId1), "f1");
        require(tokenId0 != tokenId1, "f2");
        require(getRemainingCooldown(tokenId0) <= 0 && getRemainingCooldown(tokenId1) <= 0, "f3");
        string memory h1 = getTokenHash(tokenId0);
        string memory h2 = getTokenHash(tokenId1);

        // Phenotype = [0,1,0,...,1]
        //           = [p1,p2,p1,...,p2]]
        string memory out;
        uint8 curr = 0;
        uint8 cost = fuseCost;

        for(uint i = 0; i < phenotype.length; i++) { 
            if(phenotype[i] == -2) {
                out = string(abi.encodePacked(out, AnonymiceLibrary.substring(h1, curr, curr + seq[i])));
            } else if(phenotype[i] == -1) {
                out = string(abi.encodePacked(out, AnonymiceLibrary.substring(h2, curr, curr + seq[i])));
            } else {
                // you cannot set 0 color, 3 sym1, 7 sym2
                require(phenotype[i] >= 0 && i != 0 && i != 3 && i != 7, "f4");
                // 0, 1, 2, 3, 4, 1, 2, 3, 4
                // safe to convert to unsigned type as we already checked bounds above.
                require(uint8(phenotype[i]) < rarityTree[i < 5 ? i : i - 4].length, "f5");
                cost += costs[i];
                uint8 rar = uint8(phenotype[i]);
                out = string(
                    abi.encodePacked(out, string(abi.encodePacked((rar <= 9 && seq[i] == 2) ? "0" : "", rar.toString())))
                );
            }
            curr += seq[i];
        }

        uint8 bal0 = uint8(getTraitTokenBalance(tokenId0));
        uint8 bal1 = uint8(getTraitTokenBalance(tokenId1));
        uint8 t0spend;
        uint8 t1spend;
        require(bal0 + bal1 >= cost, "f6");
        if(tokenCostPreference == tokenId0) {
            t0spend = cost > bal0 ? bal0 : cost;
            t1spend = cost > t0spend ? cost - t0spend : 0;
        } else {
            t1spend = cost > bal1 ? bal1 : cost;
            t0spend = cost > t1spend ? cost - t1spend : 0;
        }
        tokenIdToSpent[tokenId0] += t0spend;
        tokenIdToSpent[tokenId1] += t1spend;
        _safeMint(msg.sender, 1, abi.encodePacked(out, "1"));
        burnIfChild(tokenId0, h1);
        burnIfChild(tokenId1, h2);
        // It would be much better if this could fail fast.
        require(totalChildSupply() <= CHILD_CAP, "f7");
    }

    function burnIfChild(uint256 tokenId, string memory h1) private {
        if(AnonymiceLibrary.parseInt(AnonymiceLibrary.substring(h1, bytes(h1).length - 1, bytes(h1).length)) != 0) {
            safeTransferFrom(msg.sender, address(0xdead), tokenId);
            burn();
            // cooldown happens via transfer, also it doesn't matter since its dead.
        } else {
            tokenIdToCooldown[tokenId] = block.timestamp + FUSE_COOLDOWN;
        }
    }


    /**
    ______           _ _       _____             
    | ___ \         (_) |     |_   _|            
    | |_/ /__ _ _ __ _| |_ _   _| |_ __ ___  ___ 
    |    // _` | '__| | __| | | | | '__/ _ \/ _ \
    | |\ \ (_| | |  | | |_| |_| | | | |  __/  __/
    \_| \_\__,_|_|  |_|\__|\__, \_/_|  \___|\___|
                            __/ |                
                            |___/                    
    */

    /**
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        private
        view
        returns (uint8)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < rarityTree[_rarityTier].length; i++) {
            uint16 thisPercentage = rarityTree[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }
        revert("r1");
    }

    /**
     * @dev Generates a 12*q digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint8 q
    ) private view returns (string memory) {
        require(q <= 4, "h1");
        string memory currentHash;
        string memory out;
        uint8 draws = 0;
        uint8 selected = 0;
        uint256 bigRand =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            seedNonce
                        )
                    )
                );

        do {
            for (uint8 i = 0; i < TRAIT_COUNT; i++) {
                uint16 _randinput = uint16(bigRand >>= 8) % 10000;
                uint8 rar = rarityGen(_randinput, i);
                currentHash = string(
                    abi.encodePacked(currentHash, string(abi.encodePacked((rar <= 9 && i <= 1) ? "0" : "", rar.toString())))
                );
            }

            if(!hashToMinted[currentHash]) {
                selected++;
                // Set the secondary hash for breeding.
                uint8 offset = 2;
                out = string(
                    abi.encodePacked(out, currentHash, AnonymiceLibrary.substring(currentHash, offset, TRAIT_COUNT + offset))
                );
            }
            currentHash = "";
            draws++;
            if(draws >= 6) {
                revert("h1");
            }
        } while (selected < q);

        // If its ever been drawn before, then hash again to find another choice, note this is recursive.
        //TODO: This should be moved to a do while one level higher, recursion and eth do not go well together.
        //if (hashToMinted[currentHash]) return hash(_t, _a, _c + 1);
        return out;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        private
        view
        returns (string memory)
    {
        uint8 curr = 0;
        string memory metadataString;
        for(uint8 i = 0; i < seq.length; i++) {
            uint8 idx = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, curr, curr + seq[i])
            );
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    traitType,
                    abi.encodePacked(traitTypes[i > 4 ? i - 4 : i][idx].traitType, i > 4 ? "2" : ""),
                    traitValue,
                    traitTypes[i > 4 ? i - 4 : i][idx].traitName,
                    terminator,
                    i == seq.length - 1 ? "" : ","
                )
            );
            curr += seq[i];
        }
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     _____      _   _              _______      _   _            
    |  __ \    | | | |            / /  ___|    | | | |           
    | |  \/ ___| |_| |_ ___ _ __ / /\ `--.  ___| |_| |_ ___ _ __ 
    | | __ / _ \ __| __/ _ \ '__/ /  `--. \/ _ \ __| __/ _ \ '__|
    | |_\ \  __/ |_| ||  __/ | / /  /\__/ /  __/ |_| ||  __/ |   
    \____/\___|\__|\__\___|_|/_/   \____/ \___|\__|\__\___|_|                                                        
    */

    /**
     * @dev Toggles minting, so it can be start/stopped by the contract owner.
     */
    function toggleMint() public onlyOwner {
        MINT_ENABLE = !MINT_ENABLE;
    }

    function getTraitTokenBalance(uint256 tokenId) public view returns(uint) {
        _exists(tokenId);
        return ((block.timestamp - tokenIdToTimestamp[tokenId]) / TRAIT_TOKEN_EPOCH) - tokenIdToSpent[tokenId];
    }

    function getRemainingCooldown(uint256 tokenId) public view returns (uint) {
        _exists(tokenId);
        return block.timestamp > tokenIdToCooldown[tokenId] ? 0 : tokenIdToCooldown[tokenId] - block.timestamp;
    }

    /**
     * @dev Gets the hash for an existing token.
     */
    function getTokenHash(uint256 tokenId) public view returns (string memory) {
        _exists(tokenId);
        return tokenIdToHash[tokenId];
    }

    /**
     * @dev Add a trait type
     * @param _traitTypeIndex The trait type index
     * @param traits Array of traits to add
     */
    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(
                    traits[i].traitName,
                    traits[i].traitType
                )
            );
        }
        return;
    }

    /**
     * @dev Sets the p5.js mirroring URL - this can be changed if cloudflare ever disappears.
     * @param _p5Url The address of the p5.js file hosted on CDN (URL encoded).
     */

    function setp5Address(string memory _p5Url) public onlyOwner {
        p5Url = _p5Url;
    }

    /**
     * @dev Sets the SHA-512 hash of the p5.js library hosted on the CDN.
     * @param _p5Integrity The SHA-512 Hash of the p5.js library.
     */
    function setp5Integrity(string memory _p5Integrity) public onlyOwner {
        p5Integrity = _p5Integrity;
    }

    /**
     * @dev Sets the pako.js mirroring URL - this can be changed if cloudflare ever disappears.
     * @param _pakoUrl The address of the p5.js file hosted on CDN (URL encoded).
     */

    function setPakoAddress(string memory _pakoUrl) public onlyOwner {
        pakoUrl = _pakoUrl;
    }

    /**
     * @dev Sets the SHA-512 hash of the p5.js library hosted on the CDN.
     * @param _pakoIntegrity The SHA-512 Hash of the p5.js library.
     */
    function setPakoIntegrity(string memory _pakoIntegrity) public onlyOwner {
        pakoIntegrity = _pakoIntegrity;
    }

    /**
     * @dev Sets the B64 encoded Gzipped source string for HTML mirroring.
     * @param _b64Gzip the B64 encoded Gzipped source string for HTML mirroring.
     */
    function setGzipSource(string memory _b64Gzip) public onlyOwner {
        gzip = _b64Gzip;
    }
    
    /**
     * @dev Sets the base image url, this will be the Nodes API, and will be replaced by a static IPFS resource
     * after mint, so the API can be retired.
     * @param _imageUrl The URL of the image API or the IPFS static resource (URL encoded).
     */
    function setImageUrl(string memory _imageUrl) public onlyOwner {
        imageUrl = _imageUrl;
    }
    
    /**
     * @dev Sets the base animation url, this will be an IPFS hosted version of the API to render the Nodes
     * artwork without needing to hit the mirrored HTML endpoint which OpenSea can't do yet.
     * @param _animationUrl The URL of the Nodes viewer hosted on IPFS.
     */
    function setAnimationUrl(string memory _animationUrl) public onlyOwner {
        animationUrl = _animationUrl;
    }

    /**
     * @dev Sets the description returned in the tokenURI.
     */
    function setDescription(string memory _description) public onlyOwner {
        description = _description;
    }

    /**
     * @dev Clears all set traits. Note these can also just be overwritten since its tied to a mapping.
     */
    function clearTraits() public onlyOwner {
        for (uint8 i = 0; i < TRAIT_COUNT; i++) {
            delete traitTypes[i];
        }
    }

    /**
     * @dev Sets the general and team merkle roots. Only for testing.
     */
    function setMerkelRoots(bytes32 _generalMerkleRoot, bytes32 _devMerkleRoot) public onlyOwner {
        generalMerkleRoot = _generalMerkleRoot;
        devMerkleRoot = _devMerkleRoot;
    }
}