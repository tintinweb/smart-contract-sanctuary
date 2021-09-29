/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

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
     * @dev Base URI for computing {f&
     }. If set, the resulting URI for each
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


contract NFTID is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint totalUsers;
    // User Info
    struct User
    {
        string nickname;
        string motto;
        uint age;
        uint id;
    }
    
    mapping(uint256 => User) _users;
    
    function getMsgSender() public view returns (string memory) {
        return Base64.encode(abi.encodePacked(msg.sender));
    }
    
    function getMotto(uint256 tokenId) public view returns (string memory) {
        return _users[tokenId].motto;
    }
    
    function getName(uint256 tokenId) public view returns (string memory) {
        return _users[tokenId].nickname;
    }
    
    function getID(uint256 tokenId) public view returns (string memory) {
        return toString(_users[tokenId].id);
    }
    
    function getAge(uint256 tokenId) public view returns (string memory) {
        return toString(_users[tokenId].age-block.timestamp);
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[14] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 1024 1024" style="enable-background:new 0 0 1024 1024;" xml:space="preserve"><style type="text/css">.st0{fill:#2B363B;}.st1{fill:#FFFFFF;}.st2{fill:none;stroke:#FFFFFF;stroke-miterlimit:10;}.st3{fill:none;stroke:#FFFFFF;stroke-width:1.0001;stroke-miterlimit:10;}.st4{fill:none;stroke:#FFFFFF;stroke-width:1.015;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st5{fill:#13868C;}.st6{fill:#0A969C;}.st7{fill:#147A7E;}.st8{fill:#0EA5AE;}.st9{fill:none;stroke:#FFFFFF;stroke-width:0.9937;stroke-miterlimit:10;}.st10{fill:none;stroke:#FFFFFF;stroke-width:0.9937;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st11{fill:none;stroke:#FFFFFF;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st12{fill:none;stroke:#FFFFFF;stroke-width:1.2797;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st13{fill:#101213;}.st14{fill:#323E44;}.st15{clip-path:url(#SVGID_2_);}.st16{opacity:0.4;}.st17{clip-path:url(#SVGID_4_);}.st18{fill:none;stroke:#0A969C;stroke-width:4;stroke-miterlimit:10;}.st19{clip-path:url(#SVGID_6_);}.st20{clip-path:url(#SVGID_8_);}.st21{fill:#07979D;}.st22{fill:none;stroke:#FFFFFF;stroke-width:1.0363;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st23{fill:none;stroke:#FFFFFF;stroke-width:1.2059;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}.st24{fill:#137A7F;}.st25{fill:#0DA5AE;}.st26{fill:#F5B82E;}.st27{fill:#ED6A3D;}.st28{fill:#E5771A;}.st29{fill:#F18522;}.st30{fill:#773E16;}.st31{fill:#E2761B;}.st32{fill:#C0AD9E;}.st33{fill:#CD6118;}.st34{fill:#E5751F;}.st35{fill:#253548;}.st36{fill:#D8C2B4;}.st37{fill:#161617;}.st38{fill:#5690CC;}.st39{fill:#4F201F;}.st40{fill:#AD1917;}.st41{fill:#9C145E;}.st42{fill:#6B9B2F;}.st43{fill:#2A3539;}.st44{fill:#2C383D;}.st45{fill:#31383B;}.st46{fill:#242F33;}.st47{fill:#191F23;}.st48{fill:#2F393E;}.st49{fill:#212A2F;}.st50{fill:#1C2428;}.st51{fill:#303A3E;}.st52{fill:none;}.st54{font-size:102.0473px;}.st55{font-size:43.1013px;}</style><g id="Livello_1"></g><g id="PFP"><path class="st43" d="M-8.1-10.02c340.69,0,701.39,0,1042.16,0c0,341.25,0,702.51,0,1044.08c-340.67,0-701.41,0-1042.16,0 c-1.61-1.97-0.93-4.31-0.93-6.48c-0.04-67.02-0.03-144.05-0.03-211.07c0-269.69,0-549.39,0.04-819.08 C-9.02-5.06-9.83-7.72-8.1-10.02z"/><path class="st44" d="M77.73,943.44c0.88,1.18,1.65,2.41,1.23,3.97c-0.4,1.48-1.49,2.42-2.68,3.26c-4.44,3.11-8.37,2.85-11.99-1.13 c-3.86-4.23-6.13-9.15-6.77-15.01c-1.04-9.58-0.91-19.15-0.91-28.74c-0.01-269.02,0-538.04-0.05-807.06 c0-6.42,0.7-12.77,1.26-19.13c0.7-7.93,4.48-14.33,10.89-18.96c4.21-3.04,9.16-4.5,14.36-4.9c1.75-0.14,3.52-0.09,5.28-0.09 c280.56,0,561.11,0,841.67,0c1.76,0,3.52-0.01,5.28,0.08c5.11,0.27,9.66,2.07,13.67,5.23c5.39,4.26,5.77,11.34,0.89,16.44 c-1.17,1.23-2.17,1.39-3.85,0.51c-0.56-0.29-1.02-0.77-1.53-1.16c-0.07-8.62-3.83-12.38-12.89-12.68 c-22.03-0.73-44.06-0.35-66.09-0.27c-38.79,0.14-77.59,0.13-116.38,0.14c-37.06,0.01-74.13-0.02-111.19-0.24 c-37.27-0.22-74.54-0.12-111.81-0.11c-51.12,0.01-102.24-0.15-153.36,0.01c-84.29,0.27-168.58,0-252.87,0.15 c-11.63,0.02-23.28-0.38-34.9-0.13c-9.56,0.21-17.15,5.88-19.05,16.03c-2.02,10.8-0.56,21.66-0.63,32.48 c-0.3,45.3-0.13,90.61-0.18,135.91c-0.03,29.03,0.13,58.08,0.18,87.12c0.05,27.36,0,54.73-0.06,82.1 c-0.04,18.89,0.01,37.79,0.08,56.69c0.09,25.23,0.08,50.46,0.08,75.69c0.01,23.2-0.05,46.41-0.1,69.61 c-0.04,19.9,0.1,39.81,0.02,59.71c-0.09,23.7-0.15,47.41-0.1,71.11c0.04,19.72,0.2,39.45,0.14,59.17 c-0.06,21.36,0.1,42.73-0.24,64.1c-0.29,18.05,0.54,36.11-0.29,54.17c-0.15,3.27,0.62,6.89,1.81,10.02 C68.51,942.42,72.74,943.91,77.73,943.44z"/> <path class="st45" d="M931.03,76.74c-3.84,0.01-7.68,0.03-11.52,0.03c-275.45,0-550.89,0-826.34,0.01c-2.72,0-5.45-0.07-8.15,0.1 c-4.9,0.31-6.88,2.29-7.19,7.19c-0.17,2.71-0.1,5.44-0.1,8.15c0,266.95,0,533.89,0,800.84c0,11.36-0.02,22.71-0.03,34.07 c-3.74,2.03-6.22,0.33-6.48-4.84c-0.54-10.51-0.2-21.03-0.22-31.55c-0.06-30.23-0.13-60.46-0.05-90.68 c0.07-30.36,0.08-60.72,0.1-91.08c0.02-33.81,0.08-67.62-0.03-101.43c-0.1-30.2,0.03-60.39-0.13-90.59 c-0.07-14.04,0.08-28.09,0.11-42.13c0.19-118.66-0.27-237.32,0.16-355.97c0.04-10.28-0.1-20.58-1.27-30.91 c-1.5-13.22,9.51-22.1,22.69-19.8c6.85,1.19,13.88,0.64,20.8,0.61c122.35-0.38,244.71-0.07,367.06-0.1 c46.76-0.01,93.53,0.15,140.29,0.13c49.37-0.02,98.74,0.06,148.12-0.17c38.73-0.18,77.45,0.07,116.18-0.11 c12.69-0.06,25.43-0.53,38.14,0.35c1.73,0.12,3.57,0.38,5.28,0.58C933.44,70,934.23,72.58,931.03,76.74z"/><path class="st46" d="M949.27,86.36c-0.07-2.68,0.99-4.56,3.58-5.62c2.77-1.14,5.23-0.99,7.65,0.87c1.85,1.42,3.2,3.1,3.72,5.4 c0.67,2.97,1.33,5.93,1.34,9c0.01,1.76,0.02,3.52,0.02,5.28c0,276.35,0,552.7,0.02,829.05c0,4.65-0.14,9.27-1.1,13.84 c-2.07,9.82-7.55,16.43-17.67,18.56c-4.85,1.02-9.78,1.58-14.74,1.8c-1.76,0.08-3.52,0.02-5.28,0.02c-273.65,0-547.3,0-820.95,0.01 c-4.65,0-9.25-0.27-13.86-0.87c-3.55-0.46-6.32-2.07-8.87-4.35c-2.04-1.82-2.38-4.02-1.61-6.55c0.75-2.48,1.9-4.43,4.85-4.5 c0.32-0.01,0.64-0.04,0.96-0.06c0.36,0.68,1.31,0.82,1.45,1.77c0.93,6.3,5.55,6.88,10.68,7.12c7.83,0.36,15.67,0.22,23.5,0.22 c261.07-0.03,522.14,0.09,783.21-0.05c7.23,0,14.47-0.23,21.68,0.02c5.09,0.17,10.02,1.48,15.25,0.05 c8.48-2.32,16.1-11.26,16.31-20.07c1.01-43.29,0.29-86.59,0.42-129.88c0.1-35.13,0.04-70.26-0.06-105.39 c-0.1-40.14-0.1-80.27-0.07-120.41c0.03-44.1,0.12-88.21,0.11-132.31c-0.03-108.85,0.24-217.71-0.13-326.56 c-0.03-8.36,0.84-16.74-0.57-25.06c-0.88-5.18-1.91-10.23-8.78-10.38C949.96,87.29,949.62,86.69,949.27,86.36z"/><path class="st47" d="M96.93,948.25c9.76,0,19.52-0.01,29.27-0.01c265.87,0,531.75,0,797.62,0c4,0,8-0.02,12-0.01 c2.41,0,4.77-0.34,7.15-0.74c3.48-0.58,5.4-2.61,5.9-6c0.25-1.73,0.36-3.5,0.37-5.25c0.05-5.44,0.03-10.88,0.03-16.32 c0-271.45,0-542.9,0-814.36c0-3.52,0.01-7.04,0.01-10.56c3.79-2.72,4.67-2.33,5.87,2.26c1.77,6.76,1.01,13.69,0.96,20.48 c-0.31,41.43-0.09,82.86-0.1,124.29c-0.01,79.42,0.02,158.84,0.02,238.27c0,45.31-0.25,90.62-0.13,135.92 c0.15,53.2,0.06,106.4,0.27,159.59c0.18,45.62-0.24,91.25,0.07,136.88c0.06,8.47-0.1,16.96,0.96,25.47 c1.1,8.85-5.39,17.58-15.64,17.48c-271.81-2.6-543.63-0.47-815.45-1.18c-7.73-0.02-15.45,0-23.18-0.06 c-1.56-0.01-3.02-0.3-4.38-0.63C95.27,952.97,94.94,951.45,96.93,948.25z"/><path class="st48" d="M77.73,943.44c-0.8,0.8-1.7,1.44-2.8,1.8c-3.03,0.97-5.2,0.36-7.24-2.16c-1.64-2.02-2.77-4.32-3.14-6.91 c-0.6-4.27-1.41-8.52-1.24-12.88c0.08-1.92,0.01-3.84,0.01-5.76c0-272.57,0-545.13-0.01-817.7c0-3.52-0.1-7.04-0.25-10.55 c-0.07-1.61,0.01-3.18,0.39-4.76c0.33-1.4,0.64-2.81,0.8-4.24c1.14-10.61,9.62-16.75,18.78-18.39c0.16-0.03,0.32-0.08,0.48-0.06 c4.46,0.61,8.94-0.2,13.38,0.15c3.68,0.29,7.34,0.38,11.02,0.38c271.63,0,543.26,0,814.89,0.01c2.72,0,5.44,0.02,8.16,0.02 c3.07,0,6.03,0.65,8.94,1.57c1.71,0.54,3.21,1.42,4.45,2.73c3.16,3.31,3.19,6.35,0.12,10.08c-0.96,0-1.92-0.01-2.88-0.01 c-1.59-3.14-1.93-7.04-5.99-8.62c-2.14-0.83-4.23-1.37-6.48-1.4c-4.16-0.06-8.32-0.04-12.47-0.04c-272.37,0-544.75,0-817.12,0.01 c-6.45,0-12.89-0.89-19.31,0.9c-5.29,1.48-8.77,4.32-9.98,9.8c-1.09,4.93-3.15,9.68-1.69,14.95c0.45,1.64,0.08,3.5,0.08,5.26 c0,274.43-0.01,548.86,0.09,823.3c0,4.23-1.97,8.42,0.24,12.8c1.48,2.93,2.63,5.46,6.46,5.28c0.94-0.04,1.64,0.91,2.32,1.59 C77.72,941.52,77.73,942.48,77.73,943.44z"/><path class="st45" d="M931.03,76.74c-0.08-0.8-0.1-1.6-0.24-2.38c-0.3-1.78-1.44-2.78-3.13-3.24c-2.17-0.59-4.37-0.98-6.62-1.02 c-2.56-0.04-5.12-0.05-7.68-0.05c-269.35,0-538.71,0-808.06-0.01c-4.95,0-9.9,0.07-14.84-0.65c-4.25-0.62-8.31,0.56-11.91,2.83 c-4.79,3.02-7.41,7.44-7.45,13.18c-0.01,1.75,0.13,3.54,0.52,5.23c1.16,5.03,1.32,10.12,1.32,15.25 c-0.02,268.85-0.02,537.7-0.01,806.56c0,2.88-0.04,5.77,0.23,8.63c0.27,2.84,1.33,5.31,4.54,6.05c0,3.2,0,6.4,0.01,9.6 c-3.99,3.28-5.98,2.69-8.16-1.93c-1.31-2.78-2.14-5.39-1.48-8.53c0.37-1.77,0.07-3.72,0.07-5.59 c-0.04-273.99-0.01-547.97,0.02-821.96c0-5.39-1.12-10.67-0.27-16.2c1.28-8.34,6.25-15.14,17.36-16.36 c4.16-0.45,8.33,0.03,12.5,0.03c275.28,0.05,550.56-0.03,825.84,0.05c4.86,0,9.83-0.55,13.99,3.09c3.33,2.92,3.49,4.32,0.17,7.41 C935.51,76.74,933.27,76.74,931.03,76.74z"/><path class="st49" d="M949.27,86.36c0.95-0.13,1.9-0.27,2.85-0.4c2.93-0.39,4.95,0.88,6.18,3.48c2.01,4.24,3.16,8.71,3.38,13.4 c0.08,1.76,0.06,3.52,0.06,5.28c0,271.75,0,543.51,0.04,815.26c0,5.63-0.72,11.17-1.32,16.72c-0.64,5.93-3.03,11.01-7.92,14.79 c-3.83,2.97-8.19,4.3-12.88,4.7c-2.37,0.2-4.82,0.18-7.17-0.16c-3.82-0.55-7.64-0.65-11.48-0.65c-271.61,0-543.23,0-814.84,0 c-2.72,0-5.44-0.01-8.16-0.05c-2.26-0.03-4.44-0.51-6.53-1.41c-2.93-1.27-4.66-3.31-4.3-6.7c0.09-0.79,0.09-1.6,0.13-2.39 c1.28,0,2.56,0,3.84,0c4.38,6.11,10.85,6.65,17.51,6.37c7.04-0.29,14.08-0.13,21.12-0.13c257.87-0.01,515.74-0.01,773.62-0.02 c11.5,0,22.99-0.02,34.48,0.72c3.88,0.25,7.95,0.5,11.67-1.7c6.09-3.59,7.43-9.61,7.26-15.66c-0.43-15.65-0.84-31.29-0.84-46.95 c0-256.25,0.04-512.5,0-768.76c0-5.95-0.08-11.9,0.15-17.85c0.23-5.81-0.97-11.14-6.85-14.07 C949.28,88.92,949.28,87.64,949.27,86.36z"/><path class="st50" d="M949.28,90.2c0.32-0.03,0.64-0.07,0.96-0.08c4.29-0.03,5.32,0.69,6.36,4.84c0.75,2.95,1.31,5.94,1.29,9 c-0.01,1.6,0.02,3.2,0.02,4.8c0,274.28,0,548.57,0.01,822.85c0,4.33-0.28,8.61-0.96,12.89c-0.97,6.15-6.52,10.88-11.94,11.47 c-4.95,0.54-9.82,1.23-14.78,0.2c-1.39-0.29-2.87-0.22-4.3-0.24c-2.24-0.04-4.48-0.02-6.72-0.02c-270.15,0-540.29,0-810.44,0 c-2.4,0-4.8,0.04-7.2-0.05c-1.43-0.05-2.89-0.17-4.28-0.47c-4.58-1.01-5.58-2.22-6.14-7.15c1.92,0,3.84,0,5.76,0 c0.38,2.59,2.08,3.88,4.49,4.32c1.41,0.25,2.85,0.39,4.29,0.43c2.4,0.07,4.8,0.04,7.2,0.04c268.75,0,537.5,0,806.25,0 c4.64,0,9.25,0.11,13.88,0.68c3.63,0.45,7.35,0.34,11.02,0.15c4.96-0.26,9.5-4.14,10.65-8.95c0.7-2.95,1.15-5.94,0.7-9.03 c-0.32-2.2-0.33-4.46-0.36-6.7c-0.06-4.96,0-9.9-0.73-14.84c-0.42-2.82-0.23-5.75-0.23-8.62c-0.01-161.56-0.01-323.12-0.01-484.67 c0-104.77,0-209.55,0-314.32c0-2.24,0.05-4.49-0.13-6.71c-0.27-3.35-0.9-3.93-4.65-5.01C949.28,93.4,949.28,91.8,949.28,90.2z"/> <path class="st51" d="M937.75,76.74c0.54-5.29-1.6-8.22-6.79-8.96c-2.68-0.38-5.42-0.46-8.13-0.59c-1.92-0.09-3.84-0.03-5.76-0.03 c-274.19,0-548.39,0-822.58,0c-2.72,0-5.45-0.08-8.15,0.14c-4.9,0.41-9.38,1.89-12.9,5.6c-2.52,2.65-4.16,5.69-4.44,9.34 c-0.33,4.29-1.01,8.55-0.16,12.9c0.42,2.17,0.24,4.46,0.24,6.7c0.01,20.31,0.01,40.63,0.01,60.94c0,252.26,0,504.51,0,756.77 c0,2.4,0.01,4.8,0.04,7.2c0.03,1.93,0.36,3.81,0.99,5.65c0.86,2.51,2.41,4.11,5.19,4.23c0.8,0.03,1.6,0.06,2.4,0.08 c0,1.28,0,2.56,0.01,3.85c-3.43,1.04-6.53,0.49-8.42-2.68c-1.79-3.01-3.24-6.33-2.67-10.01c0.61-3.98,0.54-7.97,0.54-11.97 c0-271.59,0-543.18,0-814.77c0-4-0.18-7.97-0.55-11.97c-0.51-5.51,0.84-10.83,3.33-15.75c1.73-3.44,4.72-5.66,8.39-6.74 c4.93-1.45,9.94-2.37,15.14-1.71c1.58,0.2,3.19,0.23,4.79,0.27c2.08,0.04,4.16,0.02,6.24,0.02c272.57,0,545.14,0,817.72,0 c2.4,0,4.8,0.04,7.2,0.03c2.79-0.01,5.35,0.8,7.78,2.12c4.4,2.39,5.22,4.09,4.4,9.36C940.31,76.75,939.03,76.75,937.75,76.74z"/><polygon id="HEAD" class="st8" points="587.18,381.78 436.82,381.78 361.64,512 436.82,642.22 587.18,642.22 662.36,512"/><path id="BODY" class="st21" d="M693.72,947.64H330.28v-258c0-2.12,1.72-3.84,3.84-3.84h355.78c2.12,0,3.84,1.72,3.84,3.84V947.64z"/><rect x="107.11" y="109.67" class="st52" width="809.78" height="213.33"/><text transform="matrix(1 0 0 1 397.8102 194.366)" class="st1 st53 st54">';
        parts[1] = getName(tokenId);
        parts[2] = '</text><path id="IDBOX" class="st14" d="M906.31,914.64H665.54c-4.6,0-8.33-3.73-8.33-8.33v-70.42c0-4.6,3.73-8.33,8.33-8.33h240.77 c4.6,0,8.33,3.73,8.33,8.33v70.42C914.64,910.91,910.91,914.64,906.31,914.64z"/><text transform="matrix(1 0 0 1 686.4938 884.7258)" class="st1 st53 st55">';
        parts[3] = getID(tokenId);
        parts[4] = '</text><text transform="matrix(1 0 0 1 766.5963 810.6659)" class="st1 st53 st55">ID</text><path id="AGEBOX" class="st14" d="M358.46,914.64H117.69c-4.6,0-8.33-3.73-8.33-8.33v-70.42c0-4.6,3.73-8.33,8.33-8.33h240.77 c4.6,0,8.33,3.73,8.33,8.33v70.42C366.79,910.91,363.06,914.64,358.46,914.64z"/><text transform="matrix(1 0 0 1 185.3634 884.7258)" class="st1 st53 st55">';
        parts[5] = getAge(tokenId);
        parts[6] = '</text><text transform="matrix(1 0 0 1 198.3146 810.6659)" class="st1 st53 st55">AGE</text><path id="SVGID_x5F_2_x5F_" class="st52" d="M48.56,42.67h926.89c3.25,0,5.89,2.64,5.89,5.89v926.89c0,3.25-2.64,5.89-5.89,5.89 H48.56c-3.25,0-5.89-2.64-5.89-5.89V48.56C42.67,45.31,45.3,42.67,48.56,42.67z"/><text> <textPath xlink:href="#SVGID_x5F_2_x5F_" startOffset="-100%"><tspan class="st1" style="font-size:28.3465px;">';
        parts[7] = getMsgSender();
        parts[8] = getMotto(tokenId);
        parts[9] = '</tspan><animate additive="sum"attributeName="startOffset"from="0%" to ="100%"begin="0s" dur="30s"repeatCount="indefinite"/></textPath><textPath  xlink:href="#SVGID_x5F_2_x5F_" startOffset="0%"><tspan  class="st1" style="font-size:28.3465px;">';
        parts[10] = getMsgSender();
        parts[11] = " - ";
        parts[12] = getMotto(tokenId);
        parts[13] = '</tspan><animate additive="sum"attributeName="startOffset"from="0%" to ="100%"begin="0s" dur="30s"repeatCount="indefinite"/></textPath></text></g></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Cipher ', toString(tokenId), '", "description": "Test description", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId, string calldata name, string calldata motto) public nonReentrant {
        require(tokenId > 0 && tokenId < 7778, "Token ID invalid");
        totalUsers++;
        
        User memory user;
        user.nickname = name;
        user.age = block.timestamp;
        user.id = totalUsers;
        user.motto = motto;
        
        _users[tokenId] = user;
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

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    constructor() ERC721("CipherDuo Identities", "C2ID") Ownable() {}
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