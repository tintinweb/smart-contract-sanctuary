/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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



// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;


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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;


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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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


pragma solidity ^0.8.0;


contract MutantApeWives is ERC721Enumerable, Ownable {

    uint256 public apePrice = 40000000000000000;
    uint public constant maxApePurchase = 10;
    uint public ApeSup = 10000;
    bool public drop_is_active = false;
    bool public presale_is_active = false;
    string public baseURI = "";
    uint256 public tokensMinted = 0;

    struct Whitelistaddr {
        uint256 presalemints;
        bool exists;
    }
    mapping(address => Whitelistaddr) private whitelist;

    constructor() ERC721("MutantApeWives", "MAW"){
    whitelist[0x1Fa0c42a65B51ABdd384C1bba97992CA478DF4e7].exists = true;
    whitelist[0x03EED5383cd57b8155De4A67fEdB906dC3C9eB6D].exists = true;
    whitelist[0x4d9f62922A828939eF6CE5E50FaF4A7B5360b943].exists = true;
    whitelist[0x1CccFDBaD92675f7212cb264e4FdCbd8699a81dE].exists = true;
    whitelist[0xA01C0735C7cA5f8efc1e63efa5F2D1C4fc1a4714].exists = true;
    whitelist[0x5ed39Ed5C210bdB9e67385478323E6113C33b1F0].exists = true;
    whitelist[0xA4Adc8AbE09cf3c06f353576c2E9886eef815ebE].exists = true;
    whitelist[0x921D53Af7CC5aE8fc65B6CB390762F9Abc82b8EA].exists = true;
    whitelist[0xaD31dFbF78BdC8E90c7DeF2a97ECbE917C53E7e3].exists = true;
    whitelist[0x8d256C3dEEDCF219764425Daf6c1e47244c6839b].exists = true;
    whitelist[0x98c68168474c7EfE22828EaB331Ce98655a8ecc9].exists = true;
    whitelist[0x64B1dF8EbeA8a1039217B9A7fAAed386d856e7c2].exists = true;
    whitelist[0x511DbcBa0c78cb4E35f1Fc2b14b1FCdDf133c2dd].exists = true;
    whitelist[0x036863A5A05c5A7EbD2553824Cb040aAa2a6D687].exists = true;
    whitelist[0x2fa03dcc825f2a09705904bc8f6E51662e9c9448].exists = true;
    whitelist[0xca4BF72AE1b9C050729931e715Bd6653df951848].exists = true;
    whitelist[0x9f8c7c5BaC70342B572Af5B395553eFd978C4425].exists = true;
    whitelist[0x90a4D5aD231E9250F53D0b2a0029556798eCcaeD].exists = true;
    whitelist[0xc5F62Ed23fb755D2B89c2372bF21eE711E4DB3B4].exists = true;
    whitelist[0xd34a6B9Fca0867988CDC602D60724F822F96ffFD].exists = true;
    whitelist[0x5fE8a15dbE1863B37F7e15B1B180af7627548738].exists = true;
    whitelist[0x21bd72a7e219B836680201c25B61a4AA407F7bfD].exists = true;
    whitelist[0x9AE6d4859109c83fab823Ea4dFd42843568D1084].exists = true;
    whitelist[0x2014ca876094Bf98F53226C9CD4E811862d07504].exists = true;
    whitelist[0xB1059da8327718704086e372320185B970b3FAFD].exists = true;
    whitelist[0x5C3086CdEC08849CdC592Eb88F9b8d2F72E3e42f].exists = true;
    whitelist[0xe701A35273c57791009a5d0B2de9B9b8c1fCeAEA].exists = true;
    whitelist[0x9e14b5E72b6F94b839C148C3A60F78c999DfE9db].exists = true;
    whitelist[0xf7A926e197e2A07213B320ad4651C8DF5Bdc6B1a].exists = true;
    whitelist[0x115D55FE3f068e05f57D247389c5B93534D685CA].exists = true;
    whitelist[0xBF2C089F3e9d23aa7D124c4B4E8371A54300fD5e].exists = true;
    whitelist[0x32752703548FbAf0113d4C20ddF08B66Eef1D31A].exists = true;
    whitelist[0xc34E1e7ae15410B37Db674955335E8Fd722cb3e6].exists = true;
    whitelist[0x428e209dA85f879168fd8e91e6eBFdb809c7EA46].exists = true;
    whitelist[0xa47467EfD942daCBf3b0D1d656bC512847e7f4e0].exists = true;
    whitelist[0x7B02Cf72c598F569237336F30c283668E8199dd9].exists = true;
    whitelist[0x86cb4684b24ff467Df46EF5804B24515E6AdB9C9].exists = true;
    whitelist[0x7254bb676d9cB54281028c4083455e85e2904C1b].exists = true;
    whitelist[0xED3ea09408bc99B8617Af13CfA2A86Ae4b247c2E].exists = true;
    whitelist[0x39794c3171d4D82eB9C6FBb764749Eb7ED92881d].exists = true;
    whitelist[0x37002077CacCA7534D89118836662779233e62B1].exists = true;
    whitelist[0x033d1a2357307Ae3f8a2D7aC15931f555d37D41d].exists = true;
    whitelist[0x483199Cc3318414B2b7Af323Cb981840ae8AB4F9].exists = true;
    whitelist[0xeacF6c83C26508F55AD6Bd49746E65C39645223E].exists = true;
    whitelist[0x602B93A6ab102907a40cDE6B786cD07B4279E796].exists = true;
    whitelist[0x87C9e727aD6DD925A1De7CD949349a855bEbD836].exists = true;
    whitelist[0xD57E60947C5AEfB0D80edca6b0B0Bfd31A50b739].exists = true;
    whitelist[0x8B0C2928e935b1D2Ac9D5a149829f7103c60b94f].exists = true;
    whitelist[0x06C4106E578110ED05c943d97A9a3e561b598DB0].exists = true;
    whitelist[0x746b024b8b93D0d447c61B955f8452afdB7682c4].exists = true;
    whitelist[0x713b8C9f2713a07a43EDA78B454BEaB9D9E96015].exists = true;
    whitelist[0xf543428D35aB7F3a86a7F4F448ec2B32eb0d8b32].exists = true;
    whitelist[0x642b286935113276d363dF4Cfd202079233f25d1].exists = true;
    whitelist[0xd7B83C30609db3f1F4ad68d9c046703a7d06D722].exists = true;
    whitelist[0x6f15Aa54a9370fB5A64291499B77650d5f3882FC].exists = true;
    whitelist[0x7443E57a7d4df44FE6819dd76474BA9C3BE3c81D].exists = true;
    whitelist[0x03f4Cb9e297ea659F30E09341eE7155a7d136398].exists = true;
    whitelist[0x6A61925DcdF27d8b28C11Ec76228b4195A978069].exists = true;
    whitelist[0x5078328036E21C42426D9514378d782e489c9844].exists = true;
    whitelist[0x2AF37023A1bEf8164781f1B941E8B7d9D2764766].exists = true;
    whitelist[0x4DA33Cf3100E5DA72285F1Cc282cf056ce0ADD51].exists = true;
    whitelist[0x2a32093A20D9E1D3f0620FbA008c9b2107Aa0D39].exists = true;
    whitelist[0x0C289Ec5d7FAC13EcBa85A404f144dfE461F6757].exists = true;
    whitelist[0xb5c1bbd13f127Bd1807d6434bB016ec93e6CB107].exists = true;
    whitelist[0x9B53f9f5e94fE905a25eB5E14EFa03a86AEf2f08].exists = true;
    whitelist[0x42cBD461BADfa828D64bB2684F49289a62248D4a].exists = true;
    whitelist[0xb53467e86A7AC44ED8623f01A3772F573d2A1f1d].exists = true;
    whitelist[0x7Eca7b2A0b7170DE1Fe3DC8ABb3007d60BE382Fc].exists = true;
    whitelist[0xB13a509B8E3Dd88f4a5239c1cC4a749111CCa5a7].exists = true;
    whitelist[0xc68810cD92dAC5186d035cC65C388060C1f85373].exists = true;
    whitelist[0xf7f058Cd6D8BC862BE2193AE60f9Fe3387fdFa3A].exists = true;
    whitelist[0xe2320De5d2ddA68A9479E4271b704284679E49eb].exists = true;
    whitelist[0x4a3172c5879ab244d53ed2eEf38dDc1bD8ACaCcb].exists = true;
    whitelist[0x35851bBBDF431c2AcF773f0e3FFeaa7279Dc60d7].exists = true;
    whitelist[0x2cDAAF054a63C2eaeA23A7A071E39bE872f2f808].exists = true;
    whitelist[0xA9DCc7771b949d9917AC2Db34471325D901303cD].exists = true;
    whitelist[0x358f0632548968776247C6154c06023a10A9Aa10].exists = true;
    whitelist[0x62Ac503e46fCc13317580b8B177f28f2F5270f17].exists = true;
    whitelist[0x07cd24C35403E88B647778ccA17B91D2ee02aFF3].exists = true;
    whitelist[0x2b762480E5BdF49eBa0e2126bd96685c70112355].exists = true;
    whitelist[0xABC2A9349d41ffBe8AFdB7886D70773991ACD833].exists = true;
    whitelist[0xb0f380d49a59F929c5481992892F899d390a6110].exists = true;
    whitelist[0x40119fD73a4c3c6cAf9DD5B0078f6c13E1133c61].exists = true;
    whitelist[0x6F2752bCF04aD3Bd569F8523C146701088dB8b2A].exists = true;
    whitelist[0x64aBB85Cc94dE5e0B56B2a1139B7DA70A7cd3b01].exists = true;
    whitelist[0xc27BA52C493e291FA50a8e537142dF2140520F0b].exists = true;
    whitelist[0x27F4f00A36FAa31A60A60cb56B25F99f9C683e9A].exists = true;
    whitelist[0xd6F1c330BF5379f8dC1C3db7f5daA8FB59581E30].exists = true;
    whitelist[0xCBcA70E92C68F08350deBB50a85bae486a709cBe].exists = true;
    whitelist[0x59Dcd59551848dda2448c71485E6E25238252682].exists = true;
    whitelist[0x1F057a18a0F3a0061d8170c303019CfA1D4E70C1].exists = true;
    whitelist[0xE289512D2322Ce7Bd468C2d9E1FEe03d0fBC4D43].exists = true;
    whitelist[0xf71Fc2ecf07364F3992beaf93168e8D911ac4336].exists = true;
    whitelist[0x1a47Ef7e41E3ac6e7f9612F697E69F8D0D9F0249].exists = true;
    whitelist[0x870B4947A30939C4D9338fc07C1370CE678C4a65].exists = true;
    whitelist[0x28c1Ed3cA6289F8E0C6B68508c1B7Fc00372001E].exists = true;
    whitelist[0xB6cd1D08bE8BaB1E702d6528702310239dc9E7D4].exists = true;
    whitelist[0x2B6E6bcB6d1a0544ec09A5209Db4f6023F6EbDF5].exists = true;
    whitelist[0xaa1edc3769f31Fe780e3Ee6d6C8ec534BA9A7725].exists = true;
    whitelist[0x06020f527C640692542D542A4d25Fc104E8F46a5].exists = true;
    whitelist[0x120C0daC8A4423a495AF6AB1aD64bc26b2C73986].exists = true;
    whitelist[0xAa5Ea948fCBd10132B2659Cd2181AA06a000c74F].exists = true;
    whitelist[0xFfE4261a55f4d5AE916D1130Ce4D9132f9Adb262].exists = true;
    whitelist[0x6CFbA31B89974acD050d5cAf48Ae92A12Ed160B9].exists = true;
    whitelist[0x35ddcaa76104D8009502fFFcfd00fe54210676F6].exists = true;
    whitelist[0xaFB2BdeCafeC778923cC9058c9642565B2999A29].exists = true;
    whitelist[0x665D43b4b3167D292Fd8D2712Bb7576e9eE31334].exists = true;
    whitelist[0xaB3418068Cdcf0cB116E408948c4aA1344519C3a].exists = true;
    whitelist[0x14D05798E8FB39Ea2604243fb6C4393DD7f36E14].exists = true;
    whitelist[0x4C97361f6D41f1E27daF636114F0Abaa61459167].exists = true;
    whitelist[0x259c9B7a6D6bA8CA30B849719a7Ee4CE843E4DDE].exists = true;
    whitelist[0x4bc91Bd7126B68CBD18F367E59754b878b72B848].exists = true;
    whitelist[0x2DD534dd4949ccDbB301D29b15d8B86111eE4aE1].exists = true;
    whitelist[0x8C87b46DC45076F3Cd457790100485Fd94fb4157].exists = true;
    whitelist[0x1228a857FD7Ee845f4999f33540F6b9D0988e80d].exists = true;
    whitelist[0xe522BfAbDba3E40dFf4187f5219a4E9f267cf504].exists = true;
    whitelist[0x49565Ba1f295dD7cfaD35C198f04153B9a0FB6d7].exists = true;
    whitelist[0x5444C883AA97d419AC20DCDbD7767F632b1A7669].exists = true;
    whitelist[0x7dD580A38454b97022B59EA1747e0Ffe279C508d].exists = true;
    whitelist[0x2B1632e4EF7cde52531E84998Df74773cA5216b7].exists = true;
    whitelist[0x65e46516353dB530f431Ee0535047c00e7e07E5F].exists = true;
    whitelist[0x8D24bCfEFbC93568872490C7A5f49E67819e8242].exists = true;
    whitelist[0x492191D35Ee2040E7733e7D18E405314a31abA85].exists = true;
    whitelist[0x66883274f20a617E781c3f869c48eD93a041F178].exists = true;
    whitelist[0x358Ffb79c76b45A3B9B13EE24Eb05Db85AdB1bB8].exists = true;
    whitelist[0xf0323b7dA670B039289A222189AC61389462Cb5A].exists = true;
    whitelist[0x162195Ea6e3d170939891Dd3A68a9CA32EcC1ca7].exists = true;
    whitelist[0xF328e13C8aB3cA38845724104aCC074Ff4121D74].exists = true;
    whitelist[0xbc3C52ECa94Fc1F412443a3d706CF19Fc80FfcB3].exists = true;
    whitelist[0x58f3e78f49296D5aD1C7798057A2e34949E95d55].exists = true;
    whitelist[0x74205C844f0a6c8510a03e68008B3e5be2d642e4].exists = true;
    whitelist[0x579cD9D50cda026B06891D5D482ce1f00D754022].exists = true;
    whitelist[0xc785EB6CF887b9d1DC971FcC9A81BF3fE030fD61].exists = true;
    whitelist[0xD42a0b819F6171A697501693D234bcE421FEAFEE].exists = true;
    whitelist[0x307C13D2820F35802307e943F59d65741256326F].exists = true;
    whitelist[0x04f5465dE5E6cE83bFc5a41E3b6450B7A52a361a].exists = true;
    whitelist[0xa04aC0F08D81bbfE8a5AFd8368Fa2E8d184fA9b5].exists = true;
    whitelist[0x9321D8d72f8BeBCf3D48725643564Eaf75a7a9ef].exists = true;
    whitelist[0xdEbD23D4f7706D873Ff766ed025C5854A732A463].exists = true;
    whitelist[0xe7c1DB78d86A6Ab2295a2B911559fd754710B64e].exists = true;
    whitelist[0x20f76AE93b4217D325b09bA5B99D4062BC6f1090].exists = true;
    whitelist[0x9C74F1a06CEa6587029029f3dE875D08757B9960].exists = true;
    whitelist[0xA8a437E16Ab784D72362F9ebFdC025f200BE28bF].exists = true;
    whitelist[0x69b02E16F3818D6211071E08E19f42944B90D1E7].exists = true;
    whitelist[0xDB2e9Af0Ec4Dc504b9409ec78b0FC4D9B30281Fc].exists = true;
    whitelist[0x686CB9D88719E85aCA606797743A6cc0F7343d31].exists = true;
    whitelist[0x0b6f3D59d4268679c6eba04eaCFAA4Ab4C9352D9].exists = true;
    whitelist[0x69F50475f695760C85bb28D7d6ecb9baD4Dd911d].exists = true;
    whitelist[0x7B3ea3001cbfB19fe7142757811056680C062114].exists = true;
    whitelist[0x5fD21B488987365b2C79aD42e5Ac6c15A1EA9cF0].exists = true;
    whitelist[0x196bF546a4944C31856009a87347C735e5d42A9D].exists = true;
    whitelist[0x4e1686BEdCF7B4f21B40a032cf6E7aFBbFaD947B].exists = true;
    whitelist[0x89f2C064a1e1ee5e37DF0698Fc95F43DAAA2a43A].exists = true;
    whitelist[0x84A2345A7fE0aBb8e6726051bf5bEb4A3E47A3Ee].exists = true;
    whitelist[0x88d19e08Cd43bba5761c10c588b2A3D85C75041f].exists = true;
    whitelist[0x9d4B7D78C81cDB2FB08bb24B3FA3E65f1ac444cA].exists = true;
    whitelist[0xaE149e2a083d94B9833102cF4fd6BEFF5409Fb20].exists = true;
    whitelist[0x612952a8D811B3Cd5626eBc748d5eB835Fcf724B].exists = true;
    whitelist[0x31B19F9183094fB6B87B8F26988865026c6AcF17].exists = true;
    whitelist[0x0b4955C7B65c9fdAeCB2e12717092936316f52F3].exists = true;
    whitelist[0x6507Db73D6AdE38af8467eB5aB445f224CeDAF38].exists = true;
    whitelist[0xB9c2cB57Dfe51F8A2Fb588f333bDC89D8d90ca9B].exists = true;
    whitelist[0x8F66c0c359B4546512BC8dca379B89Ac93008d97].exists = true;
    whitelist[0xc955Ce75796eF64eB1F09e9eff4481c8968C9346].exists = true;
    whitelist[0xA3274031a981003f136b731DF2B78CEE0ceCb160].exists = true;
    whitelist[0x466AbBfb9AAb4C6dF6d3Cc03D6C63C43C5162048].exists = true;
    whitelist[0x80EF7fB78F7e65928Ba2e60B7a5A9501Cbdcb612].exists = true;
    whitelist[0x58269C4fc0ACb2fB612638e75ED0e7113612F20f].exists = true;
    whitelist[0x7448E0C5f8e6cB5920bc197B0503e6B1c8cC495f].exists = true;
    whitelist[0x409239E29Dc9595D8DE2f8D4B916e2d076C82A73].exists = true;
    whitelist[0x82CAb764Df6a044029e34Ce281dF520c7DbeCed6].exists = true;
    whitelist[0x3fE167eD835fB3B28a555a5470b355202d27F436].exists = true;
    whitelist[0x35471F2cFab7B75e88D0eBfd5528586F55900C4E].exists = true;
    whitelist[0xd17579Ecff58C528C4Aa64Db58e8A829B1c111Cd].exists = true;
    whitelist[0xA94e497c4d7d59f572e8E27D53916f23635d6acd].exists = true;
    whitelist[0x07fC676A307F41dfa7e53b285cF87305B9ab940A].exists = true;
    whitelist[0xd8226Dd110c7bA2bcD7A680d9EA5206BaC40F201].exists = true;
    whitelist[0xE56B07262a1F52755B63bf32697511F84d46E780].exists = true;
    whitelist[0xE5Dd1908626392F5F4160C4d06729F733B1cfA3D].exists = true;
    whitelist[0x7f2FD2EAAF73CE2b4897566acA233244a4524BFB].exists = true;
    whitelist[0xDc92f758986cc62A1085319D2038445f3FeEF74b].exists = true;
    whitelist[0xDdE58fb699EB6f309b5759c9fC7c3aec43EbebE7].exists = true;
    whitelist[0xCe239202371B5215aA9155c6600c4D3506bD816A].exists = true;
    whitelist[0x1bd06653d474eF3d30E2057242a07A5E976Fb91f].exists = true;
    whitelist[0xaDD089EAD1d42bF90181D1c064931c3829438074].exists = true;
    whitelist[0xDfE59d4F638E24D413f0Be75417cCeD8Fae5FECb].exists = true;
    whitelist[0x0D5a507E4883b1F8a15103C842aA63D9e0F1D108].exists = true;
    whitelist[0x5CDB7Ff563c26beA21502d1e28f6566BFdA4a498].exists = true;
    whitelist[0xF85f584D4078E16673D3326a92C836E8350c7508].exists = true;
    whitelist[0x50c6320567cC830535f026193b57C370A65bDa80].exists = true;
    whitelist[0x563b3d92A0eE49C281ee50324bCd659B2bDBA414].exists = true;
    whitelist[0xdfDd269285cfc31A47ea35Df69E149e49cFca436].exists = true;
    whitelist[0xe03f7703ED4Af3a43Ac3608b46728884f0897f33].exists = true;
    whitelist[0x3eC4483CDB2bCcC637EF2C94e8F6EEEB8247823b].exists = true;
    whitelist[0xB04791252721BcB1c9B0Af567C985EF72C03b12D].exists = true;
    whitelist[0x7296077C84DD5249B2e3ae7fC3d49C86abc38C03].exists = true;
    whitelist[0x9cb01386968136745654650a9C806C211Fd61998].exists = true;
    whitelist[0x99549Be88376CE2edCBF513964c32243c2Daf3de].exists = true;
    whitelist[0x2C14d26e34cED6BA51e9a6c0c496b1aA42BAD131].exists = true;
    whitelist[0x8053843d83282e91f9DAaecfb66fE7C440545Ef8].exists = true;
    whitelist[0x8889D47281AEF794e39f50e679242bc9AC32cfeE].exists = true;
    whitelist[0xE8BEb17839F5f7fDD8324e3de41eaB74c03A280A].exists = true;
    whitelist[0x2146b3AE649d2829ec3234d2D4f5c9f34965E3Fe].exists = true;
    whitelist[0xDbf7E19a4FbCA4a2cD8820ca8A860C41fEadda90].exists = true;
    whitelist[0xBf7c5F30057288FC2D7D406B6F6c57E1D3235A27].exists = true;
    whitelist[0x0F87cD8301a0B74CCa321Be2b3e92fF859dd59Cb].exists = true;
    whitelist[0x1F3A0dd591B51Ae6a67415E147c7a25437B54501].exists = true;
    whitelist[0xA3c731882BBb5C2f19abcbbab06c22F20745Ef2b].exists = true;
    whitelist[0x00085AA596DA26FF95A0aa5772988E100bf52730].exists = true;
    whitelist[0xA7Fc9f19d9C5F8c39E69c1674C4c14fdd8f0dc2c].exists = true;
    whitelist[0xaB58f3dE07Fb3455D218438A99d69B3f06F23C49].exists = true;
    whitelist[0x67Bb605e68389C39e1b71990c54E985BeFFa0bd6].exists = true;
    whitelist[0x0A9acCc02Bf746D44E8E5f00056E24583AFDe0E4].exists = true;
    whitelist[0x3aE68dCe9c856413D5Fc72225e3b60E4EB8984Fc].exists = true;
    whitelist[0x50517761D2be85075Df41b92E2a581B59a0DB549].exists = true;
    whitelist[0x22eEF23D58355f08034551f66c194c2752D494C6].exists = true;
    whitelist[0xA0BDF16f3C91633838ad715a4bC7e8B406093340].exists = true;
    whitelist[0xD7e5EcE88400B813Ca8BE363583ACB3342939b24].exists = true;
    whitelist[0xeA5876991ca48E366f46b5BdE5E6aDCfFA2000bc].exists = true;
    whitelist[0x095fd83d8909B3f9daB3ab36B24a28d5b57a5E48].exists = true;
    whitelist[0xbAaBA861464F25f52c2eE10CC3AC024F4f77812a].exists = true;
    whitelist[0x09AF59067B159A023E41DF8721ce4ad71cd70a99].exists = true;
    whitelist[0x56F4507C6Fdb017CDE092C37D3cf9893322245EB].exists = true;
    whitelist[0x6245f1c86AF1D0F87e5830b400033b1369d41c34].exists = true;
    whitelist[0x709Ab301978E2Cc74D35D15C7C33107a37047BFa].exists = true;
    whitelist[0x6139A7487D122934982A9a0f6eb81D64F25A8176].exists = true;
    whitelist[0xbdE1668dC41e0edDb253c03faF965ADc72BFd027].exists = true;
    whitelist[0x70070d4Ff9487755709e8ddC895820B456AF9d9A].exists = true;
    whitelist[0xA5a88A21896f963F59f2c3E0Ee2247565dd9F257].exists = true;
    whitelist[0xa26bdB6b0183F142355D82BA51540D28ABeD75fF].exists = true;
    whitelist[0xC31cB85aFa668fa7BFDF1Ad189b16F5249FA4c8E].exists = true;
    whitelist[0xDF0f45c028946D7c410e06f18547EA5eD4B98B63].exists = true;
    whitelist[0x943ead70dce4DF339227f4c7480f80A584f3d884].exists = true;
    whitelist[0xD9E77B9dc0095F45273A49442FDC49513F2E062d].exists = true;
    whitelist[0x0763cB7FC792A0AD0EE5593be50f82e2Da7aeb09].exists = true;
    whitelist[0x445934820d319b9F26cD7E7675c3184C0E2013FD].exists = true;
    whitelist[0x4f0c752fdbEA79558DdA8273750562eed4a518e2].exists = true;
    whitelist[0x9a290AF64601F34debadc26526a1A52F7a554E1b].exists = true;
    whitelist[0x8A3FfA2F2F2249da2B475EB15a223C3b9F735Fe8].exists = true;
    whitelist[0x08A5ae15FAE7A78517438A7e44f3DefE588dEf6f].exists = true;
    whitelist[0x8118123F6747f6f079492b8789256f2CEe932B64].exists = true;
    whitelist[0x327Af9D0EC5851102D53326d1dD89ea0F43eC85c].exists = true;
    whitelist[0xcCC34C28A0b3762DaE74EECa2a631661DaF3DAf5].exists = true;
    whitelist[0xe0d4938f6325F0f4f944a581fc5bb68Faa07f47a].exists = true;
    whitelist[0xaEFC4c562002de306714a40Cc0A31b86f7E79077].exists = true;
    whitelist[0xd4Af804b5fc981c889E7b7c3af0E8D8aC2e2630D].exists = true;
    whitelist[0xB5BEebBFB568be3d5d7AFc7C35CAC5bC517a1fA4].exists = true;
    whitelist[0x9Fd9eC2A8BD80EE3105E979DB5f052B92A2F3FF1].exists = true;
    whitelist[0x2401379C8f2f131089db4a13454920F64bfBE622].exists = true;
    whitelist[0xDADa6af9D17B79d2a6e916c415178c3Fc252bD9A].exists = true;
    whitelist[0x72df07D6cB06d55B4e38f0b3761e0406E3FB38F6].exists = true;
    whitelist[0xB89f17Dd3772EFa4cf32785c3ad8c73a38A82409].exists = true;
    whitelist[0x65ADb749acE94D10535e0996C4223c3DcB4E6c84].exists = true;
    whitelist[0x7A7f4487642CB6Ba2D09A7f6902EB2feFA2ED5a4].exists = true;
    whitelist[0xaEaf879E6b2BECb46e173dC96888276800C74119].exists = true;
    whitelist[0xb490dde9273C5042B1c4E18aA1d551853b4862D0].exists = true;
    whitelist[0x367fc750E257656A6B4d497a0d9Ea74FE5C320eB].exists = true;
    whitelist[0xAD0bc71Da62040A4204bbbB0D83c4F4DCE5c8B03].exists = true;
    whitelist[0xBC50EB3b6C11F05a20353c1098B49Cd137788D40].exists = true;
    whitelist[0xa32886a9abB05D69ee88A55d98418539FE2B6339].exists = true;
    whitelist[0x3E18B56E65ccb82Ac6E81a0c18071D1dd644B65B].exists = true;
    whitelist[0x048B1cCecf3635f0506909e5BCF61Fac69b9236d].exists = true;
    whitelist[0x9Ca2F06c148b6ee694892B8A455400F75c2807A2].exists = true;
    whitelist[0xf147510B4755159608C4395C121fD64FeEA37747].exists = true;
    whitelist[0x3f015b37cd324D3cbaaA075A75f8F0a9AfeB04e1].exists = true;
    whitelist[0xE8fa3E7281C9fDE4F9c590DCEF0c797FDbd8E71f].exists = true;
    whitelist[0x3580aB76A179aF05E94FcB16f84C9C253d4d0aB1].exists = true;
    whitelist[0xe63fA6524Fa2d252cC3B46fDb4839900BfBFBB49].exists = true;
    whitelist[0xb518a513fE076345B13911617976E27b262d5033].exists = true;
    whitelist[0xdb2Ceb603DdF833A8D68698078F46efaA9C165E1].exists = true;
    whitelist[0x3Dce69B6e183ceb6B39fA7DF2BC190185D8eDf75].exists = true;
    whitelist[0xf43967FCA936a195981ebEECEC035daa59Fab443].exists = true;
    whitelist[0x43123084c1B589447a02e351688765ef57dc9B85].exists = true;
    whitelist[0xe072BE2b42857dbeeE17a30fA53752BF438058b7].exists = true;
    whitelist[0x15e8CcBD3CE150B382aB8bb8B1E874fC81d14EdD].exists = true;
    whitelist[0x11C61bcD43d61b62719c7971b227fBb8Cf6F3B71].exists = true;
    whitelist[0x68EFfCbfA1Fb3b5A18FEbC8aC4d22B5999B93E7f].exists = true;
    whitelist[0x3E59eA5c21ebb11765f182D7Cf901a8615c7cCDA].exists = true;
    whitelist[0x38E3f0Ca14525d869Fa7fE19303a9b711DD375c9].exists = true;
    whitelist[0x020F441f825767542a8853e08F7fd086a26981C2].exists = true;
    whitelist[0xE498Aa2326F80c7299E22d16376D4113cb519733].exists = true;
    whitelist[0x99F1396495cCeaFfE82C9e22b8A6ceB9c6b9336d].exists = true;
    whitelist[0xF9a99B48Ca723176B5Cc10d6EB0bA7d0e0529a3E].exists = true;
    whitelist[0xA17138c0675173B8Ea506Fb1b96FA754BC316cc2].exists = true;
    whitelist[0x9c4f52cf0f6537031d64B0C8BA7ea1729f0d1087].exists = true;
    whitelist[0x98BE88Fe1305e65EBd2AfaEf493A36200740e212].exists = true;
    whitelist[0xf777a4BA5021F3aB5Fe1F623d4051e556A246F72].exists = true;
    whitelist[0x0C9642Dc22C957612fD1c297EBB9fB91d9d12990].exists = true;
    whitelist[0x402a0Af9f46690c1f5d78e4d4990fb00a91C4114].exists = true;
    whitelist[0xF4a52a3B2715dd0bb046a212dE51dB38eb1329D3].exists = true;
    whitelist[0x4bB7Eceeb36395Deb86A42be19fC1440A23B5eA0].exists = true;
    whitelist[0xE5eF9FF63C464Cf421Aa95F06Ce15D707662D5f2].exists = true;
    whitelist[0x5233f73d362BC62Ccc500036027A100194506eC9].exists = true;
    whitelist[0x9EB335400b6AB26481002a25171b0E0b50A33fd8].exists = true;
    whitelist[0xf92f571Fd4ed497f672D4F37F46ee02eb13b63C8].exists = true;
    whitelist[0xcce848d0E705c72ce054c5D4918d32Ecf44c5905].exists = true;
    whitelist[0x40B4911489A87858F7e6765FDD32DFdD9D449aC6].exists = true;
    whitelist[0x406E4e822E0706Acf2c958d00ff82452020c556B].exists = true;
    whitelist[0x6b88C64796192728eEe4Ee19db1AE43FC4C80A23].exists = true;
    whitelist[0x8f94bE578e4A5435244b2E272D2b649D58242b23].exists = true;
    whitelist[0x2b08B2c356C2c9C4Cc8F2993673F44106165b20b].exists = true;
    whitelist[0x40b6B169FC9aAa1380375EBcC4BE40D19F37e1Ff].exists = true;
    }

    function OnWhiteList(address walletaddr)
    public
    view
    returns (bool)
    {
        if (whitelist[walletaddr].exists){
            return true;
        }
        else{
            return false;
        }
    }

    function addToWhiteList (address[] memory newWalletaddr) public onlyOwner{
        for (uint256 i = 0; i<newWalletaddr.length;i++){
            whitelist[newWalletaddr[i]].exists = true;
        }        
    }

    function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
    }

    function flipDropState() public onlyOwner {
        drop_is_active = !drop_is_active;
    }

    function flipPresaleSate() public onlyOwner {
        presale_is_active = !presale_is_active;
    }

    function PresaleMint(uint256 numberOfTokens) public payable{
        require(presale_is_active, "Please wait until the PreMint has begun!");
        require(whitelist[msg.sender].exists == true, "This Wallet is not able mint for presale");
        require(numberOfTokens > 0 && tokensMinted + numberOfTokens <= ApeSup, "Purchase would exceed max supply of MAW's");
        require(whitelist[msg.sender].presalemints + numberOfTokens <= 2,"This Wallet has already minted its 2 reserved MAW's");
        require(msg.value >= apePrice * numberOfTokens, "ETH value sent is too little for this many MAW's");

        for(uint i=0;i<numberOfTokens;i++){
            if (tokensMinted < ApeSup){
                whitelist[msg.sender].presalemints++;
                tokensMinted++;
                _safeMint(msg.sender, tokensMinted);
            }
        }

    }

    function mintMAW(uint numberOfTokens) public payable {
        require(drop_is_active, "Please wait until the Public sale is active to mint");
        require(numberOfTokens > 0 && numberOfTokens <= maxApePurchase);
        require(tokensMinted + numberOfTokens <= ApeSup, "Purchase would exceed max supply of MAW's");
        require(msg.value >= apePrice * numberOfTokens, "ETH value sent is too little for this many MAW's");

        for (uint i=0;i<numberOfTokens;i++){
            if (tokensMinted < ApeSup){
                tokensMinted++;
                _safeMint(msg.sender, tokensMinted);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI)public onlyOwner{
        baseURI = newBaseURI;
    }
    function lowerMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice < apePrice);
        apePrice = newPrice;
    }

    function lowerMintSupply(uint256 newSupply) public onlyOwner {
        require(newSupply < ApeSup);
        require(newSupply > totalSupply());
        ApeSup = newSupply;
    }
}