/**
 *Submitted for verification at polygonscan.com on 2021-10-15
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

//SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol



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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/Base64.sol

pragma solidity ^0.8.0;
/// [MIT License]
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

// File: contracts/Marden.sol

pragma solidity ^0.8.6;

library MardenUtils {
    struct Styles {
        string _face;
        string _eyecolor;
        string _body;
        string _wings1;
        string _wings2;
        string _bgColor;
    }

    function compareString(string memory _str1, string memory _str2) public pure returns (bool) {
        return keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2));
    }
    function getStyles(Styles memory style) public pure returns (string memory) {
        string memory styles = string(abi.encodePacked('<style> svg { background-color: ',style._bgColor,'; } .body { fill: ',style._body,';}  ._color1 { fill: lightgray; } ._color2 { fill: gray; } ._color3 { fill: #444; } .face { fill: ',style._face,'} .eyecolor { fill: ',style._eyecolor,'} .hands { fill: purple; }  .symbol1 { fill: midnightblue; } .symbol2 { fill: purple; } .wings1 { fill: ',style._wings1,'} .wings2 { fill: ',style._wings2,'}</style>')); 
        return styles;
    }
}

library MardenHead {
    function getHead() public pure returns(string memory) {
        string[9] memory parts;
        parts[0] = '<g id="head"><use xlink:href="#pixel" x="5" y="1" class="_color1" /><use xlink:href="#pixel" x="6" y="1" class="_color1" /><use xlink:href="#pixel" x="7" y="1" class="_color1" /><use xlink:href="#pixel" x="8" y="1" class="_color1" /><use xlink:href="#pixel" x="9" y="1" class="_color1" /><use xlink:href="#pixel" x="10" y="1" class="_color1" /><use xlink:href="#pixel" x="11" y="1" class="_color3" /><use xlink:href="#pixel" x="12" y="1" class="_color3" />';
        parts[1] = '<use xlink:href="#pixel" x="4" y="2" class="_color1" /><use xlink:href="#pixel" x="5" y="2" class="_color1" /><use xlink:href="#pixel" x="6" y="2" class="_color1" /><use xlink:href="#pixel" x="7" y="2" class="_color1" /><use xlink:href="#pixel" x="8" y="2" class="_color1" /><use xlink:href="#pixel" x="9" y="2" class="_color1" /><use xlink:href="#pixel" x="10" y="2" class="_color2" /><use xlink:href="#pixel" x="11" y="2" class="_color2" /><use xlink:href="#pixel" x="12" y="2" class="_color3" /><use xlink:href="#pixel" x="13" y="2" class="_color3" />';
        parts[2] = '<use xlink:href="#pixel" x="4" y="3" class="face" /><use xlink:href="#pixel" x="5" y="3" class="face" /><use xlink:href="#pixel" x="6" y="3" class="face" /><use xlink:href="#pixel" x="7" y="3" class="face" /><use xlink:href="#pixel" x="8" y="3" class="face" /><use xlink:href="#pixel" x="9" y="3" class="_color3" /><use xlink:href="#pixel" x="10" y="3" class="_color2" /><use xlink:href="#pixel" x="11" y="3" class="_color2" /><use xlink:href="#pixel" x="12" y="3" class="_color2" /><use xlink:href="#pixel" x="13" y="3" class="_color3" />';
        parts[3] = '<use xlink:href="#pixel" x="3" y="4" class="face" /><use xlink:href="#pixel" x="4" y="4" class="face" /><use xlink:href="#pixel" x="5" y="4" class="face" /><use xlink:href="#pixel" x="6" y="4" class="face" /><use xlink:href="#pixel" x="7" y="4" class="face" /><use xlink:href="#pixel" x="8" y="4" class="face" /><use xlink:href="#pixel" x="9" y="4" class="face" /><use xlink:href="#pixel" x="10" y="4" class="_color3" /><use xlink:href="#pixel" x="11" y="4" class="_color2" /><use xlink:href="#pixel" x="12" y="4" class="_color2" /><use xlink:href="#pixel" x="13" y="4" class="_color3" />';
        parts[4] = '<use xlink:href="#pixel" x="3" y="5" class="face" /><use xlink:href="#pixel" x="4" y="5" class="face" /><use xlink:href="#pixel" x="5" y="5" class="face" /><use xlink:href="#pixel" x="6" y="5" class="face" /><use xlink:href="#pixel" x="7" y="5" class="face" /><use xlink:href="#pixel" x="8" y="5" class="face" /><use xlink:href="#pixel" x="9" y="5" class="face" /><use xlink:href="#pixel" x="10" y="5" class="_color3" /><use xlink:href="#pixel" x="11" y="5" class="_color2" /><use xlink:href="#pixel" x="12" y="5" class="_color2" /><use xlink:href="#pixel" x="13" y="5" class="_color3" />';
        parts[5] = '<use xlink:href="#pixel" x="3" y="6" class="face" /><use xlink:href="#pixel" x="4" y="6" class="face" /><use xlink:href="#pixel" x="5" y="6" class="face" /><use xlink:href="#pixel" x="6" y="6" class="face" /><use xlink:href="#pixel" x="7" y="6" class="face" /><use xlink:href="#pixel" x="8" y="6" class="face" /><use xlink:href="#pixel" x="9" y="6" class="face" /><use xlink:href="#pixel" x="10" y="6" class="_color3" /><use xlink:href="#pixel" x="11" y="6" class="_color2" /><use xlink:href="#pixel" x="12" y="6" class="_color2" /><use xlink:href="#pixel" x="13" y="6" class="_color3" />';
        parts[6] = '<use xlink:href="#pixel" x="3" y="7" class="face" /><use xlink:href="#pixel" x="4" y="7" class="face" /><use xlink:href="#pixel" x="5" y="7" class="face" /><use xlink:href="#pixel" x="6" y="7" class="face" /><use xlink:href="#pixel" x="7" y="7" class="face" /><use xlink:href="#pixel" x="8" y="7" class="face" /><use xlink:href="#pixel" x="9" y="7" class="_color3" /><use xlink:href="#pixel" x="10" y="7" class="_color1" /><use xlink:href="#pixel" x="11" y="7" class="_color2" /><use xlink:href="#pixel" x="12" y="7" class="_color2" /><use xlink:href="#pixel" x="13" y="7" class="_color3" />';
        parts[7] = '<use xlink:href="#pixel" x="4" y="8" class="face" /><use xlink:href="#pixel" x="5" y="8" class="face" /><use xlink:href="#pixel" x="6" y="8" class="face" /><use xlink:href="#pixel" x="7" y="8" class="face" /><use xlink:href="#pixel" x="8" y="8" class="_color3" /><use xlink:href="#pixel" x="9" y="8" class="_color1" /><use xlink:href="#pixel" x="10" y="8" class="_color1" /><use xlink:href="#pixel" x="11" y="8" class="_color2" /><use xlink:href="#pixel" x="12" y="8" class="_color2" /><use xlink:href="#pixel" x="13" y="8" class="_color3" />';
        parts[8] = '<use xlink:href="#pixel" x="4" y="9" class="_color1" /><use xlink:href="#pixel" x="5" y="9" class="_color1" /><use xlink:href="#pixel" x="6" y="9" class="_color1" /><use xlink:href="#pixel" x="7" y="9" class="_color1" /><use xlink:href="#pixel" x="8" y="9" class="_color1" /><use xlink:href="#pixel" x="9" y="9" class="_color1" /><use xlink:href="#pixel" x="10" y="9" class="_color2" /><use xlink:href="#pixel" x="11" y="9" class="_color2" /><use xlink:href="#pixel" x="12" y="9" class="_color3" /></g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8]));
        return output;
    }    
}

library MardenEyes { 
    function wardenEye() public pure returns(string memory) {
        string[6] memory parts;
        parts[0] = '<g id="eyes" transform="translate(0,2)" class="eyecolor" >';
        parts[1] = '<use xlink:href="#pixel" x="1" y="0" /><use xlink:href="#pixel" x="2" y="0" /><use xlink:href="#pixel" x="10" y="0" /><use xlink:href="#pixel" x="11" y="0" />';
        parts[2] = '<use xlink:href="#pixel" x="2" y="1" /><use xlink:href="#pixel" x="3" y="1" /><use xlink:href="#pixel" x="8" y="1" /><use xlink:href="#pixel" x="9" y="1" /><use xlink:href="#pixel" x="10" y="1" />';
        parts[3] = '<use xlink:href="#pixel" x="3" y="2" /><use xlink:href="#pixel" x="4" y="2" /><use xlink:href="#pixel" x="5" y="2" /><use xlink:href="#pixel" x="8" y="2" /> <use xlink:href="#pixel" x="7" y="2" />';
        parts[4] = '<use xlink:href="#pixel" x="4" y="3" /><use xlink:href="#pixel" x="5" y="3" /><use xlink:href="#pixel" x="7" y="3" /><use xlink:href="#pixel" x="8" y="3" />';
        parts[5] = '<use xlink:href="#pixel" x="5" y="4" /><use xlink:href="#pixel" x="7" y="4" /></g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        return output;
    }
    function robotEye() public pure returns(string memory) {
        string[3] memory parts;
        parts[0] = '<g id="robot-eye" transform="translate(0,2)" fill="lightgray">';
        parts[1] = '<rect x="3" y="2" width="7" height="1" /><use xlink:href="#pixel" x="3" y="3" /><g fill="red"><rect x="4" y="3" width="5" height="1" /></g>';
        parts[2] = '<use xlink:href="#pixel" x="9" y="3" /><rect x="3" y="4" width="7" height="1" /></g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function thugEye() public pure returns(string memory) {
        string[5] memory parts;
        parts[0] = '<g id="ciggar" transform="translate(0,8)"><use xlink:href="#pixel" x="6" y="0" fill="brown" /><use xlink:href="#pixel" x="5" y="0" fill="wheat" /><use xlink:href="#pixel" x="4" y="0" fill="wheat" /><use xlink:href="#pixel" x="3" y="0" fill="red" /><use xlink:href="#pixel" x="2" y="-1" fill="gray" /><use xlink:href="#pixel" x="1" y="-2" fill="gray" /><use xlink:href="#pixel" x="0" y="-3" fill="lightgray" /></g>';
        parts[1] = '<g id="thug-eye" transform="translate(0,2)" fill="black"><use xlink:href="#pixel" x="3" y="2" /><use xlink:href="#pixel" x="4" y="2" /><use xlink:href="#pixel" x="5" y="2" fill="white" /><use xlink:href="#pixel" x="7" y="2" /><use xlink:href="#pixel" x="8" y="2" fill="white" /><use xlink:href="#pixel" x="9" y="2" /><use xlink:href="#pixel" x="10" y="2" /><use xlink:href="#pixel" x="11" y="2" /><use xlink:href="#pixel" x="12" y="2" />';
        parts[2] = '<use xlink:href="#pixel" x="3" y="3" /><use xlink:href="#pixel" x="4" y="3" fill="white" /><use xlink:href="#pixel" x="5" y="3" /><use xlink:href="#pixel" x="6" y="3" /><use xlink:href="#pixel" x="7" y="3" fill="white" /><use xlink:href="#pixel" x="8" y="3" /><use xlink:href="#pixel" x="9" y="3" /><use xlink:href="#pixel" x="10" y="3" />';
        parts[3] = '<use xlink:href="#pixel" x="4" y="4" /><use xlink:href="#pixel" x="5" y="4" /><use xlink:href="#pixel" x="7" y="4" /><use xlink:href="#pixel" x="8" y="4" /><use xlink:href="#pixel" x="9" y="4" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }

    function tdEye() public pure returns(string memory) {
        string[4] memory parts;
        parts[0] = '<g id="tdEye" transform="translate(0,2)" fill="red"><use xlink:href="#pixel" x="3" y="1" fill="#6384B3"/><use xlink:href="#pixel" x="4" y="1" fill="#6384B3" /><use xlink:href="#pixel" x="5" y="1" fill="#6384B3" /><use xlink:href="#pixel" x="6" y="1" fill="#6384B3" /><use xlink:href="#pixel" x="7" y="1" fill="#6384B3" /><use xlink:href="#pixel" x="8" y="1" fill="#6384B3" /><use xlink:href="#pixel" x="9" y="1" fill="#6384B3" />';
        parts[1] = '<use xlink:href="#pixel" x="3" y="2" fill="#6384B3" /><use xlink:href="#pixel" x="4" y="2" fill="blue" /><use xlink:href="#pixel" x="5" y="2" fill="blue" /><use xlink:href="#pixel" x="6" y="2" fill="red" /><use xlink:href="#pixel" x="7" y="2" fill="red" /><use xlink:href="#pixel" x="8" y="2" fill="red" /><use xlink:href="#pixel" x="9" y="2" fill="#6384B3" /><use xlink:href="#pixel" x="10" y="2" fill="#444" /><use xlink:href="#pixel" x="11" y="2" fill="#444" />';
        parts[2] = '<use xlink:href="#pixel" x="3" y="3" fill="#6384B3" /><use xlink:href="#pixel" x="4" y="3" fill="blue" /><use xlink:href="#pixel" x="5" y="3" fill="blue" /><use xlink:href="#pixel" x="6" y="3" fill="blue" /><use xlink:href="#pixel" x="7" y="3" /><use xlink:href="#pixel" x="8" y="3" /><use xlink:href="#pixel" x="9" y="3" fill="#6384B3" /><use xlink:href="#pixel" x="10" y="3" fill="#444" /><use xlink:href="#pixel" x="11" y="3" fill="#444" /><use xlink:href="#pixel" x="12" y="3" fill="#444" />';
        parts[3] = '<use xlink:href="#pixel" x="3" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="4" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="5" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="6" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="7" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="8" y="4" fill="#6384B3" /><use xlink:href="#pixel" x="9" y="4" fill="#6384B3" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }
    function heartEye() public pure returns(string memory) {
        string[2] memory parts;
        parts[0] = '<g id="heart-eye" transform="translate(0,2)" fill="pink">';
        parts[1] = '<rect x="3" y="2" width="2" height="1" /><rect x="4" y="2" width="1" height="1" fill="orangered" /><rect x="8" y="2" width="1" height="1" fill="orangered" /><rect x="8" y="3" width="1" height="1" fill="orangered" /><rect x="8" y="4" width="1" height="1" fill="orangered" /><rect x="7" y="5" width="1" height="1" fill="orangered" /><rect x="6" y="6" width="1" height="1" fill="orangered" /><rect x="6" y="2" width="2" height="1" /><rect x="3" y="3" width="5" height="1" /><rect x="3" y="4" width="5" height="1" /><rect x="4" y="5" width="3" height="1" /><rect x="5" y="6" width="1" height="1" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        return output;
    }

    function smileEye() public pure returns(string memory) {
        string[2] memory parts;
        parts[0] = '<g id="smile-eye" transform="translate(0,2)" fill="#2f2f">';
        parts[1] = '<use xlink:href="#pixel" x="3" y="3" /><use xlink:href="#pixel" x="4" y="2" /><use xlink:href="#pixel" x="5" y="3" /><use xlink:href="#pixel" x="7" y="3" /><use xlink:href="#pixel" x="8" y="2" /><use xlink:href="#pixel" x="9" y="3" /><use xlink:href="#pixel" x="5" y="6" /><use xlink:href="#pixel" x="4" y="5" /><use xlink:href="#pixel" x="6" y="6" /><use xlink:href="#pixel" x="7" y="5" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        return output;
    }

    function brokenFace() public pure returns(string memory) {
        string[2] memory parts;
        parts[0] = '<g id="brokenface"  fill="#2f2f">';
        parts[1] = '<use xlink:href="#pixel" x="8" y="4" /><use xlink:href="#pixel" x="9" y="4" /><use xlink:href="#pixel" x="8" y="5" fill="red"/><use xlink:href="#pixel" x="9" y="5" /><use xlink:href="#pixel" x="7" y="6" /><use xlink:href="#pixel" x="8" y="6" /><use xlink:href="#pixel" x="9" y="6" /><use xlink:href="#pixel" x="6" y="7" /><use xlink:href="#pixel" x="7" y="7" /><use xlink:href="#pixel" x="8" y="7" /><use xlink:href="#pixel" x="6" y="8" /><use xlink:href="#pixel" x="7" y="8" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        return output;
    }

    function mustacheFace() public pure returns(string memory) {
        string[3] memory parts;
        parts[0] = '<g id="mustacheface" transform="translate(0,2)" fill="black"><use xlink:href="#pixel" x="3" y="2" /><use xlink:href="#pixel" x="4" y="2" /><use xlink:href="#pixel" x="5" y="2" /><use xlink:href="#pixel" x="7" y="2" /><use xlink:href="#pixel" x="8" y="2" /><use xlink:href="#pixel" x="8" y="2" /><use xlink:href="#pixel" x="6" y="4" /><use xlink:href="#pixel" x="5" y="5" /><use xlink:href="#pixel" x="7" y="5" />';
        parts[1] = '<rect x="1" y="6" width="5" height="1" /><rect x="7" y="6" width="5" height="1" /><use xlink:href="#pixel" x="1" y="5" /><use xlink:href="#pixel" x="3" y="5" /><rect x="1" y="4" width="3" height="1" />';
        parts[2] = '<use xlink:href="#pixel" x="11" y="5" /><use xlink:href="#pixel" x="9" y="5" /><rect x="9" y="4" width="3" height="1" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }
    
    function squidRectFace() public pure returns(string memory) {
        string [3] memory parts;
        parts[0] = '<g id="rectSquidFace" fill="#FF0075"><rect x="5" y="1" width="6" height="1" /><rect x="4" y="2" width="6" height="1" /><rect x="10" y="2" width="2" height="1" fill="#F43B86" /><rect x="10" y="3" width="3" height="1" fill="#F43B86" /><rect x="11" y="4" width="2" height="5" fill="#F43B86" /><rect x="10" y="9" width="2" height="1" fill="#F43B86" /><rect x="10" y="7" width="1" height="1" />';
        parts[1] =  '<rect x="9" y="8" width="2" height="1" /><rect x="4" y="9" width="6" height="1" /><rect x="4" y="4" width="4" height="1" fill="#ffffff" /><use xlink:href="#pixel" x="4" y="5" fill="#ffffff" /><use xlink:href="#pixel" x="7" y="5" fill="#ffffff" /><use xlink:href="#pixel" x="4" y="6" fill="#ffffff" /><use xlink:href="#pixel" x="7" y="6" fill="#ffffff" /><rect x="4" y="7" width="4" height="1" fill="#ffffff" />';
        parts[2] = '<rect x="4" y="3" width="5" height="1" fill="#333" /><rect x="3" y="4" width="1" height="4" fill="#333" /><rect x="5" y="5" width="2" height="2" fill="#333" /><rect x="8" y="4" width="2" height="3" fill="#333" /><rect x="8" y="7" width="1" height="1" fill="#333" /><rect x="4" y="8" width="4" height="1" fill="#333" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function laserEye(string memory _eyecolor) public pure returns(string memory) {
        string[2] memory parts;
        parts[0] = string(abi.encodePacked('<g id="laserEye" fill="',_eyecolor,'" ><use xlink:href="#pixel" x="2" y="0" /><use xlink:href="#pixel" x="1" y="1" /><use xlink:href="#pixel" x="0" y="2" /><use xlink:href="#pixel" x="4" y="0" /><use xlink:href="#pixel" x="3" y="1" /><use xlink:href="#pixel" x="2" y="2" /><use xlink:href="#pixel" x="1" y="3" /><use xlink:href="#pixel" x="0" y="3" /><use xlink:href="#pixel" x="0" y="4" /><use xlink:href="#pixel" x="4" y="4" /><use xlink:href="#pixel" x="7" y="4" /><use xlink:href="#pixel" x="4" y="6" /><use xlink:href="#pixel" x="7" y="6" />'));
        parts[1] = '<rect x="0" y="5" width="9" height="1" /><use xlink:href="#pixel" x="0" y="6" /><use xlink:href="#pixel" x="0" y="7" /><use xlink:href="#pixel" x="1" y="7" /><use xlink:href="#pixel" x="0" y="8" /><use xlink:href="#pixel" x="2" y="8" /><use xlink:href="#pixel" x="1" y="9" /><use xlink:href="#pixel" x="3" y="9" /><use xlink:href="#pixel" x="2" y="10" /><use xlink:href="#pixel" x="3" y="11" /></g>';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1]));
        return output;
    }
}

library MardenBody {
    function getBody() public pure returns(string memory) {
        string[7] memory parts;
        parts[0] = '<g id="body"><use xlink:href="#pixel" x="7" y="10" class="_color1" /><use xlink:href="#pixel" x="8" y="10" class="_color3" />';
        parts[1] = '<use xlink:href="#pixel" x="6" y="11" class="body" /><use xlink:href="#pixel" x="7" y="11" class="body" /><use xlink:href="#pixel" x="8" y="11" class="body" /><use xlink:href="#pixel" x="9" y="11" class="_color3" />';
        parts[2] = '<use xlink:href="#pixel" x="5" y="12" class="body" /><use xlink:href="#pixel" x="6" y="12" class="body" /><use xlink:href="#pixel" x="7" y="12" class="body" /><use xlink:href="#pixel" x="8" y="12" class="body" /><use xlink:href="#pixel" x="9" y="12" class="body" /><use xlink:href="#pixel" x="10" y="12" class="_color3" />';
        parts[3] = '<use xlink:href="#pixel" x="5" y="13" class="body" /><use xlink:href="#pixel" x="6" y="13" class="body" /><use xlink:href="#pixel" x="7" y="13" class="body" /><use xlink:href="#pixel" x="8" y="13" class="body" /><use xlink:href="#pixel" x="9" y="13" class="body" /><use xlink:href="#pixel" x="10" y="13" class="_color3" />';
        parts[4] = '<use xlink:href="#pixel" x="5" y="14" class="body" /><use xlink:href="#pixel" x="6" y="14" class="body" /><use xlink:href="#pixel" x="7" y="14" class="body" /><use xlink:href="#pixel" x="8" y="14" class="body" /><use xlink:href="#pixel" x="9" y="14" class="body" /><use xlink:href="#pixel" x="10" y="14" class="_color3" />';
        parts[5] = '<use xlink:href="#pixel" x="5" y="15" class="hands" /><use xlink:href="#pixel" x="6" y="15" class="body" /><use xlink:href="#pixel" x="7" y="15" class="body" /><use xlink:href="#pixel" x="8" y="15" class="body" /><use xlink:href="#pixel" x="9" y="15" class="body" /><use xlink:href="#pixel" x="10" y="15" class="hands" /></g>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        return output;
    }
}

library MardenSymbol {
    function getSymbol() public pure returns(string memory) {
        string[4] memory parts;
        parts[0] = '<g id="wardentoken" transform="translate(6,12)">';
        parts[1] = '<use xlink:href="#pixel" x="0" y="0" class="symbol1" /><use xlink:href="#pixel" x="2" y="0" class="symbol1" />';
        parts[2] = '<use xlink:href="#pixel" x="0" y="1" class="symbol2" /><use xlink:href="#pixel" x="1" y="1" class="symbol1" /><use xlink:href="#pixel" x="2" y="1" class="symbol2" />';
        parts[3] = '<use xlink:href="#pixel" x="2" y="1" class="symbol2" /><use xlink:href="#pixel" x="1" y="2" class="symbol2" /></g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        return output;
    }
}

library MardenWing {
    function getWing() public pure returns(string memory) {
        string[6] memory parts;
        parts[0] = '<g id="wings" transform="translate(10,11)">';
        parts[1] = '<use xlink:href="#pixel" x="0" y="0" class="wings1" /><use xlink:href="#pixel" x="1" y="0" class="wings1" /><use xlink:href="#pixel" x="2" y="0" class="wings1" />';
        parts[2] = '<use xlink:href="#pixel" x="1" y="1" class="wings2" /><use xlink:href="#pixel" x="2" y="1" class="wings1" /><use xlink:href="#pixel" x="3" y="1" class="wings1" />';
        parts[3] = '<use xlink:href="#pixel" x="1" y="2" class="wings2" /><use xlink:href="#pixel" x="2" y="2" class="wings2" /><use xlink:href="#pixel" x="3" y="2" class="wings1" /><use xlink:href="#pixel" x="4" y="2" class="wings1" />';
        parts[4] = '<use xlink:href="#pixel" x="1" y="3" class="wings2" /><use xlink:href="#pixel" x="2" y="3" class="wings2" /><use xlink:href="#pixel" x="3" y="3" class="wings1" /><use xlink:href="#pixel" x="4" y="3" class="wings1" />';
        parts[5] = '<use xlink:href="#pixel" x="1" y="4" class="wings2" /><use xlink:href="#pixel" x="2" y="4" class="wings2" /><use xlink:href="#pixel" x="3" y="4" class="wings1" /><use xlink:href="#pixel" x="4" y="4" class="wings1" /></g>';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        return output;
    }
}


contract MardenFactory is ERC721Enumerable, ReentrancyGuard, Ownable {

    mapping(uint256 => uint256) public minted;

    string[] private colors = [ 
        "#222831",
        "#393E46",
        "#00ADB5",
        "#F9ED69",
        "#F08A5D",
        "#B83B5E",
        "#6A2C70",
        "#F38181",
        "#FCE38A",
        "#EAFFD0",
        "#95E1D3",
        "#08D9D6",
        "#252A34",
        "#FF2E63",
        "#53354A",
        "#903749",
        "#E84545",
        "#2B2E4A",
        "#A7FF83",
        "#17B978",
        "#086972",
        "#94FC13",
        "#1df900",
        "#071A52",
        "#FF165D",
        "#FF9A00",
        "#F6F7D7",
        "#3EC1D3"
    ];

    string[] private bgColors = [
        "#F0E5CF", //COMMON
        "#149e22", //RARE
        "#f1e61d", //EPIC
        "#000000" //LEGENDARY
    ];

    function getEye(uint256 tokenId) internal view returns(string memory) {
        uint256 rand = random(string(abi.encodePacked(tokenId, "eyeware")));
        uint256 eyeNum = rand % 11;
        if(eyeNum == 0) {
            string memory eyecolor = getEyeColor(tokenId);
            return MardenEyes.laserEye(eyecolor);
        } else if(eyeNum == 1) {
            return  MardenEyes.robotEye();
        } else if(eyeNum == 2) {
            return  MardenEyes.tdEye();
        } else if(eyeNum == 3) {
            return MardenEyes.thugEye();
        } else if(eyeNum == 4) {
            return MardenEyes.heartEye();
        } else if(eyeNum == 5) {
            return MardenEyes.smileEye();
        } else if(eyeNum == 6) {
            return  MardenEyes.brokenFace();
        } else if(eyeNum == 7) {
            return MardenEyes.mustacheFace();
        } else if (eyeNum == 8) {
            string memory rarity = getRarity(tokenId);
            if(MardenUtils.compareString(rarity, "legendary") || MardenUtils.compareString(rarity, "epic")) {
                return  MardenEyes.squidRectFace();
            } 
            return MardenEyes.wardenEye();
        } else {
            return MardenEyes.wardenEye();

        }
    }

    function getEyeColor(uint256 tokenId) internal view returns(string memory) {
        return pluck(tokenId, "EYES", colors);
    }

    function getBgColor(uint256 tokenId) internal view returns(string memory) {
        return pluck(tokenId, "BACKGROUND", bgColors);
    }

    function getWingColor(uint256 tokenId) internal view returns(string memory, string memory) { 
        return (pluck(tokenId, "WINGS1", colors), pluck(tokenId, "WINGS2", colors));
    }

    function getFaceColor(uint256 tokenId) internal view returns(string memory) {
        return pluck(tokenId, "FACE", colors);
    } 

    function getBodyColor(uint256 tokenId) internal view returns(string memory) {
        return pluck(tokenId, "BODY", colors);
    }

    function getRarity(uint256 tokenId) internal view returns(string memory) {
        string memory rarity = getBgColor(tokenId);
        if(MardenUtils.compareString(rarity, bgColors[0])) {
            return "common";
        } else if (MardenUtils.compareString(rarity, bgColors[1])) {
            return "rare";
        } else if (MardenUtils.compareString(rarity, bgColors[2])) {
            return "epic";
        } else {
            return "legendary";
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pluck(uint256 tokenId, string memory prefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(prefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 rareBg = rand % 21;

        /**
        @dev Background color is represent the rarity of MardenLoot
        "#F0E5CF" = COMMON 
        "#149e22" = RARE
        "#f1e61d" = EPIC
        "#a80fc3" = LEGENDARY
        */
        if(MardenUtils.compareString(prefix, "BACKGROUND")) {
            if(rareBg > 14 && rareBg < 19) {
                output = sourceArray[1];
            } else if (rareBg >= 19) {
                output = sourceArray[2];
            } else if (rareBg == 0) {
                output = sourceArray[3];
            } else {
                output = sourceArray[0];
            }
        }
        return output;
    }

    function isMinted(uint256 tokenId) internal returns(bool) {
        if(minted[tokenId] == 0) {
            minted[tokenId] = 1;
            return true;
        } else {
            return false;
        }    
    }


    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        string[9] memory parts;
        (string memory wings1, string memory wings2) = getWingColor(tokenId);

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="336px" height="336px" preserveAspectRatio="xMinYMin meet" viewBox="0, 0 16, 16">';
        parts[1] = string(abi.encodePacked('<defs><g id="pixel" class="',toString(tokenId),'"><rect width="1" height="1"></rect></g></defs>'));
        parts[2] = MardenUtils.getStyles(
            MardenUtils.Styles(
                getFaceColor(tokenId), 
                getEyeColor(tokenId), 
                getBodyColor(tokenId), 
                wings1, 
                wings2,
                getBgColor(tokenId)
            )
        ); 
        parts[3] = MardenHead.getHead();
        parts[4] = getEye(tokenId);
        parts[5] = MardenBody.getBody();
        parts[6] = MardenSymbol.getSymbol();
        parts[7] = MardenWing.getWing();
        parts[8] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        output = string(abi.encodePacked(output, parts[6], parts[7], parts[8]));


        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Marden #', toString(tokenId), '", "description": "Marden 16 bit is the NFT project for WardenSwap fanart contest on OCT 2021, for random Marden generated and stored on chain. (Loot project random Style), there are 3 types of rarity represented by it background color, there are COMMON, RARE, EPIC, LEGENDARY, use it as avatar or any way you want !", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '", "attributes": [ { "trait_type": "rarity", "value": "',getRarity(tokenId),'"} ]}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId < 16001, "Token ID invalid");
        require(isMinted(tokenId), 'this token is minted!');
        _safeMint(_msgSender(), tokenId);
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

    constructor() ERC721("Warden 16 NFTs", "WAD16") Ownable() {
    }

}