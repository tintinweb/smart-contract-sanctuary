/**
 *Submitted for verification at BscScan.com on 2021-10-08
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

interface PancakeSquadInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface ToolInterface {
    function checkExistWhitelist(address addr) external view returns(bool);

    function updateWhitelist(address addr) external;

    function getTokenURIBase() external pure returns (string memory);
}

contract Badge is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public baseMintPrice = 100000000000000000;//0.1 BNB

    uint256 public baseLootUserMintPrice = 70000000000000000;//0.07 BNB

    uint256 public mintPrice = 100000000000000000;//0.1 BNB

    uint256 public lootUserMintPrice = 70000000000000000;//0.07 BNB

    uint256 private ladderUnit = 1000;

    uint256 public costUserTotalSupply = 0;

    uint256 public maxTotalSupply = 7999;

    uint256 public addZeroTotalSupply = 0;

    uint256 public addOneTotalSupply = 0;

    uint256 public addTwoTotalSupply = 0;

    uint256 public addThreeTotalSupply = 0;

    uint256 public addFourTotalSupply = 0;

    uint[] usedTokenIdArr;

    //PancakeSquad Contract 0x0a8901b0E25DEb55A87524f0cC164E9644020EBA
    address public pancakeSquadAddress = 0x0a8901b0E25DEb55A87524f0cC164E9644020EBA;
    PancakeSquadInterface pancakeSquadContract = PancakeSquadInterface(pancakeSquadAddress);

    //Tool Contract 0x3CF98F80194A273cf36658e60861e8bcC82d25f8
    address public toolAddress = 0x3CF98F80194A273cf36658e60861e8bcC82d25f8;
    ToolInterface toolContract = ToolInterface(toolAddress);

    address payable private _royaltyRecipient;

    struct SelfDecidedAttribute {
        uint8 gender;
        uint8 strength;
        uint8 stamina;
        uint8 agility;
        uint8 charisma;
        uint8 intelligence;
        uint8 shield;
        uint8 race;
        uint8 element;

        uint8 addOne1;
        uint8 addOne2;
        uint8 addOne3;
        uint8 addOne4;
    }

    mapping(uint256 => SelfDecidedAttribute) private attrsIndex;

    mapping(uint256 => mapping(uint256 => string[])) private mapList;

    string[] private genders = [
    "Male",
    "Female",
    "Unknown"
    ];

    string[] private races = [
    "Dwarf",
    "Human",
    "Night Elf",
    "Giant",
    "Goblin"
    ];

    string[] private elements = [
    "Fire",
    "Water",
    "Earth",
    "Air"
    ];

    string[] private cike_golden = ["Justiciar of Metaverse","Metaverse Planeshifter"];
    string[] private cike_white = ["Rogue","Assassin","Shadowdancer","Guild Thief","Kishi Charger Kishi","Ninja Spy","Yakuza","Slaad Brooder","Orc Scout","Wild Scout","Nentyar Hunter"];
    string[] private cike_green = ["Hunter of the Dead","Perfect Wight","Sword Dancer","Windwalker","Foe Hunter","Dungeon Delver","Spymaster","Thief-Acrobat","Ghostwalker"];
    string[] private cike_blue = ["Lifedrinker","Shadow Adept","Mage-Killer","Bloodhound","Master of Flies","Red Avenger","Arachnemancer"];
    string[] private cike_orange = ["Disciple of Baalzebul","Disciple of Dispater","Forsaker","Bayushi Deceiver Bayushi","Darkmask","Void Incarnate","Mage Hunter"];
    string[] private cike_red = ["Shadowdance Assassin","Shadow Scout","Shapeshifter","Soulblade","Shadow Mind"];
    string[] private fs_golden = ["Red Wizard","Meta Nightcloak","Mystic Meta Wanderer","Metamind","Pale Master","Truth Seeker"];
    string[] private fs_white = ["Bard","Druid","Sorcerer","Wizard","Loremaster","Thrall of Demogorgon","Thrall of Grazt","Thrall of Jubilex","Thrall of Orcus","Ur-Priest","Vermin Lord","Horned Harbinger","Ocular Adept","Silverstar","Wear of Purple","Arcane Devotee","Spelldancer","Spellfire Channeler","War Wizard of Cormyr","Bane of Infidels","Blighter","Void Disciple","Witch Hunter","ElvenHigh Mage","Emancipated Spawn","Illithid Savant","Sybil","Yuan-Ti Cultist","BlackFlame Zealot","Raumathari Battlemage","Talontar Blightlord","Beholder Mage","Runecaster","Zhentarim Skymage","Incantatrix","Master Harper"];
    string[] private fs_green = ["Arcane Trickster","Archmage","Dragon Disciple","Horizon Walker","Loremaster","Divine Oracle","Sacred Exorcist","Warpriest","Wizard of High Sorcery","Heartwarder","Divine Disciple","Harper Scout","Hathran","Red Wizard","Runecaster","Harper Mage","Geomancer","Hexer","Oozemaster","Shifter","Fangof Lolth","Arcane Trickster","Bladesinger","Blood Magus","Entropist ","Fiend of Blasphemy","Fiend of Corruption ","Fiend of Possession","Zhentarim Skymage"];
    string[] private fs_blue = ["Hierophant","Mystic Theurge","Thaumaturgist","Demonologist","Cosmic Descryer","Divine Emissary","Doomguide","Archmage","Bone Collector","Deathwarden Chanter","Eidoloncer core class","Henshin Mystic Henshin","Iaijutsu Master Iaijutsu","Moto Avenger Moto","Siren","Candle Caster","Dragon Disciple","Elemental Savant","Mage of the Arcane Order","Doomdreamer","Mystic Theurge","Raumathari Battlemage","Ruby Disciple"];
    string[] private fs_orange = ["Diabolist","Disciple of Asmodeus","Disciple of Mammon","Dweomerkeeper","Elemental Archon","Goldeye","Ghost Slayer","Gnome Artificer","Incantatrix","Pyrokineticist","Spellsinger","Durthan","Nar Demonbinder","Telflammar Shadolord","Warpriest","Grim Psion","Lord of the Dead"];
    string[] private fs_red = ["Church Inquisitor","Master of Shrouds","Dreadmaster","Stormlord","Eye of Gruumsh","Queen of the Wild","Elven Bladesinger","Alienist","Mindbender","True Necromancer","Divine Agent","Sangehirn","Spellfire Hierophant"];
    string[] private ms_golden = ["Fatespinner"];
    string[] private ms_white = ["Harper","Cleric","Contemplative","ShintaoMonk","Warrior Skald"];
    string[] private ms_green = ["Hierophant","Virtuoso","Harper Priest","Hospitaler"];
    string[] private ms_blue = ["Virtuoso","Cancer Mage","Master Alchemist"];
    string[] private ms_orange = ["Acolyteof the Skin","Knight Protector"];
    string[] private ms_red = ["High Proselytizer","Forest Master"];
    string[] private ss_golden = ["God Eater"];
    string[] private ss_white = ["Ranger","Arcane Archer","Mortal Hunter","PeerlessArcher"];
    string[] private ss_green = ["Orderof the Bow Initiate","Consecrated Harrier"];
    string[] private ss_blue = ["Arboreal Guardian","Deepwood Sniper"];
    string[] private ss_orange = ["HalflingWarsling Sniper"];
    string[] private ss_red = ["Exotic Weapon Master"];
    string[] private tk_golden = ["Master of the Metaverse"];
    string[] private tk_white = ["Dwarven Defender","Carven Defender","Guardian of the Road"];
    string[] private tk_green = ["Giant-Killer","Tribal Protector"];
    string[] private tk_blue = ["Orc Warlord","Techsmith"];
    string[] private tk_orange = ["Scaled Horror","People Champion"];
    string[] private tk_red = ["Master Arcane Artisan"];
    string[] private zs_golden = ["Auspician","Keshen Blademaster ","Warlord of Metaverse"];
    string[] private zs_red = ["Paladin","Holy Liberator","Divine Champion","Verdant Lord","EunuchWarlock","Gatecrasher","Planar Champion ","Spur the Lord ","Psychic Weapon Master"];
    string[] private zs_orange = ["Eldritch Knight","Templar","Knight of Neraka","Knight of Solamnia","Animal Lord","Bear Warrior","Maho-Bujin","Maho-Tsukai","Royal Explorer","Shou Disciple","Thayan Slaver","Berserk","Soldier of Light ","Life Eater"];
    string[] private zs_blue = ["Knight of the Chalice","Sacred Fist","Agent Retriever","Divine Seeker","Eidolon core class","Watch Detective","Windrider","Battle Maiden","Blade Dancer","Survivor","Waverider","Horde Breaker","Dread Pirate","Spellsword","Wayferer Guide","Aglarondan Griffonrider","Runescarred Berserker"];
    string[] private zs_green = ["Warrior of Darkness","Legionnaire of Steel","Guardian Paramount","Union Sentinel","Frenzied Berserker","Tamer of Beasts","Tempest","DaidojiBodyguard Daidoji","TattooedMonk","Breachgnome","DwarvenBattlerager","GreatRift Skyguard","OrcWarlord","Masterof Chains","MasterSamurai","Ravager","Warmaster","WeaponMaster","Mindknight"];
    string[] private zs_white = ["Barbarian","Fighter","Monk","Blackguard","Duelist","Arachne","Strifeleader","Waveservant","Purple Dragon Knight","Hida DefenderHida","Mantis Mercenary","Shiba Protector","Weapon Master ","Slayer","Vigilante","Cavalier","Devoted Defender","Drunken Master","Duelist","Fist of Hextor","Gladiator","Halfling Outrider","Lasher","Thyan Knight"];
    string[] private traits = ["Administrator","Elusive Shadow","Gamer","Genius","Grey Eminence","Immortal","Midas Touched","Mystic","Brilliant Strategist","Charismatic Negotiator","Fortune Builder","Mastermind Theologian","Naive Appeaser","Naive Enthusiast","Nudist","Possessed","Righteous","Skilled Tactician","Tolerant","Amateurish Plotter","Ambitious","Architect","Architectural Visionary","Benevolent","Body Purist","Graceful","Misguided Warrior","Physician","Scholarly Theologian","Speed Demon","Theologian","Too Smart","Tough Soldier","Zealous","Arbitrary","Ascetic","Asexual","Babbling Buffoon","Bisexual","Bloodlust","Body Modder","Born Inthe Purple","Fertile","Fierce Negotiator","Gay","Giant","Gregarious","Hedonist","Idolizer","Iron Gut","Keen Hearing","Lefthanded","Light Eater","Low Thirst","Martial Cleric","Out Of Shape","Outdoorsman","Playful","Robust","Schemer","Scholar","Secretive","Seducer","Seductress","Shy","Slow Reader","Strategist","Sturdy","Tortured Artist","Underhanded Rogue","Wakeful","Well Advised","Well Connected","Zealot","Pyromaniac","Quick Sleeper","Restless Sleeper","Scarred High","Severely Injured","Short Sighted","Silver Tongue","Sleepyhead","Smoker","Socializer","Tactical Genius","Troubled Pregnancy","Trusting","Twin","Undergrounder","Underweight","Very Underweight","Weak Stomach","Willful","Wroth","Bastard","Child Ofconsort","Dwarf","Feeble","Fever","Food Poisoning","Hard Pregnancy","Harelip","Has Measles","Has Small Pox","Has Tuberculosis","Has Typhoid Fever","Impaler","Indolent","Indulgent","Infection","Infirm","Lisp","Loose Lips","Obese","One Eyed","One Handed","One Legged","Stout","Stressed","Syphilitic"];
    string[] private preffixes = ["Able","Alert","Candid","Frank","Frugal","Happy","Lazy","Modest","Smart","Steady","Strict","Active","Adroit","Bossy","Brave","Caring","Funny","Hearty"];


    uint256[] private roleScoreMatch = [
    0,
    4,
    15,
    41,
    82,
    99
    ];

    uint256[] private roleColorMatch = [
    4,
    14,
    29,
    48,
    71,
    99
    ];


    uint256[] private traitColorMatch = [
    7,
    18,
    33,
    73,
    93,
    129
    ];


    function getCostUserTotalSupply() public view returns (uint256)
    {
        return costUserTotalSupply;
    }

    function getUsedTokenIdArr() public view returns (uint[] memory)
    {
        return usedTokenIdArr;
    }

    function getRealMintPrice(uint256 tokenId) public view returns (uint256) {
        if(tokenId<7799)
        {
            return baseMintPrice*(1+costUserTotalSupply/ladderUnit);
        }
        return mintPrice;
    }

    function getRealLootUserMintPrice(uint256 tokenId) public view returns (uint256) {
        if(tokenId<7799)
        {
            return baseLootUserMintPrice*(1+costUserTotalSupply/ladderUnit);
        }
        return lootUserMintPrice;
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        mintPrice = newMintPrice;
    }

    function setLootUserMintPrice(uint256 newLootUserMintPrice) public onlyOwner {
        lootUserMintPrice = newLootUserMintPrice;
    }

    function setMaxTotalSupply(uint256 newMaxTotalSupply) public onlyOwner {
        maxTotalSupply = newMaxTotalSupply;
    }

    function updateRoyalties(address payable recipient) public onlyOwner {
        _royaltyRecipient = recipient;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(_royaltyRecipient != address(0x0), "Must set royalty recipient");
        _royaltyRecipient.transfer(amount);
    }

    function deposit() public payable onlyOwner {}

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getGender(uint256 tokenId) public view returns (string memory) {
        return genders[attrsIndex[tokenId].gender];
    }

    function getStrength(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].strength);
    }

    function getStamina(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].stamina);
    }

    function getAgility(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].agility);
    }

    function getCharisma(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].charisma);
    }

    function getIntelligence(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].intelligence);
    }

    function getShield(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].shield);
    }

    function getRace(uint256 tokenId) public view returns (string memory) {
        return races[attrsIndex[tokenId].race];
    }

    function getElement(uint256 tokenId) public view returns (string memory) {
        return elements[attrsIndex[tokenId].element];
    }

    function getOccupation(uint256 tokenId) public view returns (string memory) {
        return pluck1(tokenId);
    }

    //@return 1~6
    function getOccupationType(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("Occupation", toString(tokenId))));
        uint256 score = rand % 100;

        uint i = 0;
        for(; i < roleScoreMatch.length; i++){
            if(score <= roleScoreMatch[i]){
                break;
            }
        }
        return i+1;
    }

    //@return 1~6
    function getOccupationColor(uint256 tokenId) public view returns (uint256) {
        uint256 rand2 = random(string(abi.encodePacked("color", toString(tokenId))));
        uint256 colorScore = rand2 % 100;
        uint j = 0;
        for(; j < roleColorMatch.length; j++){
            if(colorScore <= roleColorMatch[j]){
                break;
            }
        }
        return j+1;
    }

    function getTrait1(uint256 tokenId) public view returns (string memory) {
        return pluck2(tokenId, "Trait1");
    }

    function getTrait2(uint256 tokenId) public view returns (string memory) {
        return pluck2(tokenId, "Trait2");
    }

    function getTrait3(uint256 tokenId) public view returns (string memory) {
        return pluck2(tokenId, "Trait3");
    }

    function getTraitColor(uint256 tokenId, uint256 index) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("Trait", toString(index), toString(tokenId))));
        uint256 score = rand % traits.length;

        uint j = 0;
        for(; j < traitColorMatch.length; j++){
            if(score <= traitColorMatch[j]){
                break;
            }
        }
        return getColorFull(j+1);
    }

    function getColorFull(uint256 index) private pure returns  (string memory) {
        if(index == 1){
            return "#ffc000";
        }else if(index == 2){
            return "#c00000";
        }else if(index == 3){
            return "#ed7d31";
        }else if(index == 4){
            return "#5b9bd5";
        }else if(index == 5){
            return "#70ad47";
        }else{
            return "#ffffff";
        }
    }

    function pluck1(uint256 tokenId) internal view returns (string memory) {
        uint256 roleType = getOccupationType(tokenId);
        uint256 colorType = getOccupationColor(tokenId);
        string[] memory sourceArray = mapList[roleType][colorType];

        uint256 rand = random(string(abi.encodePacked("item", toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];

        string memory prefix = preffixes[rand % preffixes.length];
        output = string(abi.encodePacked(prefix, ' ', output));
        return output;
    }

    function pluck2(uint256 tokenId, string memory keyPrefix) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 index = rand % traits.length;
        string memory output = string(abi.encodePacked('"', traits[index], '"'));
        return output;
    }

    function getIcon(uint256 tokenId) internal view returns (string memory) {
        string memory Assassin = '&#x25B2;';
        string memory Mage = '&#x203B;';
        string memory Hunter = '&#x2191;';
        string memory Priest = '&#x25CB;';
        string memory Tank = '&#x25C6;';
        string memory Warior = '&#x25A0;';

        string memory output="";
        uint256 typeIndex = getOccupationType(tokenId);

        if(typeIndex == 1){
            output = Tank;
        }else if (typeIndex == 2){
            output = Assassin;
        }else if (typeIndex == 3){
            output = Hunter;
        }else if (typeIndex == 4){
            output = Priest;
        }else if (typeIndex == 5){
            output = Mage;
        }else{
            output = Warior;
        }
        return output;
    }

    function getIconName(uint256 tokenId) internal view returns (string memory) {
        string memory Assassin = 'Assassin';
        string memory Mage = 'Mage';
        string memory Hunter = 'Hunter';
        string memory Priest = 'Priest';
        string memory Tank = 'Tank';
        string memory Warior = 'Warior';

        uint256 typeIndex = getOccupationType(tokenId);
        string memory output = "";
        if(typeIndex == 1){
            output = Tank;
        }else if (typeIndex == 2){
            output = Assassin;
        }else if (typeIndex == 3){
            output = Hunter;
        }else if (typeIndex == 4){
            output = Priest;
        }else if (typeIndex == 5){
            output = Mage;
        }else{
            output = Warior;
        }
        return output;
    }

    function getColorName(uint256 tokenId) internal view returns (string memory) {
        uint256 typeIndex = getOccupationColor(tokenId);
        if(typeIndex == 1){
            return "gold";
        }else if (typeIndex == 2){
            return "red";
        }else if (typeIndex == 3){
            return "orange";
        }else if (typeIndex == 4){
            return "blue";
        }else if (typeIndex == 5){
            return "green";
        }else{
            return "white";
        }
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[46] memory parts;

        parts[0]=toolContract.getTokenURIBase();
//        parts[0] = '<?xml version="1.0" encoding="utf-8"?><svg version="1.1" id="1"    xmlns="http://www.w3.org/2000/svg"    xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" width="750px" height="750px" viewBox="0 0 750 750" style="enable-background:new 0 0 750 750;" xml:space="preserve">    <style type="text/css">.st0{fill:#023E6B;}.st1{fill:#05517F;stroke:#05517F;stroke-width:3;stroke-miterlimit:10;}.st2{fill:#FFFFFF;}</style>    <title>image</title>    <rect class="st0" width="750" height="750"/>    <path class="st1" d="M84.7,100.35H64.12V58.28h20.12c11.58-0.15,17.3,3.36,17.15,10.52c-0.13,3.81-2.2,7.28-5.49,9.2c4.57,1.37,6.93,4.57,7.09,9.6C103.14,96.11,97.05,100.36,84.7,100.35z M82.87,68.11h-4.81V75h5.72c3.2,0,4.8-1.22,4.8-3.66C88.73,68.89,86.83,67.81,82.87,68.11z M82.41,82.75h-4.35v7.77h6c4.11,0.15,6.09-1.14,5.94-3.89C90.28,83.74,87.75,82.44,82.41,82.75z"/>    <path class="st1" d="M142.54,100.35H130l-0.46-3.2c-2.74,2.6-6.63,3.81-11.66,3.66c-7.01-0.31-10.67-3.29-11-8.92c0-5.63,4.88-9.06,14.63-10.29c4.88-0.45,7.32-1.45,7.32-3c0-1.67-1.38-2.51-4.12-2.51c-2.59,0-4,1-4.12,3h-11.66c-0.15-6.86,5.41-10.29,16.69-10.29c11.28-0.46,16.39,3.81,15.32,12.8v14.18c-0.15,1.83,0.38,3.13,1.6,3.89L142.54,100.35z M123.34,94.41c3.81,0,5.64-2.52,5.49-7.55c-1.39,0.58-2.85,0.97-4.35,1.14c-3.51,0.45-5.18,1.68-5,3.65C119.61,93.34,120.89,94.26,123.34,94.41z"/>    <path class="st1" d="M180.5,100.35h-10.75v-4.11c-2.24,3.03-5.84,4.74-9.6,4.57c-8.84-0.31-13.51-5.42-14-15.32c0.46-10.36,4.79-15.92,13-16.69c3.96-0.15,7.01,1.15,9.14,3.89V58.28h12.21V100.35z M163.35,92.35c3.51,0,5.34-2.36,5.49-7.09c-0.15-4.72-1.9-7.08-5.26-7.09c-3.2,0.16-4.87,2.6-5,7.32C158.56,90.06,160.15,92.35,163.35,92.35z"/>    <path class="st1" d="M186.9,101.5H199c0.17,0.49,0.4,0.95,0.69,1.37c0.83,0.48,1.78,0.71,2.74,0.68c3.35,0.15,5-1.67,4.8-5.48v-2.52c-2,2.29-4.89,3.44-8.68,3.43c-8.24-0.46-12.66-5.34-13.27-14.63c0.48-10.06,5.05-15.24,13.72-15.55c3.7,0.01,7.15,1.89,9.15,5v-4.09h10.75v24.7c1.06,11.12-4.27,16.45-16,16C193.15,110.26,187.81,107.29,186.9,101.5z M202.22,77.5c-3.2,0-4.8,2.36-4.8,7.09c0.15,3.65,1.75,5.64,4.8,5.94c3.21,0,4.88-2.13,5-6.4c0.03-4.43-1.64-6.64-5-6.64V77.5z"/>    <path class="st1" d="M259.39,87.78h-23.33c0.31,3.66,2.37,5.64,6.18,5.94c1.87,0.06,3.62-0.9,4.57-2.51h11.43c-1.82,6.25-7.46,9.45-16.92,9.6c-11.13-0.31-16.92-5.5-17.37-15.55c0.6-10.36,6.39-15.85,17.37-16.46C253.06,69.41,259.08,75.74,259.39,87.78z M236.06,81.6h11.21c-0.31-3.2-2.14-4.95-5.49-5.26C238.12,76.34,236.21,78.1,236.06,81.6z"/>    <path class="st2" d="M84.7,100.35H64.12V58.28h20.12c11.58-0.15,17.3,3.36,17.15,10.52c-0.13,3.81-2.2,7.28-5.49,9.2c4.57,1.37,6.93,4.57,7.09,9.6C103.14,96.11,97.05,100.36,84.7,100.35z M82.87,68.11h-4.81V75h5.72c3.2,0,4.8-1.22,4.8-3.66C88.73,68.89,86.83,67.81,82.87,68.11z M82.41,82.75h-4.35v7.77h6c4.11,0.15,6.09-1.14,5.94-3.89C90.28,83.74,87.75,82.44,82.41,82.75z"/>    <path class="st2" d="M142.54,100.35H130l-0.46-3.2c-2.74,2.6-6.63,3.81-11.66,3.66c-7.01-0.31-10.67-3.29-11-8.92c0-5.63,4.88-9.06,14.63-10.29c4.88-0.45,7.32-1.45,7.32-3c0-1.67-1.38-2.51-4.12-2.51c-2.59,0-4,1-4.12,3h-11.66c-0.15-6.86,5.41-10.29,16.69-10.29c11.28-0.46,16.39,3.81,15.32,12.8v14.18c-0.15,1.83,0.38,3.13,1.6,3.89L142.54,100.35z M123.34,94.41c3.81,0,5.64-2.52,5.49-7.55c-1.39,0.58-2.85,0.97-4.35,1.14c-3.51,0.45-5.18,1.68-5,3.65C119.61,93.34,120.89,94.26,123.34,94.41z"/>    <path class="st2" d="M180.5,100.35h-10.75v-4.11c-2.24,3.03-5.84,4.74-9.6,4.57c-8.84-0.31-13.51-5.42-14-15.32c0.46-10.36,4.79-15.92,13-16.69c3.96-0.15,7.01,1.15,9.14,3.89V58.28h12.21V100.35z M163.35,92.35c3.51,0,5.34-2.36,5.49-7.09c-0.15-4.72-1.9-7.08-5.26-7.09c-3.2,0.16-4.87,2.6-5,7.32C158.56,90.06,160.15,92.35,163.35,92.35z"/>    <path class="st2" d="M186.9,101.5H199c0.17,0.49,0.4,0.95,0.69,1.37c0.83,0.48,1.78,0.71,2.74,0.68c3.35,0.15,5-1.67,4.8-5.48v-2.52c-2,2.29-4.89,3.44-8.68,3.43c-8.24-0.46-12.66-5.34-13.27-14.63c0.48-10.06,5.05-15.24,13.72-15.55c3.7,0.01,7.15,1.89,9.15,5v-4.09h10.75v24.7c1.06,11.12-4.27,16.45-16,16C193.15,110.26,187.81,107.29,186.9,101.5z M202.22,77.5c-3.2,0-4.8,2.36-4.8,7.09c0.15,3.65,1.75,5.64,4.8,5.94c3.21,0,4.88-2.13,5-6.4c0.03-4.43-1.64-6.64-5-6.64V77.5z"/>    <path class="st2" d="M259.39,87.78h-23.33c0.31,3.66,2.37,5.64,6.18,5.94c1.87,0.06,3.62-0.9,4.57-2.51h11.43c-1.82,6.25-7.46,9.45-16.92,9.6c-11.13-0.31-16.92-5.5-17.37-15.55c0.6-10.36,6.39-15.85,17.37-16.46C253.06,69.41,259.08,75.74,259.39,87.78z M236.06,81.6h11.21c-0.31-3.2-2.14-4.95-5.49-5.26C238.12,76.34,236.21,78.1,236.06,81.6z"/><text id="Male-Demons-Chaotic" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="60" y="212">';
        parts[1] = getGender(tokenId);
        parts[2] = '</tspan><tspan x="60" y="256">';
        parts[3] = getRace(tokenId);
        parts[4] = '</tspan><tspan x="60" y="300">';
        parts[5] = getElement(tokenId);

        parts[6] = '  ';

        parts[7] = attrsIndex[tokenId].addOne1 == 1 ? '+1' : '';

        parts[8] = '</tspan><tspan x="60" y="344" fill="';
        parts[9] = getColorFull(getOccupationColor(tokenId));
        parts[10] = '">';
        parts[11] = getOccupation(tokenId);
        parts[12] = '  ';
        parts[13] = getIcon(tokenId);
        parts[14] = '</tspan><tspan x="60" y="388" fill="';
        parts[15] = getTraitColor(tokenId, 1);
        parts[16] = '">';
        parts[17] = getTrait1(tokenId);

        parts[18] = '  ';

        parts[19] = attrsIndex[tokenId].addOne2 == 1 ? '+1' : '';

        parts[20] = '</tspan><tspan x="60" y="432" fill="';
        parts[21] = getTraitColor(tokenId, 2);
        parts[22] = '">';
        parts[23] = getTrait2(tokenId);

        parts[24] = '  ';

        parts[25] = attrsIndex[tokenId].addOne3 == 1 ? '+1' : '';

        parts[26] = '</tspan><tspan x="60" y="476" fill="';
        parts[27] = getTraitColor(tokenId, 3);
        parts[28] = '">';
        parts[29] = getTrait3(tokenId);

        parts[30] = '  ';

        parts[31] = attrsIndex[tokenId].addOne4 == 1 ? '+1' : '';

        parts[32] = '</tspan></text><text id="Str-Sta-Agi-Cha-Int-Shi" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="522" y="216">Str</tspan><tspan x="522" y="260">Sta</tspan><tspan x="522" y="304">Agi</tspan><tspan x="522" y="348">Cha</tspan><tspan x="522" y="392">Int</tspan><tspan x="522" y="436">Shi</tspan></text><text id="2-3-6-7-1-1" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="618" y="216">';
        parts[33] = getStrength(tokenId);
        parts[34] = '</tspan><tspan x="618" y="260">';
        parts[35] = getStamina(tokenId);
        parts[36] = '</tspan><tspan x="618" y="304">';
        parts[37] = getAgility(tokenId);
        parts[38] = '</tspan><tspan x="618" y="348">';
        parts[39] = getCharisma(tokenId);
        parts[40] = '</tspan><tspan x="618" y="392">';
        parts[41] = getIntelligence(tokenId);
        parts[42] = '</tspan><tspan x="618" y="436">';
        parts[43] = getShield(tokenId);
        parts[44] = '</tspan></text><line x1="490.5" y1="192.5" x2="490.5" y2="475.5" stroke="#979797" stroke-linecap="square"></line>';
        parts[45] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8],parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16],parts[17], parts[18], parts[19], parts[20], parts[21]));
        output = string(abi.encodePacked(output, parts[22], parts[23], parts[24],parts[25], parts[26], parts[27], parts[28]));
        output = string(abi.encodePacked(output, parts[29], parts[30], parts[31],parts[32], parts[33], parts[34]));
        output = string(abi.encodePacked(output, parts[35], parts[36], parts[37], parts[38]));
        output = string(abi.encodePacked(output, parts[39], parts[40], parts[41], parts[42], parts[43], parts[44], parts[45]));

        string memory atrrOutput = makeAttributeParts(getGender(tokenId), getRace(tokenId), getElement(tokenId), getIconName(tokenId), getColorName(tokenId));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Badge #', toString(tokenId), '", "description": "Badge is a seed, a seed account for a PVP Metaverse Game.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"', ',"attributes":', atrrOutput, '}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function makeAttributeParts(string memory gender, string memory race, string memory ele, string memory flag, string memory color) internal pure returns (string memory){
        string[11] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Gender", "value": "';
        attrParts[1] = gender;
        attrParts[2] = '" }, { "trait_type": "OccupatColor", "value": "';
        attrParts[3] = color;
        attrParts[4] = '" }, { "trait_type": "Race", "value": "';
        attrParts[5] = race;
        attrParts[6] = '" }, { "trait_type": "Element", "value": "';
        attrParts[7] = ele;
        attrParts[8] = '" }, { "trait_type": "OccupatFlag", "value": "';
        attrParts[9] = flag;
        attrParts[10] = '" }]';

        string memory atrrOutput = string(abi.encodePacked(attrParts[0], attrParts[1], attrParts[2], attrParts[3], attrParts[4], attrParts[5], attrParts[6], attrParts[7]));
        atrrOutput = string(abi.encodePacked(atrrOutput, attrParts[8], attrParts[9], attrParts[10]));
        return atrrOutput;
    }


    function randomNum(uint8 length) private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))) % length;
    }

    function randLevel(uint8 num) private returns (uint8) {
        uint8 maxNum = 0;
        if (num <= maxNum && addFourTotalSupply < maxTotalSupply / 100 *  1)
        {
            addFourTotalSupply++;
            return 4;
        }
        maxNum += 3;
        if (num <= maxNum && addThreeTotalSupply < maxTotalSupply / 100 * 3)
        {
            addThreeTotalSupply++;
            return 3;
        }
        maxNum += 5;
        if (num <= maxNum && addTwoTotalSupply < maxTotalSupply / 100 * 5)
        {
            addTwoTotalSupply++;
            return 2;
        }
        maxNum += 10;
        if (num <= maxNum && addOneTotalSupply < maxTotalSupply / 100 * 10)
        {
            addOneTotalSupply++;
            return 1;
        }
        addZeroTotalSupply++;
        return 0;
    }

    function randAddOneArr() private returns (uint8[] memory){
        uint8 level = randLevel(randomNum(100));
        uint8[] memory addOneArr = new uint8[](4);
        uint8 addOneCount =0;
        for (uint8 i = 1; i <= 4; i++)
        {
            bool isAddOne = randomNum(2) == 1;
            uint8 overAddOne = level - addOneCount;

            if (isAddOne && overAddOne == 0)
            {
                isAddOne = false;
            }
            if (false == isAddOne && overAddOne > 4 - i)
            {
                isAddOne = true;
            }
            if(isAddOne)
            {
                addOneCount++;
            }

            addOneArr[i - 1] = isAddOne ? 1 : 0;
        }
        return addOneArr;
    }


    function common(uint256 tokenId,uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 staNum, uint256 agiNum, uint256 chaNum, uint256 intNum, uint256 shiNum) private
    {
        require(!_exists(tokenId), "Token ID invalid");
        require(genderId < genders.length, "genderId invalid");
        require(strNum + staNum+ agiNum+ chaNum+ intNum+ shiNum <= 30, "attributes num invalid");
        require(raceId < races.length, "raceId invalid");
        require(elementId < elements.length, "elementId invalid");

        attrsIndex[tokenId].gender = uint8(genderId);
        attrsIndex[tokenId].strength = uint8(strNum);
        attrsIndex[tokenId].stamina = uint8(staNum);
        attrsIndex[tokenId].agility = uint8(agiNum);
        attrsIndex[tokenId].charisma = uint8(chaNum);
        attrsIndex[tokenId].intelligence = uint8(intNum);
        attrsIndex[tokenId].shield = uint8(shiNum);
        attrsIndex[tokenId].race = uint8(raceId);
        attrsIndex[tokenId].element = uint8(elementId);

        uint8[] memory addOneArr = randAddOneArr();
        attrsIndex[tokenId].addOne1=addOneArr[0];
        attrsIndex[tokenId].addOne2=addOneArr[1];
        attrsIndex[tokenId].addOne3=addOneArr[2];
        attrsIndex[tokenId].addOne4=addOneArr[3];

        usedTokenIdArr.push(tokenId);
        _safeMint(_msgSender(), tokenId);
    }

    function checkExistWhitelist(address addr) public view returns (bool)
    {
        return toolContract.checkExistWhitelist(addr);
    }

    function checkTokenIdAvailable(uint256 tokenId,address addr) public view returns (bool)
    {
        bool result=!_exists(tokenId);
        if(result)
        {
            if(tokenId>=1 && tokenId<=999 && !toolContract.checkExistWhitelist(addr))//whitelist
            {
                result=false;
            }
            else if(tokenId >= 7800 && tokenId <= 7999 && addr!=owner())//team
            {
                result=false;
            }
        }
        return result;
    }

    function claim(uint256 tokenId, uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 staNum, uint256 agiNum, uint256 chaNum, uint256 intNum, uint256 shiNum) public payable nonReentrant {
        require((tokenId >= 1000 && tokenId <= 7799) || (tokenId >= 8000 && tokenId <= maxTotalSupply), "Token ID invalid");
        require(getRealMintPrice(tokenId) <= msg.value, "Please pay mint fee");

        costUserTotalSupply++;
        common(tokenId, genderId, raceId, elementId, strNum, staNum, agiNum, chaNum, intNum, shiNum);
    }

    function claimWithLoot(uint256 tokenId, uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 staNum, uint256 agiNum, uint256 chaNum, uint256 intNum, uint256 shiNum,uint256 lootId) public payable nonReentrant {
        require((tokenId >= 1000 && tokenId <= 7799) || (tokenId >= 8000 && tokenId <= maxTotalSupply), "Token ID invalid");
        require(pancakeSquadContract.ownerOf(lootId) == msg.sender, "Not the owner of this loot");
        require(getRealLootUserMintPrice(tokenId) <= msg.value, "Please pay mint fee");

        costUserTotalSupply++;
        common(tokenId, genderId, raceId, elementId, strNum, staNum, agiNum, chaNum, intNum, shiNum);
    }

    function claimWithWhitelist(uint256 tokenId, uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 staNum, uint256 agiNum, uint256 chaNum, uint256 intNum, uint256 shiNum) public nonReentrant {
        require(tokenId >= 1 && tokenId <= 999 , "Token ID invalid");

        require(toolContract.checkExistWhitelist(_msgSender()), "Not in whitelist");
        toolContract.updateWhitelist(_msgSender());

        common(tokenId, genderId, raceId, elementId, strNum, staNum, agiNum, chaNum, intNum, shiNum);
    }

    function ownerClaim(uint256 tokenId, uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 staNum, uint256 agiNum, uint256 chaNum, uint256 intNum, uint256 shiNum) public nonReentrant onlyOwner {

        require(tokenId >= 7800 && tokenId <= 7999, "Token ID invalid");

        common(tokenId, genderId, raceId, elementId, strNum, staNum, agiNum, chaNum, intNum, shiNum);

        //        _safeMint(owner(), tokenId);
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

    constructor() ERC721("Badge", "Badge") Ownable() {
        mapList[1][1] = tk_golden;
        mapList[1][2] = tk_red;
        mapList[1][3] = tk_orange;
        mapList[1][4] = tk_blue;
        mapList[1][5] = tk_green;
        mapList[1][6] = tk_white;

        mapList[2][1] = cike_golden;
        mapList[2][2] = cike_red;
        mapList[2][3] = cike_orange;
        mapList[2][4] = cike_blue;
        mapList[2][5] = cike_green;
        mapList[2][6] = cike_white;

        mapList[3][1] = ss_golden;
        mapList[3][2] = ss_red;
        mapList[3][3] = ss_orange;
        mapList[3][4] = ss_blue;
        mapList[3][5] = ss_green;
        mapList[3][6] = ss_white;

        mapList[4][1] = ms_golden;
        mapList[4][2] = ms_red;
        mapList[4][3] = ms_orange;
        mapList[4][4] = ms_blue;
        mapList[4][5] = ms_green;
        mapList[4][6] = ms_white;

        mapList[5][1] = fs_golden;
        mapList[5][2] = fs_red;
        mapList[5][3] = fs_orange;
        mapList[5][4] = fs_blue;
        mapList[5][5] = fs_green;
        mapList[5][6] = fs_white;

        mapList[6][1] = zs_golden;
        mapList[6][2] = zs_red;
        mapList[6][3] = zs_orange;
        mapList[6][4] = zs_blue;
        mapList[6][5] = zs_green;
        mapList[6][6] = zs_white;
    }
}


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