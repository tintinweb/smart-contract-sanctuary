/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

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

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

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


    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC165, IERC2981Royalties {
    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }
}

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
     * plain`call` is an unsafe replacement for a function call: use this
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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



/**
 * OpenVibes is a set of 2,222 free to mint generative art pieces.
 * Combined with the original Vibes drop, the max supply is 9,999.
 * This is my gift to the NFT Community. You are legendary. Thank you!
 * 
 *   - remnynt
 *
 *   https://vibes.art
 */

contract OpenVibes is ERC721Enumerable, ERC2981ContractWideRoyalties, ReentrancyGuard, Ownable {
    ArtLib lib_Art;
    ColorDataLib lib_ColorData;

    using Strings for uint256;

    bool public mintingActive = false;
    bool public useAnimation = false;
    bool public useOnChainAnimation = false;
    string private baseVibeURI;

    // the max number of vibes in the original drop, 0.07 ETH each
    uint256 private constant MAX_VIBE_SUPPLY = 7777;

    // the max number of vibes in this drop, free mint
    uint256 private constant MAX_OPEN_VIBE_SUPPLY = 2222;

    // the blockhash being visualized by each token
    mapping(uint256 => bytes32) private entropyHashes;

    // one mint per wallet
    mapping(address => bool) private hasWalletMinted;

    struct ColorInfo {
        uint256[] colorInts;
        uint256[] colorIntsChosen;
        uint256 colorIntCount;
        bool ordered;
        bool shuffle;
        bool restricted;
        string palette;
        uint256 colorCount;
    }

    struct TokenInfo {
        string entropyHash;
        string element;
        string palette;
        uint256 colorCount;
        string style;
        string gravity;
        string grain;
        string display;
        string[14] html;
    }

    struct WobbleInfo {
        uint256 r;
        uint256 g;
        uint256 b;
        uint256 offsetR;
        uint256 offsetG;
        uint256 offsetB;
        uint256 offsetDirR;
        uint256 offsetDirG;
        uint256 offsetDirB;
    }

    constructor() ERC721("OpenVibes", "OVIBES") Ownable() {
        // set voluntary royalties, according to ERC2981, @ 12.5%, 1250 basis points
        _setRoyalties(owner(), 1250);
    }

    function setLibArt(address lib) public onlyOwner {
      lib_Art = ArtLib(lib);
    }

    function setLibColorData(address lib) public onlyOwner {
      lib_ColorData = ColorDataLib(lib);
    }

    function getElement(uint256 tokenId) private view returns (string memory) {
        return lib_Art.getElementByRoll(roll1000(tokenId, lib_Art.ROLL_ELEMENT()));
    }

    function getPalette(uint256 tokenId) private view returns (string memory) {
        return lib_Art.getPaletteByRoll(roll1000(tokenId, lib_Art.ROLL_PALETTE()), getElement(tokenId));
    }

    function getColorByIndex(uint256 tokenId, uint256 lookupIndex) public view returns (string memory) {
        ColorInfo memory info;
        info.colorCount = getColorCount(tokenId);

        if (lookupIndex >= info.colorCount
            || tokenId <= MAX_VIBE_SUPPLY
            || tokenId > MAX_VIBE_SUPPLY + super.totalSupply())
        {
            return 'null';
        }

        (info.colorInts, info.colorIntCount, info.ordered, info.shuffle, info.restricted) = lib_ColorData.getPaletteColors(getPalette(tokenId));

        uint256 i;
        uint256 temp;
        uint256 startIndex;
        uint256 currIndex;
        uint256 codeCount;

        info.colorIntsChosen = new uint256[](12);

        if (info.ordered) {
            temp = roll1000(tokenId, lib_Art.ROLL_ORDERED());
            startIndex = temp % info.colorIntCount;
            for (i = 0; i < info.colorIntCount; i++) {
                currIndex = startIndex + i;
                if (currIndex >= info.colorIntCount) {
                    currIndex -= info.colorIntCount;
                }
                info.colorIntsChosen[i] = info.colorInts[currIndex];
            }
        } else if (info.shuffle) {
            codeCount = info.colorIntCount;

            while (codeCount > 0) {
                i = roll1000(tokenId, string(abi.encodePacked(lib_Art.ROLL_SHUFFLE, toString(codeCount)))) % codeCount;
                codeCount -= 1;

                temp = info.colorInts[codeCount];
                info.colorInts[codeCount] = info.colorInts[i];
                info.colorInts[i] = temp;
            }

            for (i = 0; i < info.colorIntCount; i++) {
                info.colorIntsChosen[i] = info.colorInts[i];
            }
        } else {
            for (i = 0; i < info.colorIntCount; i++) {
                info.colorIntsChosen[i] = info.colorInts[i];
            }
        }

        if (info.restricted) {
            temp = getWobbledColor(info.colorIntsChosen[lookupIndex % info.colorIntCount], tokenId, lookupIndex);
        } else if (lookupIndex >= info.colorIntCount) {
            temp = getRandomColor(tokenId, lookupIndex);
        } else {
            temp = getWobbledColor(info.colorIntsChosen[lookupIndex], tokenId, lookupIndex);
        }

        return lib_Art.getColorCode(temp);
    }

    function getWobbledColor(uint256 color, uint256 tokenId, uint256 index) private view returns (uint256) {
        WobbleInfo memory info;
        info.r = (color >> uint256(16)) & uint256(255);
        info.g = (color >> uint256(8)) & uint256(255);
        info.b = color & uint256(255);
        info.offsetR = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_RED, toString(index)))) % uint256(8);
        info.offsetG = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_GREEN, toString(index)))) % uint256(8);
        info.offsetB = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_BLUE, toString(index)))) % uint256(8);
        info.offsetDirR = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_DIRRED, toString(index)))) % uint256(2);
        info.offsetDirG = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_DIRGREEN, toString(index)))) % uint256(2);
        info.offsetDirB = rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_DIRBLUE, toString(index)))) % uint256(2);

        if (info.offsetDirR == uint256(0)) {
            if (info.r > info.offsetR) {
                info.r -= info.offsetR;
            } else {
                info.r = uint256(0);
            }
        } else {
            if (info.r + info.offsetR <= uint256(255)) {
                info.r += info.offsetR;
            } else {
                info.r = uint256(255);
            }
        }

        if (info.offsetDirG == uint256(0)) {
            if (info.g > info.offsetG) {
                info.g -= info.offsetG;
            } else {
                info.g = uint256(0);
            }
        } else {
            if (info.g + info.offsetG <= uint256(255)) {
                info.g += info.offsetG;
            } else {
                info.g = uint256(255);
            }
        }

        if (info.offsetDirB == uint256(0)) {
            if (info.b > info.offsetB) {
                info.b -= info.offsetB;
            } else {
                info.b = uint256(0);
            }
        } else {
            if (info.b + info.offsetB <= uint256(255)) {
                info.b += info.offsetB;
            } else {
                info.b = uint256(255);
            }
        }

        return uint256((info.r << uint256(16)) | (info.g << uint256(8)) | info.b);
    }

    function getRandomColor(uint256 tokenId, uint256 index) private view returns (uint256) {
        return rollMax(tokenId, string(abi.encodePacked(lib_Art.ROLL_RANDOMCOLOR, toString(index)))) % uint256(16777216);
    }

    function getStyle(uint256 tokenId) private view returns (string memory) {
        return lib_Art.getStyleByRoll(roll1000(tokenId, lib_Art.ROLL_STYLE()));
    }

    function getColorCount(uint256 tokenId) private view returns (uint256) {
        return lib_Art.getColorCount(roll1000(tokenId, lib_Art.ROLL_COLORCOUNT()), getStyle(tokenId));
    }

    function getGravity(uint256 tokenId) private view returns (string memory) {
        string memory gravity;
        string memory style = getStyle(tokenId);
        uint256 colorCount = getColorCount(tokenId);
        uint256 roll = roll1000(tokenId, lib_Art.ROLL_GRAVITY());

        if (colorCount >= uint256(5) && compareStrings(style, lib_Art.STYLE_SMOOTH())) {
            gravity = lib_Art.getGravityLimitedByRoll(roll);
        } else {
            gravity = lib_Art.getGravityByRoll(roll);
        }

        return gravity;
    }

    function getGrain(uint256 tokenId) private view returns (string memory) {
        return lib_Art.getGrainByRoll(roll1000(tokenId, lib_Art.ROLL_GRAIN()));
    }

    function getDisplay(uint256 tokenId) private view returns (string memory) {
        return lib_Art.getDisplayByRoll(roll1000(tokenId, lib_Art.ROLL_DISPLAY()));
    }

    function getRandomBlockhash(uint256 tokenId) private view returns (bytes32) {
        uint256 decrement = (tokenId % 255) % (block.number - 1);
        uint256 blockIndex = block.number - (decrement + 1);
        return blockhash(blockIndex);
    }

    function getEntropyHash(uint256 tokenId) private view returns (string memory) {
        return uint256(entropyHashes[tokenId]).toHexString();
    }

    function rollMax(uint256 tokenId, string memory key) private view returns (uint256) {
        string memory hashEntropy = getEntropyHash(tokenId);
        string memory tokenEntropy = string(abi.encodePacked(key, toString(tokenId)));
        return random(hashEntropy) ^ random(tokenEntropy);
    }

    function roll1000(uint256 tokenId, string memory key) private view returns (uint256) {
        return uint256(1) + rollMax(tokenId, key) % uint256(1000);
    }

    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function tokenScript(uint256 tokenId) public view returns (string memory) {
        require(tokenId > MAX_VIBE_SUPPLY, 'invalid tokenId');
        require(tokenId <= MAX_VIBE_SUPPLY + super.totalSupply(), 'invalid tokenId');

        TokenInfo memory info;
        info.entropyHash = getEntropyHash(tokenId);
        info.colorCount = getColorCount(tokenId);
        info.style = getStyle(tokenId);
        info.gravity = getGravity(tokenId);
        info.grain = getGrain(tokenId);
        info.display = getDisplay(tokenId);

        info.html[0] = '<!doctype html><html><head><script>';
        info.html[1] = string(abi.encodePacked('H="', info.entropyHash, '";'));
        info.html[2] = string(abi.encodePacked('Y="', info.style, '";'));
        info.html[3] = string(abi.encodePacked('G="', info.gravity, '";'));
        info.html[4] = string(abi.encodePacked('A="', info.grain, '";'));
        info.html[5] = string(abi.encodePacked('D="', info.display, '";'));

        string memory colorString;
        string memory partString;
        uint256 i;
        for (i = 0; i < 6; i++) {
            if (i < info.colorCount) {
                colorString = getColorByIndex(tokenId, i);
            } else {
                colorString = '';
            }

            if (i == 0) {
                partString = string(abi.encodePacked('P=["', colorString, '",'));
            } else if (i < info.colorCount - 1) {
                partString = string(abi.encodePacked('"', colorString, '",'));
            } else if (i < info.colorCount) {
                partString = string(abi.encodePacked('"', colorString, '"];'));
            } else {
                partString = '';
            }

            info.html[6 + i] = partString;
        }

        info.html[12] = lib_Art.getScript();
        info.html[13] = '</script></head><body></body></html>';

        string memory output = string(abi.encodePacked(info.html[0], info.html[1], info.html[2], info.html[3], info.html[4], info.html[5], info.html[6]));
        return string(abi.encodePacked(output, info.html[7], info.html[8], info.html[9], info.html[10], info.html[11], info.html[12], info.html[13]));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(tokenId > MAX_VIBE_SUPPLY, 'invalid tokenId');
        require(tokenId <= MAX_VIBE_SUPPLY + super.totalSupply(), 'invalid tokenId');

        TokenInfo memory info;
        info.element = getElement(tokenId);
        info.palette = getPalette(tokenId);
        info.colorCount = getColorCount(tokenId);
        info.style = getStyle(tokenId);
        info.gravity = getGravity(tokenId);
        info.grain = getGrain(tokenId);
        info.display = getDisplay(tokenId);

        string memory imagePath = string(abi.encodePacked(baseVibeURI, toString(tokenId), '.jpg'));
        string memory json = string(abi.encodePacked('{"name": "vibe #', toString(tokenId), '", "description": "vibes is a generative art collection, randomly created and stored on chain. each token is an interactive html page that allows you to render your vibe at any size. vibes make their color palette available on chain, so feel free to carry your colors with you on your adventures.", "image": "', imagePath));

        if (useOnChainAnimation) {
            string memory script = tokenScript(tokenId);
            json = string(abi.encodePacked(json, '", "animation_url": "data:text/html;base64,', Base64.encode(bytes(script))));
        } else if (useAnimation) {
            json = string(abi.encodePacked(json, '", "animation_url": "', string(abi.encodePacked(baseVibeURI, toString(tokenId), '.html'))));
        }

        json = string(abi.encodePacked(json, '", "attributes": [{ "trait_type": "element", "value": "', info.element, '" }, { "trait_type": "palette", "value": "', info.palette, '" }, { "trait_type": "colors", "value": "', toString(info.colorCount), '" }, { "trait_type": "style", "value": "', info.style));
        json = string(abi.encodePacked(json, '" }, { "trait_type": "gravity", "value": "', info.gravity, '" }, { "trait_type": "grain", "value": "', info.grain, '" }, { "trait_type": "display", "value": "', info.display, '" }]}'));

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function mintVibes() public nonReentrant {
        uint256 lastTokenId = MAX_VIBE_SUPPLY + super.totalSupply();
        uint256 nextTokenId = lastTokenId + 1;
        address minter = _msgSender();

        require(mintingActive, 'gm fren. minting open vibes soon.');
        require(!hasWalletMinted[minter], 'whoa fren. max 1 open vibe per wallet.');
        require(nextTokenId <= MAX_VIBE_SUPPLY + MAX_OPEN_VIBE_SUPPLY, 'gn fren. only so many open vibes.');

        hasWalletMinted[minter] = true;
        entropyHashes[nextTokenId] = getRandomBlockhash(nextTokenId);

        _safeMint(minter, nextTokenId);
    }

    function vibeCheck() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function toggleAnimation() public onlyOwner {
        useAnimation = !useAnimation;
    }

    function toggleOnChainAnimation() public onlyOwner {
        useOnChainAnimation = !useOnChainAnimation;
    }

    function setVibeURI(string memory uri) public onlyOwner {
        baseVibeURI = uri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981ContractWideRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

}

abstract contract ColorDataLib {
    function getPaletteColors(string memory palette) virtual public pure returns (uint256[] memory, uint256, bool, bool, bool);
}

abstract contract ArtLib {
    string public ROLL_ELEMENT;
    string public ROLL_PALETTE;
    string public ROLL_ORDERED;
    string public ROLL_SHUFFLE;
    string public ROLL_RED;
    string public ROLL_GREEN;
    string public ROLL_BLUE;
    string public ROLL_DIRRED;
    string public ROLL_DIRGREEN;
    string public ROLL_DIRBLUE;
    string public ROLL_RANDOMCOLOR;
    string public ROLL_STYLE;
    string public ROLL_COLORCOUNT;
    string public ROLL_GRAVITY;
    string public ROLL_GRAIN;
    string public ROLL_DISPLAY;
    string public ELEM_NATURE;
    string public ELEM_LIGHT;
    string public ELEM_WATER;
    string public ELEM_EARTH;
    string public ELEM_WIND;
    string public ELEM_ARCANE;
    string public ELEM_SHADOW;
    string public ELEM_FIRE;
    string public NAT_PAL_JUNGLE;
    string public NAT_PAL_SPRING;
    string public NAT_PAL_CAMOUFLAGE;
    string public NAT_PAL_BLOSSOM;
    string public NAT_PAL_LEAF;
    string public NAT_PAL_LEMONADE;
    string public NAT_PAL_BIOLUMINESCENCE;
    string public NAT_PAL_RAINFOREST;
    string public LIG_PAL_PASTEL;
    string public LIG_PAL_HOLY;
    string public LIG_PAL_SYLVAN;
    string public LIG_PAL_GLOW;
    string public LIG_PAL_SUNSET;
    string public LIG_PAL_INFRARED;
    string public LIG_PAL_ULTRAVIOLET;
    string public LIG_PAL_YANG;
    string public WAT_PAL_ARCHIPELAGO;
    string public WAT_PAL_FROZEN;
    string public WAT_PAL_VAPOR;
    string public WAT_PAL_DAWN;
    string public WAT_PAL_GLACIER;
    string public WAT_PAL_SHANTY;
    string public WAT_PAL_VICE;
    string public WAT_PAL_OPALESCENT;
    string public EAR_PAL_ARID;
    string public EAR_PAL_RIDGE;
    string public EAR_PAL_COAL;
    string public EAR_PAL_TOUCH;
    string public EAR_PAL_BRONZE;
    string public EAR_PAL_SILVER;
    string public EAR_PAL_GOLD;
    string public EAR_PAL_PLATINUM;
    string public WIN_PAL_BERRY;
    string public WIN_PAL_BREEZE;
    string public WIN_PAL_JOLT;
    string public WIN_PAL_THUNDER;
    string public WIN_PAL_WINTER;
    string public WIN_PAL_HEATHERMOOR;
    string public WIN_PAL_ZEUS;
    string public WIN_PAL_MATRIX;
    string public ARC_PAL_PLASTIC;
    string public ARC_PAL_COSMIC;
    string public ARC_PAL_BUBBLE;
    string public ARC_PAL_ESPER;
    string public ARC_PAL_SPIRIT;
    string public ARC_PAL_COLORLESS;
    string public ARC_PAL_ENTROPY;
    string public ARC_PAL_YINYANG;
    string public SHA_PAL_MOONRISE;
    string public SHA_PAL_UMBRAL;
    string public SHA_PAL_DARKNESS;
    string public SHA_PAL_SHARKSKIN;
    string public SHA_PAL_VOID;
    string public SHA_PAL_IMMORTAL;
    string public SHA_PAL_UNDEAD;
    string public SHA_PAL_YIN;
    string public FIR_PAL_VOLCANO;
    string public FIR_PAL_HEAT;
    string public FIR_PAL_FLARE;
    string public FIR_PAL_SOLAR;
    string public FIR_PAL_SUMMER;
    string public FIR_PAL_EMBER;
    string public FIR_PAL_COMET;
    string public FIR_PAL_CORRUPTED;
    string public STYLE_SMOOTH;
    string public STYLE_PAJAMAS;
    string public STYLE_SILK;
    string public STYLE_RETRO;
    string public STYLE_SKETCH;
    string public GRAV_LUNAR;
    string public GRAV_ATMOSPHERIC;
    string public GRAV_LOW;
    string public GRAV_NORMAL;
    string public GRAV_HIGH;
    string public GRAV_MASSIVE;
    string public GRAV_STELLAR;
    string public GRAV_GALACTIC;
    string public GRAIN_NULL;
    string public GRAIN_FADED;
    string public GRAIN_NONE;
    string public GRAIN_SOFT;
    string public GRAIN_MEDIUM;
    string public GRAIN_ROUGH;
    string public GRAIN_RED;
    string public GRAIN_GREEN;
    string public GRAIN_BLUE;
    string public DISPLAY_NORMAL;
    string public DISPLAY_MIRRORED;
    string public DISPLAY_UPSIDEDOWN;
    string public DISPLAY_MIRROREDUPSIDEDOWN;

    function getElementByRoll(uint256 roll) virtual public pure returns (string memory);
    function getPaletteByRoll(uint256 roll, string memory element) virtual public pure returns (string memory);
    function getNaturePaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getLightPaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getWaterPaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getEarthPaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getWindPaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getArcanePaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getShadowPaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getFirePaletteByRoll(uint256 roll) virtual public pure returns (string memory);
    function getColorCount(uint256 roll, string memory style) virtual public pure returns (uint256);
    function getStyleByRoll(uint256 roll) virtual public pure returns (string memory);
    function getGravityByRoll(uint256 roll) virtual public pure returns (string memory);
    function getGravityLimitedByRoll(uint256 roll) virtual public pure returns (string memory);
    function getGrainByRoll(uint256 roll) virtual public pure returns (string memory);
    function getDisplayByRoll(uint256 roll) virtual public pure returns (string memory);
    function getColorCode(uint256 color) virtual public pure returns (string memory);
    function compareStrings(string memory a, string memory b) virtual internal pure returns (bool);
    function getScript() virtual public pure returns (string memory);
}