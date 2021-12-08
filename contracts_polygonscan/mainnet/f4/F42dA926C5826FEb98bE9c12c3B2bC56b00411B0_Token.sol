/**
 *Submitted for verification at polygonscan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//import "../utils/Context.sol";
/**
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


//import "@openzeppelin/contracts/access/Ownable.sol";
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


//import "./IERC721Receiver.sol";
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


//import "./IERC165.sol";
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


//import "../../utils/introspection/ERC165.sol";
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


//import "./IERC721.sol";
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


//import "./extensions/IERC721Metadata.sol";
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


//import "../../utils/Address.sol";
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

//import "../../utils/Strings.sol";

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


//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
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
                return retval == IERC721Receiver.onERC721Received.selector;
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


//import "./Lib/LibStr.sol";
//--------------------------
// 文字列ライブラリ
//--------------------------
library LibStr {
    //---------------------------
    // 数値を１０進数文字列にして返す
    //---------------------------
    function numToStr( uint256 val ) internal pure returns (bytes memory) {
        // 数字の桁
        uint256 len = 1;
        uint256 temp = val;
        while( temp >= 10 ){
            temp = temp / 10;
            len++;
        }

        // バッファ確保
        bytes memory buf = new bytes(len);

        // 数字の出力
        temp = val;
        for( uint256 i=0; i<len; i++ ){
            uint c = 48 + (temp%10);
            buf[len-(i+1)] = bytes1(uint8(c));
            temp /= 10;
        }

        return( buf );
    }

    //----------------------------
    // 数値を１６進数文字列にして返す
    //----------------------------
    function numToStrHex( uint256 val, uint256 zeroFill ) internal pure returns (bytes memory) {
        // 数字の桁
        uint256 len = 1;
        uint256 temp = val;
        while( temp >= 16 ){
            temp = temp / 16;
            len++;
        }

        // ゼロ埋め桁数
        uint256 padding = 0;
        if( zeroFill > len ){
            padding = zeroFill - len;
        }

        // バッファ確保
        bytes memory buf = new bytes(padding + len);

        // ０埋め
        for( uint256 i=0; i<padding; i++ ){
            buf[i] = bytes1(uint8(48));
        }

        // 数字の出力
        temp = val;
        for( uint256 i=0; i<len; i++ ){
            uint c = temp % 16;    
            if( c < 10 ){
                c += 48;
            }else{
                c += 87;
            }
            buf[padding+len-(i+1)] = bytes1(uint8(c));
            temp /= 16;
        }

        return( buf );
    }
}


//import "./Lib/LibB64.sol";
/// [MIT License]
/// @title LibB64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library LibB64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (bytes memory) {
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

        return result;
    }
}


//-----------------------------------
// トークン
//-----------------------------------
contract Token is Ownable, ERC721 {
    //-----------------------------------------
    // 定数
    //-----------------------------------------
    string constant private TOKEN_NAME = "Pixel Work 4-bit";
    string constant private TOKEN_SYMBOL = "PW4b";
    uint256 constant private TOKEN_ID_OFS = 1;
    uint256 constant private CREATOR_ID_OFS = 1;
    uint256 constant private COL_IN_PAL = 16;
    uint256 constant private COL_STR_LEN = 6;
    uint256 constant private PAL_STR_LEN = COL_IN_PAL*COL_STR_LEN;
    uint256 constant private DOT_WIDTH = 16;
    uint256 constant private DOT_HEIGHT = 16;
    uint256 constant private DOT_STR_LEN = DOT_WIDTH*DOT_HEIGHT;
    string[] private _strArrX = ["42","61","80","99","118","137","156","175","194","213","232","251","270","289","308","327"];
    string[] private _strArrY = ["20","39","58","77","96","115","134","153","172","191","210","229","248","267","286","305"];

    //-----------------------------------------
    // ストレージ
    //-----------------------------------------
    // token
    uint256[] private _arrBirthday;
    address[] private _arrCreator;
    bytes[COL_IN_PAL][] private _arrPal;
    bytes[] private _arrDot;
    bytes[] private _arrPalCount;

    // creator
    address[] private _arrCreatorForId;
    mapping( address => uint256) private _mapCreatorId;
    mapping( address => uint256[] ) private _mapCreatorTokens;

    //-----------------------------------------
    // 管理用
    //-----------------------------------------
    mapping( uint256 => bool ) private _mapFrozenToken;
    mapping( address => bool ) private _mapFrozenUser;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor() Ownable() ERC721( TOKEN_NAME, TOKEN_SYMBOL ) {
    }

    //-----------------------------------------
    // [external] トークン数
    //-----------------------------------------
    function totalToken() external view returns (uint256) {
        return( _arrBirthday.length );
    }

    //-----------------------------------------
    // [external] クリエイター数
    //-----------------------------------------
    function totalCreator() external view returns (uint256) {
        return( _arrCreatorForId.length );
    }

    //-----------------------------------------
    // [external] 作成日時の取得
    //-----------------------------------------
    function tokenBirthday( uint256 tokenId ) external view returns (uint256) {
        require( _exists( tokenId ), "nonexistent token" );

        return( _arrBirthday[tokenId-TOKEN_ID_OFS] );
    }

    //-----------------------------------------
    // [external] クリエイターの取得
    //-----------------------------------------
    function tokenCreator( uint256 tokenId ) external view returns (address) {
        require( _exists( tokenId ), "nonexistent token" );

        return( _arrCreator[tokenId-TOKEN_ID_OFS] );
    }

    //-----------------------------------------
    // [external] 画像データの取得
    //-----------------------------------------
    function tokenImage( uint256 tokenId ) external view returns (string memory) {
        require( _exists( tokenId ), "nonexistent token" );

        bytes memory arrDot = _arrDot[tokenId-TOKEN_ID_OFS];
        bytes[COL_IN_PAL] memory arrPal = _arrPal[tokenId-TOKEN_ID_OFS];

        bytes[DOT_HEIGHT] memory bytesLines;
        for( uint256 y=0; y<DOT_HEIGHT; y++ ){
            bytesLines[y] = abi.encodePacked( arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+0]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+1]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+2]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+3]))] );
            bytesLines[y] = abi.encodePacked( bytesLines[y], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+4]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+5]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+6]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+7]))] );
            bytesLines[y] = abi.encodePacked( bytesLines[y], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+8]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+9]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+10]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+11]))] );
            bytesLines[y] = abi.encodePacked( bytesLines[y], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+12]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+13]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+14]))], arrPal[uint256(uint8(arrDot[DOT_WIDTH*y+15]))] );
        }

        bytesLines[0] = abi.encodePacked( bytesLines[0], bytesLines[1], bytesLines[2], bytesLines[3] );
        bytesLines[4] = abi.encodePacked( bytesLines[4], bytesLines[5], bytesLines[6], bytesLines[7] );
        bytesLines[8] = abi.encodePacked( bytesLines[8], bytesLines[9], bytesLines[10], bytesLines[11] );
        bytesLines[12] = abi.encodePacked( bytesLines[12], bytesLines[13], bytesLines[14], bytesLines[15] );

        return( string( abi.encodePacked( bytesLines[0], bytesLines[4], bytesLines[8], bytesLines[12] ) ) );
    }

    //-----------------------------------------
    // [external] クリエイターのIDの取得
    //-----------------------------------------
    function creatorId( address creator ) external view returns (uint256) {
        require( creator != address(0), "invalid address" );

        return( _mapCreatorId[creator] );
    }

    //-----------------------------------------
    // [external] クリエイターアドドレスの取得
    //-----------------------------------------
    function creatorAddress( uint256 cId ) external view returns (address) {
        require( cId >= CREATOR_ID_OFS && cId < (_arrCreatorForId.length+CREATOR_ID_OFS), "nonexistent creator" );

        return( _arrCreatorForId[cId-CREATOR_ID_OFS] );
    }

    //-----------------------------------------
    // [external] クリエイターの作成したトークン数
    //-----------------------------------------
    function creatorCreatedNum( address creator ) external view returns (uint256) {
        require( creator != address(0), "invalid address" );

        return( _mapCreatorTokens[creator].length );
    }

    //-----------------------------------------
    // [external] クリエイターの作成したトークン一覧
    //-----------------------------------------
    function creatorTokenList( address creator, uint256 pageSize, uint256 pageOfs ) external view returns (uint256[] memory) {
        require( creator != address(0), "invalid address" );

        uint256 size = _mapCreatorTokens[creator].length;
        uint256 startAt = pageOfs * pageSize;
        if( size < (startAt + pageSize) ){
            if( size <= startAt ){
                pageSize = 0;
            }else{
                pageSize = size - startAt;
            }
        }

        uint256[] memory list = new uint256[](pageSize);

        // 新しく作成したトークンから抽出
        for( uint256 i=0; i<pageSize; i++ ){
            list[i] = _mapCreatorTokens[creator][size-(startAt+i+1)];
        }

        return( list );
    }

    //-----------------------------------------
    // [public] 凍結されたトークンか？
    //-----------------------------------------
    function isTokenFrozen( uint256 tokenId ) public view returns (bool) {
        require( _exists( tokenId ), "nonexistent token" );

        return( _mapFrozenToken[tokenId] );
    }

    //-----------------------------------------
    // [external/onlyOwner] トークンの凍結
    //-----------------------------------------
    function freezeToken( uint256 tokenId, bool flag ) external onlyOwner {
        require( _exists( tokenId ), "nonexistent token" );

        if( flag ){
            _mapFrozenToken[tokenId] = true;
        }else{
            delete _mapFrozenToken[tokenId];
        }
    }

    //-----------------------------------------
    // [public] 凍結されたユーザーか？
    //-----------------------------------------
    function isUserFrozen( address user ) public view returns (bool) {
        require( user != address(0), "invalid address" );

        return( _mapFrozenUser[user] );
    }

    //-----------------------------------------
    // [external/onlyOwner] ユーザーの凍結
    //-----------------------------------------
    function freezeUser( address user, bool flag ) external onlyOwner {
        require( user != address(0), "invalid address" );

        if( flag ){
            _mapFrozenUser[user] = true;
        }else{
            delete _mapFrozenUser[user];
        }
    }

    //-----------------------------------------
    // [external] トークンの発行
    //-----------------------------------------
    function mintToken( string calldata palStr, string calldata dotStr ) external {
        // 凍結されているか？
        require( ! isUserFrozen( msg.sender ), "not available" );

        // パレットは有効か？
        bytes memory arrPal = bytes(palStr);
        require( arrPal.length == PAL_STR_LEN, "palStr: invalid length" );

        for( uint256 i=0; i<PAL_STR_LEN; i++ ){
            uint256 c = uint256(uint8(arrPal[i]));
            if( c >= 48 && c <= 57 ){ continue; }
            if( c >= 65 && c <= 70 ){ continue; }
            if( c >= 97 && c <= 102 ){ continue; }
            require( false, "palStr: invalid char" );
        }

        // 利用数の枠
        bytes memory counts = new bytes(COL_IN_PAL);

        // ドットは有効か？
        bytes memory arrDot = bytes(dotStr);
        require( arrDot.length == DOT_STR_LEN, "dotStr: invalid length" );

        for( uint256 i=0; i<DOT_STR_LEN; i++ ){
            uint256 c = uint256(uint8(arrDot[i]));
            if( c >= 48 && c <= 57 ){ c -= 48; }
            else if( c >= 65 && c <= 70 ){ c -= 55; }
            else if( c >= 97 && c <= 102 ){ c -= 87; }
            else{ require( false, "dotStr: invalid char" ); }

            arrDot[i] = bytes1(uint8(c));
            counts[c] = bytes1(uint8(uint256(uint8(counts[c]))+1));
        }
        
        //--------------------------
        // ここまできたらチェック完了
        //--------------------------

        // 発行
        uint256 tokenId = TOKEN_ID_OFS + _arrBirthday.length;
        _safeMint( msg.sender, tokenId );

        // トークン情報
        _arrBirthday.push( block.timestamp );
        _arrCreator.push( msg.sender );
        bytes[COL_IN_PAL] memory pal;
        for( uint256 i=0; i<COL_IN_PAL; i++ ){
            pal[i] = new bytes(COL_STR_LEN);
            for( uint256 j=0; j<COL_STR_LEN; j++ ){
                pal[i][j] = arrPal[COL_STR_LEN*i+j];
            }
        }
        _arrPal.push( pal );
        _arrDot.push( arrDot );
        _arrPalCount.push( counts );

        // クリエイター情報
        uint256 cId = _mapCreatorId[msg.sender];
        if( cId < CREATOR_ID_OFS ){
            cId = CREATOR_ID_OFS + _arrCreatorForId.length;
            _arrCreatorForId.push( msg.sender );
            _mapCreatorId[msg.sender] = cId;
        }

        _mapCreatorTokens[msg.sender].push( tokenId );
    }

    //-----------------------------------------
    // [public] トークンURI
    //-----------------------------------------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "nonexistent token" );

        // 凍結されているか？
        if( isTokenFrozen( tokenId ) ){
            return( string( _createFrozenMetadata( tokenId ) ) );
        }

        // メタデータを返す
        bytes memory bytesMeta = _createMetadata( tokenId );
        bytes memory bytesSvgHeader = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .fn{ font-family: serif; font-size:15px; fill:#eee;} .fc{ font-family: serif; font-size:24px; fill:#eee;}</style><rect x="0" y="0" width="350" height="350" fill="#333" />';
        bytes memory bytesSvgPal = _createSvgPal( tokenId );
        bytes memory bytesSvgDot = _createSvgDot( tokenId );
        bytes memory bytesSvgHooter = _createSvgFooter( tokenId );
        bytes memory bytesSvg = abi.encodePacked( bytesSvgHeader, bytesSvgPal, bytesSvgDot, bytesSvgHooter );

        // polygon/mumbai だと下記はダメ
        //return( string( abi.encodePacked( 'data:application/json;charset=UTF-8,{', bytesMeta, '"image": "data:image/svg+xml;base64,', LibB64.encode( bytesSvg ), '"}' ) ) );

        bytesMeta = abi.encodePacked( '{', bytesMeta, '"image": "data:image/svg+xml;base64,', LibB64.encode( bytesSvg ), '"}' );
        return( string( abi.encodePacked( 'data:application/json;base64,', LibB64.encode( bytesMeta ) ) ) );
    }

    //--------------------------------------
    // [internal] 凍結されたmetadataの作成
    //--------------------------------------
    function _createFrozenMetadata( uint256 tokenId ) internal pure returns( bytes memory ){        
        bytes memory bytesName = abi.encodePacked( '"name":"', TOKEN_SYMBOL, ' #', LibStr.numToStr( tokenId ), '",' );
        bytes memory bytesDescription = abi.encodePacked( '"description":"not available",' );
        bytes memory bytesSvg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .f{ font-family: serif; font-size:200px; fill:#eee;}</style><rect x="0" y="0" width="350" height="350" fill="#333" /><text x="175" y="250" text-anchor="middle" class="f">?</text></svg>';

        // polygon/mumbai だと下記はダメ
        //return( abi.encodePacked( 'data:application/json;charset=UTF-8,{', bytesName, bytesDescription, '"image": "data:image/svg+xml;base64,', LibB64.encode( bytesSvg ), '"}' ) );

        bytes memory bytesMeta = abi.encodePacked( '{', bytesName, bytesDescription, '"image": "data:image/svg+xml;base64,', LibB64.encode( bytesSvg ), '"}' );
        return( abi.encodePacked( 'data:application/json;base64,', LibB64.encode( bytesMeta ) ) );
    }

    //--------------------------------------
    // [internal] metadataの作成
    //--------------------------------------
    function _createMetadata( uint256 tokenId ) internal view returns( bytes memory ){        
        bytes memory bytesId = LibStr.numToStr( tokenId );
        bytes memory bytesBirthday = LibStr.numToStr( _arrBirthday[tokenId-TOKEN_ID_OFS] );
        bytes memory bytesCreator = LibStr.numToStrHex( uint256(uint160(_arrCreator[tokenId-TOKEN_ID_OFS])), 40 );
        bytes memory bytesName = abi.encodePacked( '"name":"', TOKEN_SYMBOL, ' #', bytesId, '",' );
        bytes memory bytesDescription = abi.encodePacked( '"description":"', TOKEN_NAME, ' created by 0x', bytesCreator, '",' );
        bytes memory bytesAttributes = abi.encodePacked( '"attributes":[', '{"trait_type":"creator","value":"0x', bytesCreator, '"},', '{"display_type":"date","trait_type":"birthday","value":', bytesBirthday, '}],');
        return( abi.encodePacked( bytesName, bytesDescription, bytesAttributes ) );
    }

    //--------------------------------------
    // [internal] svgのパレット作成
    //--------------------------------------
    function _createSvgPal( uint256 tokenId ) internal view returns( bytes memory ){
        bytes[COL_IN_PAL] memory arrPal = _arrPal[tokenId-TOKEN_ID_OFS];
        bytes memory arrPalCount = _arrPalCount[tokenId-TOKEN_ID_OFS];
 
        bytes memory bytesUse;
        uint256 y = 20;
        for( uint256 i=0; i<COL_IN_PAL; i++ ){
            uint256 use = uint256(uint8(arrPalCount[i]));
            if( use <= 0 ){
                continue;
            }

            bytesUse = abi.encodePacked( bytesUse, '<rect x="5" y="', LibStr.numToStr(y) ,'" width="30" height="', LibStr.numToStr(use) ,'" fill="#', arrPal[i], '" />' );
            y += use;
        }

        return( abi.encodePacked( '<rect x="3" y="18" width="34" height="260" fill="#111" />', bytesUse ) );
    }

    //--------------------------------------
    // [internal] svgのドット作成
    //--------------------------------------
    function _createSvgDot( uint256 tokenId ) internal view returns( bytes memory ){
        bytes memory arrDot = _arrDot[tokenId-TOKEN_ID_OFS];
        bytes[COL_IN_PAL] memory arrPal = _arrPal[tokenId-TOKEN_ID_OFS];

        bytes[DOT_HEIGHT] memory bytesLines;
        for( uint256 y=0; y<DOT_HEIGHT; y++ ){
            for( uint256 x=0; x<DOT_WIDTH; x++ ){
                uint256 c = uint256(uint8(arrDot[DOT_WIDTH*y+x]));
                bytesLines[y] = abi.encodePacked( bytesLines[y], '<rect x="', _strArrX[x], '" y="', _strArrY[y], '" width="18" height="18" fill="#', arrPal[c], '" />' );
            }
        }

        bytesLines[0] = abi.encodePacked( bytesLines[0], bytesLines[1], bytesLines[2], bytesLines[3] );
        bytesLines[4] = abi.encodePacked( bytesLines[4], bytesLines[5], bytesLines[6], bytesLines[7] );
        bytesLines[8] = abi.encodePacked( bytesLines[8], bytesLines[9], bytesLines[10], bytesLines[11] );
        bytesLines[12] = abi.encodePacked( bytesLines[12], bytesLines[13], bytesLines[14], bytesLines[15] );
        return( abi.encodePacked( '<rect x="40" y="18" width="307" height="307" fill="#111" />', bytesLines[0], bytesLines[4], bytesLines[8], bytesLines[12] ) );
    }

    //--------------------------------------
    // [internal] svgのフッターの作成
    //--------------------------------------
    function _createSvgFooter( uint256 tokenId ) internal view returns( bytes memory ){
        bytes memory bytesId = LibStr.numToStr( tokenId );
        bytes memory bytesCreator = LibStr.numToStrHex( uint256(uint160(_arrCreator[tokenId-TOKEN_ID_OFS])), 40 );
        return( abi.encodePacked( '<text x="347" y="16" text-anchor="end" class="fn">', TOKEN_NAME, ' #', bytesId ,'</text><text x="2" y="346" textLength="55" lengthAdjust="spacingAndGlyphs" class="fn">created by</text><text x="60" y="347" textLength="288" lengthAdjust="spacingAndGlyphs" class="fc">0x', bytesCreator, '</text></svg>' ) );
    }
    
}