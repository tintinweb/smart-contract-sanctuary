/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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


contract inthedarknessbindthem is ERC721Enumerable, ReentrancyGuard, Ownable {

        string[] private names = [
     "Ancalagon m dragon ",
"Glaurung m dragon ",
"Smaug m dragon ",
"Azaghal m Dwarf ",
"Balin m Dwarf ",
"Bifur m Dwarf ",
"Bofur m Dwarf ",
"Bombur m Dwarf ",
"Borin m Dwarf ",
"Dain II m Dwarf (Ironfoot) ",
"Dain I m Dwarf ",
"Dis f Dwarf ",
"Dori m Dwarf ",
"Durin VI m Dwarf ",
"Durin I m Dwarf ",
"Durin II m Dwarf ",
"Durin III m Dwarf ",
"Durin IV m Dwarf ",
"Durin V m Dwarf ",
"Durin VII m Dwarf ",
"Dwalin m Dwarf ",
"Farin m Dwarf ",
"Fili m Dwarf ",
"FlOi m Dwarf ",
"Frar m Dwarf ",
"Frerin m Dwarf ",
"FrOr m Dwarf ",
"Fundin m Dwarf ",
"Gamil Zirak m Dwarf ",
"Gimli m Dwarf ",
"GlOin m Dwarf ",
"GrOin m Dwarf ",
"GrOr m Dwarf ",
"Ibun m Dwarf ",
"Khim m Dwarf ",
"Kili m Dwarf ",
"LOni m Dwarf ",
"Mim m Dwarf ",
"Nain I m Dwarf ",
"Nain II m Dwarf ",
"Nali m Dwarf ",
"Nar m Dwarf ",
"Narvi m Dwarf ",
"Nori m Dwarf ",
"Oin m Dwarf ",
"Ori m Dwarf ",
"Telchar m Dwarf ",
"Thorin II Oakenshield m Dwarf ",
"Thorin I m Dwarf ",
"Thorin III Stonehelm m Dwarf ",
"Thrain II m Dwarf ",
"Thrain I m Dwarf ",
"ThrOr m Dwarf ",
"Gwaihir m eagle ",
"Landroval m eagle ",
"Meneldor m eagle ",
"Thorondor m eagle ",
"Aegnor m Elf (Aikanaro",
" Ambarato) ",
"Amarie f Elf ",
"Amdir m Elf ",
"Amras m Elf (Telufinwe",
" Umbarto) ",
"Amrod m Elf (Ambarussa",
" Pityafinwe) ",
"Amroth m Elf ",
"Anaire f Elf ",
"Angrod m Elf (Angarato) ",
"Annael m Elf ",
"Aranwe m Elf ",
"Aredhel f Elf (Ar-Feiniel  irisse) ",
"Argon m Elf (Arakano) ",
"Arminas m Elf ",
"Beleg Cuthalion m Elf ",
"Caranthir m Elf (Carnistir",
" Morifinwe) ",
"Celeborn m Elf (Teleporno) ",
"Celebrian f Elf ",
"Celebrimbor m Elf ",
"Celegorm m Elf (Turcafinwe",
" Tyelkormo) ",
"Cirdan m Elf ",
"Curufin m Elf (Atarinke",
" Curufinwe) ",
"Daeron m Elf ",
"Denethor m Elf ",
"Earwen f Elf ",
"Ecthelion of the Fountain m Elf ",
"Edrahil m Elf ",
"Egalmoth m Elf ",
"EldalOte f Elf ",
"Elemmakil m Elf ",
"Elemmire ? Elf ",
"Elenwe f Elf ",
"Elmo m Elf ",
"Enel m Elf ",
"Enerdhil m Elf ",
"Eol m Elf ",
"Erestor m Elf ",
"Feanor m Elf (Curufinwe Feanaro) ",
"Finarfin m Elf (Ingalaure) ",
"Findis f Elf ",
"Finduilas f Elf (Faelivrin) ",
"Fingolfin m Elf (Aracano)",

"Fingon m Elf (Findekano) ",
"Finrod m Elf ",
"Finwe m Elf (NoldOran) ",
"Galadhon m Elf ",
"Galadriel f Elf ",
"Galathil m Elf ",
"Galdor m Elf ",
"Galion m Elf ",
"Gelmir m Elf ",
"Gildor Inglorion m Elf ",
"Gil-galad m Elf",
"Glorfindel m Elf ",
"Guilin m Elf ",
"Gwindor m Elf ",
"Haldir m Elf ",
"Idril f Elf (Celebrindal) ",
"Imin m Elf ",
"Indis f Elf ",
"Ingwe m Elf ",
"Ingwion m Elf ",
"Irime f Elf ",
"Legolas m Elf ",
"Lenwe m Elf ",
"Luthien f Elf (Tinuviel) ",
"Mablung m Elf ",
"Maedhros m Elf ",
"Maeglin m Elf ",
"Maglor m Elf ",
"Mahtan m Elf ",
"Miriel Therinde f Elf ",
"Mithrellas f Elf ",
"Nellas f Elf ",
"Nerdanel f Elf ",
"Nimloth f Elf ",
"Olwe m Elf ",
"Orodreth m Elf ",
"Oropher m Elf ",
"Orophin m Elf ",
"Pengolodh m Elf ",
"Rumil m Elf ",
"Tata m Elf ",
"Thingol m Elf (Elwe) ",
"Thranduil m Elf ",
"Turgon m Elf ",
"Voronwe m Elf (Aranwion) ",
"Beechbone m Ent ",
"Bregalad m Ent (Quickbeam) ",
"Fimbrethil f Ent (Wandlimb) ",
"Finglas m Ent ",
"Fladrif m Ent ",
"Treebeard m Ent (Fangorn) ",
"Arwen f Half-elf (UndOmiel) ",
"Dior m Half-elf (Aranel",
" Eluchil) ",
"Earendil m Half-elf (Ardamire",
" Azrubel) ",
"Elladan m Half-elf ",
"Elrohir m Half-elf ",
"Elrond m Half-elf ",
"Elros m Half-elf (Minyatur) ",
"Elured m Half-elf ",
"Elurin m Half-elf ",
"Elwing f Half-elf ",
"Galador m Half-elf ",
"Gilmith f Half-elf ",
"Adalbert Bolger m Hobbit ",
"Adaldrida Bolger f Hobbit ",
"Adalgar Bolger m Hobbit ",
"Adalgrim Took m Hobbit ",
"Adamanta Chubb f Hobbit ",
"Adelard Took m Hobbit ",
"Alfrida f Hobbit ",
"Amaranth Brandybuck f Hobbit ",
"Amethyst Hornblower f Hobbit ",
"Andwise Roper m Hobbit (Andy) ",
"Angelica Baggins f Hobbit ",
"Anson Roper m Hobbit ",
"Asphodel Brandybuck f Hobbit ",
"Balbo Baggins m Hobbit ",
"Bandobras Took m Hobbit ",
"Basso Boffin m Hobbit ",
"Belba Baggins f Hobbit ",
"Bell Goodchild f Hobbit ",
"Belladonna Took f Hobbit ",
"Berilac Brandybuck m Hobbit ",
"Berylla Boffin f Hobbit ",
"Bilbo Baggins m Hobbit ",
"Bilbo Gardner m Hobbit ",
"Bingo Baggins m Hobbit ",
"Blanco m Hobbit ",
"Blanco Bracegirdle m Hobbit ",
"Bob m Hobbit ",
"Bodo Proudfoot m Hobbit ",
"Bosco Boffin m Hobbit ",
"Bowman Cotton m Hobbit (Nick) ",
"Briffo Boffin m Hobbit ",
"Bruno Bracegirdle m Hobbit ",
"Bucca m Hobbit ",
"Buffo Boffin m Hobbit ",
"Bungo Baggins m Hobbit ",
"Camellia Sackville f Hobbit ",
"Carl Cotton m Hobbit ",
"Celandine Brandybuck f Hobbit ",
"Chica Chubb f Hobbit ",
"Cora Goodbody f Hobbit ",
"Cotman m Hobbit ",
"Cottar m Hobbit ",
"Daisy Baggins f Hobbit ",
"Daisy Gardner f Hobbit ",
"Deagol m Hobbit (Nahald) ",
"Diamond f Hobbit ",
"Dina Diggle f Hobbit ",
"Dinodas Brandybuck m Hobbit ",
"Doderic Brandybuck m Hobbit ",
"Dodinas Brandybuck m Hobbit ",
"Donnamira Took f Hobbit ",
"Dora Baggins f Hobbit ",
"Drogo Baggins m Hobbit ",
"Druda Burrows f Hobbit ",
"Dudo Baggins m Hobbit ",
"Eglantine Banks f Hobbit ",
"Elanor Gardner f Hobbit ",
"Elfstan Fairbairn m Hobbit ",
"Erling Greenhand m Hobbit ",
"Esmeralda Brandybuck f Hobbit ",
"Estella Bolger f Hobbit ",
"Everard Took m Hobbit ",
"Falco Chubb-Baggins m Hobbit ",
"Faramir Took m Hobbit ",
"Fastolph Bolger m Hobbit ",
"Fastred m Hobbit ",
"Ferdinand Took m Hobbit ",
"Ferumbras Took I m Hobbit ",
"Ferumbras Took II m Hobbit ",
"Ferumbras Took III m Hobbit ",
"Filibert Bolger m Hobbit ",
"Firiel Fairbairn f Hobbit ",
"Flambard Took m Hobbit ",
"Folco Boffin m Hobbit ",
"Fortinbras Took I m Hobbit ",
"Fortinbras Took II m Hobbit ",
"Fosco Baggins m Hobbit ",
"Fredegar Bolger m Hobbit (Fatty) ",
"Frodo Baggins m Hobbit ",
"Frodo Gardner m Hobbit ",
"Gerda Boffin f Hobbit ",
"Gerontius Took m Hobbit (Old Took) ",
"Gilly Brownlock f Hobbit ",
"Goldilocks Gardner f Hobbit ",
"Gollum m Hobbit ",
"Gorbadoc Brandybuck m Hobbit ",
"Gorbulas Brandybuck m Hobbit ",
"Gorhendad Brandybuck m Hobbit ",
"Gormadoc Brandybuck m Hobbit ",
"Griffo Boffin m Hobbit ",
"Gruffo Boffin m Hobbit ",
"Gundabald Bolger m Hobbit ",
"Gundahad Bolger m Hobbit ",
"Gundahar Bolger m Hobbit ",
"Gundolpho Bolger m Hobbit ",
"Halfast Gamgee m Hobbit (Hal) ",
"Halfred Gamgee m Hobbit ",
"Halfred Greenhand m Hobbit ",
"Hamfast of Gamwich m Hobbit ",
"Hamfast Gamgee m Hobbit (Gaffer) ",
"Hamfast Gardner m Hobbit ",
"Hamson Gamgee m Hobbit ",
"Hanna Goldworthy f Hobbit ",
"Harding of the Hill m Hobbit ",
"Hending m Hobbit ",
"Heribald Bolger m Hobbit ",
"Herugar Bolger m Hobbit ",
"Hilda Bracegirdle f Hobbit ",
"Hildibrand Took m Hobbit ",
"Hildifons Took m Hobbit ",
"Hildigard Took f Hobbit ",
"Hildigrim Took m Hobbit ",
"Hob Gammidge m Hobbit ",
"Hob Hayward m Hobbit ",
"Hobson Gamgee m Hobbit (Roper) ",
"Holfast Gardner m Hobbit ",
"Holman Cotton m Hobbit (Long Hom) ",
"Holman Greenhand m Hobbit ",
"Hugo Boffin m Hobbit ",
"Hugo Bracegirdle m Hobbit ",
"Ilberic Brandybuck m Hobbit ",
"Isembard Took m Hobbit ",
"Isembold Took m Hobbit ",
"Isengar Took m Hobbit ",
"Isengrim Took I m Hobbit ",
"Isengrim Took II m Hobbit ",
"Isengrim Took III m Hobbit ",
"Isumbras Took I m Hobbit ",
"Isumbras Took II m Hobbit ",
"Isumbras Took III m Hobbit ",
"Isumbras Took IV m Hobbit ",
"Ivy Goodenough f Hobbit ",
"Jago Boffin m Hobbit ",
"Jessamine Boffin f Hobbit ",
"Lalia Clayhanger f Hobbit ",
"Largo Baggins m Hobbit ",
"Laura Grubb f Hobbit ",
"Lavender Grubb f Hobbit ",
"Lily Baggins f Hobbit ",
"Lily Brown f Hobbit ",
"Linda Baggins f Hobbit ",
"Lobelia Sackville-Baggins f Hobbit ",
"Longo Baggins m Hobbit ",
"Lotho Sackville-Baggins m Hobbit ",
"Madoc Brandybuck m Hobbit ",
"Farmer Maggot m Hobbit ",
"Malva Headstrong f Hobbit ",
"Marcho m Hobbit ",
"Marigold Gamgee f Hobbit ",
"Marmadas Brandybuck m Hobbit ",
"Marmadoc Brandybuck m Hobbit ",
"Marroc Brandybuck m Hobbit ",
"May Gamgee f Hobbit ",
"Melilot Brandybuck f Hobbit ",
"Menegilda Goold f Hobbit ",
"Mentha Brandybuck f Hobbit ",
"Meriadoc Brandybuck m Hobbit (Holdwine",
" Merry) ",
"Merimac Brandybuck m Hobbit ",
"Merimas Brandybuck m Hobbit ",
"Merry Gardner m Hobbit ",
"Milo Burrows m Hobbit ",
"Mimosa Bunce f Hobbit ",
"Minto Burrows m Hobbit ",
"Mirabella Took f Hobbit ",
"Moro Burrows m Hobbit ",
"Mosco Burrows m Hobbit ",
"Mungo Baggins m Hobbit ",
"Myrtle Burrows f Hobbit ",
"Nina Lightfoot f Hobbit ",
"Nob m Hobbit ",
"Nora Bolger f Hobbit ",
"Odo Proudfoot m Hobbit ",
"Odovacar Bolger m Hobbit ",
"Olo Proudfoot m Hobbit ",
"Orgulas Brandybuck m Hobbit ",
"Otho Sackville-Baggins m Hobbit ",
"Otto Boffin m Hobbit ",
"Paladin Took I m Hobbit ",
"Paladin Took II m Hobbit ",
"Pansy Baggins f Hobbit ",
"Pearl Took f Hobbit ",
"Peony Baggins f Hobbit ",
"Peregrin Took m Hobbit (Pippin) ",
"Pervinca Took f Hobbit ",
"Pimpernel Took f Hobbit ",
"Pippin Gardner m Hobbit ",
"Polo Baggins m Hobbit ",
"Ponto Baggins I m Hobbit ",
"Ponto Baggins II m Hobbit ",
"Poppy Chubb-Baggins f Hobbit ",
"Porto Baggins m Hobbit ",
"Posco Baggins m Hobbit ",
"Primrose Boffin f Hobbit ",
"Primrose Gardner f Hobbit ",
"Primula Brandybuck f Hobbit ",
"Prisca Baggins f Hobbit ",
"Reginard Took m Hobbit ",
"Robin Gardner m Hobbit ",
"Robin Smallburrow m Hobbit ",
"Rollo Boffin m Hobbit ",
"Rorimac Brandybuck m Hobbit (Rory) ",
"Rosa Baggins f Hobbit ",
"Rosamunda Took f Hobbit ",
"Rose f Hobbit ",
"Rose Gardner f Hobbit ",
"Rosie Cotton f Hobbit ",
"Rowan f Hobbit ",
"Ruby Bolger f Hobbit ",
"Ruby Gardner f Hobbit ",
"Rudibert Bolger m Hobbit ",
"Rudigar Bolger m Hobbit ",
"Rudolph Bolger m Hobbit ",
"Rufus Burrows m Hobbit ",
"Sadoc Brandybuck m Hobbit ",
"Salvia Brandybuck f Hobbit ",
"Samwise Gamgee m Hobbit (Sam) ",
"Sancho Proudfoot m Hobbit ",
"Sapphira Brockhouse f Hobbit ",
"Saradas Brandybuck m Hobbit ",
"Saradoc Brandybuck m Hobbit ",
"Seredic Brandybuck m Hobbit ",
"Sigismond Took m Hobbit ",
"Tanta Hornblower f Hobbit ",
"Theobald Bolger m Hobbit ",
"Tobold Hornblower m Hobbit ",
"Togo Goodbody m Hobbit ",
"Tolman Cotton m Hobbit ",
"Tolman Gardner m Hobbit (Tom) ",
"Tosto Boffin m Hobbit ",
"Uffo Boffin m Hobbit ",
"Vigo Boffin m Hobbit ",
"Wilcome Cotton m Hobbit (Jolly) ",
"Wilibald Bolger m Hobbit ",
"Wilimar Bolger m Hobbit ",
"Will Whitfoot m Hobbit ",
"Willie Banks m Hobbit ",
"Wiseman Gamwich m Hobbit ",
"Arod m horse ",
"Arroch ? horse ",
"Asfaloth ? horse ",
"FelarOf m horse ",
"Firefoot m horse ",
"Hasufel m horse ",
"Nahar m horse ",
"Shadowfax m horse ",
"Alatar m Maia ",
"Arien f Maia ",
"Eonwe m Maia ",
"Gandalf m Maia (Mithrandir",
" OlOrin) ",
"Gothmog m Maia ",
"Ilmare f Maia ",
"Melian f Maia ",
"Osse m Maia ",
"Pallando m Maia ",
"Radagast m Maia (Aiwendil) ",
"Salmar m Maia ",
"Saruman m Maia (Curumo) ",
"Sauron m Maia (Annatar) ",
"Tilion m Maia ",
"Uinen f Maia ",
"Adanel f Man ",
"Adrahil I m Man ",
"Adrahil II m Man ",
"Ar-Adunakhor m Man (Herunumen) ",
"Aerin f Man ",
"Aghan m Man ",
"Ailinel f Man ",
"Tar-Alcarin m Man ",
"Tar-Aldarion m Man (Anardil) ",
"Aldor m Man ",
"Algund m Man ",
"Almarian f Man ",
"Almiel f Man ",
"Amandil m Man ",
"Tar-Amandil m Man (Aphanuzir) ",
"Amlach m Man ",
"Amlaith m Man ",
"Anardil m Man ",
"Tar-Anarion m Man ",
"Anarion m Man ",
"Anborn m Man ",
"Tar-Ancalime f Man (Emerwen Aranel) ",
"Tar-Ancalimon m Man ",
"Andreth f Man (Saelind) ",
"AndrOg m Man ",
"Angbor m Man ",
"Angelimar m Man ",
"Angelimir m Man ",
"Angrim m Man ",
"Arador m Man ",
"Araglas m Man ",
"Aragorn II Elessar m Man (Elessar",
" Estel",
" Strider) ",
"Aragorn I m Man ",
"Aragost m Man ",
"Arahad I m Man ",
"Arahad II m Man ",
"Arahael m Man ",
"Aranarth m Man ",
"Aranuir m Man ",
"Araphant m Man ",
"Araphor m Man ",
"Arassuil m Man ",
"Aratan m Man ",
"Arathorn II m Man ",
"Arathorn I m Man ",
"Araval m Man ",
"Aravir m Man ",
"Aravorn m Man ",
"Arciryas m Man ",
"Tar-Ardamin m Man (Abattarik) ",
"Ardamir m Man ",
"Argeleb II m Man ",
"Argeleb I m Man ",
"Argonui m Man ",
"Artamir m Man ",
"Arthad m Man ",
"Arvedui m Man ",
"Arvegil m Man ",
"Arveleg I m Man ",
"Arveleg II m Man ",
"Asgon m Man ",
"Atanalcar m Man ",
"Tar-Atanamir m Man ",
"Atanatar I m Man ",
"Atanatar II m Man ",
"Aulendil m Man ",
"Axantur m Man ",
"Bain m Man ",
"Baldor m Man ",
"Barach m Man ",
"Baragund m Man ",
"Barahir m Man ",
"Baran m Man ",
"Baranor m Man ",
"Bard the Bowman m Man ",
"Bard II m Man ",
"Barliman Butterbur m Man ",
"Beldir m Man ",
"Beldis f Man ",
"Belecthor I m Man ",
"Belecthor II m Man ",
"Beleg m Man ",
"Belegorn m Man ",
"Belegund m Man ",
"Belemir m Man ",
"Belen m Man ",
"Beor m Man (Balan) ",
"Beorn m Man ",
"Bereg m Man ",
"Beregar m Man ",
"Beregond m Man ",
"Beren Erchamion m Man (Camlost) ",
"Beren m Man ",
"Bereth f Man ",
"Bergil m Man ",
"Beril f Man ",
"Beruthiel f Man ",
"Bill Ferny m Man ",
"BOr m Man ",
"Borlach m Man ",
"Borlad m Man ",
"Boromir m Man ",
"Boron m Man ",
"Borondir m Man ",
"Borthand m Man ",
"Brand m Man ",
"Brandir m Man ",
"Brego m Man ",
"Bregolas m Man ",
"Brodda m Man ",
"Brytta m Man (Leofa) ",
"Calimehtar m Man ",
"Caliondo m Man ",
"Tar-Calmacil m Man (Belzagar) ",
"Calmacil m Man ",
"Castamir the Usurper m Man ",
"Celebrindor m Man ",
"Celepharn m Man ",
"Cemendur m Man ",
"Ceorl m Man ",
"Cirion m Man ",
"Ciryandil m Man ",
"Tar-Ciryatan m Man (Balkumagan) ",
"Ciryatur m Man ",
"Ciryon m Man ",
"Dagnir m Man ",
"Dairuin m Man ",
"Damrod m Man ",
"Denethor II m Man ",
"Denethor I m Man ",
"Deor m Man ",
"Deorwine m Man ",
"Derufin m Man ",
"Dervorin m Man ",
"Dior m Man ",
"Dirhael m Man ",
"Dirhavel m Man ",
"Dorlas m Man ",
"Duilin m Man ",
"Duinhir m Man ",
"Dunhere m Man ",
"Earendil m Man ",
"Earendur m Man ",
"Earnil I m Man ",
"Earnil II m Man ",
"Earnur m Man ",
"Ecthelion I m Man ",
"Ecthelion II m Man ",
"Egalmoth m Man ",
"Eilinel f Man ",
"Elatan m Man ",
"Elboron m Man ",
"Eldacar m Man ",
"Eldacar m Man (Vinitharya) ",
"Eldarion m Man ",
"Tar-Elendil m Man (Parmaite) ",
"Elendil m Man ",
"Elendur m Man ",
"Elfhelm m Man ",
"Elfhild f Man ",
"Elfwine m Man ",
"Emeldir f Man ",
"Eofor m Man ",
"eomer m Man ",
"eomund m Man ",
"Eorl the Young m Man ",
"eothain m Man ",
"eowyn f Man ",
"Eradan m Man ",
"Erchirion m Man ",
"Erendis f Man (Elestirne) ",
"Erkenbrand m Man ",
"Estelmo m Man ",
"Faramir m Man ",
"Fastred m Man ",
"Fengel m Man ",
"Findegil m Man ",
"Finduilas f Man ",
"Folca m Man ",
"Folcred m Man ",
"Folcwine m Man ",
"Forlong m Man ",
"Forthwini m Man ",
"Forweg m Man ",
"Fram m Man ",
"Frea m Man ",
"Frealaf Hildeson m Man ",
"Freawine m Man ",
"Freca m Man ",
"Frumgar m Man ",
"Fuinur m Man ",
"Galdor the Tall m Man ",
"GalmOd m Man ",
"Gamling m Man ",
"Garulf m Man ",
"Gethron m Man ",
"Ghan-buri-Ghan m Man ",
"Gildis f Man ",
"Gildor m Man ",
"Gilraen f Man ",
"Gimilkhad m Man ",
"Gimilzagar m Man ",
"Ar-Gimilzor m Man (Telemnar) ",
"Girion m Man ",
"Gleowine m Man ",
"Glirhuin m Man ",
"GlOredhel f Man ",
"Golasgil m Man ",
"Goldwine m Man ",
"Gorlim m Man ",
"Gram m Man ",
"Grima Wormtongue m Man (Wormtongue) ",
"Grimbeorn m Man ",
"Grimbold m Man ",
"Grithnir m Man ",
"Gundor m Man ",
"Guthlaf m Man ",
"Hador LOrindol m Man ",
"Hador m Man ",
"Halbarad m Man ",
"Haldad m Man ",
"Haldan m Man ",
"Haldar m Man ",
"Haldir m Man ",
"Haleth f Man ",
"Hallacar m Man (Mamandil) ",
"Hallas m Man ",
"Hallatan m Man ",
"Halmir m Man ",
"Hama m Man ",
"Harding m Man ",
"Hareth m Man ",
"Harry Goatleaf m Man ",
"Hatholdir m Man ",
"Helm Hammerhand m Man ",
"Herefara m Man ",
"Herion m Man ",
"Herubrand m Man ",
"Herucalmo m Man (Anducal) ",
"Herumor m Man ",
"Hirgon m Man ",
"Hiril f Man ",
"Hirluin m Man ",
"Horn m Man ",
"Hundar f Man ",
"Hunthor m Man ",
"Huor m Man ",
"Hurin m Man ",
"Hurin I m Man ",
"Hurin II m Man ",
"Hyarmendacil I m Man ",
"Hyarmendacil II m Man ",
"ibal m Man ",
"Imrahil m Man ",
"Inzilbeth f Man ",
"Ioreth f Man ",
"Iorlas m Man ",
"irilde f Man ",
"Isildur m Man ",
"Isilme f Man ",
"Isilmo m Man ",
"Ivorwen f Man ",
"Khamul m Man ",
"Leod m Man ",
"Lindisse f Man ",
"LindOrie f Man ",
"Lorgan m Man ",
"Lothiriel f Man ",
"Mablung m Man ",
"Mairen f Man ",
"Malach m Man ",
"Malantur m Man ",
"Mallor m Man ",
"Malvegil m Man ",
"Manwendil m Man ",
"Marach m Man ",
"Mardil Voronwe m Man ",
"Marhari m Man ",
"Marhwini m Man ",
"Mat Heathertoes m Man ",
"Meneldil m Man ",
"Tar-Meneldur m Man (irimon) ",
"Minardil m Man ",
"Minastan m Man ",
"Tar-Minastir m Man ",
"Tar-Miriel f Man (Zimraphel) ",
"Morwen f Man ",
"Morwen Steelsheen f Man ",
"Narmacil I m Man ",
"Narmacil II m Man ",
"Nessanie f Man ",
"Nienor f Man ",
"Nolondil m Man ",
"Numendil m Man ",
"Nuneth f Man ",
"Ondoher m Man ",
"Orchaldor m Man ",
"Orodreth m Man ",
"Oromendil m Man ",
"Ostoher m Man ",
"Tar-Palantir m Man (Inziladun) ",
"Pelendur m Man ",
"Ar-Pharazon m Man (Calion) ",
"Rian f Man ",
"ROmendacil I m Man (Tarostar) ",
"ROmendacil II m Man (Minalcar) ",
"Rowlie Appledore m Man ",
"Sador m Man ",
"Saeros m Man ",
"Ar-Sakalthor m Man (Falassion) ",
"Silmarien f Man ",
"Siriondil m Man ",
"Soronto m Man ",
"Tar-Surion m Man ",
"Tarannon m Man (Falastur) ",
"Tarcil m Man ",
"Targon m Man ",
"Tarondor m Man ",
"Ted Sandyman m Man ",
"Tar-Telemmaite m Man ",
"Telemnar m Man ",
"Tar-Telperien f Man ",
"Telumehtar m Man (Umbardacil) ",
"Thengel m Man ",
"Theoden m Man ",
"Theodred m Man ",
"Thorondir m Man ",
"TindOmiel f Man ",
"Tuor m Man ",
"Turgon m Man ",
"Turin I m Man ",
"Turin II m Man ",
"Turin Turambar m Man (Adanedhel",
" Agarwaen",
" Gorthol",
" Mormegil",
" Neithan",
" Thurin) ",
"Ulbar m Man ",
"Uldor m Man ",
"Ulfang the Black m Man ",
"Ulfast m Man ",
"Ulrad m Man ",
"Ulwarth m Man ",
"Valacar m Man ",
"Valandil m Man ",
"Tar-Vanimelde f Man ",
"Vardamir m Man (NOlimon) ",
"Vardilme f Man ",
"Veantur m Man ",
"Vidugavia m Man ",
"Vidumavi f Man ",
"Vorondil the Hunter m Man ",
"Walda m Man ",
"Wulf m Man ",
"Yavien f Man ",
"Zamin f Man ",
"Zimrahin f Man (Meldis) ",
"Ar-Zimrathon m Man (Hostamir) ",
"Azog m Orc ",
"Bolg m Orc ",
"Golfimbul m Orc ",
"Gorbag m Orc ",
"Grishnakh m Orc ",
"Lagduf m Orc ",
"Lugdush m Orc ",
"Mauhur m Orc ",
"Muzgash m Orc ",
"Radbug m Orc ",
"Shagrat m Orc ",
"Snaga m Orc ",
"Ufthak m Orc ",
"Ugluk m Orc ",
"Bill m pony ",
"Fatty Lumpkin m pony ",
"Strider m pony ",
"Stybba m pony ",
"Carc m raven ",
"Roac m raven ",
"Shelob f spider ",
"Ungoliant m spider ",
"Bert m Troll ",
"Bill m Troll (William Huggins) ",
"Tom m Troll ",
"Aerandir m unknown ",
"Erellont m unknown ",
"Goldberry f unknown ",
"Gothmog m unknown ",
"Tom Bombadil m unknown ",
"Aule m Vala ",
"Este f Vala ",
"LOrien m Vala (Irmo) ",
"Mandos m Vala (Namo) ",
"Manwe m Vala ",
"Melkor m Vala (Morgoth) ",
"Nessa f Vala ",
"Nienna f Vala ",
"Orome m Vala ",
"Tulkas m Vala ",
"Ulmo m Vala ",
"Vaire f Vala ",
"Vana f Vala ",
"Varda f Vala (Elbereth) ",
"Yavanna f Vala ",
"Thuringwethil f vampire ",
"Carcharoth m werewolf (Anfauglir) ",
"Draugluin m werewolf ",
"Huan m wolf "


    ];
    
    string[] private chestArmor = [
        "Big Cock",
         "Small Cock",
          "Tiny Cock"

        
    ];
    
    string[] private headArmor = [
    
        "Clit  Hood",
        "Hood"
    ];
    
    string[] private waistArmor = [
        "Hard",
        "Linen Sash",
        "Sash"
    ];
    
    string[] private footArmor = [
       
        "Shoes"
    ];
    
    string[] private handArmor = [
      
        "Gloves"
    ];
    
    string[] private necklaces = [
        "Necklace",
        "Amulet",
        "Pendant"
    ];
    
       string[] private  rings = [
        "01 Ring",
        "02 Ring",
        "03 Ring",
        "04 Ring",
        "05 Ring"
    ];
 

        
    string[] private suffixes = [
      ""
      
    ];
    
    string[] private namePrefixes = [
        "Agony", "Apocalypse", "Armageddon", "Beast", "Behemoth", "Blight", "Blood"  
    ];
    
    string[] private nameSuffixes = [
        ""
        
    ];
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getName(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "NAMES", names);
    }
    
    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "CHEST", chestArmor);
    }
    
    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "HEAD", headArmor);
    }
    
    // function getWaist(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "WAIST", waistArmor);
    // }

    // function getFoot(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "FOOT", footArmor);
    // }
    
    // function getHand(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "HAND", handArmor);
    // }
    
    // function getNeck(uint256 tokenId) public view returns (string memory) {
    //     return pluck(tokenId, "NECK", necklaces);
    // }
    
    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RING", rings);
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: handwriting; font-size: 18px; }</style><rect width="100%" height="100%" fill="#424242" /><text x="10" y="20" class="base">';

        parts[1] = getName(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getRing(tokenId);

        // parts[6] = '</text><text x="10" y="80" class="base">';

        // parts[7] = getWaist(tokenId);

        // parts[8] = '</text><text x="10" y="100" class="base">';

        // parts[9] = getFoot(tokenId);

        // parts[10] = '</text><text x="10" y="120" class="base">';

        // parts[11] = getHand(tokenId);

        // parts[12] = '</text><text x="10" y="140" class="base">';

        // parts[13] = getNeck(tokenId);

        // parts[14] = '</text><text x="10" y="160" class="base">';

        // parts[15] = getRing(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        output = string(abi.encodePacked(output,  parts[16]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Chest #', toString(tokenId), '", "description": " inthedarknessbindthem ", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7777 && tokenId < 8001, "Token ID invalid");
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
    
    constructor() ERC721("inthedarknessbindthem", "DRKBIND") Ownable() {}
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