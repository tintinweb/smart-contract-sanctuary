/**
 *Submitted for verification at Etherscan.io on 2021-11-16
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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






//  __  __      _           _____ _      _  __      _                _     
// |  \/  |    | |         / ____(_)    | |/ _|    (_)              | |    
// | \  / | ___| |_ __ _  | |  __ _ _ __| | |_ _ __ _  ___ _ __   __| |___ 
// | |\/| |/ _ \ __/ _` | | | |_ | | '__| |  _| '__| |/ _ \ '_ \ / _` / __|
// | |  | |  __/ || (_| | | |__| | | |  | | | | |  | |  __/ | | | (_| \__ \
// |_|  |_|\___|\__\__,_|  \_____|_|_|  |_|_| |_|  |_|\___|_| |_|\__,_|___/                                                                         
//
// Meta Girlfriends / 2021 





contract MetaGirlfriends is ERC721, Ownable {
    using Strings for uint;

    event PriceChanged(uint256 newPrice);
    event BaseURIChanged(string newbaseURIPrefix);
    event TokenUpdated( uint256 tokenId, uint256 oldtraits, uint256 newtraits, uint256 parent1, uint256 parent2);

    uint public price = 0.08 ether;
    uint public constant maxSupply = 10000;
    uint public constant giveAwayCount = 200;    
    bool public mintingEnabled;
    bool public whitelistEnabled = true;
    uint public buyLimit = 10;
    uint256 public giveAwaysReserved;
    uint256 public tokensReserved;
    uint256 public tokensMinted;
    uint256 public tokensBurnt;

    mapping(address => uint256) public reservedCount;

    mapping(uint256 => uint256) private gftraits; 
    uint16[10000] private levels; 
    mapping(uint256 => uint256) private traitsToId;
    bool public combineEnabled;

    uint16[10] traitQuantities_0 = [700, 300, 125, 75, 150, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_1 = [6000, 600, 200, 0, 0, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_2 = [8500, 1000, 100, 200, 0, 0, 0, 0,0,0];
    uint16[10] traitQuantities_3 = [700, 1500, 500, 400, 300, 200, 100, 0, 0, 0];
    uint16[10] traitQuantities_4 = [3000, 2000, 1500, 1500, 1000, 500, 300, 200, 0, 0];
    uint16[10] traitQuantities_5 = [2500, 500, 300, 150, 100, 50, 0, 0, 0, 0];
    uint16[10] traitQuantities_6 = [700, 1300, 500, 400, 300, 100, 200, 0, 0, 0];
    uint16[10] traitQuantities_7 = [300, 200, 100, 50, 25, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_8 = [75, 70, 75, 70, 60, 65, 40, 30, 10, 0];
    uint16[10] traitQuantities_9 = [3000, 1500, 1000, 500, 0, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_10 = [1500, 800, 700, 500, 300, 150, 100, 0, 0, 0];
    uint16[10] traitQuantities_11 = [1500, 1200, 750, 500, 400, 500, 0, 0, 0, 0];
    uint16[10] traitQuantities_12 = [4000, 2500, 1500, 500, 0, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_13 = [1000, 650, 500, 400, 0, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_14 = [1200, 700, 500, 400, 0, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_15 = [500, 750, 500, 250, 125, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_16 = [0, 500, 300, 200, 100, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_17 = [0, 600, 400, 150, 125, 0, 0, 0, 0, 0];
    uint16[10] traitQuantities_18 = [0, 400, 500, 400, 200, 100, 50, 0, 0, 0];
    uint16[10] traitQuantities_19 = [1000, 300, 250, 350, 200, 350, 150, 100, 0, 0];

    uint8[10] traitNumbers_0 =[7,12,9,3,1,0,0,0,0,0];
    uint8[10] traitNumbers_1 =[1,6,2,0,0,0,0,0,0,0];
    uint8[10] traitNumbers_2 =[1,1,1,2,0,0,0,0,0,0];
    uint8[10] traitNumbers_3 =[1,4,1,4,1,4,1,0,0,0];
    uint8[10] traitNumbers_4 =[1,1,1,1,1,1,1,1,0,0];
    uint8[10] traitNumbers_5 =[1,7,11,3,2,1,0,0,0,0];
    uint8[10] traitNumbers_6 =[2,2,6,2,5,1,3,0,0,0];
    uint8[10] traitNumbers_7 =[16,5,34,15,2,0,0,0,0,0];
    uint8[10] traitNumbers_8 =[8,8,24,28,20,40,24,9,5,0];
    uint8[10] traitNumbers_9 =[1,2,2,4,0,0,0,0,0,0];
    uint8[10] traitNumbers_10 =[1,4,1,6,3,4,1,0,0,0];
    uint8[10] traitNumbers_11 =[1,3,4,1,1,2,0,0,0,0];
    uint8[10] traitNumbers_12 =[1,1,2,1,0,0,0,0,0,0];
    uint8[10] traitNumbers_13 =[6,4,2,1,0,0,0,0,0,0];
    uint8[10] traitNumbers_14 =[6,2,2,1,0,0,0,0,0,0];
    uint8[10] traitNumbers_15 =[1,5,9,4,2,0,0,0,0,0];
    uint8[10] traitNumbers_16 =[1,10,12,1,12,0,0,0,0,0];
    uint8[10] traitNumbers_17 =[1,10,8,2,4,0,0,0,0,0];
    uint8[10] traitNumbers_18 =[1,3,3,7,19,6,2,0,0,0];    
    uint8[10] traitNumbers_19 =[1,10,4,6,2,2,10,3,0,0];

    string private _baseURIPrefix;
    address private signerAddress = 0x77bFCca6F45B07047a34A31885Af86F11033665B;
    address private constant treasury = 0xAb22AD2eDF9774C4aAe550165397Ebc6050a1f4E;
    address private dev1;
    address private dev2 = 0x353d285681458962eD5830672cbDeFcBB9b888A7;

    constructor () ERC721('Meta Girlfriends', 'MG') {
        _transferOwnership(treasury);
        dev1 = _msgSender();
    }

    function totalSupply() external view returns (uint256){
        return tokensMinted - tokensBurnt;
    }

    // ========================== Girlfriends generation  ==============================    

    /*
    * @dev Stacks an array of uint8 < 1000 into one big uint256 uintTraits
    */    
    function charsToUint(uint8[20] memory chars) public pure returns (uint256 uintTraits){
        for(uint i=0; i<20; i++){
            uintTraits += chars[19-i]*(1000**i);
        }
    }

    /*
    * @dev Unstacks an array of uint8 < 1000 from one big uintTraits
    */    
    function uintToChars(uint256 uintTraits) public pure returns(uint8[20] memory chars){
        for(uint i=0; i<20; i++){
            chars[i] = uint8( uintTraits/(1000**(19-i)) );
            uintTraits -= chars[i]*(1000**(19-i));
        }
    }    

    function _concatBytes(bytes1 u1, bytes1 u2) internal pure returns (uint16) {
        return uint16(uint8(u1)) << 8 | uint16(uint8(u2));
    }

    function _pseudoRandomHash(uint nonce1, uint nonce2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nonce1.toString(), nonce2.toString(), 'pseudoRandomHashing'));
    }

    function _randomTrait(
        uint16 seed, 
        uint16[10] memory traitQuantities,
        uint8[10] memory traitNumbers
    ) internal pure returns (uint8) {
        seed = uint16(uint256(seed)*maxSupply/uint256(0xFFFF));
        uint16 sum;
        uint8 traitIndex;
        for(uint8 i=0; i<10; i++){
            for(uint8 j=0; j<traitNumbers[i]; j++){
                sum += traitQuantities[i];
                if (sum >0 && seed <= sum){return traitIndex;}
                traitIndex++;
            }
        }
        revert('MG: traitQuantities do not sum up to maxSupply');
    }

    // check if hair traits allows hats
    function _hairAllowsHat(uint8 t8, uint8 t19) internal pure returns (bool){
        return !(( (t8>=16 && t8<=31) || (t8>=64 && t8<=79) || (t8>=96 && t8<=119) || (t8>=136 && t8<=151) || (t8>=152 && t8<=157) ) && ((t19>=1 && t19<=10) || t19==32) );
    }

    function _generateGirlFriend(uint256 tokenId) internal view returns (uint256) {
        bytes32 hash = _pseudoRandomHash(tokenId, 1);

        uint8[20] memory traits;
        
        traits[0] = _randomTrait( _concatBytes(hash[0], hash[1]), traitQuantities_0, traitNumbers_0); // Background
        traits[1] = _randomTrait( _concatBytes(hash[2], hash[3]), traitQuantities_1, traitNumbers_1); // Tail
        traits[2] = _randomTrait( _concatBytes(hash[4], hash[5]), traitQuantities_2,traitNumbers_2); // Back
        traits[3] = _randomTrait( _concatBytes(hash[6], hash[7]), traitQuantities_3, traitNumbers_3); // Skin
        traits[4] = _randomTrait( _concatBytes(hash[8], hash[9]), traitQuantities_4, traitNumbers_4); // Vag
        traits[5] = _randomTrait( _concatBytes(hash[10], hash[11]), traitQuantities_5, traitNumbers_5); // Tattoos
        traits[6] = _randomTrait( _concatBytes(hash[12], hash[13]), traitQuantities_6, traitNumbers_6); // Eyes
        traits[7] = _randomTrait( _concatBytes(hash[14], hash[15]), traitQuantities_7, traitNumbers_7); // Mouth
        traits[8] = _randomTrait( _concatBytes(hash[16], hash[17]), traitQuantities_8, traitNumbers_8); // Hair
        traits[9] = _randomTrait( _concatBytes(hash[18], hash[19]), traitQuantities_9, traitNumbers_9); // Piercings
        traits[10] = _randomTrait( _concatBytes(hash[20], hash[21]), traitQuantities_10, traitNumbers_10); // Face
        traits[11] = _randomTrait( _concatBytes(hash[22], hash[23]), traitQuantities_11, traitNumbers_11); // Neck
        traits[12] = _randomTrait( _concatBytes(hash[24], hash[25]), traitQuantities_12, traitNumbers_12); // Earrings
        traits[13] = _randomTrait( _concatBytes(hash[26], hash[27]), traitQuantities_13, traitNumbers_13); // Panties
        traits[14] = _randomTrait( _concatBytes(hash[28], hash[29]), traitQuantities_14, traitNumbers_14); // Bra
        traits[15] = _randomTrait( _concatBytes(hash[30], hash[31]), traitQuantities_15, traitNumbers_15); // Shoes

        hash = _pseudoRandomHash(tokenId, 2);
        // deal with incompatible traits : full suit vs top+bottom
        if(uint8(hash[8])>=128){
            traits[16] = _randomTrait( _concatBytes(hash[0], hash[1]), traitQuantities_16, traitNumbers_16); // Full outfit
        }else{
            traits[17] = _randomTrait( _concatBytes(hash[2], hash[3]), traitQuantities_17, traitNumbers_17); // Clothing bottom
            traits[18] = _randomTrait( _concatBytes(hash[4], hash[5]), traitQuantities_18, traitNumbers_18); // Clothing top    
        }
        traits[19] = _randomTrait( _concatBytes(hash[6], hash[7]), traitQuantities_19, traitNumbers_19); // Head

        // deal with incompatible traits : hairs prevent hat
        if(!_hairAllowsHat(traits[8], traits[19])){
            traits[19]=0;
        }

        return charsToUint(traits);
    }

    function _createGirlFriend(uint256 tokenId) internal {
        uint256 newtraits = _generateGirlFriend(tokenId);
        gftraits[tokenId] = newtraits;
        levels[tokenId-1]=1;
        traitsToId[newtraits] = tokenId;
        _safeMint(_msgSender(), tokenId);
        emit TokenUpdated(tokenId, 0, newtraits, 0, 0);
    }

    function getTraits(uint256 tokenId) external view returns (uint256){
        require(_exists(tokenId), 'MG: non existent tokenId');
        return gftraits[tokenId];
    }

    function getTraitArray(uint256 tokenId) public view returns (uint8[20] memory){
        require(_exists(tokenId), 'MG: non existent tokenId');
        return uintToChars(gftraits[tokenId]);
    }

    function getLevel(uint256 tokenId) external view returns (uint16){
        require(_exists(tokenId), 'MG: non existent tokenId');        
        return levels[tokenId-1]; 
    }

    function _checkTraitCompatibility(uint8[20] memory traitArray) internal pure{
        if( traitArray[16] == 0 ){
            require( traitArray[17]>0 && traitArray[18]>0, "MG: Forbidden trait");
        }else{
            require( traitArray[17]==0 && traitArray[18]==0, "MG: Forbidden trait");
        }
        require(_hairAllowsHat(traitArray[8], traitArray[19]), "MG: Incompatible trait");        
    }

    function combineGirlfriends(uint256 gfId1, uint256 gfId2, uint256 newId, uint8[20] memory traitArray) external {
        require(combineEnabled, "MG: Combining GirlFriends is not enabled");
        require( ownerOf(gfId1) == _msgSender() && ownerOf(gfId2) == _msgSender(), "MG: Must own these GirlFriends");

        require(gfId1 == newId || gfId2 == newId, "MG: Invalid ID");

        uint256 gf1UintTraits = gftraits[gfId1];
        uint256 gf2UintTraits = gftraits[gfId2];

        uint8[20] memory gf1traits = uintToChars(gf1UintTraits);
        uint8[20] memory gf2traits = uintToChars(gf2UintTraits);

        for(uint8 i=0; i<20; i++){
            require(gf1traits[i] == traitArray[i] || gf2traits[i] == traitArray[i], "MG: Invalid trait");
        }

        _checkTraitCompatibility(traitArray);

        uint256 uintTraits = charsToUint(traitArray);

        require(traitsToId[uintTraits] == 0, "MG: This trait combination already exists");
        traitsToId[uintTraits] = newId;

        levels[newId-1] = levels[gfId1-1] > levels[gfId2-1] ? levels[gfId1-1] + 1 : levels[gfId2-1] + 1;

        emit TokenUpdated( newId, gftraits[newId], uintTraits, gfId1, gfId2 );

        gftraits[newId] = uintTraits;

        _burn( (newId == gfId1)? gfId2: gfId1 );
        tokensBurnt++;

        delete traitsToId[gf1UintTraits];
        delete traitsToId[gf2UintTraits];
    }  

    // ========================== Minting ==============================


    function _mintQuantity(uint256 quantity) internal {
        for (uint i = 0; i < quantity; i++) {
            _createGirlFriend(tokensMinted+i+1);            
        }
        tokensMinted += quantity;
    }

    // owner can mint up to giveAwayCount tokens for giveaways
    function mintForGiveaways(uint256 quantity) external onlyOwner {
        require(quantity > 0, "MG: Invalid quantity");
        require(tokensMinted+quantity <= maxSupply - tokensReserved, "MG: Max supply exceeded");
        require(giveAwaysReserved+quantity <= giveAwayCount, "MG: givaway count exceeded");
        giveAwaysReserved += quantity;            

        _mintQuantity(quantity);
    }

    function _mint(uint256 quantity) internal {
        require(quantity > 0, "MG: Invalid quantity");        

        require(tokensMinted+quantity <= maxSupply - tokensReserved, "MG: Max supply exceeded");
        require(quantity <= buyLimit, "MG: Buy limit per txn exceeded");
        require(price*quantity == msg.value, "MG: invalid price");

        // No eth stays on contract, they go directly to treasury
        payable(treasury).transfer(msg.value);

        _mintQuantity(quantity);
    }  

    function _hashMaxCount(address sender, uint8 maxCount, string memory nonce) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked( "\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(sender, maxCount, nonce))));         
    }

    function presaleMint( uint256 quantity, uint8 v, bytes32 r, bytes32 s, uint8 maxCount, string memory nonce) external payable {

        require(mintingEnabled && whitelistEnabled, "MG: Presale minting disabled"); 

        // verify ECDSA signature for parameters maxCount
        require(signerAddress == ecrecover( _hashMaxCount( _msgSender(), maxCount, nonce) , v, r, s), "MG: invalid hash or signature");
        require(maxCount <= 5, "MG: maxCount must be <= 5");

        require( balanceOf(_msgSender())+quantity <= uint256(maxCount), "MG: White list count exceeded");
        _mint(quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(mintingEnabled && !whitelistEnabled, "MG: Public minting disabled"); 
        // Prevent minting from smart contract
        require(_msgSender() == tx.origin, "MG: not EOA");
        _mint(quantity);
    }  

    function reserve(uint256 quantity) external payable {
        require(mintingEnabled && !whitelistEnabled, "MG: Public minting disabled"); 
        require(quantity > 0, "MG: Invalid quantity");

        require(tokensMinted+quantity <= maxSupply - tokensReserved, "MG: Max supply exceeded");
        require(reservedCount[_msgSender()]+quantity <= buyLimit, "MG: Maximum reservations exceeded");        
        require(price*quantity == msg.value, "MG: invalid price");

        // Prevent minting from smart contract
        require(_msgSender() == tx.origin, "MG: not EOA");

        // No eth stays on contract, they go directly to treasury
        payable(treasury).transfer(msg.value);        

        tokensReserved += quantity;
        reservedCount[_msgSender()] += uint16(quantity);
    }


    function claim() external {
        require(reservedCount[_msgSender()]>0, "MG: Nothing to claim");

        _mintQuantity(reservedCount[_msgSender()]);
        tokensReserved -= reservedCount[_msgSender()];
        reservedCount[_msgSender()] = 0;
    }


    // ========================== Other ==============================

    function withdraw() external onlyOwner{
        payable(_msgSender()).transfer(address(this).balance);
    }

    /*
    * @dev Gives access to dev or owner only
    */
    modifier devOrOwner() {
        _devOrOwner();
        _;
    }

    function _devOrOwner() internal view {
        require( (owner()==_msgSender())||(dev1==_msgSender())||(dev2==_msgSender()), "MG: Signer is not dev nor owner");
    }

    function setDevs(address newDev1, address newDev2) external onlyOwner{
        dev1 = newDev1;
        dev2 = newDev2;
    } 

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function setBaseURI(string memory newUri) external devOrOwner{
        _baseURIPrefix = newUri;
        emit BaseURIChanged(newUri);
    }

    function toggleWhitelist() external devOrOwner{
        whitelistEnabled = !whitelistEnabled;
    }  

    function setPrice(uint256 newPrice) external devOrOwner{
        price = newPrice;
        emit PriceChanged(newPrice);
    } 

    function setBuyLimit(uint256 newBuyLimit) external devOrOwner{
        buyLimit = newBuyLimit;
    }

    function setSigner(address newSigner) external devOrOwner{
        signerAddress = newSigner;
    }

    function toggleMinting() external devOrOwner{
        mintingEnabled = !mintingEnabled;
    }

    function toggleCombining() external devOrOwner{
        combineEnabled = !combineEnabled;
    } 
}