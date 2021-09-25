/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// File: contracts/MetadataUtils.sol

pragma solidity ^0.8.0;

function toString(uint256 value) pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
// File: contracts/Context.sol



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
// File: contracts/Ownable.sol

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
// File: contracts/ReentrancyGuard.sol

pragma solidity ^0.8.0;


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
// File: contracts/IERC165.sol



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

// File: contracts/IERC1155.sol



pragma solidity ^0.8.0;


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

// File: contracts/IERC721.sol



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
// File: contracts/IERC721Enumerable.sol



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
// File: contracts/ERC165.sol



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

// File: contracts/Address.sol



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
// File: contracts/IERC1155MetadataURI.sol



pragma solidity ^0.8.0;


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
// File: contracts/IERC1155Receiver.sol



pragma solidity ^0.8.0;


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

// File: contracts/ERC1155.sol



pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

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
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
// File: contracts/Skills.sol
//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Skills is ERC1155, ReentrancyGuard, Ownable {
    // first 4 are Epic, second 4 are Rare, remaining are Common
	string[] private meleeAttacks = [
		"Mortal Wound", // 0
		"Heart Thrust", // 1
		"Berserker", // 2
		"Killing Spree", // 3
		"Rage of the Ape", // 4
		"Spinal Slice", // 5
		"Death Blow", // 6
		"Ocular Slash ", // 7
		"Grasp of the Kraken", // 8
		"Heroic Strike", // 9
		"Sweep", // 10
		"Backstab", // 11
		"Silent Strike", // 12
		"Skull Bash", // 13
		"Garrote", // 14
		"Mutilating Blow", // 15
		"Tiger Maul", // 16
		"Rune Strike", // 17
		"Cleave", // 18
		"Dragon Tail Swipe", // 19
		"Punch in the Mouth" // 20
	];

	string[] private rangeAttacks = [
		"Multishot", // 0
		"Kill Shot", // 1
		"Shot Through The Heart", // 2
		"Hit and Run", // 3
		"Blot Out the Sun", // 4
		"Barrage of Bullets", // 5
		"Ancestral Arrow", // 6
		"Arrow of Armageddon", // 7
		"Double Strafe", // 8
		"Poison Arrow", // 9
		"Tranquilizing Dart", // 10
		"Frost Shot", // 11
		"Burning Arrow", // 12
		"Blinding Bolt", // 13
		"Degenerate Dart", // 14
		"Shaft of Glory" // 15
	];

    string[] private elementalSpells = [
        "Meteor", // 0
        "Earthquake", // 1
        "Ball Lightning", // 2
        "Blizzard", // 3
        "Cataclysm", // 4
        "Maelstrom Bolt", // 5
        "Black Dragon Breath", // 6
        "Comet Strike", // 7
        "Fireball", // 8
        "Firewall", // 9
        "Firestorm", // 10
        "Dragon Breath", // 11
        "Ice Spear", // 12
        "Frost Touch", // 13
        "Frozen Heart", // 14
        "Frost Cone", // 15
        "Electric Personality", // 16
        "Lightning Strike", // 17
        "Chain Lightning", // 18
        "Electric Boogaloo", // 19
        "Landslide", // 20
        "Sinking Sand", // 21
        "Earth Spike", // 22
        "Drowning Deluge" // 23
    ];

	string[] private spiritualSpells = [
		"Searing Sun", // 0
		"Divine Indignation", // 1
		"Death and Decay", // 2
		"Hurricane of the Mother", // 3
		"Divine Retribution", // 4
		"Demonic Despair", // 5
		"Praise The Sun", // 6
		"Pandemonium", // 7
		"Light of the Moon", // 8
		"Spear of Brilliance", // 9
		"Raise Dead", // 10
		"Seraph Smite", // 11
		"Soul Arrow", // 12
		"Arrow of Evil", // 13
		"Bolt of Rage", // 14
		"Wroth of the Mother", // 15
		"Devilish Deed", // 16
		"Demon Soul" // 17
	];

	string[] private curses = [
		"Doom", // 0
		"Regress to the Mean", // 1
		"Curse of the Winner", // 2
		"Not Gonna Make It", // 3
		"Plague of Frogs", // 4
		"Curse of the Ape", // 5
		"Bad Morning", // 6
		"Demise of the Degenerate", // 7
		"Touch of Sorrow", // 8
		"Curse of Down Bad", // 9
		"Kiss of Death", // 10
		"Blight of the Moon", // 11
		"Morbid Sun", // 12
		"Torment of Titans", // 13
		"Agonizing Gaze", // 14
		"Change of Heart", // 15
		"Curse of Anger" // 16
	];

    string[] private heals = [
        "Divine Touch", // 0
        "Soul Glow", // 1
        "Time Heals All Wounds", // 2
        "Innervate", // 3
        "Infectious Heal", // 4
        "Raise the Dead", // 5
        "Healed and Shield", // 6
        "You're Gonna Make It", // 7
        "Healing Touch", // 8
        "Restoring Wind", // 9
        "Healing Current", // 10
        "Wellspring", // 11
        "Reviving Touch", // 12
        "Rejuvenating Surge" // 13
    ];
      
	string[] private buffs = [
		"We're All Gonna Make It", // 0
		"Vigor of the Twins", // 1
		"Fury of the Ape", // 2
		"Invigorating Touch", // 3
		"Frozen Touch", // 4
		"Blessing of Good Morning", // 5
		"Ancient Vitriol", // 6
		"Luck and Leverage", // 7
		"Dragonskin", // 8
		"Sight of Enlightenment", // 9
		"Wind In Your Back", // 10
		"Fury of Giants", // 11
		"Song of Power", // 12
		"Cleverness of the Fox", // 13
		"Strength of Vengeance", // 14
		"Wind Walker", // 15
		"Scent of Blood", // 16
		"Thick Skin", // 17
		"Hymn of Protection", // 18
		"Blessing of Light", // 19
		"Iron Flesh" // 20
	];

	string[] private defensiveSkills = [
		"Haste of the Fox", // 0
		"Blessing of Protection", // 1
		"Vanish", // 2
		"Sacrifice of the Martyr", // 3
		"Evasive Maneuver", // 4
		"Perfect Roll", // 5
		"Taunt 'Em All", // 6
		"Determination of a Degenerate", // 7
		"Dodge", // 8
		"Protect", // 9
		"Taunt", // 10
		"Feign Death", // 11
		"Counter", // 12
		"Shield Block" // 13
	];

	string[] private namePrefixes = [
		"", // 0
		"Dom", // 1
		"Hoffman", // 2
		"Nish", // 3
		"Nuge", // 4
		"Orgeos", // 5
		"Looter", // 6
		"Italik", // 7
		"Reppap", // 8
		"Oni", // 9
		"Zurhahs", // 10
		"Ackson", // 11
		"gm enjoyer", // 12
		"Chad", // 13
		"Adventurer"  // 14
	];

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    IERC721Enumerable constant lootContract = IERC721Enumerable(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);

    mapping(uint256 => uint256) _genSkillCooldown;

	uint256 constant skillIdOffset = 57896044618658097711785492504343953926634992332820282019728792003956564819968; // offset skill ids to halfway into the token id range
	uint16 constant setCap = 16000;

	uint256 lastMintedSetId = 8223;

    // Minting functions
    function _claimSet(uint256 setId) private {
		uint256[] memory tokenIds = _getSetSkillIds(setId);

		uint256[] memory amounts = new uint256[](9);
		amounts[0] = uint256(1);
		amounts[1] = uint256(1);
		amounts[2] = uint256(1);
		amounts[3] = uint256(1);
		amounts[4] = uint256(1);
		amounts[5] = uint256(1);
		amounts[6] = uint256(1);
		amounts[7] = uint256(1);
		amounts[8] = uint256(1);
		
		_mintBatch(_msgSender(), tokenIds, amounts, "");
        _owners[setId] = _msgSender();
    }

	function claimAvailableSet() public {
		require(lastMintedSetId <= setCap, "All available sets have been claimed");

		_claimSet(lastMintedSetId);
		lastMintedSetId++;
	}

    function claimWithLoot(uint256 tokenId) public {
		require(lootContract.ownerOf(tokenId) == _msgSender(), "you do not own the lootbag for this set of skill");
		require(!_exists(tokenId), "Set has already been claimed");
		_claimSet(tokenId);
    }

	function claimAllWithLoot() public {
        uint256 tokenBalanceOwner = lootContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "You do not own any Loot bags");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            uint256 lootId = lootContract.tokenOfOwnerByIndex(_msgSender(), i);
            if(!_exists(lootId)) {
                _claimSet(lootId);
            }
        }
    }

    function ownerClaimSet(uint256 setId) public onlyOwner {
        require( setId > 8000 && setId < 8223, "Not a reserved Set ID");
		require(!_exists(setId), "You already own this set");
        _claimSet(setId);
    }

	function skillUp(uint256 skillId) public {
        require(skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
		skillId += skillIdOffset;
		_burn(_msgSender(), skillId, 2);
		uint256 skillId1Up = skillId + 2175; // total skills * total name prefixes
		_mint(_msgSender(), skillId1Up, 1, "");
	}

	function skillDown(uint256 skillId) public {
        require(skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
		skillId += skillIdOffset;
		_burn(_msgSender(), skillId, 1);
		uint256 skillId1Down = skillId - 2175;
		_mint(_msgSender(), skillId1Down, 2, "");
	}

    function skillUpMulti(uint256 skillId, uint256 steps) public {
        require(skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
        require(steps > 0, "Invalid amount of steps");

		skillId += skillIdOffset;

		_burn(_msgSender(), skillId, 1 << steps);
		uint256 skillId1Up = skillId + (2175 * steps) ; // total skills * total name prefixes
		_mint(_msgSender(), skillId1Up, 1, "");
	}

    function skillDownMulti(uint256 skillId, uint256 steps) public {
        require(skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
        require(steps > 0, "Invalid amount of steps");

		skillId += skillIdOffset;

		_burn(_msgSender(), skillId, 1);
		uint256 skillId1Up = skillId - (2175 * steps) ; // total skills * total name prefixes
		_mint(_msgSender(), skillId1Up, 1 << steps, "");
    }

	function generateSkill(uint256 setId) public {
        require(_balances[setId][_msgSender()] > 0, "You do not own this set");
        uint256 lastBlock = _genSkillCooldown[setId];

        require(lastBlock == 0 || block.number >= lastBlock, "This set has generated a skill too recently");
        
        uint256 rand = uint256(keccak256(abi.encodePacked(setId, block.number ^ block.basefee ^ tx.gasprice )));
        uint8 categoryIndex = uint8(rand % 8);
        uint8 categoryLength;

        if(categoryIndex == 0) categoryLength = 21;
        else if(categoryIndex == 1) categoryLength = 16;
        else if(categoryIndex == 2) categoryLength = 24;
        else if(categoryIndex == 3) categoryLength = 18;
        else if(categoryIndex == 4) categoryLength = 17;
        else if(categoryIndex == 5) categoryLength = 14;
        else if(categoryIndex == 6) categoryLength = 21;
        else categoryLength = 14;
        
		uint256 skillId = _getSkillId(rand, categoryIndex, categoryLength) + skillIdOffset;

        _mint(_msgSender(), skillId, 1, "");

        if( ownsWholeSet(setId) ) _genSkillCooldown[setId] = block.number + 50000;
        else _genSkillCooldown[setId] = block.number + 250000;
    }

    function _exists(uint256 setId) internal view returns (bool) {
        return _owners[setId] != address(0);
    }

    function ownsWholeSet(uint256 setId) public view returns( bool ){
        uint256[] memory tokenIds = _getSetSkillIds(setId);
        for( uint256 i = 0; i < 9; i++)
        {
            if( _balances[tokenIds[i]][_msgSender()] == 0 ) return false;
        }
        return true;
    }

    // Transfer functions
	function transferSkill(address from, address to, uint256 skillId, uint256 amount, bytes memory data) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        require(skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
		_safeTransferFrom(from, to, skillId + skillIdOffset, amount, data);
	}

	function batchTransferSkills(address from, address to, uint256[] memory skillIds, uint256[] memory amounts, bytes memory data) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
		for( uint256 i = 0; i < 145; i++)
		{
            require(skillIds[i] < skillIdOffset, "Please use the Skill ID, not the token ID");
			skillIds[i] += skillIdOffset;
		}
		_safeBatchTransferFrom(from, to, skillIds, amounts, data);
	}

	function transferSet(address from, address to, uint256 setId, bytes memory data) public {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
		uint256[] memory tokenIds = _getSetSkillIds(setId);

		uint256[] memory amounts = new uint256[](9);
		amounts[0] = uint256(1);
		amounts[1] = uint256(1);
		amounts[2] = uint256(1);
		amounts[3] = uint256(1);
		amounts[4] = uint256(1);
		amounts[5] = uint256(1);
		amounts[6] = uint256(1);
		amounts[7] = uint256(1);
		amounts[8] = uint256(1);
		
		_safeBatchTransferFrom(from, to, tokenIds, amounts, data);
	}

    // Override 1155 transfer functions to handle Set/Skill ID offset
    function safeTransferFrom( address from, address to, uint256 id, uint256 amount, bytes memory data ) public override {
        if( id >= skillIdOffset ) 
        {
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not owner nor approved"
            );
            _safeTransferFrom(from, to, id, amount, data);
        }
        else
        {
            transferSet(from, to, id, data);
        }
    }

    function safeBatchTransferFrom( address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        bool setFound = false;
        bool skillFound = false;
        for( uint256 i = 0; i < ids.length; i++ )
        {
            if( ids[i] >= skillIdOffset ) 
            {
                skillFound = true;
            }
            else
            {
                require(amounts[i] == 1, "You cannot transfer more than 1 set as there is only 1 of each");
                setFound = true;
            }
        }

        require( !(setFound && skillFound), "Please attempt to only transfer Set IDs or Skill IDs in one batch" );
        
        if( skillFound )
        {
            _safeBatchTransferFrom(from, to, ids, amounts, data);
        }
        else
        {
            for( uint256 i = 0; i < ids.length; i++ )
            {
                transferSet(from, to, ids[i], data);
            }
        }
    }

    // Skill data
	function getSkillString(uint256 skillId) public view returns (string memory)
	{
		string memory output;
		uint256 skillIndex = skillId / 145;
		uint256 skillBaseId = skillId % 145;
		
		if( skillBaseId < 21 )
		{
			output = meleeAttacks[skillBaseId];
		}
		else if( skillBaseId < 37 )
		{
			output = rangeAttacks[skillBaseId - 21];
		}
		else if( skillBaseId < 61 )
		{
			output = elementalSpells[skillBaseId - 37];
		}
		else if( skillBaseId < 79 )
		{
			output = spiritualSpells[skillBaseId - 61];
		}
		else if( skillBaseId < 96 )
		{
			output = curses[skillBaseId - 79];
		}
		else if( skillBaseId < 110 )
		{
			output = heals[skillBaseId - 96];
		}
		else if( skillBaseId < 131 )
		{
			output = buffs[skillBaseId - 110];
		}
		else
		{
			output = defensiveSkills[skillBaseId - 131];
		}

		uint256 skillNamePrefix = skillIndex % 15; // namePrefixes.length

		if( skillNamePrefix > 0 )
		{
			output = string(abi.encodePacked(namePrefixes[skillNamePrefix], "'s ", output));
		}

		uint256 skillLevel = skillIndex / 15; // namePrefixes.length
		if( skillLevel > 0 )
		{
			output = string(abi.encodePacked(output, " +", toString(skillLevel)));
		}

		return output;
	}

	function _getSkillId(uint256 setId, uint8 categoryIndex, uint8 categoryLength) internal view returns (uint256 skillId) {
        uint256 rand = uint256(keccak256(abi.encodePacked(setId, categoryIndex)));
        uint256 rarity = rand % 1000;
        if (rarity < 4)
        {
            skillId = rand % categoryLength % 4;
        }
        else if (rarity < 40)
        {
            skillId = rand % categoryLength % 4 + 4;
        }
        else
        {
            skillId = rand % (categoryLength - 8) + 8;
        }

		skillId += categoryIndex;
        
		uint256 nameRand = uint256(keccak256(abi.encodePacked(rand))) % 1000;
		if (nameRand < 40)
		{
			skillId = (nameRand % 15) * 145 + skillId;
		}
        return skillId;
    }
    
	function _getSetSkillIds(uint256 setId) internal view returns (uint256[] memory) {
		uint256[] memory tokenIds = new uint256[](9);

		tokenIds[0] = _getSkillId(setId, 0, 21) + skillIdOffset; // meleeAttacks
		tokenIds[1] = _getSkillId(setId, 21, 16) + skillIdOffset; // rangeAttacks
		tokenIds[2] = _getSkillId(setId, 37, 24) + skillIdOffset; // elementalSpells
		tokenIds[3] = _getSkillId(setId, 61, 18) + skillIdOffset; // spiritualSpells
		tokenIds[4] = _getSkillId(setId, 79, 17) + skillIdOffset; // curses
		tokenIds[5] = _getSkillId(setId, 96, 14) + skillIdOffset; // heals
		tokenIds[6] = _getSkillId(setId, 110, 21) + skillIdOffset; // buffs
		tokenIds[7] = _getSkillId(setId, 131, 14) + skillIdOffset; // defensiveSkills

		tokenIds[8] = setId;

		return tokenIds;
	}

    // get functions
    function getGenSkillCooldown(uint256 setId) public view returns (uint256) {
		require( setId < skillIdOffset, "Not a valid Set ID");
        return _genSkillCooldown[setId];
    }

    function balanceOfSkill(address account, uint256 skillId) public view returns (uint256) {
        require( skillId < skillIdOffset, "Please use the Skill ID, not the token ID");
        return _balances[skillId + skillIdOffset][account];
    }

	function getMeleeAttack(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 0, 21));
	}
	
	function getRangeAttack(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 21, 16));
	}
	
	function getElementalSpell(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 37, 24));
	}
	
	function getSpiritualSpell(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 61, 18));
	}

	function getCurse(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 79, 17));
	}
	
    function getHeal(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
        return getSkillString(_getSkillId(setId, 96, 14));
    }
      
	function getBuff(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 110, 21));
	}
	
	function getDefensiveSkill(uint256 setId) public view returns (string memory) {
		require( setId < skillIdOffset, "Not a valid Set ID");
		return getSkillString(_getSkillId(setId, 131, 14));
	}
    
    function uri(uint256 tokenId) override public view returns (string memory) {
		if( tokenId > skillIdOffset )
		{
			string[3] memory parts;
        	parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        	parts[1] = getSkillString(tokenId - skillIdOffset);
			parts[2] = '</text></svg>';

			string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
			
			string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Skill #', toString(tokenId - skillIdOffset), '", "description": "Skills are randomized adventurer abilities generated and stored on chain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
			output = string(abi.encodePacked('data:application/json;base64,', json));

			return output;
		}
		else
		{
			string[17] memory parts;
			parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

			parts[1] = getMeleeAttack(tokenId);

			parts[2] = '</text><text x="10" y="40" class="base">';

			parts[3] = getRangeAttack(tokenId);

			parts[4] = '</text><text x="10" y="60" class="base">';

			parts[5] = getElementalSpell(tokenId);

			parts[6] = '</text><text x="10" y="80" class="base">';

			parts[7] = getSpiritualSpell(tokenId);

			parts[8] = '</text><text x="10" y="100" class="base">';

			parts[9] = getCurse(tokenId);

			parts[10] = '</text><text x="10" y="120" class="base">';

			parts[11] = getHeal(tokenId);

			parts[12] = '</text><text x="10" y="140" class="base">';

			parts[13] = getBuff(tokenId);

			parts[14] = '</text><text x="10" y="160" class="base">';

			parts[15] = getDefensiveSkill(tokenId);

			parts[16] = '</text></svg>';

			string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
			output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
			
			string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Set #', toString(tokenId), '", "description": "Skills are randomized adventurer abilities generated and stored on chain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
			output = string(abi.encodePacked('data:application/json;base64,', json));

			return output;
		}
    }

    constructor() ERC1155("Skills") Ownable() {}
}