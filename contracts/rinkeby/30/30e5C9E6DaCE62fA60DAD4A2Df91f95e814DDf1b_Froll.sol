/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// File: node_modules\openzeppelin-solidity\contracts\utils\introspection\IERC165.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721.sol

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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721Receiver.sol


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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\extensions\IERC721Metadata.sol


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

// File: node_modules\openzeppelin-solidity\contracts\utils\Address.sol


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

// File: node_modules\openzeppelin-solidity\contracts\utils\Context.sol


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

// File: node_modules\openzeppelin-solidity\contracts\utils\Strings.sol


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

// File: node_modules\openzeppelin-solidity\contracts\utils\introspection\ERC165.sol


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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\ERC721.sol


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

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\extensions\IERC721Enumerable.sol

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

// File: openzeppelin-solidity\contracts\token\ERC721\extensions\ERC721Enumerable.sol


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

// File: openzeppelin-solidity\contracts\access\Ownable.sol

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

// File: contracts\FroXx.sol

// FroXx NFT
/**
    !Disclaimer!
    FroXx NFT is part of an experimental and educational project into different fun smart 
    contracts on blockchain.
    
    Each FroXx is generated on the fly at mint time with random traits. Imagedata from each
    image is stored directly on the Ethereum blockchain forever.
    
    This smart contract also include an experimental "raffle" function. It will automaticly 
    airdrop (30% of mint price) back to a random existing FroXx NFT owners wallet. 
    This happens at every mint and gives the opportunity to be lucky and get ETH back from
    the initial purchase if anyone mints a FroXx after you. 
    In theory, the more FroXx you hold, the bigger chance to win the raffles on future mints.
    
    This is only meant to be used for an educational purpose. We will not be reliable for any 
    speculation or misuse of the public avaliable smart contract. Do your own research before 
    investing in any NFT.
    
    SB
*/

pragma solidity >=0.8.0 <0.9.0;



/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

contract Froll is ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public giftShare = 30;
    bool public paused = false;
    
    struct NOC  {
      string tokenID;
      uint256[10] target;
      string[4] myColors;
    }
    
    mapping (uint256 => NOC) public nOCs;

    constructor( ) ERC721("Froll", "FROL") {}
    
    function mint() public payable {
        require(!paused, "Contract is currently Paused!");
        uint256 supply = totalSupply();
        require(supply + 1 <= 10000, "Max Supply Reached!");
        require(msg.sender != owner(), "Owner of contract cannot mint for free due to giftShare!");
        require(msg.value >= 0.01 ether, "Not enough funds in account!");
        
        uint256 rnd = rNd(string(abi.encodePacked('FroXxWasHere', supply)));
        
        uint256[10] memory target1;
        target1[0] = 1 + ((rnd/10) % 2); 
        target1[1] = 1 + ((rnd/100) % 2);
        target1[2] = 1 + ((rnd/1000) % 4);
        target1[3] = 1 + ((rnd/10000) % 15);
        target1[4] = 1 + ((rnd/100000) % 3);
        target1[5] = 1 + ((rnd/1000000) % 2);
        target1[6] = 1 + ((rnd/10000000) % 20);
        target1[7] = 1 + ((rnd/100000000) % 2); 
        target1[8] = 1 + ((rnd/1000000000) % 3); 
        target1[9] = 1 + ((rnd/10000000000) % 4); 
        
        string[4] memory myColors1;
        uint256 colorScale;
        (target1[9]-1 == 1) ? colorScale = 243 : colorScale = 65500;
        myColors1[0] = hashIt(rNBtwn(supply+4, 1, 16777215));
        myColors1[1] = hashIt((rNBtwn(supply+2, 2, colorScale*256)));
        myColors1[2] = hashIt((rNBtwn(supply+3, 3, colorScale*256)));
        myColors1[3] = hashIt((rNBtwn(supply+1, 4, colorScale*256)));
        myColors1[3] = string(abi.encodePacked(myColors1[3], 'CC'));
        
        NOC memory newNOC = NOC(
            uint256(supply + 1).toString(),
            uint256[10](target1),
            string[4](myColors1)
        );
        nOCs[supply + 1] = newNOC;

        address payable giftAddress = payable(msg.sender);
        uint256 giftValue;
    
        if (supply > 0) {
            giftAddress = payable(ownerOf(rN(supply, block.timestamp, supply + 1) + 1));
            giftValue = msg.value * giftShare / 100;
        }
    
        _safeMint(msg.sender, supply + 1);
    
        if (supply > 0) {
            (bool success, ) = payable(giftAddress).call{value: giftValue}("");
            require(success);
        }
    }
  
    function hashIt(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) {
            return "000000";
        }
        uint256 i;

        bytes memory buffer = "000000";
        for(i=6;i>0;i--) {
            if (_value % 16 < 10)
                buffer[i-1] = bytes1(uint8(48 + uint256(_value % 16)));
            else
                buffer[i-1] = bytes1(uint8(55 + uint256(_value % 16)));

            _value /= 16;
        }
        return string(buffer);
    }
  
    function rNd(string memory _input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_input)));
    }
    
    function rN(uint256 _mod, uint256 _seed, uint256 _salt) internal view returns(uint256) {
        uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
        return num;
    }
  
    function rNBtwn(uint256 _supply, uint256 min, uint256 max) internal view returns (uint256) {
        uint256 mod = max - min;
        uint256 rndNum = uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, _supply))) % mod;
        rndNum = rndNum + min;
        return rndNum;
    }

    function buildImage(uint256 _tokenId) internal view returns(string memory) {
        NOC memory currNOC = nOCs[_tokenId];
        require(_exists(_tokenId), "Error: This token has not been minted yet");
        
        string[30] memory elements;
        string[1] memory scar;
        string[1] memory eth;
        string[1] memory btc;
        string[1] memory hexi;
        string[1] memory bnb;
        string[2] memory eyeL;
        string[2] memory eyeR;
        string[2] memory eyeRepeat;

        scar[0] = 'M28.43,81.16c7.45-11.98,15.54-22.56,25.62-32.42c8.32-8.15,16.62-16.31,22.09-26.72c1.35-2.56-2.54-4.84-3.89-2.27 c-5.89,11.22-15.18,19.63-24.06,28.44c-9.36,9.28-16.7,19.53-23.65,30.71C23.01,81.35,26.9,83.62,28.43,81.16L28.43,81.16z M58.07,24.91c3.43,5.97,8.68,10.33,15.09,12.79c2.71,1.04,3.88-3.31,1.2-4.34c-5.3-2.03-9.58-5.82-12.4-10.72 C60.51,20.13,56.62,22.4,58.07,24.91L58.07,24.91z M52.5,33.38c3.36,4.93,7.15,9.52,11.4,13.71c2.06,2.04,5.25-1.14,3.18-3.18c-3.98-3.92-7.55-8.18-10.69-12.8 C54.76,28.73,50.86,30.97,52.5,33.38L52.5,33.38z M44.39,41.79c2.96,4.98,6.57,9.51,10.79,13.49c2.11,1.99,5.29-1.19,3.18-3.18c-3.95-3.73-7.31-7.9-10.09-12.58 C46.8,37.03,42.91,39.29,44.39,41.79L44.39,41.79z M34.09,54.44c3.91,4.63,8.12,8.96,12.63,12.99c2.15,1.92,5.35-1.25,3.18-3.18c-4.52-4.04-8.73-8.37-12.63-12.99 C35.4,49.04,32.23,52.24,34.09,54.44L34.09,54.44z M25.57,67.97c4.09,3.12,8.36,7.51,13.49,8.75c2.81,0.68,4.01-3.66,1.2-4.34c-4.6-1.11-8.73-5.48-12.41-8.29 C25.54,62.33,23.3,66.24,25.57,67.97L25.57,67.97z';
        eth[0] = 'M125.166 285.168l2.795 2.79 127.962-75.638L127.961 0l-2.795 9.5z M127.962 287.959V0L0 212.32z M126.386 412.306l1.575 4.6L256 236.587l-128.038 75.6-1.575 1.92z M0 236.585l127.962 180.32v-104.72z M127.961 154.159v133.799l127.96-75.637zM127.96 154.159L0 212.32l127.96 75.637z';
        btc[0] = 'M11.5 11.5v-2.5c1.75 0 2.789.25 2.789 1.25 0 1.172-1.684 1.25-2.789 1.25zm0 .997v2.503c1.984 0 3.344-.188 3.344-1.258 0-1.148-1.469-1.245-3.344-1.245zm12.5-.497c0 6.627-5.373 12-12 12s-12-5.373-12-12 5.373-12 12-12 12 5.373 12 12zm-7 1.592c0-1.279-1.039-1.834-1.789-2.025.617-.223 1.336-1.138 1.046-2.228-.245-.922-1.099-1.74-3.257-1.813v-1.526h-1v1.5h-.5v-1.5h-1v1.5h-2.5v1.5h.817c.441 0 .683.286.683.702v4.444c0 .429-.253.854-.695.854h-.539l-.25 1.489h2.484v1.511h1v-1.511h.5v1.511h1v-1.5c2.656 0 4-1.167 4-2.908z';
        hexi[0] = 'M79.56,290.47l-22.92-39.7a5.28,5.28,0,0,1,0-4.65l25.45-44.07a5.24,5.24,0,0,1,4.06-2.35h50.89a5.26,5.26,0,0,1,4.07,2.35l25.45,44.07a5.32,5.32,0,0,1,0,4.7l-25.45,44.07a5.33,5.33,0,0,1-4,2.34H91.36A15.43,15.43,0,0,1,79.56,290.47Zm165.27-90.69L194.13,112a7.21,7.21,0,0,0-5.56-3.21H87.17A7.21,7.21,0,0,0,81.61,112l-50.7,87.82a7.18,7.18,0,0,0,0,6.42L45.77,232l26-45a8.22,8.22,0,0,1,6.43-3.72H145a8.22,8.22,0,0,1,6.43,3.72l33.41,57.86a8.24,8.24,0,0,1,0,7.43l-26,45h29.7a7.19,7.19,0,0,0,5.56-3.22l50.7-87.81A7.18,7.18,0,0,0,244.83,199.78Zm92-58.09L259.06,6.93a15.37,15.37,0,0,0-12-6.93H91.45a15.37,15.37,0,0,0-12,6.93L1.65,141.69a15.36,15.36,0,0,0,0,13.85l17.83,30.88,51.7-89.56a10.14,10.14,0,0,1,7.94-4.58H196.53a10.14,10.14,0,0,1,7.94,4.58l58.71,101.69a10.13,10.13,0,0,1,0,9.16l-51.69,89.52h35.57a15.37,15.37,0,0,0,12-6.93l77.8-134.76A15.36,15.36,0,0,0,336.86,141.69Z';
        bnb[0] = 'M764.48,1050.52,1250,565l485.75,485.73,282.5-282.5L1250,0,482,768l282.49,282.5M0,1250,282.51,967.45,565,1249.94,282.49,1532.45Zm764.48,199.51L1250,1935l485.74-485.72,282.65,282.35-.14.15L1250,2500,482,1732l-.4-.4,282.91-282.12M1935,1250.12l282.51-282.51L2500,1250.1,2217.5,1532.61Z M1536.52,1249.85h.12L1250,963.19,1038.13,1175h0l-24.34,24.35-50.2,50.21-.4.39.4.41L1250,1536.81l286.66-286.66.14-.16-.26-.14';
        eyeL[0] = '187;190;195;190;195;181;187';
        eyeR[0] = '307;310;315;310;315;301;307';
        eyeL[1] = '187;187;187;187;187;187;187;187;187;187;195;181;187';
        eyeR[1] = '307;307;307;307;307;307;307;307;307;307;315;301;307';
    
        eyeRepeat[0] = ' repeatCount="indefinite"';
        eyeRepeat[1] = '';
    
        elements[0] = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500"><linearGradient id="NOCBg" gradientUnits="userSpaceOnUse" x1="250" y1="500" x2="250" y2="0"><stop offset=".6" style="stop-color:#',currNOC.myColors[0],'"/><stop offset="1" style="stop-color:#',currNOC.myColors[1],'"/></linearGradient><path fill="url(#NOCBg)" d="M0 0h500v500H0z"/>'));
        if (currNOC.target[4] == 1){ 
            elements[1] = '<ellipse transform="rotate(45 350 350)" stroke="#000" ry="99" rx="45" cy="350" cx="350" fill="#'; 
            elements[2] = '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="45 350 350" to="65 330 350" dur="0.1s" repeatCount="10"/></ellipse>'; 
            elements[3] = '<ellipse transform="rotate(-45 150 350)" ry="99" rx="45" cy="350" cx="150" stroke="#000" fill="#'; 
            elements[4] = '"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="-45 150 350" to="-65 170 350" dur="0.1s" repeatCount="10"/></ellipse>';
        }else{
            elements[1] = '><ellipse transform="rotate(45 350 350)" stroke="#000" ry="99" rx="45" cy="350" cx="350" fill="#'; 
            elements[2] = '"/>'; 
            elements[3] = '<ellipse transform="rotate(-45 150 350)" ry="99" rx="45" cy="350" cx="150" stroke="#000" fill="#'; 
            elements[4] = '"/>';
        }
        elements[5] = '<ellipse ry="133" rx="136" cy="299" cx="251" stroke="#000" fill="#'; 
        elements[6] = '"/><ellipse ry="116" rx="111" cy="310" cx="250" stroke="#000" fill="#'; 
        elements[7] = '90"/><ellipse ry="34" rx="36" cy="425" cx="210" stroke="#000" fill="#';
        elements[8] = '"/><ellipse ry="34" rx="36" cy="425" cx="288" stroke="#000" fill="#'; 
        elements[9] = '"/><rect height="50" width="200" y="423" x="147" fill="#';
        elements[10] = '"/><ellipse ry="65" rx="143" cy="145" cx="252" stroke="#000" fill="#';
        elements[11] = '"/><ellipse ry="40" rx="43" cy="97" cx="188" stroke="#000" fill="#';
        elements[12] = '"/><ellipse ry="40" rx="43" cy="97" cx="307" stroke="#000" fill="#';
        elements[13] = '"/><ellipse ry="31" rx="32" cy="97" cx="187" stroke="#000" fill="#fff"/><ellipse ry="31" rx="32" cy="97" cx="307" stroke="#000" fill="#fff"/>';
        if (currNOC.target[5] == 1){ 
            elements[14] = string(abi.encodePacked('<ellipse ry="22" rx="22" cy="102" cx="187">'));
            elements[15] = string(abi.encodePacked('<animate attributeName="cx" attributeType="XML" begin="0;graphics.click" ',eyeRepeat[currNOC.target[0]-1],' values="',eyeL[currNOC.target[1]-1],'" dur="',currNOC.target[3].toString(),'s" calcMode="linear"/></ellipse>'));
            elements[16] = string(abi.encodePacked('<ellipse ry="22" rx="22" cy="102" cx="307">'));
            elements[17] = string(abi.encodePacked('<animate attributeName="cx" attributeType="XML" begin="0;graphics.click" ',eyeRepeat[currNOC.target[0]-1],' values="',eyeR[currNOC.target[1]-1],'" dur="',currNOC.target[3].toString(),'s" calcMode="linear"/></ellipse>'));
            elements[18] = string(abi.encodePacked('<ellipse ry="5" rx="6" cy="94" cx="187" fill="#fff"><animate attributeName="cx" attributeType="XML" begin="0;graphics.click"',eyeRepeat[currNOC.target[0]-1],' values="',eyeL[currNOC.target[1]-1],'" dur="',currNOC.target[3].toString(),'s" calcMode="linear"/></ellipse>')); 
            elements[19] = string(abi.encodePacked('<ellipse ry="5" rx="6" cy="94" cx="307" fill="#fff"><animate attributeName="cx" attributeType="XML" begin="0;graphics.click"',eyeRepeat[currNOC.target[0]-1],' values="',eyeR[currNOC.target[1]-1],'" dur="',currNOC.target[3].toString(),'s" calcMode="linear"/></ellipse>'));    
        }else{
            elements[14] = string(abi.encodePacked('<ellipse ry="22" rx="22" cy="102" cx="',rNBtwn(_tokenId, 181, 196).toString(),'"/>'));
            elements[15] = '';
            elements[16] = string(abi.encodePacked('<ellipse ry="22" rx="22" cy="102" cx="',rNBtwn(_tokenId, 301, 315).toString(),'"/>'));
            elements[17] = '';
            elements[18] = '<ellipse ry="5" rx="6" cy="94" cx="187" fill="#fff"/>'; 
            elements[19] = '<ellipse ry="5" rx="6" cy="94" cx="307" fill="#fff"/>';
        }
        elements[20] = '<ellipse ry="11" rx="75" cy="172" cx="251"/>'; 
        (currNOC.target[2] != 1) ? elements[21] = '<ellipse ry="14" rx="76" cy="163" cx="252" fill="#' : elements[21] = '<ellipse fill="#'; 
        (currNOC.target[2] != 1) ? elements[22] = '"/>' : elements[22] = '"/>';
        (currNOC.target[6] == 1) ? elements[23] = '<rect stroke="#ff5656" height="52" width="38" y="183" x="232" fill="#ff5656"/><ellipse stroke="#ff5656" ry="19" rx="19" cy="237" cx="251" fill="#ff5656"/>' : elements[23] = ''; 
        (currNOC.target[8] == 1) ? elements[24] = '<path opacity="1" transform="translate(330,130), scale(0.5)" ' : elements[24] = '';
        (currNOC.target[8] == 1) ? elements[25] = string(abi.encodePacked('d="',scar[0],'" fill="#8b0000" />')) : elements[25] = '';
        if (currNOC.target[7] == 1){
            if (currNOC.target[2] == 1){
                elements[26] = '<path opacity="1" transform="translate(218,260), scale(2.8)" '; 
                elements[27] = string(abi.encodePacked(' d="',btc[0],'" fill="#ffffff80" stroke="#000" stroke-width=".5"/>'));
            } else if (currNOC.target[2] == 2){
                elements[26] = '<path opacity="1" transform="translate(225,260), scale(0.2)" '; 
                elements[27] = string(abi.encodePacked(' d="',eth[0],'" fill="#ffffff80" stroke="#000" stroke-width="1"/>'));
            } else if (currNOC.target[2] == 3){
                elements[26] = '<path opacity="1" transform="translate(218,260), scale(0.2)" '; 
                elements[27] = string(abi.encodePacked(' d="',hexi[0],'" fill="#ffffff80" stroke="#000" stroke-width="1"/>'));
            } else {
                elements[26] = '<path opacity="1" transform="translate(212,260), scale(0.03)" '; 
                elements[27] = string(abi.encodePacked(' d="',bnb[0],'" fill="#ffffff80" stroke="#000" stroke-width="10"/>'));  
            }
        } else {
            elements[26] = '';
            elements[27] = '';
        }
        elements[29] = '</svg>';
        
        string memory svgimage = string(abi.encodePacked(elements[0],elements[1],currNOC.myColors[1]));
        svgimage = string(abi.encodePacked(svgimage,elements[2],elements[3],currNOC.myColors[1],elements[4]));
        svgimage = string(abi.encodePacked(svgimage,elements[5],currNOC.myColors[1],elements[6],currNOC.myColors[2]));
        svgimage = string(abi.encodePacked(svgimage,elements[7],currNOC.myColors[1],elements[8],currNOC.myColors[1]));
        svgimage = string(abi.encodePacked(svgimage,elements[9],currNOC.myColors[0],elements[10],currNOC.myColors[1]));
        svgimage = string(abi.encodePacked(svgimage,elements[11],currNOC.myColors[3],elements[12],currNOC.myColors[3]));
        svgimage = string(abi.encodePacked(svgimage,elements[13],elements[14],elements[15],elements[16]));
        svgimage = string(abi.encodePacked(svgimage,elements[17],elements[18],elements[19],elements[20]));
        svgimage = string(abi.encodePacked(svgimage,elements[21],currNOC.myColors[1],elements[22],elements[23]));
        svgimage = string(abi.encodePacked(svgimage,elements[24],elements[25],elements[26],elements[27]));
        svgimage = string(abi.encodePacked(svgimage,elements[28],elements[29]));
    
        string[21] memory jsonData;
        jsonData[0] = '[{ "trait_type": "#1 Color", "value": "#';
        jsonData[1] = currNOC.myColors[1];
        jsonData[2] = '" }, { "trait_type": "#2 Color", "value": "#';
        jsonData[3] = currNOC.myColors[2];
        jsonData[4] = '" }, { "trait_type": "#3 Color", "value": "#';
        jsonData[5] = currNOC.myColors[3];
        jsonData[6] = '" }, { "trait_type": "#4 Color", "value": "#';
        jsonData[7] = currNOC.myColors[0];
        jsonData[8] = '" }, { "trait_type": "Legs", "value": "';
        (currNOC.target[4] == 1) ? jsonData[9] = 'Animation' : jsonData[9] = 'No effect';
        jsonData[10] = '" }, { "trait_type": "Eyes", "value": "';
        (currNOC.target[5] == 1) ? (currNOC.target[0]-1 == 1) ? jsonData[11] = string(abi.encodePacked('Animation ',currNOC.target[3].toString(),'s')) : jsonData[11] = string(abi.encodePacked('Replay')) : jsonData[11] = 'No effect';
        jsonData[12] = '" }, { "trait_type": "Mouth", "value": "';
        (currNOC.target[2] != 1) ? jsonData[13] = 'Smile' : jsonData[13] = 'Open';
        jsonData[14] = '" }, { "trait_type": "Tongue", "value": "';
        (currNOC.target[6] == 1) ? jsonData[15] = 'Yes' : jsonData[15] = 'None';
        jsonData[16] = '" }, { "trait_type": "Tattoo", "value": "';
        (currNOC.target[7] == 1) ? (currNOC.target[2] == 1) ? (jsonData[17] = 'BTC') : (currNOC.target[2] == 2) ? (jsonData[17] = 'ETH') : (currNOC.target[2] == 3) ? (jsonData[17] = 'HEX') : (jsonData[17] = 'BNB') : jsonData[17] = 'None';
        jsonData[18] = '" }, { "trait_type": "Scar", "value": "';
        (currNOC.target[8] == 1) ? jsonData[19] = 'Yes' : jsonData[19] = 'None';
        jsonData[20] = '" }]';
    
        string memory jsonPacket = string(abi.encodePacked(jsonData[0],jsonData[1],jsonData[2],jsonData[3],jsonData[4]));
        jsonPacket = string(abi.encodePacked(jsonPacket,jsonData[5],jsonData[6],jsonData[7],jsonData[8]));
        jsonPacket = string(abi.encodePacked(jsonPacket,jsonData[9],jsonData[10],jsonData[11],jsonData[12]));
        jsonPacket = string(abi.encodePacked(jsonPacket,jsonData[13],jsonData[14],jsonData[15],jsonData[16]));
        jsonPacket = string(abi.encodePacked(jsonPacket,jsonData[17],jsonData[18],jsonData[19],jsonData[20]));
    
        string memory encodedData = Base64.encode(bytes(string(abi.encodePacked('{"name": "FroXx #',currNOC.tokenID,'", "description": "FroXx is randomly generated art. Createdon mint execution. Each FroXx is stored directly on the Blockchain.", "attributes": ', jsonPacket,', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svgimage)), '"}'))));
        encodedData = string(abi.encodePacked('data:application/json;base64,', encodedData));

        return encodedData;
    }
  
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Error: This token has not been minted yet");
        return string(abi.encodePacked(buildImage(_tokenId)));
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
    function setGiftShare(uint256 _newGiftShare) public onlyOwner() {
        giftShare = _newGiftShare;
    }
 
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}