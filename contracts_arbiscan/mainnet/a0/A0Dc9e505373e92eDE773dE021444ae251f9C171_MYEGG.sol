/**
 *Submitted for verification at arbiscan.io on 2022-01-20
*/

// File: contracts/libraries/Base64.sol



pragma solidity ^0.8.0;

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
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/MYEGG.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;







/**
          ████                              
        ██░░░░██                            
      ██░░░░░░░░██                          
      ██░░░░░░░░██                          
    ██░░░  ░░  ░░░██                        
    ██░░░█ ░░█ ░░░██                        
    ██░░░░░░░░░░░░██                        
      ██░░░  ░░░██                          
        ████████     

          eg
  @author goldendilemma
  
 */


struct EggPart {
  string svg;
  string name;
}

struct Egg {
  string svgBody;
  string jsonBody;
}

uint8 constant CAT_BODY = 0;
uint8 constant CAT_MOUTH = 1;
uint8 constant CAT_HAIR = 2;
uint8 constant CAT_EYES = 3;
uint8 constant CAT_GLASSES = 4;
uint8 constant CAT_ACCESSORY = 5;

contract MYEGG is 
  ERC721Enumerable,
  ERC721URIStorage,
  Ownable,
  ReentrancyGuard {

  uint constant EGG_PER_WALLET = 1;

  uint public maxEggs;
  uint public price = 0;
  bool public paused = true;
  bool public singleMint = true;

  mapping (bytes32 => bool) eggs;
  mapping (address => bool) hasEgg;

  uint public eggCount = 0;

  event MintEgg (address indexed wallet, uint tokenId);

  constructor(
    string memory name, 
    string memory ticker, 
    uint maxMints
  ) ERC721(name, ticker) {
    maxEggs = maxMints;
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
  {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getFill (uint8 fillIndex) 
  private pure returns (string memory) 
  {
    return ["FF0000", "FF8800", "FFFF00", "00FF00", "00FFFF", "FF00FF", "0000FF", "F9E8CF", "CEAB97", "D1D1D1", "393939"][fillIndex];
  }

  function getPart (uint8 catIndex, uint8 attrIndex, uint8 fillIndex)
  private pure returns (EggPart memory) {
    uint8 catLength = [4, 3, 1, 2, 1, 11][catIndex];
    uint8 catStart = [1, 5, 8, 9, 11, 12][catIndex];
    bool isRemovable = [false, true, true, false, true, true][catIndex];
    if (attrIndex == 0) {
      require(isRemovable, "EGG_BROKE_1"); // not removable
    } else {
      require(attrIndex >= catStart && attrIndex < catStart + catLength, "EGG_BROKE_2");  // out of bounds
    }
    EggPart memory part = [
      EggPart({ name: 'none', svg: '' }),
      EggPart({ name: 'regular', svg: string(abi.encodePacked('<path class="eo" d="M10 11H14V12H15V14H16V19H15V20H14H10H9V19H8V14H9V12H10V11Z" fill="#', getFill(fillIndex) ,'"/><path class="eo" d="M13 11H14V12H13V11ZM14 12H15V13H14V12ZM16 14H15V15H16V14ZM15 18H16V19H15V18ZM15 19V20H14V19H15ZM9 19H10V20H9V19ZM9 19H8V18H9V19Z" fill="black" fill-opacity="0.5"/><path class="eo" d="M13 11H11V12H12V13H13V15H14V17H13V18H12V19H10V20H12H15V19H16V15V14H15V13H14V12H13V11Z" fill="black" fill-opacity="0.29"/>')) }),
      EggPart({ name: 'transparent', svg: '<path class="eo" d="M13 11H11V12H12V13H13V15H14V17H13V18H12V19H10V20H12H15V19H16V15V14H15V13H14V12H13V11Z" fill="black" fill-opacity="0.29"/><path class="eo" d="M11 11H10V12H9V14H8V16H9V15H10V14H11V13H12V12H14V11H12H11Z" fill="white" fill-opacity="0.78"/>' }),
      EggPart({ name: 'rainbow', svg: '<rect x="10" y="11" width="1" height="9" fill="#FFFF00"/><rect x="11" y="11" width="1" height="9" fill="#88FF00"/><rect x="12" y="11" width="1" height="9" fill="#00FF88"/><rect x="13" y="11" width="1" height="9" fill="#00FFFF"/><rect x="14" y="12" width="1" height="8" fill="#0088FF"/><rect x="15" y="14" width="1" height="5" fill="#0000FF"/><rect x="8" y="14" width="1" height="5" fill="#FF0000"/><rect x="9" y="12" width="1" height="8" fill="#FF8800"/><path class="eo" d="M13 11H14V12H13V11ZM14 12H15V13H14V12ZM16 14H15V15H16V14ZM15 18H16V19H15V18ZM15 19V20H14V19H15ZM9 19H10V20H9V19ZM9 19H8V18H9V19Z" fill="black" fill-opacity="0.5"/><path class="eo" d="M13 11H11V12H12V13H13V15H14V17H13V18H12V19H10V20H12H15V19H16V15V14H15V13H14V12H13V11Z" fill="black" fill-opacity="0.29"/><path class="eo" d="M11 11H10V12H9V14H8V16H9V15H10V14H11V13H12V12H14V11H12H11Z" fill="white" fill-opacity="0.78"/>' }),
      EggPart({ name: 'eggtrix', svg: '<path class="eo" d="M10 11H14V12H15V14H16V19H15V20H14H10H9V19H8V14H9V12H10V11Z" fill="#1C712F"/><path class="eo" d="M12 11H11V12H12V11ZM14 11H13V12H14V11ZM9 13H10V14H9V13ZM12 13H11V14H12V13ZM13 13H14V14H13V13ZM16 15H15V16H16V15ZM13 15H14V16H13V15ZM12 15H11V16H12V15ZM9 15H10V16H9V15ZM10 17H9V18H10V17ZM13 17H14V18H13V17ZM14 19H13V20H14V19Z" fill="#00FF00"/><path class="eo" d="M13 11H11V12H12V13H13V15H14V17H13V18H12V19H10V20H12H15V19H16V15V14H15V13H14V12H13V11Z" fill="#03A360" fill-opacity="0.36"/><path class="eo" d="M11 11H10V12H9V14H8V16H9V15H10V14H11V13H12V12H14V11H12H11Z" fill="#00FF38" fill-opacity="0.4"/><path class="eo" d="M13 11H14V12H13V11ZM14 12H15V13H14V12ZM16 14H15V15H16V14ZM15 18H16V19H15V18ZM15 19V20H14V19H15ZM9 19H10V20H9V19ZM9 19H8V18H9V19Z" fill="black" fill-opacity="0.5"/>' }),
      EggPart({ name: 'smile', svg: '<path class="eo" d="M15 17H14V18H10V19H14V18H15V17Z" fill="black"/>' }),
      EggPart({ name: 'ooo', svg: '<rect x="11" y="18" width="1" height="1" fill="black"/>' }),
      EggPart({ name: 'egg', svg: '<path d="M10 18H13V20H10V18Z" fill="black"/>' }),
      EggPart({ name: 'cap', svg: string(abi.encodePacked('<path class="eo" d="M13 10H15V11H16V12H17V14H14H6V13H8V12V11H9V10H13Z" fill="#', getFill(fillIndex),'"/><rect x="6" y="13" width="8" height="1" fill="white" fill-opacity="0.4"/><path class="eo" d="M15 10H13V11H14V12V14H17V12H16V11H15V10Z" fill="black" fill-opacity="0.19"/>')) }),
      EggPart({ name: 'regular', svg: '<path class="eo" d="M11 15H10V17H11V15ZM14 15H13V17H14V15Z" fill="white"/><path class="eo" d="M10 15H9V17H10V15ZM13 15H12V17H13V15Z" fill="black"/><path class="eo" d="M11 15H9V16H11V15ZM14 15H12V16H14V15Z" fill="black" fill-opacity="0.15"/>' }),
      EggPart({ name: 'high-af', svg: '<path class="eo" d="M11 16H10V17H11V16ZM14 16H13V17H14V16Z" fill="#FF0000"/><path class="eo" d="M10 16H9V17H10V16ZM13 16H12V17H13V16Z" fill="black"/>' }),
      EggPart({ name: 'sunglasses', svg: '<path class="eo" d="M9 15H11H12H14V17H12V16H11V17H9V15Z" fill="#000000"/>' }),
      EggPart({ name: 'bathing-ring', svg: string(abi.encodePacked('<path class="eo" d="M5 16H6V17H7V18V19H8V20H16V19H17V20V21H16V22H14V23H10V22H8V21H7V20H6V19H5V18V17V16Z" fill="#', getFill(fillIndex), '"/><rect x="4" y="18" width="1" height="1" fill="black"/><path class="eo" d="M6 17H5V18H6V17ZM15 20H9V21H15V20Z" fill="white" fill-opacity="0.5"/><path class="eo" d="M7 20H8V21H7V20ZM10 22V21H8V22H10ZM14 22V23H10V22H14ZM16 21V22H14V21H16ZM16 21H17V20H16V21Z" fill="black" fill-opacity="0.36"/>')) }),
      EggPart({ name: 'cigarette', svg: '<rect x="7" y="18" width="4" height="1" fill="#F0F0F0"/><rect x="7" y="18" width="1" height="1" fill="#FFA800"/><path class="eo" d="M6 12H5V16H6V12ZM7 17H6V18H7V17Z" fill="#C4C4C4" fill-opacity="0.5"/>' }),
      EggPart({ name: 'earring', svg: string(abi.encodePacked('<rect x="16" y="16" width="1" height="1" fill="#', getFill(fillIndex), '"/><path class="eo" d="M17 15H16V16H15V17H16V18H17V17H18V16H17V15ZM17 16V17H16V16H17Z" fill="black"/>')) }),
      EggPart({ name: 'easter-egg', svg: '<path class="eo" d="M15 16H16V17H15V16ZM15 20H14V18V17H15V18V20ZM18 20V21H15V20H18ZM18 18V20H19V18V17H18V16H17V17H18V18Z" fill="#3E62FE"/><path class="eo" d="M16 15H17V17H18V20H17H16H15V17H16V15Z" fill="#113EFF"/><rect x="15" y="17" width="3" height="1" fill="#FB512A"/><path class="eo" d="M14 18H15V19H14V18ZM18 19V20H15V19H18ZM18 19H19V18H18V19Z" fill="#F1FF0E"/><path class="eo" d="M16 17H15V18H16V17ZM18 17H17V18H18V17ZM15 19H16V20H15V19ZM18 19H17V20H18V19Z" fill="black" fill-opacity="0.18"/><path class="eo" d="M17 15H16V16H17V15ZM15 17H14V20H15V21H18V20H19V17H18V20H15V17Z" fill="black" fill-opacity="0.35"/>' }),
      EggPart({ name: 'jindujun', svg: '<path class="eo" d="M13 19H16V20H17V22V23H16V24H14H12H10H9H7V23H6V20H7H8H9V19H10V20H12H13V19Z" fill="white"/><path class="eo" d="M9 19H10V20H9V19ZM7 21H8V20H9V21V22H7V21ZM7 21H6V20H7V21ZM14 19H13V20H14V19ZM14 22V23H12V22V21H13V22H14ZM12 21H11V20H12V21ZM16 23H15V24H16V23ZM16 21H17V22H16V21ZM10 24V23H8V24H10Z" fill="black" fill-opacity="0.11"/><path class="eo" d="M9 20H10V21H9V20ZM16 21H15V22H16V23H13V24H16V23H17V22H16V21ZM10 23H12V24H10V23ZM7 21H6V22H7V21ZM9 22H8V23H9V22Z" fill="black" fill-opacity="0.3"/>' }),
      EggPart({ name: 'knife', svg: '<rect x="6" y="19" width="3" height="1" fill="#FFE794"/><path class="eo" d="M6 19H2V20H3V21H6V20V19Z" fill="#EDEDED"/><rect x="3" y="20" width="3" height="1" fill="black" fill-opacity="0.13"/><rect x="3" y="20" width="1" height="1" fill="white" fill-opacity="0.38"/>' }),
      EggPart({ name: 'lollipop', svg: string(abi.encodePacked('<rect x="5" y="15" width="1" height="6" fill="white"/><path class="eo" d="M4 10H7V11H8V14H7V15H4V14H3V11H4V10Z" fill="#', getFill(fillIndex), '"/><path d="M4 11H7V12H4V11Z" fill="white" fill-opacity="0.58"/><path class="eo" d="M7 12H6V13H5V14H6H7V12Z" fill="white" fill-opacity="0.39"/><path class="eo" d="M7 10H6V11H7V12H8V11H7V10ZM7 13H8V14H7V13ZM6 15H7V14H6V15ZM5 15V16H6V15H5ZM4 14H5V15H4V14ZM4 14H3V13H4V14ZM3 11H4V12H3V11ZM4 11V10H5V11H4Z" fill="black" fill-opacity="0.15"/>')) }),
      EggPart({ name: 'chikin', svg: string(abi.encodePacked('<path class="eo" d="M14 17H15V18H14V17ZM16 20H17V21H16V20Z" fill="#FFC107"/><rect width="1" height="1" transform="matrix(-1 0 0 1 16 16)" fill="#', getFill(fillIndex), '"/><path class="eo" d="M19 17H18V18H19V17ZM16 18H17H18V19V20H15V19V18V17H16V18Z" fill="white"/><path class="eo" d="M18 17H19V18H18V19H16V18H18V17Z" fill="black" fill-opacity="0.06"/>')) }),
      EggPart({ name: 'pills', svg: '<path class="eo" d="M15 18H14V21H15H16V18H15Z" fill="#FF0000"/><path class="eo" d="M19 19H16V20V21H19V20V19Z" fill="#00FFFF"/><path class="eo" d="M16 18H15V21H16H19V20H16V18Z" fill="black" fill-opacity="0.28"/><path class="eo" d="M15 18H14V19H15V18ZM19 19H18V20H19V19Z" fill="white" fill-opacity="0.71"/>' }),
      EggPart({ name: 'rune-scimitar', svg: '<path class="eo" d="M8 18H9V19H10V20V21H9H8V20H7V19H8V18Z" fill="#EDC715"/><path class="eo" d="M5 12H6V13V14V15H7V17H8V18V19H7H6V18H5V17H4V16H3V14H4V13H5V12Z" fill="#3F7DA4"/><path class="eo" d="M3 14H4V16H3V14ZM5 17H4V16H5V17ZM6 18H5V17H6V18ZM6 18H7V19H6V18ZM9 19H8V20H9V19Z" fill="black" fill-opacity="0.23"/><path class="eo" d="M5 12H6V13H5V12ZM5 13V14H4V13H5ZM9 18H8V19H7V20H8V19H9V20H10V19H9V18Z" fill="white" fill-opacity="0.38"/>' })
    ][attrIndex];
    return part;
  }

  function eggsists (
    uint8[6] memory attributes,
    uint8[6] memory fillIndexes
  ) public view returns (bool) {
    return eggs[idEgg(attributes, fillIndexes)];
  }

  function idEgg (
    uint8[6] memory attributes,
    uint8[6] memory fillIndexes
  ) private pure returns (bytes32) {
    bytes memory temp;
    for (uint8 i = 0; i < attributes.length; i++) {
      temp = [false,true,false,false,false,false,false,false,true,false,false,false,true,false,true,false,false,false,true,true,false,false][attributes[i]]
        ? abi.encodePacked(temp, attributes[i], fillIndexes[i])
        : abi.encodePacked(temp, attributes[i]);
    }
    return keccak256(temp);
  }

  function createEgg (
    uint8[6] memory attributes,
    uint8[6] memory fillIndexes
    ) private pure returns (Egg memory) {
    Egg memory egg;
    EggPart[6] memory parts = [
      getPart(CAT_BODY, attributes[0], fillIndexes[0]),
      getPart(CAT_MOUTH, attributes[1], fillIndexes[1]),
      getPart(CAT_HAIR, attributes[2], fillIndexes[2]),
      getPart(CAT_EYES, attributes[3], fillIndexes[3]),
      getPart(CAT_GLASSES, attributes[4], fillIndexes[4]),
      getPart(CAT_ACCESSORY, attributes[5], fillIndexes[5])
    ];
    egg.svgBody = string(
      abi.encodePacked(
        // border & inside
        '<g class="border"><path class="eo" d="M14 10H10V11H9V12H8V14H7V19H8V20H9V21H15V20H16V19H17V14H16V12H15V11H14V10ZM14 11V12H15V14H16V19H15V20H9V19H8V14H9V12H10V11H14Z" fill="black"/></g>',
        '<g class="inside"><path class="eo" d="M14 14H13V15H11V16H13V15H14V14Z" fill="#F2BC2F"/><path class="eo" d="M11 13H12H13V14H12H11V13ZM11 14V15H10V14H11Z" fill="#FFE76B"/><rect x="11" y="14" width="2" height="1" fill="#FFD600"/></g>',
        abi.encodePacked(
          '<g class="body" id="a', Strings.toString(attributes[CAT_BODY]), '">', parts[CAT_BODY].svg, '</g>',
          '<g class="mouth" id="a', Strings.toString(attributes[CAT_MOUTH]), '">', parts[CAT_MOUTH].svg, '</g>',
          '<g class="hair" id="a', Strings.toString(attributes[CAT_HAIR]), '">', parts[CAT_HAIR].svg, '</g>'
        ),
        abi.encodePacked(
          '<g class="eyes" id="a', Strings.toString(attributes[CAT_EYES]), '">', parts[CAT_EYES].svg, '</g>',
          '<g class="glasses" id="a', Strings.toString(attributes[CAT_GLASSES]), '">', parts[CAT_GLASSES].svg, '</g>'
          '<g class="accessory" id="a', Strings.toString(attributes[CAT_ACCESSORY]), '">', parts[CAT_ACCESSORY].svg, '</g>'
        )
      )
    );
    egg.jsonBody = string(abi.encodePacked(
      '{ "trait_type": "body", "value": "', parts[CAT_BODY].name,'" },'
      '{ "trait_type": "mouth", "value": "', parts[CAT_MOUTH].name,'" },'
      '{ "trait_type": "hair", "value": "', parts[CAT_HAIR].name,'" },'
      '{ "trait_type": "eyes", "value": "', parts[CAT_EYES].name,'" },'
      '{ "trait_type": "glasses", "value": "', parts[CAT_GLASSES].name,'" },'
      '{ "trait_type": "accessory", "value": "', parts[CAT_ACCESSORY].name,'" }'
    ));
    return egg;
  }

  function setMaxEggs (uint newMaxEggs) public onlyOwner  { maxEggs = newMaxEggs; }
  function setPrice (uint newPrice) public onlyOwner { price = newPrice; }
  function setPaused (bool newState) public onlyOwner { paused = newState; }
  function setSingleMint (bool newState) public onlyOwner { singleMint = newState; }
  function withdraw(uint256 amount) public onlyOwner {
    (bool success, ) = msg.sender.call { value: amount }("");
    require(success, "NOT_ENOUGH_FUNDS");
  }

  function eggIt (
    uint8[6] memory attributes,
    uint8[6] memory fillIndexes
  ) public payable nonReentrant {
    bytes32 eggId = idEgg(attributes, fillIndexes);
    require(!eggs[eggId], "NON_UNIQUE_EGG");
    if (msg.sender != owner()) {
      require(eggCount < maxEggs, "OUT_OF_EGGS");
      require(msg.value >= price, "NOT_ENOUGH_FUNDS");
      require(!paused, "WERE_CLOSED");
      if (singleMint == true) {
        require(!hasEgg[msg.sender], "FBI_OPEN_UP_ONE_EGG");
      }
    }

    uint newTokenId = eggCount;
    Egg memory newEgg = createEgg(attributes, fillIndexes);
    string memory image = string(
      abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(
        abi.encodePacked(
        '<svg width="100%" height="100%" viewBox="0 0 24 24" id="egg" fill="none" xmlns="http://www.w3.org/2000/svg">',
        '<style>.eo{fill-rule:evenodd;clip-rule:evenodd;}#egg{transform-origin:center center;shape-rendering:crispEdges;}#egg:active{transform:scaleX(-1);}</style>',
        newEgg.svgBody,
        '</svg>'
        )
      ))
    ));
    string memory encodedMetaData = Base64.encode(bytes(string(abi.encodePacked(
      '{',
        '"name": "EGG #', Strings.toString(newTokenId), '",',
        '"description": "', 'Mint Your EGG','",',
        '"image":', '"', image, '",',
        '"attributes":', '[',
          newEgg.jsonBody,
        ']',
      '}'
    ))));

    string memory tokenUri = string(abi.encodePacked(
      "data:application/json;base64,",
      encodedMetaData
    ));

    _safeMint(msg.sender, newTokenId);
    _setTokenURI(newTokenId, tokenUri);

    eggs[eggId] = true;
    eggCount++;
    hasEgg[msg.sender] = true;

    emit MintEgg(msg.sender, newTokenId);
  }

}