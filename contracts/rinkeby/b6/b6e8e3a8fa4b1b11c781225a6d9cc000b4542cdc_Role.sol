/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
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


contract Role is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public mintPrice = 10000000000000000;//0.01 ETH

    address payable private _royaltyRecipient;

    struct SelfDecidedAttribute {
        uint8 gender;
        uint8 strength;
        uint8 dexterity;
        uint8 constitution;
        uint8 wisdom;
        uint8 charisma;
        uint8 intelligence;
        uint8 race;
        uint8 element;
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
    string[] private cike_green = ["Hunter of the Dead","Perfect Wight","Sword Dancer","Windwalker","Foe Hunter","Dungeon Delver","Spymaster","Thief-Acrobat","Ghostwalker","Ninja of the Crescent Moon"];
    string[] private cike_blue = ["Lifedrinker","Shadow Adept","Mage-Killer","Bloodhound","Master of Flies","Red Avenger","Arachnemancer"];
    string[] private cike_orange = ["Disciple of Baalzebul","Disciple of Dispater","Forsaker","Bayushi Deceiver Bayushi","Darkmask","Void Incarnate","Mage Hunter"];
    string[] private cike_red = ["Shadowdance Assassin","Shadow Scout","Shapeshifter","Soulblade","Shadow Mind"];

    string[] private fs_golden = ["Red Wizard","Meta Nightcloak","Mystic Meta Wanderer","Metamind","Pale Master","Truth Seeker"];
    string[] private fs_white = ["Bard","Druid","Sorcerer","Wizard","Loremaster","Thrall of Demogorgon","Thrall of Grazt","Thrall of Jubilex","Thrall of Orcus","Ur-Priest","Vermin Lord","Horned Harbinger","Ocular Adept","Silverstar","Wear of Purple","Arcane Devotee","Guild Wizard of Waterdeep","Spelldancer","Spellfire Channeler","War Wizard of Cormyr","Bane of Infidels","Blighter","Void Disciple","Witch Hunter","ElvenHigh Mage","Emancipated Spawn","Illithid Savant","Sybil","Yuan-Ti Cultist","BlackFlame Zealot","Raumathari Battlemage","Talontar Blightlord","Beholder Mage","Runecaster","Zhentarim Skymage","Incantatrix","Master Harper"];
    string[] private fs_green = ["Arcane Trickster","Archmage","Dragon Disciple","Horizon Walker","Loremaster","A Guidebook to Clerics and Paladins","Divine Oracle","Sacred Exorcist","Warpriest","Wizard of High Sorcery","Heartwarder","Divine Disciple","Harper Scout","Hathran","Red Wizard","Runecaster","Harper Mage","Geomancer","Hexer","Oozemaster","Shifter","Fangof Lolth","Arcane Trickster","Bladesinger","Blood Magus","Entropist ","Fiend of Blasphemy","Fiend of Corruption ","Fiend of Possession","Zhentarim Skymage"];
    string[] private fs_blue = ["Hierophant","Mystic Theurge","Thaumaturgist","Demonologist","Disciple of Mephistopheles","Cosmic Descryer","Divine Emissary","Doomguide","Archmage","Bone Collector","Deathwarden Chanter","Eidoloncer core class","Henshin Mystic Henshin","Iaijutsu Master Iaijutsu","Mirumoto Niten Master Mirumoto Niten","Moto Avenger Moto","Siren","Candle Caster","Dragon Disciple","Elemental Savant","Mage of the Arcane Order","Doomdreamer","Mystic Theurge","Raumathari Battlemage","Ruby Disciple"];
    string[] private fs_orange = ["Diabolist","Disciple of Asmodeus","Disciple of Mammon","Dweomerkeeper","Elemental Archon","Goldeye","Ghost Slayer","Gnome Artificer","Incantatrix","Pyrokineticist","Spellsinger","Durthan","Nar Demonbinder","Telflammar Shadolord","Warpriest","Grim Psion","Lord of the Dead"];
    string[] private fs_red = ["Church Inquisitor","Master of Shrouds","Dreadmaster","Stormlord","Eye of Gruumsh","Queen of the Wild","Elven Bladesinger","Alienist","Mindbender","True Necromancer","Divine Agent","Sangehirn","Spellfire Hierophant"];

    string[] private ms_golden = ["Fatespinner"];
    string[] private ms_white = ["Harper","Cleric","Contemplative","ShintaoMonk","Warrior Skald"];
    string[] private ms_green = ["Hierophant","Virtuoso","Harper Priest","Hospitaler"];
    string[] private ms_blue = ["Virtuoso","Cancer Mage","Master Alchemist"];
    string[] private ms_orange = ["Acolyteof the Skin","KnightProtector of the Great Kingdom"];
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
    string[] private zs_orange = ["Eldritch Knight","Templar","Knight of Neraka","Knight of Solamnia","Animal Lord","Bear Warrior","Maho-Bujin","Maho-Tsukai","Outlaw of the Crimson Road","Royal Explorer","Temple Raider of Olidammara","Shou Disciple","Thayan Slaver","Berserk","Soldier of Light ","Life Eater"];
    string[] private zs_blue = ["Knight of the Chalice","Knight of the Middle Circle","Sacred Fist","Agent Retriever","Divine Seeker","Eidolon core class","Watch Detective","Windrider","Battle Maiden","Blade Dancer","Survivor","Waverider","Horde Breaker","Knight Errant of Silverymoon","Dread Pirate","Spellsword","Wayferer Guide","Aglarondan Griffonrider","Runescarred Berserker"];
    string[] private zs_green = ["Warrior of Darkness","Legionnaire of Steel","Guardian Paramount","Union Sentinel","Frenzied Berserker","Tamer of Beasts","Tempest","Urban Ranger variant Ranger core class","DaidojiBodyguard Daidoji","TattooedMonk","Breachgnome","DwarvenBattlerager","GreatRift Skyguard","OrcWarlord","Masterof Chains","MasterSamurai","Ravager","Warmaster","WeaponMaster","Mindknight"];
    string[] private zs_white = ["Barbarian","Fighter","Monk","Blackguard","Duelist","Arachne","Strifeleader","Waveservant","Purple Dragon Knight","Hida DefenderHida","Mantis Mercenary","Shiba Protector","Weapon Master ","Slayer","Vigilante","Cavalier","Devoted Defender","Drunken Master","Duelist","Fist of Hextor","Gladiator","Halfling Outrider","Lasher","Thyan Knight"];

    string[] private traits = ["Administrator","Elusive Shadow","Gamer","Genius","Grey Eminence","Immortal","Midas Touched","Mystic","Brilliant Strategist","Charismatic Negotiator","Fortune Builder","Mastermind Theologian","Naive Appeaser","Naive Enthusiast","Nudist","Possessed","Righteous","Skilled Tactician","Tolerant","Amateurish Plotter","Ambitious","Architect","Architectural Visionary","Benevolent","Body Purist","Graceful","Misguided Warrior","Physician","Scholarly Theologian","Speed Demon","Theologian","Too Smart","Tough Soldier","Zealous","Arbitrary","Ascetic","Asexual","Babbling Buffoon","Bisexual","Bloodlust","Body Modder","Born Inthe Purple","Fertile","Fierce Negotiator","Gay","Giant","Gregarious","Hedonist","Idolizer","Iron Gut","Keen Hearing","Lefthanded","Light Eater","Low Thirst","Martial Cleric","Out Of Shape","Outdoorsman","Playful","Robust","Schemer","Scholar","Secretive","Seducer","Seductress","Shy","Slow Reader","Strategist","Sturdy","Tortured Artist","Underhanded Rogue","Wakeful","Well Advised","Well Connected","Zealot","Pyromaniac","Quick Sleeper","Restless Sleeper","Scarred High","Severely Injured","Short Sighted","Silver Tongue","Sleepyhead","Smoker","Socializer","Tactical Genius","Troubled Pregnancy","Trusting","Twin","Undergrounder","Underweight","Very Underweight","Weak Stomach","Willful","Wroth","Bastard","Child Ofconsort","Dwarf","Feeble","Fever","Food Poisoning","Hard Pregnancy","Harelip","Has Measles","Has Small Pox","Has Tuberculosis","Has Typhoid Fever","Impaler","Indolent","Indulgent","Infection","Infirm","Lisp","Loose Lips","Obese","One Eyed","One Handed","One Legged","Stout","Stressed","Syphilitic"];


    string[] private preffixes = ["Able","Aggressive","Alert","Ambitious","Attractive","Candid","Careful","Devoted","Dutiful","Easy-Going","Efficient","Expressive","Expressivity","Forceful","Forgetful","Frank","Frugal","Genteel","Gullible","Happy","Hard-Working","Initiative","Inventive","Lazy","Liberal","Modest","Obedient","Porting","Reasonable","Selfless","Sensible","Sensitive","Sincere","Skeptical","Smart","Sociable","Sporting","Steady","Straightforward","Strict",
    "Strong-Willed","Sympathetic","Systematic","Talented","Trustful","Understanding","Unselfish","Active","Adroit","Analytical","Apprehensive","Argumentative","Bad-Tempered","Bossy","Brave","Brilliant","Caring","Charitable","Cheerful","Childish","Comical","Conceited","Confident","Conscientious","Contemplative","Cooperative","Dashing","Dedicated","Demanding","Dependable","Depressing","Determined","Diplomatic","Disciplined","Disorganized","Energetic","Enthusiastic","Faithful",
    "Friendly","Funny","Generous","Hearty","Helpful","Helpless"];

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


    function setMintPrice(uint256 newPrice) public onlyOwner {
        mintPrice = newPrice;
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

    function getDexterity(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].dexterity);
    }

    function getConstitution(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].constitution);
    }

    function getWisdom(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].wisdom);
    }

    function getIntelligence(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].intelligence);
    }

    function getCharisma(uint256 tokenId) public view returns (string memory) {
        return toString(attrsIndex[tokenId].charisma);
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
        string[38] memory parts;

        parts[0] = '<?xml version="1.0" encoding="UTF-8"?><svg width="750px" height="750px" viewBox="0 0 750 750" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><rect fill="#231D39" x="0" y="0" width="750" height="750"></rect><g transform="translate(60.000000, 35.000000)" fill="#FFFFFF" fill-rule="nonzero"><g transform="translate(0.000000, 15.000000)"><path d="M41.7518248,77.1077844 C39.1698869,73.5756487 36.8398454,69.9489022 34.7617003,66.2275449 C31.927866,60.9293413 29.3774152,55.4734531 27.1103478,49.8598802 L18.9866896,49.8598802 L18.9866896,77.1077844 L0,77.1077844 L0,1.89221557 L32.2112495,1.89221557 C35.0450837,1.95528942 37.878918,2.36526946 40.7127523,3.12215569 C44.1133534,4.13133733 47.2305711,5.77125749 50.0644053,8.04191617 C55.6061257,12.7093812 58.471447,18.6698603 58.6603693,25.9233533 C58.5973952,30.338523 57.4323744,34.3752495 55.165307,38.0335329 C52.5833691,41.9441118 49.214255,44.9716567 45.0579648,47.1161677 C47.7028768,52.0359281 50.5681981,56.798004 53.6539287,61.4023952 C57.2434521,66.7636727 60.9904108,71.9988024 64.8948046,77.1077844 L41.7518248,77.1077844 Z M18.9866896,36.2359281 L28.6217261,36.2359281 C31.6444826,36.299002 34.3208816,35.3844311 36.6509231,33.4922156 C38.6660942,31.6630739 39.7051667,29.3608782 39.7681408,26.5856287 C39.7051667,23.8734531 38.6031201,21.6027944 36.4620009,19.7736527 C34.1949334,18.0075848 31.6129956,17.093014 28.7161872,17.0299401 L18.9866896,17.0299401 L18.9866896,36.2359281 Z"></path><path d="M106.457707,20.057485 C110.173179,21.3189621 113.447832,23.2742515 116.281666,25.9233533 C119.052526,28.7616766 121.130671,32.041517 122.516101,35.7628743 C124.02748,39.9888224 124.783169,44.3409182 124.783169,48.8191617 C124.783169,53.360479 124.02748,57.7441118 122.516101,61.9700599 C121.130671,65.6914172 119.052526,68.9397206 116.281666,71.7149701 C113.447832,74.4271457 110.173179,76.3824351 106.457707,77.5808383 C103.371977,78.4638723 100.254759,78.9369261 97.1060541,79 C93.8943753,78.9369261 90.7456705,78.4638723 87.6599399,77.5808383 C83.9444683,76.3824351 80.6383283,74.4271457 77.74152,71.7149701 C74.9706598,68.9397206 72.8925147,65.6914172 71.5070846,61.9700599 C69.9957063,57.7441118 69.2715042,53.360479 69.3344783,48.8191617 C69.2715042,44.3409182 69.9957063,39.9888224 71.5070846,35.7628743 C72.8925147,32.041517 74.9706598,28.7616766 77.74152,25.9233533 C80.6383283,23.2742515 83.9444683,21.3189621 87.6599399,20.057485 C90.7456705,19.1744511 93.8943753,18.7013972 97.1060541,18.6383234 C100.254759,18.7013972 103.371977,19.1744511 106.457707,20.057485 Z M100.8845,62.7269461 C102.081008,61.8439122 103.088593,60.7401198 103.907256,59.4155689 C104.788894,57.7756487 105.418635,56.0095808 105.796479,54.1173653 C106.048376,52.3512974 106.205811,50.5852295 106.268785,48.8191617 C106.205811,47.1161677 106.048376,45.3816367 105.796479,43.6155689 C105.418635,41.7233533 104.788894,39.9572854 103.907256,38.3173653 C103.088593,36.9928144 102.081008,35.889022 100.8845,35.005988 C99.687992,34.2491018 98.4285101,33.8391218 97.1060541,33.7760479 C95.6576499,33.8391218 94.366681,34.2491018 93.2331473,35.005988 C91.9736654,35.889022 90.9345928,36.9928144 90.1159296,38.3173653 C89.2342923,39.9572854 88.6045513,41.7233533 88.2267067,43.6155689 C87.9748104,45.3816367 87.8488622,47.1161677 87.8488622,48.8191617 C87.8488622,50.5852295 87.9748104,52.3512974 88.2267067,54.1173653 C88.6045513,56.0095808 89.2342923,57.7756487 90.1159296,59.4155689 C90.9345928,60.8031936 91.9736654,61.906986 93.2331473,62.7269461 C94.366681,63.4838323 95.6576499,63.8622754 97.1060541,63.8622754 C98.4285101,63.8622754 99.687992,63.4838323 100.8845,62.7269461 Z"></path><path d="M162.756548,77.8646707 C158.978102,78.6215569 155.168169,79 151.32675,79 C148.303993,78.9369261 145.438672,78.3692615 142.730786,77.297006 C140.274796,76.1616766 138.196651,74.5532934 136.49635,72.4718563 C134.79605,70.1381238 133.631029,67.5205589 133.001288,64.6191617 C132.434521,62.0331337 132.182625,59.3840319 132.245599,56.6718563 L132.245599,-8.40312517e-15 L150.759983,-8.40312517e-15 L150.759983,52.3197605 C150.634035,54.653493 150.759983,56.9241517 151.137827,59.1317365 C151.389724,60.4562874 152.019465,61.5285429 153.02705,62.348503 C153.971662,63.1053892 155.073708,63.5784431 156.33319,63.7676647 C157.844568,64.0199601 159.387434,64.0830339 160.961786,63.9568862 L162.756548,77.8646707 Z"></path><path d="M184.765994,53.6443114 C185.206813,56.6087824 186.560756,59.0371257 188.827823,60.9293413 C190.150279,61.938523 191.598683,62.6954092 193.173036,63.2 C194.93631,63.7045908 196.762559,63.9253493 198.651782,63.8622754 C201.170746,63.8622754 203.658222,63.5153693 206.114212,62.8215569 C208.633176,62.1277445 211.057679,61.1816367 213.38772,59.9832335 L217.449549,72.4718563 C214.23787,74.742515 210.711321,76.4139721 206.869901,77.4862275 C203.091456,78.4954092 199.281523,79 195.440103,79 C191.031916,79 186.812652,78.2115768 182.78231,76.6347305 C179.129813,75.0578842 175.949621,72.8187625 173.241735,69.9173653 C170.596823,66.7636727 168.7076,63.2 167.574066,59.2263473 C166.692429,55.8203593 166.25161,52.3512974 166.25161,48.8191617 C166.188636,44.2778443 166.881351,39.8311377 168.329755,35.4790419 C169.715185,31.7576846 171.79333,28.5093812 174.564191,25.7341317 C177.460999,23.0850299 180.798626,21.1928144 184.577072,20.057485 C187.725776,19.1744511 190.968942,18.7013972 194.306569,18.6383234 C197.329326,18.7013972 200.289108,19.1744511 203.185917,20.057485 C206.649492,21.1928144 209.672248,23.053493 212.254186,25.639521 C214.836124,28.4147705 216.756834,31.6 218.016316,35.1952096 C219.338772,39.3580838 220,43.6155689 220,47.9676647 C220,49.9229541 219.937026,51.8151697 219.811078,53.6443114 L184.765994,53.6443114 Z M202.524689,42.8586826 C202.398741,40.4618762 201.580077,38.3489022 200.068699,36.5197605 C198.368398,34.7536926 196.32174,33.8391218 193.928725,33.7760479 C191.472735,33.9021956 189.363103,34.8167665 187.599828,36.5197605 C185.899528,38.2858283 184.923429,40.3988024 184.671533,42.8586826 L202.524689,42.8586826 Z"></path></g><polygon transform="translate(95.392136, 15.110538) rotate(-62.153664) translate(-95.392136, -15.110538) " points="89.0944127 -5.31770227 101.68986 -5.31770227 101.68986 35.5387792 89.0944127 35.5387792"></polygon></g><text id="Male-Demons-Chaotic" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="60" y="212">';
        parts[1] = getGender(tokenId);
        parts[2] = '</tspan><tspan x="60" y="256">';
        parts[3] = getRace(tokenId);
        parts[4] = '</tspan><tspan x="60" y="300">';
        parts[5] = getElement(tokenId);
        parts[6] = '</tspan><tspan x="60" y="344" fill="';
        parts[7] = getColorFull(getOccupationColor(tokenId));
        parts[8] = '">';
        parts[9] = getOccupation(tokenId);
        parts[10] = '  ';
        parts[11] = getIcon(tokenId);
        parts[12] = '</tspan><tspan x="60" y="388" fill="';
        parts[13] = getTraitColor(tokenId, 1);
        parts[14] = '">';
        parts[15] = getTrait1(tokenId);
        parts[16] = '</tspan><tspan x="60" y="432" fill="';
        parts[17] = getTraitColor(tokenId, 2);
        parts[18] = '">';
        parts[19] = getTrait2(tokenId);
        parts[20] = '</tspan><tspan x="60" y="476" fill="';
        parts[21] = getTraitColor(tokenId, 3);
        parts[22] = '">';
        parts[23] = getTrait3(tokenId);
        parts[24] = '</tspan></text><text id="Str-Sta-Agi-Cha-Int-Shi" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="522" y="216">Str</tspan><tspan x="522" y="260">Sta</tspan><tspan x="522" y="304">Agi</tspan><tspan x="522" y="348">Cha</tspan><tspan x="522" y="392">Int</tspan><tspan x="522" y="436">Shi</tspan></text><text id="2-3-6-7-1-1" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="618" y="216">';
        parts[25] = getStrength(tokenId);
        parts[26] = '</tspan><tspan x="618" y="260">';
        parts[27] = getDexterity(tokenId);
        parts[28] = '</tspan><tspan x="618" y="304">';
        parts[29] = getConstitution(tokenId);
        parts[30] = '</tspan><tspan x="618" y="348">';
        parts[31] = getCharisma(tokenId);
        parts[32] = '</tspan><tspan x="618" y="392">';
        parts[33] = getIntelligence(tokenId);
        parts[34] = '</tspan><tspan x="618" y="436">';
        parts[35] = getWisdom(tokenId);
        parts[36] = '</tspan></text><line x1="490.5" y1="192.5" x2="490.5" y2="475.5" stroke="#979797" stroke-linecap="square"></line>';
        parts[37] = '</g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8],parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16],parts[17], parts[18], parts[19], parts[20], parts[21]));
        output = string(abi.encodePacked(output, parts[22], parts[23], parts[24],parts[25], parts[26], parts[27], parts[28]));
        output = string(abi.encodePacked(output, parts[29], parts[30], parts[31],parts[32], parts[33], parts[34]));
        output = string(abi.encodePacked(output, parts[35], parts[36], parts[37]));

        string memory atrrOutput = makeAttributeParts(getGender(tokenId), getRace(tokenId), getElement(tokenId), getIconName(tokenId), getColorName(tokenId));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Role #', toString(tokenId), '", "description": "Role is a seed, a seed account for Metaverse Game.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"', ',"attributes":', atrrOutput, '}'))));
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

    function claim(uint256 tokenId, uint256 genderId, uint256 raceId, uint256 elementId, uint256 strNum, uint256 dexNum, uint256 conNum, uint256 wisNum, uint256 chaNum, uint256 intNum) public payable nonReentrant {
        require(tokenId > 0 && tokenId <= 8000, "Token ID invalid");
        require(mintPrice <= msg.value, "Please pay mint fee");
        require(!_exists(tokenId), "Token ID invalid");
        require(genderId < genders.length, "genderId invalid");
        require(strNum + dexNum+ conNum+ wisNum+ chaNum+ intNum <= 30, "attributes num invalid");
        require(raceId < races.length, "raceId invalid");
        require(elementId < elements.length, "elementId invalid");

        attrsIndex[tokenId].gender = uint8(genderId);
        attrsIndex[tokenId].strength = uint8(strNum);
        attrsIndex[tokenId].dexterity = uint8(dexNum);
        attrsIndex[tokenId].constitution = uint8(conNum);
        attrsIndex[tokenId].wisdom = uint8(wisNum);
        attrsIndex[tokenId].charisma = uint8(chaNum);
        attrsIndex[tokenId].intelligence = uint8(intNum);
        attrsIndex[tokenId].race = uint8(raceId);
        attrsIndex[tokenId].element = uint8(elementId);

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

    constructor() ERC721("CryptoLoot", "CryptoLoot") Ownable() {
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