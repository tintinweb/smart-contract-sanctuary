/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// File: contracts/pets.sol

/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/


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


interface Role {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

interface Token721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}


contract Pets is ERC721Enumerable, ReentrancyGuard, Ownable {
    address public roleAddr;

    mapping(uint256 => mapping(uint256 => string[])) public mapList;
    mapping (uint256 => bool) public roleMints;
    mapping (uint256 => bool) public lootMints;
    mapping (uint256 => bool) public mlootMints;
    
    uint256 public lootDailyMintNum = 0;
    uint256 public mlootDailyMintNum = 0;
    uint256 public roleDailyMintNum = 0;
    uint256 public dailyMintBeginTime = 0;
    
    string[] public alignments = [
        "Lawful Good",
        "Neutral Good",
        "Chaotic Good",
        "Lawful Neutral",
        "Neutral",
        "Chaotic Neutral",
        "Lawful Evil",
        "Neutral Evil",
        "Chaotic Evil"
    ];
    
    string[] public aberrationGold = ["DeathKiss"];
    string[] public aberrationOrange = ["Aboleth","Gauth"];
    string[] public aberrationRed = ["Beholder","Gazer","Gazer Familiar"];
    string[] public aberrationBlue = ["Belashyrra","Berbalang","Blue Slaad","Choker","Dyrrn"];
    string[] public aberrationGreen = ["Chaos Quadrapod","Spawn Emissary","Flumph","Gingwatzim"];
    string[] public aberrationWhite = ["Balhannoth","Cloaker","Dolgaunt","Dolgrim"];
    
    string[] public beastGold = ["Ape"];
    string[] public beastOrange = ["Allosaurus","AxeBeak"];
    string[] public beastRed = ["Almiraj","Cave Badger","Hyena","Toad"];
    string[] public beastBlue = ["Badger","Walrus","Wasp","Weasel"];
    string[] public beastGreen = ["Black Bear","Diseased Giant Rat","Fastieth","Riding Lizard","Guthash"];
    string[] public beastWhite = ["Bat","Barnacle Bess","Elk","Deep Rothe","Flying Monkey","Crayfish"];
    
    string[] public celestialGold = ["Battleforce Angel"];
    string[] public celestialOrange = ["Empyrean"];
    string[] public celestialRed = ["Deva"];
    string[] public celestialBlue = ["Firemane Angel"];
    string[] public celestialGreen = ["Ashen Rider","Couatl"];
    string[] public celestialWhite = ["Aurelia","Fazrian","Felidar"];
    
    string[] public dragonGold = ["Sapphire Dragon","Faerie Dragon","Gold Dragon"];
    string[] public dragonOrange = ["Blue Dragon","Brass Dragon","Copper Dragon"];
    string[] public dragonRed = ["Dragon Tortoise","Dragon Turtle"];
    string[] public dragonBlue = ["Claugiyliamatar"];
    string[] public dragonGreen = ["Bronzefume"];
    string[] public dragonWhite = ["Black Dragon","Bronze Dragon","Green Dragon"];
    
    string[] public elementalGold = ["Dust Devil"];
    string[] public elementalOrange = ["Fire Elemental"];
    string[] public elementalRed = ["Azer","Dao","Dust Mephit"];
    string[] public elementalBlue = ["Arclight Phoenix","Earth Elemental","Flail Snail","Geonid"];
    string[] public elementalGreen = ["BigXorn","Chwinga","Efreeti","Fluxcharger","Frost Salamander"];
    string[] public elementalWhite = ["Air Elemental","Auril","Djinni","Elder Tempest","Galeb Duhr","Gargoyle"];
    
    string[] public feyGold = ["Dryad"];
    string[] public feyOrange = ["Annis Hag"];
    string[] public feyRed = ["Dusk Hag"];
    string[] public feyBlue = ["Alseid","Bheur Hag","Conclave Dryad"];
    string[] public feyGreen = ["Boggle"];
    string[] public feyWhite = ["Blink Dog"];
    
    string[] public giantGold = ["Doomwake Giant"];
    string[] public giantOrange = ["Bloodfray Giant","Cressaro"];
    string[] public giantRed = ["Cyclops","Fire Giant","Four-Armed Troll"];
    string[] public giantBlue = ["Duke Zalto","Estia","Ettin","Frost Giant"];
    string[] public giantGreen = ["Cinderhild","Cloud Giant","DireTroll","Failed Dragonpriest","Garra"];
    string[] public giantWhite = ["Blagothkus","Borborygmos","Carrion Ogre","Guh","Nosnra","Duchess Brimskarda"];
    
    string[] public oozeGold = ["Black Pudding"];
    string[] public oozeOrange = ["Elder Oblex"];
    string[] public oozeRed = ["Oblex"];
    string[] public oozeBlue = ["Gelatinous Cube"];
    string[] public oozeGreen = ["Gray Ooze"];
    string[] public oozeWhite = ["Glabbagool"];
    
    string[] public plantGold = ["Tree"];
    string[] public plantOrange = ["Shrub","Gas Spore"];
    string[] public plantRed = ["Zurkhwood"];
    string[] public plantBlue = ["Bodytaker Plant"];
    string[] public plantGreen = ["Assassin Vine","Zuggtmoy","Corpse Flower","Drow Spore","Grandfather Oak"];
    string[] public plantWhite = ["Duergar Spore"];

    string[] public traits = ["Sand Veil","Aroma Veil","Sticky Hold","Technician","Competitive","Download","Sand Stream","Ice Face","Big Pecks","Sheer Force","Cheek Pouch","Chilling Neigh","Pure Power","Beast Boost","Power Spot","Merciless","Damp","Thick Fat","Cotton Down","Magma Armor","Stakeout","Plus","Filter","Forewarn","Wandering Spirit","Natural Cure","Fairy Aura","Soundproof","Keen Eye","Adaptability","Dark Aura","Synchronize","Intimidate","Shadow Tag","Shields Down","Motor Drive","Ripen","Inner Focus","Battle Bond","Perish Body","Flare Boost","Justified","Stamina","Friend Guard","Rough Skin","Innards Out","Tangling Hair","Lightning Rod","Torrent","Scrappy","Volt Absorb","Swift Swim","Insomnia","Solar Power","Strong Jaw","Delta Stream","Simple","Color Change","Power Construct","Vital Spirit","Turboblaze","Reckless","Dragons Maw","Mirror Armor","Cloud Nine","Water Bubble","Parental Bond","Sturdy","Ice Body","Anger Point","Rock Head","Magician","Pixilate","Galvanize","Snow Cloak","Dauntless Shield","Quick Draw","Flash Fire","Truant"];
    
    string[] public classNames =["Ooze","Fey","Celestial","Plant","Dragon","Aberration","Beast","Elemental","Giant"];
    
    string[] public sizes = ["Gargantuan", "Huge", "Large", "Medium", "Small", "Tiny"];

    string[] public preffixes = ["Retro","celestial","cosmic","interstellar","alien","stellate","intergalactic","laser-equipped","hyperspatial","Superhero","Immutable","Invulnerable","Wallcrawling","Mental Projection","Mind Control","Intangible","volitant","steam-driven","Victorian","Brass-fitted","Gauge-fitted","retro-futuristic","Clockpunk","Dieselpunk","Decopunk","Atompunk","Steelpunk","Cassette futurism","steampunk","Retro Arcade","8-bit","hulking","Gunslinger","scoundrel","inscrutable","nightmarish","once-human","federal","fallen angel","resurrected","hybridized","crossbreed","cyberpunk","Mecha","robotic","humanoid","biomorphic","Metal","Ancient","Adult"];
    
    uint256[] public classScoreMatch = [5,12,20,29,40,52,64,80,99];
    
    uint256[] public petsColorMatch = [6,16,31,51,74,99];
        
    uint256[] public traitColorMatch = [4,11,22,33,49,79];
    
    bool public mintFlag = true;
    function mintForbid() public onlyOwner {
        mintFlag = false;
    }
    
    function setRoleAddr(address addr) public onlyOwner {
        roleAddr = addr;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getStrength(uint256 tokenId) public pure returns (string memory) {
        return toString(random(string(abi.encodePacked("pet_str", toString(tokenId)))) % 3);
    }
    
    function getDexterity(uint256 tokenId) public pure returns (string memory) {
        return toString(random(string(abi.encodePacked("pet_dex", toString(tokenId)))) % 3);
    }
    
    function getConstitution(uint256 tokenId) public pure returns (string memory) {
        return toString(random(string(abi.encodePacked("pet_con", toString(tokenId)))) % 3);
    }
    
    function getWisdom(uint256 tokenId) public pure returns (string memory) {
        return toString(random(string(abi.encodePacked("pet_wis", toString(tokenId)))) % 3);
    }
    
    function getCharisma(uint256 tokenId) public pure returns (string memory) {
        return toString(15 - random(string(abi.encodePacked("pet_str", toString(tokenId)))) % 3
            - random(string(abi.encodePacked("pet_dex", toString(tokenId)))) % 3
            - random(string(abi.encodePacked("pet_con", toString(tokenId)))) % 3
            - random(string(abi.encodePacked("pet_wis", toString(tokenId)))) % 3
            - random(string(abi.encodePacked("pet_int", toString(tokenId)))) % 3
            );
    }
    
    function getIntelligence(uint256 tokenId) public pure returns (string memory) {
        return toString(random(string(abi.encodePacked("pet_int", toString(tokenId)))) % 3);
    }
    
    function getAlignment(uint256 tokenId) public view returns (string memory) {
        return pluck2(tokenId, "pet_ali", alignments);
    }
    
    function getSize(uint256 tokenId) public view returns (string memory) {
        return pluck2(tokenId, "pet_size", sizes);
    }
    
    function getClass(uint256 tokenId) public view returns (string memory) {
        uint256 index = getClassType(tokenId);
        return classNames[index-1];
    }
    
    //@return 1~9
    function getClassType(uint256 tokenId) public view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("pet_class", toString(tokenId))));
        uint256 score = rand % 100;
        
        uint i = 0;
        for(; i < classScoreMatch.length; i++){
            if(score <= classScoreMatch[i]){
                break;
            }
        }
        return i+1;
    }
    
    function getSpecies(uint256 tokenId) public view returns (string memory) {
        return pluck1(tokenId);
    }
    
    //@return 1~6
    function getSpeciesColor(uint256 tokenId) public view returns (uint256) {
        uint256 rand2 = random(string(abi.encodePacked("pet_color", toString(tokenId))));
        uint256 colorScore = rand2 % 100;
        uint j = 0;
        for(; j < petsColorMatch.length; j++){
            if(colorScore <= petsColorMatch[j]){
                break;
            }
        }
        return j+1;
    }
    
    function getTrait(uint256 tokenId, uint index) public view returns (string memory) {
        string memory output = pluck2(tokenId, string(abi.encodePacked("pet_trait", toString(index))), traits);
        return string(abi.encodePacked('"', output, '"'));
    }
    
    function getTraitColor(uint256 tokenId, uint256 index) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("pet_trait_color", toString(index), toString(tokenId))));
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
    
    function getColorName(uint256 tokenId) public view returns (string memory) {
        uint256 typeIndex = getSpeciesColor(tokenId);
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
    
    function pluck1(uint256 tokenId) internal view returns (string memory) {
        uint256 classType = getClassType(tokenId);
        uint256 colorType = getSpeciesColor(tokenId);
        string[] memory sourceArray = mapList[classType][colorType];
        
        uint256 rand = random(string(abi.encodePacked("pet_item", toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        
        string memory prefix = preffixes[rand % preffixes.length];
        output = string(abi.encodePacked(prefix, ' ', output));
        return output;
    }
    
    function pluck2(uint256 tokenId, string memory keyPrefix, string[] memory dataList) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        uint256 index = rand % dataList.length;
        return dataList[index];
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[35] memory parts;
        parts[0] = '<?xml version="1.0" encoding="UTF-8"?><svg width="750px" height="750px" viewBox="0 0 750 750" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g stroke="none" stroke-width="1" fill="none" fill-rule="evenodd"><g id="Apple-TV" transform="translate(-1111.000000, -234.000000)"><g transform="translate(1111.000000, 234.000000)"><rect fill="#073142" x="0" y="0" width="750" height="750"></rect><text id="Class-Alignment-Size" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="78" y="194">';
        parts[1] = getClass(tokenId);
        parts[2] = '</tspan><tspan x="78" y="238">';
        parts[3] = getAlignment(tokenId);
        parts[4] = '</tspan><tspan x="78" y="282">';
        parts[5] = getSize(tokenId);
        parts[6] = '</tspan><tspan x="78" y="326" fill="';
        parts[7] = getColorFull(getSpeciesColor(tokenId));
        parts[8] = '">';
        parts[9] = getSpecies(tokenId);
        parts[10] = '</tspan><tspan x="78" y="370" fill="';
        parts[11] = getTraitColor(tokenId, 1);
        parts[12] = '">';
        parts[13] = getTrait(tokenId,1);
        parts[14] = '</tspan><tspan x="78" y="414" fill="';
        parts[15] = getTraitColor(tokenId, 2);
        parts[16] = '">';
        parts[17] = getTrait(tokenId,2);
        parts[18] = '</tspan><tspan x="78" y="458" fill="';
        parts[19] = getTraitColor(tokenId, 3);
        parts[20] = '">';
        parts[21] = getTrait(tokenId,3);
        parts[22] = '</tspan></text><text id="Str-Dex-Con-Cha-int" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="540" y="194">Str</tspan><tspan x="540" y="238">Dex</tspan><tspan x="540" y="282">Con</tspan><tspan x="540" y="326">Cha</tspan><tspan x="540" y="370">Int</tspan><tspan x="540" y="414">Wis</tspan></text><text id="2-3-6-7-1-1" font-family="Georgia" font-size="28" font-weight="normal" line-spacing="44" fill="#FFFFFF"><tspan x="636" y="194">';
        parts[23] = getStrength(tokenId);
        parts[24] = '</tspan><tspan x="636" y="238">';
        parts[25] = getDexterity(tokenId);
        parts[26] = '</tspan><tspan x="636" y="282">';
        parts[27] = getConstitution(tokenId);
        parts[28] = '</tspan><tspan x="636" y="326">';
        parts[29] = getCharisma(tokenId);
        parts[30] = '</tspan><tspan x="636" y="370">';
        parts[31] = getIntelligence(tokenId);
        parts[32] = '</tspan><tspan x="636" y="414">';
        parts[33] = getWisdom(tokenId);
        parts[34] = '</tspan></text><line x1="491.5" y1="170.5" x2="491.5" y2="453.5" stroke="#979797" stroke-linecap="square"></line><text transform="translate(71.66 97.84)" style="font-size:64px;fill:#fff;font-family:OpenSans-ExtraBold, Open Sans;font-weight:800">Pet</text><text transform="translate(181.1 76.53) scale(0.58)" style="font-size:64px;fill:#fff;font-family:OpenSans-ExtraBold, Open Sans;font-weight:800">s</text><polygon fill="#fff" points="120.49 46.55 124.48 39 148.96 51.93 144.97 59.48 120.49 46.55"/></g></g></g></svg>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        output = string(abi.encodePacked(output, parts[7], parts[8],parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16],parts[17], parts[18], parts[19], parts[20], parts[21]));
        output = string(abi.encodePacked(output, parts[22], parts[23], parts[24],parts[25], parts[26], parts[27], parts[28]));
        output = string(abi.encodePacked(output, parts[29], parts[30], parts[31],parts[32], parts[33], parts[34]));
        
        string memory atrrOutput = makeAttributeParts(getAlignment(tokenId), getClass(tokenId), getColorName(tokenId), getSize(tokenId));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Pets #', toString(tokenId), '", "description": "Pets are companions in pursuit of what Role sets fire to.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"', ',"attributes":', atrrOutput, '}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function makeAttributeParts(string memory ali, string memory class, string memory color, string memory size) internal pure returns (string memory){
        string[9] memory attrParts;
        attrParts[0] = '[{ "trait_type": "Size", "value": "';
        attrParts[1] = size;
        attrParts[2] = '" }, { "trait_type": "SpeciesColor", "value": "';
        attrParts[3] = color;
        attrParts[4] = '" }, { "trait_type": "Class", "value": "';
        attrParts[5] = class;
        attrParts[6] = '" }, { "trait_type": "Alignment", "value": "';
        attrParts[7] = ali;
        attrParts[8] = '" }]';
        
        return string(abi.encodePacked(attrParts[0], attrParts[1], attrParts[2], attrParts[3], attrParts[4], attrParts[5], attrParts[6], attrParts[7], attrParts[8]));
    }
    
    function roleClaim() public nonReentrant {
        uint256 roleNums = Role(roleAddr).balanceOf(_msgSender());
        require(roleNums > 0, "have no role token");
        
        uint256 dailyLimitTime = dailyMintBeginTime + 1 days;
        if(block.timestamp < dailyLimitTime) {
            require(roleDailyMintNum + roleNums < 2000, "role claim reach daily limit.");
        }

        uint realNum = 0;
        for(uint i = 0; i < roleNums; i++){
            uint256 roleTokenId = Role(roleAddr).tokenOfOwnerByIndex(_msgSender(), i);
            if(!roleMints[roleTokenId]){
                roleMints[roleTokenId] = true;
                _safeMint(_msgSender(), roleTokenId);
                realNum = realNum +1;
            }
        }
        
        roleDailyMintNum = roleDailyMintNum + realNum;
    }
    
    function refreshCommunityDailyMint() public onlyOwner {
        lootDailyMintNum = 0;
        mlootDailyMintNum = 0;
        roleDailyMintNum = 0;
        dailyMintBeginTime = block.timestamp;
    }
    
    function lootClaim(uint tokenId, uint lootId) public nonReentrant {
        require(tokenId >= 10000  && tokenId <= 12000, "Token ID invalid for claim");
        require(!_exists(tokenId), "Token ID invalid");
        require(!lootMints[lootId], "already minted");
        require(Token721(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7).ownerOf(lootId) == _msgSender(), "not the loot owner");
        
        uint256 dailyLimitTime = dailyMintBeginTime + 1 days;
        if(block.timestamp < dailyLimitTime) {
            require(lootDailyMintNum < 400, "loot mint reach daily limit.");
        }
        lootDailyMintNum = lootDailyMintNum + 1;
        lootMints[lootId] = true;
        _safeMint(_msgSender(), tokenId);
    }
    
    function mlootClaim(uint tokenId, uint mlootId) public nonReentrant {
        require(tokenId > 12000  && tokenId <= 14000, "Token ID invalid for claim");
        require(!_exists(tokenId), "Token ID invalid");
        require(!mlootMints[mlootId], "already minted");
        require(Token721(0x1dfe7Ca09e99d10835Bf73044a23B73Fc20623DF).ownerOf(mlootId) == _msgSender(), "not the mloot owner");
        
        uint256 dailyLimitTime = dailyMintBeginTime + 1 days;
        if(block.timestamp < dailyLimitTime) {
            require(mlootDailyMintNum < 400, "loot mint reach daily limit.");
        }
        mlootDailyMintNum = mlootDailyMintNum + 1;
        mlootMints[mlootId] = true;
        _safeMint(_msgSender(), tokenId);
    }

    function mint(uint tokenId) public nonReentrant payable {
        require(mintFlag, "mint forbid");
        require(tokenId > 14000  && tokenId <= 19000, "Token ID invalid for mint");
        require(!_exists(tokenId), "Token ID invalid");
        require(msg.value >= 10000000000000000, "not enough funds to purchase.");
        
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint tokenId, address addr) public nonReentrant onlyOwner {
        require(tokenId > 19000  && tokenId <= 20000, "Token ID invalid for mint");
        require(!_exists(tokenId), "Token ID invalid");

        _safeMint(addr, tokenId);
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
    
    constructor() ERC721("Pets", "PETS") Ownable() {
        roleAddr = 0xCd4D337554862F9bC9ffffB67465B7d643E4E3ad;
        mapList[1][1] = oozeGold;
        mapList[1][2] = oozeOrange;
        mapList[1][3] = oozeRed;
        mapList[1][4] = oozeBlue;
        mapList[1][5] = oozeGreen;
        mapList[1][6] = oozeWhite;
        
        mapList[2][1] = feyGold;
        mapList[2][2] = feyOrange;
        mapList[2][3] = feyRed;
        mapList[2][4] = feyBlue;
        mapList[2][5] = feyGreen;
        mapList[2][6] = feyWhite;
        
        mapList[3][1] = celestialGold;
        mapList[3][2] = celestialOrange;
        mapList[3][3] = celestialRed;
        mapList[3][4] = celestialBlue;
        mapList[3][5] = celestialGreen;
        mapList[3][6] = celestialWhite;
        
        mapList[4][1] = plantGold;
        mapList[4][2] = plantOrange;
        mapList[4][3] = plantRed;
        mapList[4][4] = plantBlue;
        mapList[4][5] = plantGreen;
        mapList[4][6] = plantWhite;
        
        mapList[5][1] = dragonGold;
        mapList[5][2] = dragonOrange;
        mapList[5][3] = dragonRed;
        mapList[5][4] = dragonBlue;
        mapList[5][5] = dragonGreen;
        mapList[5][6] = dragonWhite;
        
        mapList[6][1] = aberrationGold;
        mapList[6][2] = aberrationOrange;
        mapList[6][3] = aberrationRed;
        mapList[6][4] = aberrationBlue;
        mapList[6][5] = aberrationGreen;
        mapList[6][6] = aberrationWhite;
       
        mapList[7][1] = beastGold;
        mapList[7][2] = beastOrange;
        mapList[7][3] = beastRed;
        mapList[7][4] = beastBlue;
        mapList[7][5] = beastGreen;
        mapList[7][6] = beastWhite;
        
        mapList[8][1] = elementalGold;
        mapList[8][2] = elementalOrange;
        mapList[8][3] = elementalRed;
        mapList[8][4] = elementalBlue;
        mapList[8][5] = elementalGreen;
        mapList[8][6] = elementalWhite;
        
        mapList[9][1] = giantGold;
        mapList[9][2] = giantOrange;
        mapList[9][3] = giantRed;
        mapList[9][4] = giantBlue;
        mapList[9][5] = giantGreen;
        mapList[9][6] = giantWhite;


    }
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
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