/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// Dependency file: @openzeppelin/contracts/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Strings.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/introspection/ERC165.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC721/ERC721.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

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


// Dependency file: @openzeppelin/contracts/interfaces/IERC165.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


// Dependency file: @openzeppelin/contracts/interfaces/IERC2981.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Counters.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Dependency file: contracts/Hashku.sol

// pragma solidity 0.8.9;

/*
*
* Hashku Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used as base contract for ERC721 when minting on Hashku
*
*/

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/interfaces/IERC2981.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Hashku is Context, Ownable, ERC721, IERC2981 {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private tokenIdTracker;

    string public baseTokenURI;
    string public key = "SHOP";
    string public group = "init";
    uint256 public maxMintPerAddress;
    uint256 public maxMintPerTransaction;
    uint256 public maxTokens;
    uint256 public price;
    bool public isPublic;
    bool public isClosed;
    mapping(address => uint256) public tokensMinted;
    address public withdrawalAddress;
    address public verifySigner;
    uint256 public royaltyPercent;
    address public proxyRegistryAddress;

    event ContractUpdated(string _type);

    modifier onlyWithdrawer() {
        require(withdrawalAddress != address(0), "no_withdrawals");
        require(withdrawalAddress == _msgSender(), "not_allowed");
        _;
    }

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _baseTokenURI,
        string memory _key,
        uint256 _maxTokens, 
        uint256 _maxMintPerAddress,
        uint256 _maxMintPerTransaction,
        uint256 _price,
        uint256 _royaltyPercent,
        address _withdrawalAddress
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        key = _key;
        maxTokens = _maxTokens;
        maxMintPerAddress = _maxMintPerAddress;
        maxMintPerTransaction = _maxMintPerTransaction;
        price = _price;
        royaltyPercent = _royaltyPercent;
        withdrawalAddress = _withdrawalAddress;
        verifySigner = _msgSender();
    }

    // support IERC2981
    function supportsInterface(bytes4 _interfaceId) public view virtual override (ERC721, IERC165) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    // return the token URI for a specific token
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "no_token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString())) : "";
    }

    // internal mint function, incrementing token
    function mint(address _to) internal {
        _safeMint(_to, tokenIdTracker.current());
        tokenIdTracker.increment();
    }

    // owner sends NFTs to addresses
    function send(address[] calldata _addresses, uint256[] calldata _amounts) external virtual onlyOwner {
        require(_addresses.length == _amounts.length, "amount_mismatch");

        uint256 total;
        for (uint256 t = 0; t < _amounts.length; t++) {
            total += _amounts[t];
        }

        require(nextToken() + total <= maxTokens, "not_enough_tokens");

        delete total;

        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 a = 0; a < _amounts[i]; a++) {
                mint(_addresses[i]);
            }
        }
    }

    // buy NFTs - version without signature required for public mint
    function shop(uint256 _amount) external virtual payable {}

    // buy NFTs
    function shop(uint256 _amount, bytes memory _signature) external virtual payable {}

    // return the id for the next token that will be minted
    function nextToken() public view returns (uint256) {
        return tokenIdTracker.current();
    }

    // check if a msg sender is eligible to shop
    function eligible() public view virtual returns (bool) {
        if (isClosed) {
            return false;
        }

        return isPublic;
    }

    // owner can ONLY decrease the total number of available tokens
    function decreaseMaxTokens(uint256 _amount) external virtual onlyOwner {
        require(_amount < maxTokens, "only_decrease");
        maxTokens = _amount;
    }

    // owner set the contract to public mode
    function setIsPublic(bool _public) external virtual onlyOwner {
        isPublic = _public;
        emit ContractUpdated("isPublic");
    }

    // owner set the contract to closed
    function setIsClosed(bool _closed) external virtual onlyOwner {
        isClosed = _closed;
        emit ContractUpdated("isClosed");
    }

    // owner set the price of minting
    function setPrice(uint256 _price) external virtual onlyOwner {
        price = _price;
    }

    // set the maximum amount an address may mint
    function setMaxMintPerAddress(uint256 _amount) external virtual onlyOwner {
        maxMintPerAddress = _amount;
    }

    // set the maximum amount an address may mint
    function setMaxMintPerTransaction(uint256 _amount) external virtual onlyOwner {
        maxMintPerTransaction = _amount;
    }

    // owner set the contract key for signature verification
    function setKey(string calldata _key) external virtual onlyOwner {
        key = _key;
    }

    // set the current contract group for signature verification
    function setGroup(string memory _group) external virtual onlyOwner {
        group = _group;
        emit ContractUpdated("group");
    }

    // owner set a new base token URI
    function setBaseUri(string calldata _baseTokenURI) external virtual onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // owner set a new address for signature verification
    function setVerifySigner(address _verifySigner) external virtual onlyOwner {
        verifySigner = _verifySigner;
    }

    // verify signature based on contract key, contract group, token amount, and the msg sender
    function verifySignature(
        bytes memory _signature
    ) internal view virtual returns (bool) {
        bytes32 _messageHash = keccak256(abi.encodePacked(key, group, _msgSender()));

        return _messageHash.toEthSignedMessageHash().recover(_signature) == verifySigner;
    }

    // set the royalty percent
    function setRoyaltyPercent(uint256 _amount) external virtual onlyOwner {
        royaltyPercent = _amount;
    }

    // EIP-2981 royaltyInfo
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "no_token");

        return (address(this), SafeMath.div(SafeMath.mul(_salePrice, royaltyPercent), 100));
    }

    // withdrawal address convenience method for pulling balance of contract
    function seeBalance() external view virtual onlyWithdrawer returns (uint256) {
        return address(this).balance;
    }

    // withdrawal address send an amount to an address
    function withdraw(address payable _to, uint256 _amount) external virtual onlyWithdrawer returns (bool) {
        require(_amount <= address(this).balance, "insufficient_funds");
        _to.transfer(_amount);
        return true;
    }

    // withdrawal address set a new withdrawal address
    function setWithdrawalAddress(address _address) external virtual onlyWithdrawer {
        withdrawalAddress = _address;
        // emit ContractUpdated("withdrawalAddress");
    }

    // owner can set the proxy registry access after deploy
    function setProxyRegistryAddress(address _proxy) external virtual onlyOwner {
        // OpenSea Rinkeby Address = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
        // OpenSea Mainnet Address = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
        proxyRegistryAddress = _proxy;
    }

    // override isApprovedForAll to allow proxy address for OpenSea gasless listing
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(_proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


// Dependency file: contracts/imports/VerifySignature.sol


/*
*
* VerifySignature Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Verify a signature generated off-chain
* To be used for helping avoid gas wars without having to whitelist addresses on contract
*
*/

// pragma solidity 0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract VerifySignature is Ownable {

    address public verifySigner;

    constructor() {
        verifySigner = msg.sender;
    }

    function setSigner(address _newSigner) public onlyOwner {
        verifySigner = _newSigner;
    }

    function getMessageHash(
        string memory _messageOne,
        string memory _messageTwo,
        uint _numberOne,
        uint _numberTwo,
        address _address
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_messageOne, _messageTwo, _numberOne, _numberTwo, _address));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "siglngth");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function verifySignature(
        string memory _messageOne,
        string memory _messageTwo,
        uint _numberOne,
        uint _numberTwo,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 _messageHash = getMessageHash(_messageOne, _messageTwo, _numberOne, _numberTwo, msg.sender);
        bytes32 _ethSignedMessageHash = getEthSignedMessageHash(_messageHash);
        return recoverSigner(_ethSignedMessageHash, signature) == verifySigner;
    }
}

// Dependency file: contracts/imports/Withdraw.sol


/*
*
* Withdraw Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Withdraw funds from a contract
*
*/

// pragma solidity 0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract Withdraw is Ownable {
    function seeBalance() public view onlyOwner returns(uint)  {
        return address(this).balance;
    }

    function withdraw(address payable _to, uint _amount) public onlyOwner returns(bool)  {
        require(_amount <= address(this).balance, "insfnds");
        _to.transfer(_amount);
        return true;
    }
}

// Dependency file: contracts/imports/Group.sol


/*
*
* Group Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used in conjuction with VerifySignature as a way to validate a signature generated off-chain
*
*/

// pragma solidity 0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract Group is Ownable {

    string public group = "init";

    event GroupUpdated(string _group);

    function setGroup(string memory _grp) public onlyOwner {
        group = _grp;
        emit GroupUpdated(_grp);
    }
}

// Dependency file: contracts/imports/ExternalAccount.sol


/*
*
* ExternalAccount Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used to allow a single external address (likely another another contract) to interact with particular functions
*
*/

// pragma solidity 0.8.9;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract ExternalAccount is Ownable {

    address public externalAccount;

    function setExternalAccount(address _addr) public onlyOwner {
        externalAccount = _addr;
    }

    modifier onlyExternalAccount() {
        require(externalAccount != address(0), "noext");
        require(msg.sender == externalAccount, "invacct");
        _;
    }
}

// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// Dependency file: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// Dependency file: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates weither any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_mint}.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    /**
     * @dev See {ERC1155-_mintBatch}.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] += amounts[i];
        }
    }

    /**
     * @dev See {ERC1155-_burn}.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /**
     * @dev See {ERC1155-_burnBatch}.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply[ids[i]] -= amounts[i];
        }
    }
}


// Dependency file: contracts/CabinetOfCuriosities.sol


/*
*
* Society of the Hourglass: Cabinet of Curiosities
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Website: https://www.societyofthehourglass.com/
* Mint Page: https://app.hashku.com/team/society-of-the-hourglass/cabinet-of-curiosities/mint
*
*/

// pragma solidity 0.8.9;

// import "contracts/imports/VerifySignature.sol";
// import "contracts/imports/Withdraw.sol";
// import "contracts/imports/Group.sol";
// import "contracts/imports/ExternalAccount.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
// import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

contract CabinetOfCuriosities is 
    Ownable, 
    Withdraw, 
    Group, 
    VerifySignature, 
    ExternalAccount,
    ERC1155, 
    ERC1155Burnable
{
    mapping(uint256 => uint256) private _totalSupply;

    struct CabinetItem {
        uint256 price;
        uint256 amountMinted;
        uint256 amountAllowed;
        uint256 maxMintPerAddress;
        uint256 mainCollectionQty;
    }
    mapping(uint256 => CabinetItem) public items;

    /// @notice How many items someone can mint
    uint256 public maxMintEachAddress = 2;
    mapping(address => uint) public hasMinted;

    string private cabinetUri = "https://storage.hashku.com/api/soth/cabinet/{id}.json";

    uint256 constant private DUST = 0;
    uint256 constant private SCOPE = 1;
    uint256 constant private BOOK = 2;
    uint256 constant private BOT = 3;
    uint256 constant private POSTER = 4;
    uint256 constant private BOOK_CLOSED = 5;
    uint256 constant private BOT_ACTIVE = 6;

    uint256 public currentRaffleIndex = 11;

    mapping(uint256 => bool) public nigelWinners;

    constructor() ERC1155("https://storage.hashku.com/soth/cabinet/{id}.json") {
        // forget me dust
        items[DUST] = CabinetItem(60000000000000000, 0, 222, 2, 2);

        // pocket spectroscope
        items[SCOPE] = CabinetItem(120000000000000000, 0, 166, 2, 4);

        // book of epochs
        items[BOOK] = CabinetItem(170000000000000000, 0, 99, 2, 4);

        // autotranslator bot
        items[BOT] = CabinetItem(170000000000000000, 0, 99, 2, 4);

        // wanted poster of nigel
        items[POSTER] = CabinetItem(180000000000000000, 0, 99, 2, 4);

        // opened book of epochs
        items[BOOK_CLOSED] = CabinetItem(0, 0, 99, 2, 0);

        // activated autotranslator bot
        items[BOT_ACTIVE] = CabinetItem(0, 0, 99, 2, 0);

        // Raffle tickets will be IDs 11-99
    }

    /*
    * @notice Total supply of a given item
    */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }

    /*
    * @notice Set overall quanitity a user is allowed to mint
    */
    function setMaxMintEachAddress(uint256 _amt) public onlyOwner {
        maxMintEachAddress = _amt;
    }

    /*
    * @notice Set a Nigel raffle ticket as a winner
    */
    function setNigelWinner(uint256 _id) public onlyOwner {
        nigelWinners[_id] = true;
    }

    /*
    * @notice Allow updating the item data
    */
    function setItem( uint256 _id, uint256 _price, uint256 _amountAllowed, uint256 _maxMintPerAddress, uint256 _mainCollectionQty ) public onlyOwner {
        items[_id].price = _price;
        items[_id].amountAllowed = _amountAllowed;
        items[_id].maxMintPerAddress = _maxMintPerAddress;
        items[_id].mainCollectionQty = _mainCollectionQty;
    }

    function uri(uint256) public view override returns (string memory) {
        return cabinetUri;
    }
    
    function setURI(string memory _newuri) public onlyOwner {
        cabinetUri = _newuri;
    }

    /*
    * @notice Shop for a single item of varyiable quantity
    */
    function shop( uint256 _id, uint256 _qty, bytes memory _signature ) public payable {
        // check signature - will be provided by Hashku
        require(verifySignature("SHOP", group, _id, _qty, _signature), "invsig");
        require(_id < 5, "invitm");
        require(_qty * items[_id].price == msg.value, "incfnds");

        mintInternal(msg.sender, _id, _qty);
    }

    /*
    * @notice Shop for more than a single item
    */
    function shopMultiple( uint256[] memory _ids, uint256[] memory _qtys, bytes memory _signature ) public payable {
        // check signature - will be provided by Hashku
        require(verifySignature("SHOP", group, _ids[0], _qtys[0], _signature), "invsig");
        require(_ids.length == _qtys.length, "idqtymm");
        require(_ids.length < 6, "maxitms");

        uint256 _totalPrice;
        for (uint256 _i = 0; _i < _ids.length; _i++) {
            require(_ids[_i] < 5, "invitm");
            _totalPrice += items[_ids[_i]].price * _qtys[_i];
        }

        require(_totalPrice == msg.value, "incfnds");

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            mintInternal(msg.sender, _ids[_i], _qtys[_i]);
        }
    }

    /*
    * @notice Mint an item, used by other functions only
    */
    function mintInternal(address _to, uint256 _id, uint256 _qty) internal {
        require(hasMinted[_to] + _qty <= maxMintEachAddress, "mintmax");
        require(items[_id].amountMinted + _qty <= items[_id].amountAllowed, "itmunv");
        require(_qty + balanceOf(_to, _id) <= items[_id].maxMintPerAddress, "itmmax");

        hasMinted[_to] += _qty;
        items[_id].amountMinted += _qty;
        _mint(_to, _id, _qty, "");
    }

    /*
    * @notice Send tokens to an address (to be used for rewarding community members and partners)
    */
    function send(address _to, uint256[] memory _ids, uint256[] memory _qtys) public onlyOwner {
        require(_ids.length == _qtys.length, "idqtymm");
        require(_ids.length < 6, "maxitms");

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            require(_ids[_i] < 5, "invitm");
        }

        for (uint256 _i = 0; _i < _ids.length; _i++) {
            mintInternal(_to, _ids[_i], _qtys[_i]);
        }
    }

    /*
    * @notice Mint BOOK_CLOSED or BOT_ACTIVE from redemption contract
    */
    function mintExternal(address _to, uint256 _id, uint256 _qty) external onlyExternalAccount {
        require(_id > 4, "invitm");
        require(_id < 7, "invitm");
        items[_id].amountMinted += _qty;
        _mint(_to, _id, _qty, "");
    }

    /*
    * @notice Mint Nigel raffle ticket (IDs 11+)
    */
    function mintNigelRaffle(address _to, uint256 _qty) external onlyExternalAccount {
        for (uint256 _i = 0; _i < _qty; _i++) {
            _mint(_to, currentRaffleIndex, 1, "");
            currentRaffleIndex += 1;
        }
    }

    /*
    * @notice Burn token from redemption account
    */
    function burnExternal(address _to, uint256 _id, uint256 _qty) external onlyExternalAccount {
        _burn(_to, _id, _qty);
    }

    /*
    * @notice Shortcut for retrieving number of main collection NFTs are redemeed from a Cabinet item
    */
    function itemMainCollectionQuantity(uint256 _id) public view returns (uint256) {
        return items[_id].mainCollectionQty;
    }

    function burn(
        address _account,
        uint256 _id,
        uint256 _value
    ) override public virtual onlyOwner {}

    function burnBatch(
        address _account,
        uint256[] memory _ids,
        uint256[] memory _values
    ) override public virtual onlyOwner {}
}


// Dependency file: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// Root file: contracts/SocietyOfTheHourglass.sol

pragma solidity 0.8.9;

/*
*
* Society of the Hourglass: Main Collection + Cabinet of Curiosities Redemption
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Website: https://www.societyofthehourglass.com/
* Mint Page: https://app.hashku.com/team/society-of-the-hourglass/main/mint
*
*/

// import "contracts/Hashku.sol";
// import "contracts/CabinetOfCuriosities.sol";
// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

contract SocietyOfTheHourglass is Hashku, ERC721Holder {
    using Strings for uint256;

    // total main collection tokens based on 2022-01-01 cabinet items; will decrease as cabinet items are redeemed
    uint256 public reservedFromCabinet = 642;

    // mapping of which tokens have a bot
    mapping(uint256 => bool) public hasBot;

    // mappig of which tokens are in the book
    mapping(uint256 => bool) public inBook;

    // track which nigel token will mint next
    uint256 public nextNigelIndex;

    // how many nigels total
    uint256 constant private nigelsAvailable = 10;

    constructor() Hashku(
        "Society of the Hourglass", 
        "SOTH", 
        "https://storage.hashku.com/api/soth/main/", 
        "SOTH", 
        8888, 
        20, 
        30, 
        70000000000000000, 
        5, 
        0xED0998a1489Ab5cF1900f546f620aB67Af19915B
    ) {
        // on deploy, mint the first 10 tokens to the contract
        // these first ten tokens are nigels
        for (uint256 i = 0; i < nigelsAvailable; i++) {
            mint(address(this));
        }
    }

    // set however many tokens should be reserved for cabinet redemption
    function setReservedFromCabinet(uint256 _amt) public onlyOwner {
        require(nextToken() + _amt <= maxTokens, "too_many");
        reservedFromCabinet = _amt;
    }

    // owner can ONLY decrease the total number of available tokens
    function decreaseMaxTokens(uint256 _amount) external override onlyOwner {
        require(_amount < maxTokens, "only_decrease");
        require(_amount > reservedFromCabinet + nextToken(), "cabinet_reserved");
        maxTokens = _amount;
    }

    // internal function for transferring a nigel
    function transferNigel(address _to) internal {
        // nigels will be 0-9, nigelsAvailable will be 10
        require(nextNigelIndex + 1 < nigelsAvailable, "none_available");
        uint256 nigelIdToClaim = nextNigelIndex;
        nextNigelIndex += 1;
        _safeTransfer(address(this), _to, nigelIdToClaim, "");
        delete nigelIdToClaim;
    }

    // internal function for setting bot on a token
    function setHasBot(uint256 _tokenId) internal {
        require(!hasBot[_tokenId], "already_has_bot");
        hasBot[_tokenId] = true;
    }

    // internal function for marking a token in the book
    function setIsInBook(uint256 _tokenId) internal {
        require(!inBook[_tokenId], "already_has_bot");
        inBook[_tokenId] = true;
    }

    // once final tokens are set and we know all tokens to be in book, will call this to update the contract
    function setIsInBookMultiple(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            setIsInBook(_tokenIds[i]);
        }
    }

    // returns uri with data for book and bot where appropriate
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "no_token");

        string memory append = ".json?var=1";
        string memory addBot = "";
        if (hasBot[_tokenId]) {
            addBot = "&bot=yes";
        }
        string memory addBook = "";
        if (inBook[_tokenId]) {
            addBook = "&book=yes";
        }

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString(), append, addBot, addBook)) : "";
    }

    // buy NFTs - version without signature required for public mint
    function shop(uint256 _amount) external override payable {
        require(nextToken() + _amount + reservedFromCabinet <= maxTokens, "sold_out");
        require(_amount <= maxMintPerTransaction, "max_mintable");
        require(!isClosed, "is_closed");
        require(isPublic, "not_public");
        require(price * _amount == msg.value, "incorrect_funds");
        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    // buy NFTs - signature required from Hashku for presale
    function shop(uint256 _amount, bytes memory _signature) external override payable {
        require(nextToken() + _amount + reservedFromCabinet <= maxTokens, "sold_out");
        require(tokensMinted[_msgSender()] + _amount <= maxMintPerAddress, "max_minted");
        require(!isClosed, "is_closed");
        require(verifySignature(_signature), "invalid_signature");
        require(price * _amount == msg.value, "incorrect_funds");

        tokensMinted[_msgSender()] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    // owner sends NFTs to addresses
    function send(address[] calldata _addresses, uint256[] calldata _amounts) external override onlyOwner {
        require(_addresses.length == _amounts.length, "amount_mismatch");

        uint256 total;
        for (uint256 t = 0; t < _amounts.length; t++) {
            total += _amounts[t];
        }

        require(nextToken() + total + reservedFromCabinet <= maxTokens, "sold_out");

        delete total;

        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 a = 0; a < _amounts[i]; a++) {
                mint(_addresses[i]);
            }
        }
    }

    // cabinet collection address
    CabinetOfCuriosities public externalAccount;

    // redemption of initial cabinet items allowed when true
    bool public redemptionOpen;

    // redemption of secondary cabinet items allowed when true
    bool public secondRedemptionOpen;

    modifier cabinetMustBeSet() {
        require(address(externalAccount) != address(0), "no_cabinet");
        _;
    }

    // open or close initial cabinet item redemption
    function setRedemptionOpen(bool _open) public onlyOwner {
        redemptionOpen = _open;
    }

    // open or close secondary cabinet item redemption
    function setSecondRedemptionOpen(bool _open) public onlyOwner {
        secondRedemptionOpen = _open;
    }

    // set the cabinet account
    function setExternalAccount(address _contract) public onlyOwner {
        externalAccount = CabinetOfCuriosities(_contract);
    }

    // external function to mint Nigel raffle tickets in case we have external awards or later uses for raffle tickets
    function mintNigelRaffle(address _to, uint256 _qty) external onlyOwner cabinetMustBeSet {
        externalAccount.mintNigelRaffle(_to, _qty);
    }

    // redeem a winning nigel raffle ticket from the cabinet
    function useNigelTicket(uint256 _id) public cabinetMustBeSet {
        require(secondRedemptionOpen, "not_open");
        require(externalAccount.nigelWinners(_id), "not_winner");
        require(externalAccount.balanceOf(msg.sender, _id) >= 1, "not_enough");

        // burn nigel ticket
        externalAccount.burnExternal(msg.sender, _id, 1);

        // mint a nigel from the main collection
        transferNigel(msg.sender);
    }

    // check that the msg sender is the owner of an array of tokens
    function validateOwner(uint[] calldata _tokenIds) internal view returns (bool) {
        for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
            // does the user own the tokenIds
            require(ownerOf(_tokenIds[_i]) == msg.sender, "not_owner");
        }

        return true;
    }

    // assign bots to main collection tokens
    function useBot(uint[] calldata _tokenIds) public cabinetMustBeSet {
        require(secondRedemptionOpen, "not_open");
        require(externalAccount.balanceOf(msg.sender, 6) >= _tokenIds.length, "no_item");
        validateOwner(_tokenIds);

        externalAccount.burnExternal(msg.sender, 6, _tokenIds.length);

        for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
            setHasBot(_tokenIds[_i]);
        }
    }

    // assign books to main collection tokens
    function useBook(uint[] calldata _tokenIds) public cabinetMustBeSet {
        require(secondRedemptionOpen, "not_open");
        require(externalAccount.balanceOf(msg.sender, 5) >= _tokenIds.length, "no_item");
        validateOwner(_tokenIds);

        externalAccount.burnExternal(msg.sender, 5, _tokenIds.length);

        for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
            setIsInBook(_tokenIds[_i]);
        }
    }

    // redeem items from the cabinet of curiosities
    function redeem(uint[] calldata _itemIds, uint[] calldata _itemQtys) public cabinetMustBeSet {
        require(redemptionOpen, "not_open");
        require(_itemIds.length > 0, "no_items");
        require(_itemIds.length == _itemQtys.length, "length_mismatch");
        require(_itemIds.length < 6, "invalid_items");

        for (uint256 _i = 0; _i < _itemIds.length; _i++) {
            require(_itemQtys[_i] > 0, "quantity_zero");
            // does the user own enough tokenIds
            require(externalAccount.balanceOf(msg.sender, _itemIds[_i]) >= _itemQtys[_i], "no_item");
            require(_itemIds[_i] < 5, "invalid_item");
        }

        uint256 _qtyMintMain;
        for (uint256 _i = 0; _i < _itemIds.length; _i++) {
            // burn the number of tokens by id
            externalAccount.burnExternal(msg.sender, _itemIds[_i], _itemQtys[_i]);

            // each token gets at least 1 from main collection
            _qtyMintMain += externalAccount.itemMainCollectionQuantity(_itemIds[_i]) * _itemQtys[_i];

            // book, bot, and poster get an additional item minted
            if (_itemIds[_i] == 2) {
                externalAccount.mintExternal(msg.sender, 5, _itemQtys[_i]);
            } else if (_itemIds[_i] == 3) {
                externalAccount.mintExternal(msg.sender, 6, _itemQtys[_i]);
            } else if (_itemIds[_i] == 4) {
                externalAccount.mintNigelRaffle(msg.sender, _itemQtys[_i]);
            }
        }

        reservedFromCabinet -= _qtyMintMain;

        // finally mint all the correct qty
        for (uint256 i = 0; i < _qtyMintMain; i++) {
            mint(msg.sender);
        }
    }
}