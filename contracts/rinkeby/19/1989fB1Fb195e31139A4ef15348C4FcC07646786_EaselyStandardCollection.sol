/**
 *Submitted for verification at Etherscan.io on 2021-10-12
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
    address internal _owner;

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

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
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

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

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721URIStorage, IERC721Enumerable {
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
        require(index < ERC721.balanceOf(owner), "Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "Enumerable: global index out of bounds");
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

/**
 * @dev External interface of the EaselyContractInitializer. Formatted to enable ContractFactory
 * to have a single method that can deploy a wide variety of different contracts.
 */
interface IEaselyContractInitializer {
    function init(bool[8] memory bools, address[8] memory addresses, uint256[32] memory uints, string[8] memory strings) external;
}

/**
 * @dev External interface of the EaselyPayout contract
 */
interface IEaselyPayout {
    /**
     * @dev Takes in a payable amount and splits it among the given royalties. 
     * Also takes a cut of the payable amount depending on the sender and the primaryPayout address.
     * Ensures that this method never splits over 100% of the payin amount.
     */
    function splitPayable(address primaryPayout, address[] memory royalties, uint256[] memory bps) external payable;
}

/**
 * @dev This implements three things on top of the standard ERC extensions.
 * 1. The ability for contract owners to mint claimable (burnable) tokens that can optionally
 *    generate another token.
 * 2. The ability for current token owners to create ascending auctions, which locks the token for
 *    the duration of the auction.
 * 3. The ability for current token owners to lazily sell their tokens in this contract instead of 
 *    needing a marketplace contract.
 */
contract EaselyStandardCollection is ERC721Enumerable, Ownable, IEaselyContractInitializer {    
    using Strings for uint256;

    /**
     * @dev Auction structure that includes:
     * 
     * @param address topBidder - Current top bidder who has already paid the price param below. Is
     *        initialized with address(0) when there have been no bids. When a bidder gets outBid,
     *        the old topBidder will get the price they paid returned.
     * @param uint256 price - Current top price paid by the topBidder.
     * @param uint256 startTimestamp - When the auction can start getting bidded on.
     * @param uint256 endTimestamp - When the auction can no longer get bid on.
     * @param uint256 minBidIncrement - The minimum each new bid has to be greater than the previous
     *        bid in order to be the next topBidder.
     * @param uint256 minLastBidDuration - The minimum time each bid must hold the highest price before
     *        the auction can settle. If people keep bidding, the auction can last for much longer than 
     *        the initial endTimestamp, and endTimestamp will continually be updated.
     */
    struct Auction {
        address topBidder;
        uint256 price;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 minBidIncrement;
        uint256 minLastBidDuration;
    }

    /* Determines if every token in this contract is burnable/claimable by default */
    bool public burnable;
    bool private hasInit = false;

    /* see {IEaselyPayout} for more */
    address public payoutContractAddress = 0xc495c35C7220D93aA3CA77E8D394bdf7241257d6;
    /* Optional addresses to distribute royalties for primary sales of this collection */
    address[] public royalties;
    /* Optional basis points for above royalties addresses for primary sales of this collection */
    uint256[] public royaltiesBPS;
    /* Optional basis points for the owner for secondary sales of this collection */
    uint256 public secondaryOwnerBPS;
    uint256 private nextTokenId = 0;
    /* Optional basis points for the owner for secondary sales of this collection */
    uint256 public timePerDecrement = 300;
    uint256 public constant maxRoyaltiesBPS = 9500;
    uint256 public constant maxSecondaryBPS = 1000;

    /* Mapping if a tokenId has an active auction or not */
    mapping(uint256 => Auction) private _tokenIdToAuction;
    /* Mapping if a tokenId can be claimed */
    mapping(uint256 => bool) private _tokenIdIsClaimable;
    /* Mapping for what the generated token's URI is if the token is claim */
    mapping(uint256 => string) private _tokenIdToPostClaimURI;
    /* Mapping to the active version for all signed transactions */
    mapping(address => uint256) private _addressToActiveVersion;
    /* Cancelled or finalized sales by hash to determine buyabliity */
    mapping(bytes32 => bool) private _cancelledOrFinalizedSales;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 startingTimestamp, uint256 endingTimestamp, uint256 minBidIncrement, uint256 minLastBidDuration, address seller);
    event AuctionEndTimeAltered(uint256 tokenId, uint256 endTime, address seller);
    event AuctionCancelled(uint256 tokenId, address seller);
    event AuctionBidded(uint256 tokenId, uint256 newPrice, address bidder);
    event AuctionSettled(uint256 tokenId, uint256 price, address buyer, address seller);

    event ClaimableClaimed(address claimer, uint256 originalTokenId, uint256 newTokenId, string originalIpfs);
    event SaleCancelled(bytes32 hash);
    event SaleCompleted(bytes32 hash);

    /**
     * @dev Constructor function
     */
    constructor(
        bool[8] memory bools, address[8] memory addresses, uint256[32] memory uints, string[8] memory strings
    ) ERC721(strings[0], strings[1]) {
        addresses[0] = _msgSender();
        _init(bools, addresses, uints, strings);
    }

    function init(
        bool[8] memory bools, 
        address[8] memory addresses, 
        uint256[32] memory uints, 
        string[8] memory strings
    ) external override {
        _init(bools, addresses, uints, strings);
    }

    function _init(
        bool[8] memory bools, 
        address[8] memory addresses, 
        uint256[32] memory uints, 
        string[8] memory strings
    ) internal {
        require(!hasInit, "Already has be initiated");
        hasInit = true;
        burnable = bools[0];
        
        _owner = addresses[0];
        address[4] memory royaltiesAddrs = [addresses[1], addresses[2], addresses[3], addresses[4]];
        // Only used for local testing.
        // payoutContractAddress = addresses[5];

        _name = strings[0];
        _symbol = strings[1];

        _setSecondary(uints[0]);
        _setRoyalties(royaltiesAddrs, [uints[1], uints[2], uints[3], uints[4]]);
        if (uints[5] != 0) {
            timePerDecrement = uints[5];
        }
    }

    /**
     * @dev Sets secondary BPS amount
     */
    function _setSecondary(uint256 secondary) internal {
        secondaryOwnerBPS = secondary;
        require(secondaryOwnerBPS <= maxSecondaryBPS, "Cannot take more than 10% of secondaries");
    }

    /**
     * @dev Sets primary royalties
     */
    function _setRoyalties(address[4] memory newRoyalties, uint256[4] memory bps) internal {
        require(bps[0] + bps[1] + bps[2] + bps[3] <= maxRoyaltiesBPS, "Royalties too high");
        royalties = newRoyalties;
        royaltiesBPS = bps;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "ipfs://";
    }

    /**
     * @dev Changing _beforeTokenTransfer to lock tokens that are in an auction so
     * that owner cannot transfer the token as people are bidding on it.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override { 
        require(!_validAuction(_tokenIdToAuction[tokenId]), "Cannot transfer a token in an auction");

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev checks if a token is in an auction or not. We make sure that no active auction can 
     * have an endTimestamp of 0.
     */
    function _validAuction(Auction memory auction) internal pure returns (bool) {
        return auction.endTimestamp != 0;
    }

    /**
     * @dev helper method get ownerRoyalties into an array form
     */
    function _ownerRoyalties() internal view returns (address[] memory) {
        address[] memory ownerRoyalties = new address[](1);
        ownerRoyalties[0] = owner();
        return ownerRoyalties;
    }

    /**
     * @dev helper method get secondary BPS into array form
     */
    function _ownerBPS() internal view returns (uint256[] memory) {
        uint256[] memory ownerBPS = new uint256[](1);
        ownerBPS[0] = secondaryOwnerBPS;
        return ownerBPS;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToCheck(
        address owner,
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash,
        bool claimable
    ) internal view returns (bytes32) {
        return _toEthSignedMessageHash(_hash(owner, version, tokenId, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable));
    }

    /**
     * @dev First checks if a sale is valid by checking that the hash has not been cancelled or already completed
     * and that the correct address has given the signature. If both checks pass we mark the hash as complete and
     * emit an event.
     */
    function _markHashForSale(
        address owner,
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash,
        bool claimable,
        uint8 v, 
        bytes32 r,
        bytes32 s
    ) internal {
        bytes32 hash = _hashToCheck(owner, version, tokenId, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable);
        require(!_cancelledOrFinalizedSales[hash], "Sale no longer active");
        require(ecrecover(hash, v, r, s) == owner, "Not signed by current token owner");
        _cancelledOrFinalizedSales[hash] = true;

        emit SaleCompleted(hash);
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hash(
        address owner,
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash,
        bool claimable
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this), block.chainid, owner, version, tokenId, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable));
    }

    /**
     * @dev Current price for a sale which is calculated for the case of a descending auction. So
     * the ending price must be less than the starting price and the auction must have already started.
     * Standard single fare sales will have a matching starting and ending price.
     */
    function _currentPrice(uint256[4] memory pricesAndTimestamps) internal view returns (uint256) {
        uint256 startingPrice = pricesAndTimestamps[0];
        uint256 endingPrice = pricesAndTimestamps[1];
        uint256 startingTimestamp = pricesAndTimestamps[2];
        uint256 endingTimestamp = pricesAndTimestamps[3];

        uint256 currTime = block.timestamp;
        require(currTime >= startingTimestamp, "Has not started yet");
        require(startingTimestamp < endingTimestamp, "Must end after it starts");
        require(startingPrice >= endingPrice, "Ending price cannot be bigger");

        if (startingPrice == endingPrice || currTime > endingTimestamp) {
            return endingPrice;
        }

        uint256 diff = startingPrice - endingPrice;
        uint256 decrements = (currTime - startingTimestamp) / timePerDecrement;

        // This cannot equal 0 because if endingTimestamp == startingTimestamp, requirements will fail
        uint256 totalDecrements = (endingTimestamp - startingTimestamp) / timePerDecrement;

        return startingPrice - diff / totalDecrements * decrements;
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function _toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId 
            || interfaceId == type(Ownable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the current auction variables for a tokenId if the auction is present
     */
    function getAuction(uint256 tokenId) external view returns (Auction memory) {
        require(_validAuction(_tokenIdToAuction[tokenId]), "This auction does not exist");
        
        return _tokenIdToAuction[tokenId];
    }

    /**
     * @dev Returns the current activeVersion of an address both used to create signatures
     * and to verify signatures of {buyExistingToken} and {buyNewToken}
     */
    function getActiveVersion(address address_) external view returns (uint256) {
        return _addressToActiveVersion[address_];
    }

    /** 
     * @dev See {_currentPrice}
     */
    function getCurrentPrice(uint256[4] memory pricesAndTimestamps) external view returns (uint256) {
        return _currentPrice(pricesAndTimestamps);
    }

    /**
     * @dev Usable by the owner of any token initiate a sale for their token. This does not
     * lock the tokenId and the owner can freely trade their token because unlike auctions
     * sales would be immediate.
     */
    function hashToSignToSellToken(
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps
    ) external view returns (bytes32) {
        require(_msgSender() == ownerOf(tokenId), "Not the owner of the token");
        return _hash(_msgSender(), version, tokenId, pricesAndTimestamps, "", "", false);
    }

    /**
     * @dev Usable by the owner of this collection to sell a new token. The owner can decide what
     * the tokenURI of it will be and if the token is claimable and what the claimable hash would be
     */
    function hashToSignToSellNewToken(
        bool claimable,
        uint256 version,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash
    ) external view onlyOwner returns (bytes32) {
        require(bytes(ipfsHash).length > 0, "Invalid ipfsHash");
        return _hash(_msgSender(), version, 0, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellToken} any user sending enough value can buy
     * the token from the seller. These are all considered secondary sales and will give a cut to the 
     * owner of the contract based on the secondaryOwnerBPS.
     */
    function buyExistingToken(
        address seller,
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        uint8 v, 
        bytes32 r,
        bytes32 s
    ) external payable {
        uint256 currentPrice = _currentPrice(pricesAndTimestamps);

        require(_addressToActiveVersion[seller] == version, "Incorrect signature version");
        require(msg.value >= currentPrice, "Not enough ETH to buy");

        _markHashForSale(seller, version, tokenId, pricesAndTimestamps, "", "", false, v, r, s);

        _transfer(seller, _msgSender(), tokenId);

        IEaselyPayout(payoutContractAddress).splitPayable{ value: currentPrice }(seller, _ownerRoyalties(), _ownerBPS());
        payable(_msgSender()).transfer(msg.value - currentPrice);
    }

    /**
     * @dev With a hash signed by the method {hashToSignToSellNewToken} any user sending enough value can
     * mint the token from the contract. These are all considered primary sales and will give a cut to the 
     * royalties defined in the contract.
     */
    function buyNewToken(
        bool claimable,
        uint256 version,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        uint256 currentPrice = _currentPrice(pricesAndTimestamps);

        require(_addressToActiveVersion[owner()] == version, "Incorrect signature version");
        require(msg.value >= currentPrice, "Not enough ETH to buy");

        _markHashForSale(owner(), version, 0, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable, v, r, s);

        _safeMint(_msgSender(), nextTokenId);
        _setTokenURI(nextTokenId, ipfsHash);
        
        if (claimable) {
            _tokenIdIsClaimable[nextTokenId] = true;
            _tokenIdToPostClaimURI[nextTokenId] = claimedIpfsHash;
        }
        
        nextTokenId = nextTokenId + 1;

        IEaselyPayout(payoutContractAddress).splitPayable{ value: currentPrice }(owner(), royalties, royaltiesBPS);
        payable(_msgSender()).transfer(msg.value - currentPrice);
    }

    /**
     * @dev Usable to cancel hashes generated from both {hashToSignToSellNewToken} and {hashToSignToSellToken}
     */
    function cancelSale(
        bool claimable,
        uint256 version,
        uint256 tokenId,
        uint256[4] memory pricesAndTimestamps,
        string memory ipfsHash,
        string memory claimedIpfsHash
    ) external {
        bytes32 hash = _hashToCheck(_msgSender(), version, tokenId, pricesAndTimestamps, ipfsHash, claimedIpfsHash, claimable);
        _cancelledOrFinalizedSales[hash] = true;
        emit SaleCancelled(hash);
    }

    /**
     * @dev Usable by any user to update the version that they want their signatures to check. This is helpful if
     * an address wants to mass invalidate their signatures without having to call cancelSale on each one.
     */
    function updateVersion(uint256 version) external {
        _addressToActiveVersion[_msgSender()] = version;
    }

    /**
     * @dev For any user who owns a token that is claimable. If the token has an
     * associated post claim hash then the claimer will get a newly minted token
     * with that hash after claiming. 
     *
     * Claimed tokens that refer to off-chain benefits will be facillitated
     * by Easely, but are the responsibility of the contract creator to 
     * deliver on the promises.
     */
    function claimToken(uint256 tokenId) external {
        require(_exists(tokenId), "tokenId must exist");
        require(_tokenIdIsClaimable[tokenId] || burnable, "tokenId must be claimable");
        require(ownerOf(tokenId) == _msgSender(), "Only current tokenOwner can claim");

        // lock the token from being claimed and thus also from being transferred
        _tokenIdIsClaimable[tokenId] = false;

        // If URI is set, mint the tagged token
        if (bytes(_tokenIdToPostClaimURI[tokenId]).length > 0) {
            _safeMint(_msgSender(), nextTokenId);
            _setTokenURI(nextTokenId, _tokenIdToPostClaimURI[tokenId]);

            emit ClaimableClaimed(_msgSender(), tokenId, nextTokenId, tokenURI(tokenId));
            nextTokenId = nextTokenId + 1;
        }

        _burn(tokenId);
    }

    /**
     * @dev Creates an auction for a token and locks it from being transferred until the auction ends
     * the auction can end if the endTimestamp has been reached and can be cancelled prematurely if
     * there has been no bids yet.
     *
     * @param tokenId uint256 for the token to put on auction. Must exist and be on the auction already
     * @param startingPrice uint256 for the starting price an interested owner must bid
     * @param startingTimestamp uint256 for when the auction can start taking bids
     * @param endingTimestamp uint256 for when the auction has concluded and can no longer take bids
     * @param minBidIncrement uint256 the minimum each interested owner must bid over the latest bid
     * @param minLastBidDuration uint256 the minimum time a bid needs to be live before the auction can end.
     *        this means that an auction can extend past its original endingTimestamp
     */
    function createAuction(
        uint256 tokenId,
        uint256 startingPrice,
        uint256 startingTimestamp,
        uint256 endingTimestamp,
        uint256 minBidIncrement,
        uint256 minLastBidDuration
    ) external {
        require(endingTimestamp > block.timestamp, "Cannot create an auction in the past");
        require(!_validAuction(_tokenIdToAuction[tokenId]), "Token is already on auction");
        require(minBidIncrement > 0, "Min bid must be a positive number");
        require(_msgSender() == ownerOf(tokenId), "Must own token to create auction");

        Auction memory auction = Auction(address(0), startingPrice, startingTimestamp, endingTimestamp, minBidIncrement, minLastBidDuration);

        // This locks the token from being sold
        _tokenIdToAuction[tokenId] = auction;
        emit AuctionCreated(tokenId, startingPrice, startingTimestamp, endingTimestamp, minBidIncrement, minLastBidDuration, ownerOf(tokenId));
    }

    /** 
     * @dev Lets the token owner alter the end time of an auction in case they want to end an auction early or extend
     * the auction. This can only be called when the auction has not yet been concluded and is not within 
     * a minLastBidDuration from concluding.
     */
    function alterEndTime(uint256 tokenId, uint256 endTime) external {
        // 0 EndTimestamp is reserved to check if a tokenId is on auction or not
        require(endTime != 0, "End time cannot be 0");
        require(_msgSender() == ownerOf(tokenId), "Only token owner can alter end time");
        Auction memory auction = _tokenIdToAuction[tokenId];
        require(auction.endTimestamp > block.timestamp + auction.minLastBidDuration, "Auction has already ended");

        auction.endTimestamp = endTime;

        _tokenIdToAuction[tokenId] = auction;
        emit AuctionEndTimeAltered(tokenId, endTime, ownerOf(tokenId));
    }

    /**
     * @dev Allows the token owner to cancel an auction that does not yet have a bid.
     */
    function cancelAuction(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), "Only token owner can cancel auction");
        Auction memory auction = _tokenIdToAuction[tokenId];
        require(auction.topBidder == address(0), "Cannot cancel an auction with a bid");

        delete _tokenIdToAuction[tokenId];
        emit AuctionCancelled(tokenId, ownerOf(tokenId));
    }

    /**
     * @dev Method that anyone can call to settle the auction. It is available to everyone
     * because the settlement is not dependent on the message sender, and will allow either
     * the buyer, the seller, or a third party to cover the gas fees to settle. The burdern of
     * the auction to settle should be on the seller, but in case there are issues with
     * the seller settling we will not be locked from settling.
     *
     * If the seller is the contract owner, this is considered a primary sale and royalties will
     * be paid to primiary royalties. If the seller is a user then it is a secondary sale and
     * the contract owner will get a secondary sale cut.
     */
    function settleAuction(uint256 tokenId) external {
        Auction memory auction = _tokenIdToAuction[tokenId];
        address tokenOwner = ownerOf(tokenId);
        require(block.timestamp > auction.endTimestamp, "Auction must end to be settled");
        require(auction.topBidder != address(0), "No bidder, cancel the auction instead");

        // This will allow transfers again
        delete _tokenIdToAuction[tokenId];

        _transfer(tokenOwner, auction.topBidder, tokenId);
    
        if (tokenOwner == owner()) {
            IEaselyPayout(payoutContractAddress).splitPayable{ value: auction.price }(tokenOwner, royalties, royaltiesBPS);
        } else {
            address[] memory ownerRoyalties = new address[](1);
            uint256[] memory ownerBPS = new uint256[](1);
            ownerRoyalties[0] = owner();
            ownerBPS[0] = secondaryOwnerBPS;

            IEaselyPayout(payoutContractAddress).splitPayable{ value: auction.price }(tokenOwner, ownerRoyalties, ownerBPS);
        }

        emit AuctionSettled(tokenId, auction.price, auction.topBidder, tokenOwner);
    }

    /**
     * @dev Allows any potential buyer to submit a bid on a token with an auction. When outbidding the current topBidder
     * the contract returns the value that the previous bidder had escrowed to the contract.
     */
    function bidOnAuction(uint256 tokenId) external payable {
        uint256 timestamp = block.timestamp;
        Auction memory auction = _tokenIdToAuction[tokenId];
        uint256 msgValue = msg.value;

        // Tokens that are not on auction always have an endTimestamp of 0
        require(timestamp <= auction.endTimestamp, "Auction has already ended");
        require(timestamp >= auction.startTimestamp, "Auction has not started yet");

        uint256 minPrice = auction.price + auction.minBidIncrement;
        if (auction.topBidder == address(0)) {
            minPrice = auction.price;
        }
        require(msgValue >= minPrice, "Bid is too small");

        uint256 endTime = auction.endTimestamp;
        if (endTime < auction.minLastBidDuration + timestamp) {
            endTime = timestamp + auction.minLastBidDuration;
        }

        Auction memory newAuction = Auction(_msgSender(), msgValue, auction.startTimestamp, endTime, auction.minBidIncrement, auction.minLastBidDuration);

        if (auction.topBidder != address(0)) {
            // Give the old top bidder their money back
            payable(auction.topBidder).transfer(auction.price);
        }

        _tokenIdToAuction[tokenId] = newAuction;
        emit AuctionBidded(tokenId, newAuction.price, newAuction.topBidder);
    }

    /**
     * @dev see {_setRoyalties}
     */
    function setRoyalties(address[4] memory newRoyalties, uint256[4] memory bps) external onlyOwner {
        _setRoyalties(newRoyalties, bps);
    }

    /**
     * @dev see {_setSecondary}
     */
    function setSecondaryBPS(uint256 bps) external onlyOwner() {
        _setSecondary(bps);
    }

    /**
     * @dev Allows the owner to create a new token with ipfsHash as the tokenURI.
     */
    function mint(address collectorAddress, string memory ipfsHash) external onlyOwner {
        // mint token
        _safeMint(collectorAddress, nextTokenId);
        _setTokenURI(nextTokenId, ipfsHash);
        
        nextTokenId = nextTokenId + 1;
    }

    /**
     * @dev Adds a claimable hash to an existing token. If claimedIpfsHash is exactly "" then
     * no token will be created when the token is claimed, otherwise a new token with that hash 
     * will be given to the token owner when they call {claimToken}
     */
    function addClaimable(
        uint256 tokenId,
        string memory claimedIpfsHash
    ) external onlyOwner {
        require(_exists(tokenId), "tokenId must exist");
        require(!_tokenIdIsClaimable[tokenId], "Claimable already exists");

        _tokenIdIsClaimable[tokenId] = true;
        _tokenIdToPostClaimURI[tokenId] = claimedIpfsHash;
    }

    /**
     * @dev Allows the owner to create a new token with ipfsHash as the tokenURI that is also claimable. 
     * If claimedIpfsHash is exactly "" then no token will be created when the token is claimed, otherwise 
     * a new token with hash claimedIpfsHash will be given to the token owner when they call {claimToken}
     */
    function mintClaimable(
        address collectorAddress, 
        string memory ipfsHash,
        string memory claimedIpfsHash
    ) external onlyOwner {
        // mint token
        _safeMint(collectorAddress, nextTokenId);
        _setTokenURI(nextTokenId, ipfsHash);

        _tokenIdIsClaimable[nextTokenId] = true;
        _tokenIdToPostClaimURI[nextTokenId] = claimedIpfsHash;
        
        nextTokenId = nextTokenId + 1;
    }
}