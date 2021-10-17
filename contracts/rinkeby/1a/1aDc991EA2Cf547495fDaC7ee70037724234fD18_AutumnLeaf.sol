// File: contracts/AutumnLeaf.sol

pragma solidity ^0.8.7;
//SPDX-License-Identifier: Unlicense


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

contract AutumnLeaf is ERC721Enumerable, Ownable, ReentrancyGuard{
    
    uint256 public max_supply = 4000;
    uint256 public price = 0.025 ether;
    uint256 public max_per_address = 20;
    uint256 public minted;
    uint256 public maxMint = 20;
    
    bool public sales_paused = false;
    
    mapping(address => uint256) private _mintperaddress;
    
    string[45] private colors=["#822A25","#9D373E","#E8544B","#D62B2A","#B62511","#755612","#C8712D","#A47147","#E4AE44","#AC2C04","#C37005","#FBCC04","#AA5C05","#E47204",
    "#F2A624","#5C6A08","#796F0D","#344006","#3F3C0B","#A49323","#DDBB4F","#F3612A","#F09A2D","#FF4444","#DC0605",
    "#FFFFFF","#B0D8DC","#B6CAC0","#1FC8A9","#F9BDBD","#FEDCCC","#EBB9D4","#F2CB6C","#343B3F","#D1BDFF","#FAAD58","#F2F2F2","#EAFB00","#EF303B","#0E38B1","#1FC8A9","#9A008A","#FDB90B","#FDFF50","#7A30CF"];
    
    string[45] private colornames=["berry","wine","blush","apple","scarlet","coffee","squash","peanut","mustard","brick","cider","honey","amber","orange","butterscotch","moss","pickle","seaweed","pine","olive","fawn","tangerine","apricot",
    "rose","crimson","white","paleaqua","powder ash","topaz","tea rose","peach schnapps","pink flare","sand","tuna","melrose","pale orange","porcelain","laser lemon","deep carmine pink","egyptian blue","thunderbird",
    "dark magenta","golden","canary yellow","blue violet"];
    string[8] private pathstart=['<path d="M247.25 304.184C189.62 333.034 100 304.184 100 304.184C100 304.184 130.527 252.693 161.139 251.837C138.249 239.845 125.913 172.759 111.049 168.425C110.781 168.369 110.541 168.316 110.333 168.265C110.573 168.302 110.811 168.355 111.049 168.425C121.972 170.672 181.713 176.392 189.555 176.531C203.358 125.567 237.459 124.101 247.25 70C286.067 135.745 311.078 142.805 306.666 176.531C334.497 171.171 392.572 172.44 397.083 170.102C402.472 174.858 373.199 245.799 341.972 251.837C373.255 262.717 403.528 301.023 399.666 306.02C398.859 313.203 314.632 331.141 247.25 304.184Z" fill="',
    '<path d="M250.541 85.4339L250.541 84.4339C305.364 61.086 515.463 330.002 250.541 371.439C-14.8402 315.696 194.019 65.6193 250.541 85.4339Z" fill="',
    '<path d="M252.552 330.605C207.62 320.478 184.108 311.18 150.729 276.157C155.992 267.583 158.433 265.214 162.519 262.278C128.938 251.594 140.355 235.761 110 195.018C136.267 202.3 151.733 207.721 171.094 202.491C169.621 190.276 170.451 182.629 171.094 169.395L183.956 174.733C188.92 164.023 192.054 158.536 197.889 149.11H206.464C208.161 141.038 210.272 136.595 216.11 128.826H227.9C233.446 113.94 239.551 109.997 252.552 102.5C266.522 110.52 272.307 114.7 275.06 128.826H288.994C295.69 137.001 298.057 141.417 300.784 149.11H310.43C317.949 159.996 319.58 165.417 321.148 174.733L332.938 169.395C335.887 184.03 336.01 191.348 332.938 202.491C352.232 207.914 405.822 181.139 385.458 195.018C365.093 208.897 379.572 231.047 351.159 262.278C359.199 265.938 362.304 268.942 365.093 276.157C328.82 308.058 305.688 322.069 252.552 330.605Z" fill="',
    '<path d="M249.007 336C201.007 413 110.098 386.92 111.007 280C116.976 180.921 155.805 130.691 249.007 61C334.007 141 379.743 222.155 388.873 298.657C398.002 375.16 332.171 406.06 249.007 338V336Z" fill="',
    '<path d="M243.663 325C31.6204 259.206 224.591 91.2588 242.753 58.0227C303.937 93.6094 462.572 254.85 243.663 325Z" fill="',
    '<path d="M117.143 242.5C113.732 252.421 171.735 380.926 244.143 393.5C320.328 380.825 389 255.263 382.643 248C376.286 240.737 293.837 249.916 282.143 271.5C305.305 193.588 297.848 149.041 249.143 68C205.221 145.028 196.857 189.545 212.143 271.5C191.239 243.163 117.143 242.5 117.143 242.5Z" fill="',
    '<path d="M232.5 374.5C68.5001 316.5 220.5 169 225.5 47.5C239 141 419 312 232.5 374.5Z" fill="',
    '<path d="M224 331.641C234.277 337.099 244.36 342.375 254 347.5V297C170.79 230.63 245.822 123.182 253.305 116.172C278.001 130.444 338.151 244.219 254 297V347.5C263.485 342.076 272.626 336.829 281.517 331.641C279.01 273.727 356.889 252.664 400.984 246.571C395.418 270.729 353.429 387.445 281.517 331.641C272.626 336.829 263.485 342.076 254 347.5C244.36 342.375 234.277 337.099 224 331.641C154.543 371.475 132.028 322.56 99.56 248.637C150.572 261.008 228.484 262.254 224 331.641Z" fill="'];
    
    string[8] private pathend=['"/><path d="M247.25 430C239.726 385.818 241.124 357.35 247.25 304.184M247.25 126.939C242.594 196.157 240.653 234.965 247.25 304.184M247.25 304.184C189.62 333.034 100 304.184 100 304.184C100 304.184 130.527 252.693 161.139 251.837C137.883 239.653 125.521 170.597 110.333 168.265C119.001 170.388 181.52 176.388 189.555 176.531C203.358 125.567 237.459 124.101 247.25 70C286.067 135.745 311.078 142.805 306.666 176.531C334.497 171.171 392.572 172.44 397.083 170.102C402.472 174.858 373.199 245.799 341.972 251.837C373.255 262.717 403.528 301.023 399.666 306.02C398.859 313.203 314.632 331.141 247.25 304.184Z" stroke="black" stroke-width="2.5"/><path d="M246.5 303C276.623 260.723 295.609 241.221 331.5 210.5M246.5 303C286.524 296.9 308.959 288.739 349 300M246.5 303C222.425 262.297 171.608 206.684 166 207.5M246.5 303C208.078 296.123 186.565 288.661 148 300" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M250.541 417.44V371.439M250.541 371.439V84.4339C305.364 61.086 515.463 330.002 250.541 371.439ZM250.541 371.439C-14.8402 315.696 194.019 65.6193 250.541 85.4339" stroke="black" stroke-width="2.5"/><path d="M251.541 346.439C306.418 340.276 346.413 273.014 341.541 259.437M251.541 305.438C194.804 297.506 176.04 277.988 147.541 237.437M251.541 265.437C288.605 245.258 300.195 226.59 313.541 187.436M251.541 218.436C210.678 207.577 197.32 195.418 186.541 165.435M251.541 172.435C263.448 172.733 292.51 135.247 282.541 109.434M251.541 129.435C231.46 127.045 226.369 121.887 222.541 109.434" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M252.552 400C265.744 391.301 255.652 362.03 252.552 330.605M252.552 330.605C207.62 320.478 184.108 311.18 150.729 276.157C155.992 267.583 158.433 265.214 162.519 262.278C128.938 251.594 140.355 235.761 110 195.018C136.267 202.3 151.733 207.721 171.094 202.491C169.621 190.276 170.451 182.629 171.094 169.395L183.956 174.733C188.92 164.023 192.054 158.536 197.889 149.11H206.464C208.161 141.038 210.272 136.595 216.11 128.826H227.9C233.446 113.94 239.551 109.997 252.552 102.5M252.552 330.605C246.081 245.131 246.229 195.106 252.552 102.5M252.552 330.605C305.688 322.069 328.82 308.058 365.093 276.157C362.304 268.942 359.199 265.938 351.159 262.278C379.572 231.047 365.093 208.897 385.458 195.018C405.822 181.139 352.232 207.914 332.938 202.491C336.01 191.348 335.887 184.03 332.938 169.395L321.148 174.733C319.58 165.417 317.949 159.996 310.43 149.11H300.784C298.057 141.417 295.69 137.001 288.994 128.826H275.06C272.307 114.7 266.522 110.52 252.552 102.5" stroke="black" stroke-width="2.5"/><path d="M149.5 224.5C192.671 253.696 214.574 278.855 252 330C284.856 279.593 305.428 255.271 349 224.5" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M249.007 438V338M249.007 336V66V61M249.007 336C201.007 413 110.098 386.92 111.007 280C116.976 180.921 155.805 130.691 249.007 61M249.007 336V338M249.007 338C332.171 406.06 398.002 375.16 388.873 298.657C379.743 222.155 334.007 141 249.007 61" stroke="black" stroke-width="2.5"/><path d="M121.007 215C127.637 239.159 134.496 258.653 144.007 274.294M366.007 220C355.607 248.229 345.83 269.618 331.929 286M249.007 265C190.792 243.557 162.658 227.027 144.007 166M249.007 239C295.6 216.149 318.685 201.148 326.007 150M249.007 183C207.647 174.143 191.979 161.137 178.007 123M249.007 138C274.799 133.489 284.704 127.186 294.007 109M249.007 103C234.181 104.367 222.007 82 222.007 82M216.007 322.188C225.829 324.56 236.77 326.478 249.007 328C261.014 325.529 271.598 322.684 281.007 319.369M216.007 322.188C213.269 352.637 202.757 364.733 169.007 378M216.007 322.188C200.914 318.542 188.461 313.824 178.007 307.817M178.007 307.817C166.81 327.336 157.201 335.245 121.007 332M178.007 307.817C163.328 299.382 152.588 288.406 144.007 274.294M144.007 274.294C135.512 284.882 129.613 289.262 111.007 286M331.929 286C356.934 303.3 368.229 300.734 387.007 290M331.929 286C324.675 294.549 316.299 301.734 306.124 307.817M306.124 307.817C313.471 343.442 325.338 356.423 356.007 371M306.124 307.817C298.775 312.21 290.487 316.028 281.007 319.369M281.007 319.369C274.221 342.15 280.678 353.304 306.124 371" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M243.846 443.5C256.433 402.402 250.846 332 243.663 325M243.846 82.5001C238.191 183.055 235.548 236.796 243.663 325M243.663 325C29.346 258.5 228.777 87.6442 243.277 57M243.663 325C463.663 254.5 302.346 92.0001 241.846 57.5001" stroke="black" stroke-width="2.5"/><path d="M242 299.5C273.35 271.349 309 214 324 209.5M240.5 292.5C214.086 270.696 190 222.5 176.5 216M239.5 227.5C252.925 214.4 255.804 207.614 261 195.5M238 222.5C229.348 217.766 215.99 200.239 211 195.5M239.5 167.5C260.09 149.779 269.154 137.389 282 112M239.5 161.5C225.974 152.961 218.607 140.442 205.5 117" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M249.143 431.5L244.143 393.5M249.143 131.5C242.634 233.8 241.256 291.166 244.143 393.5M244.143 393.5C171.735 380.926 113.732 252.421 117.143 242.5C117.143 242.5 191.239 243.163 212.143 271.5C196.857 189.545 205.221 145.028 249.143 68C297.848 149.041 305.305 193.588 282.143 271.5C293.837 249.916 376.286 240.737 382.643 248C389 255.263 320.328 380.825 244.143 393.5Z" stroke="black" stroke-width="2.5"/><path d="M243.5 388C278.591 338.085 300.823 316.602 343.5 286M242.5 387.5C214.981 341.169 195.02 319.166 152.5 286" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M232.5 430.5C229.349 411.519 229.03 399.55 232.5 374.5M227.5 94.5C222.473 205.725 222.481 267.322 232.5 374.5M232.5 374.5C68.5001 316.5 220.5 169 225.5 47.5C239 141 419 312 232.5 374.5Z" stroke="black" stroke-width="2.5"/><path d="M231.5 361C272.155 324.209 289.766 298.082 308 237.5M227.5 326.5C198.369 300.667 176.671 277.979 167 231M226.5 280.5C260.165 249.289 268.431 225.7 285 180.5M224 231C204.695 216.369 196.655 204.296 189 173.5M224 173.5C244.372 156.278 251.973 145.828 255 125" stroke="black" stroke-width="1.5"/>',
    '"/><path d="M254 384.5V347.5M254 145C248.502 204.36 248.229 237.64 254 297M254 347.5C244.36 342.375 234.277 337.099 224 331.641M254 347.5C263.485 342.076 272.626 336.829 281.517 331.641M254 347.5V297M110 258C141.309 286.539 184.122 310.463 224 331.641M390.5 258C356.908 290.914 324.382 313.525 281.517 331.641M224 331.641C228.5 262 150 261 99 248.5M224 331.641C154.5 371.5 132 322.5 99.5 248.5M281.517 331.641C279 273.5 357.5 252.5 401.5 246.5M281.517 331.641C353.5 387.5 395.5 270.5 401 246.5M254 297C170 230 247.261 121.138 253.5 116M254 297C338.5 244 277.5 129.5 253 116" stroke="black" stroke-width="2.5"/><path d="M198 317.5C195.117 300.307 179.296 268.08 177.5 267.5M173 303.5C152.841 302.376 140.441 301.044 120.5 294M250.5 258.5C235.355 240.959 227.843 228.636 215.5 204M250.5 211.5C253.5 211.5 276 177.5 282.5 157M312 317C314.557 298.268 317.015 288.665 324 269.5M339.5 300C355.204 299.862 380.979 295.756 382 294" stroke="black" stroke-width="1.5"/>'];

    string[9] private linearComponents=['x1="250" y1="70" x2="250" y2="430" gradientUnits="userSpaceOnUse">',
                                       'x1="250.22" y1="83" x2="250.22" y2="417.44" gradientUnits="userSpaceOnUse">',
                                       'x1="250" y1="102.5" x2="250" y2="400" gradientUnits="userSpaceOnUse">',
                                       'x1="250.36" y1="61" x2="250.36" y2="438" gradientUnits="userSpaceOnUse">',
                                       'x1="250.366" y1="57" x2="250.366" y2="443.5" gradientUnits="userSpaceOnUse">',
                                       'x1="250.026" y1="68" x2="250.026" y2="431.5" gradientUnits="userSpaceOnUse">',
                                       'x1="236.58" y1="47.5" x2="236.58" y2="430.5" gradientUnits="userSpaceOnUse">',
                                       'x1="250.25" y1="116" x2="250.25" y2="439.5" gradientUnits="userSpaceOnUse">'];
    string[9] private leafnames =["sugar maple","coton easter","red maple","lilac","aspen","japanes maple","pin cherry","white ash"];
    string[4] private effects =["normal","water","dust","crushed"];
    string[3] private grads = ["normal","two color gradient","three color gradient"];
    constructor() ERC721("Leafs", "LEAFS")  Ownable(){}
    
    struct Leaf{
        uint256 leafstyle;
        uint256 bgcolor;
        uint256 leafcolor;
        uint256 filltype;
        uint256 effect;
    }
    
    function randomLeaf(uint256 tokenId) internal view returns(Leaf memory){
        Leaf memory leaf;
        leaf.leafstyle = getLeafStyle(tokenId);
        leaf.bgcolor = getColor(tokenId,"BACKGROUND COLOR",25,44);
        leaf.filltype = getFillType(tokenId);
        leaf.leafcolor = getColor(tokenId,"LEAF COLOR",0,24);
        leaf.effect = getEffectType(tokenId);
        return leaf;
    }
    
    function traits(Leaf memory leaf) internal view returns(string memory){
        string[9] memory parts;
        parts[0] = '"attributes": [{"trait_type": "Leaf Name","value": "';
        parts[1] = leafnames[leaf.leafstyle];
        parts[2] = '"}, {"trait_type": "BG Color","value": "';
        parts[3] = colors[leaf.bgcolor];
        parts[4] = '"}, {"trait_type": "Gradient_Type","value": "';
        parts[5] = grads[leaf.filltype];
        parts[6] = '"}, {"trait_type": "Effect_Type","value": "';
        parts[7] = effects[leaf.effect];
        parts[8] = '"}], ';
        return string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8]));
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
     function pluckNum(uint256 tokenId, string memory keyPrefix, uint256 minNum, uint256 maxNum) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId), toString(minNum), toString(maxNum),_msgSender())));
        uint256 num = rand % (maxNum - minNum + 1) + minNum;
        return num;
    }
    
    function getColor(uint256 tokenId,string memory seed,uint256 min,uint256 max) internal view returns(uint256){
          return pluckNum(tokenId,seed,min,max);
    }
    
    function getLeafStyle(uint256 tokenId) internal view returns(uint256){
        uint rand = random(string(abi.encodePacked("LEAF STYLE", toString(tokenId),_msgSender())));
        rand = rand % 113;
        uint256 ps;
        if (rand >= 0 && rand < 20){ ps=0;}
        if (rand >= 20 && rand < 40){ ps=1;}
        if (rand >= 40 && rand < 60){ ps=2;}
        if (rand >= 60 && rand < 80){ ps=3;}
        if (rand >= 80 && rand < 95){ ps=4;}
        if (rand >= 95 && rand < 105){ ps=5;}
        if (rand >= 105 && rand < 110){ ps=6;}
        if (rand >= 110 && rand < 113){ ps=7;}
        return ps;
    }
    
    
    function getFillType(uint256 tokenId) internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("LEAF FILL", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >=150 && rand < 180){ ps=1;}
        if(rand >=180 && rand < 200){ ps=2;}
        return ps;
    }
    
    function getEffectType(uint256 tokenId) internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("EFFECT TYPE", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >=120 && rand < 160){ps = 1;}
        if(rand>=160 && rand < 185){ps = 2;}
        if(rand>=185 && rand < 201){ps = 3;}
        return ps;
    }
    

    
    function getBackgroundTemplateSVG(uint256 bg) internal view returns(string memory){
        return string(abi.encodePacked('<rect width="500" height="500" fill="',colors[bg],'"/>'));
    }
    
    
        
    function getLeafUrl(Leaf memory leaf) internal view returns(string memory){
        uint256 fill = leaf.filltype;
        string memory fillUrl;
        if(fill==0){
            fillUrl = colors[leaf.leafcolor];
            return fillUrl;
        }
        fillUrl = 'url(#A)';
        return fillUrl;
    }
    function getLeafUrlId(Leaf memory leaf) internal view returns(string memory){
        uint256 fill = leaf.filltype;
        string memory fillcolor;
        if(fill==0){ 
            fillcolor = colors[leaf.leafcolor];
            return fillcolor;
        }
        fillcolor = 'A';
        return fillcolor;
    }
    
    
    function getShadowBody(uint256 effect) internal pure returns(string memory){
        string memory frequency;
        if(effect == 0){
            return string(
                abi.encodePacked('<filter xmlns="http://www.w3.org/2000/svg" id="C" x="-50%" y="-50%" width="200%" height="200%">',
                '<feDropShadow dx="8" dy="8" flood-color="#000000" flood-opacity="0.9" stdDeviation="0"/></filter>'));
        }
        if(effect == 1)
            frequency = '0.02';
        if(effect == 2)
            frequency = '0.4';
        if(effect == 3)
            frequency = '0.04';
        return string(
            abi.encodePacked('<filter xmlns="http://www.w3.org/2000/svg" id="C" x="-50%" y="-50%" width="200%" height="200%">',
            '<feTurbulence type="turbulence" baseFrequency="',frequency,'" numOctaves="2" result="turbulence"/>',
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="20" xChannelSelector="R" yChannelSelector="G"/>',
            '<feDropShadow dx="8" dy="8" flood-color="#000000" flood-opacity="0.9" stdDeviation="0"/></filter>'
            )
        );
    }
    
    function getLeafFilterFill(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string memory grad = '';
        if(leaf.filltype==0){
            return grad;
        }
        if(leaf.filltype==1){
            grad = string(
                abi.encodePacked('<linearGradient id="',getLeafUrlId(leaf),
                '" ',
                linearComponents[leaf.leafstyle],
                '<stop offset="0.30" stop-color="',
                colors[getColor(tokenId,"linear first",0,24)],
                '"/>',
                '<stop offset="0.60" stop-color="',
                colors[getColor(tokenId,"LINEAR SECOND",0,24)],
                '"/>',
                '</linearGradient>'
                )
            );
        }
        if(leaf.filltype==2){
            grad = string(
                        abi.encodePacked('<linearGradient id="',
                        getLeafUrlId(leaf),
                        '" ',
                        linearComponents[leaf.leafstyle],
                        '<stop offset="0.25" stop-color="',colors[getColor(tokenId,"linear first",0, 24)],
                        '"/>',
                        '<stop offset="0.50" stop-color="',colors[getColor(tokenId,"LINEAR SECOND",0, 24)],
                        '"/>',
                        '<stop offset="0.68" stop-color="',colors[getColor(tokenId,"Linear THIRD",0, 24)],
                        '"/>',
                        '</linearGradient>'
                        )
                    );
        }
         return grad;
    }
    
    
    function getSVGImage(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string[11] memory parts;
        parts[0]='<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg">';
        parts[1]= getBackgroundTemplateSVG(leaf.bgcolor);
        parts[2]='<g filter="url(#C)">';
        parts[3] = pathstart[leaf.leafstyle];
        parts[4] = getLeafUrl(leaf);
        parts[5] = pathend[leaf.leafstyle];
        parts[6]='</g>';
        parts[7]='<defs>';
        parts[8]= getShadowBody(leaf.effect);
        parts[9] = getLeafFilterFill(leaf,tokenId);
        parts[10] = '</defs></svg>';
        string memory output = string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5]));
        output = string(abi.encodePacked(output,parts[6],parts[7],parts[8],parts[9],parts[10]));
        return output;
    }
    
    
   function tokenURI(uint256 tokenId)override public view returns (string memory){
       Leaf memory leaf = randomLeaf(tokenId);
       string memory output = Base64.encode(bytes(string(abi.encodePacked('{"name": "Leaf #', toString(tokenId), '", "description": "Fall Leaves are fully on-chain, randomly generated unique Leaves. To Enjoy Fall Colors.",', 
        traits(leaf),
        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVGImage(leaf,tokenId))), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', output));
        return output;
    }
    
    function mintLeaf(address add,uint256 numOftokens) private  {
        require(!sales_paused, "Sale is paused right now");
        require(totalSupply() < max_supply, "All tokens minted");
        require(totalSupply() + numOftokens <= max_supply, "Minting exceeds supply");
        require(numOftokens <= maxMint, "Cannot purchase so many in a transaction");
        require(numOftokens > 0, "Must mint at least one");
        require(_mintperaddress[msg.sender] + numOftokens <= max_per_address,  "Max per address minted");
        require(price * numOftokens == msg.value, "ETH amount not correct");
        for(uint32 i=0;i < numOftokens; i++){
            uint256 tokenId = minted + 1;
            _safeMint(add, tokenId);
            minted += 1;
            _mintperaddress[msg.sender] += 1;
        }
    }

    function toggleAllSalesPaused() public onlyOwner {
        sales_paused = !sales_paused;
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