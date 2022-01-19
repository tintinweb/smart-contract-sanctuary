/**
 *Submitted for verification at Etherscan.io on 2022-01-19
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

/// @title A Loot-Derivative Project for the Travel Industry
/// @author jacmos3 - TripsCommunity
/// @notice Text-based NFTs thought for the Travel Industry appannage. Hotels, restaurants, hospitality etc can use them both in the real or metaverse worlds
contract TravelerLoot is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 private constant DISCOUNT_EXPIRATION = 1790553599; //Sun 27 Sep 2026 21:59:59 UTC
    string private constant WHITE = "white";
    string private constant BLACK = "black";
    string private constant GOLD = "gold";
    string private constant PLATINUM = "#D5D6D8";
    string private constant GUILD = "GUILD";
    string private constant PATRON = "PATRON";
    string private constant CONQUEROR = "CONQUEROR";
    uint160 private constant INITIAL_PRICE_FOR_PATRONS = 1 ether;
    string private constant ERROR_TOKEN_ID_INVALID = "Token ID invalid";
    string private constant ERROR_ADDRESS_NOT_VERIFIED = "Address not verified. Try another";
    string private constant ERROR_NOT_THE_OWNER = "You do not own token(s) of the address";
    string private constant ERROR_DOM_40TH_BIRTHDAY = "Only valid till Dom's 40th bday";
    string private constant ERROR_LOW_VALUE = "Set a higher value";
    string private constant ERROR_COMPETITION_ENDED = "Competition has ended. Check the Conqueror!";
    string private constant ERROR_COMPETITION_ONGOING = "Conqueror not yet elected!";
    string private constant ERROR_OWNER_NOT_ALLOWED = "Use claimByOwner() instead";
    string private constant ERROR_ALREADY_ACTIVATED = "Already activated";
    string private constant ERROR_COME_BACK_LATER = "Come back later";
    string private constant ERROR_WITHDRAW_NEEDED = "Treasurer already changed. Perform a withdrawal before changing it";
    string private constant ERROR_GUILD_ALREADY_WHITELISTED = "Guild already whitelisted!";
    string private constant ERROR_CANNOT_ADD_THIS_CONTRACT = "Not possible";
    string private constant ERROR_NOT_ENTITLED = "Check conditions before whitelisting";

    address private constant INITIAL_TREASURER = 0xce73904422880604e78591fD6c758B0D5106dD50; //TripsCommunity address
    address private constant ADDRESS_OG_LOOT = 0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7;
    address private constant PH_USERS = address(1);
    address private constant PH_PATRONS = address(2);
    address private constant PH_OG_LOOT = address(3);
    address private constant PH_CONQUERORS = address(4);
    address private constant PH_OWNER = address(0);

    uint16 public constant MAX_ID = 10000;
    uint16 public constant MAX_FOR_OWNER = 100;
    uint16 public constant MAX_FOR_GUILDS = 900;
    uint16 public constant LOCK_TIME = 5760 * 3; //it's three days
    struct Traveler {
        string familyType;
        string familyName;
        string color;
        uint256 counter;
        bool verified;
    }

    struct Conqueror {
      address addr;
      uint16 count;
      bool elected;
    }

    struct Treasurer {
      address old;
      address current;
      uint256 blockNumber;
    }

    struct Initial{
        address addr;
        string symbol;
    }
    Conqueror public conqueror;
    Treasurer public treasurer;
    bool public canChangeTreasurer = true;
    mapping(address => Traveler) public detailsByAddress;
    mapping(uint256 => address) public addressList;
    uint8 public counterOwner = 0;
    uint16 public counterStandard = 0;
    uint16 public counterGuild = 0;
    uint16 public counterPatrons = 0;
    uint160 public priceForPatrons = INITIAL_PRICE_FOR_PATRONS;
    uint256 public blockActivation = 0;
    string[] private categories = ["ENVIRONMENT","TALENT","PLACE","CHARACTER","TRANSPORT","LANGUAGE","EXPERIENCE","OCCUPATION","ACCOMMODATION","BAG"];

    address[] public whiteListedGuilds;
    mapping(string => string[]) elements;



    constructor() ERC721("TravelerLoot", "TRVLR") Ownable(){
      uint256 blockNumber = block.number;
      treasurer.old = address(0);
      treasurer.current = INITIAL_TREASURER;
      treasurer.blockNumber = blockNumber;
      elements[categories[0]] = ["Beaches", "Mountains", "Urban", "Countrysides", "Lakes", "Rivers", "Farms", "Tropical areas", "Snowy places", "Forests", "Historical cities", "Islands", "Wilderness", "Deserts", "Natural parks", "Old towns", "Lakes", "Villages", "Forests", "Coral Reefs", "Wetlands", "Rainforests", "Grasslands", "Chaparral"];
      elements[categories[1]] = ["Cooking", "Painting", "Basketball", "Tennis", "Football", "Soccer", "Climbing", "Surfing", "Photographer", "Fishing", "Painting", "Writing", "Dancing", "Architecture", "Singing", "Dancing", "Baking", "Running", "Sword-fighting", "Boxing", "Jumping", "Climbing", "Hiking", "Kitesurfing", "Sailing", "Comforting others", "Flipping NFTs", "Katana sword fighter", "Programming Solidity", "Creating Memes"];
      elements[categories[2]] = ["Eiffel Tower", "Colosseum", "Taj Mahal", "Forbidden City", "Las Vegas", "Sagrada Familia", "Statue of Liberty", "Pompeii", "Tulum", "St. Peter's Basilica", "Bangkok", "Tower of London", "Alhambra", "San Marco Square", "Ciudad de las Artes y las Ciencias", "Moscow Kremlin", "Copacabana", "Great Wall of China", "Havana", "Arc de Triomphe", "Neuschwanstein Castle", "Machu Picchu", "Gili Islands", "Maya Bay", "Etherscan", "0x0000000000000000000000000000000000000000", "::1", "42.452483,-6.051345","Parcel 0, CityDAO", "Wyoming"];
      elements[categories[3]] = ["Energetic", "Good-Natured", "Enthusiastic", "Challenging", "Charismatic", "Wise", "Modest", "Honest", "Protective", "Perceptive", "Providential", "Prudent", "Spontaneous", "Insightful", "Intelligent", "Intuitive", "Precise", "Sharing", "Simple", "Sociable", "Sophisticated", "Benevolent", "Admirable", "Brilliant", "Accessible", "Calm", "Capable", "Optimistic", "Respectful", "Responsible"];
      elements[categories[4]] = ["Train", "Car", "Airplane", "Cruise", "4 wheel drive car", "Bus", "Convertible car", "Bicycle", "Motorbike", "Campervan", "Trailer", "Sailboat", "Electric car", "Sidecar", "Scooter", "Tram", "Cinquecento", "Hitch-hiking", "VW Beetle", "VW Bus", "Truck", "Off-road Vehicle", "Cab", "Lambo", "Ferrari", "Rocket", "DeLorean", "Kia Sedona", "Magic carpet", "Broomstick"];
      elements[categories[5]] = ["English", "Mandarin Chinese", "Hindi", "Spanish", "Arabic", "French", "Russian", "Portuguese", "Indonesian", "German", "Japanese", "Turkish", "Korean", "Vietnamese", "Iranian Persian", "Swahili", "Javanese", "Italian", "Thai", "Filipino", "Burmese", "Polish", "Croatian", "Danish", "Serbian", "Slovenian", "Czech", "Slovakian", "Greek", "Hungarian"];
      elements[categories[6]] = ["2", "3", "4", "5", "6", "7", "8", "9","10","100","0","1"];
      elements[categories[7]] = ["Host", "Cook", "Writer", "DeeJay", "Employee", "Doctor", "Traveler", "Tour Guide", "Ship Pilot", "DAO Member", "Driver", "NFT flipper", "Meme creator", "Sales Manager", "Play 2 Earner", "NFT collector", "Hotel receptionist", "Hotel Manager", "Digital Nomad", "Crypto Trader", "Head of Growth", "PoS validator", "Lightning Network Developer", "Anonymous DeFi Protocol Lead", "Yacht owner (in bull markets)", "Web3 Engineer", "Blockchain Consultant", "Crypto VC", "Miner","Metaverse Realtor"];
      elements[categories[8]] = ["Hotel", "Apartment", "Hostel", "Tent", "BnB", "Guest House", "Chalet", "Cottage", "Boat", "Caravan", "Motorhome", "5 stars Hotel", "Suite in 5 Stars Hotel", "Tipi", "Tree House", "Bungalow", "Ranch", "Co-living", "Gablefront cottage", "Longhouse", "Villa", "Yurt", "Housebarn", "Adobe House", "Castle", "Rammed earth", "Underground living", "Venetian palace", "Igloo", "Trullo"];
      elements[categories[9]] = ["Pen", "eBook reader", "Water", "Cigarettes", "Swiss knife", "Mobile phone", "Notebook", "Laptop", "Digital Camera", "Lighter", "Earphones", "Beauty case", "Toothbrush", "Toothpaste", "Slippers", "Shirts", "Pants", "T-shirts", "Socks", "Underwear","Condoms"];

      detailsByAddress[PH_USERS] = Traveler({color:BLACK,familyType:"",familyName:"",counter:0,verified:true});
      detailsByAddress[PH_PATRONS] = Traveler({color:"#F87151",familyType:PATRON,familyName:"",counter:0,verified:true});
      detailsByAddress[PH_OG_LOOT] = Traveler({color:GOLD,familyType:PATRON,familyName:"Loot (for Adventurers)",counter:0,verified:true});
      detailsByAddress[PH_CONQUERORS] = Traveler({color:WHITE,familyType:CONQUEROR,familyName:"",counter:0,verified:true});
      detailsByAddress[PH_OWNER] = Traveler({color:BLACK,familyType:" ",familyName:"",counter:0,verified:true});

      whiteListedGuilds.push(ADDRESS_OG_LOOT);
      detailsByAddress[ADDRESS_OG_LOOT] = Traveler({color:BLACK,familyType:PLATINUM,familyName:"LOOT",counter:0,verified:true});
    }

    modifier checkStart() {
      require(blockActivation > 0 && block.number >= blockActivation,ERROR_COME_BACK_LATER);
      _;
    }

    /// @notice                     Everyone can claim an available tokenId for free (+ gas)
    function claim() external nonReentrant checkStart {
        require(owner() != _msgSender(),ERROR_OWNER_NOT_ALLOWED);
        uint16 adjusted = 1 + counterStandard + MAX_FOR_GUILDS + MAX_FOR_OWNER;
        require(adjusted <= MAX_ID, ERROR_TOKEN_ID_INVALID);
        processing(adjusted,PH_USERS,1,false);
        _safeMint(_msgSender(), adjusted);
        counterStandard++;
    }

    /// @notice                     Guilds can use this function to mint a forged Traveler Loot.
    ///                             Forged TLs are recognizable by a colored line on the NFT.
    ///                             When all the forgeable TLs are minted, the guild who forged
    ///                             the most becomes Conqueror. Its members gain access to
    ///                             claimByConquerors() function
    /// @param                      tokenId         derivative's tokenId owned by the user
    /// @param                      contractAddress derivative's address pretending to be guild
    function claimByGuilds(uint256 tokenId, address contractAddress) external nonReentrant checkStart{
        require(!conqueror.elected, ERROR_COMPETITION_ENDED);
        Traveler storage details = detailsByAddress[contractAddress];
        require(details.verified, ERROR_ADDRESS_NOT_VERIFIED);
        IERC721 looter = IERC721(contractAddress);
        require(tokenId > 0 && looter.ownerOf(tokenId) == _msgSender(), ERROR_NOT_THE_OWNER);
        if (details.counter == 0 && contractAddress != whiteListedGuilds[0]){
            details.color = pickAColor();
        }
        uint16 discretId = uint16(tokenId % MAX_FOR_GUILDS);

        if (counterGuild == MAX_FOR_GUILDS - 1 ){
            (conqueror.addr, conqueror.count) = whoIsWinning();
            conqueror.elected = true;
            detailsByAddress[PH_CONQUERORS].color = details.color;
            detailsByAddress[PH_CONQUERORS].familyName = details.familyName;
        }
        // after this mint, the price for patrons will be increased by 1%
        uint16 finalId = discretId == 0 ? MAX_FOR_GUILDS : discretId;
        processing(finalId, contractAddress, 1, true);
        _safeMint(_msgSender(), finalId);
        counterGuild++;
    }

    /// @notice                     Becoming a Patron. Requires payment
    function claimByPatrons() external payable nonReentrant checkStart{
      require(msg.value >= priceForPatrons, ERROR_LOW_VALUE);
      if (priceForPatrons < INITIAL_PRICE_FOR_PATRONS){
        priceForPatrons == INITIAL_PRICE_FOR_PATRONS;
      }
      // After this mint, the price for next patrons will be increased by 5%
      reservedMinting(PH_PATRONS, 5, true);
      counterPatrons++;
    }

    /// @notice                     - Loot (for Adventurers) holders can become Patrons for free if:
    ///                             . the Conqueror Guild is not yet elected,
    ///                             . or Dominik Hoffman (@ dhof on twitter) is still younger than 40 y/o.
    function claimByOGLooters() external nonReentrant checkStart{
      require(IERC721(whiteListedGuilds[0]).balanceOf(_msgSender()) > 0, ERROR_NOT_THE_OWNER);
      require(!conqueror.elected, ERROR_COMPETITION_ENDED);
      require(block.timestamp <= DISCOUNT_EXPIRATION, ERROR_DOM_40TH_BIRTHDAY);

      // After this mint, the price for patrons will be decreased by 5%
      reservedMinting(PH_OG_LOOT, 5, false);
      counterPatrons++;
    }

    /// @notice                     Conquerors can mint a CONQUEROR Traveler Loot for free + gas
    ///                             only valid if they have not already minted a PATRON type before
    function claimByConquerors() external nonReentrant checkStart{
        require(conqueror.elected, ERROR_COMPETITION_ONGOING);
        require(IERC721(conqueror.addr).balanceOf(_msgSender()) > 0, ERROR_NOT_THE_OWNER);
        // After this mint, the price for patrons is increased by 2%
        reservedMinting(PH_CONQUERORS, 2, true);
        counterPatrons++;
    }

    /// @notice                     Owner can claim its reserved tokenIds.
    function claimByOwner() external nonReentrant onlyOwner checkStart{
        uint16 adjusted = 1 + counterOwner + MAX_FOR_GUILDS;
        require(adjusted <= MAX_FOR_GUILDS + MAX_FOR_OWNER, ERROR_TOKEN_ID_INVALID);
        //after this mint, the price for patrons will remain the same
        processing(adjusted,PH_OWNER,0,true);
        _safeMint(_msgSender(), adjusted);
        counterOwner++;
    }

    /// @notice                     Owner can call this function to activate the mintings.
    ///                             Note that the activation is delayed of LOCK_TIME blocks
    function activateClaims() external onlyOwner{
      require (blockActivation == 0, ERROR_ALREADY_ACTIVATED);
      blockActivation = block.number + LOCK_TIME;
    }

    /// @notice                     Owner can order the withdraw all the funds coming from Patron mints
    ///                             to the Treasurer address previously set.
    function withdraw() external onlyOwner {
      require(block.number >= treasurer.blockNumber, ERROR_COME_BACK_LATER);
      canChangeTreasurer = true; //release treasurer
      payable(treasurer.current).transfer(address(this).balance);
    }


    /// @notice                     . Owner calls this function with lockTreasurer = true if the intent is
    ///                             to do a donation to a public-good project. Lock guarantees that nobody
    ///                             (not even the owner) can change treasurer till the donation is made.
    ///                             . Owner calls this function with lockTreasurer = false if the intent is
    ///                             to keep open the chance to change the treasurer even if no any
    ///                             withdrawal has been performed in the meanwhile.
    /// @param      newAddress      the new treasurer address
    /// @param      lockTreasurer   true if the the treasurer has to be locked till one withdraw is performed
    function setTreasurer(address newAddress, bool lockTreasurer) external onlyOwner{
      require(canChangeTreasurer, ERROR_WITHDRAW_NEEDED); //this is a safety measure for when donating to public goods
      if (lockTreasurer){
        canChangeTreasurer = false;
      }
      uint256 blockNumber = block.number + LOCK_TIME;
      treasurer.old = treasurer.current;
      treasurer.current = newAddress;
      treasurer.blockNumber = blockNumber;
    }

    /// @notice                     You can register new Guilds to the whitelist, if:
    ///                             - You own at least 50 Traveler Loots in your address
    ///                             - Or if you have mint a Patron version by using claimByPatrons() or
    ///                             claimByOGLooters() functions (no matter if you dont own them anymore)
    ///                             - Or if you are the owner of this Contract
    ///                             NOTE: no Guilds can be registered once the competition has ended
    /// @param      addresses       List of contract addresses to be whitelisted for the game.
    ///                             They'll be allowed to mint GUILD type Traveler Loot
    function addNewGuildToWhiteList(address[] calldata addresses) nonReentrant external {
        require(!conqueror.elected, ERROR_COMPETITION_ENDED);
        for (uint8 j = 0; j< addresses.length; j++){
            address addr = addresses[j];
            require(address(this) != addr, ERROR_CANNOT_ADD_THIS_CONTRACT);
            require(IERC721(address(this)).balanceOf(_msgSender()) > 50
                        || _exists(uint160(_msgSender()))
                        || owner() == _msgSender()
                    ,ERROR_NOT_ENTITLED);
            for (uint16 i = 0; i < whiteListedGuilds.length; i++){
                require(whiteListedGuilds[i] != addr, ERROR_GUILD_ALREADY_WHITELISTED);
            }
            whiteListedGuilds.push(addr);
            detailsByAddress[addr] = Traveler({color:BLACK,familyType:GUILD,familyName:familyName(addr),counter:0,verified:true});
        }
    }

    /// @notice                     Given a Guild address, returns the count for that addr
    /// @param      addr            Address of the Guild to be checked (the contract address)
    /// @return                     Number of the NFT minted from the members of the given Guild address
    function getCounterForAddress(address addr) external view returns (uint256){
        Traveler memory details = detailsByAddress[addr];
        require(details.verified, ERROR_ADDRESS_NOT_VERIFIED);
        return details.counter;
    }

    /// @notice                     Call this function if you want to know the list of the current Guilds
    /// return                      Array containing the addresses of all the whitelisted guilds
    function getWhiteListedGuilds() external view returns (address[] memory){
        return whiteListedGuilds;
    }

    /// @notice                     Call this function to see the element for a given tokenId and categoryId
    /// @param      tokenId         The id of the Traveler Loot you want to check
    /// @param      categoryId      The category of the Traveler Loot you want to check
    /// @return                     The element of the given Token Id for the given categoryId
    function getElement(uint256 tokenId, uint8 categoryId) public view returns (string memory){
      return pluck(tokenId, categories[categoryId], elements[categories[categoryId]]);
    }

    /// @notice                     Provides metadata and image of the PATRONS and CONQUEROR
    /// @param      addr            Address of the user who minted the PATRON or CONQUEROR you are checking
    /// @return                     The json containing the NFT info
    function addressURI(address addr) external view returns (string memory){
        return tokenURI(uint160(addr));
    }

    /// @notice                     Provides metadata and image of the Traveler Loot
    /// @param      tokenId         Token if of the Traveler Loot to process
    /// @return                     The json containing the NFT info
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        Traveler memory details = detailsByAddress[addressList[tokenId]];
        string[4] memory parts;
        parts[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.b { fill:white; font-family: serif; font-size: 14px; }</style> <rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="b">'));
        parts[1] = string(abi.encodePacked(getElement(tokenId,0),'</text><text x="10" y="40" class="b">',getElement(tokenId,1),'</text><text x="10" y="60" class="b">',getElement(tokenId,2),'</text><text x="10" y="80" class="b">',getElement(tokenId,3),'</text><text x="10" y="100" class="b">',getElement(tokenId,4),'</text><text x="10" y="120" class="b">',getElement(tokenId,5)));
        parts[2] = string(abi.encodePacked('</text><text x="10" y="140" class="b">',getElement(tokenId,6),'</text><text x="10" y="160" class="b">',getElement(tokenId,7),'</text><text x="10" y="180" class="b">',getElement(tokenId,8),'</text><text x="10" y="200" class="b">',getElement(tokenId,9),'</text>'));
        parts[3] = string(abi.encodePacked('<line x1="0" x2="350" y1="300" y2="300" stroke="',details.color,'" stroke-width="4"/>','<text x="340" y="294" text-anchor="end" class="b">',details.familyType,'</text></svg>'));

        string memory compact = string(abi.encodePacked(parts[0], parts[1], parts[2],parts[3]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Traveler #', toString(tokenId), '", "description": "Traveler Loot is a Loot derivative for the Travel Industry, generated and stored on chain. Feel free to use the Traveler Loot in any way you want", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(compact)), '","attributes":[',metadata(tokenId,details),']}'))));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /// @notice                     Call this method to check the Guild which is owning the most Forged Traveler Loot
    ///
    /// @return                     The address of the guild who has the most Forged Traveler Loot so far
    /// @return                     The amount of Forged Traveler Loot minted by the Winning Guild so far
    function whoIsWinning() public view returns (address, uint16){
      if (conqueror.elected){
        return (conqueror.addr,conqueror.count);
      }
      address winningLoot = whiteListedGuilds[0];
      uint16 winningCount = uint16(detailsByAddress[winningLoot].counter);

      for (uint8 i = 1; i < whiteListedGuilds.length; i++){
        address addr = whiteListedGuilds[i];
        (winningLoot, winningCount) = checkWinning(winningLoot,winningCount, addr, uint16(detailsByAddress[addr].counter));
      }
      return (winningLoot, winningCount);
    }

    /// @notice                     Call this function to get a random color using block difficulty, timestamp as seed
    /// @return                     A string containing the HEX number of a random color
    function pickAColor() internal view returns (string memory){
        string[16] memory list = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
        string memory color = "#";
        for (uint8 i=0; i<6;i++){
          uint rand = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i )));
          color = string(abi.encodePacked(color,list[rand % list.length]));
        }
        return color;
    }

    /// @notice                     This function calls an external NFT contract and gets the symbol to be used into the metadata
    /// @param      addr            The address of the contract address to whitelist
    /// @return                     The symbol of the given external contract address
    function familyName(address addr) internal view returns (string memory){
      return IERC721Metadata(addr).symbol();
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    /// @notice                     Update the PATRON price and the address counter
    /// @param      id              TokenId minted
    /// @param      addr            address Guild of the token to mint
    /// @param      percentage      percentage number of the PATRON'price variability
    /// @param      isPositive      true if the variability is positive, false if it's negative
    function processing(uint256 id, address addr, uint8 percentage, bool isPositive) internal{
      if (percentage != 0){
        uint160 x = priceForPatrons / (100 / percentage);
        priceForPatrons = isPositive ? priceForPatrons + x : priceForPatrons - x;
      }
      detailsByAddress[addr].counter++;
      addressList[id] = addr;
    }

    /// @notice                     It mints the Traveler Loot using the address as tokenId.
    ///                             Only particular cases can access to this:
    ///                             - Users who decide to become Patrons by paying the patronPrice
    ///                             - Conqueror Guild members, as the prize for have won the competition
    ///                             - OG Loot owners, as privilegiate users till @ dhof 40 bday or till Conqueror Guild election
    /// @param      addr            address Guild of the token to mint
    /// @param      percentage      percentage number of the PATRON'price variability
    /// @param      isPositive      true if the variability is positive, false if it's negative
    function reservedMinting(address addr,uint8 percentage, bool isPositive) internal{
      uint160 castedAddress = uint160(_msgSender());
      require(castedAddress > MAX_ID, ERROR_ADDRESS_NOT_VERIFIED);
      processing(castedAddress, addr, percentage, isPositive);
      _safeMint(_msgSender(), castedAddress);
    }

    /// @notice                     Call this function to get pick the element for a given Traveler Loot id and category
    /// @param      tokenId         TokenId
    /// @param      keyPrefix       Seed/nounce of the randomity
    /// @param      sourceArray     The list of all the elements
    /// @return                     The element extracted
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint8 toHoundred = uint8(rand % 100);
        uint8 delta = toHoundred > 95 ? 1 : toHoundred > 80 ? 2 : 3;
        uint8 len = uint8(sourceArray.length);
        uint8 x = len / 3;
        uint8 min = len - (delta * x);
        uint8 max = (len - 1) - ((delta - 1) * x);
        uint8 rand2 = uint8((random(string(abi.encodePacked(msg.sender, toHoundred, keyPrefix ))) % (max - min + 1)) + min);
        return sourceArray[rand2];
    }

    /// @dev                     This function processes and build the metadata for the given tokenId
    /// @param      tokenId         TokenId
    /// @param      details         The details to be used for filling the metadata
    /// @return                     The json with the metadata to be appended to the full json
    function metadata(uint256 tokenId, Traveler memory details) internal view returns (string memory){
     string memory toRet = "";
     for (uint8 i = 0; i < 10; i++){
        toRet = string(abi.encodePacked(toRet,'{"trait_type":"', categories[i], '","value":"',getElement(tokenId,i),'"},'));
     }
     if (keccak256(abi.encodePacked(details.color)) != keccak256(abi.encodePacked(BLACK))) {
      toRet = string(abi.encodePacked(toRet,'{"trait_type":"Type","value":"',details.familyType,'"}'));
      toRet = string(abi.encodePacked(toRet,',{"trait_type":"Flag Color","value":"',details.color,'"}'));
      toRet = string(abi.encodePacked(toRet,',{"trait_type":"',details.familyType,'","value":"',details.familyName,'"}'));
     }
     else{
        toRet = string(abi.encodePacked(toRet,'{"trait_type":"Type","value":"EXPLORER"}'));
     }

     return toRet;
   }

    /// @dev                     This function compares two Guilds and check which has more Froged Guild already minted
    /// @param      winningAddress  The legacy winning address (so far)
    /// @param      winningCount    The amount for the legacy winning address (so far)
    /// @param      newAddress      The new address to compare with legacy
    /// @param      newCount        The new amount to compare with legacy
    /// @return                     The new winning address after comparison
    /// @return                     The new minted amount of winning address after comparison
    function checkWinning(address winningAddress, uint16 winningCount, address newAddress, uint16 newCount) internal pure returns(address,uint16){
        return newCount > winningCount ? (newAddress, newCount) : (winningAddress, winningCount);
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