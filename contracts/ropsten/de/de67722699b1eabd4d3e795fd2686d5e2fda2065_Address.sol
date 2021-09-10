/**
 *Submitted for verification at Etherscan.io on 2021-09-10
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

/*--------------------------------------------*/
//                                            //
//      PINEAPPLE PIZZA PARTY PRESENTS        //
//                      __                    //
//                    _(__)                   //
//                  _(____)                   // 
//                 (______)                   //
//           ...//( 00  )\.....               //
//                                            //
//              CRYPTO CRABS                  //
//                                            //
/*--------------------------------------------*/

contract CryptoCrab is ERC721, ERC721Enumerable, Ownable {

    /*--------------------------------------------*/
    //         Only 10000 first gen crabs         //
    /*--------------------------------------------*/
    // 9000 publicly mintable crabs
    uint256 public constant maxSupply = 10000;
    //Mint and breed price the same
    uint256 private _price = 0.01 ether;
    uint256 private _evolvePrice = 0.001 ether;
    uint256 private _actionPrice = 0.001 ether;
    // 1000 reserved crabs (for publicity and giveaways)
    uint256 private _reserved = 1000;

    uint256 public startingIndex;
    bool private _saleStarted;
    string public baseURI;
    uint256 public bredCrabs = 0;

    // address withdrawlAddress = 0x6A15A2f7EC02471C4Ee11c12F4C15B8D7AE90A00;

    struct CrabyDNA {
        bytes32 crabyDNA;
    }

    mapping( uint256 => CrabyDNA) private _tokenDetails;

    constructor() ERC721("CryptoCrabs", "CC"){
        _saleStarted = false;
    }

    modifier whenSaleStarted() {
        require(_saleStarted);
        _;
    }

    function getTokenDetails(uint256 tokenId) public view returns (CrabyDNA memory) {
        return _tokenDetails[tokenId];
    }

    /*--------------------------------------------*/
    //         Make some random Craby DNA         //
    /*--------------------------------------------*/

    /*--------------------------------------------*/
    //               DNA Structure                //
    // ------------------------------------------ //
    // | Byte |             Data                | //
    // ------------------------------------------ //
    // |                Crab Data               | //
    // ------------------------------------------ //
    // |  0   | Stage - 0=Shell 1=Baby 2=Adult  | //
    // |  1   | Has Bred - 0=No, 1=Yes          | //
    // |  2   | Generation                      | //
    // |  3   | Crab Special Reserve            | //
    // ------------------------------------------ //
    // |                Crab Stats              | //
    // ------------------------------------------ //
    // |  4   | Cuteness                        | //
    // |  5   | Sasiness                        | //
    // |  6   | Size                            | //
    // |  7   | Speed                           | //
    // |  8   | Smarts                          | //
    // |  9   | Wisdom                          | //
    // |  10  | Power                           | //
    // |  11  | Luck                            | //
    // ------------------------------------------ //
    // |                Shell Stage             | //
    // ------------------------------------------ //
    // |  12  | Background                      | //
    // |  13  | Shell Type                      | //
    // |  14  | Shell Accessory                 | //
    // ------------------------------------------ //
    // |                Baby Stage              | //
    // ------------------------------------------ //
    // |  15  | Background                      | //
    // |  16  | Shell Type                      | //
    // |  17  | Shell Accessory                 | //
    // |  18  | Crab Type                       | //
    // |  19  | Crab Claw                       | //
    // |  20  | Crab Eyes                       | //
    // |  21  | Crab Mouth                      | //
    // |  22  | Crab Accessory                  | //
    // ------------------------------------------ //
    // |      |        Adult Stage              | //
    // |  23  | Background                      | //
    // |  24  | Shell Type                      | //
    // |  25  | Shell Accessory                 | //
    // |  26  | Crab Type                       | //
    // |  27  | Crab Claw                       | //
    // |  28  | Crab Eyes                       | //
    // |  29  | Crab Mouth                      | //
    // |  30  | Crab Accessory                  | //
    // |  31  | Overflow protection             | //
    // ------------------------------------------ //
    /*--------------------------------------------*/

    function randBytes32(uint256 tokenId) internal view returns(bytes32){
        // The premmise is that even if the DNA is psudo-random but deterministic, make it impractably so.
        // Its a tad overkill, but you can add / remove bits to adjust the complexity... Good luck!
        uint256 dna = uint256(keccak256(abi.encodePacked(               // Take the hash of
            uint256(blockhash(block.number - 2))                        // the hash of the block 2 blocks ago XOR with
            // ^ uint256(blockhash(block.number - 1)                    // the hash of the last block XOR with
            ^ block.timestamp                                           // the time stamp XOR with
            ^ block.difficulty                                          // the difficulty XOR with
            // ^ block.gaslimit                                         // the gas limit XOR with
            // ^ block.number                                           // the block number XOR with
            // ^ uint256(keccak256(abi.encodePacked(block.coinbase)))   // the hash of the coinbase XOR with
            ^ uint256(keccak256(abi.encodePacked(msg.sender)))          // the hash of the calling wallet XOR with
            // ^ uint256(keccak256(abi.encodePacked(tokenId)))          // the hash of the tokenId
            + tokenId                                                   // add the tokenId
        )));

        return bytes32(dna);
    }

    /*--------------------------------------------*/
    //         Mint some random Crabs             //
    /*--------------------------------------------*/
    function internalMint(address to, uint256 tokenId, bytes1 generation, bytes1 reserve) internal {
        bytes32 x = 0xff00000000000000000000000000000000000000000000000000000000000000;

        //Start with some random bytes
        bytes32 setCrabyDNA = randBytes32(tokenId);

        // mask out the status and other unused bytes
        setCrabyDNA &= 0x00000000ffffffffffffffffffffff000000ffffffffff000000000000000000;

        //Set generation and reserve status
        setCrabyDNA ^= (x & generation) >> 16;
        setCrabyDNA ^= (x & reserve) >> 24;

        //trim attributes to leave room for growth when evolving
        for(uint i=12; i <= 22; i++){
            uint8 byteResult = uint8(setCrabyDNA[i]);
            if( i > 17 ){
                unchecked {
                    //Crab attributes only evolve once so take off the max benifit of evolving once
                    byteResult -= 0x0f;
                }
            }else{
                unchecked {
                    //Shell and background attributes can evolve twice so take off double
                    byteResult -= 0x1e;
                }
            }
            if(byteResult > uint8(setCrabyDNA[i])){byteResult = 0x00;}
            setCrabyDNA ^= (x & bytes1(byteResult)) >> (i*8);
        }

        //Ready to Mint
        _tokenDetails[tokenId] = CrabyDNA(setCrabyDNA);
        _safeMint(to, tokenId);
    }

    //Mint from the reserve stash
    function ownerMintReserved(uint256 _nbTokens, address reciever) public onlyOwner { 
        uint256 supply = totalSupply();
        require(_nbTokens <= _reserved, "!MAXRESERVED");

        for (uint256 i; i < _nbTokens; i++) {
            internalMint(reciever, supply + i, 0x01, 0x01);
        }
    }

    //Anyone can mint when the sale is on
    function mint(uint256 _nbTokens) external payable whenSaleStarted {
        uint256 supply = totalSupply() + _reserved;
        require(_nbTokens < 21, "!<21");
        require(supply + _nbTokens <= maxSupply, "!TOKENSLEFT");
        require(_nbTokens * _price <= msg.value, "!AMOUNT");

        for (uint256 i; i < _nbTokens; i++) {
            internalMint(msg.sender, supply + i, 0x01, 0x00);
        }
    }

    /*--------------------------------------------*/
    //         Put them Crabs on sale             //
    /*--------------------------------------------*/
    function flipSaleStarted() external onlyOwner {
        _saleStarted = !_saleStarted;

        if (_saleStarted && startingIndex == 0) {
            setStartingIndex();
        }
    }

    //Check if the sale has started
    function saleStarted() public view returns(bool) {
        return _saleStarted;
    }

    //Change the bas URI if required
    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }


    // Make it possible to change the price: just in case
    function setPrice(uint256 _newPrice, uint256 _newActionPrice, uint256 _newEvolvePrice) external onlyOwner {
        _price = _newPrice;
        _actionPrice = _newActionPrice;
        _evolvePrice = _newEvolvePrice;
    }

    //Check the price
    function getPrice() public view returns (uint256){
        return _price;
    }

    function getActionPrice() public view returns (uint256){
        return _actionPrice;
    }

    function getEvolvePrice() public view returns (uint256){
        return _evolvePrice;
    }

    //Check how many reserved crabs are left
    function getReservedLeft() public view returns (uint256) {
        return _reserved;
    }

    // Show me my crabs!
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Do they own that crab?
    function _owns(address user, uint256 craby) internal view returns (bool){
        uint count = balanceOf(user);
        if (count == 0){ return false;}
        for (uint i; i < count; i++){
            if (tokenOfOwnerByIndex(user, i) == craby){return true;}
        }
        return false;
    }


    // Set the starting index
    function setStartingIndex() public {
        require(startingIndex == 0, "ALREADYSET");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift =  1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint(blockhash(_block_ref)) % maxSupply;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    // Check the starting index
    function getStartingIndex() public view returns (uint) {
        return startingIndex;
    }

    // Withdraw from the contract
    function withdraw(uint256 withdrawlAddress) public onlyOwner {
        require(payable(address(uint160(uint256(withdrawlAddress)))).send(address(this).balance));
    }

    // Make a string from a bytes32 array
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {

            uint8 _f = uint8(_bytes32[i/2] & 0x0f);
            uint8 _l = uint8(_bytes32[i/2] >> 4);

            bytesArray[i] = toByte(_l);
            i = i + 1;
            bytesArray[i] = toByte(_f);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) internal pure returns (bytes1) {
        if(_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }

    // Convert uint to string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Get the URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "!TOKEN");
        //string memory baseURI = _baseURI();
        CrabyDNA storage crabyDNA = _tokenDetails[tokenId];
        string memory dnaString = bytes32ToString(crabyDNA.crabyDNA);
        string memory tokenIdString = uint2str(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, dnaString, "&tokenID=", tokenIdString)) : "";
    }

    /*--------------------------------------------*/
    //        Interact with crabs for gas         //
    /*--------------------------------------------*/

    // Decreases one crab stat (or any byte in any bytes32 array by any amount)
    function decreaseStat(bytes32 currentDNA, bytes32 newDNA, uint pos, uint8 amount) internal pure returns (bytes32){
        bytes32 x = 0xff00000000000000000000000000000000000000000000000000000000000000;
        if(currentDNA[pos] < bytes1(amount)){ newDNA ^= ((x & 0x00) >> (pos*8)); }else{
            newDNA ^= (x & bytes1(uint8(currentDNA[pos]) - amount)) >> (pos*8);}
        return newDNA;
    }

    // Increases one crab stat (or any byte in any bytes32 array by any amount)
    function increaseStat(bytes32 currentDNA, bytes32 newDNA, uint pos, uint8 amount) internal pure returns (bytes32){
        bytes32 x = 0xff00000000000000000000000000000000000000000000000000000000000000;
        if(currentDNA[pos] > bytes1(0xff - amount)){ newDNA ^= ((x & bytes1(0xff)) >> (pos*8)); }else{
            newDNA ^= (x & bytes1(uint8(currentDNA[pos]) + amount)) >> (pos*8);}
        return newDNA;
    }

    // Feed that crab!
    function feed(uint256 crab) public payable{
        require(_owns(msg.sender, crab), "!OWN");
        require(_actionPrice <= msg.value, "!AMOUNT");

        CrabyDNA storage crabyDNA = _tokenDetails[crab];
        bytes32 currentDNA =crabyDNA.crabyDNA;
        bytes32 newDNA;
        bytes32 statDNAMask = 0xffffffffff000000ffff00ffffffffffffffffffffffffffffffffffffffffff;
        
        newDNA ^= currentDNA & statDNAMask;

        newDNA = decreaseStat(currentDNA, newDNA, 5, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 6, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 7, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 10, 0x20);

        crabyDNA.crabyDNA = newDNA;
    }

    // Play with the crab!
    function play(uint256 crab) public payable{
        require(_owns(msg.sender, crab), "!OWN");
        require(_actionPrice <= msg.value, "!AMOUNT");

        CrabyDNA storage crabyDNA = _tokenDetails[crab];
        bytes32 currentDNA =crabyDNA.crabyDNA;
        bytes32 newDNA;
        bytes32 statDNAMask = 0xffffffffff0000ffff0000ffffffffffffffffffffffffffffffffffffffffff;

        newDNA ^= currentDNA & statDNAMask;

        newDNA = increaseStat(currentDNA, newDNA, 5, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 6, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 9, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 10, 0x20);

        crabyDNA.crabyDNA = newDNA;
    }

    // Train the crab!
    function train(uint256 crab) public payable{
        require(_owns(msg.sender, crab), "!OWN");
        require(_actionPrice <= msg.value, "!AMOUNT");

        CrabyDNA storage crabyDNA = _tokenDetails[crab];
        bytes32 currentDNA =crabyDNA.crabyDNA;
        bytes32 newDNA;
        bytes32 statDNAMask = 0xffffffff0000000000000000ffffffffffffffffffffffffffffffffffffffff;

        newDNA ^= currentDNA & statDNAMask;

        newDNA = decreaseStat(currentDNA, newDNA, 4, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 5, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 6, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 7, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 8, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 9, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 10, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 11, 0x20);

        crabyDNA.crabyDNA = newDNA;
    }

    // Groom the crab!
    function groom(uint256 crab) public payable{
        require(_owns(msg.sender, crab), "!OWN");
        require(_actionPrice <= msg.value, "!AMOUNT");

        CrabyDNA storage crabyDNA = _tokenDetails[crab];
        bytes32 currentDNA =crabyDNA.crabyDNA;
        bytes32 newDNA;
        bytes32 statDNAMask = 0xffffffff000000ff00ff0000ffffffffffffffffffffffffffffffffffffffff;

        newDNA ^= currentDNA & statDNAMask;

        newDNA = increaseStat(currentDNA, newDNA, 4, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 5, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 6, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 8, 0x20);
        newDNA = decreaseStat(currentDNA, newDNA, 10, 0x20);
        newDNA = increaseStat(currentDNA, newDNA, 11, 0x20);

        crabyDNA.crabyDNA = newDNA;
    }
 
    
    /*--------------------------------------------*/
    //        Evolve crabs for a fee              //
    /*--------------------------------------------*/
    function evolve(uint256 crab) external payable {
        require(_owns(msg.sender, crab), "!OWN");
        require(_evolvePrice <= msg.value, "!AMOUNT");

        CrabyDNA storage crabyDNA_actual = _tokenDetails[crab];
        bytes32 crabDNA_temp = crabyDNA_actual.crabyDNA;

        require(uint8(crabDNA_temp[0]) < 2, "ADULT");

        bytes32 x = bytes32(0xff00000000000000000000000000000000000000000000000000000000000000);

        uint8 state;
        uint statEnd;
        uint baseStart;
        uint finalStart;

        //If its a shell becoming a baby crab
        state = 1;
        statEnd = 6;
        baseStart = 8; //12 - 4
        finalStart = 11; //15 - 4

        //If its a baby becoming an adult
        if(uint8(crabDNA_temp[0])==1){
            state = 2;
            statEnd = 11;
            baseStart = 11; //15 - 4
            finalStart = 19; //23 - 4
        }

        //Update the attributes based on the stats 
        for(uint i=4; i <= statEnd; i++){
            uint8 byteResult = uint8(crabDNA_temp[i]);
            byteResult >>= 4; // Highest single increment = 16 //TODO discuss with Tom
            unchecked {
                byteResult += uint8(crabDNA_temp[i+baseStart]);
            }
            if(byteResult < uint8(crabDNA_temp[i+baseStart])){byteResult = 0xff;}
            crabDNA_temp ^= (x & bytes1(byteResult)) >> ((i+finalStart)*8);
        }
        
        //Update the crabs evolutionary stage
        bytes32 y = bytes32(0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        crabDNA_temp &= y;
        crabDNA_temp ^= (x & bytes1(state));

        //Apply to crab
        crabyDNA_actual.crabyDNA = crabDNA_temp;
    }

    /*--------------------------------------------*/
    //        Breed crabs for a fee               //
    /*--------------------------------------------*/

    function breed(uint256 oneCrab, uint256 anotherCrab) external payable {

        // Checks for payment.
        require(msg.value >= _price);

        // Caller must own the Crabies.
        require(_owns(msg.sender, oneCrab));
        require(_owns(msg.sender, anotherCrab));

        // Get the DNA of the two Crabies.
        CrabyDNA storage oneCrabDNA_actual = _tokenDetails[oneCrab];
        CrabyDNA storage anotherCrabDNA_actual = _tokenDetails[anotherCrab];
        bytes32 oneCrabyDNA = oneCrabDNA_actual.crabyDNA;
        bytes32 anotherCrabyDNA = anotherCrabDNA_actual.crabyDNA;

        // Check that the Crabies are ready to breed and haven't bred before.
        require(oneCrabyDNA[0] >= 0x02);
        require(oneCrabyDNA[1] == 0x00);
        require(anotherCrabyDNA[0] >= 0x02);
        require(anotherCrabyDNA[1] == 0x00);

        // thiss will be the new crabs DNA
        bytes32 offspringDNA = 0x00;

        // Get some random bytes to determine DNA mixing
        bytes32 dnaMixer = randBytes32(oneCrab + anotherCrab);

        bytes32 x = 0xff00000000000000000000000000000000000000000000000000000000000000;
        
        //Randomly mix the two DNA streams, starting at byte 4 and ending at byte 22
        for (uint8 i = 1; i < 23; i++){
            if (dnaMixer[i] > 0x8F){
                offspringDNA ^= (x & oneCrabyDNA[i]) >> (i*8);
            }
             else{
                offspringDNA ^= (x & anotherCrabyDNA[i]) >> (i*8);
            }
        }

        //calculate the generation based on the highest parent generation + 1
        uint8 generation = 2;

        if (oneCrabyDNA[2] > anotherCrabyDNA[2]){
            generation = uint8(oneCrabyDNA[2]) + 1;
        }
        else{
            generation = uint8(anotherCrabyDNA[2]) + 1;
        }

        //trim attributes to leave room for growth when evolving
        for(uint i=12; i <= 22; i++){
            /*
            uint8 byteResult = uint8(offspringDNA[i]);
            unchecked {
                byteResult -= 0x1e;
            }
            if(byteResult > uint8(offspringDNA[i])){byteResult = 0x00;}
            offspringDNA ^= (x & bytes1(byteResult)) >> (i*8);
            */
            offspringDNA = decreaseStat(offspringDNA, offspringDNA, i, 0x1e);
        }

        //Mask out unused bytes
        offspringDNA &= 0x00000000ffffffffffffffffffffff000000ffffffffff000000000000000000;

        //Set the generation
        offspringDNA ^= (x & bytes1(generation)) >> 16;

        //Set that the parents have bred
        bytes32 hasBred = 0x0001000000000000000000000000000000000000000000000000000000000000;
        oneCrabDNA_actual.crabyDNA ^= hasBred;
        anotherCrabDNA_actual.crabyDNA ^= hasBred;

        //Mint the offspring
        uint256 tokenId = maxSupply + _reserved + bredCrabs + 1;
        bredCrabs += 1;  
        _tokenDetails[tokenId] = CrabyDNA(offspringDNA);
        _safeMint(msg.sender, tokenId);
    }

    // Required overides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}