/**
 *Submitted for verification at Etherscan.io on 2021-10-29
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



contract Degens is ERC721Enumerable, ERC2981ContractWideRoyalties, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant MINT_COST = 50000000000000000; // 0.05 ETH
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_RESERVE = 150;
    uint256 public constant MAX_PER_MINT = 20;
    uint256 public constant ROYALTY_BASIS_PTS = 1000; // 10%

    address public contractDev = 0x2533798d5f1386bbA9101387Ff3342FFFC220E27;

    string public PROVENANCE;
    string private baseDegenURI;
    uint256 public tokenOffset = MAX_SUPPLY;
    bool public mintingActive = false;
    bool public earlyMintingActive = false;

    mapping(address => uint256) whitelist;

    constructor() ERC721("gmdegens", "GMD") Ownable() {
        _setRoyalties(owner(), ROYALTY_BASIS_PTS);

        // snapshot of mint pass and founders pass holders
        whitelist[0xff88bD69dc4D42B292B4ACADe8E24A20979C0098] = 2;
        whitelist[0xfF3aB8989bf275CE128Ca69481bdabbe93055876] = 2;
        whitelist[0xfDF0eaDE0C4ba947999e7885b60099985347eE7A] = 2;
        whitelist[0xfa2Ff875d5DED2d6702e3d35678aB9fe674bd68B] = 2;
        whitelist[0xF8038FD7DF0862faA5708c174b485F519698d628] = 2;
        whitelist[0xF641e2800a94b49B8b428353ea71aAE85865decE] = 2;
        whitelist[0xf33f4dF9d5693EC35Be246557E52bA250cF437Dd] = 2;
        whitelist[0xeba06532a72bec44A1d33130aaa7C45c31e502F6] = 2;
        whitelist[0xeA3AC159b6a623D503e48E3c1726072f20c73089] = 2;
        whitelist[0xe8f596d68aEfc6aDdF7E0b4a3A1c5f462F6AF1E0] = 2;
        whitelist[0xe8514Ba313Fb227Da83103BbcF57ec0eD710a325] = 2;
        whitelist[0xE5e2a3E8fc49De0F2Fd7b87d6D88daA5A305ead9] = 2;
        whitelist[0xE53008a668836514B6AC7E4039c788De7850d438] = 2;
        whitelist[0xE0cD6DbcbAbc6aA967D1Dc318F7526090d47606C] = 2;
        whitelist[0xDAc4f4356E9F92ed39427bb96A47E6981C7B3375] = 2;
        whitelist[0xD3b129F1F796f5C26210Eb8f39a938175bDbe215] = 2;
        whitelist[0xcEfa22191E49d3D501c57c9a831D01a09f7c1112] = 2;
        whitelist[0xc9fbb3a7869aF25aefA08914021520cd05aF0E1D] = 2;
        whitelist[0xBDB0Dd845E95d2E24B77D9bEf54d4dF82bAF8335] = 2;
        whitelist[0xBD9dDf4b73aa454CC6D47E7C504eb73157BCf35D] = 2;
        whitelist[0xbC6e70CB9b89851E6Cff7cE198a774549f4c0F0C] = 2;
        whitelist[0xb7D7cE36de85E0E080b1F94Fa7cd8A47378B1b4c] = 2;
        whitelist[0xB4e69092a6EB310559e50Bb160ae36f7193b6A99] = 2;
        whitelist[0xB1b18bDE5DF9b447727c985e3942Ea937fb0C430] = 2;
        whitelist[0xA54E54567c001F3D9f1259665d4E93De8A151A5e] = 2;
        whitelist[0xa32f008Cb5Ae34a91abe833A64b13E4E58969B76] = 2;
        whitelist[0x9D9Fa64Bd35F06c9F0e9598a7dF93c31d72D14Ce] = 2;
        whitelist[0x99e0a9e19775b61b50C690E8F713a588eA3F28bF] = 2;
        whitelist[0x9996e496a36B42897b44a5b0Df62A376C3390098] = 2;
        whitelist[0x98938eDFfA707492A6E76420d2F42458CC1AC15B] = 2;
        whitelist[0x95aF39507c413c12E33ACc34f044d12e5F86f551] = 2;
        whitelist[0x946eC68B81f439b490b489F645c4D73bC8f9414c] = 2;
        whitelist[0x92a7BD65c8b2a9c9d98be8eAa92de46d1fbdefaF] = 2;
        whitelist[0x9260ae742F44b7a2e9472f5C299aa0432B3502FA] = 2;
        whitelist[0x90ee9AF63F5d1dC23EfEE15f1598e3852165E195] = 2;
        whitelist[0x906a2C11B033d0799107Ae1eFEDA2bd422133D7d] = 2;
        whitelist[0x8Fb2A5d8736776291388827E9787F221a1d3633a] = 2;
        whitelist[0x8cC140E41f064079F921f53A1c36e765DB4B7e59] = 2;
        whitelist[0x889C97c24be9bBD5Fab464ba89D47f621Fbe019c] = 2;
        whitelist[0x87b895F37A93E76CF1C27ed68B38d77fEE0f7867] = 2;
        whitelist[0x8297A5971a05903D4d33453425D1B800730B10e7] = 2;
        whitelist[0x7EFB9007074BBe3047c607531e77D6eF840D8FD5] = 2;
        whitelist[0x774363d02e2C8FbBEB5b6B37DAA590317d5C4152] = 2;
        whitelist[0x7305ce3A245168dDc87c3009F0B4b719BC4519F5] = 2;
        whitelist[0x723D5453Fc08769cb454B5B95DB106Bf396C73B3] = 2;
        whitelist[0x6D1fd99F6749C175F72441b04277eC50056A6ABE] = 2;
        whitelist[0x691b7e59EA6E8569aBC4C2fE6a8bCAe49D802924] = 2;
        whitelist[0x64211c2B214Ee2543AaA224EAdd9715818f085Ed] = 2;
        whitelist[0x63E0bD39F6EAd960E2C6317D4540DECaf7ab53bA] = 2;
        whitelist[0x6325178265892Ab382bf4f2BcF3745D2c4A987e6] = 2;
        whitelist[0x5b046272cB9fDe317aB73a836546E52B1F2d81F3] = 3;
        whitelist[0x4f368Dfb630Ba2107e51BABD062657DC7cb6381f] = 2;
        whitelist[0x4D92A462e97443a72524664fC2300d07c208b4aF] = 2;
        whitelist[0x4D4e5506C75642E2cB4C9b07CCcE305E71e30c15] = 2;
        whitelist[0x487d0c7553c8d88500085A805d316eD5b18357f8] = 4;
        whitelist[0x486843aD8adb101584FCcE56E88a09e6f25D16d1] = 4;
        whitelist[0x41A88a01987174d49bBc72b6Ef46b58727aDc4d0] = 2;
        whitelist[0x4115E41D52C6769C4f6D00B9aA6046dF92D41870] = 2;
        whitelist[0x402112921222090851acbE280bB68b44bfe3eeB2] = 2;
        whitelist[0x3a86FD7949F1bD3b2Bfb8dA3f5e86cFEDC79e0Fb] = 2;
        whitelist[0x38D0401941d794D245d41870FcdD9f8Ec61C1352] = 2;
        whitelist[0x383b8F1B11812E81D78f945ac344CbF9DD329316] = 2;
        whitelist[0x332552959a4d437F2Eecdce021E650ED1F343E63] = 2;
        whitelist[0x324Edc2211EF542792588de7A50D9A7E56d95C3a] = 2;
        whitelist[0x3020d185B7c6dAE2C2248763Cc0EAB2b48BEb743] = 2;
        whitelist[0x2CdbF64c0327a731b53bDD6ce715c3aD6BA099C7] = 2;
        whitelist[0x2b8b26ceF820911E18db996396e8053cA1A4459C] = 2;
        whitelist[0x25eA8dB35eb9F34cC4e3e1e7261096Fe86b006D2] = 2;
        whitelist[0x24D10De50DCFcB21d9620bE3042Ee70aDF69d1D4] = 2;
        whitelist[0x229a6A5Da12Ca0d134Fc8AeC58F3359E8eE247b6] = 2;
        whitelist[0x1b7B45A9dBE2cc3df954bF52D49D5453a357c196] = 2;
        whitelist[0x121b37caDb25A2e7D0c8389aae256144fE0f89A8] = 2;
        whitelist[0x1200a40C18804F6B5e01f465D5489E53340d61EC] = 2;
        whitelist[0x11aE298E74A77ec562A5Ff262eE0586568eb03c5] = 2;
        whitelist[0x0dC83606A23cA9dd1a161CC7B95764b7E7424093] = 2;
        whitelist[0x0CB7A06ec845EDCA1AF6DB6b6538C4Ca0942019A] = 2;
        whitelist[0x05c232CE5BCC9bFDB838B41A7870Aea5E4fA0fA8] = 2;
        whitelist[0x038c275A365b7bF84fbc5C86156619943DF1c123] = 2;
        whitelist[0x010edAFA8a3C464413A680a1F6a7115B4eE4c74d] = 2;
        whitelist[0xF547Ce1247D3F3959794Ca6Ccad99bf56b7CE52c] = 4;
        whitelist[0xe6Fda5F67ebA9dE2cfb0fB2a0734969C951653be] = 4;
        whitelist[0xe3E55Fae5B27f1Ec658d3808ecc6137E8F466F1f] = 4;
        whitelist[0xcB724B38D476cd8e39bA12B1D06c34b8Be0E0B32] = 4;
        whitelist[0x29D5cea7D511810f3Ff754886B898FcE16A6D8fD] = 4;
        whitelist[0x17E31bf839acB700e0F584797574A2C1FDe46d0b] = 4;
        whitelist[0x10b54d8e8E7EA708E5C71915401261F92E03B376] = 4;
        whitelist[0xEF3feA2aB12C822dc3437bE195A1BFFc67f2AD08] = 6;
        whitelist[0x230FCac06ae171309ea2E0D826cb021A0F786b81] = 6;
        whitelist[0xBD9E322303Fa0EE764d8Efb497Ca4b81589A281a] = 10;
        whitelist[0x0c2DFdDdeEF2deBBE58fEC8cf93D2daaCDBe1c1e] = 2;
        whitelist[0x48c61D3aB04537448a16F52cF508Bc0dd71316b5] = 2;
        whitelist[0x3094cf9A360Fb98ca7a9Dc666751DA9C16E45394] = 3;
        whitelist[0xEcDC1c32E4b0bFf00afF1d8f809bDD8b33A58969] = 2;
        whitelist[0x46c72258ef3266BD874e391E7A55666A532aeCbA] = 2;
        whitelist[0x20f3C88d39c03262eFDDAEE16768e7a334Ff2A3d] = 2;
        whitelist[0xB31999Ca48Bd9EFC065eB3E2676badD21dfa17b6] = 5;
        whitelist[0x3AaA6A59f89de6419E9392e6F94B57c98573Ae05] = 2;
        whitelist[0xA76E80209610480aafd8807a20325e7a9030ed55] = 2;
        whitelist[0x7b5585D844A5af06e274C7D66Ce12A2a3d2469f0] = 2;
        whitelist[0x6562A7e32a35c479B9044A75D96Ae38a9fe12aB7] = 2;
        whitelist[0x7309e1582d611D3ef9DBA6FCe709F177240E0fd9] = 2;
        whitelist[0x2d52538486de12CC3Ce00F60DE3CD84fD75597eE] = 2;
        whitelist[0x4574F2AEbfa00B9489fad168d2530c1AB0dA94aF] = 2;
        whitelist[0xDa56B1ae899Fab58cbB0EEDA7D667aF0DcAe5572] = 2;
        whitelist[0xdc96fd721474C3632D6dd5774280a7E1650a3b00] = 2;
        whitelist[0xd85Cc97FFC3b8Dc315F983f1bE00D916EF59e2cB] = 2;
        whitelist[0x00b6852E20Cd924e536eD94Be2140B3728989cFc] = 2;
        whitelist[0xcA1bCc5AfDcc45E87B1B73AdCCa5863f01C46629] = 5;
        whitelist[0xe7733E30360B98677DA67F406b23327cA96A4750] = 2;
        whitelist[0x3Cd9C90E94850BFfC6C1b7f8fF0Cbd151740Ef5b] = 2;
        whitelist[0x59811762A399b4eCED3248406cE5412f5F2b6cb2] = 3;
        whitelist[0xB0b8D3345A7276170de955bD8c1c9Bc787d62519] = 2;
        whitelist[0x3b8b35D37aBC65CcF7C78Bd677241870417c8451] = 2;
        whitelist[0x52D1c62020208dFF40eaAe4f1C41c51D82AB3A4e] = 2;
        whitelist[0xB8221D5fb33C317CfBD912b8cE4Bd7C7740fAF88] = 2;
        whitelist[0x20A32b6266febb861E0771116FB7B4a7dd6014cE] = 2;
        whitelist[0xBD3fD7b44CA24741Db067ace1decEe9B164e31CA] = 2;
        whitelist[0xfAcEAA25C46c84F3eE20F979A8bcB6d8deC0Ed78] = 3;
        whitelist[0x7ad3d35f3D0970AE97D638C5d461E82401344e67] = 3;
        whitelist[0x46e5a4b4721AD087680dC6c2EAE5E4Aa93F8f848] = 2;
        whitelist[0x5220CD067677bc7aE6016bd0C8c4eb58B118B77b] = 1;
        whitelist[0x52D4E9c6b23cFAfA13938034814AcdAB895B6848] = 1;
        whitelist[0xB6B402de2B7fE014500C7e07dFE1eD5c291FFCa8] = 1;
        whitelist[0x376a61DC5B30C805089eB027A49F9CA7c21a6c3F] = 1;
        whitelist[0x0663C5cD5F11DdDE32630EE929ac00f0C3d4dB9F] = 1;
        whitelist[0x70817f848cC79ACB114F606685E8751943fB02C2] = 1;
        whitelist[0x95dC53A380D5AbB83438b9308f8219D603543Eed] = 1;
        whitelist[0x9Da3f811143ED2208085f460754b32788913a788] = 1;
        whitelist[0x36bBA2955490f46396E87f6DB052e1106dEAAcA1] = 1;
        whitelist[0xb59C86A4c28bd2663855E02Be15d5a31d1C4eb0b] = 1;
        whitelist[0xcF1e264B0B8Fa3cd014Cd7d32A81f5b46Bc06250] = 2;
        whitelist[0x29aC2D2A79Dfc7B29277E328235F572C7E626b9C] = 1;
        whitelist[0xCCdf62316CA146Ee87AbB2B2c6Fe686A2319466c] = 1;
        whitelist[0x1E5139c78050D014f05968Dc5c0755dAe958481B] = 1;
        whitelist[0x5eaF958de68f09E7b18D9dc3e424c01ca9136e3e] = 1;
        whitelist[0x75321Bc4b5A2aA044C33f1f51e0Ec6e282E91e25] = 1;
        whitelist[0x60ef47a7A264818797Ea298d045e7Ef8bA6ac16B] = 1;
        whitelist[0xA7cA01E775Dd42ef73f1F87d08e774a9235d516d] = 1;
        whitelist[0x8d7c651b9CFfFb23B98c533F11d10ea0BbA8Dd9B] = 2;
        whitelist[0x8d4dAbA34C92E581F928fCA40e018382f7A0282a] = 1;
        whitelist[0x54ad9d40414eD047067ae04C6faFc199A5bb90bB] = 1;
    }

    function mintDegens(uint256 mintCount) public payable nonReentrant {
        uint256 lastTokenId = super.totalSupply();
        require(mintingActive, 'minting not enabled yet');
        require(mintCount <= MAX_PER_MINT, 'max 20 per mint');
        require(lastTokenId + mintCount <= MAX_SUPPLY, 'sold out');
        require(MINT_COST * mintCount <= msg.value, 'not enough ETH');

        for (uint256 i = 1; i <= mintCount; i++) {
            _mintDegen(_msgSender(), lastTokenId + i);
        }
    }

    function reserveDegens(uint256 reserveCount) public nonReentrant onlyOwner {
        uint256 lastTokenId = super.totalSupply();
        require(lastTokenId + reserveCount <= MAX_RESERVE, 'max reserves reached.');

        for (uint256 i = 1; i <= reserveCount; i++) {
            _mintDegen(owner(), lastTokenId + i);
        }
    }

    function mintDegensFromWhitelist(uint256 mintCount) public nonReentrant {
        uint256 lastTokenId = super.totalSupply();
        uint256 freePasses = whitelist[_msgSender()];

        require(earlyMintingActive, 'early minting not enabled yet');
        require(lastTokenId + mintCount <= MAX_SUPPLY, 'sold out');
        require(mintCount <= freePasses, 'mintCount exceeds passes for this wallet');

        whitelist[_msgSender()] = freePasses - mintCount;

        for (uint256 i = 1; i <= mintCount; i++) {
            _mintDegen(_msgSender(), lastTokenId + i);
        }
    }

    function _mintDegen(address minter, uint256 tokenId) private {
        _safeMint(minter, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        uint256 tokenIdOffset = 1 + (tokenId + tokenOffset) % MAX_SUPPLY;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdOffset.toString())) : "";
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function toggleMinting() public onlyOwner {
        mintingActive = !mintingActive;
    }

    function toggleEarlyMinting() public onlyOwner {
        earlyMintingActive = !earlyMintingActive;
    }

    function setTokenOffset(uint256 offset) external onlyOwner() {
        require(tokenOffset == MAX_SUPPLY, 'tokenOffset can only be set once');
        tokenOffset = offset % MAX_SUPPLY;
    }

    function setBaseURI(string memory baseURI) external onlyOwner() {
        baseDegenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseDegenURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractFee = balance / 40; // 2.5%

        // send contractFee to contractDev
        require(payable(contractDev).send(contractFee), "failed to send contractFee");

        // send everything else to owner
        balance = address(this).balance;
        require(payable(owner()).send(balance), "failed to withdraw");
    }

    function emergencyWithdraw() public onlyOwner {
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

}