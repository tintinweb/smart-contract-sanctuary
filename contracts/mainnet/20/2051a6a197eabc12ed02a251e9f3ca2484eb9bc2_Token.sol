/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

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

//--------------------------
// Base64 ライブラリ
//--------------------------
library Base64Lib {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// 渡されたバイト配列をBase64エンコードする
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // エンコードサイズ
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // 出力配列の確保
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
//--------------------------
// 文字列ライブラリ
//--------------------------
library StrLib {
    //---------------------------
    // 数値を１０進数文字列にして返す
    //---------------------------
    function numToStr( uint256 val ) internal pure returns (string memory) {
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
            uint c = 48 + (temp%10);    // ascii: '0' 〜 '9'
            buf[len-(i+1)] = bytes1(uint8(c));
            temp /= 10;
        }

        return( string(buf) );
    }

    //----------------------------
    // 数値を１６進数文字列にして返す
    //----------------------------
    function numToStrHex( uint256 val, uint256 zeroFill ) internal pure returns (string memory) {
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
                c += 48;        // ascii: '0' 〜 '9'
            }else{
                c += 87;        // ascii: 'a' 〜 'f'
            }
            buf[padding+len-(i+1)] = bytes1(uint8(c));
            temp /= 16;
        }

        return( string(buf) );
    }
}

//--------------------------
// 乱数ライブラリ
//--------------------------
library RandLib {
    //----------------------------------------------------------------------------------------------------------------------
    // 乱数のシードの生成：[rand32]への初期値となる値を作成する
    //----------------------------------------------------------------------------------------------------------------------
    // [rand32]が繰り返し呼ばれる流れを複数実装する場合、[seed]値を変えることで、同じ[base]値から異なる初期値を取りだせる
    //（※例えば、[rand32]を複数呼ぶ関数をコールする際、同じ初期値を使ってしまうと関数の呼び先で同じ乱数が生成されることになるので注意すること）
    //----------------------------------------------------------------------------------------------------------------------
    function randInitial32WithBase( uint256 base, uint8 seed ) internal pure returns (uint32) {
        // ベース値から[32]ビット抽出する（※[seed]の値により取り出し位置を変える）
        // [seed]の値によってシフトされるビットは最大で[13*7+37=128]となる（※[uint160=address]の最上位32ビットまでを想定）
        return( uint32( base >> (13*(seed%8) + (seed%38)) ) );
    }

    //----------------------------------------------------------
    // 乱数の作成：[BASEFEE]を利用したなんちゃって乱数
    // [BASEFEE]はローカルでは動かないので注意（invalid opcodeが出る）
    //----------------------------------------------------------
    function createRand32( uint256 base0, uint8 seed ) internal view returns(uint32) {
        // base値の算出
        uint256 base1 = uint256( uint160(msg.sender) ); // addressを流用
        uint256 base2 = block.basefee;    // console developだと動かないので注意
        uint256 base = (base0 ^ base1 ^ base2);

        uint32 initial = randInitial32WithBase( base, seed );
        return( updateRand32( initial ) );
    }

    //----------------------------------------------------------
    // 乱数の更新：返値を次回の入力に使うことで乱数の生成を繰り返す想定
    //----------------------------------------------------------
    function updateRand32( uint32 val ) internal pure returns (uint32) {
        val ^= (val >> 13);
        val ^= (val << 17);
        val ^= (val << 15);

        return( val );
    }
}

//-----------------------------------------------------------------
// 処理をアンロックするための鍵：[Unlockable]を利用する側で実装する
//-----------------------------------------------------------------
// [IUnlockKey]の[isUnlocking]が[true]を返す状況でのみ、
// [Unlockable]の[whenUnlocked]で修飾される関数が実行可能
//-----------------------------------------------------------------
interface IUnlockKey {
    //------------------------
    // アンロック中か？
    //------------------------
    function isUnlocking() external view returns (bool);
}

//-----------------------------------------------------------------------
// カートリッジ：インターフェイス
//-----------------------------------------------------------------------
interface ICartridge {
    //----------------------------------------
    // 残弾の取得
    //----------------------------------------
    function getNum() external view returns (uint256);

    //----------------------------------------
    // クリエイターの取り出し
    //----------------------------------------
    function getCreator( uint256 at ) external view returns (string memory);

    //----------------------------------------
    // データの取り出し
    //----------------------------------------
    function getData( uint256 at ) external view returns (uint256);

    //----------------------------------------
    // データの消費（アンロックして呼び出す想定）
    //----------------------------------------
    function waste( uint256 at ) external;
}

//-----------------------------------
// ERC721 トークンクラス
//-----------------------------------
contract Token is Ownable, ERC721, IUnlockKey {
    //-----------------------------------------
    // イベント
    //-----------------------------------------
    event PuzzleMint( uint256 indexed tokenId, uint256 indexed data, address indexed minter, string creator );
    event PuzzleRepairData( uint256 indexed tokenId, uint256 indexed data );
    event PuzzleRepairMinter( uint256 indexed tokenId, address indexed minter );
    event PuzzleRepairCreator( uint256 indexed tokenId, string creator );

    //-----------------------------------------
    // 定数
    //-----------------------------------------
    string constant private TOKEN_NAME = "Puzzle (Number Place)";
    string constant private TOKEN_SYMBOL = "PNP";
    uint256 constant private TOKEN_ID_OFS = 1;

    //-----------------------------------------
    // 文字列
    //-----------------------------------------
    string[] private _strArrNum = [ "", "1", "2", "3", "4", "5", "6", "7", "8", "9" ];
    string[] private _strArrX = [ "16", "53", "90", "128", "165", "202", "240", "277", "314" ];
    string[] private _strArrY = [ "40", "77", "114", "152", "189", "226", "264", "301", "338" ];

    //------------------------------------------------------------
    // カートリッジ設定（NFT販売前に設定しておく値）
    //------------------------------------------------------------
    ICartridge[] private _cartridges;   // カートリッジ
    uint256 private _version;           // カートリッジのバージョン（第一弾、第二弾等やる場合の利用を想定）
    uint256 private _price;             // NFTの値段
    uint256 private _total;             // 装填弾数（リリース時の総数）
    uint256 private _max_shot;          // 一度に購入できるNFT数

    //------------------------------------------------------------
    // 販売管理
    //------------------------------------------------------------
    bool private _onSale;               // 販売中か？（NFTを購入できるか？）

    //------------------------------------------------------------
    // トークン管理
    //------------------------------------------------------------
    // カートリッジのアンロックフラグ（データを取り出す前に立てて、引いたら寝かす）
    bool private _unlock;

    // NFTのデータ：[tokenId-TOKEN_ID_OFS]でアクセスする
    uint256[] private _datas;
    address[] private _minters;
    string[] private _creators;

    //-----------------------------------------
    // コンストラクタ
    //-----------------------------------------
    constructor() Ownable() ERC721( TOKEN_NAME, TOKEN_SYMBOL ) {
    }

    //--------------------------------------
    // [external] 解錠中か？（IUnlockKey実装）
    //--------------------------------------
    function isUnlocking() external view override returns (bool) {
        return( _unlock );
    }
    
    //-----------------------------------------
    // [external] トークンの発行数
    //-----------------------------------------
    function totalSupply() external view returns( uint256 ) {
        return( _datas.length );
    }

    //-----------------------------------------
    // [external/payable] トークンの発行
    //-----------------------------------------
    function mintToken( uint256 num ) external payable {
        // 販売中か？
        require( _onSale, "not on sale" );

        // 試行回数は有効か？
        require( num > 0 && num <= _max_shot, "invalid num" );       

        // 入金額は有効か？
        uint256 amount = _price * num;
        require( msg.value >= amount, "insufficient value" );

        // 残りがあるか？
        uint256 remain = getRemain();
        require( num <= remain, "remaining data not enough" );
        
        //--------------------------
        // ここまできたらチェック完了
        //--------------------------
        // 乱数の初期化
        uint32 rand = RandLib.createRand32( _datas.length, uint8(remain) );     

        // フラグを立てる
        _unlock = true;

        // NFTの抽選
        for( uint256 i=0; i<num; i++ ){
            // 当選番号
            uint256 at = rand % remain;

            // 対象のスロットの特定
            uint256 target = 0;
            for( uint256 j=0; j<_cartridges.length; j++ ){
                uint256 temp = _cartridges[j].getNum();
                if( temp > at ){
                    target = j;
                    break;
                }
                at -= temp;
            }

            // データの取り出し＆消費
            uint256 data = _cartridges[target].getData( at );
            string memory creator = _cartridges[target].getCreator( at );
            _cartridges[target].waste( at );

            // tokenIdは連番
            uint256 tokenId = _datas.length + TOKEN_ID_OFS;

            // トークンの付与（Tx発行者へ）
            _mint( msg.sender, tokenId );

            // データの紐付け
            _datas.push( data );
            _minters.push( msg.sender );
            _creators.push( creator );

            // イベント
            emit PuzzleMint( tokenId, data, msg.sender, creator );

            // 値の更新
            remain--;
            rand = RandLib.updateRand32( rand );
        }

        // フラグを寝かす
        _unlock = false;
    }

    //--------------------------------------
    // [public] トークンURIの上書き
    //--------------------------------------
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token" );

        string memory strName = string( abi.encodePacked( '"name":"PNP #', StrLib.numToStr(tokenId), '",' ) );
        string memory strDescription = '"description":"Puzzle (Number Place)",';
        string memory strAttributes = string( abi.encodePacked( '"attributes":[{"trait_type":"Creator","value":"', _creators[tokenId-TOKEN_ID_OFS], '"}],' ) );
        string memory strSvg = createSvg( _datas[tokenId-TOKEN_ID_OFS] );

        string memory json = Base64Lib.encode( bytes( string( abi.encodePacked( '{', strName, strDescription, strAttributes, '"image": "data:image/svg+xml;base64,', Base64Lib.encode(bytes(strSvg)), '"}' ) ) ) );
        json = string( abi.encodePacked('data:application/json;base64,', json ) );
        return( json );
    }

    //--------------------------------------
    // [internal] svgの作成
    //--------------------------------------
    function createSvg( uint256 data ) internal view returns( string memory ){
        string memory strRet = "";
        string memory strLine;

        bytes memory nums = decodePuzzle( data );
        uint256 num;

        for( uint256 i=0; i<9; i++ ){
            strLine = "";
            for( uint256 j=0; j<9; j++ ){
                num = uint256( uint8(nums[9*i + j]) );
                if( num != 0 ){
                    strLine = string( abi.encodePacked( strLine, '<text x="', _strArrX[j], '" y="', _strArrY[i], '" class="f">', _strArrNum[num], '</text>' ) );
                }
            }

            strRet = string( abi.encodePacked( strRet, strLine ) );
        }

        strRet = string( abi.encodePacked( '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.f { font-family: serif; font-size:34px; fill:#ffffff;}</style><rect x="0" y="0" width="350" height="350" fill="#000000" /><rect x="5" y="5" width="340" height="340" fill="#ffffff" /><rect x="8" y="8" width="334" height="334" fill="#000000" /><rect x="118" y="6" width="2" height="338" fill="#ffffff" /><rect x="230" y="6" width="2" height="338" fill="#ffffff" /><rect y="118" x="6" height="2" width="338" fill="#ffffff" /><rect y="230" x="6" height="2" width="338" fill="#ffffff" /><rect x="44" y="6" width="1" height="338" fill="#ffffff" /><rect x="81" y="6" width="1" height="338" fill="#ffffff" /><rect y="44" x="6" height="1" width="338" fill="#ffffff" /><rect y="81" x="6" height="1" width="338" fill="#ffffff" /><rect x="155" y="6" width="1" height="338" fill="#ffffff" /><rect x="192" y="6" width="1" height="338" fill="#ffffff" /><rect y="155" x="6" height="1" width="338" fill="#ffffff" /><rect y="192" x="6" height="1" width="338" fill="#ffffff" /><rect x="267" y="6" width="1" height="338" fill="#ffffff" /><rect x="304" y="6" width="1" height="338" fill="#ffffff" /><rect y="267" x="6" height="1" width="338" fill="#ffffff" /><rect y="304" x="6" height="1" width="338" fill="#ffffff" />', strRet, '</svg>' ) );
        return( strRet );
    }

    //-----------------------------------------
    // [internal] データの解凍
    //-----------------------------------------
    function decodePuzzle( uint256 data ) internal pure returns (bytes memory) {
        bytes memory nums = new bytes(81);

        uint256 numCandX;
        bytes memory candX = new bytes(9);

        uint256 numCand;
        bytes memory cand = new bytes(9);

        // 先頭ビットの検出
        for( uint256 i=0; i<256; i++ ){
            if( (data & 0x8000000000000000000000000000000000000000000000000000000000000000 ) != 0 ){
                data <<= 1;
                break;
            }
            data <<= 1;
        }

        uint256 flags = data;
        data <<= 81;

        // 数字の復元
        for( uint256 i=0; i<9; i++ ){

            // 横方向の候補の抽出
            numCandX = 9;
            for( uint256 k=0; k<9; k++ ){
                candX[k] = bytes1(uint8(1+k));
            }

            for( uint256 j=0; j<9; j++ ){

                // フラグ立っていたら出力
                if( (flags & 0x8000000000000000000000000000000000000000000000000000000000000000 ) != 0 ){
                    // 候補の設定
                    numCand = numCandX;
                    for( uint256 k=0; k<numCandX; k++ ){
                        cand[k] = candX[k];
                    }

                    // 縦方向の除外
                    for( uint256 k=0; k<i; k++ ){
                        numCand -= removeVal( cand, numCand, nums[9*k+j] );
                    }

                    // 参照先の読み込み
                    uint256 target = 0;
                    if( numCand > 8){
                        target = (data >> 252) & 0xF;
                        data <<= 4;
                    }else if( numCand > 4 ){
                        target = (data >> 253) & 0x7;
                        data <<= 3;
                    }else if( numCand > 2 ){
                        target = (data >> 254) & 0x3;
                        data <<= 2;
                    }else if( numCand > 1 ){
                        target = (data >> 255) & 0x1;
                        data <<= 1;
                    }
                    nums[9*i+j] = cand[target];

                    // 候補配列から外す
                    numCandX -= removeVal( candX, numCandX, cand[target] );
                }

                flags <<= 1;
            }
        }

        return( nums );
    }

    //--------------------------------------
    // [internal] 配列内に対象の値があれば削除
    //--------------------------------------
    function removeVal( bytes memory vals, uint256 size, bytes1 val ) internal pure returns (uint256) {
        for( uint256 i=0; i<size; i++ ){
            if( vals[i] == val ){
                for( uint256 j=i+1; j<size; j++ ){
                    vals[j-1] = vals[j];
                }
                return( 1 );
            }
        }

        return( 0 );
    }

    //--------------------------------------------------------
    // [public] データ残数の確認
    //--------------------------------------------------------
    function getRemain() public view returns (uint256) {
        uint256 remain = 0;

        for( uint256 i=0; i<_cartridges.length; i++ ){
            remain += _cartridges[i].getNum();
        }

        return( remain );
    }

    //--------------------------------------------------------
    // [external] 確認
    //--------------------------------------------------------
    // カートリッジ
    function cartridges( uint256 at ) external view returns (address) {
        require( at < _cartridges.length, "out of range" );

        return( address(_cartridges[at]) );
    }

    // バージョン確認
    function version() external view returns (uint256) {
        return( _version );
    }

    // 価格確認
    function price() external view returns (uint256) {
        return( _price );
    }

    // 総数確認
    function total() external view returns (uint256) {
        return( _total );
    }

    // 最大回数確認
    function max_shot() external view returns (uint256) {
        return( _max_shot );
    }

    //--------------------------------------------------------
    // [extrnal/onlyOwner] カートリッジ設定
    //--------------------------------------------------------
    function setCartridges( address[] calldata __cartridges, uint256 __version, uint256 __price, uint256 __total, uint256 __max_shot ) external onlyOwner {
        // 用心
        uint256 temp = 0;
        for( uint256 i=0; i<__cartridges.length; i++ ){
            ICartridge cartridge = ICartridge( __cartridges[i] );
            temp += cartridge.getNum();
        }
        require( temp == __total, "mismatch total" );

        // 設定
        delete _cartridges;
        for( uint256 i=0; i<__cartridges.length; i++ ){
            _cartridges.push( ICartridge( __cartridges[i] ) );
        }
        _version = __version;
        _price = __price;
        _total = __total;
        _max_shot = __max_shot;
    }

    //--------------------------------------------------------
    // [external] 販売中か？
    //--------------------------------------------------------
    function onSale() external view returns (bool) {
        return( _onSale );
    }

    //--------------------------------------------------------
    // [extrnal/onlyOwner] 販売設定
    //--------------------------------------------------------
    function setOnSale( bool flag ) external onlyOwner {
        _onSale = flag;
    }

    //--------------------------------------------------------
    // [external] データの確認
    //--------------------------------------------------------
    function getData( uint256 tokenId ) external view returns (uint256) {
         require( _exists( tokenId ), "token not exist" );

         return( _datas[tokenId-TOKEN_ID_OFS] );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] データの修復
    //--------------------------------------------------------
    function repairData( uint256 tokenId, uint256 data ) external onlyOwner {
         require( _exists( tokenId ), "token not exist" );

        _datas[tokenId-TOKEN_ID_OFS] = data;
        emit PuzzleRepairData( tokenId, data );
    }

    //--------------------------------------------------------
    // [external] 発行者の確認
    //--------------------------------------------------------
    function getMinter( uint256 tokenId ) external view returns (address) {
         require( _exists( tokenId ), "token not exist" );

         return( _minters[tokenId-TOKEN_ID_OFS] );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] 発行者の修復
    //--------------------------------------------------------
    function repairMinter( uint256 tokenId, address minter ) external onlyOwner {
         require( _exists( tokenId ), "token not exist" );

        _minters[tokenId-TOKEN_ID_OFS] = minter;
        emit PuzzleRepairMinter( tokenId, minter );
    }

    //--------------------------------------------------------
    // [external] クリエイターの確認
    //--------------------------------------------------------
    function getCreator( uint256 tokenId ) external view returns (string memory) {
         require( _exists( tokenId ), "token not exist" );

         return( _creators[tokenId-TOKEN_ID_OFS] );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] クリエイターの修復
    //--------------------------------------------------------
    function repairCreator( uint256 tokenId, string calldata creator ) external onlyOwner {
         require( _exists( tokenId ), "token not exist" );

        _creators[tokenId-TOKEN_ID_OFS] = creator;
        emit PuzzleRepairCreator( tokenId, creator );
    }

    //--------------------------------------------------------
    // [external] 残高の確認
    //--------------------------------------------------------
    function checkBalance() external view returns (uint256) {
        return( address(this).balance );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] 引き出し
    //--------------------------------------------------------
    function withdraw( uint256 amount ) external onlyOwner {
        require( amount <= address(this).balance, "insufficient balance" );

        address payable target = payable( msg.sender );
        target.transfer( amount );
    }
}