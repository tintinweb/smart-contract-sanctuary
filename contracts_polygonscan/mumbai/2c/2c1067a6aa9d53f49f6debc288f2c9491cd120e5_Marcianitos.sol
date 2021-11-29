/**
 *Submitted for verification at polygonscan.com on 2021-11-29
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/Base64.sol

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}


// File contracts/MarcianitosDNA.sol

pragma solidity ^0.8.0;

contract MarcianitosDNA {
  string[] private _headTypes = [
    "Head01",
    "Head02",
    "Head03",
    "Head04",
    "Head05"
  ];

  string[][] private _headTypesSvgPaths = [
    [
      "M306 177.796C306 246.25 256.889 349 181.633 349C106.378 349 67 235.989 67 167.534C67 99.08 133.955 66 209.21 66C284.466 66 306 109.341 306 177.796Z",
      "M128.5 153.5C114.5 179 122.157 206.5 101.5 206.5C80.8435 206.5 81 170.765 81 149.029C81 127.292 133.343 91 154 91C174.657 91 142.5 128 128.5 153.5Z"
    ],
    [
      "M306 177.796C306 246.25 262.256 331 187 331C111.744 331 67 235.989 67 167.534C67 99.08 133.955 66 209.21 66C284.466 66 306 109.341 306 177.796Z",
      "M125 149.029C111 174.529 116.157 185.029 95.5 185.029C74.8435 185.029 77.5 166.293 77.5 144.557C77.5 122.821 115.343 93.0286 136 93.0286C156.657 93.0286 139 123.529 125 149.029Z"
    ],
    [
      "M306 177.796C306 246.25 262.256 331 187 331C111.744 331 103.562 253 95.5 177.796C88.5 112.5 94.5 66 209.21 66C284.466 66 306 109.341 306 177.796Z",
      "M154.232 128.303C129.358 143.387 128.574 155.058 110.685 144.73C92.7957 134.402 104.464 119.505 115.332 100.681C126.2 81.8564 173.87 74.9773 191.759 85.3056C209.648 95.6339 179.107 113.219 154.232 128.303Z"
    ],
    [
      "M302 182C302 250.454 260.756 351 185.5 351C110.244 351 107.5 274 59.5 182C29.1233 123.778 94.5 66 209.21 66C253 66 302 113.546 302 182Z",
      "M88.2358 153.921C76.7304 171.431 79.8339 179.263 65.0032 178.086C50.1725 176.908 53.148 163.608 54.3873 148.002C55.6266 132.396 84.4956 113.164 99.3263 114.342C114.157 115.52 99.7412 136.411 88.2358 153.921Z"
    ],
    [
      "M325.5 143.5C325.5 211.954 332.256 344.5 257 344.5C181.744 344.5 109 318 61 226C30.6233 167.778 94.5 66 209.21 66C253 66 325.5 75.0457 325.5 143.5Z",
      "M94.069 182.341C87.5029 202.237 92.5333 208.996 77.9052 211.708C63.2771 214.42 62.6984 200.804 59.8444 185.411C56.9905 170.018 79.8779 143.952 94.506 141.24C109.134 138.527 100.635 162.445 94.069 182.341Z"
    ]
  ];

  string[] private _bodyTypes = [
    "Body01",
    "Body02",
    "Body03",
    "Body04",
    "Body05"
  ];

  string[][] private _bodyTypesSvgPaths = [
    [
      "M300 537.051C300 635.859 231.235 661 156.07 661C80.9041 661 56 625.808 56 527C56 428.192 102.237 295 177.403 295C252.568 295 300 438.243 300 537.051Z",
      "M251 361.923C251 382.711 215.524 388 176.746 388C137.968 388 105 376.561 105 355.773C105 334.986 148.974 311 187.752 311C226.53 311 251 341.136 251 361.923Z"
    ],
    [
      "M310.5 499C310.5 597.808 231.235 661 156.07 661C80.9042 661 96.5 582.808 96.5 484C96.5 385.192 102.237 295 177.403 295C252.568 295 310.5 400.192 310.5 499Z",
      "M247.205 336.188C252.585 356.267 219.687 370.558 182.231 380.595C144.774 390.631 109.968 388.114 104.588 368.035C99.208 347.956 135.476 313.406 172.932 303.37C210.389 293.333 241.825 316.109 247.205 336.188Z"
    ],
    [
      "M323.5 499C323.5 597.808 244.235 661 169.07 661C93.9041 661 39 564.308 39 465.5C39 366.692 115.237 295 190.403 295C265.568 295 323.5 400.192 323.5 499Z",
      "M236.23 325.599C240.78 342.581 212.958 354.667 181.28 363.155C149.602 371.643 121.435 369.514 116.885 352.533C112.335 335.552 141.739 306.332 173.416 297.844C205.094 289.356 231.68 308.618 236.23 325.599Z"
    ],
    [
      "M266 499C266 597.808 218.358 661 173.179 661C128 661 95 564.308 95 465.5C95 366.692 140.823 295 186.001 295C231.18 295 266 400.192 266 499Z",
      "M224.053 330.599C228.603 347.581 208.432 357.616 185.118 363.863C161.804 370.11 140.435 366.16 135.885 349.179C131.335 332.198 151.567 305.436 174.881 299.189C198.195 292.942 219.503 313.618 224.053 330.599Z"
    ],
    [
      "M283 447C283 571 218.358 661 173.179 661C128 661 64 545.808 64 447C64 348.192 126 295 186.001 295C253.5 295 264 347 283 447Z",
      "M227.053 336.599C231.603 353.581 211.432 363.616 188.118 369.863C164.804 376.11 143.435 372.16 138.885 355.179C134.335 338.198 154.567 311.436 177.881 305.189C201.195 298.942 222.503 319.618 227.053 336.599Z"
    ]
  ];

  string[] private _skinColors = [
    "#ff7979",
    "#badc58",
    "#ffbe76",
    "#7ed6df"
  ];

  string[] private _eyesTypes = [
    "Eyes01",
    "Eyes02",
    "Eyes03",
    "Eyes04",
    "Eyes05"
  ];

  string[] private _eyesColors = [
    "#161E26",
    "#2c2c54",
    "#cc8e35",
    "#b33939",
    "#218c74"
  ];

  string[][] private _eyesTypesSvgPaths = [
    [
      "M210 213.053C210 228.375 200.625 232 182.465 232C164.306 232 156 228.375 156 213.053C156 197.73 169.919 204.481 188.079 204.481C206.239 204.481 210 197.73 210 213.053Z",
      "M287.999 212.754C287.999 227.621 282.679 228 264.674 228C246.669 228 244 227.621 244 212.754C244 197.887 252.5 204.437 270.505 204.437C288.51 204.437 287.999 197.887 287.999 212.754Z",
      "M288 186.73C288 205.089 283.15 217 264.916 217C246.682 217 237 197.522 237 179.162C237 160.802 239.166 157 257.4 157C275.634 157 288 168.37 288 186.73Z",
      "M212 186.481C212 204.869 201.048 226 182.933 226C164.818 226 156 207.575 156 189.188C156 170.801 175.218 154 193.333 154C211.448 154 212 168.094 212 186.481Z",
      "M175.986 181.387C175.322 186.6 175.271 189.784 170.514 190.087C165.756 190.39 164.872 185.521 164.567 180.726C164.262 175.931 169.135 171.487 173.892 171.184C178.649 170.881 176.649 176.174 175.986 181.387Z"
    ],
    [
      "M212.5 204.481C212.5 219.804 201.16 234 183 234C164.84 234 155 221.823 155 206.5C155 191.177 169.919 204.481 188.079 204.481C206.239 204.481 212.5 189.159 212.5 204.481Z",
      "M292.5 208.5C292.5 223.367 282.505 231.5 264.5 231.5C246.495 231.5 234 219.304 234 204.437C234 189.57 250.495 202.5 268.5 202.5C286.505 202.5 292.5 193.633 292.5 208.5Z",
      "M288 186.73C288 205.089 283.15 217 264.916 217C246.682 217 236.5 205.089 236.5 186.73C236.5 168.37 240.766 169.5 259 169.5C277.234 169.5 288 168.37 288 186.73Z",
      "M212 186.481C212 204.869 201.048 226 182.933 226C164.818 226 156 207.575 156 189.188C156 170.801 171.885 167.5 190 167.5C208.115 167.5 212 168.094 212 186.481Z",
      "M172.124 186.902C169.829 191.629 168.763 194.631 164.158 193.397C159.554 192.163 160.272 187.267 161.516 182.626C162.759 177.985 168.797 175.332 173.402 176.565C178.006 177.799 174.419 182.175 172.124 186.902Z"
    ],
    [
      "M213 209.997C213 236.991 198.818 243 180.5 243C162.182 243 155 240.547 155 213.553C155 186.559 170.049 209.997 188.367 209.997C206.685 209.997 213 183.003 213 209.997Z",
      "M291.5 205.685C291.5 230.454 277.851 230.5 260 230.5C242.149 230.5 234 233.682 234 208.912C234 184.143 250.354 205.685 268.205 205.685C286.056 205.685 291.5 180.916 291.5 205.685Z",
      "M287.5 178C296.457 194.5 283.15 214 264.916 214C246.682 214 237 209.36 237 191C237 172.64 242.766 178 261 178C279.234 178 278 160.5 287.5 178Z",
      "M212 178.712C212 200.714 198.897 226 177.224 226C155.551 226 145 193.002 145 171C145 148.998 172.327 166.5 194 166.5C215.673 166.5 212 156.711 212 178.712Z",
      "M163.124 182.902C160.829 187.63 162.604 189.234 158 188C153.396 186.766 151.256 181.141 152.5 176.5C153.744 171.859 157.396 171.766 162 173C166.604 174.234 165.419 178.175 163.124 182.902Z"
    ],
    [
      "M193 210.997C193 222.5 177.818 232.5 159.5 232.5C141.182 232.5 135 227 135 214.553C135 187.559 150.049 210.997 168.367 210.997C186.685 210.997 193 184.003 193 210.997Z",
      "M288 199.5C288 216 279.851 222 262 222C244.149 222 234 225 234 208.912C234 192.825 255.705 199.5 265.5 199.5C275.295 199.5 288 174.731 288 199.5Z",
      "M292 159C294.5 179 283.15 214 264.916 214C246.682 214 239.5 207 235.5 192.5C231.5 178 237.578 159.89 253 153.5C267.099 147.658 289.53 139.241 292 159Z",
      "M196 178.712C196 200.714 182.897 226 161.224 226C139.551 226 123 200.714 123 178.712C123 156.71 127.327 148.5 149 148.5C170.673 148.5 196 156.71 196 178.712Z",
      "M142.13 175.043C139.835 179.77 141.611 181.374 137.007 180.14C132.402 178.907 130.263 173.282 131.507 168.641C132.75 163.999 136.402 163.907 141.007 165.141C145.611 166.374 144.426 170.316 142.13 175.043Z"
    ],
    [
      "M193 210.997C193 222.5 177.818 232.5 159.5 232.5C141.182 232.5 119 210.947 119 198.5C119 171.506 150.049 210.997 168.367 210.997C186.685 210.997 193 184.003 193 210.997Z",
      "M291 192.627C299.285 206.896 284.851 224.5 267 224.5C249.149 224.5 238 221 238 204.913C238 188.825 259.705 195.5 269.5 195.5C279.295 195.5 282 177.127 291 192.627Z",
      "M283.5 181.5C286 201.5 283.15 214 264.916 214C246.682 214 239.5 207 235.5 192.5C231.5 178 236.078 178.39 251.5 172C265.599 166.158 281.03 161.741 283.5 181.5Z",
      "M196 178.712C196 200.714 182.897 226 161.224 226C139.551 226 123 200.714 123 178.712C123 156.71 118.327 130 140 130C161.673 130 196 156.71 196 178.712Z",
      "M139.137 152.543C136.842 157.27 135.111 170.234 130.507 169C125.902 167.766 127.27 150.782 128.513 146.141C129.757 141.499 133.409 141.407 138.013 142.641C142.618 143.874 141.432 147.816 139.137 152.543Z"
    ]
  ];

  string[] private _mouthTypes = [
    "Mouth01",
    "Mouth02",
    "Mouth03",
    "Mouth04",
    "Mouth05"
  ];

  string[][] private _mouthTypesSvgPaths = [
    [
      "M234.94 282.142C233.339 286.056 214.727 294.204 202 289C187.495 284.668 198.49 253.156 199.5 249C203.323 243.024 207.273 257.296 220 262.5C232.727 267.704 237.021 277.053 234.94 282.142Z",
      ""
    ],
    [
      "M234.94 282.142C233.34 286.056 223.087 277.295 210.36 272.091C195.856 267.759 187.843 267.453 188.853 263.296C192.676 257.32 199.154 263.168 211.881 268.372C224.608 273.576 237.021 277.053 234.94 282.142Z",
      ""
    ],
    [
      "M266.457 276.387C262.742 285.471 259.904 273.708 252.869 270.831C243.86 270.858 237.591 275.187 240.979 265.969C247.761 251.248 249.362 259.325 256.397 262.201C263.433 265.078 271.286 264.578 266.457 276.387Z",
      "M355 266.771C355 276.585 327.995 266.771 299 266.771C267.231 270.205 251.346 276.585 250 266.771C252.692 250.578 270.005 257.447 299 257.447C327.995 257.447 355 254.013 355 266.771Z"
    ],
    [
      "M238.534 253.912C231.245 271.738 213.535 287.807 206.5 284.931C196.24 288.018 199.538 271.871 206.5 253.912C219.18 224.767 206.465 268.123 213.5 271C220.535 273.877 248.009 230.739 238.534 253.912Z",
      ""
    ],
    [
      "M247.128 283.536C239.839 301.362 222.13 317.431 215.095 314.554C204.835 317.641 178.132 318.583 185.095 300.624C197.775 271.478 212.059 280.659 219.095 283.536C226.13 286.413 256.604 260.362 247.128 283.536Z",
      ""
    ]
  ];

  string[] private _planetColors = [
    "#B02A00",
    "#be2edd",
    "#4834d4",
    "#eb4d4b",
    "#30336b",
    "#535c68"
  ];

  function _getHeadTypeSvgPath(uint _headTypeIndex, string memory _skinColor) public view returns (string memory) {
    string memory path1 = string(
      abi.encodePacked(
        "<path d='",
        _headTypesSvgPaths[_headTypeIndex][0],
        "' fill='",
        _skinColor,
        "'/>"
      )
    );
    return string(
      abi.encodePacked(
        path1,
        "<path d='",
        _headTypesSvgPaths[_headTypeIndex][1],
        "' fill='white' fill-opacity='0.1'/>"
      )
    );
  }

  function _getBodyTypeSvgPath(uint _bodyTypeIndex, string memory _skinColor) public view returns (string memory) {
    string memory path1 = string(
      abi.encodePacked(
        "<path d='",
        _bodyTypesSvgPaths[_bodyTypeIndex][0],
        "' fill='",
        _skinColor,
        "'/>"
      )
    );
    return string(
      abi.encodePacked(
        "<g clip-path='url(#clip512)'>",
        path1,
        "<path d='",
        _bodyTypesSvgPaths[_bodyTypeIndex][1],
        "' fill='black' fill-opacity='0.05'/>",
        "</g>"
      )
    );
  }

  function _getEyesTypeSvgPath(uint _bodyTypeIndex, string memory _eyesColor) public view returns (string memory) {
    string memory path1 = string(
      abi.encodePacked(
        "<path d='",
        _eyesTypesSvgPaths[_bodyTypeIndex][0],
        "' fill='black' fill-opacity='0.05' />"
      )
    );
    string memory path2 = string(
      abi.encodePacked(
        "<path d='",
        _eyesTypesSvgPaths[_bodyTypeIndex][1],
        "' fill='black' fill-opacity='0.05' />"
      )
    );
    string memory path3 = string(
      abi.encodePacked(
        "<path d='",
        _eyesTypesSvgPaths[_bodyTypeIndex][2],
        "' fill='",
        _eyesColor,
        "' />"
      )
    );
    string memory path4 = string(
      abi.encodePacked(
        "<path d='",
        _eyesTypesSvgPaths[_bodyTypeIndex][3],
        "' fill='",
        _eyesColor,
        "' />"
      )
    );
    return string(
      abi.encodePacked(
        path1,
        path2,
        path3,
        path4,
        "<path d='",
        _eyesTypesSvgPaths[_bodyTypeIndex][4],
        "' fill='white' fill-opacity='0.1'/>"
      )
    );
  }

  function _getMouthTypeSvgPath(uint _mouthTypeIndex) public view returns (string memory) {
    string memory path1 = string(
      abi.encodePacked(
        "<path d='",
        _mouthTypesSvgPaths[_mouthTypeIndex][0],
        "' fill='#161E26'/>"
      )
    );
    return string(
      abi.encodePacked(
        path1,
        "<path d='",
        _mouthTypesSvgPaths[_mouthTypeIndex][1],
        "' fill='#C4C4C4'/>"
      )
    );
  }

  function _getPlanetTypeSvgPath(string memory _planetColor) public pure returns (string memory) {
    string memory _planetCircle = string(
      abi.encodePacked(
        "<circle cx='440' cy='512' r='312' fill='",
        _planetColor,
        "'/>"
      )
    );
    return string(
      abi.encodePacked(
        "<g clip-path='url(#clip512)'>",
        _planetCircle,
        "</g>"
      )
    );
  }

  function deterministicPseudoRandomDNA(uint256 _tokenId, address _minter) public view returns(uint256) {
    uint256 combinedParams = _tokenId + uint160(_minter) + block.timestamp + block.number;
    bytes memory encodedParams = abi.encodePacked(combinedParams);
    bytes32 hashedParams = keccak256(encodedParams);

    return uint256(hashedParams);
  }

  // Get attributes
  uint8 constant ADN_SECTION_SIZE = 2;

  function _getDNASection (uint256 _dna, uint8 _rightDiscard) internal pure returns (uint8) {
    return uint8(
      (_dna % (1 * 10 ** (_rightDiscard + ADN_SECTION_SIZE))) / (1 * 10 ** _rightDiscard)
    );
  }

  function _getItem(string[] memory _items, uint256 _dna, uint8 _section) internal pure returns (string memory) {
    uint8 dnaSection = _getDNASection(_dna, _section);
    return _items[dnaSection % _items.length];
  }

  function getSkinColor(uint256 _dna) public view returns (string memory) {
    return _getItem(_skinColors, _dna, 0);
  }

  function getHeadType(uint _dna) public view returns(string memory) {
    return _getItem(_headTypes, _dna, 1);
  }

  function getHeadSvg(uint _dna) public view returns(string memory) {
    string memory _skinColor = getSkinColor(_dna);
    uint headSection = _getDNASection(_dna, 1);
    return _getHeadTypeSvgPath(headSection % _headTypesSvgPaths.length, _skinColor);
  }

  function getBodySvg(uint _dna) public view returns(string memory) {
    string memory _skinColor = getSkinColor(_dna);
    uint bodySection = _getDNASection(_dna, 2);
    return _getBodyTypeSvgPath(bodySection % _bodyTypesSvgPaths.length, _skinColor);
  }

  function getEyesColor(uint256 _dna) public view returns (string memory) {
    return _getItem(_eyesColors, _dna, 3);
  }

  function getEyesSvg(uint _dna) public view returns(string memory) {
    string memory _eyesColor = getEyesColor(_dna);
    uint eyesSection = _getDNASection(_dna, 4);
    return _getEyesTypeSvgPath(eyesSection % _eyesTypesSvgPaths.length, _eyesColor);
  }

  function getMouthSvg(uint _dna) public view returns(string memory) {
    uint mouthSection = _getDNASection(_dna, 5);
    return _getMouthTypeSvgPath(mouthSection % _mouthTypesSvgPaths.length);
  }

  function getPlanetColor(uint256 _dna) public view returns (string memory) {
    return _getItem(_planetColors, _dna, 6);
  }

  function getPlanetSvg(uint256 _dna) public view returns (string memory) {
    return _getPlanetTypeSvgPath(getPlanetColor(_dna));
  }
}


// File contracts/Marcianitos.sol

pragma solidity ^0.8.0;







contract Marcianitos is ERC721, ERC721Enumerable, Ownable, MarcianitosDNA {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _idCounter;
  uint256 public maxSupply;
  uint256 public mintingPrice;
  mapping(uint256 => uint256) public tokenDNA;

  constructor(uint256 _maxSupply, uint256 _mintingPrice) ERC721("Marcianitos", "PRS") {
    maxSupply = _maxSupply;
    mintingPrice = _mintingPrice;
  }

  function mint() public payable {
    uint256 current = _idCounter.current();
    require(current < maxSupply, "Not Marcianitos Lefts :(");
    require(msg.value >= mintingPrice, "Not enought money");

    payable(owner()).transfer(mintingPrice);

    // TODO: Use an oracle like Chainlink for production!
    tokenDNA[current] = deterministicPseudoRandomDNA(current, msg.sender);

    _safeMint(msg.sender, current);
    _idCounter.increment();
  }

   function getSupplyLeft() public view returns(uint256) {
    return maxSupply - _idCounter.current();
  }

  function imageDataByDna(uint256 _dna) public view returns (string memory) {
    return string(abi.encodePacked(
      "<svg width='512' height='512' viewBox='0 0 512 512' fill='none' xmlns='http://www.w3.org/2000/svg'>",
      "<rect width='512' height='512' fill='#333333'/>",
      getPlanetSvg(_dna),
      getBodySvg(_dna),
      getHeadSvg(_dna),
      getEyesSvg(_dna),
      getMouthSvg(_dna),
      "<defs><clipPath id='clip512'><rect width='512' height='512' fill='white'/></clipPath></defs>",
      "</svg>"
    ));
  }

  // Override
  function tokenURI(uint256 _tokenId) override public view returns(string memory) {
    require(_exists(_tokenId), "Invalid token id");
    uint256 dna = tokenDNA[_tokenId];
    string memory imageData = imageDataByDna(dna);

    string memory jsonURI = Base64.encode(abi.encodePacked(
      '{"name": "Marcianito #',
      _tokenId.toString(),
      '", "description": "Marcianitos are randomly generated characters", "image_data": "',
      imageData,
      '", "attributes": []}'
    ));
    return string(abi.encodePacked("data:application/json;base64,", jsonURI));
  }

  // The following functions are overrides required by Solidity.
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