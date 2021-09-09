/**
 *Submitted for verification at Etherscan.io on 2021-09-09
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


contract Lute is ERC721Enumerable, ReentrancyGuard, Ownable {

    mapping (address => bool) private _whitelist;
    mapping (address => uint256) private _whitelistMints;
    uint256 private constant _maxWhitelistMint = 11;

    string[] private genresCommon = [
        "Alternative",
        "Bluegrass",
        "Blues",
        "Classical",
        "Country",
        "Electronic",
        "Folk",
        "Funk",
        "Heavy Metal",
        "Hip Hop",
        "Indie Rock",
        "Jazz",
        "Pop",
        "Pop Punk",
        "Punk",
        "Rock",
        "Soul",
        "Techno",
        "Religious",
        "Disco"
    ];
    
    string[] private genresMid = [
        "Acid House",
        "Black Metal",
        "Boy Band",
        "Celtic",
        "Dubstep",
        "G-Funk",
        "Grindcore",
        "Post-Rock",
        "K-Pop",
        "Polka",
        "Post-Punk",
        "SKA",
        "Trap",
        "Death Metal",
        "Garage",
        "Opera",
        "Industrial",
        "Lo-fi",
        "Emo",
        "Ambient"
    ];
    
    string[] private genresRare = [
        "Afrobeat",
        "ASMR",
        "Doom Metal",
        "Chiptune",
        "Elevator Music",
        "West Coast Hip Hop",
        "Boom Bap",
        "Crust Punk",
        "Dreampunk",
        "Sludge Metal",
        "Grime",
        "Jungle",
        "Doo-wop",
        "Bossa Nova",
        "Choral",
        "Porno",
        "Psych Rock",
        "Sound Effects for Daytime Television",
        "Film Scores"
    ];

    string[] private instrumentsCommon = [
        "Acc. Guitar",
        "Bass Guitar",
        "Drum Set",
        "Elec. Guitar",
        "Keyboard",
        "MIDI Keyboard",
        "Piano",
        "Synth",
        "Vocalist",
        "Saxophone",
        "Violin",
        "Turntables"
    ];
    
    string[] private instrumentsMid = [
        "Ableton Live",
        "Bongos",
        "Cabasa",
        "Cello",
        "Clarinet",
        "Cowbell",
        "Drum Machine",
        "Flute",
        "Organ",
        "Harmonica",
        "Harpsichord",
        "Moog Synth",
        "Oboe",
        "Rhodes",
        "Shaker",
        "Upright Bass",
        "Triangle",
        "Trombone",
        "Trumpet",
        "Tuba",
        "Ukulele",
        "Vibraphone",
        "Djembe",
        "Harp"
    ];

    string[] private instrumentsRare = [
        "Vocoder",
        "Bar. Guitar",
        "Beatboxing",
        "Cajon",
        "Car Horn",
        "Castanets",
        "Clavichord",
        "Didgeridoo",
        "Fender Strat",
        "Hand Farts",
        "Kazoo",
        "Lute",
        "Mod. Synth",
        "Pan Pipes",
        "Prophet Synth",
        "Sitar",
        "Slide Whistle",
        "Sousaphone",
        "Steel Drums",
        "Talk Box",
        "Theremin",
        "Thumb Piano",
        "Timpani",
        "MPC",
        "Keytar"
    ];

    string[] private riderRequestsCommon = [
        "Buffet",
        "Pack of Newports",
        "Ticket for a Buffalo Chicken Wrap",
        "6 Domestic Beers",
        "6 Imported Beers",
        "Two Drink Tickets",
        "Two Guest Tickets",
        "Shot of Whiskey",
        "Veggie Tray",
        "Moral Support",
        "One Guest List Spot",
        "Fruit Platter",
        "Two Bottles of Water"
    ];

    string[] private riderRequestsMid = [
        "Coffee Stirred Counterclockwise",
        "Essential Oils",
        "Blunt Roller on Staff",
        "Driver Dressed in 100% Cotton",
        "Personal Driver",
        "Fast Food Served on Fine China",
        "Floor Lamps with Dimmer Switch",
        "Personal Chef",
        "Priority Access to TopShot Queues",
        "Private Elevator",
        "Private OpenSea Listings",
        "1 Bowl of Fresh Homemade Guacamole",
        "Box of Huggies Baby Nature Care Wipes",
        "20 Dozen Clean Towels",
        "25 Pound Dumbbells",
        "4 Small Vases with White Tulips",
        "Masseuse",
        "No Bananas Anywhere in the Building",
        "Pool Kept at 98 Degrees",
        "Nivea Chapstick",
        "No Coca-Cola Products",
        "Someone to Throw Out Gum",
        "48 Natural Scented Incense Sticks",
        "Heavily Seasoned Chicken Wings"
    ];

    string[] private riderRequestsRare = [
        "Cristal with Bendy Straws",
        "Pack of Marlboro Lights w/ Lighter",
        "A Bottle of Ketel One to Clean Things",
        "A Framed Photo of Princess Diana",
        "Full Floor of a Hotel",
        "7 Dressing Rooms",
        "A Mannequin w/ Pink Pubic Hair",
        "A Room Full of Puppies",
        "A Room of Wigs",
        "All White Everything",
        "Armored Car Escort",
        "Disinfected Doorknobs",
        "New Toilet Seat at Every Venue",
        "Dr. Bronner's Peppermint Soap",
        "Ping Pong Table",
        "No Crew Members Named Justin",
        "Someone Dressed as Bob Hope",
        "Slushy Machine w/ Coke and Hennessy",
        "Sedentary Curiosities",
        "Room Temp at 78 Degrees",
        "Private Toilet w/ New Toilet Seat",
        "One Large Fur Rug",
        "Private Jet on Standby",
        "Personal Basketball Court",
        "Police Escort",
        "Handful of BYOPills",
        "No Interviews"
    ];

    string[] private venuesCommon = [
        "Alone",
        "Auditorium",
        "Beach",
        "Canada",
        "Carnival",
        "Charity Event",
        "Coffee House",
        "Dive Bar",
        "Golf Course",
        "Jail",
        "Mom's Basement",
        "Motel 6",
        "Office Party",
        "Oil Rig",
        "Parking Lot",
        "Porch",
        "Shipping Container",
        "Theater",
        "Trailer Park",
        "Watering Hole",
        "Wedding",
        "Nefarious Gatherings"
    ];

    string[] private venuesMid = [
        "Amphitheater",
        "Arena",
        "Festival Ground",
        "Forest",
        "Base of a Volcano",
        "Castle",
        "Grand Canyon",
        "Haunted House",
        "Heaven",
        "Hell",
        "Cemetery",
        "Childhood Dreams",
        "Metaverse",
        "Mountains",
        "Ozarks",
        "Rooftop",
        "Stadium",
        "Steamship",
        "Temple",
        "The Future",
        "The Past",
        "Underground Club",
        "Warehouse",
        "Yacht",
        "Alternate Dimension"
    ];

    string[] private venuesRare = [
        "LilNoobie's Backyard",
        "Pacific Ocean",
        "ArtBlocks Factory",
        "Asgard",
        "Private Island",
        "Bob's Burgers",
        "Satman's Metaverse Gallery",
        "Burning Roof Top",
        "City Wok",
        "Earth 616",
        "Earth's Core",
        "Four Seasons Total Landscaping",
        "Ice Fortress",
        "Mandalore",
        "The Sun",
        "The Void",
        "Moon Base",
        "9 Lives Lounge",
        "Mos Eisley Cantina",
        "Mount Rushmore",
        "Columbus Crew Stadium",
        "Namek",
        "TEPNU's Pirate Ship",
        "Razorback Stadium"
    ];
    
    string[] private influencesCommon = [
        "Aaliyah",
        "Alice Cooper",
        "Aretha Franklin",
        "Avril Lavigne",
        "Bach",
        "Beethoven",
        "Beyonce",
        "Bob Dylan",
        "Bob Marley",
        "Carrie Underwood",
        "Cher",
        "Coldplay",
        "Diana Ross",
        "Dixie Chicks",
        "Dolly Parton",
        "Dr. Dre",
        "Drake",
        "Ella Fitzgerald",
        "Eminem",
        "God",
        "Jackson 5",
        "James Brown",
        "Janis Joplin",
        "Jay Z",
        "Jonas Brothers",
        "Joni Mitchell",
        "Kendrick Lamar",
        "Lauryn Hill",
        "Led Zeppelin",
        "Madonna",
        "Marvin Gaye",
        "Michael Jackson",
        "Mozart",
        "Nirvana",
        "NSYNC",
        "Reba McEntire",
        "Radiohead",
        "Run DMC",
        "RZA",
        "Shania Twain",
        "Stevie Nicks",
        "Sublime",
        "Taylor Swift",
        "The Beatles",
        "The Carpenters",
        "The Doors",
        "The Rolling Stones",
        "The Supremes",
        "Tyler, the Creator",
        "Van Halen",
        "Whitney Houston",
        "Yo-Yo Ma",
        "Iron Maiden",
        "Slayer"
    ];

    string[] private influencesMid = [
        "Fleetwood Mac",
        "Flight of the Conchords",
        "Electric Light Orchestra",
        "Goo Goo Dolls",
        "Gorillaz",
        "Grateful Dead",
        "Hank Williams",
        "Hanson",
        "Janet Jackson",
        "KRS-One",
        "Lin-Manuel Miranda",
        "Mandy Moore",
        "Metallica",
        "Moby",
        "Modest Mouse",
        "Nicki Minaj",
        "Nickelback",
        "Nina Simone",
        "No Doubt",
        "Parliament",
        "A Tribe Called Quest",
        "Prince",
        "Reel Big Fish",
        "Sheryl Crow",
        "Sly and the Family Stone",
        "Spinal Tap",
        "Tenacious D",
        "The Blues Brothers",
        "The Devil",
        "The Fugees",
        "The Offspring",
        "The Pixies",
        "Wyld Stallyns",
        "Pantera",
        "Tool",
        "?uestlove",
        "Weird Al Yankovic",
        "Alanis Morissette",
        "Ani DiFranco",
        "Arctic Monkeys",
        "Backstreet Boys",
        "Beck",
        "BTS",
        "Blink 182",
        "Childish Gambino",
        "D'Angelo",
        "Daft Punk",
        "Death Cab for Cutie"
    ];

    string[] private influencesRare = [
        "Kate Bush",
        "Mos Def",
        "Mouse Rat",
        "Neutral Milk Hotel",
        "Noname",
        "Patti Smith",
        "Sex Bob-Omb",
        "MF DOOM",
        "Smokey Robinson",
        "Swedish House Mafia",
        "SZA",
        "The Bangles",
        "Travis Tritt",
        "Velvet Underground",
        "Vince Staples",
        "Woody Guthrie",
        "Deep Purple",
        "Dream Theater",
        "Rush",
        "Ja Rule",
        "9th Wonder",
        "Arvo Part",
        "Black Thought",
        "Blondie",
        "Buddy Holly",
        "Carl Cox",
        "Chemical Brothers",
        "Daniel Johnston",
        "DJ Premier",
        "DragonForce",
        "Earl Sweatshirt",
        "Erykah Badu",
        "Eugene Belcher",
        "Fiona Apple",
        "Funkadelic",
        "Jethro Tull",
        "Joan Baez",
        "Joe Cocker"
    ];

    string[] private vehiclesCommon = [
        "18-Wheel Semi",
        "Bicycle",
        "Dog-Sled",
        "Escalator",
        "Feet",
        "Golf Cart",
        "Grocery Cart",
        "Hatchback",
        "Minivan",
        "Mule Train",
        "Pedal Cab",
        "Pogo Sticks",
        "Rickshaw",
        "Rollerblades",
        "Unicycle",
        "Sailboat",
        "School Bus",
        "Scooters",
        "Skateboard",
        "Subway",
        "VW Bus",
        "Van"
    ];

    string[] private vehiclesMid = [
        "RV",
        "Tour Bus",
        "Yo Mamma",
        "Luxury Sedan",
        "Armored Car",
        "Balloons",
        "Monster Truck",
        "Bobsled",
        "Caravan",
        "Cruise Ship",
        "Elevator",
        "Gondola",
        "Helicopter",
        "Horse",
        "Hovercraft",
        "Blow-up Raft",
        "Snowmobile",
        "Zamboni",
        "Limo",
        "Jet Ski"
    ];

    string[] private vehiclesRare = [
        "ATAT-Walker",
        "Dirigible",
        "Jetpack",
        "Spacecraft",
        "Submarine",
        "$anta's Sled",
        "Palanquin",
        "Angels' Wings",
        "Magic Carpet",
        "UFO",
        "Private Jet",
        "Rainbow",
        "Rocket",
        "Pegasus",
        "X-Wing",
        "Yacht",
        "Rollercoaster",
        "Royal Canoe",
        "Portal",
        "1995 Windstar",
        "MuttCutts Van"
    ];

    string[] private suffixes = [
        "Composition",
        "Nihilism",
        "Ego",
        "Elegance",
        "Improvisation",
        "Power",
        "Serenity",
        "Fury",
        "Clarity",
        "Solidarity",
        "Virility",
        "Stardom",
        "Good Vibes",
        "Love",
        "Peace",
        "Shadows",
        "Splendor",
        "Madness",
        "Tranquility",
        "War",
        "Wonder",
        "Local Acclaim",
        "the Third Eye",
        "Envy",
        "Betrayal",
        "Inner Peace",
        "Fame",
        "Fortune",
        "Inspiration",
        "Perfect Pitch",
        "Perfect Time",
        "Self Loathing",
        "Mediocrity",
        "Looting",
        "Doom",
        "Divination"
    ];
    
    string[] private namePrefixes = [
        "Antique",
        "Brand New",
        "Busted Up",
        "Diamond",
        "Dope",
        "Exquisite",
        "Haunted",
        "Golden",
        "Lucky",
        "Rusty",
        "Sexy",
        "Silver",
        "Trusty",
        "Ancient",
        "Legendary",
        "Platinum",
        "Wooden",
        "Tenacious",
        "Plastic",
        "Alien",
        "Radical",
        "Flaming",
        "Bedazzled",
        "Boring",
        "Epic",
        "Glowing",
        "Groovy",
        "Used",
        "Shiny",
        "Invisible",
        "Mirrored"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getRarity(uint256 tokenId, string memory keyPrefix, string[] memory commonArray, string[] memory midArray, string[] memory rareArray) internal pure returns (string[] memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, "MAINNETRARITYSTRING" ,toString(tokenId))));
        uint256 chance = rand % 100;
        if (chance < 70) {
            return commonArray;
        } else if (chance < 95) {
            return midArray;
        } else {
            return rareArray;
        }
    }

    function getGenre(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "GENRE", genresCommon, genresMid, genresRare, false);
    }

    function getRiderRequest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "RIDERREQUEST", riderRequestsCommon, riderRequestsMid, riderRequestsRare, false);
    }

    function getVenue(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VENUE", venuesCommon, venuesMid, venuesRare, false);
    }

    function getInfluence(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INFLUENCE", influencesCommon, influencesMid, influencesRare, false);
    }

    function getVehicle(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "VEHICLE", vehiclesCommon, vehiclesMid, vehiclesRare, true);
    }

    function getInstrument1(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INSTRUMENT1", instrumentsCommon, instrumentsMid, instrumentsRare, true);
    }

    function getInstrument2(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INSTRUMENT2", instrumentsCommon, instrumentsMid, instrumentsRare, true);
    }

    function getInstrument3(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "INSTRUMENT3", instrumentsCommon, instrumentsMid, instrumentsRare, true);
    }

    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory commonArray, string[] memory midArray, string[] memory rareArray, bool addAffix) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, "RANDOMSTRING", toString(tokenId))));
        string[] memory sourceArray = getRarity(tokenId, keyPrefix, commonArray, midArray, rareArray);
        string memory output = sourceArray[rand % sourceArray.length];
        if (addAffix) {
            uint256 greatness = rand % 21;
            if (greatness > 14) {
                output = string(abi.encodePacked(output, " of ", suffixes[rand % suffixes.length]));
            }
            if (greatness >= 19) {
                string memory name = namePrefixes[rand % namePrefixes.length];
                output = string(abi.encodePacked(name, ' ', output));
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: rgb(5, 5, 5); font-family: Courier; font-size: 12px; }</style><rect width="100%" height="100%" fill="rgb(235, 234, 232)" /><text x="10" y="20" class="base">GNRE: ';

        parts[1] = getGenre(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">INS1: ';

        parts[3] = getInstrument1(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">INS2: ';

        parts[5] = getInstrument2(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">INS3: ';

        parts[7] = getInstrument3(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">INFL: ';

        parts[9] = getInfluence(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">VENU: ';

        parts[11] = getVenue(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">VEHC: ';

        parts[13] = getVehicle(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">RIDR: ';

        parts[15] = getRiderRequest(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        string memory tempJson = string(abi.encodePacked('{"attributes":[{"trait_type":"Genre","value":"', parts[1], '"},{"trait_type":"Instrument 1","value":"', parts[3], '"},{"trait_type":"Instrument 2","value":"', parts[5], '"},{"trait_type":"Instrument 3","value":"', parts[7],'"},{"trait_type":"Influence","value":"'));
        tempJson = string(abi.encodePacked(tempJson, parts[9], '"},{"trait_type":"Venue","value":"', parts[11], '"},{"trait_type":"Vehicle","value":"', parts[13], '"},{"trait_type":"Rider Request","value":"', parts[15], '"}],"name": "Band #'));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(tempJson,toString(tokenId), '", "description": "Lute consists of randomized musical identities that are generated and stored on-chain. The instruments, influences, genres, and other particulars are simply the foundation of our collective effort to fill the airwaves of the nascent metaverse.  Whether you have plans to take over the Shillboard Hot 100 or just want to piss off your neighbors, these traits await your exploration and interpretation. Feel free to use Lute in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        require(tokenId > 7898 && tokenId < 8001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    function isWhitelisted(address addr) public view returns (bool) {
        return _whitelist[addr];
    }

    function addToWhitelist(address[] memory addrs) public onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _whitelist[addrs[i]] = true;
            _whitelistMints[addrs[i]] = 0;
        }
    }

    function whitelistClaim(uint256 tokenId) public nonReentrant {
        require(isWhitelisted(msg.sender), "Address not whitelisted");
        require(_whitelistMints[msg.sender] + 1 <= _maxWhitelistMint, "Exceeds max whitelist mint");
        require(tokenId > 7777 && tokenId < 7899, "Token ID invalid");
        _whitelistMints[msg.sender] += 1;
        _safeMint(_msgSender(), tokenId);
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

    constructor() ERC721("Lute", "LUTE") Ownable() {}
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