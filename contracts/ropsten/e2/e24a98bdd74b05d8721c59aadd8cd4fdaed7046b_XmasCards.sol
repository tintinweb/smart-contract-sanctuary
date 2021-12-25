/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/XmasCards.sol
// SPDX-License-Identifier: MIT AND ISC
pragma solidity >=0.8.0 <0.9.0 >=0.8.6 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC721.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

/* pragma solidity ^0.8.0; */

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/Strings.sol
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/* pragma solidity ^0.8.0; */

/* import "./IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

/* pragma solidity ^0.8.0; */

/* import "./IERC721.sol"; */
/* import "./IERC721Receiver.sol"; */
/* import "./extensions/IERC721Metadata.sol"; */
/* import "../../utils/Address.sol"; */
/* import "../../utils/Context.sol"; */
/* import "../../utils/Strings.sol"; */
/* import "../../utils/introspection/ERC165.sol"; */

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

////// src/Base64.sol
/* pragma solidity ^0.8.0; */

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

////// src/XmasCards.sol
/* pragma solidity ^0.8.6; */

/* import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; */

/* import "./Base64.sol"; */

contract XmasCards is ERC721 {
    string[] private _messages;

    constructor() ERC721("Xmas Cards", "XMAS") {}

    function mint(address to, string memory message) public {
        require(bytes(message).length <= 28, "Message too long");
        uint256 tokenId = _messages.length;
        _safeMint(to, tokenId);
        _messages.push(message);
    }

    function totalSupply() public view returns (uint256) {
        return _messages.length;
    }

    function tokenSVG(uint256 tokenId) public view returns (string memory svg) {
        uint8 imageIndex = uint8(uint256(keccak256(abi.encodePacked(tokenId)))) % 4;
        string memory imageHTML = generateImageHTML(imageIndex);
        string memory imageStyleCode;
        if (imageIndex == 0) {
            imageStyleCode = '.c0{color:green;}.c1{color:#ffffff;}.c2{color:#000f12;}.c3{color:#258541;animation:x 800ms 80ms steps(1) infinite;}.c4{color:#4b9947;}.c5{color:#e31c35;}.c6{color:#f27d37;}.c7{color:#f5ae69;}.c8{color:#ffd6a8;}@keyframes x{10%{color:#258541;}20%{color:#2a8a46;}30%{color:#2f8f4b;}40%{color:#349450;}50%{color:#399955;}60%{color:#3e9e5a;}70%{color:#399955;}80%{color:#349450;}90%{color:#2f8f4b;}}';
        } else if (imageIndex == 1) {
            imageStyleCode = '.c0{color:green;}.c1{color:#ffffff;}.c2{color:#000000;}.c3{color:#f8851b;animation:x 800ms 80ms steps(1) infinite;}.c4{color:#8a5132;}.c5{color:#383c59;}@keyframes x{10%{color:#f8851b;}20%{color:#fd8a20;}30%{color:#028f25;}40%{color:#07942a;}50%{color:#0c992f;}60%{color:#119e34;}70%{color:#0c992f;}80%{color:#07942a;}90%{color:#028f25;}}';
        } else if (imageIndex == 2) {
            imageStyleCode = '.c0{color:green;}.c1{color:#ffffff;}.c2{color:#000f12;}.c3{color:#8a5132;animation:x 800ms 80ms steps(1) infinite;}.c4{color:#ad7145;}.c5{color:#302011;}.c6{color:#441c15;}.c7{color:#713115;}@keyframes x{10%{color:#8a5132;}20%{color:#8f5637;}30%{color:#945b3c;}40%{color:#996041;}50%{color:#9e6546;}60%{color:#a36a4b;}70%{color:#9e6546;}80%{color:#996041;}90%{color:#945b3c;}}';
        } else {
            imageStyleCode = '.c0{color:green;}.c1{color:#ffffff;}.c2{color:#000000;}.c3{color:#be2025;animation:x 800ms 80ms steps(1) infinite;}.c4{color:#f5ae69;}.c5{color:#ffd6a8;}.c6{color:#fef100;}@keyframes x{10%{color:#be2025;}20%{color:#c3252a;}30%{color:#c82a2f;}40%{color:#cd2f34;}50%{color:#d23439;}60%{color:#d7393e;}70%{color:#d23439;}80%{color:#cd2f34;}90%{color:#c82a2f;}}';
        }

        string memory part1 = '<svg xmlns="http://www.w3.org/2000/svg" width="512" height="640" viewBox="0 0 512 640"><style>@font-face{font-family:"Minecraft";src:url(data:application/font-woff2;charset=utf-8;base64,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)format("woff");}p{margin:0;text-align:center;}.canvas{font-family:"Arial";font-size:24px;display:grid;grid-template-columns:repeat(22,16px);grid-template-rows:repeat(24,16px);}.message{font-family:"Minecraft";font-size:28px;letter-spacing:2px;fill:white;}';
        string memory part3 = '</style><rect width="100%" height="100%" fill="green" /><foreignObject x="80" y="80" width="352" height="384"><div class="canvas" xmlns="http://www.w3.org/1999/xhtml">';
        string memory part4 = '</div></foreignObject>';
        string memory part5 = '<text x="50%" y="552" text-anchor="middle" class="message">';
        string memory part6 = '</text></svg>';

        svg = string(abi.encodePacked(part1, imageStyleCode, part3, imageHTML));
        return string(abi.encodePacked(svg, part4, part5, _messages[tokenId], part6));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory uri) {
        require(tokenId < _messages.length, "Invalid token ID");
        string memory svgEncoded = Base64.encode(bytes(tokenSVG(tokenId)));
        string memory encoded = Base64.encode(bytes(string(abi.encodePacked(
            '{"image": "data:image/svg+xml;base64,', svgEncoded, '"}'))));
        return string(abi.encodePacked("data:application/json;base64,", encoded));
    }

    function generateImageHTML(uint8 index) private pure returns (string memory html) {
        require(index < 4, "Image index out of bounds");

        uint256[8] memory image;
        if (index == 0) {
            image = [
                uint256(555555555500000000000003333333300000000000000005555000000000),
                uint256(61888888888816000000001111111111111100000000031111111111300000),
                uint256(66812888821866000000066681288882186660000000668888888888660000),
                uint256(6888777788860000000006888788887888600000006688118888118866000),
                uint256(888800000000000000088888888880000000000008888888888000000),
                uint256(333333333300000000000033333333330000000000003333333333000000),
                uint256(1000010000000000000084444444480000000000005333333335000000),
                uint256(33000033000000000000000100001000000000000000050000500000000)
            ];
        } else if (index == 1) {
            image = [
                uint256(2222220000000000000000222222000000000000000022222200000000),
                uint256(1111110000000000000005555555500000000000000022222200000000),
                uint256(1111110000000000000000111333000000000000000012112100000000),
                uint256(440011112111000040004400000111111000000000000000001111000000000),
                uint256(11111111000000000000001111211100004400040044111111114444000),
                uint256(111111111100000000000001111111100000000000000011121100000000),
                uint256(1111111111110000000000111111111111000000000011111111111100000),
                uint256(111111111100000000000111111111111000000000011111111111100000)
            ];
        } else if (index == 2) {
            image = [
                uint256(6666660000006666660006060600000000006060600606000000000000006060),
                uint256(312333321300000000000033333333330000000000000633333360000000),
                uint256(333555533300000000000031155551130000000000003123333213000000),
                uint256(333333333300000000000033773333330000000000003733553333000000),
                uint256(30344444444303000000000333444444333000000000033333333333300000),
                uint256(300344444444300300000030034444444430030000000303444444443030000),
                uint256(300000000300000000000034444444430000000006003444444443006000),
                uint256(6600000000660000000000030000000030000000000003000000003000000)
            ];
        } else {
            image = [
                uint256(3333111111333300000000033333333333300000000001133333333000),
                uint256(1512555555215100000000155555555555510000000031115555551113),
                uint256(5555511115555500000000551155555511550000000015125555552151),
                uint256(1111111111111100000000111515445151110000000011551455415511),
                uint256(333000333333333333000000000031111111111300000000001111111111110),
                uint256(3330000333333333333000333000033333333333300006600003333333333330),
                uint256(333333300030000000030003333300053333333333500333330003222266222230),
                uint256(333333300220000000022033333330002000000002003333333000300000000300)
            ];
        }

        uint256 digits;
        bytes memory b = new bytes(1);
        for (uint8 group = 0; group < 8; group++) {
            digits = image[group];
            for (uint8 col = 0; col < 66; col++) {
                b[0] = bytes1(uint8(digits % 10 + 48));
                html = string(abi.encodePacked(html, '<p class="c', string(b), '">&#9608;</p>'));
                digits /= 10;
            }
        }
        return html;
    }
}