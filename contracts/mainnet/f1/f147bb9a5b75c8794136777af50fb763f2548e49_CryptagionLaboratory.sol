/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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



// OpenZeppelin Contracts v4.3.2 (token/ERC721/extensions/ERC721Enumerable.sol)
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








//Version Mainnet

//****************   MAIN CONTRACT  ****************************
//Who? A3g1X. When? The Fall before the Fall, 2021

contract CryptagionLaboratory is ERC721Enumerable{

	event NewEthogen(uint indexed ethogenID, uint16 dtypeID, uint8 rarity);

    //consts
    uint constant DEC18 =  10 ** 18;
    uint8 constant maxBaseStat = 200;

	using Counters for Counters.Counter;
	using Address for address;

	uint upgradefee = 0.001 ether;
	uint silverpackfee = 0.002 ether;

	uint legendarypackfee = 3 ether;
	uint sickpackfee = 0.2 ether;

    uint16 sickbonusbase = 400;
    uint16 sickfeebase = 1000;
    uint16 userxpgainbase = 200;

	uint16 founderpackcap1 = 800;
    uint8 founderpackcap2 = 230;
    uint8 founderpackcap3 = 80;
    
    uint16 xpDivisor = 400;
    uint8 sickburndivisor = 10;

// Base URI
    string private _baseURIextended;
    string private _contractURI;

  	Counters.Counter private _tokenIdTracker;
 
	address payable private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
	modifier onlyOwnerOf(uint _ethogenID) {
        require(msg.sender == ownerOf(_ethogenID));
        _;
	}

//main erc20 currency SICK
    ERC20Burnable public sicktoken;
//dtypes - types of ethogens - owner can add new types with rarity caps
	struct dtype{
  		
		uint16 raritycap1;
		uint16 raritycap2;
		uint16 raritycap3;
		uint8 raritycap4;
		uint8 raritycap5;
        uint8 baseinfect;
		uint8 basemort;
        uint8 baseresist;
        uint8 basestealth;
        uint8 classtype;
        uint8 legendarymaxcap;
	}
	
	dtype[] public dtypes;

//main token type: ethogen 
	struct Ethogen {

        uint birthday;
        uint birthblock;
        uint16 dtype;
        uint16 xp;
        uint8 rarity;
		uint8 level;
        uint8 baseinfect;
		uint8 basemort;
        uint8 baseresist;
        uint8 basestealth;

	}
	
	Ethogen[] public ethogens;

//additional stats 1:1 with Ethogen
	struct EthogenStats {

        uint8 modinfect;
		uint8 modmort;
        uint8 modresist;
        uint8 modstealth;
        uint8 boostinfect;
		uint8 boostmort;
        uint8 boostresist;
        uint8 booststealth;
        uint8 mutation;        
        uint8 trait;
        uint8 special;
	}
	
	EthogenStats[] public ethogenstats;

//user stats
	struct User {

        uint incubating1;
        uint incubating1date;
        uint incubating2;
        uint incubating2date;
        uint incubating3;
        uint incubating3date;
        uint16 xp;
		uint8 level;
	}

    mapping (address => User) public users;

//constructor  
	constructor()  ERC721('Cryptagion Ethogen', 'ETHOGEN') {  

        _baseURIextended = "https://lab.cryptagion.com/tokenmeta/getmetadata.php?tokenid=";
        _contractURI = "https://lab.cryptagion.com/tokenmeta/contractmetadata";
  
 		owner = payable(msg.sender);
        setCurrency(0x3aA22ff4781D61FD3dbb820e0e2D9533bf908d5C);
        
        //initial types
        addType(92,56,45,181,14,6);
        addType(107,16,38,132,21,8);
        addType(55,62,152,43,41,10);
        addType(74,157,63,31,35,6);
        addType(130,41,86,78,12,8);
        addType(56,77,133,87,41,6);
        addType(142,26,21,173,22,8);
        addType(72,64,98,95,33,10);

        //mint a common as #0
        mintRandom(62,1,1);
        mintRandom(5,5,5);
	}

//set and return URIs
 function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
 function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
 function setContractURI(string memory contractURI_) external onlyOwner() {
        _contractURI = contractURI_;
    }
  function contractURI() public view returns (string memory) {
        return _contractURI;
    }

//************************* SETTERS ******************************************
//this sets contract address of Cryptagion (SICK)
	function setCurrency(address _token) public onlyOwner {
       sicktoken = ERC20Burnable(_token);
    }
//add new ethogen type
	function addType ( uint8 _baseinfect, uint8 _basemort,  uint8 _baseresist, uint8 _basestealth, uint8 _classtype,uint8 _legendarycap) public onlyOwner{

    	require (_legendarycap <=20, " Max is 20");
    	require (_basemort <=maxBaseStat && _baseinfect <=maxBaseStat && _basestealth <=maxBaseStat && _baseresist <=maxBaseStat, " Max Base Stat");
	
	    //proportion of mint caps in relation to legendary
        uint16 commoncap = uint16(_legendarycap) * 150;
	    uint16 uncommoncap = uint16(_legendarycap) * 70;
		uint16 rarecap = uint16(_legendarycap) * 20;
		uint8 epiccap = uint8(_legendarycap) * 5;
	
        dtypes.push(dtype(commoncap,uncommoncap,rarecap,epiccap,_legendarycap,_baseinfect,_basemort,_baseresist,  _basestealth, _classtype,_legendarycap));
	}
//overwrite ethogen type in case of f**k ups
	function overwriteType (uint8 _baseinfect, uint8 _basemort, uint8 _baseresist, uint8 _basestealth, uint8 _classtype,uint _overwriteindex) external onlyOwner{

       require (_basemort <=maxBaseStat && _baseinfect <=maxBaseStat && _basestealth <=maxBaseStat && _baseresist <=maxBaseStat, " Max Base Stat");

       dtypes[_overwriteindex].baseresist = _baseresist;
       dtypes[_overwriteindex].basestealth = _basestealth;
       dtypes[_overwriteindex].baseinfect = _baseinfect;
       dtypes[_overwriteindex].basemort = _basemort;
       dtypes[_overwriteindex].classtype = _classtype;
	}

//************************* THE MINT ******************************************
//mint random card with weighted rarity chances if _raritymin is 0, otherwise set the rarity
	function mintRandom(uint _randomadd,uint8 _raritymin, uint8 _raritymax) private {

        uint randNonce = 3 + _randomadd;
        uint16 randomtype;
    	uint8 randomweight;
        uint8 finalrarity;

        //200 tries to get one that's not capped out.. just prevent endless loop
        while (randNonce < _randomadd + 200){
            
    	    randomtype = uint16(uint(keccak256(abi.encodePacked(block.number, msg.sender, randNonce))) % dtypes.length );
            randNonce++;

    	    if(_raritymin == 0){
        	    
        	    randomweight = uint8(uint(keccak256(abi.encodePacked(block.number + _tokenIdTracker.current() , msg.sender, randNonce))) % 100  + 1);

                if(_raritymax == 2)
                {
                    if (randomweight < 66){finalrarity = 1;}
                    else {finalrarity = 2;}
                    
                }
                else if(_raritymax == 3)
                {
                    if (randomweight < 60){finalrarity = 1;}
                    else if (randomweight < 90){finalrarity = 2;}
                    else {finalrarity = 3;}
                }
    	    }
            else{
                finalrarity = _raritymin;
            }
    	    //particular mintcap?
    	    if(checkmintcaps(randomtype,finalrarity)){
    	             _mintEthogen(msg.sender, randomtype, finalrarity);
    	            return;
    	    }
            randNonce++;
        }
        //massive fail       
        revert("No Cap, Try again")  ;
	}

//mint new ethogen
	function _mintEthogen(address _to, uint16 _dtypeID, uint8 _rarity) private {

	    uint16 tmpfactor;

        //set base stats based on rarity
		if(_rarity == 1){tmpfactor = 1000;}
		else if(_rarity == 2){tmpfactor = 1030;}
		else if(_rarity == 3){tmpfactor = 1100;}
		else if(_rarity == 4){tmpfactor = 1180;}
		else if(_rarity == 5){tmpfactor = 1275;}
		else {revert("Bad Rarity");}

        //the real minting
        uint256 newNftTokenId = _tokenIdTracker.current();
       
        _mint(_to, newNftTokenId);
  
        //percents increase based on rarity
        uint8 finalinfect =  uint8((uint32(dtypes[_dtypeID].baseinfect) * uint32(tmpfactor))/1000);
        uint8 finalmort =  uint8((uint32(dtypes[_dtypeID].basemort) * uint32(tmpfactor))/1000);
        uint8 finalresist =  uint8((uint32(dtypes[_dtypeID].baseresist) * uint32(tmpfactor))/1000);
        uint8 finalstealth =  uint8((uint32(dtypes[_dtypeID].basestealth) * uint32(tmpfactor))/1000);
        
        //main Ethogen
        ethogens.push(Ethogen(block.timestamp,block.number,_dtypeID, 0, _rarity, 0,finalinfect,finalmort,finalresist,finalstealth));

        //random shizen
        uint8 randommutation = uint8(uint(keccak256(abi.encodePacked(block.number + _tokenIdTracker.current() + 11, msg.sender))) % 255  + 1);
        uint8 randomtrait = uint8(uint(keccak256(abi.encodePacked(block.timestamp + _tokenIdTracker.current() + 5, msg.sender))) % 255  + 1);
        uint8 randomspecial = uint8(uint(keccak256(abi.encodePacked(block.timestamp + _tokenIdTracker.current() + 3, msg.sender))) % 255  + 1);

        //EthogenStats 1:1 with Ethogens
        ethogenstats.push(EthogenStats(1,1,1,1,0,0,0,0,randommutation,randomtrait,randomspecial));

        _tokenIdTracker.increment();
		
        //decrement specific value in mintcaps mapping and raritycaps array
		if(_rarity == 1){dtypes[_dtypeID].raritycap1--;}
		if(_rarity == 2){dtypes[_dtypeID].raritycap2--;}
		if(_rarity == 3){dtypes[_dtypeID].raritycap3--;}
		if(_rarity == 4){dtypes[_dtypeID].raritycap4--;}
		if(_rarity == 5){dtypes[_dtypeID].raritycap5--;}

        //emit the event 	
		emit NewEthogen(newNftTokenId, _dtypeID, _rarity);
    }
    
//mint a specific ethogen
	function mintOwner(address _to, uint16 _dtypeID, uint8 _rarity) external onlyOwner {
    	 require (checkmintcaps(_dtypeID,_rarity), "Cap reached");
		 _mintEthogen(_to, _dtypeID, _rarity);
	}	    
    
//************************* SET FEES ******************************************
//set the upgradefee
	function setUpgradeFee(uint _fee) external onlyOwner {
		upgradefee = _fee;
	}
//set the silver fee
	function setSilverpackFee(uint _fee) external onlyOwner {
		silverpackfee = _fee;
	}
//set the legendary fee
	function setLegendarypackFee(uint _fee) external onlyOwner {
		legendarypackfee = _fee;
	}
//set the sickpack fee
	function setSickpackFee(uint _fee) external onlyOwner {
		sickpackfee = _fee;
	}	
//set the userxpgainbase
	function setUserXPgainBase(uint16 _newval) external onlyOwner {
		userxpgainbase = _newval;
	}	
//set the sickbonusbase
	function setSickBonusBase(uint16 _newval) external onlyOwner {
		sickbonusbase = _newval;
	}	
//set the sickfeebase
	function setSickFeeBase(uint16 _newval) external onlyOwner {
		sickfeebase = _newval;
	}	
//set the sickburndivisor
	function setSickBurnDivisor(uint8 _newval) external onlyOwner {
		sickburndivisor = _newval;
	}	
//set the xpDivisor
	function setXpDivisor(uint16 _newval) external onlyOwner {
		xpDivisor = _newval;
	}	

//************************* PAYABLES ******************************************
//buy a pack
	function buyCardPack(uint8 _packtype) external payable {
		require((msg.value == silverpackfee || msg.value == 10 * silverpackfee || msg.value == 100 * silverpackfee || msg.value == sickpackfee || msg.value == legendarypackfee ) ," Fee must match one listed");

        uint16 sickgain;
        uint16 xpgain;
        
        if(msg.value == silverpackfee && _packtype == 1){
            //first uncom
    		mintRandom(13,2,2);
    		mintRandom(17,1,1);

    		if(founderpackcap1 > 0){
    		    
    		    mintRandom(3,1,1);
    		    sickgain = sickbonusbase * 2;
                xpgain = userxpgainbase * 2;
    		    
    		    founderpackcap1 --;
    		    
    		}
            else{
    		    sickgain = sickbonusbase;
        	    xpgain = userxpgainbase;
            }

        }
        else if(msg.value == silverpackfee * 10 && _packtype == 2){
            //first rare
    		mintRandom(7,3,3);
    		mintRandom(4,2,2);

            if(founderpackcap2 > 0){
                
                mintRandom(13,0,2);
    		    sickgain = sickbonusbase * 5;
        	    xpgain = userxpgainbase * 3;

    		    founderpackcap2 --;
    		}
            else{
                sickgain = sickbonusbase * 2;
                xpgain = userxpgainbase * 2;
            }

        }
        else if(msg.value == silverpackfee * 100 && _packtype == 3){
        
            //first epic
    		mintRandom(24,4,4);
    		mintRandom(12,0,3);

            if(founderpackcap3 > 0){
                
    		    mintRandom(23,0,2);
    		    sickgain = sickbonusbase * 10;
                xpgain = userxpgainbase * 6;
 
    		    founderpackcap3 --;
    		}
            else{
    		    sickgain = sickbonusbase * 5;
                xpgain = userxpgainbase * 4;
            }
        }
        else if(msg.value == sickpackfee && _packtype == 200){
        
    		mintRandom(9,0,2);
    		sickgain = sickbonusbase * 10;
            xpgain = userxpgainbase * 2;
        }
        else if(msg.value == legendarypackfee && _packtype == 250){
        
    		mintRandom(7,5,5);
      		mintRandom(11,4,4);
    		mintRandom(5,3,3);

    		sickgain = sickbonusbase * 20;
            xpgain = userxpgainbase * 10;
        }
        else if(msg.value == legendarypackfee && _packtype == 253){
        
    		mintRandom(13,5,5);
    		sickgain = sickbonusbase * 10;
            xpgain = userxpgainbase * 5;
        }
        else{
             revert("Wrong Amount ");
        }
        //give Sick, burn Sick, gain XP
  		sicktoken.transfer(msg.sender,sickgain * DEC18);
		sicktoken.burn((sickgain * DEC18 ) / sickburndivisor);
    	useraddxp(uint16(xpgain));
    }

//*************************  SICK PAYABLE ******************************************
// buy user xp with sicktoken
	function buyXPwithSick(uint16 _sicktokens) external {
    
        require (_sicktokens > 0 && _sicktokens <= 32000 && (users[msg.sender].xp + _sicktokens) <= 32000 , "No_Max SICK");
    
        sicktoken.transferFrom(address(msg.sender), address(this), _sicktokens * DEC18);
        useraddxp(_sicktokens);
    }

// buy small pack with SICK
	function buyPackwithSick(uint8 _pack) external {
            
            uint16 xpgain;
            uint16 sickfee;
            
            if(_pack == 1){
                
                sickfee = sickfeebase;
                xpgain = sickfeebase/2;
    
    		    mintRandom(14,0,2);
            }
            else{
                sickfee = sickfeebase * 10;
                xpgain = sickfeebase * 5;
                
                mintRandom(12,4,4);
            }

           sicktoken.transferFrom(address(msg.sender), address(this), sickfee * DEC18);
           useraddxp(xpgain);
           mintRandom(13,2,2);
    }

// mutate with SICK
	function mutate(uint _ethogenID, uint16 _rand) external onlyOwnerOf(_ethogenID){

            sicktoken.transferFrom(address(msg.sender), address(this), sickfeebase * 5 * DEC18);
    		sicktoken.burn((sickfeebase * DEC18) / sickburndivisor);
        	useraddxp(sickfeebase);
           
            ethogenstats[_ethogenID].mutation = uint8(uint(keccak256(abi.encodePacked(block.number + _tokenIdTracker.current() + _rand, msg.sender))) % 255  + 1);
     }

//************************* EXTERNAL ETHOGEN UPDATES ******************************************

// boost an ethogen with SickToken
	function boostStat(uint _ethogenID,uint8 _sicktokens,uint8 _stat) external onlyOwnerOf(_ethogenID){
    
        uint8 finalfee;

        if (_stat == 1){
             if(uint16(ethogenstats[_ethogenID].boostinfect) + uint16(_sicktokens) > 255){
                
                 finalfee = uint8(255 - ethogenstats[_ethogenID].boostinfect);
                 ethogenstats[_ethogenID].boostinfect  = 255;
             }
             else{
                 ethogenstats[_ethogenID].boostinfect  = uint8(ethogenstats[_ethogenID].boostinfect + _sicktokens);
                 finalfee = _sicktokens;
             }  
        }
        else if (_stat == 2){
              if(uint16(ethogenstats[_ethogenID].boostmort) + uint16(_sicktokens) > 255){
                 finalfee = uint8(255 - ethogenstats[_ethogenID].boostmort);
                 ethogenstats[_ethogenID].boostmort  = 255;
             }
             else{
                 ethogenstats[_ethogenID].boostmort  = uint8(ethogenstats[_ethogenID].boostmort + _sicktokens);
                 finalfee = _sicktokens;
             }  
        }
        else if (_stat == 3){
             if(uint16(ethogenstats[_ethogenID].boostresist) + uint16(_sicktokens) > 255){
                 finalfee = uint8(255 - ethogenstats[_ethogenID].boostresist);
                 ethogenstats[_ethogenID].boostresist  = 255;
             }
             else{
                 ethogenstats[_ethogenID].boostresist  = uint8(ethogenstats[_ethogenID].boostresist + _sicktokens);
                 finalfee = _sicktokens;
             }  
        }
        else if (_stat == 4){
              if(uint16(ethogenstats[_ethogenID].booststealth) + uint16(_sicktokens) > 255){
                 finalfee = uint8(255 - ethogenstats[_ethogenID].booststealth);
                 ethogenstats[_ethogenID].booststealth  = 255;
             }
             else{
                 ethogenstats[_ethogenID].booststealth  = uint8(ethogenstats[_ethogenID].booststealth + _sicktokens);
                 finalfee = _sicktokens;
             }  
        }
        //take some SICK for the boost
        if(finalfee > 0){sicktoken.transferFrom(address(msg.sender), address(this), finalfee * DEC18);}
    }

//************************* INCUBATE ******************************************
//lock token in incubator for upgrade fee
	function incubatein1(uint _ethogenID) external payable onlyOwnerOf(_ethogenID){
		
		require (users[msg.sender].incubating1 == 0 , " Full");
		require(msg.value == upgradefee);
		
	    users[msg.sender].incubating1date = uint(block.timestamp);
        users[msg.sender].incubating1 = _ethogenID;

	}
	function incubatein2(uint _ethogenID) external payable onlyOwnerOf(_ethogenID){
		
		require (users[msg.sender].incubating2 == 0 , " Full");
		require (users[msg.sender].level >= 50 , " Level 50");
		require(msg.value == upgradefee);
		
	    users[msg.sender].incubating2date = uint(block.timestamp);
        users[msg.sender].incubating2 = _ethogenID;

	}
	function incubatein3(uint _ethogenID) external payable onlyOwnerOf(_ethogenID){
		
		require (users[msg.sender].incubating3 == 0 , " Full");
		require(msg.value == upgradefee*3);
		
	    users[msg.sender].incubating3date = uint(block.timestamp);
        users[msg.sender].incubating3 = _ethogenID;
	}

//take out of incubator
	function incubateout(uint8 _whichone) external {
		
		uint ethogenID;
		uint16 xpgained;
		
		if(_whichone == 1){
		    if(users[msg.sender].incubating1 == 0){revert("Empty");}
		    ethogenID =  users[msg.sender].incubating1;
		    users[msg.sender].incubating1 = 0;
            xpgained = uint16((block.timestamp - users[msg.sender].incubating1date)/xpDivisor); 
		}	
		else if(_whichone == 2){
		    if(users[msg.sender].incubating2 == 0){revert("Empty");}
		    ethogenID =  users[msg.sender].incubating2;
		    users[msg.sender].incubating2 = 0;
            xpgained = uint16((block.timestamp - users[msg.sender].incubating2date)/xpDivisor); 
		}	
		else if(_whichone == 3){
		    if(users[msg.sender].incubating3 == 0){revert("Empty");}
		    ethogenID =  users[msg.sender].incubating3;
		    users[msg.sender].incubating3 = 0;
            xpgained = uint16((block.timestamp - users[msg.sender].incubating3date) * 3 /xpDivisor); 
		}	

        if(ownerOf(ethogenID) == msg.sender){
            addxp(ethogenID,xpgained);
        }	
    }

//*************************  XP AND LEVELS ******************************************
//add xp check Max
	function addxp(uint _ethogenID,uint16 _xp) private onlyOwnerOf(_ethogenID){
        
        if(_xp > 32000){_xp=32000;}
        if(ethogens[_ethogenID].xp + _xp > 32000){
            ethogens[_ethogenID].xp = 32000;
        }
        else{
            ethogens[_ethogenID].xp += _xp;
        }

	    uint8 newlevel = calclevel(ethogens[_ethogenID].xp);
	    uint8 newmod = uint8(5 + (newlevel * 2) + (10 *ethogens[_ethogenID].rarity));
	    
	    ethogens[_ethogenID].level = newlevel;

        uint8 debuff = uint8(newlevel/4);
        uint8 debuff2 = uint8(newlevel/8);

        ethogenstats[_ethogenID].modmort = newmod;
        ethogenstats[_ethogenID].modinfect = newmod;
        ethogenstats[_ethogenID].modstealth = newmod;
        ethogenstats[_ethogenID].modresist = newmod;

	    if (dtypes[ethogens[_ethogenID].dtype].classtype < 20){ ethogenstats[_ethogenID].modmort = newmod - 1;ethogenstats[_ethogenID].modstealth = newmod - debuff2;}
        else if (dtypes[ethogens[_ethogenID].dtype].classtype < 30){ethogenstats[_ethogenID].modinfect = newmod - debuff;ethogenstats[_ethogenID].modresist = newmod - 1;}
        else if (dtypes[ethogens[_ethogenID].dtype].classtype < 40){ethogenstats[_ethogenID].modstealth = newmod - debuff;ethogenstats[_ethogenID].modinfect = newmod - 1;}
        else if (dtypes[ethogens[_ethogenID].dtype].classtype < 50){ethogenstats[_ethogenID].modresist = newmod - debuff;ethogenstats[_ethogenID].modmort = newmod - debuff2;}
        else if (dtypes[ethogens[_ethogenID].dtype].classtype < 60){ethogenstats[_ethogenID].modresist = newmod - 1;ethogenstats[_ethogenID].modinfect = newmod - debuff2;}
        else if (dtypes[ethogens[_ethogenID].dtype].classtype < 70){ethogenstats[_ethogenID].modmort = newmod - debuff;ethogenstats[_ethogenID].modresist = newmod - debuff2;}
    }

//add xp check Max
	function useraddxp(uint16 _xp) private {
        
        if(_xp > 32000){_xp=32000;}
         //max xp 32k
        if(users[msg.sender].xp + _xp > 32000){
            users[msg.sender].xp = 32000;
        }
        else{
             users[msg.sender].xp += _xp; 
        }
		users[msg.sender].level = calclevel(users[msg.sender].xp);
     }
	
//*************************  GETTERS ******************************************
//showfees
	function getfees() external view returns (uint,uint,uint,uint) {
		return(upgradefee,silverpackfee,sickpackfee,legendarypackfee);
	}
//show founder caps
	function getfoundercaps() external view returns (uint16,uint8,uint8) {
		return(founderpackcap1,founderpackcap2,founderpackcap3);
	}
//show bases
	function getbasenumbers() external view returns (uint16,uint16,uint16,uint8,uint16) {
		return(userxpgainbase,sickbonusbase,sickfeebase,sickburndivisor,xpDivisor);
	}

//************************* PRIVATE ******************************************
//check if cap is reached
    function checkmintcaps(uint16 _dtypeID,uint8 _rarity) private view returns (bool){
        
        if(_rarity == 1 && dtypes[_dtypeID].raritycap1<=0){return false;}
        if(_rarity == 2 && dtypes[_dtypeID].raritycap2<=0){return false;}
        if(_rarity == 3 && dtypes[_dtypeID].raritycap3<=0){return false;}
        if(_rarity == 4 && dtypes[_dtypeID].raritycap4<=0){return false;}
        if(_rarity == 5 && dtypes[_dtypeID].raritycap5<=0){return false;}

        return true;
    }
//square root yo
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }   
//get level from xp
   function calclevel(uint16 _xp) internal pure returns (uint8) {
       return uint8(sqrt(5*uint32(_xp)) / 4);
   }
   
//************************* STEP 3  ******************************************
//step 3: (from the underpants)
	function collectDonations(address payable _shareholder1,address payable _shareholder2,uint _divamount) external onlyOwner {

		_shareholder1.transfer(_divamount /2);
		_shareholder2.transfer(_divamount /2);
	}
	function collectSick(uint _sickamount) external onlyOwner {
		sicktoken.transfer(owner, _sickamount * DEC18);
	}
//end contract
}