/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

/**************************************
╦╔╦╗╔╦╗╔═╗╦═╗╔╦╗╔═╗╦    ╔╦╗╔═╗╔╗╔╦╔═╔═╗
║║║║║║║║ ║╠╦╝ ║ ╠═╣║    ║║║║ ║║║║╠╩╗╚═╗
╩╩ ╩╩ ╩╚═╝╩╚═ ╩ ╩ ╩╩═╝  ╩ ╩╚═╝╝╚╝╩ ╩╚═╝
**************************************/

// Powered by NFT Artisans (nftartisans.io) - [email protected]
// Sources flattened with hardhat v2.7.1 https://hardhat.org
// SPDX-License-Identifier: MIT


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// File contracts/ImmortalMonks.sol

pragma solidity ^0.8.4;


contract ImmortalMonks is ERC721Enumerable, Ownable {

    // project settings
    uint256 public ethPrice = 250000000000000000; // 0.25 ETH
    uint256 public ethPricePresale = 220000000000000000; // 0.22 ETH

    bool public isActive = false;
    bool public isActivePresale = false;
    bool public hasReserved = false;
    uint8 public maxReserved = 50;
    uint8 public maxSell = 2;
    uint8 public maxSellPresale = 2;
    uint16 public maxSupply = 2500;
    uint16 public maxSupplyPresale = 1554;

    // withdraw addresses
    address private _t1; // 90%
    address private _t2; // 5%
    address private _t3; // 5%

    // presale whitelist
    mapping (address => bool) private _presaleWhitelist;

    string private _baseURIPath;

    event Reserved();

    constructor(address t1_, address t2_, address t3_) ERC721("ImmortalMonks", "MONKS") {
        _t1 = t1_;
        _t2 = t2_;
        _t3 = t3_;

        _setupPresaleWhitelist();
    }

    // Add a single address to the presale whitelist
    function addWhitelistAddress(address whitelistAddress) external onlyOwner {
        _presaleWhitelist[whitelistAddress] = true;
    }

    // Add addresses in bulk to the presale whitelist
    function addWhitelistBulk(address[] memory addresses) external onlyOwner {
        for(uint i; i < addresses.length; i++) {
            _presaleWhitelist[addresses[i]] = true;
        }
    }

    // Mint tokens
    function mintTokens(uint numberOfTokens) external payable {
        require(isActive, "Sale is not active");
        require(numberOfTokens <= maxSell, "Exceeds max number of Tokens in one transaction");
        require(totalSupply() + numberOfTokens <= maxSupply, "Purchase would exceed max supply");
        require(ethPrice * numberOfTokens == msg.value, "Ether value sent is not correct");

        uint mintIndex;
        for (uint i; i < numberOfTokens; i++) {
            mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    // Mint tokens during pre-sale, must be on whitelist
    function mintTokensPresale(uint numberOfTokens) external payable {
        require(isActivePresale, "Presale is not active");
        require(_presaleWhitelist[msg.sender] == true, "Address is not whitelisted");
        require(balanceOf(msg.sender) + numberOfTokens <= maxSellPresale, "Exceeds max number of presale Tokens for address");
        require(totalSupply() + numberOfTokens <= maxSupplyPresale, "Purchase would exceed max presale supply");
        require(ethPricePresale * numberOfTokens == msg.value, "Ether value sent is not correct");

        uint mintIndex;
        for (uint i; i < numberOfTokens; i++) {
            mintIndex = totalSupply();
            if (totalSupply() < maxSupply) {
                _safeMint(_msgSender(), mintIndex);
            }
        }
    }

    // Remove a single address to the presale whitelist
    function removeWhitelistAddress(address whitelistAddress) external onlyOwner {
        _presaleWhitelist[whitelistAddress] = false;
    }

    // Reserve tokens for promotions
    function reserveTokens() external onlyOwner onReserve {
        uint supply = totalSupply();
        for (uint i; i < maxReserved; i++) {
            _safeMint(_msgSender(), supply + i);
        }
    }

    // Sets the base URI for the metadata
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIPath = baseURI;
    }

    // Just in case we have to change the max sell after deployment
    function setMaxSell(uint8 amount) external onlyOwner {
        maxSell = amount;
    }

    // Just in case we have to change the max sell for presales after deployment
    function setMaxSellPresale(uint8 amount) external onlyOwner {
        maxSellPresale = amount;
    }

    // Just in we have to change the address after deployment
    function setT1(address t1_) external onlyOwner {
        _t1 = t1_;
    }

    // Just in we have to change the address after deployment
    function setT2(address t2_) external onlyOwner {
        _t2 = t2_;
    }

    // Just in we have to change the address after deployment
    function setT3(address t3_) external onlyOwner {
        _t3 = t3_;
    }

    // Turn presale mode on/off
    function togglePreSaleState() external onlyOwner {
        isActivePresale = !isActivePresale;
    }

    // Turn live sale mode on/off
    function toggleSaleState() external onlyOwner {
        isActive = !isActive;
    }

    // Withdraw ETH from contract 90% to founders, 10% to dev
    function withdraw() external onlyOwner {
        uint256 _share = address(this).balance / 20;
        Address.sendValue(payable(_t1), _share * 18);
        Address.sendValue(payable(_t2), _share);
        Address.sendValue(payable(_t3), _share);
    }

    // Override the default baseURI path
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPath;
    }

    // Include presale whitelist during deployment to save on gas costs
    function _setupPresaleWhitelist() internal {
        _presaleWhitelist[0x718D3cFB318f1dCCc55Fd63208d94830F9F1f97B] = true;
        _presaleWhitelist[0x0E3477186f120a185B79a21cc16cfC88651E8e9E] = true;
        _presaleWhitelist[0x8257aD6E227F4c0409C8a33E8ef546D41B9C9101] = true;
        _presaleWhitelist[0x4333273f2C7596D0bcD0caa00c1F734462C17778] = true;
        _presaleWhitelist[0xd15AfBCE982d2B7611668E4539B7fe30E8bAB1E6] = true;
        _presaleWhitelist[0xF241d82e31d54fa4f6c286eFa69c83BB9F0cbd5E] = true;
        _presaleWhitelist[0x19777288ec02D4d1D2C18B0369eE98A7512FE54A] = true;
        _presaleWhitelist[0xE0DA98D99eD92876c59b0DE3f0c36D405D421178] = true;
        _presaleWhitelist[0x8BC2744a7889C52F3d33D335Bb52E6F4830a988A] = true;
        _presaleWhitelist[0xeC2Ca6d3C3687EbD6E71C6A4a3dDf642Dbb8F453] = true;
        _presaleWhitelist[0xa17095432e6edA759ED9224037FeDA656a0E0256] = true;
        _presaleWhitelist[0x382bd2414d474137dd9Ee5d242c373E2675378ca] = true;
        _presaleWhitelist[0x0A6495c50196e8d728FC1610097A88f1D21FE923] = true;
        _presaleWhitelist[0x8158C89cC0Cd679c9035113e608f841d11BCd602] = true;
        _presaleWhitelist[0xBa2aeEdCA9eC9B9fD36d66723b5bBF41a2E31797] = true;
        _presaleWhitelist[0x87dbf13c9D6ffe57ffaEeBDfe4442993A5E5B619] = true;
        _presaleWhitelist[0x7c74dA0e22de8A7a8f8F04b1b11935c231FFd246] = true;
        _presaleWhitelist[0xB16c964095e7A59688f3f8471387D735b0F15584] = true;
        _presaleWhitelist[0xf81ca0c17423Ef1E918DaEE6035EEabb99401a89] = true;
        _presaleWhitelist[0x33e1DdE8Cc60E926fBf9605316ad23B1F2cde010] = true;
        _presaleWhitelist[0x1C85e528c06b06f49B3B3e6c5B10c160b84CC38e] = true;
        _presaleWhitelist[0x0CC5CB75c6759fF352D68577a628cBa98c4D20D0] = true;
        _presaleWhitelist[0xc2f4d768320eB6BedeF4fDf5DEe69b11E1A8F897] = true;
        _presaleWhitelist[0xDc53E34Ec757f7D3fb497cda91d0335c83ddAfb6] = true;
        _presaleWhitelist[0x853d89487352aa249E0580F8f82BeEa2E20b33b7] = true;
        _presaleWhitelist[0xCF7B02B17f4e9fBfFe122Afb10086Bf3CD5bae52] = true;
        _presaleWhitelist[0x996Aa4234081941cAb097D9b51cBD4197Aa87B4e] = true;
        _presaleWhitelist[0xcfb83F44646d02eBeb4639c87855a4280c1FC9bE] = true;
        _presaleWhitelist[0xcaA3A3573c42d587eBAa2E01b392507c70BfF2eE] = true;
        _presaleWhitelist[0x7265f2569E700Fccd5181263DFb5b94a3d449cc4] = true;
        _presaleWhitelist[0x597c12bb2D98e1b1Deb2775b55E23D984E9d8A75] = true;
        _presaleWhitelist[0x83B8e2EdA472A56De448C0964447Ca26a50DceD2] = true;
        _presaleWhitelist[0x131bB2F1bdaBCb08d37F33d5F40cd080aa3Ad5a8] = true;
        _presaleWhitelist[0xd3BaaaB871570C1f6C68eE027F2c7a9124f9DBbA] = true;
        _presaleWhitelist[0xC999E869B0C0ce72A705d5078B33155E67ceEc7F] = true;
        _presaleWhitelist[0x255510F0f3Ab227ee1a372738eaBFf50E52D0Af7] = true;
        _presaleWhitelist[0x81343aAc89e762cDE6Af45DfF78204811DFBE3FC] = true;
        _presaleWhitelist[0x26cC8a52748Ce934226599F52Ca7b03F90151CA1] = true;
        _presaleWhitelist[0xEff13d78Ec1093fe52Ec816ad8a9b1a08619EB46] = true;
        _presaleWhitelist[0xb6B2D07b830395A70BDAA5a67f5CFf5ed9C8BE0d] = true;
        _presaleWhitelist[0x002cfCe7088B9711D1df63E48EBc99C3c1b03C3D] = true;
        _presaleWhitelist[0xbf338Bdffc3142Aa2298b3343D6B11718e29B40b] = true;
        _presaleWhitelist[0xa6476d6655b0854eCE5909C0cb9240C304314464] = true;
        _presaleWhitelist[0xf89237d7465985ceA2f9036BF61637A27Bd899f7] = true;
        _presaleWhitelist[0x5DE02c8924922b756a79a9E69a7B2E644f0c4a3a] = true;
        _presaleWhitelist[0xF0d327f6be6123AD03C89A97C16753dd3635Ff14] = true;
        _presaleWhitelist[0x39D21b8B349328aCeD3EbBa434667f8aBb47c773] = true;
        _presaleWhitelist[0x81FE6EfeB62528b943eCF2dA47C55b48D218eA6b] = true;
        _presaleWhitelist[0x4C0269BB380aBc30345D19e7b03FDb98a0442891] = true;
        _presaleWhitelist[0x0C66665ABb84246F759576D5C2Bfd30e89416004] = true;
        _presaleWhitelist[0x6168b8fb98c5A8E5b9C7A7647673Bc3b4db708f0] = true;
        _presaleWhitelist[0xc9F737034D796cbc3a45744e83dB7b33c3ac9bef] = true;
        _presaleWhitelist[0xE3fC951776e7E607521cE0dCf46fB13FC8eCf582] = true;
        _presaleWhitelist[0x98c2EC93931C32AA1Bb6aFC6128d65B5706B26B8] = true;
        _presaleWhitelist[0x4d63edB5ac1B077Bb0bF48777D2eBb36b56F2577] = true;
        _presaleWhitelist[0x1F2e63669C55DFEC4cE1Fb94eC449080a7102298] = true;
        _presaleWhitelist[0x5821A1b92940A25A123852946DE51b600E69E34F] = true;
        _presaleWhitelist[0x429a7409499aE86dF47F5304E205cA35B8c49320] = true;
        _presaleWhitelist[0xBba16ffA7AB34837022c11f4435d9D6E90990b14] = true;
        _presaleWhitelist[0xED8F2fcef40f1f78B34c70eC00ffaf927fEBD077] = true;
        _presaleWhitelist[0x5f8955f2BaF74310cc140775E7DAFFa05921076A] = true;
        _presaleWhitelist[0xA82FbAEbCe44e7642C4E376C8e77425ae5b6634D] = true;
        _presaleWhitelist[0xa2c78F4802e83b47b634b5Dcbc2cC4CDd5B71D56] = true;
        _presaleWhitelist[0x0d55c4F3CCcd145b42753eDc89b6dc98b69a088C] = true;
        _presaleWhitelist[0xADe1BabbFA178812F85d3Be9Bb4EFaA92B77AbBc] = true;
        _presaleWhitelist[0xfbF546040Ee71dcC5FE30c046976592eb20B1325] = true;
        _presaleWhitelist[0xf3923bEC7cD34e05494e77F7Ed6c82e2daEd11C7] = true;
        _presaleWhitelist[0xe7cb8F61A3F4a833347FDAa59255f26916516045] = true;
        _presaleWhitelist[0xb77049081E26846A8f5D43Eb810898a5574Bdb9C] = true;
        _presaleWhitelist[0x7A91ee9A535bEd9Ba1bB3722C54D7918018Fa8Ab] = true;
        _presaleWhitelist[0x5a12f6F6b7fb16bfB9Eb0c14F7cbA531465d2998] = true;
        _presaleWhitelist[0x6c74955B3Af33EC42b00676A0dD0F2962fcF258c] = true;
        _presaleWhitelist[0x680119ee5A4983b15932c0a2785ec727Cc3ccDA2] = true;
        _presaleWhitelist[0x2c652d6A2fA74709Ca925c2c53c3a85fe6556e18] = true;
        _presaleWhitelist[0x42BA75BC5259DC25dD89bA6D3F14E01134880308] = true;
        _presaleWhitelist[0x53768Af818be06f9ef58B78f2Fcad795Ad433F1D] = true;
        _presaleWhitelist[0x77F0a25935bf47c5ce771Ad0f0AA2AB8f07fe104] = true;
        _presaleWhitelist[0xe135C4b13a26b52954df2F8813a363617C57Efa4] = true;
        _presaleWhitelist[0x533D5B4A84795Ec5edA37f73b198e6e77495dE59] = true;
        _presaleWhitelist[0xB02519588F3982b6A3EB5bcb2692C3eb379F2048] = true;
        _presaleWhitelist[0xAA7225Fc586D2B9041Fa1AD906C91e4909805865] = true;
        _presaleWhitelist[0x2D9db0402A3F26fe13751427541bF701131aa6AC] = true;
        _presaleWhitelist[0x738726AC023b3f559D822Ef13E4f91b8AF18EB39] = true;
        _presaleWhitelist[0x41457FD8F460768C0AbE1E236A265AE0A9C41091] = true;
        _presaleWhitelist[0xe14945a03194Cb58F72eb04809f99dD829f27AE1] = true;
        _presaleWhitelist[0xC91f408C580E2bC75b281Dfc452E1763a905ccA2] = true;
        _presaleWhitelist[0xBA534dd699A6908d6ED1D114b03e43554ACf7b96] = true;
        _presaleWhitelist[0x85b0F9498ed437f412C58dfE017d64fFc2694e6d] = true;
        _presaleWhitelist[0x477DfA5966fD4dDc3f3675862f19b071DA021ed6] = true;
        _presaleWhitelist[0xb045458c8bc244D67dc40f07e2c75A22dc403F4b] = true;
        _presaleWhitelist[0xD8DC72De813AbE60096dfEC14c05AC2cd3D4B801] = true;
        _presaleWhitelist[0x2A5CD5Fd05bFA8b4AdFD4e1315F37753D71a5c69] = true;
        _presaleWhitelist[0x80b3A22a4be1a582580b34B7E600D2cb3aa28452] = true;
        _presaleWhitelist[0xce7395C9C048065088D230E78C6d32c4D53e2b36] = true;
        _presaleWhitelist[0x8402818700bEb9E92947c632b8a214B56Ed5a6d9] = true;
        _presaleWhitelist[0x86F93A1C78277B55Ca1dF92f272B74485B208C98] = true;
        _presaleWhitelist[0xf4Ac8Fe9AD731d111B2318b8233b1c4fCEE272b5] = true;
        _presaleWhitelist[0x35d1dDF0Eb6d265052Da00D5E6ADee446fF9dCE7] = true;
        _presaleWhitelist[0xF1C584aa328408185a6670C1949975E8436cD95a] = true;
        _presaleWhitelist[0xcAbe239E2B998f9F1747C83895a48Cc99a7746b7] = true;
        _presaleWhitelist[0x7c31925b73FDC165faB89396E54084dDADFCab39] = true;
        _presaleWhitelist[0xD8A510a5eC59fDb52F0C6c052Af6E669c4577852] = true;
        _presaleWhitelist[0x069cA681Fb96d10c7F25e56B9902d255a576b61f] = true;
        _presaleWhitelist[0xf65d5dC340545EB426DA011F219B2Cf517904c9E] = true;
        _presaleWhitelist[0x090a89b6ef2265eCDEe6266F34c4571fB1bF9138] = true;
        _presaleWhitelist[0x30f97245663B7a31EC3FDb23C3b368B4941AfaF4] = true;
        _presaleWhitelist[0xe6dA1D19FdCEc179bA9755F2C6139f8FFEcbfeB0] = true;
        _presaleWhitelist[0x17917ba68adF72977023Fb97f133Bf8B96424998] = true;
        _presaleWhitelist[0xB21f8EB437065542E75fb71a52a573DF0E9097ba] = true;
        _presaleWhitelist[0xa6578b79A27aCF29f3C20da21Eef9b75226812C9] = true;
        _presaleWhitelist[0x4E68Fb65f76bE2C5afe9AE50afB953843BdcbFd0] = true;
        _presaleWhitelist[0xF7827701D4C1E5AE6B7741328Df34A43F7e5eDF2] = true;
        _presaleWhitelist[0xe9A506466024C8b4b27B0e675DF78d86F98cF0E2] = true;
        _presaleWhitelist[0xfbA934f80bEd2c974B0Bb8d946b8d270F774a4b6] = true;
        _presaleWhitelist[0xe0A051886A77f47150b2378333C7d58F20225b78] = true;
        _presaleWhitelist[0xFf1B4990136303f3772799091e52Cbdfb9ab8E4D] = true;
        _presaleWhitelist[0x1d4604430e54f5E07846320d8B189be1572047cB] = true;
        _presaleWhitelist[0x1ADca51D058569BfCcD0F5C5fb2Dc351307b3FF3] = true;
        _presaleWhitelist[0x103b8FbdF3284CbF5B202624493E66a336511c39] = true;
        _presaleWhitelist[0x341325d6E5B929e646C5080Dc4Ee2b27C684d59B] = true;
        _presaleWhitelist[0xFF29a3FDFEC02c288308198Eb3990479f7135cD0] = true;
        _presaleWhitelist[0xEa01645ec3501A553c2E9E04d5Ae8d247aF7b058] = true;
        _presaleWhitelist[0x4Ab8D60880B80AF2580aE1B0CfDe949f98586FF5] = true;
        _presaleWhitelist[0x475a289877cbcdB92E4768309827FD238BB3fc0f] = true;
        _presaleWhitelist[0x273D81611981363e916Fb7B458833b45125383aD] = true;
        _presaleWhitelist[0x667D260E1ADEafF17e548C0ab8C0aC49c6222333] = true;
        _presaleWhitelist[0xCD390Eb31886bF06ec5C94ca0cDeb8C56bA128d1] = true;
        _presaleWhitelist[0xB3BbD2e85bE786B59cfc4EB787EcFa8728a7e49b] = true;
        _presaleWhitelist[0x8308A17925da4023309De6Bd4460654eDB7DD480] = true;
        _presaleWhitelist[0x7E3201d358edB91925d8e6e7F4415Cb7c50686df] = true;
        _presaleWhitelist[0x0Be57780ba56c29601E26549AAEd584E5ACc78A0] = true;
        _presaleWhitelist[0x12C0d019683770883A35C3598B6F993a691Be15C] = true;
        _presaleWhitelist[0x75539c237B1D2154B3Ec7a4433ACD8dF6f4aaB29] = true;
        _presaleWhitelist[0xD14D8D43949b7BF9862d591dD81640682b290167] = true;
        _presaleWhitelist[0xFd2c6F0Baca2E3319FD3fEbab4d726c46803B79e] = true;
        _presaleWhitelist[0xC2239Bc0e6a001437Aa9207a7717bA7A0cD65B5a] = true;
        _presaleWhitelist[0xbbd5D9BFec105378043E9Ce54DE6650194De50e1] = true;
        _presaleWhitelist[0x20c9f7140794B0578fE569E99e14a3710e91D9b7] = true;
        _presaleWhitelist[0x444D371eBc8dEAC789D9c001f9744B02c9d70e68] = true;
        _presaleWhitelist[0x487B54bBEcbCe2C0222B49c3bE292642855D5Bf3] = true;
        _presaleWhitelist[0xDFB6f86A41c87020bC19A0FAA790F6B8fDEb560b] = true;
        _presaleWhitelist[0x6Bd819c0AE4Ef0Bc7579d49E06E6f10F745D813d] = true;
        _presaleWhitelist[0xDBa1C8cc0Bf243d80B265A4127384E40A0901aAB] = true;
        _presaleWhitelist[0x0bf03623783FCc3e0a5110e7Dd881Cdba7213e46] = true;
        _presaleWhitelist[0x40AE3c21738fDCE23E4Adec87372935A375370b6] = true;
        _presaleWhitelist[0x2eA84c5bcDe9fE6e4cB76C25dEE2F1664CfBAB1B] = true;
        _presaleWhitelist[0x4C6382c22F1622bc41B634C5d3ba5a266E1332Bc] = true;
        _presaleWhitelist[0xBA78031376a6264B6452145b19461065BfbE8876] = true;
        _presaleWhitelist[0xEE3dEa4E526784eAD93fD50bC63e11e1be5934B7] = true;
        _presaleWhitelist[0x674860E9F965c4D22a48eE0F57587DE319637e46] = true;
        _presaleWhitelist[0xEE80F8B2A1b089053f83040C474EDBce19085246] = true;
        _presaleWhitelist[0xaf22998910cC0D6c50d4234CCC5e17a96ada4F2B] = true;
        _presaleWhitelist[0x3601a2B2f085Fa489599bd5fC2bbcB39581f2122] = true;
        _presaleWhitelist[0xE48c1010b538932D2F65F14811C05945A4aa193F] = true;
        _presaleWhitelist[0xcdbae7B74c7A9399372576c7ffC495d3124623D2] = true;
        _presaleWhitelist[0x330AA0a042347313B68Be4CB629323488CF19D20] = true;
        _presaleWhitelist[0x92f5bF5c0808182D37DbcF4E0B81AC5BA79fa972] = true;
        _presaleWhitelist[0x6F2971734927D9731ED19c964e11C7730a30C9cf] = true;
        _presaleWhitelist[0xcEF36627931fC1C16e39Fb42308c3245a18dC597] = true;
        _presaleWhitelist[0xC3d080A08c2fc57a5248DC9865DB775eD492Ec6c] = true;
        _presaleWhitelist[0x4F25A32bF24990D43374539c82C70AcdEe0DC924] = true;
        _presaleWhitelist[0xC2c753418f3c06cE2fb071DDC41CEC1Bc392cD7C] = true;
        _presaleWhitelist[0x8f7DBc40AD189023DfB9669dA81c183bC39799eb] = true;
        _presaleWhitelist[0x8bC065E0Cf4a63c3AcBB446C9884413ea3BAFb22] = true;
        _presaleWhitelist[0x17c44CC31C205a47C7A02De56422b817269fD115] = true;
        _presaleWhitelist[0x8F1DD05e4Ce1D175ae5e84c6AD0E73B590ba23F9] = true;
        _presaleWhitelist[0xb5aF7e70f0B307D07D6546eb046a0790E305BB56] = true;
        _presaleWhitelist[0xeA9fc77F8Fbb5F24ac4247d44cf978B6c3600DbD] = true;
        _presaleWhitelist[0x429a40569087d42C506335Ef39D0786d306A8021] = true;
        _presaleWhitelist[0x04C4C2AC22dbE1451684d5CEc50d672279B9Cdb1] = true;
        _presaleWhitelist[0x53CbcDD4aa85ce2303ce4109adf494ABdf3D46fD] = true;
        _presaleWhitelist[0x1cC6929926959B6Ee44ae50FBA125E30Bb95537B] = true;
        _presaleWhitelist[0x74C002c4Edee654f81F0F6B18E3425ee56eCfd12] = true;
        _presaleWhitelist[0x877932B0D29dEbaa7E90Dc41d5AA862239FDb284] = true;
        _presaleWhitelist[0x695e1FC091309e66C1EeEeE955aFE573564E6Ed0] = true;
        _presaleWhitelist[0x3896F3fd5Ccf2faBAd94E8BB73951e289742536F] = true;
        _presaleWhitelist[0x28A85E00575CC9Fc6F4F5cDf2e54A971Bbc4A978] = true;
        _presaleWhitelist[0x05A83721E016B9dD6742A96eC8d68c26b040Fb08] = true;
        _presaleWhitelist[0x10824D1c2fCE4632af7fbA886a6903fb1D4CEdcF] = true;
        _presaleWhitelist[0x37A4dE30A6Afc28ba547271A9A588bc05AE8566c] = true;
        _presaleWhitelist[0x90E90f12486cAe24a4E891Aaf9C336269aABA7EB] = true;
        _presaleWhitelist[0x5E47a44D1c2ea6c1024F495CDcc55B05aA82E349] = true;
        _presaleWhitelist[0x19E5B153Face9EEefC09de57D22CC817e4Af6b2c] = true;
        _presaleWhitelist[0x3e8289CD7a49B8E59Ed9b4bFFc958Ab85c1D637c] = true;
        _presaleWhitelist[0x012f4881D429d59F8917e2908773eCBd6E570D2F] = true;
        _presaleWhitelist[0x02C05D1625B7460Afd2C9e063c5fD40B122393a8] = true;
        _presaleWhitelist[0xec62B648c214B130ebA5ABd54C2Ee88984b39083] = true;
        _presaleWhitelist[0x82400eA848CA71A7dc491e33496E3f2b3509b947] = true;
        _presaleWhitelist[0x1159DBC66C3b6F7742f8e951656a830631dFe69B] = true;
        _presaleWhitelist[0xf45a877A7A3A1aa82fe2313080728cC3DA90cF16] = true;
        _presaleWhitelist[0x87302A99d1Bbb367E95ad9da9265feafe57b95a4] = true;
        _presaleWhitelist[0x8f3E5f24293DAcc1EcA931811B4fccc30a70d26F] = true;
        _presaleWhitelist[0x2EdB8bfb8cACA74ddcF0a1914864a8E37BD4b000] = true;
        _presaleWhitelist[0x563d6b022FcA35bE0eeFDD9Df57D31e743ae5a42] = true;
        _presaleWhitelist[0x469B86b8992b2d4db8D7C74033991a2c75d6454e] = true;
        _presaleWhitelist[0xBCF0C6870018C889726AfA2B3a0c0eaB03381Bf1] = true;
        _presaleWhitelist[0x4f86e6A54881083028E38cC1cF48e08A47e576d7] = true;
        _presaleWhitelist[0x21a692edaD23512386bc7664C5B20A175Aa39811] = true;
        _presaleWhitelist[0x3379aEc4aEC5f88f6B239aaBAe542516D3d113E6] = true;
        _presaleWhitelist[0xE633D5b2Ae8928d43D258E8c131583E6232B0dfc] = true;
        _presaleWhitelist[0x2F5b62B1fC025Ac53690d339064eBC01b4a1F138] = true;
        _presaleWhitelist[0x538E7b26473a50a250E4B61c1062adBaf6cf474D] = true;
        _presaleWhitelist[0xe4E68F43704263caf50808714DA38b079809D49A] = true;
        _presaleWhitelist[0x2B4AbB161D69c0BD3C54B48ad8A5403B52480A44] = true;
        _presaleWhitelist[0x3d87eB98b84630FAE7CD663D1Ee1e8bf05b999A2] = true;
        _presaleWhitelist[0x9c9eC8bDBC3642ad28b1320D31A656D258E27618] = true;
        _presaleWhitelist[0x54E82b511F2f2B111b67788f11F7179969013BaF] = true;
        _presaleWhitelist[0x07852203b89088F3Fe360f8621Ec7d835E950cBe] = true;
        _presaleWhitelist[0xF69189af9A2eB9bE094BEc32D5aEA8E330f24900] = true;
        _presaleWhitelist[0x7d4c5964e07c7d85D73dcbf4547Eec9bAe58Ae02] = true;
        _presaleWhitelist[0xAf72D4494C7e72dab807fBDf369291cE34C93872] = true;
        _presaleWhitelist[0x1AAbC85Dc99Eba0C833ADbAb22de3ef4da5f60C5] = true;
        _presaleWhitelist[0xe848812f5192D9FFb49fbd1E5c4eeFc26d0A5Bc1] = true;
        _presaleWhitelist[0x2aF225b3D7D102B81A3BCa7e43B8Cd1b1eAEd1A9] = true;
        _presaleWhitelist[0x8F89DFaB75EA709aC704389c36228FCCfaE37EF8] = true;
        _presaleWhitelist[0x37c9eD3b53adD2c4186FFcC61DD7d7B9C4F6a8e3] = true;
        _presaleWhitelist[0x7b3040879F1E1b987f33E1D7449C4BFeeF083cC5] = true;
        _presaleWhitelist[0x85C1047737D91E3e84320d5e6228DDdB1fd61D80] = true;
        _presaleWhitelist[0x35DF56164944bB3C2DF2ef8453Ae394E8DEF9F25] = true;
        _presaleWhitelist[0x7ed018F10294EbA79a47f8C65C0F6380299f40B4] = true;
        _presaleWhitelist[0x0F717344c35f1ACc2795344583db5A006E08C88b] = true;
        _presaleWhitelist[0x7817E0F3877b86371F80746fE2Ef186dF1807e4c] = true;
        _presaleWhitelist[0xFE2378F2EB684D609175D5c9E94F7f8f7a5d6DBA] = true;
        _presaleWhitelist[0x3E9Dd7801a609Eb1DC2DD5faA8af8E23598E15Ba] = true;
        _presaleWhitelist[0x369b3595273dde3A7a4064BbA4Afe3ad0DfD9983] = true;
        _presaleWhitelist[0x0479886A0335F96df5A9eC164Dc4cC621c2b119f] = true;
        _presaleWhitelist[0x3053eCb8B6C14c307FCf49728B299cb8367fc226] = true;
        _presaleWhitelist[0xC18dfCB1C5b8E4A626B406685B8a56Db3aEa5C64] = true;
        _presaleWhitelist[0x3Ecc7e334BBCF13A72060145Cadd4c5Af6941Ca9] = true;
        _presaleWhitelist[0xE540B924E809cBFdaEb4C70b0589FA0622C4057b] = true;
        _presaleWhitelist[0x247bE5421cc8Aab9207e607Fea6ed6699a44ACfF] = true;
        _presaleWhitelist[0x1Cca3C96783cA665450eB4Fe7ccE5D8D0962E10e] = true;
        _presaleWhitelist[0x1c8AfD8500CaE37aEF9A1bB71d6E1Fea2331Ed36] = true;
        _presaleWhitelist[0x445fdA5D695e26938E4d6059e0A25b6f6D234E33] = true;
        _presaleWhitelist[0x47829e099FE2c07262BaA3E7b039876086F4A9D8] = true;
        _presaleWhitelist[0x3AE42cDdE0aA6889049eb67ceBF56b6fcfFE24f9] = true;
        _presaleWhitelist[0x634Cc4e2F0bE96b2642EfD10FC0E750FDFaa28d9] = true;
        _presaleWhitelist[0xAD2B8E18CC7BDDDe1Fe7e254D78ABF1188b6C8f4] = true;
        _presaleWhitelist[0x20148934F6bA904562128495a007Cf1D4f3B11A7] = true;
        _presaleWhitelist[0xDb17f648a5da5a4B2E8706Fc9Dd8822407e684A0] = true;
        _presaleWhitelist[0x4233fdEB1cDc84eA29764598Ea997CF6c06B2B79] = true;
        _presaleWhitelist[0x985A19cb5a8316C3aD2c8d6af2bcD8Fe22e18b89] = true;
        _presaleWhitelist[0xf3a5731285656E925e82AD25666A580c381A5A09] = true;
        _presaleWhitelist[0x1e1055Ed1281101C6d149de602e32B6C64aE9412] = true;
        _presaleWhitelist[0xCDe721640EfAAD64d34B0663F6096a7Fcc759483] = true;
        _presaleWhitelist[0x3fC4822F7363E906C6d4E5eF319e4a5ff2fCB517] = true;
        _presaleWhitelist[0x31460cFda82af09c26306092843dFDb8b65F0544] = true;
        _presaleWhitelist[0x1c3c5305Eeaf72B3d6D20D1c20bcbC894FFeafeE] = true;
        _presaleWhitelist[0xF834C6Da7AA4aA71d94c2496554e54103492D5ee] = true;
        _presaleWhitelist[0x98605B0303D2786451E062a414A458Aa2CF0A2a9] = true;
        _presaleWhitelist[0x075BE9842f966A124b55D1E8Ef8D16e04443D9C0] = true;
        _presaleWhitelist[0x252A755AeCad8b802552697ad1c0a7B095F4Bb36] = true;
        _presaleWhitelist[0x2A1B414b392529D4468e7b6FDfdD1227eFfDbFeF] = true;
        _presaleWhitelist[0xdfC3D0FEA0e64CA062C6bb82cF0896109BC8F327] = true;
        _presaleWhitelist[0x1Dbb4D1C3dB0D3d69134cCB49375AF6AF70C80eD] = true;
        _presaleWhitelist[0x0aa24e153B8371878691db4219F4C24155f61784] = true;
        _presaleWhitelist[0x90A1467D64535C43a205601A4D53E390C29f672F] = true;
        _presaleWhitelist[0x0f561ee1EaecbDCCb9Dc14a51EB729601cA5233a] = true;
        _presaleWhitelist[0x7d1Ca405009FAE414A340249cDFfAFDbB957F98c] = true;
        _presaleWhitelist[0xf4fD3ac9867469C325CD8a8DBe8eBFC80B50c3e4] = true;
        _presaleWhitelist[0x66CC6Eb1D8D64099d07720F6Bd502e95b760b821] = true;
        _presaleWhitelist[0xda933A14805821E85c8Fe31a5B2984C2Dd3d83d3] = true;
        _presaleWhitelist[0x63B093fdD96d566011B6974DBA50C8fF9c0F20B1] = true;
        _presaleWhitelist[0x06DD41e3370d2Db6614c0029DC2B2085cE1Cd061] = true;
        _presaleWhitelist[0x52262De29D8B5Df89C64113E4B3A1acc1D8139CA] = true;
        _presaleWhitelist[0x4694398055c10Ee95Fd59d951fab817417A3Ff36] = true;
        _presaleWhitelist[0xFC76f691c9c816fea2687cD32835EAb4c31D2d5f] = true;
        _presaleWhitelist[0x84B59D6208e41c6088cc0198fbc9874D0f84892f] = true;
        _presaleWhitelist[0x97706e57D9C4EAeD5a4c1C245E1e21F8233301bc] = true;
        _presaleWhitelist[0x294e1dA868084bf8951A09C7B5Df035Ce3658b1D] = true;
        _presaleWhitelist[0xFb8DCCBE99Bd647A2a0c7EAC57C422BC3a530ECd] = true;
        _presaleWhitelist[0xefBc0039FdBe3FEa731B02f4Ee2577437b2161Dc] = true;
        _presaleWhitelist[0xAe35922D6E3037e7223ba3AcDCCde497C9a462e8] = true;
        _presaleWhitelist[0x5B6b15D55Ad78D9Abee7D08944F781407fc492Fa] = true;
        _presaleWhitelist[0x73d6D1fE53C2DA73968F0EbD10A95290b6912b5E] = true;
        _presaleWhitelist[0x193E08ef534F22BE30Fe9d8456912f6E5E4F2A8a] = true;
        _presaleWhitelist[0x87a4bb507C45B06B17189EE886C6f568dEfb2014] = true;
        _presaleWhitelist[0x935E8E924CbB5e6020C54149852bdb43bEbbd036] = true;
        _presaleWhitelist[0xc0E88265e4c4333E7Ec7DbF978fbEaA46F3d46D6] = true;
        _presaleWhitelist[0x8BeCa0309248700dadDE5679E95ae809320f23Cc] = true;
        _presaleWhitelist[0xE52085a7d4855c3a7BB748f5c8D2741efD0C7807] = true;
        _presaleWhitelist[0x646EF9cF794662448FE1A544A0f7B234e22281E5] = true;
        _presaleWhitelist[0xC3d90644F686b1cb2C4A43D8Dee621BA09DAe370] = true;
        _presaleWhitelist[0xD6d710f0Fa57f25135fB8c3e7d34455300B9eF4a] = true;
        _presaleWhitelist[0xa049AFeF83d112F9B9Ac4E9d743C50aD08EBEe01] = true;
        _presaleWhitelist[0xc2065E8C845448b6FD7a3aD168918f2BA6e9d45f] = true;
        _presaleWhitelist[0xc12Dd428DEbb46697AeC5774A04347DE160e7B39] = true;
        _presaleWhitelist[0xa8De98c84B3c4Db23F34614bd290f0490EF9649B] = true;
        _presaleWhitelist[0x05B016636d078e501338343039dCf3e6254ea51D] = true;
        _presaleWhitelist[0x94D6CbEeD9341aab1AA4fdCd329703D357510a81] = true;
        _presaleWhitelist[0x586ABD52822cA273c5a0ABC881143E7326dC4101] = true;
        _presaleWhitelist[0x8fEfB5C2C78c5227146da2Bba3E9bd75Dc763365] = true;
        _presaleWhitelist[0x48F4efc8EaA90C747E7859216dA14149fFd31eA2] = true;
        _presaleWhitelist[0xC824D3869b2C08b825C835FeA4eDdbA4cdEd3A01] = true;
        _presaleWhitelist[0xa41813CbCE447376dF8936a69b449064D9F2A016] = true;
        _presaleWhitelist[0x000376dA4117e04233A39C29161e99e829516cF7] = true;
        _presaleWhitelist[0xd0AD343F78D3864f4fFCA528aCE86551754AdeC7] = true;
        _presaleWhitelist[0xF3b7C59cACC5E78C2b49c1C27Cd0099f1d9209c2] = true;
        _presaleWhitelist[0x3a3cd3c556c424fBbc4527CbAc907B3D13B3f3EE] = true;
        _presaleWhitelist[0xc20420853CAa5bc5c8Ea359599EE27e74C7A65D4] = true;
        _presaleWhitelist[0xeAf0dA467cABE404727F2221b5Be72F6F54BE508] = true;
        _presaleWhitelist[0xA01d590200946D92eE84364624ba459e8B75FFc1] = true;
        _presaleWhitelist[0x95408cb170E01DE663016D1865b926E9aB90258E] = true;
        _presaleWhitelist[0x443C153019df225F6842532509303C2A778185cA] = true;
        _presaleWhitelist[0x2f18B365BF7561f38983256CBd8cb5113953a985] = true;
        _presaleWhitelist[0xF3676091e6BEFCEF0f86Ace8D69995794Ca13715] = true;
        _presaleWhitelist[0xAbf29fAb7D6389408691682BF3362001fa65053b] = true;
        _presaleWhitelist[0xFA14dE9Ae7E438b81ACDEF3d37d3fB76ccEF18dB] = true;
        _presaleWhitelist[0x3d706016C74123b1751138D2AD13A48265cb4Fd6] = true;
        _presaleWhitelist[0xcB53E30C599550f30c1c7fa456C6614fCfE8d5C4] = true;
        _presaleWhitelist[0xb12B414444C3D8eD68684AF9f1D1A765d3c63D09] = true;
        _presaleWhitelist[0xC9D3C2d5AB6c2Ca7aBfBea5238332322f05A74a6] = true;
        _presaleWhitelist[0x1c3c5305Eeaf72B3d6D20D1c20bcbC894FFeafeE] = true;
        _presaleWhitelist[0xD4Db7364A1218fd77a77481D340dC0a0E052a6dE] = true;
        _presaleWhitelist[0x9EC64c6Ee1C7dB8F79d7691B5A2d9e00399dAE98] = true;
        _presaleWhitelist[0x786C56F3E470CE0149dFEe5F3aCB6e6ebA794A69] = true;
        _presaleWhitelist[0xC45382F287A69A912f4554E5F33A498f6672b023] = true;
        _presaleWhitelist[0xA289272eB38D5cDd0aD8DAF4144c0676606d09F0] = true;
        _presaleWhitelist[0xe0b4FB4549656992fba30A11647252AEC107Ee14] = true;
        _presaleWhitelist[0x412d4F62d94462128Cb3e7684739bD5244281B90] = true;
        _presaleWhitelist[0x5b48ADB79E1743d4675FD035FdD789D417eD78bE] = true;
        _presaleWhitelist[0x933b7122cD94B89215aC10F689cC26b395a57FBe] = true;
        _presaleWhitelist[0x2D3bCFDfAD3434dE22BC8b698021cAdf4115A29f] = true;
        _presaleWhitelist[0xFb8d0640198593B4680861a913E29d0BFe6ba319] = true;
        _presaleWhitelist[0x63826836D9F139314d129955bc6905607AEB679c] = true;
        _presaleWhitelist[0xCFC6bbFb3f8584c7ff0AEB032172ee472Ed4E7dC] = true;
        _presaleWhitelist[0x650cdC41bf81317D0D3d49BD92f6A17f38DA0aE4] = true;
        _presaleWhitelist[0x776dd6AAb2F0CA98d3D69E4396c6165DE2659e80] = true;
        _presaleWhitelist[0x035F0193f73C50A6012fD2C28B746Cd7b4235C3F] = true;
        _presaleWhitelist[0xfa5d5940091f527E56807568f79fB0fe75225037] = true;
        _presaleWhitelist[0x22d0CcB3315eFeCa1eE95f7E68A199e053719b16] = true;
        _presaleWhitelist[0x5b8301FBFFFf378CA466953724088Bc2e6D34084] = true;
        _presaleWhitelist[0xf189408B372ce23a6d5E3be4Caa02277031fC145] = true;
        _presaleWhitelist[0x917e929Ecaf20bc263984CEa8E8A705216aCEF1b] = true;
        _presaleWhitelist[0x44F25d162195b914446B3335ced1E57C4749C723] = true;
        _presaleWhitelist[0x092A80Bc64d39B1A5F06B14E3Ad9bc742bb89Bb0] = true;
        _presaleWhitelist[0x77A1A469BcAf321215408C5AB90fbd448A9d720F] = true;
        _presaleWhitelist[0x35A9D311413A031D992b80571c1e8E6bfAd4A07D] = true;
        _presaleWhitelist[0x7709b86438eac31760c9c084BE1E7CbC255740D6] = true;
        _presaleWhitelist[0x041A9Be52b2C577394BE60cBcA736034e972aD0b] = true;
        _presaleWhitelist[0x5D8D788115EE34Aa6714FaD133E19eAc46480123] = true;
        _presaleWhitelist[0xa8Ff368be65800e1b7BD5f36C2a617c661C153B5] = true;
        _presaleWhitelist[0x22d1f38a420520a380577359e976E2b4FD70fAd7] = true;
        _presaleWhitelist[0x175B3Bec10500aE28594450F7c1FC08d7Fb4465f] = true;
        _presaleWhitelist[0xB8EE7cD064ADACC915D4F3849Fc12DbC85D74B33] = true;
        _presaleWhitelist[0x0525Ed76CAA96C807843015ffE1E56Fa25e75AD5] = true;
        _presaleWhitelist[0x9CC6908A1b59F2C25d6D1356DD192886F8A6c266] = true;
        _presaleWhitelist[0x65c732C561c31563603cFC141259C5398A96fC35] = true;
        _presaleWhitelist[0x6c68052eAb2eA9C630C56251f34e4bAA4a02aa4A] = true;
        _presaleWhitelist[0x47E8849408b31F690048b35Aa7BbF7198575ffec] = true;
        _presaleWhitelist[0x6eA8F1B1F8242c29D09739B88cB8Ae20960EEe36] = true;
        _presaleWhitelist[0xE01bB320423A5Fd248b23e5ABA5580575737dC51] = true;
        _presaleWhitelist[0x2Cd851C024738ae095c8037D02b3bE5FAc1054aA] = true;
        _presaleWhitelist[0x323f35F58c7A5a954116F1A7ad8fD1085e525c4d] = true;
        _presaleWhitelist[0xC8Ef7FCac332558Bb2387D6fb64938F5DdB79C37] = true;
        _presaleWhitelist[0x0274D9f7417d421A1384d31e57FB641D8890204f] = true;
        _presaleWhitelist[0x3A3151dBd76f2Fd28b7156A3A55846EDa0266Cbf] = true;
        _presaleWhitelist[0xD8802D37df9B0c363E68Ef13EC7c6CD58dbaeadF] = true;
        _presaleWhitelist[0x9A30F112F5d35EBfA6F101466DFA68415FAEE817] = true;
        _presaleWhitelist[0x3f124dc9CC4844921c5a5e8564F7E874109b0A95] = true;
        _presaleWhitelist[0xFFB430140F55333DEdA69999f5AD4EDd5b29794b] = true;
        _presaleWhitelist[0xcfA97E4872bC679811c3fFcBC7D189093B72b341] = true;
        _presaleWhitelist[0x7C4D73F63a7E16EE227b5f6b4e87378865F22CdD] = true;
        _presaleWhitelist[0x0854d59f5Dd94b579CA9BC7689F96f3C744e3bF2] = true;
        _presaleWhitelist[0x1Ff2a117E9979a5A21b37B5254A64a9D3DfD8Bfb] = true;
        _presaleWhitelist[0xbc190c1336fD700A0CC3611BE6F2f060526cB3d3] = true;
        _presaleWhitelist[0x5A0CA2353a5E284BC23B53D130070495E1b598A1] = true;
        _presaleWhitelist[0x5c95679A83363ae561453827a0376fca9Bb7587B] = true;
        _presaleWhitelist[0xd56Fa666456bF332A6Fdee45EC41DFEb940B679f] = true;
        _presaleWhitelist[0x282B774ab025FC2c1E9ccd17e2D3CD2d2750acdE] = true;
        _presaleWhitelist[0xf8174653aC1eb9D030f0Ad630534Ae61Ef9a265d] = true;
        _presaleWhitelist[0xAA6D07B859b9D1630a2d86DAA7D140c3Ec8eE447] = true;
        _presaleWhitelist[0xf310Ea2800a76132202945fd32aE09dE8798440a] = true;
        _presaleWhitelist[0x40b8F09AfCF1D271D805Ce13F8064853D353cf59] = true;
        _presaleWhitelist[0xaEF1EfE94597bd46c1b862C92b8CFBd03A3131E6] = true;
        _presaleWhitelist[0x0D422ef6A5c3A552ee1E00CF2332a833C36162cC] = true;
        _presaleWhitelist[0x8272A6B75d902FD5E1cCDCEB213D853908E1F434] = true;
        _presaleWhitelist[0x5583E73AAbA2E4ECce4C038060131729B94F4C08] = true;
        _presaleWhitelist[0x1719dCFD708F7833BA4A3ef3047025bceEbCF7A1] = true;
        _presaleWhitelist[0xbdC16a0FFFcD2850FE68910f208B2be8b6E278Eb] = true;
        _presaleWhitelist[0x89247ef46707cB6ffc93208938Bf08d3CBA10e56] = true;
        _presaleWhitelist[0xf37841F3511ABe49E416740682Eb4baD403e7a14] = true;
        _presaleWhitelist[0xA2B48C299A90303E758680E4FdEcE6C0AdC1D588] = true;
        _presaleWhitelist[0x5c6f5A221B11284DC72C386E2CafB55dF0dffdf8] = true;
        _presaleWhitelist[0xB5779258Ce52F0b46890675B098d082e8a152CE7] = true;
        _presaleWhitelist[0xA30a03AaD5044DcE54F4E7f7faE53E07A79a26B2] = true;
        _presaleWhitelist[0x0Da5A861f2Df0D7d78D29347c1952f23D07fB208] = true;
        _presaleWhitelist[0xc723c68aC5962a3496e7EB3C9eF3f9373131eE2a] = true;
        _presaleWhitelist[0x3C218A2476E6Be3160BEd701fC859ef432BD13c4] = true;
        _presaleWhitelist[0x3d98C0a700A459740a290F4B7b13b3D1dE0B8675] = true;
        _presaleWhitelist[0x028A7316e38DE582e4E47b5ED747569DA30070E5] = true;
        _presaleWhitelist[0x3f137C1AD4FB32b10F9E117A035543B365535BC7] = true;
        _presaleWhitelist[0x1C0Acaf31f038DAC65e0D4a9a1550AE75784aAdE] = true;
        _presaleWhitelist[0xF39eD7878e4eE8c555516dF4423c01E3AD95E4BA] = true;
        _presaleWhitelist[0x86Fa7eC7176c3893721ABC7058F210e2C7900aB2] = true;
        _presaleWhitelist[0x82400eA848CA71A7dc491e33496E3f2b3509b947] = true;
        _presaleWhitelist[0xfCD067A1825904668bC6c8Ca135E312BF0bD61d0] = true;
        _presaleWhitelist[0x4500C6A5E5E9b1967885B0d393eb6FF570e08126] = true;
        _presaleWhitelist[0x54A3256d6fb04BF526B09Ef4fF4ad265305A034e] = true;
        _presaleWhitelist[0x26c3d14Fd3DBb50D50f853adf364e9616Aa1EB14] = true;
        _presaleWhitelist[0x286C9359f1DbF45E5aD4e90153474fF2d6dFC405] = true;
        _presaleWhitelist[0x117E53e814BF3a70F61a5bb168A21e4564EdE179] = true;
    }

    modifier onReserve() {
        require(!hasReserved, "Tokens reserved");
        _;
        hasReserved = true;
        emit Reserved();
    }
}