/**
 *Submitted for verification at Etherscan.io on 2021-09-18
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


contract MoonDraw is ERC721Enumerable, ReentrancyGuard, Ownable {
    // NFT upper limit
    uint256 public maxLimit = 9999;

    mapping (uint256 => uint256) private numbers;

    mapping(address => uint256) private _claimed;

    string[] private moonsElements = [
        unicode'<path d="M83.5782064,216.58443 C102.441285,223.053244 116,240.943218 116,262 C116,284.296975 100.7971,303.043123 80.1917226,308.438019 C96.7646104,299.348617 108,281.736391 108,261.5 C108,242.885243 98.4931472,226.490929 84.0698789,216.907498 L83.5782064,216.58443 Z"></path>',
        unicode'<path d="M82.0671902,216.094258 C101.712967,222.107064 116,240.385074 116,262 C116,283.614926 101.712967,301.892936 82.0671902,307.905742 C95.4451725,297.089087 104,280.543587 104,262 C104,243.752512 95.7161934,227.43981 82.7040312,216.617347 L82.0671902,216.094258 Z"></path>',
        unicode'<path d="M80.437353,215.626992 C100.917805,221.106067 116,239.791716 116,262 C116,284.208647 100.917312,302.894543 80.4363497,308.373276 C91.3662791,296.023548 98,279.786468 98,262 C98,244.45675 91.546462,228.420804 80.8839065,216.136683 L80.437353,215.626992 Z"></path>',
        unicode'<path d="M75.9985974,214.663432 C98.7009942,218.471479 116,238.21554 116,262 C116,285.78481 98.7004848,305.529102 75.9975947,309.336736 C86.0367434,296.209761 92,279.801277 92,262 C92,244.337934 86.1296472,228.046962 76.2336375,214.97178 L75.9985974,214.663432 Z"></path>',
        unicode'<path d="M74.7907014,214.476639 C98.08453,217.775303 116,237.79546 116,262 C116,286.204886 98.084017,306.225271 74.789701,309.523503 C83.1752124,295.652753 88,279.389821 88,262 C88,244.724533 83.2384588,228.561184 74.9561804,214.750756 L74.7907014,214.476639 Z"></path>',
        unicode'<path d="M72.3883115,214.197909 C96.8412535,216.41414 116,236.969687 116,262 C116,287.030313 96.8412535,307.58586 72.3883115,309.802091 C79.808208,295.488363 84,279.233704 84,262 C84,244.768716 79.8093853,228.516202 72.391709,214.206012 L72.3883115,214.197909 Z"></path>',
        unicode'<path d="M68.0120343,214.000001 C94.5161715,214.006504 116,235.494344 116,262.000001 C116,288.244571 94.9373256,309.569691 68.7937678,309.993569 L68.0146757,310.000631 C74.4371579,295.301368 78,279.066757 78,262.000001 C78,245.431458 74.6421356,229.647186 68.5698052,215.290585 L68.0120343,214.000001 Z"></path>',
        unicode'<path d="M68,214 C94.509668,214 116,235.490332 116,262 C116,288.244571 94.9373256,309.569691 68.7937678,309.993569 L68,310 L68,214 Z"></path>',
        unicode'<path d="M68.7937678,214.006431 L67.9879657,214.000001 L67.9879657,214.000001 C61.5629633,228.698079 58,244.932952 58,262.000001 C58,279.067144 61.5630033,295.302103 67.9857603,310.001629 L68,310.000001 C94.509668,310.000001 116,288.509668 116,262.000001 C116,235.755429 94.9373256,214.430309 68.7937678,214.006431 L68.7937678,214.006431 Z"></path>',
        unicode'<path d="M68,214 C66.5206445,214 65.0569199,214.066924 63.6116885,214.197909 C56.1919882,228.510876 52,244.765892 52,262 C52,279.234106 56.1919872,295.48912 63.611935,309.801017 C65.0569199,309.933076 66.5206445,310 68,310 C94.509668,310 116,288.509668 116,262 C116,235.490332 94.509668,214 68,214 Z"></path>',
        unicode'<path d="M68,214 C94.509668,214 116,235.490332 116,262 C116,288.509668 94.509668,310 68,310 C66.7924506,310 65.595316,309.955409 64.4101528,309.867785 C54.1250897,296.651826 48,280.041209 48,262 C48,243.958791 54.1250897,227.348174 64.4092073,214.134209 C65.595316,214.044591 66.7924506,214 68,214 Z"></path>',
        unicode'<path d="M88,214 C91.2348864,214 94.3950324,214.320002 97.4505094,214.930077 C108.958436,227.25723 116,243.806292 116,262 C116,280.193708 108.958436,296.74277 97.4519553,309.07054 C94.3950324,309.679998 91.2348864,310 88,310 C61.490332,310 40,288.509668 40,262 C40,235.490332 61.490332,214 88,214 Z" transform="translate(78.000000, 262.000000) scale(-1, 1) translate(-78.000000, -262.000000) "></path>',
        unicode'<path d="M68,214 C94.509668,214 116,235.490332 116,262 C116,288.509668 94.509668,310 68,310 C64.2056473,310 60.5141229,309.559739 56.973724,308.727515 C42.999796,297.937454 34,281.019734 34,262 C34,242.980266 42.999796,226.062546 56.9731561,215.273074 C60.5141229,214.440261 64.2056473,214 68,214 Z"></path>',
        unicode'<path d="M68,214 C94.509668,214 116,235.490332 116,262 C116,288.509668 94.509668,310 68,310 C61.0704508,310 54.4838648,308.5316 48.5344282,305.888985 C34.8879196,296.089163 26,280.082524 26,262 C26,243.917476 34.8879196,227.910837 48.5334826,218.110359 C54.4838648,215.4684 61.0704508,214 68,214 Z"></path>',
        unicode'<circle transform="translate(68.000000, 262.000000) scale(-1, 1) translate(-68.000000, -262.000000) " cx="68" cy="262" r="48"></circle>'
    ];

    string[][] private signNamesElements =[
        [
            unicode'春来花发映阳台',
            unicode'万里车来进宝财',
            unicode'若得禹门三级浪',
            unicode'恰如平地一声雷'
        ],
        [
            unicode'梧桐叶落秋将暮',
            unicode'行客归程去似云',
            unicode'谢得天公高著力',
            unicode'顺风船载宝珍归'
        ],
        [
            unicode'出入营谋大吉昌',
            unicode'似玉无瑕石里藏',
            unicode'若得贵人来指引',
            unicode'斯时得宝喜风光'
        ],
        [
            unicode'天地变通万物全',
            unicode'自荣自养自安然',
            unicode'生罗万象皆精彩',
            unicode'事事如心谢圣贤'
        ],
        [
            unicode'春来雷震百虫鸣',
            unicode'番身一转离泥中',
            unicode'始知出入还来往',
            unicode'一朝变化便成龙'
        ],
        [
            unicode'直上仙岩要学仙',
            unicode'岂知一旦帝王宣',
            unicode'青天日月常明照',
            unicode'心正声名四海传'
        ],
        [
            unicode'茂林松柏正兴旺',
            unicode'雨雪风霜总莫为',
            unicode'异日忽然成大用',
            unicode'功名成就栋梁材'
        ],
        [
            unicode'否去泰来咫尺间',
            unicode'暂交君子出于山',
            unicode'若逢虎兔佳音信',
            unicode'立志忙中事即闲'
        ],
        [
            unicode'金乌西坠兔东升',
            unicode'日夜循环至古今',
            unicode'僧道得之无不利',
            unicode'士农工商各从心'
        ],
        [
            unicode'开天辟地作良缘',
            unicode'吉日良时万物全',
            unicode'若得此签非小可',
            unicode'人行忠正帝王宣'
        ],
        [
            unicode'忽言一信向天飞',
            unicode'泰山宝贝满船归',
            unicode'若问路途成好事',
            unicode'前头仍有贵人推'
        ],
        [
            unicode'巍巍宝塔不寻常',
            unicode'八面玲珑尽放光',
            unicode'劝君立志勤顶礼',
            unicode'作善苍天降福祥'
        ]
    ];

    string[] private signElements = [
        unicode"上吉",
        unicode"中吉",
        unicode"小吉",
        unicode"末吉"
    ];

    string[] private backgroundColorElement = [
        unicode"#EAD1D1",
        unicode"#E0D9EA",
        unicode"#D9E4EA",
        unicode"#EFEAE7"
    ];

    string[] private cloudColorElement = [
        unicode"#FCEDED",
        unicode"#F1EAFB",
        unicode"#EBF4F9",
        unicode"#FFFFFF"
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getPhaseOfMoon(uint256 tokenId) public view returns (uint256) {
        uint256 number = numbers[tokenId];
        require( number != 0, "tokenId is invalid");
        uint256 rand = random(string(abi.encodePacked('PHASEOFTHEMOON', toString(tokenId+number))));
        return rand % 15 + 1;
    }

    function getSignNamesElements(uint256 tokenId) public view returns (string[] memory) {
        uint256 number = numbers[tokenId];
        require( number != 0, "tokenId is invalid");
        uint256 rand = random(string(abi.encodePacked('SIGNNAMESELEMENTS', toString(tokenId+number))));
        uint _sign = getSign(tokenId);
        uint256 greatness = _sign  * 3 + (rand % 3) ;
        return signNamesElements[greatness];
    }

    function getSignElement(uint256 tokenId) public view returns (string memory) {
        return signElements[getSign(tokenId)];
    }

    function getSign(uint256 tokenId) private view returns (uint256) {
        uint256 number = numbers[tokenId];
        require( number != 0, "tokenId is invalid");
        uint256 rand = random(string(abi.encodePacked('SIGNELEMENTS', toString(tokenId+number))));
        uint256 greatness = rand % 100;   

        if (greatness < 25) {
            return 0;
        }else if (greatness <51 && greatness > 24) {  
            return 1;  
        }else if (greatness < 76 && greatness > 50){
            return 2; 
        } else {
            return 3;
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[30] memory parts;
        uint256 moon = getPhaseOfMoon(tokenId);
        string memory lots = getSignElement(tokenId);
        uint256 sign = getSign(tokenId);
        string[] memory signNames = getSignNamesElements(tokenId);
        parts[0] = unicode'<svg width="100%" height="100%" viewBox="0 0 350 350" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g id="mj" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><rect fill="';
        parts[1] = backgroundColorElement[sign];
        parts[2] = unicode'" x="0" y="0" width="350" height="350"></rect><g id="13"  fill="#FFFAF7">';
        parts[3] = moonsElements[moon - 1];
        parts[4] = unicode'</g><g id="b-5" transform="translate(134.000000, 102.500000)" fill="#202020" font-family="STSongti-SC-Bold, Songti SC" font-size="14" font-weight="300" line-spacing="22"><text x="6" y="4" writing-mode="tb-rl" font-family="STSongti-SC-Bold, Songti SC" letter-spacing="8px">';
        parts[5] = signNames[3];
        parts[6] = unicode'</text><text x="32" y="4" writing-mode="tb-rl" font-family="STSongti-SC-Bold, Songti SC" letter-spacing="8px">';
        parts[7] = signNames[2];
        parts[8] = unicode'</text><text x="58" y="4" writing-mode="tb-rl" font-family="STSongti-SC-Bold, Songti SC" letter-spacing="8px">';
        parts[9] = signNames[1];
        parts[10] = unicode'</text><text x="84" y="4" writing-mode="tb-rl" font-family="STSongti-SC-Bold, Songti SC" letter-spacing="8px">';
        parts[11] = signNames[0];
        parts[12] = unicode'</text></g><text id="#-1234" font-family="STSongti-SC-Bold, Songti SC" font-size="16" font-weight="bold" fill="#202020"><tspan x="20" y="37"># ';
        parts[13] = toString(tokenId);
        parts[14] = unicode'</tspan></text>';
        parts[15] = unicode'<path d="M107.603261,106.572671 C109.728504,107.224596 111.268158,109.070164 111.528526,111.277849 L112.056948,115.758384 C112.219503,117.136704 112.160688,118.532147 111.882729,119.8919 L111.363972,122.429614 C111.188517,123.287925 111.100118,124.161751 111.100118,125.037812 L111.100118,129.113578 C111.100118,129.853198 111.03711,130.591474 110.911776,131.320398 L110.766586,132.164808 C110.552336,133.410859 109.870947,134.528298 ';
        parts[16] = unicode'108.861314,135.289342 L108.18081,135.802295 C106.777062,136.860418 104.931663,137.132309 103.282393,136.524002 L101.490113,135.862949 C100.902728,135.646302 100.263491,135.612684 99.6566222,135.766526 C99.1190532,135.9028 98.5617864,135.630274 98.3392831,135.122294 L96.5269363,130.984668 C95.7158065,129.132842 95.5391396,127.064929 96.0243951,125.102349 L96.3007776,123.98454 C96.6095845,122.735594 96.5728516,121.426171 96.1945127,';
        parts[17] = unicode'120.196501 L95.7588501,118.780518 C95.663851,118.471754 95.557396,118.166632 95.4397059,117.865784 L94.2534423,114.833374 C93.754344,113.557544 93.8928141,112.120275 94.6263049,110.963196 L95.2291503,110.012209 C95.5742276,109.467851 96.1994263,109.16782 96.8399829,109.239174 C97.5181909,109.314723 98.2021232,109.160338 98.7821131,108.800775 L100.997655,107.427258 C102.973067,106.202608 105.381229,105.891057 107.603261,106.572671 ';
        parts[18] = unicode'Z M104.356144,115.595664 C101.008637,113.869922 99.01217,113.159084 98.3667424,113.46315 C97.7383062,113.759212 97.4266285,114.124507 97.4324259,114.558509 C97.023064,114.707314 96.7274639,115.002636 96.5456256,115.444476 C95.5680049,117.819945 102.128793,117.174347 102.75809,117.146383 C102.730551,117.292036 102.700418,117.457225 102.665897,117.644942 C102.451913,118.808535 102.771404,119.946168 103.62437,121.05784 C103.512024,121.724898 ';
        parts[19] = unicode'103.085541,122.937713 102.344921,124.696286 C101.233992,127.334146 100.797273,129.47016 101.83464,130.504355 C102.872007,131.538551 106.67349,131.675568 107.753026,131.358538 C107.966217,131.29593 108.394469,131.056162 108.394469,130.875098 C108.394469,130.673039 108.147796,130.483238 107.654448,130.305696 L107.654448,130.305696 L107.636552,130.29908 C108.321089,130.478923 108.623364,130.410144 108.543376,130.092742 C108.446247,129.707326 ';
        parts[20] = unicode'108.032644,129.468472 107.302567,129.37618 C107.473502,128.850003 107.631827,128.239999 107.778239,127.545845 C108.084999,127.907071 108.351282,128.128901 108.432696,128.128901 C108.595379,128.128901 108.797738,128.128901 108.922796,127.361984 C108.946313,127.217771 108.927534,127.046324 108.864817,126.847236 C108.969195,126.883728 109.063055,126.872671 109.146395,126.814067 C109.506718,126.560689 109.024586,125.325525 107.699998,123.108573 ';
        parts[21] = unicode'L107.699998,123.108573 L107.822588,123.313507 C107.384819,121.522909 106.582886,120.393606 107.143834,120.131492 C108.03772,119.713805 108.69236,115.99795 107.856108,115.53518 C107.209065,115.177116 105.816247,115.406363 104.753699,115.646807 L104.753699,115.646807 L104.546504,115.694827 Z M101.074069,128.66991 C100.842922,128.236583 100.556087,128.101169 100.213564,128.263666 C99.6530709,128.529571 99.774078,130.117511 100.674646,129.814014 ';
        parts[22] = unicode'C101.275025,129.611684 101.428719,129.34861 101.135728,129.024792 L101.135728,129.024792 L101.135728,128.795476 Z M106.78021,116.616009 C106.826142,116.728351 106.826142,116.810376 106.78021,116.862084 C106.452558,117.230938 106.060305,117.372238 106.060305,117.247249 C106.060305,117.095977 106.300273,116.885564 106.78021,116.616009 Z" id="xzjh" fill="#BD5757"></path>';
        parts[23] = unicode'<path d="M46.8398624,306.54432 C48.2398462,297.929789 52.7727347,294.13647 60.4385279,295.164361 C68.1043212,296.192253 71.4607528,299.808123 70.5078227,306.011973 C78.2769481,305.301001 82.5949371,307.071176 83.4617898,311.322499 C84.3286425,315.573823 82.0959233,319.189369 76.7636324,322.169138 C78.7855696,324.615776 82.5233693,325.227436 87.9770315,324.004117 C87.9770315,324.004117 85.4285317,316.301559 93.9943145,315.705684 C99.7048364,';
        parts[24] = unicode'315.308433 101.71697,318.074578 100.030715,324.004117 C101.728538,325.73645 104.080472,325.12479 107.086515,322.169138 C111.595581,317.73566 112.622922,316.338323 118.59344,319.890341 C118.59344,319.890341 114.767897,319.28476 112.206456,321.237384 C109.645015,323.190009 108.795025,328.401713 103.133032,329.510523 C97.4710388,330.619334 94.8893743,328.380536 93.5606782,328.380536 C92.231982,328.380536 81.8462203,332.765191 73.5801399,';
        parts[25] = unicode'331.137857 C68.0694197,330.052968 64.8910252,328.479555 64.0449566,326.417618 C61.8765504,328.762493 58.7272733,329.793461 54.5971252,329.510523 C50.4669771,329.227585 47.5610305,327.540448 45.8792853,324.449112 C38.6264284,324.871067 35,321.825809 35,315.313335 C35,308.800862 38.9466208,305.877857 46.8398624,306.54432 Z" id="lj-8" fill="';
        parts[26] = cloudColorElement[sign];
        parts[27] = unicode'"></path><text font-family="STSongti-SC-Black, Songti SC" font-size="38" font-weight="700" fill="#202020" x="269" y="69" writing-mode="tb-rl">';
        parts[28] = lots;
        parts[29] = unicode'</text></g></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7],parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14],parts[15],parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21],parts[22],parts[23],parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Moon #', toString(tokenId), '", "description": "Men have their weal and woe, parting and meeting; The moon has her dimness and brightness, waxing and waning. -Prelude to Water Melody by Su Shi.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '", "attributes":[{"trait_type": "Phase of the moon", "value": "', toString(moon),'"}, {"trait_type": "Lots", "value": "', lots,'"}]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function claim() public nonReentrant {
        require(_claimed[msg.sender] == 0, "Address claimed");
        uint256 tokenId = totalSupply() + 1;
        require(tokenId < maxLimit, "The upper limit of token ID is 9999.");
        numbers[tokenId] = block.timestamp;
        _claimed[msg.sender]++;
        _safeMint(_msgSender(), tokenId);
    }
    
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
    
    constructor() ERC721("Moon Draw", "Moon Draw") Ownable() {}
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