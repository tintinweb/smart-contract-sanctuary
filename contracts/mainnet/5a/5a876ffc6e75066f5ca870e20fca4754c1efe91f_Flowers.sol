//SPDX-License-Identifier: Unlicense
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


contract Flowers is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 4096;
    uint256 public price = 0.025 ether;
    uint256 public maxMint = 24;
    uint256 public numTokensMinted;
    uint256 public maxPerAddress = 24;

    bool public allSalesPaused = true;
    bool public privateSaleIsActive = true;

    mapping(address => uint256) private _mintPerAddress;
    mapping(address => bool)    private _whiteList;
    mapping(address => uint256) private _whiteListPurchases;
    mapping(address => uint256) private _whiteListLimit;

    string[7] private mutationNames = ['None','Sketched','Skewed','Glitched','Long Boi','Heart','Infected'];
    string[3] private otherBG = ['<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence baseFrequency="0.08 0.08" numOctaves="2"></feTurbulence><feColorMatrix values="0 0 0 9 -6 0 0 0 9 -6 0 0 0 9 -6 0 0 0 0 0.7" /></filter>', '<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence type="fractalNoise" baseFrequency="0.015"/><feComponentTransfer><feFuncA type="discrete" tableValues="0 1 0"/></feComponentTransfer><feColorMatrix values="0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 0 1"/></filter>', '<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence type="turbulence" baseFrequency="0.0072 0.0068" result="turbulence"></feTurbulence></filter>'];
    string[4] private specialBG = ['<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence baseFrequency="0.007 0.006" numOctaves="2"></feTurbulence> <feColorMatrix values="0.500 0.938 0.819 0.151 0.849 0.377 0.158 0.241 0.969 0.758 0.629 0.374 0.669 0.507 0.733 0.468 0.496 0.095 0.688 0.616"></feColorMatrix> <feComponentTransfer><feFuncR type="table" tableValues="0.185 0.417 0.481 0.038 0.117 0.768 0.778 0.227 0.539 0.674 0.197 0.973"></feFuncR><feFuncG type="table" tableValues="0.348 0.414 0.663 0.634 0.013 0.741 0.629 0.205 0.068 0.214 0.779 0.964"></feFuncG><feFuncB type="table" tableValues="0.199 0.695 0.001 .799 0.692 0.160 .734 0.691 0.914"></feFuncB> </feComponentTransfer></filter>', '<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence baseFrequency="0.008 0.004" numOctaves="2"></feTurbulence> <feColorMatrix values="0.891 0.693 0.011 0.457 0.800 0.605 0.790 0.737 0.417 0.851 0.278 0.432 0.818 0.307 0.244 0.821 0.984 0.177 0.165 0.742"></feColorMatrix> <feComponentTransfer><feFuncR type="table" tableValues="0.674 0.800 0.314 0.317 0.845 0.725 0.075 0.718 0.164 0.775 0.078 0.037"></feFuncR><feFuncG type="table" tableValues="0.527 0.459 0.881 0.058 0.391 0.390 0.927 0.270 0.224 0.547 0.286 0.057"></feFuncG><feFuncB type="table" tableValues="0.410 0.422 0.129 .664 0.606 0.180 .422 0.084 0.254"></feFuncB> </feComponentTransfer></filter>', '<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence baseFrequency="0.008 0.007" numOctaves="2"></feTurbulence> <feColorMatrix values="0.221 0.952 0.028 0.563 0.120 0.180 0.749 0.580 0.211 0.788 0.019 0.341 0.948 0.998 0.809 0.685 0.033 0.538 0.659 0.382"></feColorMatrix> <feComponentTransfer><feFuncR type="table" tableValues="0.365 0.893 0.803 0.017 0.472 0.083 0.473 0.487 0.233 0.899 0.776 0.277"></feFuncR><feFuncG type="table" tableValues="0.851 0.584 0.043 0.912 0.632 0.695 0.651 0.563 0.776 0.394 0.040 0.102"></feFuncG><feFuncB type="table" tableValues="0.045 0.045 0.709 .937 0.594 0.058 .324 0.683 0.446"></feFuncB> </feComponentTransfer></filter>', '<filter x="0" y="0" width="100%" height="100%" id="filterBG"><feTurbulence baseFrequency="0.008 0.001" numOctaves="2"></feTurbulence> <feColorMatrix values="0.168 0.293 0.853 0.009 0.321 0.929 0.744 0.029 0.581 0.486 0.517 0.799 0.821 0.744 0.072 0.513 0.868 0.488 0.273 0.689"></feColorMatrix> <feComponentTransfer><feFuncR type="table" tableValues="0.058 0.419 0.155 0.252 0.550 0.650 0.926 0.937 0.480 0.326 0.298 0.371"></feFuncR><feFuncG type="table" tableValues="0.632 0.767 0.437 0.239 0.059 0.231 0.901 0.116 0.049 0.079 0.227 0.617"></feFuncG><feFuncB type="table" tableValues="0.201 0.589 0.299 .710 0.192 0.384 .052 0.100 0.898"></feFuncB> </feComponentTransfer></filter>'];
    string[9] private bgNames = ['Normal', 'Radial', 'Night Sky', 'Dalmatian', 'Trippy', 'Light Trip', 'Dark Trip', 'Blingy','Rainbow'];
    string[17] private petalNames = ["Lotus","Apricot","Daisy","Plumeria","Gardenias","Aster","Chamomile","Bellflower","Dahlia","Magnolia","Jasmine","Hibiscus","Tulip","Bird of Paradise","Aquilegia","Ethereum","Digital"];
    string[40] private allColors = ["#EAFB00","#F0CF61","#FFFFFF","#0E38B1","#EF3E4A","#FEDAC2","#B0D8DC","#B6CAC0","#C02A1B","#1FC8A9","#C886A2","#F9BDBD","#FEDCCC","#EBB9D4","#F2CB6C","#FF8FA4","#343B3F","#FF89B5","#D1BDFF","#9A008A","#7B76A6","#FB5408","#0B64FE","#FAAD58","#FF8B8B","#F2F2F2","#FFD3C2","#FDB90B","#FCA59B","#CDCDD0","#EEE9DC","#CDB670","#B3E0E0","#5C457B","#FDFF50","#FFCC4C","#19AAD1","#7A30CF","#189BA3","#EF303B"];
    string[40] private allColorNames = ["Laser Lemon","Arylide Yellow","White","Egyptian Blue","Carmine Pink","Peach Puff","Pale Aqua","Powder Ash","Thunderbird","Topaz","Lipstick Pink","Tea Rose","Peach Schnapps","Pink Flare","Sand","Pink Sherbet","Tuna","Rosa","Melrose","Dark Magenta","Greyish Purple","International Orange","Bright Blue","Pale Orange","Geraldine","Porcelain","Light Aprico","Golden","Sweet Pink","Grey Goose","Eggshell","Tan","Powder Blue","Purple Haze","Canary Yellow","Bright Sun","Bright Cerulean","Blue Violet","Eastern Blue","Deep Carmine Pink"];
    string[17] private petalStarts = ["<path","<path","<path","<path","<path","<path","<path","<path","<path","<ellipse","<path","<path","<path","<path","<path","<path","<path"];
    string[17] private petalEnds = [' d="M249.5 239.145C256.528 233.275 261 224.446 261 214.572C261 204.699 256.528 195.87 249.5 190C242.472 195.87 238 204.699 238 214.572C238 224.446 242.472 233.275 249.5 239.145Z"', ' d="M280 208.165C280 192.024 254.983 188.894 250 172.528C245.017 188.894 220 192.024 220 208.165C220 227.404 230.909 243 250 243C269.091 243 280 227.404 280 208.165Z"', ' d="M233.947 227.947C226.185 220.185 228.406 206.96 236.932 200.045C243.993 194.318 250.366 187.12 250.483 179.738C250.652 169.036 263.675 185.159 272.962 198.051C278.483 205.715 277.36 216.168 270.682 222.847L249.764 243.764L233.947 227.947Z"', ' d="M276 206C266 242 250 242 250 242C250 242 234 242 224 206C217 180 250 166 250 166C250 166 283 180 276 206Z"', ' d="M250 184.5L275 212L274.04 221.028C273.07 230.142 267.879 238.272 260.02 242.988C253.853 246.688 246.147 246.688 239.98 242.988C232.121 238.272 226.93 230.142 225.96 221.028L225 212L250 184.5Z"', ' d="M236.62 178.986C236.282 171.364 242.37 165 250 165V165C257.63 165 263.718 171.364 263.38 178.986L260.923 234.443C260.687 239.788 256.284 244 250.933 244H249.067C243.716 244 239.313 239.788 239.077 234.443L236.62 178.986Z"', ' d="M230.024 171.998C230.386 160.997 241.042 175 250.012 175C258.983 175 270 160.997 270 171.998C270 183 262.546 238.751 262.546 238.751C262.395 241.669 256.828 244 250.012 244C243.196 244 237.629 241.669 237.478 238.751C237.478 238.751 229.663 183 230.024 171.998Z"', ' d="M271.934 211.182L250 248L228.066 211.182C224.326 204.904 224.308 197.085 228.019 190.79L244.831 162.269C247.152 158.331 252.848 158.331 255.169 162.269L271.981 190.79C275.692 197.085 275.674 204.904 271.934 211.182Z"', ' d="M218.621 207.242C214.047 198.095 218.542 182.01 228.195 173.632C240.814 162.679 259.185 162.679 271.805 173.632C281.457 182.01 285.952 198.095 281.379 207.242L256 240H244L218.621 207.242Z"', ' cx="250" cy="217" rx="25" ry="27"', ' d="M266 218C266 235.673 258.837 240 250 240C241.163 240 234 235.673 234 218C234 200.327 244.5 186 250 186C255.5 186 266 200.327 266 218Z"', ' d="M225.334 172.528C230.007 166.558 241.793 179.939 245.982 186.259C249.313 191.282 250.687 191.282 254.018 186.259C258.207 179.939 269.993 166.558 274.666 172.528C279.648 178.895 280 198.024 280 208.165C280 227.404 272.091 243 250 243C227.909 243 220 227.404 220 208.165C220 198.024 220.352 178.895 225.334 172.528Z"', ' d="M231.839 187.485C229.349 175.917 238.166 165 250 165V165C261.834 165 270.651 175.917 268.161 187.485L257.262 238.134C256.526 241.556 253.5 244 250 244V244C246.5 244 243.474 241.556 242.738 238.134L231.839 187.485Z"', ' d="M249.034 244C266.462 244 271.8 222.029 262.445 213.353C253.09 204.677 229.575 182 229.575 182C225.644 187.601 223 204.43 223 213.353C223 230.279 231.606 244 249.034 244Z"', ' d="M244.62 172.506C244.916 171.126 247.095 170 249.718 170V170C252.342 170 254.522 171.126 254.827 172.504C255.608 176.045 258.097 183.109 266.015 192.22C273.86 201.247 276.961 211.518 270.545 220.856L257.391 240H242.776L229.459 220.619C223.135 211.414 226.047 201.287 233.63 192.353C241.416 183.179 243.856 176.063 244.62 172.506Z"', ' d="M275 201L250 248L225 201L250 153.5L275 201Z"', ' d="M270.505 223.547L264.848 229.204L264.848 229.205L264.848 229.205L249.999 244.054L235.149 229.205L235.149 229.205C226.948 221.004 226.948 207.707 235.149 199.506L235.149 199.506L240.806 193.85L240.806 193.849L255.655 179L270.368 193.714C270.414 193.759 270.459 193.804 270.505 193.849C278.706 202.05 278.706 215.346 270.505 223.547Z"'];
    uint256[17] private minPetals = [ 8, 4, 5, 4, 5, 8, 5, 6, 6, 4, 8, 4, 8, 4,10, 6, 5];
    uint256[17] private maxPetals = [15, 8, 8,10,10,12,10,12,12, 8,20, 7,16,10,18,12,10];
    string[3] private petalAnimation = ['<animateTransform attributeName="transform" begin="0s" dur="8s" type="rotate" from="', ' 250 250" to="', ' 250 250" repeatCount="indefinite"/>'];

    struct OCCFlower {
        uint256 petalStyle;
        uint256 numPetals;
        uint256 petalColor;
        uint256 coreColor;
        uint256 coreSize;
        uint256 backgroundColor;
        uint256 overlayColor;
        uint256 mutationType;
        uint256 backgroundType;
        bool isAnimated;
    }

    function randomFlower(uint256 tokenId) internal view returns (OCCFlower memory) {
        OCCFlower memory flower;

        flower.petalStyle = getPetalStyle(tokenId);
        flower.numPetals = pluckNum(tokenId,string(abi.encodePacked('NOP', toString(flower.petalStyle))), minPetals[flower.petalStyle], maxPetals[flower.petalStyle]);
        flower.petalColor = getAColorID(tokenId, "PEC");
        flower.coreColor = getAColorID(tokenId, "COC");
        flower.coreSize = getCoreSize(tokenId);
        flower.backgroundColor = getAColorID(tokenId, "BGC");
        flower.overlayColor = getAColorID(tokenId, "OVC");
        flower.mutationType = getMutation(tokenId);
        flower.backgroundType = getBackgroundType(tokenId);
        flower.isAnimated = isFlowerAnimated(tokenId);

        return flower;
    }
    
    function getTraits(OCCFlower memory flower) internal view returns (string memory) {
        string[20] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Petal Style","value": "';
        parts[1] = petalNames[flower.petalStyle];
        parts[2] = '"}, {"trait_type": "Petal Color","value": "';
        parts[3] = allColorNames[flower.petalColor];
        parts[4] = '"}, {"trait_type": "Core Color","value": "';
        parts[5] = allColorNames[flower.coreColor];
        parts[4] = '"}, {"trait_type": "Core Size","value": ';
        parts[5] = toString(flower.coreSize);
        parts[6] = '}, {"trait_type": "No. of Petals","value": ';
        parts[7] = toString(flower.numPetals);
        if (flower.backgroundType == 0 || flower.backgroundType == 1) {
            parts[8] = '}, {"trait_type": "BG Color","value": "';
            parts[9] = allColorNames[flower.backgroundColor];
            parts[10] = '"';
        }
        parts[11] = '}, {"trait_type": "BG Overlay","value": "';
        parts[12] = allColorNames[flower.overlayColor];
        parts[13] = '"}, {"trait_type": "Mutation","value": "';
        parts[14] = mutationNames[flower.mutationType];
        parts[15] = '"}, {"trait_type": "Spin","value": "';
        parts[16] = (flower.isAnimated? 'True' : 'False' );
        parts[17] = '"}, {"trait_type": "BG Type","value": "';
        parts[18] = bgNames[flower.backgroundType];
        parts[19] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
                      output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15]));
                      output = string(abi.encodePacked(output, parts[16], parts[17], parts[18], parts[19]));
        return output;
    }

    /* UTILITY FUNCTIONS FOR PICKING RANDOM TRAITS */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function pluck(uint256 tokenId, string memory keyPrefix, string[39] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId),_msgSender())));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }
    
    function pluckNum(uint256 tokenId, string memory keyPrefix, uint256 minNum, uint256 maxNum) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId), minNum, maxNum,_msgSender())));
        uint256 num = rand % (maxNum - minNum + 1) + minNum;
        return num;
    }
    
    function getAColorID(uint256 tokenId, string memory seed) internal view returns (uint256) {
        return pluckNum(tokenId, seed, 0, 38);
    }
    
    function getCoreSize(uint256 tokenId) internal view returns (uint256) {
        return pluckNum(tokenId, "CORE SIZE", 16, 30);
    }

    function getPetalStyle(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("PETAL STYLE", toString(tokenId))));

        uint256 gt = rand % 125;
        uint256 ps = 0;

        if (gt >= 10 && gt < 20) { ps = 1; }
        if (gt >= 20 && gt < 30) { ps = 2; }
        if (gt >= 30 && gt < 40) { ps = 3; }
        if (gt >= 40 && gt < 50) { ps = 4; }
        if (gt >= 50 && gt < 60) { ps = 5; }
        if (gt >= 60 && gt < 70) { ps = 6; }
        if (gt >= 70 && gt < 80) { ps = 7; }
        if (gt >= 80 && gt < 89) { ps = 8; }
        if (gt >= 89 && gt < 97) { ps = 9; }
        if (gt >= 97 && gt < 104) { ps = 10; }
        if (gt >= 104 && gt < 110) { ps = 11; }
        if (gt >= 110 && gt < 115) { ps = 12; }
        if (gt >= 115 && gt < 119) { ps = 13; }
        if (gt >= 119 && gt < 122) { ps = 14; }
        if (gt >= 122 && gt < 124) { ps = 15; }
        if (gt >= 124) { ps = 16; }

        return ps;
    }

    function isFlowerAnimated(uint256 tokenId) internal pure returns (bool) {
        uint256 rand = random(string(abi.encodePacked("FLOWER ANIMATED", toString(tokenId))));
        uint256 gt = rand % 201;

        return (gt > 180);
    }
    
    function getBackgroundType(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BACKGROUND TYPE", toString(tokenId))));
        uint256 gt = rand % 1001;
        uint256 backgroundType = 0;

        if (gt > 900 && gt <= 954) { backgroundType = 1; }
        if (gt > 954 && gt <= 975) { backgroundType = 2; }
        if (gt > 974 && gt <= 990) { backgroundType = 3; }
        if (gt > 990 && gt <= 997) { backgroundType = 4; }

        if (gt == 997) { backgroundType = 5; }
        if (gt == 998) { backgroundType = 6; }
        if (gt == 999) { backgroundType = 7; }
        if (gt == 1000) { backgroundType = 8; }

        return backgroundType;
    }
    
    function getMutation(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("MUTATION", toString(tokenId))));
        uint256 gt = rand % 201;
        uint256 mutation = 0;

        if (gt > 100 && gt <= 134) { mutation = 1; }
        if (gt > 134 && gt <= 159) { mutation = 2; }
        if (gt > 159 && gt <= 174) { mutation = 3; }
        if (gt > 174 && gt <= 191) { mutation = 4; }
        if (gt > 191 && gt <= 197) { mutation = 5; }
        if (gt > 197) { mutation = 6; }

        return mutation;
    }
    
    /* SVG BUILDING FUNCTIONS */
    function getRadialBackground(uint256 tokenId) internal view returns (string memory) {
        string memory output = string(abi.encodePacked('<defs><radialGradient id="radialBG" cx="0.8" cy="0.8" r="0.6" fx="0.42" fy="0.42" spreadMethod="pad"><stop offset="0%" stop-color="',allColors[getAColorID(tokenId, "R1")],'"/><stop offset="40%" stop-color="',allColors[getAColorID(tokenId, "R2")],'"/><stop offset="70%" stop-color="',allColors[getAColorID(tokenId, "R3")],'"/><stop offset="90%" stop-color="',allColors[getAColorID(tokenId, "R4")],'"/><stop offset="94%" stop-color="'));
        output = string(abi.encodePacked(output, allColors[getAColorID(tokenId, "R5")],'"/><stop offset="96%" stop-color="',allColors[getAColorID(tokenId, "R6")],'"/><stop offset="100%" stop-color="',allColors[getAColorID(tokenId, "BGC")],'"/></radialGradient></defs>'));
        return output;
    }

    function getFlowerBG(OCCFlower memory flower, uint256 tokenId) internal view returns (string memory) {
        string memory output;

        if (flower.backgroundType == 0) {
            output = string(abi.encodePacked('<rect width="500" height="500" fill="', allColors[flower.backgroundColor], '" />'));
        }
        if (flower.backgroundType == 1) {
            output = string(abi.encodePacked(getRadialBackground(tokenId),'<rect width="500" height="500" fill="url(#radialBG)"/>'));
        }
        if (flower.backgroundType > 1 && flower.backgroundType < 5) {
            output = string(abi.encodePacked(otherBG[(flower.backgroundType - 2)],'<rect width="500" height="500" filter="url(#filterBG)"/>'));
        }
        if (flower.backgroundType >= 5) {
            output = string(abi.encodePacked(specialBG[(flower.backgroundType - 5)],'<rect width="500" height="500" filter="url(#filterBG)"/>'));
        }
        
        return output;
    }
    
    function getPetalSVG(OCCFlower memory flower) internal view returns (string memory) {
        string memory petalStart = petalStarts[flower.petalStyle];
        string memory petalEnd = petalEnds[flower.petalStyle];
        uint256 angleGap = 360000 / flower.numPetals;
        string memory petalInsert = '';
        
        petalInsert = string(abi.encodePacked('<defs>',petalStart,' id="ps-', toString(flower.petalStyle),'" ',petalEnd,'/><mask id="fpc"><rect height="100%" width="100%" fill="white" /><use transform = "rotate(',toString((angleGap)/1000)));
        petalInsert = string(abi.encodePacked(petalInsert,'.', toString((angleGap)%1000), ' 250 250)" xlink:href="#ps-',toString(flower.petalStyle),'" fill="black"/></mask></defs>'));
        
        if(flower.isAnimated) {
            for (uint256 i=0; i<flower.numPetals; i++) {
                petalInsert = string(abi.encodePacked(petalInsert, '<use transform="rotate(',toString((angleGap*i)/1000),'.', toString((angleGap*i)%1000), ' 250 250)" xlink:href="#ps-', toString(flower.petalStyle), '" mask="url(#fpc)" fill="', allColors[flower.petalColor], '">'));
                petalInsert = string(abi.encodePacked(petalInsert, petalAnimation[0],toString((angleGap*i)/1000),'.', toString((angleGap*i)%1000),petalAnimation[1],toString(((angleGap*i)/1000)+360),'.', toString((angleGap*i)%1000),petalAnimation[2], '</use>'));
            }
        } else {
            for (uint256 i=0; i<flower.numPetals; i++) {
                petalInsert = string(abi.encodePacked(petalInsert, '<use transform="rotate(',toString((angleGap*i)/1000),'.', toString((angleGap*i)%1000), ' 250 250)" xlink:href="#ps-', toString(flower.petalStyle)));
                petalInsert = string(abi.encodePacked(petalInsert, '" mask="url(#fpc)" fill="', allColors[flower.petalColor], '"/>'));
            }
        }
        
        return petalInsert;
    }
    
    function getMutationSVG(OCCFlower memory flower, uint256 tokenId) internal view returns (string memory) {
        string memory feTurbulance;
        string memory feDisplacementMap;
        string memory xOffset = '0';
        string memory yOffset = '0';

        if (flower.mutationType == 0) {
            return '<defs><filter xmlns="http://www.w3.org/2000/svg" id="Gl" x="-50%" y="-50%" width="200%" height="200%"><feDropShadow dx="8" dy="8" flood-color="#000000" flood-opacity="1" stdDeviation="0"/></filter></defs>';
        } 
        if (flower.mutationType == 1) {
            feTurbulance = string(abi.encodePacked('0.0', toString(pluckNum(tokenId, "HAND DRAWN", 3, 5))));
            feDisplacementMap = toString(pluckNum(tokenId, "HAND DRAWN", 4, 8));
            xOffset = '-10';
            yOffset = '-5';
        } 
        if (flower.mutationType == 2) {
            feTurbulance = '0.002';
            feDisplacementMap = toString(pluckNum(tokenId, "SKEW", 100, 200));
            xOffset = '-30';
            yOffset = '-10';
        } 
        if (flower.mutationType == 3) {
            feTurbulance = string(abi.encodePacked('0.',toString(pluckNum(tokenId, "GLITCHED", 3, 5))));
            feDisplacementMap = toString(pluckNum(tokenId, "GLITCHED", 20, 30));
            xOffset = '-12';
            yOffset = '-5';
        } 
        if (flower.mutationType == 4) {
            feTurbulance = string(abi.encodePacked('0.00',toString(pluckNum(tokenId, "LONGBOI", 17, 22))));
            feDisplacementMap = string(abi.encodePacked('-',toString(pluckNum(tokenId, "LONGBOI", 110, 120))));
            xOffset = '30';
            yOffset = '35';
        } 
        if (flower.mutationType == 5) {
            feTurbulance = '0.00475 0.00155';
            feDisplacementMap = '113';
            xOffset = '-40';
            yOffset = '-45';
        } 
        if (flower.mutationType == 6) {
            feTurbulance = string(abi.encodePacked('0.0',toString(pluckNum(tokenId, "INFECTED", 7, 9))));
            feDisplacementMap = toString(pluckNum(tokenId, "INFECTED", 60, 90));
            xOffset = '-30';
            yOffset = '-25';
        }

        string memory output = string(abi.encodePacked('<defs><filter id="Gl" x="-50%" y="-50%" width="200%" height="200%"><feTurbulence baseFrequency="',feTurbulance,'"/><feDisplacementMap in="SourceGraphic" scale="',feDisplacementMap,'"/><feOffset dy="',yOffset,'" dx="',xOffset,'"/><feDropShadow dx="8" dy="8" flood-color="#000000" flood-opacity="1" stdDeviation="0"/></filter></defs>'));
        return output;
    }

    function getFlowerSVG(OCCFlower memory flower, uint256 tokenId) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = '<svg viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
        parts[1] = getFlowerBG(flower, tokenId);
        parts[4] = '<rect id="rect" style="mix-blend-mode:overlay" opacity=".2" width="100%" height="100%" fill="';
        parts[5] = allColors[flower.overlayColor];
        parts[6] = '"/>';
        parts[7] = getMutationSVG(flower, tokenId);
        parts[8] = '<g filter="url(#Gl)" stroke="#000000" stroke-width="4">';
        parts[9] = getPetalSVG(flower);
        parts[10] = '<circle cx="250" cy="250" r="';
        parts[11] = toString(flower.coreSize);
        parts[12] = '" fill="';
        parts[13] = allColors[flower.coreColor];
        parts[14] = '"/></g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        OCCFlower memory flower = randomFlower(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Flower #', toString(tokenId), '", "description": "Flowers are fully on-chain, randomly generated unique flowers. For you, or a special someone in your life."', getTraits(flower), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getFlowerSVG(flower,tokenId))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function addToWhitelist(uint256 _claimAmount, address[] calldata entries) onlyOwner external {
        for(uint i=0; i<entries.length; i++){
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!_whiteList[entry], "DUPLICATE_ENTRY");
            _whiteList[entry] = true;
            _whiteListLimit[entry] = _claimAmount;
        }
    }

    function removeFromWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            _whiteList[entry] = false;
        }
    }

    function whitelistInfoFor(address _addr) public view returns (bool isWhiteListed, uint256 numHasMinted, uint256 allottedMints) {
        isWhiteListed = _whiteList[_addr];
        numHasMinted = _whiteListPurchases[_addr];
        allottedMints = _whiteListLimit[_addr];
    }

    function mintedInfoFor(address _addr) public view returns (uint256 numHasMinted) {
        numHasMinted = _mintPerAddress[_addr];
    }

    function mint(address destination, uint256 amountOfTokens) private {
        require(!allSalesPaused, "Sale is paused right now");
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(_mintPerAddress[msg.sender] + amountOfTokens <= maxPerAddress,  "You can't exceed this wallet's minting limit");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

        if (privateSaleIsActive) {
            require(_whiteList[msg.sender], "Buyer not whitelisted for this private sale");
            require(_whiteListPurchases[msg.sender] + amountOfTokens <= _whiteListLimit[msg.sender], "Cannot exceed allotted presale mint count");
            _whiteListPurchases[msg.sender] = _whiteListPurchases[msg.sender] + amountOfTokens;
        }

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
            _mintPerAddress[msg.sender] += 1;
        }
    }
    
    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
        mint(walletAddress,amountOfTokens);
    }

    function toggleAllSalesPaused() public onlyOwner {
        allSalesPaused = !allSalesPaused;
    }

    function enablePublicSale() public onlyOwner {
        privateSaleIsActive = false;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxPerAddress(uint256 newMaxPerAddress) public onlyOwner {
        maxPerAddress = newMaxPerAddress;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        maxMint = newMaxMint;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
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
    
    constructor() ERC721("Flowers", "FLWRS") Ownable() {}
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

