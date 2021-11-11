/**
 *Submitted for verification at polygonscan.com on 2021-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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


contract OnchainBirthdayCake is ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    uint256 public cost = 1 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 150;
    bool public paused = false;
  
    constructor() ERC721("OnChain Birthday Cake", "OCBC") Ownable() {}
    
    // public
    function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    
    if (msg.sender != owner()) {
          require(msg.value >= cost * _mintAmount);
        }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }
  
    function colorBG() internal view returns (uint256) {
        uint256 randombg = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.coinbase, block.number, block.gaslimit))) % 361;
        return randombg;
    }
    
    function randShadow() internal view returns (uint256) {
        uint256 randomshadow = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.coinbase, block.number))) % 361;
        return randomshadow;
    }
    
    function randCandle() internal view returns (uint256) {
        uint256 randomcandle = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, block.coinbase))) % 361;
        return randomcandle;
    }
    
    function rand1st4thLayer() internal view returns (uint256) {
        uint256 randomlayer14 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 361;
        return randomlayer14;
    }
    
    function rand2nd5thLayer() internal view returns (uint256) {
        uint256 randomlayer25 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 361;
        return randomlayer25;
    }
    
    function rand3rd6thLayer() internal view returns (uint256) {
        uint256 randomlayer36 = uint256(keccak256(abi.encodePacked(block.timestamp))) % 361;
        return randomlayer36;
    }
    
    function rand1stLight() internal view returns (uint256) {
        uint256 randomlight1 = uint256(keccak256(abi.encodePacked(block.number, block.gaslimit))) % 361;
        return randomlight1;
    }
    
    function rand2ndLight() internal view returns (uint256) {
        uint256 randomlight2 = uint256(keccak256(abi.encodePacked(block.number, block.difficulty, block.gaslimit))) % 361;
        return randomlight2;
    }
    
    function randFire() internal view returns (uint256) {
        uint256 randomfire = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.coinbase, block.number, block.gaslimit))) % 361;
        return randomfire;
    }
    
    function rand1stchips() internal view returns (uint256) {
        uint256 randomchips = uint256(keccak256(abi.encodePacked(msg.sender, block.coinbase, block.number, block.gaslimit))) % 361;
        return randomchips;
    }
    
    function rand2ndchips() internal view returns (uint256) {
        uint256 randomchips = uint256(keccak256(abi.encodePacked(msg.sender, block.number, block.gaslimit))) % 361;
        return randomchips;
    }
    
   
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[31] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" width="800" height="800"><defs><clipPath clipPathUnits="userSpaceOnUse" id="a"><path d="M0 600h600V0H0Z"/></clipPath></defs><g clip-path="url(#a)" transform="matrix(1.33333 0 0 -1.33333 0 800)"><path d="M 0.596,-2.066 H 600.719 V 598.056 H 0.596 Z" style="fill:hsl(';
        
        parts[1] = toString(colorBG());
        
        parts[2] = ', 100%, 95%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M358.442 49.602c99.673 0 180.969 23.209 180.969 51.664 0 28.456-81.296 51.667-180.969 51.667-99.674 0-180.968-23.211-180.968-51.667 0-28.455 81.294-51.664 180.968-51.664" style="fill:#d3d3d3;fill-opacity:.3;fill-rule:evenodd;stroke:none"/><path d="M296.399 436.538v-81.74c0-4.037 21.91-4.036 21.91 0v81.74c-6.651-2.474-15.262-2.475-21.91 0" style="fill:hsl(';
        
        parts[3] = toString(randCandle());
        
        parts[4] = ', 100%, 50%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M212.084 280.677v-12.632c0-58.669 184.727-57.578 184.727 0v12.632c-33.783-38.735-150.945-38.735-184.727 0" style="fill:hsl(';
        
        parts[5] = toString(rand1st4thLayer());
        
        parts[6] = ', 50%, 40%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M212.084 312.663v-7.811c0-58.147 184.727-58.446 184.727.138-4.146-9.462-7.887-18.732-20.414-15.397-9.445 2.513-14.612-1.518-19.395-5.25-4.583-3.575-8.914-6.955-15.669-6.955-6.333 0-10.356 1.753-13.534 3.134-9.226 4.015-12.411-15.574-37.403-1.014-5.181 3.018-6.617 4.05-12.371 2.655-6.713-1.628-14.144-3.429-22.618 4.274-16.637 15.12-18.865 3.574-29.761 9.358-7.113 3.775-8.947 11.155-12.753 17.391-.272-.187-.54-.361-.809-.523" style="fill:hsl(';
        
        parts[7] = toString(rand2nd5thLayer());
        
        parts[8] = ', 52%, 65%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M400.178 320.476c6.813 6.455-1.261 29.167-6.982 35.204-16.592 17.438-42.346 23.528-65.501 26.24v-27.122c0-16.762-40.685-16.763-40.685 0v27.71c-33.105-2.724-83.148-14.58-80.892-56.81.109-2.059.416-3.749.917-4.897.165.012.324.013.488.011 4.661 3.715 7.978 4.125 11.998-.804 3.48-4.268 6.083-13.567 10.526-15.926 6.786-3.601 12.553 6.661 31.667-10.714 4.803-4.366 9.694-3.18 14.11-2.109 8.566 2.075 11.723.747 19.265-3.647 5.817-3.387 12.183-7.096 23.666 1.22 5.034 3.647 8.227 2.256 12.785.272 2.359-1.027 5.348-2.328 9.793-2.328 3.582 0 6.658 2.4 9.911 4.939 6.555 5.114 13.633 10.636 27.537 6.935 4.573-1.216 6.794 3.916 8.821 8.599 2.341 5.407 4.532 10.471 9.913 11.834.641.163 2.157.913 2.663 1.393" style="fill:hsl(';
        
        parts[9] = toString(rand3rd6thLayer());
        
        parts[10] = ', 100%, 70%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M174.049 146.803v-23.139c0-84.455 262.97-84.451 262.97 0v23.139c-42.675-59.067-220.297-59.067-262.97 0" style="fill:hsl(';
        
        parts[11] = toString(rand1st4thLayer());
        
        parts[12] = ', 50%, 40%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M390.496 339.902a4.678 4.678 0 1 0 7.261-5.904 47.364 47.364 0 0 0-4.001-4.334c-17.468-16.737-51.729-25.339-86.294-25.808-34.473-.467-69.601 7.143-88.934 22.825a53.232 53.232 0 0 0-4.882 4.473 4.684 4.684 0 0 0 6.75 6.492 43.758 43.758 0 0 1 4.037-3.704c17.585-14.265 50.397-21.175 82.919-20.734 32.432.44 64.228 8.177 79.913 23.204a38.245 38.245 0 0 1 3.231 3.49" style="fill:hsl(';
        
        parts[13] = toString(rand1stLight());
        
        parts[14] = ', 100%, 83%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M174.049 187.363v-12.058c0-84.453 262.97-84.453 262.97 0v7.667c-1.509-1.837-2.971-5.214-4.504-8.752-4.684-10.825-9.818-22.686-25.55-18.5-14.152 3.767-21.786-2.191-28.855-7.704-13.864-10.818-22.772-12.203-39.058-5.118-2.921 1.272-4.967 2.165-6.836.809-22.042-15.965-34.278-8.839-45.452-2.328-7.73 4.505-10.115 6.021-18.747 3.926-8.956-2.172-18.87-4.576-30.02 5.559-14.865 13.51-22.2 12.551-28.284 11.754-16.191-2.118-21.429 6.449-28.11 19.846-1.456 2.921-2.784 5.581-3.951 7.012-.28.344-2.62-1.595-3.603-2.113" style="fill:hsl(';
        
        parts[15] = toString(rand2nd5thLayer());
        
        parts[16] = ', 52%, 65%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M441.15 195.857c6.181 5.857 4.088 19.61 2.23 26.942-5.67 22.375-17.127 33.891-37.199 44.072-2.165-68.799-199.473-69.477-203.421-.955-23.362-12.492-38.579-33.3-37.075-61.457.129-2.411.643-6.895 2.183-8.89 2.28.76 1.31-.608 3.803 1.425 9.419 7.685 14.707-3.084 18.329-10.349 4.661-9.343 7.193-16.229 18.503-14.748 8.041 1.053 17.733 2.323 35.801-14.101 7.479-6.799 14.852-5.01 21.511-3.397 11.447 2.779 15.548.968 25.642-4.916 8.668-5.048 18.154-10.572 35.259 1.815 6.192 4.486 10.263 2.714 16.076.184 13.002-5.66 18.584-4.66 29.56 3.905 8.839 6.896 18.385 14.345 36.997 9.391 7.975-2.123 11.433 5.862 14.585 13.145 3.091 7.144 5.987 13.833 12.638 15.518 1.396.353 3.558 1.449 4.578 2.416" style="fill:hsl(';
        
        parts[17] = toString(rand3rd6thLayer());
        
        parts[18] = ', 100%, 70%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M427.728 223.294a4.679 4.679 0 1 0 7.26-5.904 64.134 64.134 0 0 0-5.459-5.911c-24.149-23.138-71.722-35.035-119.789-35.684-47.974-.652-96.796 9.884-123.566 31.602a72.22 72.22 0 0 0-6.679 6.121 4.68 4.68 0 1 0 6.747 6.491 63.578 63.578 0 0 1 5.836-5.351c25.024-20.302 71.527-30.137 117.553-29.513 45.933.625 91.042 11.653 113.407 33.081a55.166 55.166 0 0 1 4.69 5.068" style="fill:hsl(';
        
        parts[19] = toString(rand2ndLight());
        
        parts[20] = ', 100%, 83%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M308.078 460.38c26.463 11.726 4.078 40.96-5.867 57.475-14.7-27.573-20.046-37.295 5.867-57.475" style="fill:hsl(';
        
        parts[21] = toString(randFire());
        
        parts[22] = ', 100%, 80%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M291.62 443.123v-81.74c0-4.036 21.909-4.036 21.909 0v81.74c-6.648-2.474-15.26-2.475-21.909 0m-84.316-155.861c33.783-38.735 150.946-38.735 184.728 0V274.63c0-57.578-184.728-58.668-184.728 0zm0 31.985c.268.163.538.336.808.524 3.81-6.236 5.644-13.616 12.756-17.392 10.897-5.783 13.125 5.763 29.759-9.358 8.476-7.703 15.906-5.901 22.619-4.273 5.754 1.394 7.19.363 12.371-2.655 24.991-14.56 28.178 5.029 37.404 1.014 3.177-1.381 7.203-3.134 13.534-3.134 6.755 0 11.087 3.38 15.668 6.955 4.784 3.732 9.95 7.763 19.396 5.249 12.527-3.334 16.267 5.936 20.413 15.398 0-58.583-184.728-58.285-184.728-.138zm188.095 7.813c6.813 6.455-1.261 29.168-6.981 35.205-16.594 17.438-42.347 23.528-65.501 26.241v-27.123c0-16.762-40.684-16.763-40.684 0v27.71c-33.107-2.724-83.149-14.58-80.893-56.81.11-2.059.417-3.748.917-4.897.163.012.323.013.488.011 4.662 3.715 7.977 4.124 11.998-.804 3.48-4.268 6.082-13.567 10.526-15.926 6.784-3.601 12.55 6.662 31.667-10.714 4.804-4.365 9.693-3.181 14.109-2.109 8.566 2.074 11.723.748 19.267-3.647 5.815-3.387 12.184-7.096 23.664 1.22 5.034 3.646 8.228 2.256 12.785.272 2.359-1.027 5.347-2.328 9.794-2.328 3.583 0 6.657 2.4 9.911 4.939 6.555 5.113 13.633 10.636 27.537 6.934 4.571-1.215 6.794 3.916 8.819 8.599 2.342 5.409 4.533 10.472 9.915 11.835.641.163 2.157.913 2.662 1.392m-226.13-173.672c42.674-59.066 220.295-59.066 262.97 0v-23.139c0-84.451-262.97-84.455-262.97 0zm0 40.561c.986.517 3.324 2.456 3.604 2.112 1.168-1.431 2.495-4.091 3.951-7.012 6.682-13.397 11.92-21.964 28.112-19.846 6.083.797 13.416 1.756 28.281-11.753 11.152-10.137 21.065-7.733 30.021-5.56 8.632 2.095 11.016.579 18.747-3.926 11.177-6.511 23.411-13.638 45.452 2.328 1.87 1.354 3.915.463 6.835-.809 16.287-7.086 25.196-5.702 39.06 5.118 7.068 5.514 14.703 11.471 28.855 7.704 15.731-4.186 20.866 7.674 25.548 18.498 1.534 3.54 2.995 6.917 4.504 8.754v-7.667c0-84.453-262.97-84.453-262.97 0zm272.358.666v-64.366c0-97.11-281.746-97.11-281.746 0v62.91c-6.364 2.643-8 11.298-8.327 17.407-1.803 33.735 17.834 58.478 46.364 72.421V318.623c-1.81 1.002-3.202 2.688-4.189 4.906-.989 2.224-1.57 5.072-1.741 8.277-2.606 48.741 51.433 63.627 90.245 66.681v55.299c0 5.426 4.701 8.907 9.332 10.644-27.347 23.372-13.653 44.197 1.541 71.669 1.695 3.177 6.291 3.352 8.168.176 11.018-18.598 38.819-55.04 14.707-72.904 4.293-2.222 6.936-5.582 6.936-9.585V397.92c22.627-2.526 57.456-10.794 72.361-29.282 9.355-9.992 18.131-38.263 6.144-48.757V283.87c24.134-11.267 39.448-25.278 46.274-52.213 2.951-11.639 4.485-28.613-6.069-37.042m-5.256 7.827c6.183 5.858 4.089 19.608 2.231 26.942-5.67 22.374-17.127 33.89-37.2 44.072-2.166-68.799-199.472-69.477-203.421-.955-23.363-12.492-38.579-33.3-37.073-61.457.129-2.411.643-6.895 2.181-8.89 2.282.76 1.31-.608 3.804 1.425 9.418 7.685 14.705-3.084 18.329-10.35 4.658-9.342 7.193-16.228 18.503-14.747 8.039 1.053 17.732 2.323 35.8-14.101 7.48-6.799 14.854-5.012 21.514-3.397 11.444 2.779 15.544.966 25.641-4.916 8.665-5.048 18.152-10.574 35.257 1.815 6.192 4.484 10.264 2.714 16.076.182 13.004-5.658 18.585-4.658 29.56 3.907 8.839 6.896 18.385 14.343 36.997 9.391 7.976-2.125 11.433 5.86 14.585 13.145 3.092 7.144 5.989 13.833 12.638 15.518 1.395.353 3.558 1.449 4.578 2.416m-133.07 264.523c26.462 11.726 4.079 40.96-5.867 57.475-14.703-27.573-20.048-37.295 5.867-57.475" style="fill:#000';
        
        parts[23] = ';fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M183.244 132.97c.617 0 1.119-1.112 1.119-2.483 0-1.373-.502-2.484-1.119-2.484-.618 0-1.118 1.111-1.118 2.484 0 1.371.5 2.483 1.118 2.483m34.526-19.623c.893 0 1.615-.945 1.615-2.113 0-1.164-.722-2.11-1.615-2.11-.89 0-1.614.946-1.614 2.11 0 1.168.724 2.113 1.614 2.113M204.108 92.73c1.304 0 2.361-.834 2.361-1.863 0-1.028-1.057-1.862-2.361-1.862-1.301 0-2.358.834-2.358 1.862 0 1.029 1.057 1.863 2.358 1.863m78.246-13.167c1.166 0 2.11-1.167 2.11-2.606 0-1.439-.944-2.607-2.11-2.607s-2.112 1.168-2.112 2.607c0 1.439.946 2.606 2.112 2.606m58.249.499c1.233 0 2.234-1.058 2.234-2.358 0-1.304-1.001-2.361-2.234-2.361-1.235 0-2.236 1.057-2.236 2.361 0 1.3 1.001 2.358 2.236 2.358m45.641 12.17c.858 0 1.551-.666 1.551-1.491 0-.821-.693-1.487-1.551-1.487-.856 0-1.552.666-1.552 1.487 0 .825.696 1.491 1.552 1.491m3.602 12.794c.582 0 1.056-.946 1.056-2.111 0-1.167-.474-2.111-1.056-2.111-.584 0-1.056.944-1.056 2.111 0 1.165.472 2.111 1.056 2.111m13.475 10.929c1.92 0 3.478-1.11 3.478-2.483 0-1.372-1.558-2.483-3.478-2.483-1.921 0-3.478 1.111-3.478 2.483 0 1.373 1.557 2.483 3.478 2.483m-40.986-16.642c1.44 0 2.608-1.223 2.608-2.734 0-1.507-1.168-2.732-2.608-2.732-1.439 0-2.606 1.225-2.606 2.732 0 1.511 1.167 2.734 2.606 2.734M311.788 85.65a1.739 1.739 0 1 0-.002-3.478 1.739 1.739 0 0 0 .002 3.478m-33.658 7.204c1.304 0 2.359-.835 2.359-1.864 0-1.028-1.055-1.862-2.359-1.862-1.302 0-2.359.834-2.359 1.862 0 1.029 1.057 1.864 2.359 1.864m-36.514-.994c2.125 0 3.849-.999 3.849-2.234 0-1.235-1.724-2.235-3.849-2.235-2.126 0-3.85 1-3.85 2.235 0 1.235 1.724 2.234 3.85 2.234m-22.48 7.702c1.784 0 3.23-1.615 3.23-3.604 0-1.988-1.446-3.6-3.23-3.6-1.783 0-3.229 1.612-3.229 3.6 0 1.989 1.446 3.604 3.229 3.604m-17.884 11.176c1.234 0 2.235-1.168 2.235-2.608 0-1.44-1.001-2.607-2.235-2.607-1.235 0-2.234 1.167-2.234 2.607 0 1.44.999 2.608 2.234 2.608m-11.798 9.44c.478 0 .87-2.057.87-4.596 0-2.538-.392-4.595-.87-4.595-.481 0-.871 2.057-.871 4.595 0 2.539.39 4.596.871 4.596" style="fill:hsl(';
        
        parts[24] = toString(rand1stchips());
        
        parts[25] = ', 100%, 50%);fill-opacity:1;fill-rule:evenodd;stroke:none"/><path d="M376.315 265.188c-.416.021-.803-.511-.865-1.188-.061-.677.227-1.24.642-1.261.418-.021.804.512.867 1.188.062.676-.227 1.241-.644 1.261m-24.171-8.542c-.602.03-1.13-.413-1.184-.989-.052-.574.393-1.064.994-1.094.601-.029 1.131.414 1.185.989.051.575-.394 1.064-.995 1.094m8.29-10.616c-.879.043-1.631-.333-1.676-.841-.047-.507.629-.954 1.507-.996.88-.042 1.631.333 1.677.841.045.508-.63.954-1.508.996m-53.371-3.923c-.79.039-1.479-.504-1.543-1.215-.065-.71.52-1.317 1.306-1.356.788-.039 1.479.506 1.543 1.216.065.712-.52 1.318-1.306 1.355m-39.271 2.161c-.832.039-1.556-.45-1.614-1.091-.058-.643.569-1.198 1.404-1.238.831-.041 1.553.449 1.612 1.09.058.644-.569 1.197-1.402 1.239m-30.241 7.501c-.579.027-1.077-.28-1.114-.685-.038-.405.402-.758.98-.785.577-.028 1.078.276 1.114.683.037.407-.401.758-.98.787m-1.855 6.426c-.393.019-.755-.432-.807-1.007-.052-.575.223-1.056.618-1.076.393-.018.753.432.807 1.007.052.574-.225 1.057-.618 1.076m-8.598 5.831c-1.297.064-2.395-.433-2.458-1.109-.062-.676.938-1.276 2.235-1.34 1.295-.063 2.395.435 2.458 1.111.06.676-.94 1.275-2.235 1.338m26.899-9.552c-.973.047-1.814-.518-1.882-1.262-.068-.744.665-1.386 1.636-1.433.971-.048 1.815.517 1.881 1.261.068.745-.664 1.387-1.635 1.434m33.483-8.398c-.648.032-1.208-.327-1.25-.801-.045-.473.447-.882 1.094-.914.646-.032 1.208.327 1.251.8.042.475-.448.883-1.095.915m23.027 2.446c-.878.044-1.63-.334-1.675-.838-.046-.508.63-.955 1.509-.996.878-.044 1.628.333 1.677.84.045.505-.631.952-1.511.994m24.587-1.689c-1.434.071-2.642-.365-2.698-.976-.054-.609 1.063-1.159 2.498-1.227 1.432-.07 2.64.366 2.697.974.055.611-1.063 1.161-2.497 1.229m15.51 3.06c-1.203.058-2.25-.69-2.339-1.669-.09-.982.813-1.825 2.016-1.883 1.201-.06 2.249.689 2.338 1.669.091.98-.813 1.824-2.015 1.883m12.566 4.923c-.833.041-1.561-.502-1.626-1.212-.065-.71.559-1.319 1.391-1.36.835-.04 1.56.503 1.626 1.213.064.71-.559 1.319-1.391 1.359m8.383 4.268c-.324.016-.679-.985-.792-2.237-.115-1.252.054-2.28.38-2.294.323-.018.677.984.792 2.237.113 1.251-.055 2.278-.38 2.294" style="fill:hsl(';
        
        parts[26] = toString(rand2ndchips());
        
        parts[27] = ', 100%, 50%);fill-opacity:1;fill-rule:evenodd;stroke:none"/></g>';
        
        parts[28] = '<text x="30" y="770" class="base" fill= "black" font-family= "serif" font-style= "italic" font-size= "35px">#';
        
        parts[29] = toString(tokenId);
        
        parts[30] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0], 
                parts[1], 
                parts[2], 
                parts[3], 
                parts[4], 
                parts[5], 
                parts[6], 
                parts[7], 
                parts[8]
            )
        );
        
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        
         output = string(
            abi.encodePacked(
                output,
                parts[17],
                parts[18],
                parts[19],
                parts[20],
                parts[21],
                parts[22],
                parts[23],
                parts[24]
            )
        );
        
        output = string(
            abi.encodePacked(
                output,
                parts[25],
                parts[26],
                parts[27],
                parts[28],
                parts[29],
                parts[30]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Cake #',
                        toString(tokenId),
                        '", "description": "Birthday Cake built in Smart Contract.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
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
    
    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
    }
    
    function pause(bool _state) public onlyOwner {
    paused = _state;
    }

    function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
    }

}

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