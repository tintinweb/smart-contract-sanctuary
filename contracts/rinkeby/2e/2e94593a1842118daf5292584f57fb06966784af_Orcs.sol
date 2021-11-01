/**
 *Submitted for verification at Etherscan.io on 2021-11-01
*/

// SPDX-License-Identifier: GPL-3.0

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
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

// Created by HashLips
/**
    These contracts have been used to create tutorials, 
    please review them on your own before using any of
    the following code for production.
*/

pragma solidity >=0.7.0 <0.9.0;

contract Orcs is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = .001 ether;
  uint256 public maxSupply = 500;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressLimit = 5;
  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressPresaleMinted;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    
    whitelistedAddresses = 
    [
        0x4758ebEd66Bba81058efD08d1ea5a471fE31e1B7,
        0xbE264cC36eb3cfAd71fa269f6b4960586393135F,
        0x2fDB18E9FFDFCa350B0Aeb7CC799E1321664EDf7,
        0xb50e6eD73323262E1750Ede06213C44CC09063D4,
        0xDFe459eEF79721E5551c7778B54f459E2A113d31,
        0x4A79D7D3E5C0C554323D4134425ebFEA473536EB,
        0x974b20E3c2682a3dd37A01645aC5165bbcA623F2,
        0x775A3B8AF62A53c5241c2375480521d444aE1309,
        0x29e01eC68521FA1c3bd685aA4aDa59FAe1e7C048,
        0x0Be12a0fE70F24f054a5565956D71047eb976dB0,
        0x602b6f59F56a1008D76cB556a974ffe84266B5C6,
        0xF29438cB61ac85564329F0e470e90a7247945a0D,
        0x42175856652185ddDBD5477fBb1f7f4FC446847D,
        0xC76B852AFaD99eEf4338561246f8a2C327AFab0d,
        0x4b41AA10bf309aa7b5eB30e18263fd9963434F2d,
        0x1Edaa6011c0187B0Af5516ec35BC0a22e2994C31,
        0xcf5931a325d0FF94ecfF3f946c283F05634aD106,
        0x608350082bA3766aFeFE84771fD0bE95210D220A,
        0x3BF2fE6BFB2c713fd82ca4b93f1Fbb507A389671,
        0xf85Df24BEBBf98758164cd24831704cF1707c656,
        0xd6BB082d1167aCFC4bd856f75cACd9aEd634C724,
        0x1d008783A469Cf5D017f467fe139695040d9B465,
        0x0565c501640ccF3E1cc37AA3E4241bDea98010c4,
        0x2Af8fEc81FF8822170E3263E9D07F88D2F5f05c8,
        0x8f0f3FFDfa8D418Ccd8F2c7659efb25980Fb736d,
        0x200eBF3C9cAa6c762cbD0f1f420830e793C8FA88,
        0x7DC78F088d1ddd30d75aD6205893Ea2Ff5B0a8E4,
        0x98005bF51B93Ee31309c7Dc68783EfbB47B63D1c,
        0x7140ff1BC29d56e2ef0a32C078f4f0acbF7aB0Bd,
        0x88b4C088830a6cfed3bE2d5A6aaAcf0482ACf561,
        0x0063146925Da753F393bBce6522e87dc524e9Bd2,
        0xf95699b2c0bBe33195fe1aBcD97171d64F817c35,
        0x3aebF17C58C425a4Cb3789cdaf22eBb0CcC9073E,
        0x89bAF7A6516BE419bAc84ae10e7857BC33B25f8a,
        0x23D5EEC14AFc9d642c41109b0C7e0eC782990411,
        0x672CBFF03eF5A6D0B4AD736EA181CB6c0b467c88,
        0x791C67718E70eEeDA196B1C5219f9892551fbC9A,
        0x26057502EbBE02dDD5D0F0878b1490B3ee00D9eb,
        0xe1E97e9554e3C1269b82c702F69D98da8e49f0a9,
        0x945A4cbae4eF06C0114F53457404A49a6765d9a6,
        0x7e15893ed2ccFcB8a34C0b6557e7107322C32e59,
        0x40d6F4B4d5Ef496682c7C3fCC0dBfa113E5B0336,
        0x9fF09099a9126d131aDcc594857405380c6FA3b3,
        0x8616cA1705A3a3B70cF53638012d44857A40CD78,
        0x1EB4E259EAc3d97ceD2d88923eB3CCa5139019F7,
        0xBfB4848894e6C30d9121B6460e13287d96881391,
        0x3302545161633a3B55D11496fB38f0aa7b10ab3d,
        0x9bE87B0edeac66d8b8d262Ee970F6F241bA5c2C0,
        0x09f7365d1ecE51Ae2821D8647Fea73477AA9E705,
        0x6fFfb61Eac20041F442A56D10A5CdB24deeabA0e,
        0x1b46D512E2D22cD4c5186d34525EE2bfAE70ecbE,
        0xB69Ce5c5a14DafbF476F16f2918ac3c860242fbe,
        0x5609A3944FE052fecbf0a362E305C8c72531B5d4,
        0x1Ff5a5c5eAFBF880b092ED07aDa724169b81148F,
        0xA345710c3C720f20d571Bf6F03eCbA434E9FC92B,
        0x883405eBD164aBE509CFE0e2E14D3D7C80d3BeF6,
        0x895D4CEE80523f8e52777d5fb87B2297495d41e3,
        0x69Ae4a613A0aBf6fBb2bF2AafF91AE2c113B49d3,
        0x1E87fee9DE0C6453c0a405eb87BaD0d3c5Ecec0f,
        0x25A18C68aF97eE250980Db306B68E9D3Bc0A184d,
        0x11E17Cdc4C298f3B2b5530b6beCf95c02954aE51,
        0x5b7Cb6CE6Dc5ab6b3bA89483De86e8E403f22e7e,
        0x5012805693dDd6a5B13F7B103a0F17781cfF6Fe4,
        0x7aAF6A9d9d48b52530acad957deA3Fe05abA6313,
        0x56b229Ca304507A17abB26A80d7a723d8D8513e0,
        0x3fB840c9F362407Eeb62b221f712D78fECCfC80B,
        0x570A4aDF9Ce7Ad402b2BA7615909Bbd45532A8De,
        0x2B6F5ee4d2275DcC1CF08EC01baa5B4D5b967d0E,
        0x9a951FF7D6b1d00216B4242696C57A3232BdA1E6,
        0x6405af00280152866500E4ED91ee462E7f7588bC,
        0xE85DBB09A699c0543C363c3f6E51ef0049e3edC5,
        0x3B16B077aA86baE7eD45c41906Adc4fFAcccFf0E,
        0x643B34C9d7C851bf69Bb766615F860A70f4C9C86,
        0x77fb9C7D16BE80744E29E8F7De6Fe82ae6c9d11D,
        0xb84d84019Af5EeBf81b378E98567068dCB9B622b,
        0x4Cd919427f745B40096EaBdF38110b42695c41cb,
        0x62a8cA10762DFa01475B7c5C232362DF28861C08,
        0xc7322ee2d0E4EBD824adbee58F38FB51352ca8C9,
        0x6Db9C794d95e63FB9Bf4D12151A7e5315BDC4871,
        0xC72F857434F0a0ca9bf08FC2750A2B874e201550,
        0xA959735A1aF98eB7596FaBFe6E135E9f0ABd7E4d,
        0xEC1acA289F794473277aeb09a073f7e610aFB1Ff,
        0x2B167CA199E6EBDeF5008CbAd7a21A9Ccb15c46d,
        0x4769Aab421dE170f1f5781B9b0d3c1415645293E,
        0xd4e0269F31c5E0ecc3fF9fd47cfF282f51101767,
        0xA2cA851525d76e7D1Ab2154292a614E0f59CA67D,
        0x47D0DD1c5A0125F6e52fBAc3e202bfec60eCBDc2,
        0x88AaA2027Abb20a9180ae051Fd0662226C148E57,
        0x5b26888b2fD5C617e95Df5bB7b22644Bf2Aa5930,
        0xb604F3b93882dFaEDc878154cea9892f78e0Ea45,
        0x7438319E0784612dE7804e303baA52Cb3c8dB5F5,
        0x3A87081794fE7506ae0F7cc30a64ad5FE82dC47e,
        0xA95c8435846F82F4D35d57f9973A4e0D96E69a22,
        0x0D3Ef24cCd12827CcE51bcA43Cf9EfB78380429c,
        0xE51341E05699Ed92C4d0402F4E955862423d3aa8,
        0x3d57e3C0fe386F57766995F84BB4eefFAee72bA6,
        0xb604F3b93882dFaEDc878154cea9892f78e0Ea45,
        0xbdfb224D5e089d85366D535eEFEE5810F23e08BE,
        0x3f0749EE9a009EDE06A95d1e19986B9bB8D3b0A8,
        0xb0086CEd87CeD727E01c3b15E54D7Ef04301aC31,
        0x58C48A54a36D346cB71D63ACa5599166bAd21851,
        0x0E36299e2b2CA72a777567dDaB019bc0Ebd92965,
        0x8F6a7A97f3b6CEE0E374b38292Eb87723679C882,
        0x68710ea91627232d3b7D4083c7aeec912cCDc2A6,
        0x8A029549B53b04B1003f25e6E3c830E5Ed477509,
        0x96F91e3eB4840140eeDC51126A4DF1b51B6bc746,
        0xB3D264380FFcf9E764A16Ee9Addd08bdCF46093f,
        0x41cf769131D4F75C662c53D592c91d56fFD45a76,
        0x12ADc0CFB830f71D52ee600d952976054557E5C2,
        0xeD947a0F9170DE48e347F657762199F7E2992110,
        0x3f109fca5C317Ec9Ce06a6E5D8e9C7792737bC7b,
        0x3B1fc9653f03789BC399fC343d8D5B8fC1520EA0,
        0xB98C60Fe6736454999af07D642c21Cc0Dc443f25,
        0x6d6Fb3FAf9432AcE1900A3B9F66ba40Ca5cd7C0e,
        0x14378456B32f2Dc8f41D44b3613b4D6fF9eA2b83,
        0x12AcD4607393F5cf772bfF4138107325d7c4Ca09,
        0xF4151e12614478c94Db8Df53F1E1Ad12c778c4cD,
        0x662195b64795a74f0e4b32A64f0B220010dd5562,
        0x959786a8128F5FAB24b86871266a36bb0DecD495,
        0x6BA167a348DA1d17C34DDa4f94CaD7C6155C5702,
        0xc5c0E639EE5d59F40f14BC4110bb0BE99C06988e,
        0xcF991E3f8414A8949967D51550683852D47F88F2,
        0x63294F76dD7E0Dd78fb3c430281B2DAE494EC926,
        0x445a368791A20735860d42a88987F29BF9d22E01,
        0x4DB6cDd13653736044C2ce25751FC5656ca4763F,
        0xe576b9C06Ff11869127e7CD97CcDE7141ee004BF,
        0x9d45Aa7D07d9945bD011E59Ad3Fc9aCD380a4258,
        0x4DB6cDd13653736044C2ce25751FC5656ca4763F,
        0x0715C3329e38790C853F6fFD824f2771a02D37bf,
        0x8d160063E641252F4B424A9Af89E88B24e04e444,
        0xd6957Ce22991b02e352EE11E94FBc7800d5918e0,
        0x4cec1074e2A72E6943a13CE16dA7589388bf94C7,
        0x2A4E9CeE0b1c25f026A0E77Ca5931ce7BAb20a23,
        0xCd6d1513C6ebB784661Faff7a4b3CD595C555cc6,
        0x3eb8F88422dFd2AeCd1969E24443281cdA239aCD,
        0xa43589Fc8f89f02AB33f3a96De1601624f7Ee06c,
        0x84096Bd010Fee8F97C307bBDAa57bDd98EFA93B5,
        0x3f8ADbe12456188433d0CF09E0472084c4F29671,
        0x3f8ADbe12456188433d0CF09E0472084c4F29671,
        0x4fDA56C38fE5f6752106D4bAD20D50D1331744c5,
        0x5c9E61218b86c3a698F5F2B9802eEAADe1a09fe2,
        0x46d3318E8E669a311A8535798213Cb6E3f321cDc,
        0xca04b727f8b776c1F62616448aa2A0bE25C82ab9,
        0xb94872bc787343e194c069FFeB7621cBea41FF73,
        0xF35341818A13B783664053B1B0f834e658Dcba87,
        0x1cD09116Fc412247f09f4E3CA562D24d1866BBe2,
        0x66e31A557cAac68d3c218ffD0ebE6146D57F66DE,
        0x9eb5b3414B197F7ee1fA7C036931741f081897D4,
        0x02Cd407BD1216C4b227e20dDaB1837f5A74233E4,
        0xDd6969dC2ed9256cE3c399315a685cE4D4E5F720,
        0x52D3e1E323C1c99E049Ab2639B5D0F4d4fe612B7,
        0xcc747443a483a0559F666F5d3D4B6F7b6d2280E9,
        0xDb4eaEC2bE282909E46aCEbD57ff89D8dFecC13d,
        0x5A884D400df60D92391185D39BF169700A049539,
        0xAa74BE7b5Df3891fA88e383Db17A0D39965ABAf9,
        0x31e4a3EF430A729A133483AC783963CE41ceDa3E,
        0xF29438cB61ac85564329F0e470e90a7247945a0D,
        0x7b207d27FF26069E48EA631518a2E784a1460cB0,
        0xf329D15E72a6AbeD9F9290F1065312819f43727a,
        0xC9d60143128cbAc15037cF555dEdd23CCA7e4393,
        0x29d6aB0E6316F90766c0A158eb204A2Bf60AC23d,
        0xCB0835D01fd2c20f68fA3B918d86343fE4EC1A25,
        0xabb893748F86B289E67D01231fda5015BE02Ab83,
        0x9c4b443632B7d511379fe3AcA3DDcfA8F197b302,
        0x37C86E28548ddA9267Ead1CA363D6441c0bbCd6e,
        0x5D3b8520dac5b0CCA62Df147528f04Dc39BA23aa,
        0x0a06C890438F84e9848AF76102341C7A7E2133AD,
        0xbAC1b29acB014AFab23Dca3B7Be6Fbe90256AB53,
        0x637ef5aA5CaeF174a2b45EcDC560a1AfB16668bd,
        0x2C434867d28Da51549Dff76fB127cE22B9aA46c6,
        0x15af8DF7541d8d1264dd14aC6baddB04b98A89aa,
        0x4E0A88B2bEC15a8c1cD87d79DF5D145323c5EcB7,
        0x2749Af4bef7c7042D37DEeFA7978Dc325f461eb0,
        0x0E1606f50626D92aBBc39E6fbEEbbC3DC76E7b3b,
        0xB4C574334615cC5155639038b67208063cc278b8,
        0x60b1659C8b848bdBCb85F4E4792F69C90AAa3648,
        0x06e669e9E19D4FAE54171326A11105F4FD12BeDe,
        0xEDa4c9B9E79011852A1D7c2105122b0c637B5b05,
        0x9CEc27472De184D84d9872377241Cbe4009F3709,
        0x2398c7Cb91A3E929B222C045e0A5A5Cd80826b93,
        0x0E1b6F1b4697C885cCCC9C31d076947522F7CAed,
        0xDb5e9f11d0161780cd1C2be5A1C949eaA7557352,
        0x505438B4211D596D7B2A1f0ED47579cE474e5605,
        0xff4c0AD1A5c616eB96b96DABF5F39C56948BF83F,
        0x3aE6690d3b1b27A3D1aa0d399EF78edF13bFd610,
        0xff4c0AD1A5c616eB96b96DABF5F39C56948BF83F,
        0xd5323d893D721954B2d7bE195279cB2e08f48342,
        0x58491C8138e41101bFEC260466EBD3DF053868e0,
        0x82Bf6D61b2cB35f9bb08Ec99d02f80D6833271Da,
        0xD9587b5851cfD9917D358721Bf56C31DD285CeE1,
        0xF3c84E5cc17E59a78F2fdd5500BABD61023aC830,
        0x7636A5878FD870421D3e546a4b3076BaD870Ec8E,
        0x1Dc1615b4f3a7ad3e5E340e8002bA34Ad0B773Ad,
        0xce25Fc8a802eF77AD244429387CD8eb0cA2557A9,
        0x48302b76c0Ff2fd1cD1b698Be2a8cA5be4De0daF,
        0xbd891dF7b6a7C2eBF4da7f3EE10e6B4642AbA2c9,
        0xB20B5e7Dd0525dC442649C7Dee450Feda2E43C9d,
        0xD6d57d174BE03101c29C1EB3a335559014896BC7,
        0x9352421E3163a85Fe32CE6aaA116F3C64b3e6aD9,
        0x380fEEA870DB5EDd638A8fe78A271FA6E707826f,
        0xBBf17d93A2307dF43F7cC1098EFcf0985e995C65,
        0x0C4938ec23887D1384dA8c0E611042905a366f0E,
        0xc8b506B8150Ea6Ee0cbd7dC71034B12d902141d7,
        0x19E34146D1719bb7ceC1cA0896ED5fA88DCEc5C7,
        0xAe04e4AeFe095D6591c0d5774A226Bc7098D5fA7,
        0xeE97cbF18Fc41C068eb8AFE67025353346c5fA02,
        0x4986ac8522E8831e71439C529E514022596c301B,
        0xc40b73C6356c98de9a32680a6466d0dAbba04C37,
        0x94705A9d675daa924F9190Eca4c05ED6B12d5345,
        0x92451CCf65d681ECB2294114795873e63a4a6883,
        0x74A8bbe4329024ce3D4920474Fb58ca72bfAF42D,
        0x95c59B9ac2c6F2eD1BFC218CB38f87Ff9d3Bf047,
        0x338bEF2AF24EcC89261c81d3fD23F012f0ABcC4E,
        0x1ba7852b19994145bceC6b4F94A0BBc95BcFa94a,
        0x80b759F0A9391e64351e6b94E32c384A40D96b7D,
        0x664E2D99df6747ef42E8a767c0BF8B8CEfd6F373,
        0xb8ff1c4Bf352e5D2986a7c7d1196759602A4abFd,
        0x664E2D99df6747ef42E8a767c0BF8B8CEfd6F373,
        0xb3244abE943ff149fc98096c8fe024cf7146A4ad,
        0xBC82a96210555A04bdaDb29cd442F18687F1Fb9A,
        0x3aa003558fA236B3beB9B935B85e04D150ABa9bc,
        0x8c1D80bD49374d7d3f6cE123df2d8A13121486eb,
        0xD3CE769b8EDda71B86CADb0d4BdBd252897F1753,
        0xa4A0eE63Ac185Df4E2CAB3583F21a48C6d80b919,
        0x13119eA6B582302Eeb3fe78931CD3aE9b7A7532F,
        0x81f927795b64Eb3867Cb55D4eb47a06ffceB5daA,
        0xdb8c009F29F8A376e7aE2Fc75D55e8C12F109aB4,
        0x98d80eD82a3e68157139E2d9Ea6b137e9a358f7D,
        0xE934837666854c8B81FB85F93c2ba110602b77Ea,
        0x929B8AEC1084FaC2b6cA1239c82E5Fe78Dc79d2B,
        0x1fCca6CcB88AFBc361f0e2a7BFd0AF7d737548c3,
        0x2D3178af3Dfbb679716cc14E245Be0A9E5945500,
        0xecbd13e77b74F9Fb052C8dc30Cc0E989BF3dD0A6,
        0x940E6267bbaC505d6b902472e8D2f367b4Ac0997,
        0x7Ac9385A9E821BDF5eEfDf0393F06aa844C5a061,
        0x23330e0A0fd8c954DD377bC7435C8BB409031D23,
        0x861a085492476E06077B18DD62176fbCDa663425,
        0xc26e0041a142D8A77aba79D73b76fbFD8e627dA0,
        0xf26C285B4AdAb350e7E46144CdEF01D4Ad2E46Ae,
        0x699dD336AC982AF000d2171275f1DD0Ec5668C2B,
        0xFb74ad209eB3B114C05e02c45a761aF03334E184,
        0x727AaB0c8f805395444D069408492AC7b8065525,
        0x2AA2DeA1cD1dEB2a67C055C5daE974EFD347d5cB,
        0x2AA2DeA1cD1dEB2a67C055C5daE974EFD347d5cB,
        0xABfe6Aa0284c548f891c5942DB2743D2dfE4D9E1,
        0xcf800e8080C3B7F508ec90CF16e3529849CeAB8F,
        0x80f30d26fe2c61B56ACF51f0C12eF74d09d41F26,
        0x639638a0879e5b4151aff8a643A58B2931c2336A,
        0x18EB2e1f8eFcFcb092B700aeA3324f00FdBa08Ee,
        0xB49E25DfF20B4393379F7D54f0106E0bb7c7b28D,
        0x643B34C9d7C851bf69Bb766615F860A70f4C9C86,
        0x33bF863e0DC4001ac96c80f4aE8B449B8aD48F88,
        0x126B9489FB9c9BA88DcBEa78AB476b8F910F6D6e,
        0xdbc898A01c6B6b9E5F73aa321BE32FC5F136C69e,
        0x70Ddc7ba0c36CB41EAe05EA86221C9b5f5709db3,
        0xA78153D70acFdD2cbf32Ffea9D84074D9d6a5DE9,
        0x742B5F5FD0c3D32cA23D0bcE4095Ca652723A549,
        0x55a05dedcF2344758F6022D9648494DF8F61C9f1,
        0xF3bb575269D16DC7a11De9A6A34175bFB90acC3e,
        0xBfB4848894e6C30d9121B6460e13287d96881391,
        0x70cDC5CED681EA2D965D72C71d668dBe6235B24c,
        0xFECc5C778B6634A9A173D8dB932181666dD95ec6,
        0x3828330e1a4DD3b97E976e249C7Bc8979eDA6B32,
        0x7b01D04faE0aB2479344Be8dAaEdd0Ae1b04486F,
        0xF9663df170979Ac64F5806b101C894a1A8F683BD,
        0xb57c0b622A5a5FCdeb22E49953210fd4c1DE2194,
        0x9De4E4cc181d9d1966ab58E07378EF225425ccF0,
        0xc36E7E0f9A102308C52a53004c171B42AC6A7160,
        0x75EC2e2976decAe6303b7C6AE6C453C3A98b4D72,
        0xEDa4c9B9E79011852A1D7c2105122b0c637B5b05,
        0x3fB840c9F362407Eeb62b221f712D78fECCfC80B,
        0x07F9046B8f8F3b93ba688F97D1a85bfd4b08d9A7,
        0x016D4412299A7B77b61078E73BAC9d6de4821000,
        0x53B581f0F916e09ba07B6204e8720a1d9323521A,
        0x9D2a6Dc7aff9950CF725241441584540B2ac1ca5,
        0xCA7080A463706725E1632145cfcc7dB53eD25f96,
        0x1EB4E259EAc3d97ceD2d88923eB3CCa5139019F7,
        0x5fbfe8dAB81A39A04B9590dFcEac9a93e7aa3302,
        0x6dF01b9e66d3267F1f8949A9e35f89043FE9822c,
        0xE876B553741a879967f8c502b757E919Db1a8b5e,
        0xe05006Dc1369ef6BBcFd696A38a573C8C28A8E7C,
        0xd9718542D7832B322e92Fa03F408D02a4d47C2c5,
        0xC6b62b1688C2B3B1a12E3d222DdaD43BE379c1B6,
        0x0e93545Edad0Ba8884bCEe70618c3D8D4D73d5B4,
        0x4Db180f14A91d3e01776DB3cA2993676543C2A06,
        0x4f4FCA10d1863FF5fea61b8dD3E7a7F8a6bC77EE,
        0x2f8e0f91Df5A26783633910bA9Ed4B3b7b7883E3,
        0x9713222695378e27511779Ba00b7cBF178120371,
        0x0475fFc635B0F1cd52c7DAEa24e7aF02A575551B,
        0xA8f6Af28BFab672859AcF31EcA54C81a9CbBeB66,
        0x466C40b45Fd199282EF116406DE3Ba7e548426e5,
        0x2657344889F180A85a845fA2b04ECD5637508038,
        0x17A985095BD612A9B6278f8dd8A6D91Ec79dD81e,
        0x17136144999C10439D90A2aC22386595BfEf0527,
        0xE7CCfF5De5D5bbc638394D917EBFA6a60Cf38C08,
        0x01DaC505E000d4B87e427271Eac85B4a46B5141D,
        0xb63ea4865cDfedF3A7bCa5Df5BD49F04D59ea348,
        0xc3A8b0eE40098E32C1d749EBcDc6C144ada911CD,
        0xc58374eA34717411FcE751B29498ea234FabE17a,
        0x1c7bc5daaF0A913d922839196c08CF1d7b74fb12,
        0x04f23CD6624A3a1E205A59DAAe3F7b589bBb56CE,
        0xBEA8e78462246F7Ea4B531B4cB2425B329846208,
        0x291B104D72Be6a1eff9cAcA557E4745c4b10b064,
        0xD89863049aABCd4626590fdebD00aF11D8233173,
        0xE83370D402504Ba36F0866068F0c2afA5243A969,
        0x5475647b2393328eCd47B0256782365c7F42fb15,
        0x59a9bB69dd15f8E932Fbd1982389f62CfefB68f4,
        0x4F3c114735101EF8Edd81760A05bf269d2F04889,
        0x8B1dD48344de9922AC1f24B7563fC07EBaA00b20,
        0x0D492E61C9f4C90f144aa479892d0c25Aa934425,
        0x98A282dF175c7720E8439e6129F7A557746A3D03,
        0xEBaB7d355f15a21fa37F4a0E0B303f07e1a320De,
        0x45C14654CF2eAC6a7904e80Bd3F4B58ad24E0235,
        0x42C70946962DEd7fb4489D8dd543d1857eDD3291,
        0x60a26961E4cCb7DE430C8357695Dc6022417165b,
        0xe9B7092940B4631c87e406EB2d292EF9a039e4Ea,
        0x3863B7d72aE4E36B170FfFf900E5A61637011953,
        0xa78b19c5683363dE380d56CE0A164360B59E711A,
        0x9D2158f50307A971345F9bC38441FA60688BAA1E,
        0xE68c542363A74369Cc41d1490C870c41c3Da6E2A,
        0x96a603254e66AcffF3b641c461270e2b37DA67Ee,
        0x9Edb768e329d4F6F60eADAA16bb8549d52120819,
        0x18EB2e1f8eFcFcb092B700aeA3324f00FdBa08Ee,
        0x4f186d24C29a02e633092e655d27ced9439f4967,
        0x1BDE23313c081512e10dfac770f23f6C99685122,
        0xea9FeBaEcDDAE02967f70F5cF79688786c851463,
        0x25A411f95aD3b558a783f6730e7C7d8E297b0fEE,
        0x404CC659ec36E3e84B6578FBf874Dcba7bc2bF3d,
        0x08254C88e28363BB1135f884f5B616dAEc79d7EE,
        0x0b13f13c0E99F24b96A835B787D1347B33d87776,
        0xAA1E92dDd28C835fe66689771d35f38947950FD4,
        0xC3D067D6C8A5803882DFAC2dce6E2CAd0225E6e1,
        0x0A7Dd6591271b5dd1E73Ccf5aF6895B6A370D297,
        0x07B0b1121aF252B5e2AC3e0899350656b9900eDF,
        0x6A660c35A38D7c23d28F8f37e2eA8Db0D9133518,
        0xD82f3ea3c688D6ba92A9F22e5DD2E78230940cc3,
        0x5B1700e3F1C6433Ce6317A82BB40F22276E6e0d1,
        0x860164830c7d3Ce6758FceB7Be95701175cb2e6A,
        0x45328d856Fa2E3694De5896157214E6a418fA217,
        0xF72781976cb2fA2c81E43D23392Daa313FaB6B21,
        0x153AA1106140DB47120065819644E753Ca7F8854,
        0x23928DE1688a7B9Fb6fF143f881fB03A70c187FE,
        0xDaE6B3Ea322EA51D18A766F269CC86a13592c082,
        0x86A09A23688c19258416876B7157fE11F354c3f1,
        0xDFe459eEF79721E5551c7778B54f459E2A113d31,
        0x42175856652185ddDBD5477fBb1f7f4FC446847D,
        0x850db8b32D5dD815F1E3eaec65D9898D56C1C185,
        0xA476fa671F7e5ce0d7C5bEFd7Cac8042608e15DF,
        0xFb7F0808000C30d28aBA61Cdb8b4eE03c11653a7,
        0x9Ad2Bce03c45E1463a4f76864436A3048086546e,
        0x3f2c0f1c8Df862289c0bE08a8D1003449a968492,
        0x3BF2fE6BFB2c713fd82ca4b93f1Fbb507A389671,
        0x8924e4185aD0317f0C9A8d3F92E9076AD220D4e1,
        0x97b28492da285dAFF9153fE89F354E7547e4206E,
        0xB9E60A72a70B94bC74d4de1a89d5001Be6579cb9,
        0xB4600da0048D2C5002f8785A4Bf3fa8C5B41F412,
        0xDD36ecb4840432EACAC61301Bc234f917Aba84A0,
        0x292B1116753C7aFf68111D35227621e591441A6e,
        0x8F867e50b06f0Cc88B7b34C35f85BA9e567A280d,
        0xeE78f64E1613DB75A4625C4A18095BC269c9379B,
        0xd5323d893D721954B2d7bE195279cB2e08f48342,
        0x0764dc400C280FF2B6D1F0582969C0c668271340,
        0x79b505e246b66B1B800C20B6fb47b835053C971F,
        0xDF0DD57Acc0509C70665C6Be25263179E9aeEdfa,
        0xa43de1705b141fb211D52cF41B5edB76eE2502c3,
        0x9F0F6B0Eefe8Fd3594688d55BACd2a876F25eF36,
        0x1A4394ad3d5B6A40D0528d586f2eDb282a847399,
        0xbbE094AC19A523176Ea73924Ca18C7906e23d954,
        0x56c945311362B2Ad79BF7764c1b7111538BB58F9,
        0xcb9C3b903Eec023E39Ef6c719C9C6D0C4F65A154,
        0xA33453aF2EAe9EDF9DA96A54fB0401C86E240D69,
        0x4985bB31cc6B9309F616Cf0250dA8172aD744363,
        0xE79e09ffa6ac702D15c8bb71B136df55997C4A69,
        0x282f9E0a7A135B6b2812ec5842A57e6C129bAbf5,
        0x5B956De9d2B82f50C8F4ee54DA478a7fE8E21A22,
        0x661A49476C0821Dc790972000ea941C3e851e7Af,
        0x584CF1A8825990c69b7c02A8e2669a551A1692F7,
        0x877adF7A6d29A4678Dc86cBa270A2C5257B6ECc9,
        0x1225a95CE4f6E9e27987A36FF5939aD9Fb2C967b,
        0x57aF013384d969E4A838FdCeCf6deEe1D56172DF,
        0x602b6f59F56a1008D76cB556a974ffe84266B5C6,
        0x551Cfb7D44B0b84B9608B3480FE727f6aBA2dE02,
        0x974b20E3c2682a3dd37A01645aC5165bbcA623F2,
        0x31270810b7A0A76CC4664c76D9CBc48d85bd6505,
        0x82e129173f19Ae25f8D4AA2e6e710E60bA55ED96,
        0xDC61B2b6918ea88a977D2F8701b029b25496ba97,
        0x0a35EfF316b5F24b4b85a0252f1Bb09c416953F9,
        0xe4D441ffAFEB5A3f9FB804DE42d4c80579010B3a,
        0x5EC90Cca6069bc4C5ABf5D5AeD68111B2cDA47fA,
        0x6E69BB2c41f78186DD05d1e03c7EA458E88A2211,
        0xd26e712EAA4d47b89E740cD1A65322f3331C3EaF,
        0x58879266350Cc134D1073B5F4E1ADF42B4420c3E,
        0x5F42B1CEE8226A2AA674E937E9E69fEA26060D2F,
        0xf822C406f9c8F92C3C17F6c470B69faa82D3c26a,
        0x7d4aCBE69448fb96E517eFC9d203aeAAdBbC3057,
        0x577Be827A11Ec1E2f5dE2A6A05D92AC297bF56e8,
        0x031F30ea86262EC24091fCCC0CF628d381c23Dd0,
        0x716E9eda68773330809149934F3d1B0aAd766d72,
        0xd5b8b95fD69934dfDDCD3c3755931F755bb8E0b7,
        0xC75479EdEa49A0e4a12D7bFe467d7ADE156D252e,
        0xD79A5d91b4510cd26103591F83Ccb2268715F664,
        0x2fD932137355F5D04d7D84E13a9637739E1f2909,
        0xE484a9d4E2b4Ecd2375EE77872241801dfC2aB4e,
        0x7704B95D00e01016bE164a32ad37a20Ae8234b89,
        0x018f190e3e63900348b9F13e37a951888C4a5a22,
        0xA862A247b17797B74148219c66aa11f8B05ce9AA,
        0x057C550456375Ac5eBECE93310E0a4bB0F8c973b,
        0xB9E212C037D29A4afc0de955c01820Af62A18DF4,
        0xee183D9E1e2D133648829b37f5a0aB6436628C55,
        0xCb4E359afEdE075aA70578B34bbcCe39EdB47B3e,
        0xdDe8aD73BD6BcB7194445476228444B46De05a55,
        0x46D61d15C2c574163f2ec16382275A6835Dc640F,
        0xe1d59D7edcE98Aa7444b7383f8C27d4ab3e19eB5,
        0xE340015c155051A4362c8F8930030b9Fe0CB5950,
        0x01b70d6C0b99B5374542a709B852739c00190Be8,
        0xf9e4d2291c965Dbf3CE1E7d66c564CC96D0F9Cf5,
        0x61BFb853794c1E7d7CfaE6374230AE4763df7247,
        0xD0F061A500B0eBbfC60f563a53710013Ef0470F2,
        0xdbc898A01c6B6b9E5F73aa321BE32FC5F136C69e,
        0xAd8802f42E855E49E09503bb8bd2c43478273Ab7,
        0xE5AE91c6267f22D1F5AA50aC953025a7A36ed36B,
        0xfF47e41188Ed3B6598BD30730EccaCeF47985e7D,
        0xcf89bdEF66A5C070691D2666855DBb5bd3aC6680,
        0x5221dc2c8a9bE3e2c417de0Ecc78326bD5E3c34a,
        0xF25b91D0773ee199810ea4A5899F8Ac795cFd849,
        0x41E5D23dfdbf3AB6563E69B63BC74CB330f426c7,
        0x9bC5536b6EDD37fCF15f5E44e0a56C68397f5CEf,
        0xE6A9eb7aB060f459461F0F1D472c3350cE07Cb79,
        0x648d7BF538b204c160c15733aBDB915d4D7fC822,
        0x9eC51c8C70409783ce306B3bdFDa0D7E7Eede08c,
        0x83b0B5266f5dB6e6C8ac226774FF41F90bb629b5,
        0x368B6f9930B2306D1BA596A3aA96997bEbbFA3a8,
        0x3dF9d238f6E583508c3Af0e5bB84f4308EC0D245,
        0xb006168ae893A26A91c909BD09cdDD6a3135Bc99,
        0x4E5DC8CaA8BD8E8aB3E5cd64623CF7432231DE2b,
        0x7A3fA094a13fc9Ce247f6c4369Fca88b26954856,
        0x1C00E5AECB22744Bb5968e3307C2B76Cb221fF66,
        0x967604E4B0CA0A9F5F26728e0cECcca52fb173F7,
        0xdCA1080f5f82ED39d8CFF736A3a48B842Db8A371,
        0xfb2B667A8EB1dbB68fd2fC45a43AbB5092de42fd,
        0x396D404D6Aa15D858A490cb2b2861dfD030872d9,
        0x670B69e85d96c85D00DE19222c4963898d685Beb,
        0x97280268dbA80f2d32683b7c0662F26Eb27DD175,
        0x2F08EA7Bb0f4b13AF7ce135f73CbfA3eDA567B13,
        0x54f3deaBC915EB00320a3d81A37540b3a313D5F3,
        0x74b98236595Dbdd71E0CE6D628Ad20EA2300D3dE,
        0x56c7a4bFDbDC57C0545413D12a30125FA651Db25,
        0xD358b2131c5da0071612eFb171bbA94bf22c559b,
        0x63d301648c7227C8F39DA41Cc3941FFDBb3aB08f,
        0x0B6A5465f3f2D686d9A263c222a99F4AEfDe8b03,
        0xb604ADF39e054243aa08840f66226a78fEeDd4B0,
        0xdFb9131B0B8Bf0ADdf74104695d222c9f5E663e1,
        0xFa22e911123610eFC78456e888cc682d601f6b54,
        0x848a2480cD4c03dfD2217fDE2d157aCea03553Fe,
        0xcab88eB7a2Db56Df92E0C117Fe516dAD872061B1,
        0xa3975ebd0417283Fb9aCf2b733995B0dF9570447,
        0xEadC6305572e8b396551d40E0cfeCf0B8fF8eBF3,
        0x37cc6965B968bd9798C300e6086eEEca2b3B905D,
        0x56D3f3a73C48391F413E1D9353165FdB0C7dda3C,
        0xc83b44f273225F9438cBac3Bd0454b43851938e4,
        0x3aebF17C58C425a4Cb3789cdaf22eBb0CcC9073E,
        0x6ff7af175B38973731019B5031BbC0b56755D9BE,
        0xc886dB8b8CD260f5ee38Ba3d8f8E9324EE27EA33,
        0x573D92340A8cA8A7D402f0eb1DD35D9077dd07E1,
        0xF5CCAf60e2c9C15C7c91BDc8768657Ac0688C8Db,
        0x4AA781b19597aF4f9b1f623c6c02e4124E007592,
        0x7F4AAa75F03d1598B092aE0e323Bc430C015CCa9,
        0xbD14b609C33c8e5A1f09a266b2AAe1096be9DdBb,
        0xEB522A22dd782ddD8167E020e107292300490618,
        0xF3fcE30d685BBC7a40Afa2c1C1296256B70a1477,
        0xBA21f7FFfFbA579ad685f95631f09ceC7f331f03,
        0xaf32e3A19A551487D0191E07C939B0ED18eDA1f0,
        0x2C4e3C9FaD9c396F470655A6bb0916381d07Cbdd,
        0xfaeFD394BFE03e61AbDa9e295d7c64687eE73B28,
        0x52A11d57D740A0D7cEceBc53ab16440E8fD6B2B2,
        0x7Af047Dc65917aCD86D24F3F2033a002473bCcCe,
        0x14F64b652948Ed2FEBde2517858644d5C15a6d7f,
        0x867a5a7E70457AF6C8250820589c4E4B928b1bA9,
        0x3b9e1E348fF80fE79c18439103c5c53A0fEbbF43,
        0x2F8FA4fb6dE5a697c3a8344Ef62A6A168a31D66a,
        0xf558be7A985abc32b0b2bA8b0ed6562151000e41,
        0x5FE20ab75F748c887B1875231E4A510e77Bc5910,
        0x48327499E4D71ED983DC7E024DdEd4EBB19BDb28,
        0xbDf7EcD3938bC86373D15709fE09DcF9Bb677ca7,
        0x37b3FD2E17232d28b2b53e345e441951Ca887280,
        0x9B26F0F8a259873922d57169C542306DC078782a,
        0xE4eFC361F134D07634a3275ec2A585985050e1b0,
        0xEDcF12b46f57207Ec537Eb73C4E2C103A32B233A,
        0xA79De3041754FE0a82bF6106279B29De1F6A03Ab,
        0x0C04a6db771fd8A4ae71BBdb3209c2FA9d016a9c,
        0xFfc979bf6ed9785c57A262296Fe57eE666f66B01,
        0x2464E1127b89257011Fa6cA06FC51b3ec0B093d5,
        0x6f50bDa124024Ce6837cb73A20c8B96b7Ff69880,
        0xe0ABe059bF26b130F861F3c9fe48a21A57300390,
        0x2C50b665c3aCC7ecca9Cd9634C9afF5e8Ab37815,
        0xb15e19ED53f82574f99CfE575Be454db09b876eD,
        0xbd2c152256f33805c8581c7DD6F68DbdE150994A,
        0xe3F42af201Ec36992a6B89E0AD6f814B901d1128,
        0x78e55c6a3B60A903eB0D57104706B5D69fBDf4FC,
        0x032Ab8112Eb491A3e56D48B836b89b1F0c78717f,
        0x9788D64c39E2B104265c89CbbCa2a2350e62701d,
        0xC9fE451251398F7Ba82296DD6eC2E3f43ee8d93F,
        0xd532962FD7976880FDff92DB9Cbe48a7369b1fc0,
        0x0da4d20e6b7Bd947419d821BfDa3D8ca079b86f1,
        0x84fF759Ee0B6057506f36E5e908ab73877C9263c,
        0x5C9Ce53738967e4D422f0f6914d5bE496F9EdD2b,
        0xB09Cb3EC75DdbBd0bC9A715D703ea84a27a99D38,
        0xB71E4596686608aA05581660187281A00efb81Ff,
        0xCfD780ded0b05f508B98dBA7E27E11F4fb82837f,
        0x3996A7E38fa56e0A10416430e28cc28182d4B21C,
        0xdA38AFF9D34fF382F12a1De111A10491566B9876,
        0x778530DEFcFe3E28C4AC55C6ca7FC69Bf7776AbE,
        0xc34ED3F6677f694797AdCE1767aa3e73Cf48e1F3,
        0xe37D4eA5C27017C227B6bf5a9CeDA2E02c58637f,
        0xd71e4AfEDAA844E493fD612F7e9C32Cc534FAE61,
        0x747A70e778985799b11a536FC716BaF3E290bB10,
        0x642B15A995980eCcB49E6475f44975Ff1F50Dab8,
        0x186f3481dbEBA09639e1EAd65aF3457f7EFACB9e,
        0x068e9989EFF6ee3746DE4498e5Bbc0Ecc7f968Fb,
        0x03F7f1aB10e8bA1f6c3B7ea588087Ee12d44Dcc8,
        0xFEF87cbfd1F377A962a0EF8adDa5d407c5F14f1C,
        0xD909A1e32e24E806c6206CAf07A8cB3e02858149,
        0x84dDddBe34C36c894347fA3649B0E25550dEb4d6,
        0x8eda5967E823C48665C797d1E35b59B5e05162Ed,
        0xA386542F9144fEAFB0f035397E16Bf6D02bB999F,
        0x6A4406F5be648B406c0c20334E8a5DE6B4999516,
        0xD4fe5b08a436C93d076d1b0a3752C8f9b6a4abfe,
        0xe5a81738DCB83CBC73440F331659F362294Bb7f1,
        0xBA6b5E38eeE62aB0711DD020D9873316846566B9,
        0x4891baed23E9B2490dEe4bfD09c4f98579Fc08C5,
        0x764965E051b54F6695d48899506E2f26cA765edf,
        0x0d917a622ed9a5773e52cCb1fAc82A75a8a6d9D9,
        0x838AA6360Bd87c7d0A96b8b84ac107E0a49dc114,
        0xa5B0C665E95545604f0A1DD0e3ecD857a9C2D2C9,
        0x4f28E099459F200e2C6cD6cdE11d23700c208359,
        0x330331eA6b3d10aaB69b87D86478D6aB643A981B,
        0x32d40ef4928EfBcdc135B3359dFc4Ec66Ee4ceCC,
        0x51EC15594230DDf21A7EA5A4aC392BB8Dbda527E,
        0xf6A51B6c793133460B279a5E6B7ea6867FD5bd7C,
        0xCdc921690f110d077dA220121D26FD198D39eeF1,
        0xCE9D39958681fE1385FB7A3E23bFF730d90a9729,
        0xE36F023f4d7D29D51B67986089EA0d41b643Ad4a,
        0x103c887d44D81C5584053AF523002925Cc18814D,
        0x490790Ddfb169857CE80248306DB24105eb55936,
        0xd3e38c017d441558135549719f9f9C398A64FDab,
        0xCC86c675Ac9F00E440F4F80B6D27b881de0f128A,
        0xc9E7A3937CF24Ed932B69C4545a20A5966a73fB5,
        0x1Ac1Edb70367f3e9C0602dcEd488a465565F256E,
        0x3E2b71BF37cEfe64B9cde8Bd19b2c70113eB2785,
        0x0a49De8E4f369c82b5315a40Ad0AC67d529a895F,
        0xAb3034c66c30a11371E7BC05d2f2b16f8BECC110,
        0x5B8F1DaaD43D779577AC05061a6B1546a29B47d1,
        0xB16B708Fe3F85A99A253Ffe2Fe556ec4C4f8Eda3,
        0x1EF0982991493c8F3B82c7f08A047F2ceb31EAA5,
        0x0cb7a1134F45f084A060743908C468F916dA9F07,
        0xE156c1d096FEc864FF641960a262b2D8929d4195,
        0xDaEAdE1BceBF6C9cFB5f8bdcCC79C838FEFe6832,
        0x80DDf3efe08cf6A29eB917dbd326F0D6DAd85c43,
        0xAE58AA169CF8cE4Ff8FA6C24a1F434ff75c9b012,
        0x5B908066aE4cDD15778796894f4a177c6FDD8509,
        0x6d155C454C03909443f3Ab06Cc690900Bed6298B,
        0x6d155C454C03909443f3Ab06Cc690900Bed6298B,
        0xA9B60f88a82d7f8Af85F53379AaC4D7B34759f12,
        0x9Fc48dC9e0Acc7073EAdd4F37f161EBEE41F1E99,
        0x7D8EbEdDCccDBa1b070c455073aF153450C7d697,
        0xB8262145c487B328fAf14127682643ce2D1DFdcC,
        0x533950ab7F1E5BBEaF6100F2d823e23E0b4AeF0f,
        0x20B2273561D13b4e29a0F442F3430B3D226EE289,
        0x85908b2605BcF86A0d869173dF448C3afd0FE547,
        0xcE970ae1ddc10C37D079C1330fD455b6654017fC,
        0xce915E4a0Dbe5D8dFd054384C7d3a8f692d0428d,
        0xc0b7f18839091fd334315C594ccB08D26c471Fc7,
        0xba96162a8bF02b68b64e4a154617e19E4028efC4,
        0xeff59EA7b39d67cb57C606E21Ed9a4a348F8A78a,
        0xC458e1a4eC03C5039fBF38221C54Be4e63731E2A,
        0xfD08849489f0a0E665885878EAddbE28738a38F9,
        0xe54fe76a02B05d450852c49CB06427e02ac5d8B8,
        0x04f47435cb9cDF59c19C9d5E5982E073900F7De3,
        0xCdC4e5A89cc23f4e7f673a3a18c1Ed84abEC88b4,
        0x54AE40076387A68EFa483cAfBADb053123Ac7685,
        0xbf47a917254e4eFd8973a2dc270004e4e82aAA89,
        0x89d5Ac566d4d0BF14daD8B0531dd4B3de47F9424,
        0x74fa1bE357bC182c88BA77E771a5502e2b271F1B,
        0x3ec3991c0aeFd1F5De287Ac8fCDb9eDDD0DF2f72,
        0xb643c924632f71ac70a982Ebc7E4099620f076C1,
        0xB3D264380FFcf9E764A16Ee9Addd08bdCF46093f,
        0x46234FccD57237F421070E23C509c8d7f5c97022,
        0xA8a308eaff92640a33c6a075e6869e0588BE5128,
        0x7F1a4E5644E1340Db15194104eF8f5A64DF1Cf78,
        0xDDcB509Fe6E15ec45a35492686947afF08BF58E1,
        0x22586A535b975D77f2f6Af443207215eACeA6eA4,
        0x69973B44C3AE36a6803cB2D77585B8db50220Cc7,
        0x31267188D920140e3015fe285F81bA163262042F,
        0x1187d312074f9c017d6BeD1dF9754D03bA7B2Fd2,
        0x2fe50DeaCdb83Eb8beabAbC73AC8D78cf478675f,
        0x738025f325e6aB76686cC15dF07291062907092C,
        0xe68c0650A819d1c4c9f541a0dADBB457CC793419,
        0x1afe95013b5e4A017AC5B45A2649BC76b47B5f68,
        0x5609A3944FE052fecbf0a362E305C8c72531B5d4,
        0xd2055E892FAA32cF4ba2B5a33A8dBb4Fd64a506b,
        0xe70D161C7ffF90c1127dD0A03C341d429E79D211,
        0x965D5CE02c082A51A51b990b0De39857053d1F57,
        0x2FA3479F42f38078943587f45D33a9BCe36b23a7,
        0x9B03891a8251c448B6C5D55556c43c3E0C64b924,
        0xb8D781c15858688387A594B4A34f8463b56AF8bA,
        0x66ed00d2df9ee54911A90AAda0c8dfF4c169b6B1,
        0x3Dadf855b9E30e63Bee10ec4D92cbFE789E5F8A8,
        0x4820189e0C6Ae798186cA9ac48e70a7fc630Bb6e,
        0x31249c9aD60B319EaA6FdA00A84327FfBB74aC72,
        0x60670dB0663eEEa0E022ee2250aa37c6Ae427Eca,
        0x8aA69753ED549De82B82F5B1B268e6c8f96d5C07,
        0x20E44FcCFefC2215e8FFa6cD9cBDdD6EAaFdB999,
        0xAE29BEF6Fb6B2974ce79C9914889dB65E67B7aFF,
        0xECc314d8CC41438F90acAbd9A5D0c1899d143689,
        0x139932823E72Fd90543547dA33854fBC39dD1A44,
        0x2398c7Cb91A3E929B222C045e0A5A5Cd80826b93,
        0x3D139eB16d79944a98EC3Db0A862f9CE98c576F5,
        0xD31DFc43E584b546C10a8B66a363c7752086D84D,
        0x0aF0CC88182856aFD7f0d5D953c76673395fe85D,
        0xf2A38bd2A11C743c0368DDEE1cF7E155FBf41F4B,
        0x9BF89364B34A60A7935eBdb29B8Ad88Dd95C8680,
        0x4E1c94F0eE40df053B190EF6Fa8709982c10F748,
        0xDdA0eaC66073397f222DbA518c5231aE716F129B,
        0xA77AeBFa19dD12c88E7F49a09d35290025Ff25F1,
        0x29e01eC68521FA1c3bd685aA4aDa59FAe1e7C048,
        0x775A3B8AF62A53c5241c2375480521d444aE1309,
        0xf48B4C067b4816dbC0A65333E9E81CA6D8a17002,
        0x7ecEf266ED9aDa13D97A18E1E4f630E3060c652F,
        0x158c72c9fCaBf584C6324C732345b9e5080Fb725,
        0xE36a124CaA7Ee0b75A96A934499CE68DaC6D9562,
        0x0d13A9e6eA1Fcb66993C71b1ca214f350247007E,
        0xB5D4187BcF2Df95b336D59d399687A101735959d,
        0x6cC4A1044A6fB92b8e0338363728dFB9644879b4,
        0x050EF81B1cC32f1d3EC9b175Ef9e39053c156B9E,
        0x564820A33AFFF3513b28E2fA6Ca1346deE342cE1,
        0x07eD493a169956c953b1704E3e27368895A57C96,
        0xdf09092bAe5C265e404e0a8Ce01eBF341481F531,
        0xF5fd651C3193F5fe165eeB828Fc52Ceb720c5E34,
        0x156D9d0fF226B6f08D253FDcDD28A0a69e301607,
        0xbbE094AC19A523176Ea73924Ca18C7906e23d954,
        0x7464932Bd227B88cA5A5aA4903dC60Bfe2D77C5F,
        0xF325Ede0886B9784FB8CdDf0a1aDD21318da126A,
        0xb11dE9dbd61A5A54ef2B23A4Cb713Df85DF08E70,
        0x5f419F4Fa688069e8175888045c2C51aB7A35825,
        0x8b59ED2CE3731a3D4e7990CC4FA12f59a1Fa7300,
        0x489F40552a9a2bc3d2718Db5417f0955675e6cF7,
        0xE6e2731FD3479F5BC76F72C78b368C805abAAa1a,
        0x83448a9cdCb456Bb58577C141Cd77e311244A156,
        0x97341010d9DF19727f458128639Ddd81F2b6E5dE,
        0xa02d34e0f2235661F4b46b8A7BEDB42c4cce104b,
        0x4577Ae2d53ed0D340dff17fefa824eCbcFa2cE6A,
        0x55E5C1d069Fdc0489fcfCeB0564D29acdBfAF386,
        0xf3415D76F984cE7296Ca9cef0F83511388D62a30,
        0xCb5A84C0fbd65B8F00E5c9ccdFD0f14813b3e6c2,
        0xD7dEA37aDBF6888ef7a9a4035B0EdF36932cf0eD,
        0x42F30aA6D2237248638D1c74ddfCF80F4ecd340a,
        0x51384E26aabACeBb2e770cfe0E0F04f2feCB25cc,
        0x43568F65705bDEEd4082153E94205e40a393b844,
        0xDb5D099a6d2f2BC090Fcd258CC564861d552C387,
        0x698Fa8dFa821489CF4B69225347F28A56E3c3129
    ];
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerTokenCount = addressPresaleMinted[msg.sender];
            require(ownerTokenCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressPresaleMinted[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}

/**
    ["0x4758ebEd66Bba81058efD08d1ea5a471fE31e1B7",
    "0xbE264cC36eb3cfAd71fa269f6b4960586393135F",
    "0x2fDB18E9FFDFCa350B0Aeb7CC799E1321664EDf7",
    "0xb50e6eD73323262E1750Ede06213C44CC09063D4",
    "0xDFe459eEF79721E5551c7778B54f459E2A113d31",
    "0x4A79D7D3E5C0C554323D4134425ebFEA473536EB",
    "0x974b20E3c2682a3dd37A01645aC5165bbcA623F2",
    "0x775A3B8AF62A53c5241c2375480521d444aE1309",
    "0x29e01eC68521FA1c3bd685aA4aDa59FAe1e7C048",
    "0x0Be12a0fE70F24f054a5565956D71047eb976dB0",
    "0x602b6f59F56a1008D76cB556a974ffe84266B5C6",
    "0xF29438cB61ac85564329F0e470e90a7247945a0D",
    "0x42175856652185ddDBD5477fBb1f7f4FC446847D",
    "0xC76B852AFaD99eEf4338561246f8a2C327AFab0d",
    "0x4b41AA10bf309aa7b5eB30e18263fd9963434F2d",
    "0x1Edaa6011c0187B0Af5516ec35BC0a22e2994C31",
    "0xcf5931a325d0FF94ecfF3f946c283F05634aD106",
    "0x608350082ba3766afefe84771fd0be95210d220a",
    "0x3BF2fE6BFB2c713fd82ca4b93f1Fbb507A389671",
    "0xf85Df24BEBBf98758164cd24831704cF1707c656",
    "0xd6bb082d1167acfc4bd856f75cacd9aed634c724",
    "0x1d008783A469Cf5D017f467fe139695040d9B465",
    "0x0565c501640ccF3E1cc37AA3E4241bDea98010c4",
    "0x2Af8fEc81FF8822170E3263E9D07F88D2F5f05c8",
    "0x8f0f3FFDfa8D418Ccd8F2c7659efb25980Fb736d",
    "0x200eBF3C9cAa6c762cbD0f1f420830e793C8FA88",
    "0x7DC78F088d1ddd30d75aD6205893Ea2Ff5B0a8E4",
    "0x98005bF51B93Ee31309c7Dc68783EfbB47B63D1c",
    "0x7140ff1BC29d56e2ef0a32C078f4f0acbF7aB0Bd",
    "0x88b4C088830a6cfed3bE2d5A6aaAcf0482ACf561",
    "0x0063146925Da753F393bBce6522e87dc524e9Bd2",
    "0xf95699b2c0bBe33195fe1aBcD97171d64F817c35",
    "0x3aebF17C58C425a4Cb3789cdaf22eBb0CcC9073E",
    "0x89bAF7A6516BE419bAc84ae10e7857BC33B25f8a",
    "0x23D5EEC14AFc9d642c41109b0C7e0eC782990411",
    "0x672CBFF03eF5A6D0B4AD736EA181CB6c0b467c88",
    "0x791C67718E70eEeDA196B1C5219f9892551fbC9A",
    "0x26057502EbBE02dDD5D0F0878b1490B3ee00D9eb",
    "0xe1E97e9554e3C1269b82c702F69D98da8e49f0a9",
    "0x945A4cbae4eF06C0114F53457404A49a6765d9a6",
    "0x7e15893ed2ccFcB8a34C0b6557e7107322C32e59",
    "0x40d6F4B4d5Ef496682c7C3fCC0dBfa113E5B0336",
    "0x9fF09099a9126d131aDcc594857405380c6FA3b3",
    "0x8616cA1705A3a3B70cF53638012d44857A40CD78",
    "0x1EB4E259EAc3d97ceD2d88923eB3CCa5139019F7",
    "0xBfB4848894e6C30d9121B6460e13287d96881391",
    "0x3302545161633a3B55D11496fB38f0aa7b10ab3d",
    "0x9bE87B0edeac66d8b8d262Ee970F6F241bA5c2C0",
    "0x09f7365d1ecE51Ae2821D8647Fea73477AA9E705",
    "0x6fFfb61Eac20041F442A56D10A5CdB24deeabA0e",
    "0x1b46D512E2D22cD4c5186d34525EE2bfAE70ecbE",
    "0xB69Ce5c5a14DafbF476F16f2918ac3c860242fbe",
    "0x5609A3944FE052fecbf0a362E305C8c72531B5d4",
    "0x1Ff5a5c5eAFBF880b092ED07aDa724169b81148F",
    "0xA345710c3C720f20d571Bf6F03eCbA434E9FC92B",
    "0x883405eBD164aBE509CFE0e2E14D3D7C80d3BeF6",
    "0x895D4CEE80523f8e52777d5fb87B2297495d41e3",
    "0x69Ae4a613A0aBf6fBb2bF2AafF91AE2c113B49d3",
    "0x1E87fee9DE0C6453c0a405eb87BaD0d3c5Ecec0f",
    "0x25A18C68aF97eE250980Db306B68E9D3Bc0A184d",
    "0x11E17Cdc4C298f3B2b5530b6beCf95c02954aE51",
    "0x5b7Cb6CE6Dc5ab6b3bA89483De86e8E403f22e7e",
    "0x5012805693dDd6a5B13F7B103a0F17781cfF6Fe4",
    "0x7aAF6A9d9d48b52530acad957deA3Fe05abA6313",
    "0x56b229Ca304507A17abB26A80d7a723d8D8513e0",
    "0x3fB840c9F362407Eeb62b221f712D78fECCfC80B",
    "0x570A4aDF9Ce7Ad402b2BA7615909Bbd45532A8De",
    "0x2B6F5ee4d2275DcC1CF08EC01baa5B4D5b967d0E",
    "0x9a951FF7D6b1d00216B4242696C57A3232BdA1E6",
    "0x6405af00280152866500E4ED91ee462E7f7588bC",
    "0xE85DBB09A699c0543C363c3f6E51ef0049e3edC5",
    "0x3B16B077aA86baE7eD45c41906Adc4fFAcccFf0E",
    "0x643B34C9d7C851bf69Bb766615F860A70f4C9C86",
    "0x77fb9C7D16BE80744E29E8F7De6Fe82ae6c9d11D",
    "0xb84d84019Af5EeBf81b378E98567068dCB9B622b",
    "0x4Cd919427f745B40096EaBdF38110b42695c41cb",
    "0x62a8cA10762DFa01475B7c5C232362DF28861C08",
    "0xc7322ee2d0E4EBD824adbee58F38FB51352ca8C9",
    "0x6db9c794d95e63fb9bf4d12151a7e5315bdc4871",
    "0xC72F857434F0a0ca9bf08FC2750A2B874e201550",
    "0xA959735A1aF98eB7596FaBFe6E135E9f0ABd7E4d",
    "0xEC1acA289F794473277aeb09a073f7e610aFB1Ff",
    "0x2B167CA199E6EBDeF5008CbAd7a21A9Ccb15c46d",
    "0x4769Aab421dE170f1f5781B9b0d3c1415645293E",
    "0xd4e0269F31c5E0ecc3fF9fd47cfF282f51101767",
    "0xA2cA851525d76e7D1Ab2154292a614E0f59CA67D",
    "0x47D0DD1c5A0125F6e52fBAc3e202bfec60eCBDc2",
    "0x88AaA2027Abb20a9180ae051Fd0662226C148E57",
    "0x5b26888b2fD5C617e95Df5bB7b22644Bf2Aa5930",
    "0xb604F3b93882dFaEDc878154cea9892f78e0Ea45",
    "0x7438319E0784612dE7804e303baA52Cb3c8dB5F5",
    "0x3A87081794fE7506ae0F7cc30a64ad5FE82dC47e",
    "0xA95c8435846F82F4D35d57f9973A4e0D96E69a22",
    "0x0D3Ef24cCd12827CcE51bcA43Cf9EfB78380429c",
    "0xE51341E05699Ed92C4d0402F4E955862423d3aa8",
    "0x3d57e3C0fe386F57766995F84BB4eefFAee72bA6",
    "0xbdfb224D5e089d85366D535eEFEE5810F23e08BE",
    "0x3f0749EE9a009EDE06A95d1e19986B9bB8D3b0A8",
    "0xb0086CEd87CeD727E01c3b15E54D7Ef04301aC31",
    "0x58C48A54a36D346cB71D63ACa5599166bAd21851",
    "0x0E36299e2b2CA72a777567dDaB019bc0Ebd92965",
    "0x8F6a7A97f3b6CEE0E374b38292Eb87723679C882",
    "0x68710ea91627232d3b7D4083c7aeec912cCDc2A6",
    "0x8A029549B53b04B1003f25e6E3c830E5Ed477509",
    "0x96F91e3eB4840140eeDC51126A4DF1b51B6bc746",
    "0xB3D264380FFcf9E764A16Ee9Addd08bdCF46093f",
    "0x41cf769131D4F75C662c53D592c91d56fFD45a76",
    "0x12ADc0CFB830f71D52ee600d952976054557E5C2",
    "0xeD947a0F9170DE48e347F657762199F7E2992110",
    "0x3f109fca5C317Ec9Ce06a6E5D8e9C7792737bC7b",
    "0x3B1fc9653f03789BC399fC343d8D5B8fC1520EA0",
    "0xB98C60Fe6736454999af07D642c21Cc0Dc443f25",
    "0x6d6Fb3FAf9432AcE1900A3B9F66ba40Ca5cd7C0e",
    "0x14378456B32f2Dc8f41D44b3613b4D6fF9eA2b83",
    "0x12AcD4607393F5cf772bfF4138107325d7c4Ca09",
    "0xF4151e12614478c94Db8Df53F1E1Ad12c778c4cD",
    "0x662195b64795a74f0e4b32A64f0B220010dd5562",
    "0x959786a8128F5FAB24b86871266a36bb0DecD495",
    "0x6BA167a348DA1d17C34DDa4f94CaD7C6155C5702",
    "0xc5c0E639EE5d59F40f14BC4110bb0BE99C06988e",
    "0xcF991E3f8414A8949967D51550683852D47F88F2",
    "0x63294F76dD7E0Dd78fb3c430281B2DAE494EC926",
    "0x445a368791A20735860d42a88987F29BF9d22E01",
    "0x4DB6cDd13653736044C2ce25751FC5656ca4763F",
    "0xe576b9C06Ff11869127e7CD97CcDE7141ee004BF",
    "0x9d45Aa7D07d9945bD011E59Ad3Fc9aCD380a4258",
    "0x0715C3329e38790C853F6fFD824f2771a02D37bf",
    "0x8d160063E641252F4B424A9Af89E88B24e04e444",
    "0xd6957Ce22991b02e352EE11E94FBc7800d5918e0",
    "0x4cec1074e2A72E6943a13CE16dA7589388bf94C7",
    "0x2A4E9CeE0b1c25f026A0E77Ca5931ce7BAb20a23",
    "0xCd6d1513C6ebB784661Faff7a4b3CD595C555cc6",
    "0x3eb8F88422dFd2AeCd1969E24443281cdA239aCD",
    "0xa43589Fc8f89f02AB33f3a96De1601624f7Ee06c",
    "0x84096Bd010Fee8F97C307bBDAa57bDd98EFA93B5",
    "0x3f8ADbe12456188433d0CF09E0472084c4F29671",
    "0x4fDA56C38fE5f6752106D4bAD20D50D1331744c5",
    "0x5c9E61218b86c3a698F5F2B9802eEAADe1a09fe2",
    "0x46d3318E8E669a311A8535798213Cb6E3f321cDc",
    "0xca04b727f8b776c1F62616448aa2A0bE25C82ab9",
    "0xb94872bc787343e194c069FFeB7621cBea41FF73",
    "0xf35341818a13b783664053b1b0f834e658dcba87",
    "0x1cD09116Fc412247f09f4E3CA562D24d1866BBe2",
    "0x66e31A557cAac68d3c218ffD0ebE6146D57F66DE",
    "0x9eb5b3414B197F7ee1fA7C036931741f081897D4",
    "0x02Cd407BD1216C4b227e20dDaB1837f5A74233E4",
    "0xDd6969dC2ed9256cE3c399315a685cE4D4E5F720",
    "0x52D3e1E323C1c99E049Ab2639B5D0F4d4fe612B7",
    "0xcc747443a483a0559F666F5d3D4B6F7b6d2280E9",
    "0xDb4eaEC2bE282909E46aCEbD57ff89D8dFecC13d",
    "0x5A884D400df60D92391185D39BF169700A049539",
    "0xAa74BE7b5Df3891fA88e383Db17A0D39965ABAf9",
    "0x31e4a3EF430A729A133483AC783963CE41ceDa3E",
    "0x7b207d27FF26069E48EA631518a2E784a1460cB0",
    "0xf329D15E72a6AbeD9F9290F1065312819f43727a",
    "0xC9d60143128cbAc15037cF555dEdd23CCA7e4393",
    "0x29d6aB0E6316F90766c0A158eb204A2Bf60AC23d",
    "0xCB0835D01fd2c20f68fA3B918d86343fE4EC1A25",
    "0xabb893748F86B289E67D01231fda5015BE02Ab83",
    "0x9c4b443632B7d511379fe3AcA3DDcfA8F197b302",
    "0x37C86E28548ddA9267Ead1CA363D6441c0bbCd6e",
    "0x5D3b8520dac5b0CCA62Df147528f04Dc39BA23aa",
    "0x0a06C890438F84e9848AF76102341C7A7E2133AD",
    "0xbAC1b29acB014AFab23Dca3B7Be6Fbe90256AB53",
    "0x637ef5aA5CaeF174a2b45EcDC560a1AfB16668bd",
    "0x2C434867d28Da51549Dff76fB127cE22B9aA46c6",
    "0x15af8DF7541d8d1264dd14aC6baddB04b98A89aa",
    "0x4E0A88B2bEC15a8c1cD87d79DF5D145323c5EcB7",
    "0x2749Af4bef7c7042D37DEeFA7978Dc325f461eb0",
    "0x0E1606f50626D92aBBc39E6fbEEbbC3DC76E7b3b",
    "0xB4C574334615cC5155639038b67208063cc278b8",
    "0x60b1659C8b848bdBCb85F4E4792F69C90AAa3648",
    "0x06e669e9E19D4FAE54171326A11105F4FD12BeDe",
    "0xEDa4c9B9E79011852A1D7c2105122b0c637B5b05",
    "0x9CEc27472De184D84d9872377241Cbe4009F3709",
    "0x2398c7Cb91A3E929B222C045e0A5A5Cd80826b93",
    "0x0e1b6f1b4697c885cccc9c31d076947522f7caed",
    "0xDb5e9f11d0161780cd1C2be5A1C949eaA7557352",
    "0x505438B4211D596D7B2A1f0ED47579cE474e5605",
    "0xff4c0AD1A5c616eB96b96DABF5F39C56948BF83F",
    "0x3aE6690d3b1b27A3D1aa0d399EF78edF13bFd610",
    "0xd5323d893D721954B2d7bE195279cB2e08f48342",
    "0x58491C8138e41101bFEC260466EBD3DF053868e0",
    "0x82Bf6D61b2cB35f9bb08Ec99d02f80D6833271Da",
    "0xD9587b5851cfD9917D358721Bf56C31DD285CeE1",
    "0xF3c84E5cc17E59a78F2fdd5500BABD61023aC830",
    "0x7636A5878FD870421D3e546a4b3076BaD870Ec8E",
    "0x1Dc1615b4f3a7ad3e5E340e8002bA34Ad0B773Ad",
    "0xce25fc8a802ef77ad244429387cd8eb0ca2557a9",
    "0x48302b76c0Ff2fd1cD1b698Be2a8cA5be4De0daF",
    "0xbd891dF7b6a7C2eBF4da7f3EE10e6B4642AbA2c9",
    "0xB20B5e7Dd0525dC442649C7Dee450Feda2E43C9d",
    "0xD6d57d174BE03101c29C1EB3a335559014896BC7",
    "0x9352421E3163a85Fe32CE6aaA116F3C64b3e6aD9",
    "0x380fEEA870DB5EDd638A8fe78A271FA6E707826f",
    "0xBBf17d93A2307dF43F7cC1098EFcf0985e995C65",
    "0x0C4938ec23887D1384dA8c0E611042905a366f0E",
    "0xc8b506B8150Ea6Ee0cbd7dC71034B12d902141d7",
    "0x19E34146D1719bb7ceC1cA0896ED5fA88DCEc5C7",
    "0xAe04e4AeFe095D6591c0d5774A226Bc7098D5fA7",
    "0xeE97cbF18Fc41C068eb8AFE67025353346c5fA02",
    "0x4986ac8522E8831e71439C529E514022596c301B",
    "0xc40b73C6356c98de9a32680a6466d0dAbba04C37",
    "0x94705A9d675daa924F9190Eca4c05ED6B12d5345",
    "0x92451CCf65d681ECB2294114795873e63a4a6883",
    "0x74A8bbe4329024ce3D4920474Fb58ca72bfAF42D",
    "0x95c59B9ac2c6F2eD1BFC218CB38f87Ff9d3Bf047",
    "0x338bEF2AF24EcC89261c81d3fD23F012f0ABcC4E",
    "0x1ba7852b19994145bceC6b4F94A0BBc95BcFa94a",
    "0x80b759F0A9391e64351e6b94E32c384A40D96b7D",
    "0x664E2D99df6747ef42E8a767c0BF8B8CEfd6F373",
    "0xb8ff1c4Bf352e5D2986a7c7d1196759602A4abFd",
    "0xb3244abE943ff149fc98096c8fe024cf7146A4ad",
    "0xBC82a96210555A04bdaDb29cd442F18687F1Fb9A",
    "0x3aa003558fA236B3beB9B935B85e04D150ABa9bc",
    "0x8c1D80bD49374d7d3f6cE123df2d8A13121486eb",
    "0xD3CE769b8EDda71B86CADb0d4BdBd252897F1753",
    "0xa4A0eE63Ac185Df4E2CAB3583F21a48C6d80b919",
    "0x13119eA6B582302Eeb3fe78931CD3aE9b7A7532F",
    "0x81f927795b64Eb3867Cb55D4eb47a06ffceB5daA",
    "0xdb8c009F29F8A376e7aE2Fc75D55e8C12F109aB4",
    "0x98d80eD82a3e68157139E2d9Ea6b137e9a358f7D",
    "0xE934837666854c8B81FB85F93c2ba110602b77Ea",
    "0x929B8AEC1084FaC2b6cA1239c82E5Fe78Dc79d2B",
    "0x1fCca6CcB88AFBc361f0e2a7BFd0AF7d737548c3",
    "0x2D3178af3Dfbb679716cc14E245Be0A9E5945500",
    "0xecbd13e77b74F9Fb052C8dc30Cc0E989BF3dD0A6",
    "0x940E6267bbaC505d6b902472e8D2f367b4Ac0997",
    "0x7Ac9385A9E821BDF5eEfDf0393F06aa844C5a061",
    "0x23330e0A0fd8c954DD377bC7435C8BB409031D23",
    "0x861a085492476E06077B18DD62176fbCDa663425",
    "0xc26e0041a142D8A77aba79D73b76fbFD8e627dA0",
    "0xf26C285B4AdAb350e7E46144CdEF01D4Ad2E46Ae",
    "0x699dD336AC982AF000d2171275f1DD0Ec5668C2B",
    "0xFb74ad209eB3B114C05e02c45a761aF03334E184",
    "0x727AaB0c8f805395444D069408492AC7b8065525",
    "0x2AA2DeA1cD1dEB2a67C055C5daE974EFD347d5cB",
    "0xABfe6Aa0284c548f891c5942DB2743D2dfE4D9E1",
    "0xcf800e8080C3B7F508ec90CF16e3529849CeAB8F",
    "0x80f30d26fe2c61B56ACF51f0C12eF74d09d41F26",
    "0x639638a0879e5b4151aff8a643A58B2931c2336A",
    "0x18EB2e1f8eFcFcb092B700aeA3324f00FdBa08Ee",
    "0xB49E25DfF20B4393379F7D54f0106E0bb7c7b28D",
    "0x33bF863e0DC4001ac96c80f4aE8B449B8aD48F88",
    "0x126B9489FB9c9BA88DcBEa78AB476b8F910F6D6e",
    "0xdbc898A01c6B6b9E5F73aa321BE32FC5F136C69e",
    "0x70Ddc7ba0c36CB41EAe05EA86221C9b5f5709db3",
    "0xA78153D70acFdD2cbf32Ffea9D84074D9d6a5DE9",
    "0x742B5F5FD0c3D32cA23D0bcE4095Ca652723A549",
    "0x55a05dedcF2344758F6022D9648494DF8F61C9f1",
    "0xf3bb575269d16dc7a11de9a6a34175bfb90acc3e",
    "0x70cDC5CED681EA2D965D72C71d668dBe6235B24c",
    "0xFECc5C778B6634A9A173D8dB932181666dD95ec6",
    "0x3828330e1a4DD3b97E976e249C7Bc8979eDA6B32",
    "0x7b01D04faE0aB2479344Be8dAaEdd0Ae1b04486F",
    "0xF9663df170979Ac64F5806b101C894a1A8F683BD",
    "0xb57c0b622A5a5FCdeb22E49953210fd4c1DE2194",
    "0x9De4E4cc181d9d1966ab58E07378EF225425ccF0",
    "0xc36E7E0f9A102308C52a53004c171B42AC6A7160",
    "0x75EC2e2976decAe6303b7C6AE6C453C3A98b4D72",
    "0x07F9046B8f8F3b93ba688F97D1a85bfd4b08d9A7",
    "0x016D4412299A7B77b61078E73BAC9d6de4821000",
    "0x53B581f0F916e09ba07B6204e8720a1d9323521A",
    "0x9D2a6Dc7aff9950CF725241441584540B2ac1ca5",
    "0xCA7080A463706725E1632145cfcc7dB53eD25f96",
    "0x5fbfe8dAB81A39A04B9590dFcEac9a93e7aa3302",
    "0x6dF01b9e66d3267F1f8949A9e35f89043FE9822c",
    "0xE876B553741a879967f8c502b757E919Db1a8b5e",
    "0xe05006Dc1369ef6BBcFd696A38a573C8C28A8E7C",
    "0xd9718542D7832B322e92Fa03F408D02a4d47C2c5",
    "0xC6b62b1688C2B3B1a12E3d222DdaD43BE379c1B6",
    "0x0e93545Edad0Ba8884bCEe70618c3D8D4D73d5B4",
    "0x4Db180f14A91d3e01776DB3cA2993676543C2A06",
    "0x4f4fca10d1863ff5fea61b8dd3e7a7f8a6bc77ee",
    "0x2f8e0f91Df5A26783633910bA9Ed4B3b7b7883E3",
    "0x9713222695378e27511779Ba00b7cBF178120371",
    "0x0475fFc635B0F1cd52c7DAEa24e7aF02A575551B",
    "0xA8f6Af28BFab672859AcF31EcA54C81a9CbBeB66",
    "0x466C40b45Fd199282EF116406DE3Ba7e548426e5",
    "0x2657344889F180A85a845fA2b04ECD5637508038",
    "0x17A985095BD612A9B6278f8dd8A6D91Ec79dD81e",
    "0x17136144999C10439D90A2aC22386595BfEf0527",
    "0xE7CCfF5De5D5bbc638394D917EBFA6a60Cf38C08",
    "0x01DaC505E000d4B87e427271Eac85B4a46B5141D",
    "0xb63ea4865cDfedF3A7bCa5Df5BD49F04D59ea348",
    "0xc3A8b0eE40098E32C1d749EBcDc6C144ada911CD",
    "0xc58374eA34717411FcE751B29498ea234FabE17a",
    "0x1c7bc5daaF0A913d922839196c08CF1d7b74fb12",
    "0x04f23CD6624A3a1E205A59DAAe3F7b589bBb56CE",
    "0xbea8e78462246f7ea4b531b4cb2425b329846208",
    "0x291B104D72Be6a1eff9cAcA557E4745c4b10b064",
    "0xD89863049aABCd4626590fdebD00aF11D8233173",
    "0xE83370D402504Ba36F0866068F0c2afA5243A969",
    "0x5475647b2393328eCd47B0256782365c7F42fb15",
    "0x59a9bB69dd15f8E932Fbd1982389f62CfefB68f4",
    "0x4F3c114735101EF8Edd81760A05bf269d2F04889",
    "0x8B1dD48344de9922AC1f24B7563fC07EBaA00b20",
    "0x0D492E61C9f4C90f144aa479892d0c25Aa934425",
    "0x98a282df175c7720e8439e6129f7a557746a3d03",
    "0xEBaB7d355f15a21fa37F4a0E0B303f07e1a320De",
    "0x45C14654CF2eAC6a7904e80Bd3F4B58ad24E0235",
    "0x42C70946962DEd7fb4489D8dd543d1857eDD3291",
    "0x60a26961E4cCb7DE430C8357695Dc6022417165b",
    "0xe9B7092940B4631c87e406EB2d292EF9a039e4Ea",
    "0x3863B7d72aE4E36B170FfFf900E5A61637011953",
    "0xa78b19c5683363dE380d56CE0A164360B59E711A",
    "0x9D2158f50307A971345F9bC38441FA60688BAA1E",
    "0xE68c542363A74369Cc41d1490C870c41c3Da6E2A",
    "0x96a603254e66AcffF3b641c461270e2b37DA67Ee",
    "0x9Edb768e329d4F6F60eADAA16bb8549d52120819",
    "0x4f186d24c29a02e633092e655d27ced9439f4967",
    "0x1bde23313c081512e10dfac770f23f6c99685122",
    "0xea9FeBaEcDDAE02967f70F5cF79688786c851463",
    "0x25A411f95aD3b558a783f6730e7C7d8E297b0fEE",
    "0x404CC659ec36E3e84B6578FBf874Dcba7bc2bF3d",
    "0x08254C88e28363BB1135f884f5B616dAEc79d7EE",
    "0x0b13f13c0E99F24b96A835B787D1347B33d87776",
    "0xAA1E92dDd28C835fe66689771d35f38947950FD4",
    "0xC3D067D6C8A5803882DFAC2dce6E2CAd0225E6e1",
    "0x0A7Dd6591271b5dd1E73Ccf5aF6895B6A370D297",
    "0x07B0b1121aF252B5e2AC3e0899350656b9900eDF",
    "0x6A660c35A38D7c23d28F8f37e2eA8Db0D9133518",
    "0xD82f3ea3c688D6ba92A9F22e5DD2E78230940cc3",
    "0x5B1700e3F1C6433Ce6317A82BB40F22276E6e0d1",
    "0x860164830c7d3Ce6758FceB7Be95701175cb2e6A",
    "0x45328d856Fa2E3694De5896157214E6a418fA217",
    "0xF72781976cb2fA2c81E43D23392Daa313FaB6B21",
    "0x153AA1106140DB47120065819644E753Ca7F8854",
    "0x23928DE1688a7B9Fb6fF143f881fB03A70c187FE",
    "0xDaE6B3Ea322EA51D18A766F269CC86a13592c082",
    "0x86A09A23688c19258416876B7157fE11F354c3f1",
    "0x850db8b32D5dD815F1E3eaec65D9898D56C1C185",
    "0xA476fa671F7e5ce0d7C5bEFd7Cac8042608e15DF",
    "0xFb7F0808000C30d28aBA61Cdb8b4eE03c11653a7",
    "0x9Ad2Bce03c45E1463a4f76864436A3048086546e",
    "0x3f2c0f1c8Df862289c0bE08a8D1003449a968492",
    "0x8924e4185aD0317f0C9A8d3F92E9076AD220D4e1",
    "0x97b28492da285dAFF9153fE89F354E7547e4206E",
    "0xB9E60A72a70B94bC74d4de1a89d5001Be6579cb9",
    "0xB4600da0048D2C5002f8785A4Bf3fa8C5B41F412",
    "0xDD36ecb4840432EACAC61301Bc234f917Aba84A0",
    "0x292B1116753C7aFf68111D35227621e591441A6e",
    "0x8F867e50b06f0Cc88B7b34C35f85BA9e567A280d",
    "0xeE78f64E1613DB75A4625C4A18095BC269c9379B",
    "0x0764dc400C280FF2B6D1F0582969C0c668271340",
    "0x79b505e246b66B1B800C20B6fb47b835053C971F",
    "0xDF0DD57Acc0509C70665C6Be25263179E9aeEdfa",
    "0xa43de1705b141fb211D52cF41B5edB76eE2502c3",
    "0x9F0F6B0Eefe8Fd3594688d55BACd2a876F25eF36",
    "0x1A4394ad3d5B6A40D0528d586f2eDb282a847399",
    "0xbbE094AC19A523176Ea73924Ca18C7906e23d954",
    "0x56c945311362B2Ad79BF7764c1b7111538BB58F9",
    "0xcb9C3b903Eec023E39Ef6c719C9C6D0C4F65A154",
    "0xA33453aF2EAe9EDF9DA96A54fB0401C86E240D69",
    "0x4985bB31cc6B9309F616Cf0250dA8172aD744363",
    "0xE79e09ffa6ac702D15c8bb71B136df55997C4A69",
    "0x282f9E0a7A135B6b2812ec5842A57e6C129bAbf5",
    "0x5B956De9d2B82f50C8F4ee54DA478a7fE8E21A22",
    "0x661A49476C0821Dc790972000ea941C3e851e7Af",
    "0x584CF1A8825990c69b7c02A8e2669a551A1692F7",
    "0x877adF7A6d29A4678Dc86cBa270A2C5257B6ECc9",
    "0x1225a95CE4f6E9e27987A36FF5939aD9Fb2C967b",
    "0x57aF013384d969E4A838FdCeCf6deEe1D56172DF",
    "0x551Cfb7D44B0b84B9608B3480FE727f6aBA2dE02",
    "0x31270810b7A0A76CC4664c76D9CBc48d85bd6505",
    "0x82e129173f19Ae25f8D4AA2e6e710E60bA55ED96",
    "0xDC61B2b6918ea88a977D2F8701b029b25496ba97",
    "0x0a35eff316b5f24b4b85a0252f1bb09c416953f9",
    "0xe4D441ffAFEB5A3f9FB804DE42d4c80579010B3a",
    "0x5EC90Cca6069bc4C5ABf5D5AeD68111B2cDA47fA",
    "0x6E69BB2c41f78186DD05d1e03c7EA458E88A2211",
    "0xd26e712EAA4d47b89E740cD1A65322f3331C3EaF",
    "0x58879266350cc134d1073b5f4e1adf42b4420c3e",
    "0x5F42B1CEE8226A2AA674E937E9E69fEA26060D2F",
    "0xf822C406f9c8F92C3C17F6c470B69faa82D3c26a",
    "0x7d4aCBE69448fb96E517eFC9d203aeAAdBbC3057",
    "0x577Be827A11Ec1E2f5dE2A6A05D92AC297bF56e8",
    "0x031F30ea86262EC24091fCCC0CF628d381c23Dd0",
    "0x716E9eda68773330809149934F3d1B0aAd766d72",
    "0xd5b8b95fD69934dfDDCD3c3755931F755bb8E0b7",
    "0xC75479EdEa49A0e4a12D7bFe467d7ADE156D252e",
    "0xD79A5d91b4510cd26103591F83Ccb2268715F664",
    "0x2fD932137355F5D04d7D84E13a9637739E1f2909",
    "0xE484a9d4E2b4Ecd2375EE77872241801dfC2aB4e",
    "0x7704B95D00e01016bE164a32ad37a20Ae8234b89",
    "0x018f190e3e63900348b9F13e37a951888C4a5a22",
    "0xA862A247b17797B74148219c66aa11f8B05ce9AA",
    "0x057C550456375Ac5eBECE93310E0a4bB0F8c973b",
    "0xB9E212C037D29A4afc0de955c01820Af62A18DF4",
    "0xee183D9E1e2D133648829b37f5a0aB6436628C55",
    "0xCb4E359afEdE075aA70578B34bbcCe39EdB47B3e",
    "0xdDe8aD73BD6BcB7194445476228444B46De05a55",
    "0x46D61d15C2c574163f2ec16382275A6835Dc640F",
    "0xe1d59D7edcE98Aa7444b7383f8C27d4ab3e19eB5",
    "0xE340015c155051A4362c8F8930030b9Fe0CB5950",
    "0x01b70d6C0b99B5374542a709B852739c00190Be8",
    "0xf9e4d2291c965Dbf3CE1E7d66c564CC96D0F9Cf5",
    "0x61BFb853794c1E7d7CfaE6374230AE4763df7247",
    "0xD0F061A500B0eBbfC60f563a53710013Ef0470F2",
    "0xAd8802f42E855E49E09503bb8bd2c43478273Ab7",
    "0xE5AE91c6267f22D1F5AA50aC953025a7A36ed36B",
    "0xfF47e41188Ed3B6598BD30730EccaCeF47985e7D",
    "0xcf89bdEF66A5C070691D2666855DBb5bd3aC6680",
    "0x5221dc2c8a9bE3e2c417de0Ecc78326bD5E3c34a",
    "0xF25b91D0773ee199810ea4A5899F8Ac795cFd849",
    "0x41E5D23dfdbf3AB6563E69B63BC74CB330f426c7",
    "0x9bC5536b6EDD37fCF15f5E44e0a56C68397f5CEf",
    "0xE6A9eb7aB060f459461F0F1D472c3350cE07Cb79",
    "0x648d7BF538b204c160c15733aBDB915d4D7fC822",
    "0x9eC51c8C70409783ce306B3bdFDa0D7E7Eede08c",
    "0x83b0B5266f5dB6e6C8ac226774FF41F90bb629b5",
    "0x368B6f9930B2306D1BA596A3aA96997bEbbFA3a8",
    "0x3dF9d238f6E583508c3Af0e5bB84f4308EC0D245",
    "0xb006168ae893A26A91c909BD09cdDD6a3135Bc99",
    "0x4E5DC8CaA8BD8E8aB3E5cd64623CF7432231DE2b",
    "0x7A3fA094a13fc9Ce247f6c4369Fca88b26954856",
    "0x1C00E5AECB22744Bb5968e3307C2B76Cb221fF66",
    "0x967604E4B0CA0A9F5F26728e0cECcca52fb173F7",
    "0xdCA1080f5f82ED39d8CFF736A3a48B842Db8A371",
    "0xfb2B667A8EB1dbB68fd2fC45a43AbB5092de42fd",
    "0x396D404D6Aa15D858A490cb2b2861dfD030872d9",
    "0x670B69e85d96c85D00DE19222c4963898d685Beb",
    "0x97280268dbA80f2d32683b7c0662F26Eb27DD175",
    "0x2F08EA7Bb0f4b13AF7ce135f73CbfA3eDA567B13",
    "0x54f3deaBC915EB00320a3d81A37540b3a313D5F3",
    "0x74b98236595Dbdd71E0CE6D628Ad20EA2300D3dE",
    "0x56c7a4bFDbDC57C0545413D12a30125FA651Db25",
    "0xD358b2131c5da0071612eFb171bbA94bf22c559b",
    "0x63d301648c7227C8F39DA41Cc3941FFDBb3aB08f",
    "0x0B6A5465f3f2D686d9A263c222a99F4AEfDe8b03",
    "0xb604ADF39e054243aa08840f66226a78fEeDd4B0",
    "0xdFb9131B0B8Bf0ADdf74104695d222c9f5E663e1",
    "0xFa22e911123610eFC78456e888cc682d601f6b54",
    "0x848a2480cD4c03dfD2217fDE2d157aCea03553Fe",
    "0xcab88eB7a2Db56Df92E0C117Fe516dAD872061B1",
    "0xa3975ebd0417283Fb9aCf2b733995B0dF9570447",
    "0xEadC6305572e8b396551d40E0cfeCf0B8fF8eBF3",
    "0x37cc6965B968bd9798C300e6086eEEca2b3B905D",
    "0x56D3f3a73C48391F413E1D9353165FdB0C7dda3C",
    "0xc83b44f273225F9438cBac3Bd0454b43851938e4",
    "0x6ff7af175B38973731019B5031BbC0b56755D9BE",
    "0xc886dB8b8CD260f5ee38Ba3d8f8E9324EE27EA33",
    "0x573D92340A8cA8A7D402f0eb1DD35D9077dd07E1",
    "0xF5CCAf60e2c9C15C7c91BDc8768657Ac0688C8Db",
    "0x4AA781b19597aF4f9b1f623c6c02e4124E007592",
    "0x7F4AAa75F03d1598B092aE0e323Bc430C015CCa9",
    "0xbD14b609C33c8e5A1f09a266b2AAe1096be9DdBb",
    "0xEB522A22dd782ddD8167E020e107292300490618",
    "0xF3fcE30d685BBC7a40Afa2c1C1296256B70a1477",
    "0xBA21f7FFfFbA579ad685f95631f09ceC7f331f03",
    "0xaf32e3A19A551487D0191E07C939B0ED18eDA1f0",
    "0x2C4e3C9FaD9c396F470655A6bb0916381d07Cbdd",
    "0xfaeFD394BFE03e61AbDa9e295d7c64687eE73B28",
    "0x52A11d57D740A0D7cEceBc53ab16440E8fD6B2B2",
    "0x7Af047Dc65917aCD86D24F3F2033a002473bCcCe",
    "0x14F64b652948Ed2FEBde2517858644d5C15a6d7f",
    "0x867a5a7E70457AF6C8250820589c4E4B928b1bA9",
    "0x3b9e1E348fF80fE79c18439103c5c53A0fEbbF43",
    "0x2F8FA4fb6dE5a697c3a8344Ef62A6A168a31D66a",
    "0xf558be7A985abc32b0b2bA8b0ed6562151000e41",
    "0x5FE20ab75F748c887B1875231E4A510e77Bc5910",
    "0x48327499E4D71ED983DC7E024DdEd4EBB19BDb28",
    "0xbDf7EcD3938bC86373D15709fE09DcF9Bb677ca7",
    "0x37b3FD2E17232d28b2b53e345e441951Ca887280",
    "0x9B26F0F8a259873922d57169C542306DC078782a",
    "0xE4eFC361F134D07634a3275ec2A585985050e1b0",
    "0xEDcF12b46f57207Ec537Eb73C4E2C103A32B233A",
    "0xA79De3041754FE0a82bF6106279B29De1F6A03Ab",
    "0x0C04a6db771fd8A4ae71BBdb3209c2FA9d016a9c",
    "0xFfc979bf6ed9785c57A262296Fe57eE666f66B01",
    "0x2464e1127b89257011fa6ca06fc51b3ec0b093d5",
    "0x6f50bDa124024Ce6837cb73A20c8B96b7Ff69880",
    "0xe0ABe059bF26b130F861F3c9fe48a21A57300390",
    "0x2C50b665c3aCC7ecca9Cd9634C9afF5e8Ab37815",
    "0xb15e19ED53f82574f99CfE575Be454db09b876eD",
    "0xbd2c152256f33805c8581c7DD6F68DbdE150994A",
    "0xe3F42af201Ec36992a6B89E0AD6f814B901d1128",
    "0x78e55c6a3B60A903eB0D57104706B5D69fBDf4FC",
    "0x032Ab8112Eb491A3e56D48B836b89b1F0c78717f",
    "0x9788D64c39E2B104265c89CbbCa2a2350e62701d",
    "0xC9fE451251398F7Ba82296DD6eC2E3f43ee8d93F",
    "0xd532962FD7976880FDff92DB9Cbe48a7369b1fc0",
    "0x0da4d20e6b7Bd947419d821BfDa3D8ca079b86f1",
    "0x84fF759Ee0B6057506f36E5e908ab73877C9263c",
    "0x5C9Ce53738967e4D422f0f6914d5bE496F9EdD2b",
    "0xB09Cb3EC75DdbBd0bC9A715D703ea84a27a99D38",
    "0xB71E4596686608aA05581660187281A00efb81Ff",
    "0xCfD780ded0b05f508B98dBA7E27E11F4fb82837f",
    "0x3996A7E38fa56e0A10416430e28cc28182d4B21C",
    "0xdA38AFF9D34fF382F12a1De111A10491566B9876",
    "0x778530DEFcFe3E28C4AC55C6ca7FC69Bf7776AbE",
    "0xc34ED3F6677f694797AdCE1767aa3e73Cf48e1F3",
    "0xe37D4eA5C27017C227B6bf5a9CeDA2E02c58637f",
    "0xd71e4AfEDAA844E493fD612F7e9C32Cc534FAE61",
    "0x747A70e778985799b11a536FC716BaF3E290bB10",
    "0x642B15A995980eCcB49E6475f44975Ff1F50Dab8",
    "0x186f3481dbEBA09639e1EAd65aF3457f7EFACB9e",
    "0x068e9989EFF6ee3746DE4498e5Bbc0Ecc7f968Fb",
    "0x03F7f1aB10e8bA1f6c3B7ea588087Ee12d44Dcc8",
    "0xFEF87cbfd1F377A962a0EF8adDa5d407c5F14f1C",
    "0xD909A1e32e24E806c6206CAf07A8cB3e02858149",
    "0x84dDddBe34C36c894347fA3649B0E25550dEb4d6",
    "0x8eda5967E823C48665C797d1E35b59B5e05162Ed",
    "0xA386542F9144fEAFB0f035397E16Bf6D02bB999F",
    "0x6A4406F5be648B406c0c20334E8a5DE6B4999516",
    "0xD4fe5b08a436C93d076d1b0a3752C8f9b6a4abfe",
    "0xe5a81738DCB83CBC73440F331659F362294Bb7f1",
    "0xBA6b5E38eeE62aB0711DD020D9873316846566B9",
    "0x4891baed23E9B2490dEe4bfD09c4f98579Fc08C5",
    "0x764965E051b54F6695d48899506E2f26cA765edf",
    "0x0d917a622ed9a5773e52cCb1fAc82A75a8a6d9D9",
    "0x838AA6360Bd87c7d0A96b8b84ac107E0a49dc114",
    "0xa5B0C665E95545604f0A1DD0e3ecD857a9C2D2C9",
    "0x4f28E099459F200e2C6cD6cdE11d23700c208359",
    "0x330331eA6b3d10aaB69b87D86478D6aB643A981B",
    "0x32d40ef4928EfBcdc135B3359dFc4Ec66Ee4ceCC",
    "0x51EC15594230DDf21A7EA5A4aC392BB8Dbda527E",
    "0xf6A51B6c793133460B279a5E6B7ea6867FD5bd7C",
    "0xCdc921690f110d077dA220121D26FD198D39eeF1",
    "0xCE9D39958681fE1385FB7A3E23bFF730d90a9729",
    "0xE36F023f4d7D29D51B67986089EA0d41b643Ad4a",
    "0x103c887d44D81C5584053AF523002925Cc18814D",
    "0x490790Ddfb169857CE80248306DB24105eb55936",
    "0xd3e38c017d441558135549719f9f9C398A64FDab",
    "0xCC86c675Ac9F00E440F4F80B6D27b881de0f128A",
    "0xc9E7A3937CF24Ed932B69C4545a20A5966a73fB5",
    "0x1Ac1Edb70367f3e9C0602dcEd488a465565F256E",
    "0x3E2b71BF37cEfe64B9cde8Bd19b2c70113eB2785",
    "0x0a49De8E4f369c82b5315a40Ad0AC67d529a895F",
    "0xAb3034c66c30a11371E7BC05d2f2b16f8BECC110",
    "0x5B8F1DaaD43D779577AC05061a6B1546a29B47d1",
    "0xB16B708Fe3F85A99A253Ffe2Fe556ec4C4f8Eda3",
    "0x1EF0982991493c8F3B82c7f08A047F2ceb31EAA5",
    "0x0cb7a1134F45f084A060743908C468F916dA9F07",
    "0xE156c1d096FEc864FF641960a262b2D8929d4195",
    "0xDaEAdE1BceBF6C9cFB5f8bdcCC79C838FEFe6832",
    "0x80DDf3efe08cf6A29eB917dbd326F0D6DAd85c43",
    "0xAE58AA169CF8cE4Ff8FA6C24a1F434ff75c9b012",
    "0x5B908066aE4cDD15778796894f4a177c6FDD8509",
    "0x6d155C454C03909443f3Ab06Cc690900Bed6298B",
    "0xA9B60f88a82d7f8Af85F53379AaC4D7B34759f12",
    "0x9Fc48dC9e0Acc7073EAdd4F37f161EBEE41F1E99",
    "0x7D8EbEdDCccDBa1b070c455073aF153450C7d697",
    "0xB8262145c487B328fAf14127682643ce2D1DFdcC",
    "0x533950ab7F1E5BBEaF6100F2d823e23E0b4AeF0f",
    "0x20B2273561D13b4e29a0F442F3430B3D226EE289",
    "0x85908b2605BcF86A0d869173dF448C3afd0FE547",
    "0xcE970ae1ddc10C37D079C1330fD455b6654017fC",
    "0xce915E4a0Dbe5D8dFd054384C7d3a8f692d0428d",
    "0xc0b7f18839091fd334315C594ccB08D26c471Fc7",
    "0xba96162a8bF02b68b64e4a154617e19E4028efC4",
    "0xeff59EA7b39d67cb57C606E21Ed9a4a348F8A78a",
    "0xC458e1a4eC03C5039fBF38221C54Be4e63731E2A",
    "0xfD08849489f0a0E665885878EAddbE28738a38F9",
    "0xe54fe76a02B05d450852c49CB06427e02ac5d8B8",
    "0x04f47435cb9cDF59c19C9d5E5982E073900F7De3",
    "0xCdC4e5A89cc23f4e7f673a3a18c1Ed84abEC88b4",
    "0x54AE40076387A68EFa483cAfBADb053123Ac7685",
    "0xbf47a917254e4eFd8973a2dc270004e4e82aAA89",
    "0x89d5Ac566d4d0BF14daD8B0531dd4B3de47F9424",
    "0x74fa1bE357bC182c88BA77E771a5502e2b271F1B",
    "0x3ec3991c0aeFd1F5De287Ac8fCDb9eDDD0DF2f72",
    "0xb643c924632f71ac70a982Ebc7E4099620f076C1",
    "0x46234FccD57237F421070E23C509c8d7f5c97022",
    "0xA8a308eaff92640a33c6a075e6869e0588BE5128",
    "0x7F1a4E5644E1340Db15194104eF8f5A64DF1Cf78",
    "0xDDcB509Fe6E15ec45a35492686947afF08BF58E1",
    "0x22586A535b975D77f2f6Af443207215eACeA6eA4",
    "0x69973b44c3ae36a6803cb2d77585b8db50220cc7",
    "0x31267188D920140e3015fe285F81bA163262042F",
    "0x1187d312074f9c017d6BeD1dF9754D03bA7B2Fd2",
    "0x2fe50DeaCdb83Eb8beabAbC73AC8D78cf478675f",
    "0x738025f325e6aB76686cC15dF07291062907092C",
    "0xe68c0650A819d1c4c9f541a0dADBB457CC793419",
    "0x1afe95013b5e4A017AC5B45A2649BC76b47B5f68",
    "0xd2055E892FAA32cF4ba2B5a33A8dBb4Fd64a506b",
    "0xe70D161C7ffF90c1127dD0A03C341d429E79D211",
    "0x965D5CE02c082A51A51b990b0De39857053d1F57",
    "0x2FA3479F42f38078943587f45D33a9BCe36b23a7",
    "0x9B03891a8251c448B6C5D55556c43c3E0C64b924",
    "0xb8D781c15858688387A594B4A34f8463b56AF8bA",
    "0x66ed00d2df9ee54911A90AAda0c8dfF4c169b6B1",
    "0x3Dadf855b9E30e63Bee10ec4D92cbFE789E5F8A8",
    "0x4820189e0C6Ae798186cA9ac48e70a7fc630Bb6e",
    "0x31249c9aD60B319EaA6FdA00A84327FfBB74aC72",
    "0x60670dB0663eEEa0E022ee2250aa37c6Ae427Eca",
    "0x8aA69753ED549De82B82F5B1B268e6c8f96d5C07",
    "0x20E44FcCFefC2215e8FFa6cD9cBDdD6EAaFdB999",
    "0xAE29BEF6Fb6B2974ce79C9914889dB65E67B7aFF",
    "0xECc314d8CC41438F90acAbd9A5D0c1899d143689",
    "0x139932823E72Fd90543547dA33854fBC39dD1A44",
    "0x3D139eB16d79944a98EC3Db0A862f9CE98c576F5",
    "0xD31DFc43E584b546C10a8B66a363c7752086D84D",
    "0x0aF0CC88182856aFD7f0d5D953c76673395fe85D",
    "0xf2A38bd2A11C743c0368DDEE1cF7E155FBf41F4B",
    "0x9BF89364B34A60A7935eBdb29B8Ad88Dd95C8680",
    "0x4E1c94F0eE40df053B190EF6Fa8709982c10F748",
    "0xDdA0eaC66073397f222DbA518c5231aE716F129B",
    "0xA77AeBFa19dD12c88E7F49a09d35290025Ff25F1",
    "0xf48B4C067b4816dbC0A65333E9E81CA6D8a17002",
    "0x7ecEf266ED9aDa13D97A18E1E4f630E3060c652F",
    "0x158c72c9fCaBf584C6324C732345b9e5080Fb725",
    "0xE36a124CaA7Ee0b75A96A934499CE68DaC6D9562",
    "0x0d13A9e6eA1Fcb66993C71b1ca214f350247007E",
    "0xB5D4187BcF2Df95b336D59d399687A101735959d",
    "0x6cC4A1044A6fB92b8e0338363728dFB9644879b4",
    "0x050EF81B1cC32f1d3EC9b175Ef9e39053c156B9E",
    "0x564820a33afff3513b28e2fa6ca1346dee342ce1",
    "0x07eD493a169956c953b1704E3e27368895A57C96",
    "0xdf09092bAe5C265e404e0a8Ce01eBF341481F531",
    "0xF5fd651C3193F5fe165eeB828Fc52Ceb720c5E34",
    "0x156D9d0fF226B6f08D253FDcDD28A0a69e301607",
    "0x7464932Bd227B88cA5A5aA4903dC60Bfe2D77C5F",
    "0xF325Ede0886B9784FB8CdDf0a1aDD21318da126A",
    "0xb11dE9dbd61A5A54ef2B23A4Cb713Df85DF08E70",
    "0x5f419F4Fa688069e8175888045c2C51aB7A35825",
    "0x8b59ED2CE3731a3D4e7990CC4FA12f59a1Fa7300",
    "0x489F40552a9a2bc3d2718Db5417f0955675e6cF7",
    "0xE6e2731FD3479F5BC76F72C78b368C805abAAa1a",
    "0x83448a9cdCb456Bb58577C141Cd77e311244A156",
    "0x97341010d9DF19727f458128639Ddd81F2b6E5dE",
    "0xa02d34e0f2235661F4b46b8A7BEDB42c4cce104b",
    "0x4577Ae2d53ed0D340dff17fefa824eCbcFa2cE6A",
    "0x55E5C1d069Fdc0489fcfCeB0564D29acdBfAF386",
    "0xf3415D76F984cE7296Ca9cef0F83511388D62a30",
    "0xCb5A84C0fbd65B8F00E5c9ccdFD0f14813b3e6c2",
    "0xD7dEA37aDBF6888ef7a9a4035B0EdF36932cf0eD",
    "0x42F30aA6D2237248638D1c74ddfCF80F4ecd340a",
    "0x51384E26aabACeBb2e770cfe0E0F04f2feCB25cc",
    "0x43568F65705bDEEd4082153E94205e40a393b844",
    "0xDb5D099a6d2f2BC090Fcd258CC564861d552C387",
    "0x698Fa8dFa821489CF4B69225347F28A56E3c3129",
    "0xe9099FfeecA205007e5E34269093496723f51931",
    "0x7215b80FbA9c774d629Aa930baEf35E562e0Cd57",
    "0x0A611456392C14b0C6588712Da0955583A6d72d0",
    "0x22B6DCA30218E92bDcAaF33b3CeA154E850438B7",
    "0xBd0C1c09e3243335E9853a1892f5c6616E8A5202",
    "0xC2d376420b64B18328D324eE9655fED855dD87BC",
    "0x4476ab2c11b74576aa3abfAb19dde0aaDcFCA238",
    "0xb338Df12860e66EADc54Fa043302b7bC4BA3D255",
    "0x58828c7be7490bFcdAB241538F88C959dd7e2B12",
    "0x404D1938e66607D08aE9a14FA3055c66Ba814b48",
    "0x12B0f9a42B891ef7484557856874Bb1FbD144fE6",
    "0xf0a6E33Fd47F88FBA7E4fD5b05caBeF214A5A3Bf",
    "0xa6881ace63b4c011ec4a3eba2ce9959e02f2a7e5",
    "0x060ab3B83b591a6b2615a0C3587FB8E9d684E3A5",
    "0xED7261A8616d6A55a3647cF71E21F8146832aEa6",
    "0x91F743f6752e32599aB5dE8991C0aC4C33b3cCf4",
    "0xb294600c5Affb4B939f3F07693ee8a8DFE1f2B0B",
    "0xa11435b21e0Eff08A6c2c5b8316ACC94054e8bAB",
    "0x1D0AE0A25b1b41d918eA2e7c519fD369678f2390",
    "0x3b66aaD7bf50c3De4DaEcaedEcb8425CaE897518",
    "0xf23c17100f4Ba7b38F4950A84A5a06b6bF851D06",
    "0x321A6EEbf6C0B86f9CAf123c61247327373D1144",
    "0x05C7Dc96Db7fE24De28690460718720B4994b497",
    "0x9b4cf900888549E2B75991bc1335940f1e8fe924",
    "0x5bC3390C8b611d4D7a3A4E89C7ce275B3054FB13",
    "0xE648b85C095A8A494E55E1b498A27e6d9C0aFa81",
    "0x567E5880fc9e3F448a5E57c4493959622b9BFe41",
    "0x5ACb16Ea16F180b1955112eA34F75202e388441F"]
 */