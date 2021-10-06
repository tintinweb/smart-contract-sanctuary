/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

/** 
 * LootPeaks is an experimental work, NFT series inspired by the infamous Loot. 
 * 8849 randomly (not verifiably random unfortunately) generated colorful on-chain SVGs contain name, height, Alpine Grade data and a hill visual.
 * Name data derived from a sample list of real peak names all around the world.
 * Deployed to polygon, bsc and avalanche mainnets on 10.05.2021.
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

/*
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

contract LootPeaks is ERC721Enumerable, ReentrancyGuard, Ownable {
    
    constructor() ERC721("LootPeaks", "PEAKS") Ownable() {}

    string[] private grades = ["F", "PD", "AD", "D", "TD", "ED", "ABO"];

    string[] private peakImagesCommon = [
        '<path d="M302.5,25.89l26.7,28.69H301l-5.73-19.1Zm-3.36,9.29,3.56-5,11.39,12.18-1.32,3.89,1,6.39-2.86-6.34L302.7,33ZM256.6,54.59l28.65-32,15.18,32Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M304.94,54.37l-2.31-5.93,1.64-5.77s6.36,7.55,9.36,11.7Zm9.91,0c-.2-2.3-.41-5.19-.41-5.19l5.19,5.19Zm-56.73.06-8.23-.21,4.74-2.59,3.48,2.8Zm6.15.16-5.41-.15-1.7-4.74S260.89,52.3,264.27,54.59Zm-21.4-1,12-11.4,7,3.49L295.2,17l34,37.38h-8.1L295.94,23.27l3.1,14a37.94,37.94,0,0,0-3.55-4.06c-.74-.45-1.62,6.23-1.62,6.23l8.89,15H269.88L266,54.22l-9.76-8.78-8,8.3-5.34-.15Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M254.6,52.5l9.1-9.7,6,3.27,18-17.63L293.58,33l6.28-2.14,7.56,7.31-7.84-3.9L294.46,40l-5.3-5.63L268.41,48.79l-4.31-3.48Zm-5.82,2.09,14.29-15.4,7.11,3L287.6,25.47l6.51,4.9,5.9-2.84L329.2,54.59Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<polygon points="239.05 58.95 273.1 31.12 276.94 35.56 290.7 23.56 329.2 55.7 310.4 45.18 311.28 55.54 290.56 29.63 295.15 42.21 288.35 37.78 296.18 57.16 283.61 49.62 279.32 57.76 275.18 51.39 265.69 57.76 272.96 39.69 261.11 47.1 262.29 42.63 239.05 58.95 239.05 58.95" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M275.61,26.82,279.69,31l-9.91,13.32,5.06-11.67L272.1,30.3Zm23.23.64,26.24,25.7-19-1.41L293.84,39l9,5.78-7.1-12.51,8.8,4.74Zm-54,27.13,30.59-30.41,5.77,5.62L293.2,19l36,35.58Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M289,23.62l-11.25,9.71L279.26,39,270,49.39l9.83-5.27,6.75.24-2.74-5.78,3.91-3L289,23.66Zm6.6,9.1-.83,4.44-4.24,3.27,5-.15L297.77,42l1-2.45L303.59,38l-7.84-5.27Zm16.35,4-7,5.85h-3.54l-4.88,6.83L302,47.23l3.78-.37,4.59.23L312,36.79ZM250.49,54.59l39.64-36.26,16.28,19.84L312,34,329.2,54.44l-6.32.15Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M282.94,24.12l-8,7.45,2,1V39l-5,5.91,5.63.94.21,3.29,6.5-5.61.57-4.39-5.24-.7,4.3-5.3V29.39l-1-5.27ZM308.41,37.7l-9.61,6.64L302.61,46l-1.79,8.22,9.7-8.44-2.11-8.07ZM268.2,29.28,256.9,41.86,265,39.12l-3.48,5.55,9.12-3.33.15-4.87,1-6Zm-28,23.9L268.37,25.8l5.93,2.67,8.59-9,20.72,18.65,5.59-2.8,20,18-18.5-5.57L300.49,59l-12.13-15.1L271.49,56.73l-7.4-8.87-23.83,5.32Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M251.46,21,235.55,41.66l5.32,1,11,9.33,5.77,2.37L256,41.74l-8.13,1.61L255.17,36l-3.7-15ZM222.82,52.76l27.5-37.29L257.45,24,277.91,7.76,295.64,22l6.81-2.23L329.1,52.6,300.51,32.92l-26.92,25,3.1-12.58,16.63-21-15.71-12L262.32,24.65l11.59,14.63-7.26,3-4.89,8.59L264.43,58l-15-2.67L238.07,45.06Z" fill="#221f20" fill-rule="evenodd"/></svg>'
    ];
    string[] private peakImagesUncommon = [
        '<polygon points="247.48 51.53 279.22 13.27 287.09 20.39 294.41 11.16 308.06 31.34 315.36 27.32 329.2 54.59 321.89 50.48 320.36 53.84 314.89 47.4 309.7 47.4 313.72 53.55 303.25 49.03 302.28 40.38 292.59 21.36 286.44 34.33 294.22 44.8 286.91 42.02 287.4 51.73 275.66 42.4 279.98 30.57 272.48 29.91 272.19 33.66 274.41 36.05 271.05 35.97 271.83 47.4 261.23 52.98 265.09 47.67 259.47 45.84 247.48 51.53 247.48 51.53" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<polygon points="239.85 58.95 273.61 31.35 277.41 35.77 291.06 23.89 329.2 55.72 310.58 45.3 311.45 55.57 290.92 29.88 295.48 42.37 288.72 37.97 296.48 57.19 284.01 49.7 279.76 57.77 275.65 51.47 266.26 57.77 273.45 39.87 261.72 47.2 262.89 42.76 239.85 58.95 239.85 58.95" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M276.08,27.39l4,4.18-9.83,13.2,5.08-11.58-2.71-2.35Zm23.12.66,26,25.43-18.94-1.34L294.2,39.48l8.89,5.74-7-12.41,8.73,4.7ZM245.58,54.59l30.27-30.15L281.57,30l11.88-10.71L329.2,54.59Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M289.37,24.26,278.2,33.87l1.47,5.57-9.14,10.35,9.74-5.21,6.69.22-2.76-5.72,3.89-3,1.24-11.81Zm6.54,9-.8,4.4-4.27,3.25,5-.16,2.2,1.69L299,40l4.76-1.52L296,33.3Zm16.21,3.54-7,5.79h-3.45l-4.88,6.78,5.46-2.17,3.74-.34,4.55.22,1.58-10.21Zm-61,17.79,39.36-35.9,16.13,19.65,5.59-4.14,17,20.25-6.29.13Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M282.83,24.34l-8,7.4,2,1v6.4l-4.94,5.92,5.6.93.24,3.33,6.49-5.58.59-4.37-5.24-.72,4.29-5.25V29.57l-1-5.23Zm25.76,13.54-9.53,6.64,3.74,1.62L301,54.28l9.6-8.36-2-8Zm-39.82-8.36L257.54,42l8-2.72-3.41,5.51,9-3.27.13-4.84,1-5.94-3.47-1.22ZM241,53.23,268.9,26.08l5.87,2.66,8.51-9,20.56,18.52,5.56-2.74,19.8,17.9-18.33-5.63L300.72,59l-12-15L272,56.74l-7.33-8.8Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M252.26,21.13,236.49,41.59l5.28,1,10.92,9.21,5.74,2.33-1.64-12.47-8,1.58L256,35.91ZM223.87,52.61l27.33-37,7,8.52L278.46,8l17.6,14.08,6.73-2.2L329.2,52.46,300.91,32.94,274.2,57.74l3.06-12.5L293.7,24.42,278.2,12.54,263,24.72l11.45,14.52-7.19,3-4.85,8.5,2.65,7-14.81-2.65L239,45Z" fill="#221f20" fill-rule="evenodd"/></svg>'
    ];
    string[] private peakImagesRare = [    
        '<path d="M255.21,52.22l9-9.61,5.94,3.24,17.93-17.47L294,32.93l6.24-2.13,7.52,7.26-7.9-3.89-5.1,5.66-5.28-5.58L268.94,48.56l-4.23-3.44Zm-5.74,2.37,14.18-15.27,7,2.93L288,25.68l6.45,4.83,5.85-2.77,28.9,26.85Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<path d="M305.52,54.57l-2.33-5.92,1.61-5.71s6.3,7.44,9.31,11.6Zm9.83,0c-.2-2.28-.41-5.16-.41-5.16l5.13,5.16Zm-56.26-.14L251,54.2l4.7-2.51Zm6.1.16-5.36-.16-1.64-4.7,7,4.82Zm-21.2-.7,11.89-11.37,7,3.45,33-28.47L329.6,54.57h-8l-25-30.82,3.08,13.9a34.75,34.75,0,0,0-3.48-4.07c-.74-.45-1.6,6.15-1.6,6.15l8.8,14.84H270.77l-3.84-.14-9.66-8.73-8,8.23L244,53.8Z" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<polygon points="248.21 53.37 279.66 15.44 287.48 22.49 294.71 13.33 308.26 33.34 315.49 29.36 329.2 56.41 321.96 52.31 320.43 55.64 315.01 49.27 309.87 49.27 313.87 55.36 303.48 50.88 302.54 42.31 292.92 23.43 286.81 36.29 294.53 46.69 287.28 43.93 287.75 53.55 276.14 44.3 280.42 32.59 272.99 31.91 272.7 35.64 274.89 38.02 271.56 37.93 272.32 49.27 261.85 54.8 265.64 49.55 260.07 47.71 248.21 53.37 248.21 53.37" fill="#221f20" fill-rule="evenodd"/></svg>',
        '<polygon points="238.68 54.59 259.72 33.01 266.23 41.03 280.66 21.93 294.09 35.87 297.74 34.53 310.76 41.55 314.12 38.49 327.93 54.59 303.65 54.59 293.59 39.52 294.99 47.35 289.62 38.1 288.99 43.09 280.37 31.48 290.43 52.63 272.73 53.35 257.9 40.44 261.55 50.1 257.8 48.88 252.91 53.59 238.68 54.59 238.68 54.59" fill="#221f20" fill-rule="evenodd"/></svg>'
    ];
    string[] private colorCodes = [
        "63be7b","65bf7a","67c079","69c177","6bc176","6dc275","6fc374","71c472","73c571","75c670","77c66e","7ac76d","7cc86b","7ec96a","81c969","83ca67","85cb66","88cc64","8acc63","8dcd61","8fce5f","92ce5e","95cf5c","97d05b","9ad059","9dd157","9fd256","a2d254","a5d352","a8d351","aad44f","add44d","b0d54b","b3d54a","b6d648","b9d646","bcd744","bfd743","c2d841","c5d83f","c6d63d","c7d33c","c8d13a","c9ce39","cacc37","cbca36","ccc735","ccc534","cdc233","cec032","cebe31","cfbb30","cfb930","cfb62f","d0b42f","d0b22e","d0af2e","d0ad2e","d0ab2e","d1a82e","d1a62d","d1a42e","d0a12e","d09f2e","d09d2e","d09b2e","d0982f","cf962f","cf942f","cf9230","ce8f30","ce8d30","cd8b31","cd8931","cc8732","cb8432","cb8233","ca8033","c97e34","ca7d33","cb7c32","cc7b32","cd7931","ce7830","cf7730","d0762f","d1742f","d3732e","d4722e","d5702d","d66f2d","d76d2d","d86c2d","d96a2c","da692c","db672c","dc662c","dd642c","de622d","e0612d","e15f2d","e25d2d","e35b2e","e45a2e","e5582e","e6562f","e7542f","e85230","e94f31","ea4d31","eb4b32","ec4933","ed4634","ee4434","ef4135","f03e36","f13b37","f23838"
    ];

    string[] private titles = [
        "Great",
        "Grand",
        "Grande",
        "Nevado",
        "Snowy",
        "Suur"
    ];

    string[] private chain = [
        "lootpeaks :: ethereum-mainnet",
        "lootpeaks :: polygon-mainnet",
        "lootpeaks :: bsc-mainnet",
        "lootpeaks :: avalanche-mainnet",
        "lootpeaks :: RINKEBY",
        "lootpeaks :: MUMBAI",
        "lootpeaks :: BSC-TESTNET",
        "lootpeaks :: FUJI"
    ];

    string[] private prefixes = [
        "Mount",
        "Mont",
        "Mountain",
        "Monte",
        "Aiguille"
        "Aguja",
        "Morro",
        "Pico",
        "Topo",
        "Cerro",
        "Sierra",
        "Cerro",
        unicode"Dôme",
        "Pointe",
        "Rock of",
        "Puncak",
        "Piton",
        unicode"Volcán",
        "Jabal",
        "Jebel",
        "Serra",
        "Muntele",
        "Piz",
        "Doi"
    ];

    string[] private suffixes = [
        "Peak",
        "Mountain",
        "Hill",
        unicode"Dağı",
        "Kuh",
        "Shan",
        "Volcano",
        "Kangri"
    ];

    string[] private csuffixes = [
        unicode"høj",
        "bjerg",
        unicode"dağ",
        "horn",
        "spitze",
        "toppen"
    ];

    string[] private names = [
        "Agou",
        "Bonanza",
        "Hasan",
        "Eagle",
        "Omu",
        unicode"Yerupajá",
        unicode"Fábrega",
        "Everest",
        "Kinabalu",
        "Kazbek",
        "Janga",
        "Moon",
        "Annapurna",
        "Chimborazo",
        "Muztagh",
        "Karisimbi",
        "Maroon",
        "Olympus",
        "Kings",
        unicode"Tödi",
        "Habicht",
        "Argonaut"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function randomNumber (string memory input) internal pure returns (uint256[3] memory) {
        uint256[3] memory randomNumbers = [
        random(string(abi.encodePacked(input, "Name", "42"))),
        random(string(abi.encodePacked(input, "Title"))),
        random(string(abi.encodePacked(input, "Hill", "666")))
        ];
        return randomNumbers;
    }

    function getName(uint256 tokenId) internal view returns (string memory) {
        uint256 rand = randomNumber(toString(tokenId))[0];
        string memory output = names[rand % names.length];
        uint256 draw = rand % 22;
        if (draw > 9 && draw < 15) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (draw > 14 && draw < 20) {
            output = string(abi.encodePacked(prefixes[rand % prefixes.length], " ", output));
        }
        if (draw > 19) {
            output = string(abi.encodePacked(output, csuffixes[rand % csuffixes.length]));
        }
        return getNameTitle(output);
    }

    function getNameTitle(string memory generatedName) internal view returns (string memory) {
        uint256 rand = randomNumber(generatedName)[1];
        string memory peakName = generatedName;
        uint256 greatness = rand % 50;
        if (greatness >= 45) {
            peakName = string(abi.encodePacked(titles[rand % titles.length], " ", generatedName));
        }
        return peakName;
    }

    function getHill(uint256 tokenId) internal view returns (string[2] memory) {
        uint256 rand = randomNumber(toString(tokenId))[2];
        string[2] memory hillType = [peakImagesCommon[rand % peakImagesCommon.length], toString((rand % peakImagesCommon.length) + 1)];
        uint256 draw = rand % 22;
        if (draw > 14 && draw < 20) {
            hillType = [peakImagesUncommon[rand % peakImagesUncommon.length], toString((rand % peakImagesUncommon.length) + peakImagesCommon.length + 1)];
        }
        if (draw > 19) {
            hillType = [peakImagesRare[rand % peakImagesRare.length], toString((rand % peakImagesRare.length) + peakImagesUncommon.length + peakImagesCommon.length + 1)];
        }
        return hillType;
    }

    function getData(uint256 tokenId) internal view returns (string[4] memory) {
        uint256 rand = randomNumber(toString(tokenId))[0];
        uint256 elevationInFeet = rand % 30000;
        uint256 findColor = (elevationInFeet * 117) / 30000;
        uint256 elevationInMeters = (elevationInFeet * 10000) / 32808;
        string[4] memory elevationData = [toString(elevationInMeters), toString(elevationInFeet), colorCodes[findColor % colorCodes.length], grades[rand % grades.length]];
        return elevationData;
    }

    function getChain() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        string memory output;
        if (chainId == 1) {
            output = chain[0];
        }
        if (chainId == 137) {
            output = chain[1];
        }
        if (chainId == 56) {
            output = chain[2];
        }
        if (chainId == 43114) {
            output = chain[3];
        }
        if (chainId == 4) {
            output = chain[4];
        }
        if (chainId == 80001) {
            output = chain[5];
        }
        if (chainId == 97) {
            output = chain[6];
        }
        if (chainId == 43113) {
            output = chain[7];
        }
        return(output);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[14] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="350" height="350" viewBox="0 0 350 350"><defs><linearGradient id="a" x1="51.5" y1="320.5" x2="1" y2="100.5" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#63be7b"/><stop offset="0.3" stop-color="#c5d83f"/><stop offset="0.7" stop-color="#c97e34"/><stop offset="1" stop-color="#f23838"/></linearGradient></defs><path d="M0,0H350V350H0Z" fill="#';
        parts[1] = getData(tokenId)[2];
        parts[2] = '"/><rect width="350" height="350" stroke="#000" stroke-width="6" fill="none"/><text font-size="21" font-weight="bold" text-anchor="end" transform="translate(330 79.59)">';
        parts[3] = getName(tokenId);
        parts[4] = '</text><text font-size="14" text-anchor="end" transform="translate(330 273)">';
        parts[5] = getData(tokenId)[3];
        parts[6] = '</text><text font-size="14" text-anchor="end" transform="translate(330 309)">';
        parts[7] = getData(tokenId)[0];
        parts[8] = ' m</text><text font-size="14" text-anchor="end" transform="translate(330 324)">';
        parts[9] = getData(tokenId)[1];
        parts[10] = ' ft</text><text font-size="5" transform="translate(5 345)">';
        parts[11] = getChain();
        parts[12] = '</text><path d="M21.17,323.1h74V79.59h-74Z" fill="#fff" stroke="#000" stroke-width="2" opacity="0.1"/><path d="M47.17,315.31h20V101.11h-20Z" stroke="#000" stroke-width="0.25" fill="url(#a)"/><text font-size="9.74" transform="translate(38.74 94.04)">LEGEND</text><text font-size="6.82" transform="translate(70.67 317.75)">0 ft</text><text font-size="6.82" transform="translate(70.67 247.8)">10000</text><text font-size="6.82" transform="translate(70.67 176.4)">20000</text><text font-size="6.82" transform="translate(70.67 105)">30000</text><text font-size="6.82" text-anchor="end" transform="translate(43.67 317.75)">m 0</text><text font-size="6.82" text-anchor="end" transform="translate(43.67 248.45)">3000</text><text font-size="6.82" text-anchor="end" transform="translate(43.67 177.05)">6000</text><text font-size="6.82" text-anchor="end" transform="translate(43.67 105.65)">9000</text>';
        parts[13] = getHill(tokenId)[0];
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8], parts[9], parts[10], parts[11], parts[12], parts[13]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"description":"LootPeaks is an experimental NFT series inspired by the infamous Loot. 8849 randomly generated colorful on-chain SVGs contain name, height and Alpine Grade data, derived from a sample list of real peak names all around the world.","image":"data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","name":"', getName(tokenId), '","attributes":[{"trait_type":"Peak ID","value":"', toString(tokenId), '"},{"display_type":"date","trait_type":"birthday","value":"', toString(block.timestamp), '"},{"trait_type":"Peak Height In Meters","value":"', getData(tokenId)[0], '"},{"trait_type":"Peak Height In Feet","value":"', getData(tokenId)[1], '"},{"trait_type":"Peak Background Color","value":"#', getData(tokenId)[2], '"},{"trait_type":"Alpine Grade","value":"', getData(tokenId)[3], '"},{"trait_type":"Hill Visual Type","value":"', getHill(tokenId)[1], '"}]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 8831, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 8830 && tokenId < 8850, "Token ID invalid");
        _safeMint(owner(), tokenId);
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