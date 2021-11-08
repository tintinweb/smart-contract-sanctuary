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
    
    uint256 public max_supply = 2021;
    uint256 public price = 0.0 ether;
    uint256 public max_per_address = 20;
    uint256 public minted;
    uint256 public maxMint = 20;
    
    bool public sales_paused = false;
    
    mapping(address => uint256) private _mintperaddress;
    
    string[50] private colors=["#822A25","#9D373E","#E8544B","#D62B2A","#B62511","#755612","#C8712D","#A47147","#E4AE44","#AC2C04","#C37005","#FBCC04","#AA5C05","#E47204",
    "#F2A624","#5C6A08","#796F0D","#344006","#3F3C0B","#A49323","#DDBB4F","#F3612A","#F09A2D","#BA423D","#8E2741",
    "#F3F0D7","#FED2AA","#C8A3D4","#FBEABE","#FEF5ED","#FFF9B6","#FFCCD2","#F5C6A5","#FEFBF3","#E5B299","#FFD384","#EAE3CB","#FFDCDC","#DBDFC8","#AEE1E1","#D3E0EA","#A3D2CA","#FFC1B6","#FFB268",
    "#E7D9EA","#DDDDDD", "#CDAC81", "#A1CAE2", "#D9DAB0", "#314E52"];

    
    string[50] private colornames=["berry","wine","blush","apple","scarlet","coffee","squash","peanut","mustard","brick","cider","honey","amber","orange","butterscotch","moss","pickle","seaweed","pine","olive","fawn","tangerine","apricot","crail","stiletto",
    "Beige","Flesh","Edgewater","Astra","ProvincialPink","Portafino","PastelPink","Manhattan","OldLace",
    "Cashmere","Grandis","AthsSpecial","Cosmos","Tana","PowderBlue","Botticelli",
    "Sinbad","YourPink","Koromiko","Snuff","Alto", "Tan", "RegentStBlue","GreenMist", "Spectra"];

    string[25] private stemcolors=["#4F1A17", "#6E262B", "#D5261B", "#9E1F1E", "#79190B", "#392A09", "#925221", "#755133", "#C98F1D", "#6E1C03", "#814A03", "#BA9703", "#683803", "#A05003", "#CA840C", "#252B03","#3C3706", "#040500", "#090802", "#6D6217", "#C59F26", "#D0410C", "#CD790F", "#86302C", "#581828"];

    string[8] private pathstart=['<path d="M247.5 319C189.871 347.85 100 318.184 100 318.184C100 318.184 130.527 266.693 161.139 265.837C137.883 253.653 125.521 184.597 110.333 182.265C119.001 184.388 181.52 190.388 189.555 190.531C203.358 139.567 237.459 138.101 247.25 84C286.067 149.745 311.078 156.805 306.666 190.531C334.497 185.171 392.572 186.44 397.083 184.102C402.472 188.858 373.199 259.799 341.972 265.837C373.255 276.717 403.528 315.023 399.666 320.02C398.859 327.203 314.882 345.957 247.5 319Z" stroke-width="5"',
    '<path d="M250.541 380.446C-14.8402 324.703 194.019 62.5658 250.541 82.3805C305.364 59.0325 515.463 339.009 250.541 380.446Z" stroke-width="5"',
    '<path d="M150.729 281.657C184.108 316.68 207.62 325.978 252.552 336.105C305.688 327.569 328.82 313.558 365.093 281.657C362.304 274.442 359.199 271.438 351.159 267.778C379.572 236.547 365.093 214.397 385.458 200.518C405.822 186.639 352.232 213.414 332.938 207.991C336.01 196.848 335.887 189.53 332.938 174.895L321.148 180.233C319.58 170.917 317.949 165.496 310.43 154.61H300.784C298.057 146.917 295.69 142.501 288.994 134.326H275.06C272.307 120.2 266.522 116.02 252.552 108C239.551 115.497 233.446 119.44 227.9 134.326H216.11C210.272 142.095 208.161 146.538 206.464 154.61H197.889C192.054 164.036 188.92 169.523 183.956 180.233L171.094 174.895C170.451 188.129 169.621 195.776 171.094 207.991C151.733 213.221 136.267 207.8 110 200.518C140.355 241.261 128.938 257.094 162.519 267.778C158.433 270.714 155.992 273.083 150.729 281.657Z" stroke-width="5"',
    '<path d="M248.641 90.5093V86M248.641 86C155.01 148.851 116.004 194.151 110.007 283.507C109.093 379.933 200.42 403.454 248.641 334.011V335.814C332.187 397.195 398.32 369.328 389.149 300.333C379.978 231.338 334.031 158.149 248.641 86Z" stroke-width="5"',
    '<path d="M243.177 342.497C28.6463 276.688 228.776 108.052 243.177 77.3612C303.788 111.666 462.949 271.289 243.177 342.497Z" stroke-width="5"',
    '<path d="M121.399 211.914C117.988 221.835 175.991 350.34 248.399 362.914C324.584 350.238 393.256 224.677 386.899 217.414C380.542 210.151 298.093 219.329 286.399 240.914C309.561 163.002 302.104 118.454 253.399 37.4135C209.477 114.441 201.114 158.958 216.399 240.914C195.495 212.577 121.399 211.914 121.399 211.914Z" stroke-width="5"',
    '<path d="M245.922 384C81.9223 326 233.922 178.5 238.922 57C252.422 150.5 432.422 321.5 245.922 384Z" stroke-width="5"',
    '<path d="M99 237.5C150 250 226.5 252 222 321.641C152.5 361.5 132 311.5 99.5 237.5M401.5 235.5C357.5 241.5 281 265.5 283.517 323.641C355.5 379.5 395.5 259.5 401 235.5M253.5 105C247.261 110.138 170 219 254 286C338.5 233 277.5 118.5 253 105" stroke-width="5"'];
    
    string[8] private pathstemone=['<path d="M248.5 317C278.623 274.723 297.609 255.221 333.5 224.5M248.5 317C288.524 310.9 310.959 302.739 351 314M248.5 317C224.425 276.297 173.608 220.684 168 221.5M248.5 317C210.078 310.123 188.565 302.661 150 314M248.5 317V143M248.5 317C242.167 362.522 266 403.5 248.5 416.5" stroke-width="3" stroke-linecap="round"',
    '<path d="M252 342.439C306.877 336.275 346.872 269.014 342 255.437M252 301.438C195.264 293.506 176.5 273.988 148 233.437M252 261.437C289.064 241.258 300.654 222.59 314 183.436M252 214.436C211.137 203.577 197.78 191.418 187 161.435M252 168.435C263.907 168.733 292.969 131.247 283 105.434M252 125.435C231.919 123.045 226.829 117.887 223 105.434M250.959 81L252 377C255.57 395.666 254.87 404.565 252 419.5" stroke-width="3" stroke-linecap="round"',
    '<path d="M252.5 335.5C215.074 284.355 193.171 259.196 150 230M252.5 335.5C285.356 285.093 305.928 260.771 349.5 230M252.5 335.5C243.903 248.696 245.016 198.89 252.5 109M252.5 335.5C248.904 359.644 248.189 372.498 252.5 392.5" stroke-width="3" stroke-linecap="round"',
    '<path d="M121.046 221.886C127.707 243.674 134.597 261.255 144.152 275.36M367.171 226.395C356.723 251.853 346.901 271.143 332.937 285.918M249.634 266.979C191.152 247.64 162.889 232.733 144.152 177.695M249.634 243.53C296.441 222.922 319.632 209.393 326.987 163.265M249.634 193.026C208.084 185.039 192.344 173.309 178.308 138.915M249.634 152.443C275.545 148.375 285.495 142.69 294.84 126.289M249.634 120.878C234.74 122.111 222.51 101.939 222.51 101.939M216.482 318.554C226.35 320.693 237.341 322.423 249.634 323.796C261.696 321.568 272.328 319.002 281.781 316.012M216.482 318.554C213.731 346.015 203.172 356.924 169.266 368.889M216.482 318.554C201.32 315.266 188.81 311.011 178.308 305.593M178.308 305.593C167.059 323.196 157.406 330.33 121.046 327.403M178.308 305.593C163.562 297.986 152.772 288.088 144.152 275.36M144.152 275.36C135.618 284.909 129.692 288.859 111 285.918M332.937 285.918C358.056 301.52 369.403 299.205 388.268 289.525M332.937 285.918C325.65 293.628 317.234 300.108 307.014 305.593M307.014 305.593C314.394 337.722 326.316 349.429 357.125 362.576M307.014 305.593C299.63 309.556 291.304 312.999 281.781 316.012M281.781 316.012C274.964 336.557 281.45 346.616 307.014 362.576M249.634 86L249.493 331C253.092 367.389 253.3 385.861 249.634 414.5" stroke-width="3" stroke-linecap="round"',
    '<path d="M241.904 317.661C273.163 289.409 308.91 232.311 323.895 227.763M240.663 311.031C214.179 289.312 189.937 241.194 176.417 234.738M242.663 246.161C256.045 233.018 255.693 226.096 260.85 213.966M240.663 241.161C231.996 236.455 215.856 218.85 210.85 214.127M242.404 185.661C262.937 167.874 268.817 155.829 281.581 130.398M241.404 181.161C227.85 172.666 218.28 159.045 205.097 135.645M241.904 105.263L241.904 341.263C249.723 368.958 249.524 407.063 241.904 423.263" stroke-width="3" stroke-linecap="round"',
    '<path d="M248.018 341.596C283.576 292.013 307.008 270.739 349.97 240.538M248.022 341.087C220.939 294.5 201.186 272.311 158.978 238.747M249.018 119.247C245.215 216.348 245.394 270.041 249.018 364.747C255.772 389.469 255.225 402.127 249.018 423.247" stroke-width="3" stroke-linecap="round"',
    '<path d="M245.5 370C286.155 333.209 303.766 307.082 322 246.5M241.5 335.5C212.369 309.667 190.671 286.979 181 240M240.5 289.5C274.165 258.289 282.431 234.7 299 189.5M237 240C217.695 225.369 210.655 213.296 203 182.5M241 182.5C261.372 165.278 265.973 154.828 269 134M241.5 138C237.341 236.724 238.521 290.445 245.5 384C252.752 406.358 252.428 419.424 245.5 443.5" stroke-width="3" stroke-linecap="round"',
    '<path d="M199.5 309.791C196.617 292.599 180.796 259.371 179 258.791M173.5 294.791C153.341 293.668 141.941 292.336 122 285.291M254 249.791C238.855 232.25 229.343 219.928 217 195.291M255 202.791C258 202.791 277.5 168.791 284 148.291M314.5 308.291C317.057 289.559 318.515 281.956 325.5 262.791M340 293.291C355.704 293.154 382.479 287.048 383.5 285.291M257 135C252.775 213.863 253.737 259.251 257 340.75M255.5 394.291L257 340.75M257 340.75C305.356 315.248 330.133 301.074 372.5 270.791M257 340.75C206.166 314.17 177.752 299.747 139 270.791" stroke-width="3" stroke-linecap="round"'];

    
    string[9] private leafnames =["sugar maple","coton easter","red maple","lilac","aspen","japanese maple","pin cherry","white ash"];
    string[3] private grads = ["solid","two color gradient","three color gradient"];
    string[4] private backgroundtype = ["solid","aspen pattern","Japanese maple pattern"];
    string[2] private effect=["normal","glitched"];
    constructor() ERC721("AutumnLeaf", "AUTLEAFS")  Ownable(){}
    
    struct Leaf{
        uint256 leafstyle;
        uint256 bgcolor;
        uint256 leafcolor;
        uint256 filltype;
        uint256 bunches;
        bool animation;
        uint256 backgroundpattern;
        uint256 effect;
    }
    
    function randomLeaf(uint256 tokenId) internal view returns(Leaf memory){
        Leaf memory leaf;
        leaf.leafstyle = getLeafStyle(tokenId);
        leaf.bgcolor = getColor(tokenId,"BACKGROUND COLOR",25,49);
        leaf.filltype = getFillType(tokenId);
        leaf.leafcolor = getColor(tokenId,"LEAF COLOR",0,24);
        leaf.bunches = getBunches(tokenId);
        leaf.animation = getAnimation(tokenId);
        leaf.backgroundpattern = getBackgroundPattern(tokenId);
        leaf.effect = getEffect(tokenId);
        return leaf;
    }
    
    function traits(Leaf memory leaf) internal view returns(string memory){
        string[17] memory parts;
        string[6] memory leaves =["sugar maple","red maple","aspen","japanese maple","pin cherry","white ash"];
        string memory output;
        parts[0] = '"attributes": [{"trait_type": "Leaf Name","value": "';
        parts[1] = (leaf.bunches > 0)?string(abi.encodePacked(leafnames[leaf.leafstyle],' ',leaves[leaf.bunches-1])):leafnames[leaf.leafstyle];
        parts[2] = '"}, {"trait_type": "BG Color Code","value": "';
        parts[3] = colors[leaf.bgcolor];
        parts[4] = '"}, {"trait_type": "BG Color","value": "';
        parts[5] = colornames[leaf.bgcolor];
        parts[6] = '"}, {"trait_type": "Gradient_Type","value": "';
        parts[7] = grads[leaf.filltype];
        parts[8] = '"}, {"trait_type": "Bunched","value": "';
        parts[9] = (leaf.bunches > 0)?'true':'false';
        parts[10] = '"}, {"trait_type": "Background_Type","value": "';
        parts[11] = backgroundtype[leaf.backgroundpattern];
        parts[12] = '"}, {"trait_type": "Animation","value": "';
        parts[13] = (leaf.animation)?'true':'false';
        parts[14] = '"}, {"trait_type": "Effect","value": "';
        parts[15] = effect[leaf.effect];
        parts[16] = '"}], '; 
        output = string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5],parts[6],parts[7],parts[8]));
        output = string(abi.encodePacked(output,parts[9],parts[10],parts[11],parts[12],parts[13],parts[14]));
        output = string(abi.encodePacked(output,parts[15],parts[16]));
        return output;
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
        uint rand = random(string(abi.encodePacked("LEAF_STYLE", toString(tokenId),_msgSender())));
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
        uint256 rand = random(string(abi.encodePacked("LEAF_FILL", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >=180 && rand < 201){ ps=1;}
        return ps;
    }
    
    function getBunches(uint256 tokenId) internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("BUNCHES", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >= 150 && rand < 160){return ps=1;}
        if(rand >= 160 && rand < 170){return ps=2;}
        if(rand >= 170 && rand < 180){return ps=3;}
        if(rand >= 180 && rand < 185){return ps=4;}
        if(rand >= 185 && rand < 195){return ps=5;}
        if(rand >= 195 && rand < 198){return ps=6;}
        return ps;
    }
    function getAnimation(uint256 tokenId) internal view returns(bool){
        uint256 rand = random(string(abi.encodePacked("ANIMATION", toString(tokenId),_msgSender())));
        rand = rand % 201;
        return(rand >= 196);
    }
    function getBackgroundPattern(uint256 tokenId) internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("BG_PATTERN", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >= 170 && rand < 180){ps=1;}
        if(rand >= 180 && rand < 190){ps=2;}
        if(rand >= 190 && rand < 201){ps=3;}
        return ps;
    }
    
    function getEffect(uint256 tokenId) internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("EFFECT", toString(tokenId),_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand >= 190 && rand < 201){ps=1;}
        return ps;
    }
    
    function getBackgroundTemplateSVG(Leaf memory leaf,uint256 bg) internal view returns(string memory){
        string memory pattern='';
        if(leaf.backgroundpattern==0)
            pattern = string(abi.encodePacked('<rect width="500" height="500" fill="',colors[bg],'"/>'));
        if(leaf.backgroundpattern==1 || leaf.backgroundpattern==2||leaf.backgroundpattern==3)
            pattern = string(abi.encodePacked('<rect width="500" height="500" fill="url(#D)"/>'));
        return pattern;
    }
    function getBackgroundFilter(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string memory filter='';
        string[2] memory leafPatternstart = ['<path d="M59.7048 36.5817C34.5493 27.6008 57.4421 4.67629 59.5969 0.139597C66.8553 4.99713 85.6748 27.0062 59.7048 36.5817Z" fill="',
        '<path d="M46.0151 18.3648C45.6561 19.4089 51.7604 32.9331 59.3809 34.2564C67.3987 32.9224 74.626 19.708 73.9569 18.9436C73.2879 18.1793 64.6107 19.1452 63.3801 21.4168C65.8177 13.2172 65.0329 8.52893 59.9071 1.16169e-07C55.2846 8.10656 54.4044 12.7917 56.0131 21.4168C53.8131 18.4346 46.0151 18.3648 46.0151 18.3648Z" fill="'];
        string[2] memory leafPatternend = ['"/><path d="M106.705 119.504C81.5493 110.523 104.442 87.5986 106.597 83.062C113.855 87.9195 132.675 109.929 106.705 119.504Z" fill="',
        '"/><path d="M92.0151 103.365C91.6561 104.409 97.7604 117.933 105.381 119.256C113.399 117.922 120.626 104.708 119.957 103.944C119.288 103.179 110.611 104.145 109.38 106.417C111.818 98.2172 111.033 93.5289 105.907 85C101.285 93.1066 100.404 97.7917 102.013 106.417C99.8131 103.435 92.0151 103.365 92.0151 103.365Z" fill="'
        ];
        string memory backgroundPattern = '<pattern id="D" x="0" y="0" width="120" height="120" patternUnits="userSpaceOnUse"><rect width="120" height="120" fill="';
        string[12] memory patterncolors=["#CEE5D0", "#FFB786", "#87AAA", "#F6D7A7", "#D3E4CD", "#FFE699" ,"#FF9292", "#FF7777", "#F8F0D7", "#B4846C", "#FFAB73", "#CFC5A5"];
        uint256 index;
        if(leaf.backgroundpattern==1){
            index = getColor(tokenId,"Pattern_aspen", 25, 36);
            filter = string(abi.encodePacked(backgroundPattern,colors[index],'"/>'));
            filter = string(abi.encodePacked(filter,leafPatternstart[0],patterncolors[index-25],leafPatternend[0],patterncolors[index-25]));
            filter = string(abi.encodePacked(filter,'"/></pattern>'));
        }
        if(leaf.backgroundpattern==2){
            index = getColor(tokenId,"Japanese_Maple", 25, 36);
            filter = string(abi.encodePacked(backgroundPattern,colors[index],'"/>'));
            filter = string(abi.encodePacked(filter,leafPatternstart[1],patterncolors[index-25],leafPatternend[1],patterncolors[index-25]));
            filter = string(abi.encodePacked(filter,'"/></pattern>'));
        }
        return filter;
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
   
    
    function getShadowBody(Leaf memory leaf) internal pure returns(string memory){
        string memory bg = string(abi.encodePacked('<filter xmlns="http://www.w3.org/2000/svg" id="C" x="-50%" y="-50%" width="200%" height="200%">',
        '<feDropShadow dx="-6" dy="11" flood-color="#000000" flood-opacity="0.14" stdDeviation="0"/>'));
            if(leaf.effect==0){
                bg = string(abi.encodePacked(bg,'</filter>'));
            }
            if(leaf.effect==1){
                bg = string(abi.encodePacked(bg,'<feTurbulence type="turbulence" baseFrequency="0.02" numOctaves="3" result="noise" seed="0">',
                '<animate attributeName="baseFrequency" dur="2s" values="0.01 0.4;0.0;0.01 0.4;0.0;0.01 0.4" fill="freeze" repeatCount="indefinite"/>',
                '</feTurbulence>',
                '<feDisplacementMap in2="noise" in="SourceGraphic" xChannelSelector="R" yChannelSelector="G" scale="6">',
                '<animate attributeName="scale" dur="2s" values="40;6;8;6;8;" fill="freeze" repeatCount="indefinite"/>',
                '</feDisplacementMap>',
                '</filter>'));
            }
        return bg;
    }
    
    function getLeafFilterFill(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string memory grad = '';
        string[8] memory linearComponents=["70","83","102","61","57","68","48","116"];
        if(leaf.filltype==0){
            return grad;
        }
        if(leaf.filltype==1){
            grad = string(
                abi.encodePacked('<linearGradient id="',getLeafUrlId(leaf),
                '" ',
                string(abi.encodePacked('x1="250" ','y1="',linearComponents[leaf.leafstyle],'" x2="250" y2="415" gradientUnits="userSpaceOnUse">')),
                '<stop offset="0.15" stop-color="',
                colors[getColor(tokenId,"linear first",0,24)],
                '"/>',
                '<stop offset="1" stop-color="',
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
                        string(abi.encodePacked('x1="250" ','y1="',linearComponents[leaf.leafstyle],'" x2="250" y2="415" gradientUnits="userSpaceOnUse">')),
                        '<stop offset="0.15" stop-color="',colors[getColor(tokenId,"linear first",0, 24)],
                        '"/>',
                        '<stop offset="0.55" stop-color="',colors[getColor(tokenId,"LINEAR SECOND",0, 24)],
                        '"/>',
                        '<stop offset="0.95" stop-color="',colors[getColor(tokenId,"Linear THIRD",0, 24)],
                        '"/>',
                        '</linearGradient>'
                        )
                    );
        }
         return grad;
    }
    function getRotateAngles() internal view returns(uint256){
        uint256 rand = random(string(abi.encodePacked("ROTATE",_msgSender())));
        rand = rand % 201;
        uint256 ps;
        if(rand > 101 && rand<201){ps=1;}
        return ps;
    }
    function getInfoBunchestop(Leaf memory leaf) internal view returns(string memory){
        string memory bunchTop='';
        string[2] memory rotateTopLeaf = ["10","20"];
        if(leaf.bunches> 0 && leaf.bunches < 8){
            bunchTop = string(abi.encodePacked('<g filter="url(#C)" transform="rotate(',rotateTopLeaf[getRotateAngles()],' 250 250)">'));
            return bunchTop;
        }
        return bunchTop;
    } 

    function getInfoBunchesBottom(Leaf memory leaf) internal view returns(string memory){
        string memory bunchBottom='<g filter="url(#C)" ';
        string[2] memory rotateBottomLeaf = ["-30","-20"];
        if(leaf.bunches> 0 && leaf.bunches < 8){
            bunchBottom = string(abi.encodePacked(bunchBottom ,'transform="translate(-40 0) rotate(',rotateBottomLeaf[getRotateAngles()],' 250 250)">'));
            return bunchBottom;
        }
        bunchBottom = string(abi.encodePacked(bunchBottom,'>'));
        return bunchBottom;
    }
    
    function getSelectedleaves(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string memory selectedLeaf='';
         uint256 colorindex = getColor(tokenId,string(abi.encodePacked("second_leaf",toString(leaf.bunches))),0,24);
        if(leaf.bunches==1){
            selectedLeaf = string(abi.encodePacked(pathstart[0],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[0],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        if(leaf.bunches==2){
            selectedLeaf = string(abi.encodePacked(pathstart[2],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[2],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        if(leaf.bunches==3){
            selectedLeaf = string(abi.encodePacked(pathstart[4],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[4],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        if(leaf.bunches==4){
            selectedLeaf = string(abi.encodePacked(pathstart[5],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[5],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        if(leaf.bunches==5){
            selectedLeaf = string(abi.encodePacked(pathstart[6],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[6],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        if(leaf.bunches==6){
            selectedLeaf = string(abi.encodePacked(pathstart[7],' stroke="',stemcolors[colorindex],'" ','fill="',colors[colorindex],'" ','/>',pathstemone[7],' stroke ="',
            stemcolors[colorindex],'"','/>','</g>'));
        }
        return string(abi.encodePacked(selectedLeaf));
    }

    function AnimationTop(Leaf memory leaf) internal pure returns(string memory){
        string memory animation = '';
        if(leaf.animation)
            animation = string(abi.encodePacked('<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 0" to="','360 ','0 500" dur="10s" repeatCount="indefinite"/>'));
        return animation;
    }
    
    function AnimationBottom(Leaf memory leaf) internal pure returns(string memory){
        string memory animation = '';
        if(leaf.animation)
            animation = string(abi.encodePacked('<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 0" to="','-360 ','0 500" dur="10s" repeatCount="indefinite"/>'));
        return animation;
    }

    function makeLeaf(Leaf memory leaf) internal view returns(string memory){
        string memory output='';
        string memory stroke = ((leaf.filltype==1)||(leaf.filltype==2))?'#683803':stemcolors[leaf.leafcolor];
        output  = getBackgroundTemplateSVG(leaf,leaf.bgcolor);
        output = string(abi.encodePacked(output,getInfoBunchesBottom(leaf),AnimationTop(leaf)));
        output = string(abi.encodePacked(output,pathstart[leaf.leafstyle],' stroke="',stroke,'" ','fill="',getLeafUrl(leaf),'" ','/>'));
        output = string(abi.encodePacked(output,pathstemone[leaf.leafstyle],' stroke ="',stroke,'"','/>'));
        return output;
    }   

    function getSVGImage(Leaf memory leaf,uint256 tokenId) internal view returns(string memory){
        string[11] memory parts;
        parts[0]='<svg width="500" height="500" viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg">';
        parts[1] = makeLeaf(leaf);
        parts[2] = '</g>';
        parts[3] = getInfoBunchestop(leaf);
        (leaf.bunches > 0 && leaf.bunches < 8)? parts[4] = AnimationBottom(leaf): parts[4] = '';
        parts[5] =getSelectedleaves(leaf,tokenId);
        parts[6]='<defs>';
        parts[7]= getShadowBody(leaf);
        parts[8] = getLeafFilterFill(leaf,tokenId);
        parts[9] = getBackgroundFilter(leaf,tokenId);
        parts[10] = '</defs></svg>';
        string memory output = string(abi.encodePacked(parts[0],parts[1],parts[2],parts[3],parts[4],parts[5]));
        output = string(abi.encodePacked(output,parts[6],parts[7],parts[8],parts[9],parts[10]));
        return output;
    }
    
    
   function tokenURI(uint256 tokenId)override public view returns (string memory){
       require(tokenId <= totalSupply(), "Leaf still not minted");
       Leaf memory leaf = randomLeaf(tokenId);
       string memory output = Base64.encode(bytes(string(abi.encodePacked('{"name": "Leaf #', toString(tokenId), '", "Description": "Autumn Leaves are fully on-chain, randomly generated unique Leaves. To warm and spice your winter.",', 
        traits(leaf),
        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVGImage(leaf,tokenId))), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', output));
        return output;
    }
    
    function mintLeaf(address add,uint256 numOftokens) public payable  {
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