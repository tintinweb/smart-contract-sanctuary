/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// Sources flattened with hardhat v2.6.1 https://hardhat.org

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


// File contracts/SpookyCats.sol



pragma solidity ^0.8.0;



interface IReferenceContract {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

contract SpookyCats is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public _baseTokenURI;
    uint256 public _price = 0.03 ether;
    uint256 public _maxSupply = 3333;
    bool public _preSaleIsActive = false;
    bool public _saleIsActive = false;

    mapping(address => uint256) public _whitelist;
    mapping(uint256 => bool) public _tokensTracked;

    address _referenceContract = 0x5f7Ed81ee49a3D85ff9F2120156b4Cd38383B9cb;

    address a1 = 0x55c3B3D49bdeFC4DC52667C4eA7c6Ce5089e08Ed;
    address a2 = 0x7a598C9A35cC773B6E650cc8ed08b2b9513dDa01;
    address a3 = 0xA4754D6c8905AA776692bc60732F92911EA1fCa2;

    constructor(string memory baseURI) ERC721("SpookyCats", "SPOOKYCATS") {
        _baseTokenURI = baseURI;
        populateWhitelist();
    }

    function mint(uint256 mintCount) external payable {
        uint256 supply = totalSupply();
        uint256 whitelistMints = _whitelist[msg.sender];
        uint256 freeMints;
        uint256 payableMints;

        if (whitelistMints > 0 && whitelistMints < 99) {
            freeMints = whitelistMints;
            _whitelist[msg.sender] = 99;
        }

        uint256[] memory tokensOfSender = IReferenceContract(_referenceContract).tokensOfOwner(msg.sender);

        for (uint256 i; i < tokensOfSender.length; i++) {
            if (!_tokensTracked[tokensOfSender[i]]) {
                freeMints = freeMints + 2;
                _tokensTracked[tokensOfSender[i]] = true;
            }
        }

        if (whitelistMints > 0 || tokensOfSender.length > 0) {
            require(_preSaleIsActive, "pre_sale_not_active");
        }
        else {
            require(_saleIsActive, "sale_not_active");
        }

        if (mintCount > freeMints) {
            payableMints = mintCount - freeMints;
        }

        uint256 totalMints = freeMints + payableMints;

        require(supply + totalMints <= _maxSupply, "max_token_supply_exceeded");
        require(msg.value >= _price * payableMints, "insufficient_payment_value");

        for (uint256 i; i < totalMints; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function ownerMint(uint256 mintCount, address recipient) external {
        uint256 supply = totalSupply();
        bool canMint;

        if (msg.sender == a1 || msg.sender == a2 || msg.sender == a3) {
            canMint = true;
        }
        require(canMint, "unauthorized_sender");
        require(supply + mintCount <= _maxSupply, "max_token_supply_exceeded");

        for (uint256 i = 0; i < mintCount; i++) {
            _safeMint(recipient, supply + i);
        }
    }

    function checkTrackedTokenId(uint256 tokenId) external view returns (bool) {
        return _tokensTracked[tokenId];
    }

    function updateWhitelist(address owner, uint256 count) external onlyOwner {
        _whitelist[owner] = count;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function preSaleStart() public onlyOwner {
        _preSaleIsActive = true;
    }

    function preSaleStop() public onlyOwner {
        _preSaleIsActive = false;
    }

    function saleStart() external onlyOwner {
        _saleIsActive = true;
    }

    function saleStop() external onlyOwner {
        _saleIsActive = false;
    }

    function interfaceTokensOfOwner(address owner) external view returns (uint256[] memory) {
        return IReferenceContract(_referenceContract).tokensOfOwner(owner);
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 _each = address(this).balance / 3;
        require(payable(a1).send(_each));
        require(payable(a2).send(_each));
        require(payable(a3).send(_each));
    }

    function populateWhitelist() private {
        _whitelist[0x63Dc29501d7559DB0Cb81b9C6DbC3C2F042C1245] = 1;
        _whitelist[0xb5A2D06B4D3FDfC994cC82def8C7E3364905aBC7] = 1;
        _whitelist[0xDB74098bB80aff56B5e525D55ACE521a7Fa83D60] = 1;
        _whitelist[0x1107602d51193953cFe4cb8a4B01d846e7E426ab] = 1;
        _whitelist[0x8a9ae3393801cFA423a54E1031639CF8c6f65FBF] = 1;
        _whitelist[0x53F0B0a19469B9B4e493c968b52EF09826e13F30] = 1;
        _whitelist[0xeBc453E098EA5Ca81E216441891c84BC4fB6e8E6] = 1;
        _whitelist[0x7bbb1cF56c688fB49a7685Fb28409484f6aD35CD] = 1;
        _whitelist[0xcdEFcDF6937BC536a637ca8fBb44Cfae1476eB42] = 1;
        _whitelist[0xF7595B72e67264FDc8c5b12D67cdF9BF0cDB4716] = 1;
        _whitelist[0x40a2F7517a98D96aF74C0C86f9C9e1De709FF56E] = 1;
        _whitelist[0x0Dda429Fb28fD7B3D8B0D232f88F3aF19d906962] = 1;
        _whitelist[0x09e79e8b4cdbFF6B26D4cf4BaB113705896fE9a8] = 1;
        _whitelist[0x26Ac155F40A4Ac8fcac27b45D3bd38F17B928BE2] = 1;
        _whitelist[0x835649A4Ad9C806405B03e39BFCd02D6e81B408F] = 1;
        _whitelist[0x53607f10D76B9d29d6eAD2184E9045dF978F8b59] = 1;
        _whitelist[0xA494EAaDc6b7940a6DB852DC54B2FE5fA15ca624] = 1;
        _whitelist[0xC3EDD46bCf48890c1B72aE414cD61B90D1c3334f] = 1;
        _whitelist[0x4E0ad2Dd94ae7447A24e824c46061dbE983E0A1F] = 1;
        _whitelist[0xb7a2B5a7d82085567362015a775BE42D1FC70652] = 1;
        _whitelist[0xa59C465D617E9c4101FCa42463E4F9453db6da42] = 1;
        _whitelist[0xb9C86b39301246e055d01c76f20b848A88427B02] = 1;
        _whitelist[0xa57255C02d1171E960aA4F5a99184e5982f33077] = 1;
        _whitelist[0x0ACE7Cc0F10C2bF796bC2Fb1bb80e1C8847B0567] = 1;
        _whitelist[0x734Bf83ebE39F3Dbc53360a0522c6c99517a5074] = 1;
        _whitelist[0xd52C99B8D73F5bD29dA85330eFCa15acC5071C62] = 1;
        _whitelist[0x7F2AD3B180a2724c922a63DF13F8BFC7fc36b685] = 1;
        _whitelist[0x6A932553C062E0aFF43B59d3FBaAcA18F0Dab017] = 1;
        _whitelist[0xb504b504551AdEE28b9e046e2a218200e8aF66Cb] = 1;
        _whitelist[0xb963C1BFA2ee0dA0F3300F4d4AE2E2A5504A1DF9] = 1;
        _whitelist[0xF3D2d790dDE4889Ff10B8D8FBD2DE7631eE97663] = 1;
        _whitelist[0x453ac2F4462d3ced2BDA325898fae783926225FC] = 1;
        _whitelist[0xD17238636aCE796bae6BD669737775aF7AA8f82B] = 1;
        _whitelist[0xb1eBF12bCE67984D914062BD1b7c641962557660] = 1;
        _whitelist[0x7258DC6dc529B531bAE1579D190f193fa3706b4A] = 1;
        _whitelist[0x7656354162ac373A52783896E0DC9D1A1352d94d] = 1;
        _whitelist[0x41284C43F91d6307F8E5dc2CE72061d43Cd383c0] = 1;
        _whitelist[0xF7fcCCBB90eA56626A5C8ef1AA273aCFDCCC3eA6] = 1;
        _whitelist[0x66Ee3605Ca27E13848b53c9730235323B2Aa69a0] = 1;
        _whitelist[0x159148Aa964A0774F2Dc9c534aBee6e305Af4d7d] = 1;
        _whitelist[0xf2615676Dc226ECd4494A04228857e3a1BDf86f5] = 1;
        _whitelist[0xc64B31506c2c813d7C81Db05decD3c187E701e08] = 1;
        _whitelist[0xA205B1022b7915261Bf62835F02aC7A8d9Ca1e05] = 1;
        _whitelist[0xFD845e60eAea6c960d2a2b6F490b53D26925D5cB] = 1;
        _whitelist[0x64590a8a5C844394893668EaC7edE9A1adF18152] = 1;
        _whitelist[0x31FD69F76afed0FA6DB8B1a606e521C64813505D] = 1;
        _whitelist[0x1D43168ff0e4b52209571613A5a2ab6cE00B7999] = 2;
        _whitelist[0x9946Ba71C3f7f0730373dE898D8E38411FAA152b] = 1;
        _whitelist[0x3E0dF2ce06a8225F12af6D2171FEc1bDbDAcEa8D] = 1;
        _whitelist[0x3286651F7bA59ba8D23025b39A24Cb473C9C01B8] = 1;
        _whitelist[0x856a5f9a8A29b4C9E0c95357b543Ff3e9245BfBA] = 1;
        _whitelist[0x1922942C8CafA23B67d1BA45703950DD0849480a] = 1;
        _whitelist[0x68f3b8F48CaD402DDA2e7D3Fa7697984E2DCa741] = 1;
        _whitelist[0xe3901d0a64973a4f9e163A9fE8448dcdc98bA8e9] = 1;
        _whitelist[0x2b291BE98C53e2fC88224745cd0B75Fa02121f28] = 1;
        _whitelist[0x033CC34a6AB84705B3cF71098653a9840514c73D] = 1;
        _whitelist[0x0e51632B79ca39813111ea6a75f3c3ab4979fEa6] = 1;
        _whitelist[0xc70150E6DefF0b3d0578Dc99d97401631b838f55] = 2;
        _whitelist[0x1327eda6B51Ea6D19d701398EBb120C7dcd54B58] = 1;
        _whitelist[0xCba1311383Fbc544e8Ae08B48Ed7B6FcE1e5691a] = 1;
        _whitelist[0x998F6da35d54Da034ad39Df42f37FA069C645A47] = 1;
        _whitelist[0x268018E1Ef07dD68873AF53721Af50947EFE8F4a] = 1;
        _whitelist[0xBeF6A169E4d44840D55032CB75a3910b6fEF467d] = 1;
        _whitelist[0xABaa9079De6d8b4228A98Eb1435d471B7De6992f] = 1;
        _whitelist[0xc01DbEEA95ba3AC00fbD9Be9fF06eC3284dc42E5] = 1;
        _whitelist[0x3232e13096515B5cf006358bf91B588C3066757e] = 1;
        _whitelist[0x9dfe430F8752a5a725C79D8A8cECB6F9535f62D5] = 1;
        _whitelist[0x1234ec7C0Ab43fae7f7B97c18d5183Ba5967564B] = 1;
        _whitelist[0x1498A57afE51860b22413CEdD196Cf4493bBfe12] = 1;
        _whitelist[0xA1232CE88B93702c3467d0b6Ad7E9FA6eEb49EB4] = 1;
        _whitelist[0x765Bd363c8fCF8AA4dB870E05fD5Ba40dAa81B66] = 1;
        _whitelist[0x9dD23e4Ea9e5b10529056FF120dcd41bd1C8F310] = 1;
        _whitelist[0xfF069d9c80235FF14d296E2b81788f25eeDd6D11] = 1;
        _whitelist[0xb27D058c8C64e0FC6DFaf4860D271d51B27A5F88] = 1;
        _whitelist[0xf66A629EdA2c24B6EFeB750Fe74A3FeA9902aC6d] = 1;
        _whitelist[0x1eFf4f9836F34F9618DF4491D0bAE051F07eF2d6] = 1;
        _whitelist[0x716C59a499fADeb4b5Be3b319B6cf24385503Ed0] = 1;
        _whitelist[0x4d96b171372385EEF9db97cfaF9f16A46BD22d04] = 1;
        _whitelist[0x6BbFf3885bBf209bF40Eb5Bb95c21E20feE214ad] = 1;
        _whitelist[0x4c02081163eEf26c5b6d607D5a92eB46f14e3917] = 1;
        _whitelist[0x0226f58C94C0857B2e3aBd4aA0df2Ef917A71dCc] = 1;
        _whitelist[0x2a127C5d264013026eF3f31cbAa7f6812cC2a731] = 1;
        _whitelist[0xA5Ed9AcE0C2a53B6490D4C8e72f9a966F37DF35f] = 1;
        _whitelist[0x6F9900f5dF40399080a0CC206AD41c674CFa66CE] = 1;
        _whitelist[0x2972fe704FBd567bE18A4BAcfe9f05eA9a62f729] = 1;
        _whitelist[0x7961Bd738c2218038A60324181311f0e8e406121] = 1;
        _whitelist[0xC42bA60a4f78b4037E30167105e5f76657a9d08f] = 1;
        _whitelist[0x2f5Ab230e5B0564C0eecc93674a8B85B781A499F] = 1;
        _whitelist[0xe7B622e9a313e79a7b693485f0F5878740BC9249] = 1;
        _whitelist[0x88c97dF74680530Dfb4bc10Bb61707De63D439f7] = 1;
        _whitelist[0x9B5f95fFb5Cb01723BBD1e8E76f310358351f483] = 1;
        _whitelist[0x1459a34762b6401f5fbFa11C55B0f81Bda100391] = 1;
        _whitelist[0x08CA657ca337EDE754ceD0200918fEfEE7203041] = 1;
        _whitelist[0x5f697FB2A1b538a62bC196bc0aacD280e0bD22AE] = 1;
        _whitelist[0x6101e3de526fCC9596A9ed2FBA8BCdE47bd66920] = 1;
        _whitelist[0x0e0889A8F18C1319B2f8e22AEc2F4Bbe8Fc422A0] = 1;
        _whitelist[0xCE6900D875C7460CE6293C77F6070C98C5c3db9A] = 1;
        _whitelist[0xd88cEaaE5e9156B5D48b718EdbA62C4E52C509d6] = 1;
        _whitelist[0x1DB0056646a5bf324cB53a324aC325c6fbB85fB5] = 1;
        _whitelist[0x4122Ac127311bB4bD22ceC65AE3A8007d8ab9489] = 1;
        _whitelist[0x11ba2C5506E69A33e333fF9E9D7174aa52B59093] = 1;
        _whitelist[0xF4E30bcb65f56B9bbb5B7aeF70Daaf07b7B5FCD2] = 1;
        _whitelist[0x486B90d442F4319FC8A19B9c4b75C9857196e6D4] = 1;
        _whitelist[0xfEfF684674F2a0549723C75814b1487eBc92EDE5] = 1;
        _whitelist[0x4a1ccB3fC509205EC44e86A741bA29AB66a06F45] = 1;
        _whitelist[0x5e9b7676B36f5DE6ce31Eef1fa4a23598Af8EdDc] = 1;
        _whitelist[0x711Ed6Dff07A4E61C4158350557B0606FF79a6b5] = 1;
        _whitelist[0xc745AE18B87eb0DB75c89D9699dc880b833D7645] = 1;
        _whitelist[0xdA19cd59A312CB34b4c5B07D6DdAeC333b989973] = 1;
        _whitelist[0x987aF6aAfA9415D1684905B4654338F4bEd19AD8] = 1;
        _whitelist[0x0CD40F7EdB13EC6B372e8B3333b209eF16E5ae98] = 2;
        _whitelist[0xC03aDa2B5DF0cC5D3919aE551Cfe65559Dbabe1D] = 1;
        _whitelist[0xB2d68609a7374d81ee096C965467BbA5c20E6DD8] = 1;
        _whitelist[0xc304E913ebB7625687D66f6904207fdFD19C7E53] = 1;
        _whitelist[0xfa3369b19ACB8625A631ea807D9F60Cc0e050577] = 1;
        _whitelist[0x863E7aAded2B90a08802d362b7FBf228b65C5Bc9] = 1;
        _whitelist[0x4A9973D3A1563a85B9424D2Db229151a8E1f5611] = 1;
        _whitelist[0xd90DBE9117676b29c2e06fffc339b24A71051ed0] = 1;
        _whitelist[0x71453727E55C378551B7b466F16da18aC1Dfc874] = 1;
        _whitelist[0xd011878cBEE251d148857A58EB737ADc3A4a9e98] = 1;
        _whitelist[0xf9eC946c7D7Fa6189147EeE1C2B7bF418e7eB705] = 1;
        _whitelist[0x560f74a13E7118038eB4e67caFCc42BA19EE8F82] = 1;
        _whitelist[0xe300DD7bd1c79aa78ED4217b482ec9f95De7fBb1] = 1;
        _whitelist[0x2913ffd77bf3317C3922B707D6aDDCFc9d0e3eAF] = 1;
        _whitelist[0x3710c45D46aD86A868Ae03899412B8aB6246f64e] = 1;
        _whitelist[0x9B23C802dD34cCdB7661102d9F9D647D3879D25C] = 1;
        _whitelist[0x2881fDf7e15D3664BeDCFb79B4775A89ED7Fc122] = 1;
        _whitelist[0xC5FC0a9Cb273ad5cfa538345618Aa692a3CBB02a] = 1;
        _whitelist[0xB109c2B91095E27Ecec3B9e46F72063c90A6054B] = 1;
        _whitelist[0x00A3031230E54f9fc124A7AeDB77111e020DD675] = 1;
        _whitelist[0x31ad5BF465D86952253D07B89dc68b236BE50bE2] = 1;
        _whitelist[0x1b7549c126680B1d08Cc660C6e772ccEc0Bcc663] = 1;
        _whitelist[0x79322e3d7133BF9d3b886e6adD1Fc65e0DcC60AF] = 1;
        _whitelist[0x4a36246660620b03A933BBEd0E87c469eDa61A74] = 1;
        _whitelist[0x2bd0897c180feaEa5D4DcD8CE4CDc4167ee3Cf22] = 1;
        _whitelist[0x575fA7ac7E4fCfdD66ed62602Ff28b0FCec47AD7] = 1;
        _whitelist[0x29CAa7a393cFE67576F81A8b77A22c7880aF5501] = 1;
        _whitelist[0x78244D51D21BC7A58BeE3bD6932928c93C83Fb99] = 1;
        _whitelist[0xc70Be24060c944790B1af7a67b63Bb4109FB1f2A] = 1;
        _whitelist[0xbF6CB050941a12305ccADbc594B5fE46290efaFB] = 1;
        _whitelist[0x58A00F069924fB09d261CFFA02EFa6316D4dFc1A] = 1;
        _whitelist[0x3913d13611D2F128e3e1d3Ee7dAbA53e4d37a2C8] = 1;
        _whitelist[0x9c466fBdECF0a60018a8eC0D3a0Ef540DF31d9Ba] = 1;
        _whitelist[0x9B578c1696b30b85e36f36F679242D25283910E4] = 1;
        _whitelist[0xFCe04BD855fddce366ff8D04ca930503E8263A3f] = 1;
        _whitelist[0x908DF508e7Cb714c32F1986bC29e9e350a70b1d6] = 1;
        _whitelist[0x3D03856068DF8A206F452DF10156B909671517D7] = 1;
        _whitelist[0x8f8260521A3EE8540D5e1b5f17051ea434D18d72] = 1;
        _whitelist[0x0D552308237A5536864D15E7c2eeC79f8FE3982A] = 1;
        _whitelist[0x797c7B11f619dfE9665b8e9f17F6666d3142f378] = 1;
        _whitelist[0xA4Da502fcdf699827AB39ec0Ebd5A7D298B8548b] = 1;
        _whitelist[0x31963b060d71ee24A6d458B75AA85E63b99Bd7fB] = 1;
        _whitelist[0xd8a2759c485f0028e1d494d9cFbFF61a857703Ba] = 1;
        _whitelist[0xd8e611961E49c21592f58DeFe9272e81E0880fF0] = 1;
        _whitelist[0xfd2c90dBA0BD1CAD3Eb8696A49e86d9d7Bf6A677] = 1;
        _whitelist[0x575BeF676A2d7EA43839D3DEb57bf94EBd603c3f] = 1;
        _whitelist[0x178f05180456bD8bfb58512B20a35F1ECaD8E488] = 1;
        _whitelist[0xd2bE77Ad97a8ae76061b14f60f8E75d0618a8Bc6] = 1;
        _whitelist[0xD7738712EC08Cf59C2F948E0Dc9E0535F2eFA2cE] = 1;
        _whitelist[0x6E3998bAB30F24d0B7bB09a24FBC7105F3f2dCf8] = 1;
        _whitelist[0xBFFc3dd2490c44015c6eA06d62B8bFac7F666663] = 1;
        _whitelist[0xfFd8074dFA81097A0eb770C25f8fE367B2017e5D] = 1;
        _whitelist[0xba779536c4AdAbC750F66053477C6BD63B5a814b] = 1;
        _whitelist[0x8d3bD8c1FefDd108b59a725a3A16276E43ceE6bb] = 1;
        _whitelist[0x17070EEC41395063CC046132cC95CE028bCA352E] = 1;
        _whitelist[0x27c017479C893226F8e8Ce6eDc862dFC1786F6c3] = 1;
        _whitelist[0x5685A0d411E88fdf99702189506540807C0fd4F0] = 1;
        _whitelist[0x414aE5317aC0109d3B4B78a739E46EF6594A8117] = 1;
        _whitelist[0x8D16e6AF9faa28277B4fef9F7225ab1642a7dC8E] = 1;
        _whitelist[0xD44EF5Ba2F992F44dB5F43630F0d0ECC3AE6D192] = 1;
        _whitelist[0x760a42570FAa7BC535B00Ef872DDbBFd15bf632A] = 1;
        _whitelist[0x654902C7fb6514376221e33dF2342452Df1B8a20] = 1;
        _whitelist[0xdDdB7aE1Db2a487059Ed87ADEfb534b60e183379] = 1;
        _whitelist[0x998B5660b069884a34D67A6D564d64374EF101CA] = 1;
        _whitelist[0x352465348315DAb6079B01EeC41d99E4630a6884] = 1;
        _whitelist[0x466AbBfb9AAb4C6dF6d3Cc03D6C63C43C5162048] = 1;
        _whitelist[0x91cEaECEeF3Fee475Cd6B1EB8a466BffF3276235] = 1;
        _whitelist[0x7aF81fCDfD6F9a5115d33518C3119A829eF996cF] = 1;
        _whitelist[0x64d7f75EB50C1FD3ab0f5b7a091017058265560C] = 1;
        _whitelist[0x3e276663F97c85FDbC4952Bb3f17667257b7ec06] = 1;
        _whitelist[0x2622A9d55d687E96C6320f64AD8c323ccD3B1115] = 1;
        _whitelist[0x228e7EF9ca9d993cDCdC51157EE3087ec0BFB1Ed] = 1;
        _whitelist[0x05cAAD8dd79807D1D31d089CE90Bde9c068dc743] = 1;
        _whitelist[0x005fe151D9185a30A11B3Fc7233ca3b2cfee7EC5] = 1;
        _whitelist[0xd181C2250DF5eb611D7d5Fc06725c71EF807B74D] = 1;
        _whitelist[0x2B64ba4D237D534971D7bE9F0323c0FE8d6ED374] = 1;
        _whitelist[0x479D10B2ECdD86ff92098E11693ABaa8A06e53ec] = 1;
        _whitelist[0x9DCAA39A7fB46f6d7281C636253473E43912Dd04] = 1;
        _whitelist[0x5c1a0FA9C926D570DF1db629A359507aE411957C] = 1;
        _whitelist[0xDA862691ab3F8fD3F28123b72146a571575E5E2A] = 1;
        _whitelist[0xE537161881499a8eded38aBD72A3A42e2CD02F14] = 1;
        _whitelist[0x077FdfA2aeC6b8094091E04832bAEfC29869fCE2] = 1;
        _whitelist[0x357521a8F37120730986504bfbC9AB3823014B02] = 1;
        _whitelist[0x9dB0d73BA0Ac7069A043dd61AF111d383cdf4959] = 1;
        _whitelist[0x6D27109eE133835817EB9F232CF5047879CA3BE9] = 1;
        _whitelist[0xbb379Fd5C382462B036285cf212ef86b447230Ac] = 1;
        _whitelist[0x7A6Be82e4268086D8BDb723F5ca7e3f47699528F] = 1;
        _whitelist[0xd999AD87f550BdeA462873EEC02C7a6aBb7dbC59] = 1;
        _whitelist[0x14BB901ba4B98898465a7dc9a1c27E4970183dcf] = 1;
        _whitelist[0xd8b13F3647122ce258c802f2A48B9b1774b72218] = 1;
        _whitelist[0xE9bCcf975C1D18839CC0522647Df6004d01DD4f9] = 1;
        _whitelist[0xE736E2f558B59fb333C9092fD407B1c8a775CED5] = 1;
        _whitelist[0xf39E5F6d386b79F981Aa58b5E53c50De81eb5f28] = 1;
        _whitelist[0xb36a66271b2c99043fE07C93fc4Bd723300d67ae] = 1;
        _whitelist[0xdb68A37014FaeaAB36f3d244f9649A6877d3b045] = 2;
        _whitelist[0x57325fFB486cfD1B943c77507ba339b0D5D1B546] = 1;
        _whitelist[0x47b40d0c64005c74666dCb348bd4a3D6A2e8Faf2] = 1;
        _whitelist[0xf7321Cb3Ab5EaD1C78187380D89c3c6Afb492C84] = 1;
        _whitelist[0xD930FA30c21cC729C11C550854A2f16eB545b38e] = 1;
        _whitelist[0xeC0D280929ed4a08F367CAD07bc5A3Bb4BB07687] = 1;
        _whitelist[0x70e8df8e5887b6Ca5A118B06E132fbBE69f0f736] = 2;
        _whitelist[0x4DA33Cf3100E5DA72285F1Cc282cf056ce0ADD51] = 1;
        _whitelist[0x680fffAEaF8A1888006b31FB1c1804eae8A2aE84] = 1;
        _whitelist[0xDff71A881a17737b6942FE1542F4b88128eA57D8] = 1;
        _whitelist[0x29cb02180D8d689918cE2c50A3357798d6Fd9283] = 1;
        _whitelist[0xeFF582CE2650FBe7fdf8b8d5DD70c2f71bc6e3BE] = 1;
        _whitelist[0xC4FBAfafE2eCe3b2b94Ab735A4079493faaE73B3] = 1;
        _whitelist[0x17C056d0e6A6D998ED9ea67Df252af7fcad9d998] = 1;
        _whitelist[0xD1333b41d5851eb2c229ee3ACf8b3afea2C6A486] = 1;
        _whitelist[0xd0d72Ed50588D4219c675a7d4235a7BfD832CafC] = 1;
        _whitelist[0x7C8867841cA13e9c5eF77b7abe4B4be4f4383DBB] = 1;
        _whitelist[0x64ae474dA28Db2Ef925b87E94a81C8F2783f6066] = 1;
        _whitelist[0x71fEA1Cc5B76E8bC5568dEb48C505f77B4C7920E] = 1;
        _whitelist[0x3D139eB16d79944a98EC3Db0A862f9CE98c576F5] = 1;
        _whitelist[0x815537cC9c4E54F232389E71C6413FEF905515C9] = 1;
        _whitelist[0xE62dA1963414DEAB63751989334ad71E55895620] = 1;
        _whitelist[0x178cb0E2a3d3eb0c0e76ef79b46e495A73a14f25] = 1;
        _whitelist[0x6CB5c9fd6df9Ec4fd1B61C611A88161965E0D7D0] = 1;
        _whitelist[0x3a67910fAc82Dd5cbb58B48cccea779E1e5334f0] = 1;
        _whitelist[0xf5434f31be443337F253892059740dDA019B0114] = 1;
        _whitelist[0x4cE4fD36C1040eC42f01566684b5D6424f142126] = 1;
        _whitelist[0xC7c2576E4564621d2371806e0B090AB85C4DC7b9] = 1;
        _whitelist[0x997B95a4a1eD6186A2de4D63f9ab1c95A918468a] = 1;
        _whitelist[0xBdA655472FEe2074e6bc6Db9F32ca15c786c182D] = 2;
        _whitelist[0xEFc53997a1143f6EC7d56a1b9CB8A137442F2Fd1] = 1;
        _whitelist[0xb6eeD98a7917953093992592D5A606e8d5c82BD5] = 1;
        _whitelist[0xf8c853ffA4A4f0ba3317A3AD97C9dCbbEe2f6c0f] = 1;
        _whitelist[0xe0024AB198F3F40a6EF41fCf05ed8aB153D16811] = 1;
        _whitelist[0x94E59547b8C68924380C90E729488f3E79FF8d22] = 1;
        _whitelist[0x0931D31509eCE624dF1058509D56452ae6C890F6] = 1;
        _whitelist[0x897a6D1A4e30470D9ACd5eCBb1F979cDB0F8Cdab] = 1;
        _whitelist[0x0628f16e2D1c51f6fe84D4300B63330e75e3a183] = 1;
        _whitelist[0xfD8Ce17208f8244175a6f06e522Df3E73fd843D8] = 1;
        _whitelist[0x700643004BA7Cb17B824C6808A4196a06eB25E4b] = 1;
        _whitelist[0x382DA0557343B6637cbD1ACF6BbB63DfF423D6cd] = 4;
        _whitelist[0xAD62DA09a5faC08c802aa97707186C9BE1838700] = 1;
        _whitelist[0x23E53e8215f3223D29F8b67708C384EEF2B42CC0] = 1;
        _whitelist[0x35548a028f67C7e2669b9D20D48185AaB452cF3F] = 1;
        _whitelist[0xfE9a4bd31077092cF33c82d9340CE751f53d1019] = 1;
        _whitelist[0x009268406b52502bF89024C992ab192D9CD81e1C] = 1;
        _whitelist[0xB5619CA0Bdd458EBfbc2b8B4b823E23D5717ea67] = 1;
        _whitelist[0xFda4067D5c3ECd62D6A62e47123496cba5d69408] = 1;
        _whitelist[0x38D4AA05B0C4445978BFB353c4aEDfc31b01dE86] = 1;
        _whitelist[0x31Ead29A17C14F5426d8cEe40c975f563B1daBfc] = 1;
        _whitelist[0x9c6E4c937b469f29eC5d790906B11Aa1410E3645] = 1;
        _whitelist[0x05D37a4A252459A8ce335E0b4E2852262aFD7616] = 1;
        _whitelist[0xaF85B139AA26c1A4C920Da0F63AAb2D571fD8AB5] = 1;
        _whitelist[0x1aB7966a006D47AFe62c315CC467d192d5A107A3] = 1;
        _whitelist[0x18e3cd7c20778a7cA1304E3a5698D2Ff85F14D9d] = 1;
        _whitelist[0x764aBE778aa96Cd04972444a8E1DB83dF13f7E66] = 1;
        _whitelist[0xf1ad3ED4b754c4B0D7b9d70F617191A8118B5Cf5] = 1;
        _whitelist[0x642458957C6F027fc1fea5B99928df23Fe46272E] = 1;
        _whitelist[0xfA8188bfE27Ce37C94BA87CD5717f622276A62D7] = 1;
        _whitelist[0x984b6717aFa9604e9C37eCBe44f7d12dE9c6A7d2] = 3;
        _whitelist[0x09715c29d8D8E8527853bcAcB90681048cC4E6c3] = 1;
        _whitelist[0x2DEf8c95901A01d4f8428083db4cE8B7d5f743aE] = 1;
        _whitelist[0x000091892804f655cC1ACA5BBe42944dbb972aB1] = 1;
        _whitelist[0x1f210AaEe2EfBc994dA696B8EfbD95AbbDe42Ae4] = 1;
        _whitelist[0xE1698607C930dC6330C5706827c033e1A810C8cd] = 1;
        _whitelist[0x950b45581ee4a2ad5E520053EE363859d9AE2BFd] = 1;
        _whitelist[0x4c2349B7c390cF1De6a37441D45b6C112159d3E9] = 1;
        _whitelist[0x79011Da8FBec0266A3ecE5170642c1738366d5b0] = 1;
        _whitelist[0xf0E2B96503e6ECa768afB08E342785363Dd9577E] = 1;
        _whitelist[0x232EE3d94be2274123CaE983f8Cc3E552ae0b559] = 1;
        _whitelist[0x5CD2460CC25FCA8f3a4ec6Ca0840fe381dc8Ff2a] = 1;
        _whitelist[0x15BC07A40596d5980f47982Fd8F95456Ac233Fc0] = 1;
        _whitelist[0xe408e6953A307f8f410a02a3e36A3ad9C48aabe5] = 1;
        _whitelist[0x18A86bDC70D9E30903fc7A67e9481Eb5Ae343B50] = 1;
        _whitelist[0x508385F810A96224f3c899646C465B3d05Bd4b72] = 1;
        _whitelist[0x5d988C4Da0440134E5F393a5B1fecd9233977e64] = 1;
        _whitelist[0x17bB250E7830041857ed026738250b69b97f10B0] = 1;
        _whitelist[0x221bb340a28506409a34D3c46f8E7B1cb88A403e] = 1;
        _whitelist[0x9A7bf91A97c79FF8D139DC06318e764Fd6521d26] = 1;
        _whitelist[0x49920FA4F34476D18864215486bA0d40e66C6Fb7] = 1;
        _whitelist[0xC6c0db5Cc1dfC71D3F9b9277FC9617483e4BCbBD] = 1;
        _whitelist[0xcB35A553e0D5242a1d50afE26E66953Eb0088b2F] = 1;
        _whitelist[0x86ac2D393b40a44842975f9A812EDB3F92018685] = 1;
        _whitelist[0x286DB56eAc9CF71ea582Ca6B499EBB908eb39C09] = 1;
        _whitelist[0x0cc376Ec3fAa9c17FF1F791343ad1B1556BDe19E] = 1;
        _whitelist[0xFba50D8f5133C32135d9798e1996e2b74dE7C7E6] = 1;
        _whitelist[0xa2140e9c5eA863Da58521737e566D27087E198c9] = 2;
        _whitelist[0xF6d47763f157f42E8BD711A3B41510267eaF4ba1] = 1;
        _whitelist[0xB1F0b13747F289Be7921165b0CBFBcC98C7bC5c4] = 1;
        _whitelist[0xcd32f12aDffda0291460f87D48D714bbdE4F11B7] = 1;
        _whitelist[0x09Bfa99BEcCBE7f815480219726Cd8e96b8a8F76] = 1;
        _whitelist[0x441B9f1BB3B37E529E800f5AA8E8aCC05B27FA00] = 1;
        _whitelist[0xA4E131A22DF699e6b3EE2933B614bD75457f6bd7] = 1;
        _whitelist[0x07dE15d5a6A345EeA702b457949E89DCFc3023f7] = 1;
        _whitelist[0xc03525eF5ba1d5e1262Dd573c78Ff3Ea6015F8DC] = 1;
        _whitelist[0x4E9dDdF23257B1Fe39d42c5C659627868800A78D] = 1;
        _whitelist[0x59e12d7C0bFa1B6728804Dc1D0071c911427C298] = 1;
        _whitelist[0x9a192D7AFe4450F723c3A7Be88f66b1B2B3B74DC] = 1;
        _whitelist[0x46D410b7fbaF1a2D43b48A07c15856Ad258120fa] = 1;
        _whitelist[0x460fb86D8E41C7776dddEb768013B28c95E69c69] = 1;
        _whitelist[0x3f9830a65A2CbB6E8F78D7F23308ba740C37d90a] = 1;
        _whitelist[0x11e41f95aa2CfC13E5E7F2126b5675119FDAFE8a] = 1;
        _whitelist[0xeeFbc827847d018d79095216674112eDA4Be2EC2] = 1;
        _whitelist[0xa2076DF4F3676fDDf4DD0b5fA27Df36b1A671593] = 1;
        _whitelist[0x411789076CB66b80Dc61a0cEd0dd43bfDEFe9864] = 1;
        _whitelist[0xAC3371936DE69e98071dc7c615e783234eC0b53f] = 1;
        _whitelist[0xBdE1b08071421AAB08BbB3133097A589891c25F5] = 1;
        _whitelist[0xa6585B22c2c7c92e80C33bb6620e2869BAd08CF5] = 1;
        _whitelist[0x06Ef623E6C10e397A0F2dFfa8c982125328e398c] = 1;
        _whitelist[0x86fEf6eC5320F6Cf9231f524aE89E198419CDC0F] = 1;
        _whitelist[0xdfF6B88d0372D71288103F3AC0A91a211A413794] = 1;
        _whitelist[0x69b31f245cf42fAF8A7a31db8E2285A6c6E31d66] = 1;
        _whitelist[0xE8dc63C8E7375cbe287Fc2CF63372075fC7108f6] = 1;
        _whitelist[0x793e48857f3CcdfE5CF3c504b6DFC7E8dab5b0e1] = 2;
        _whitelist[0x1D07B5638D08c45AAa079f724F854D09aA9e04A5] = 1;
        _whitelist[0x32FB6ACa62bFD1348ea07aeacee7729d63430e42] = 1;
        _whitelist[0x887eBa0e1D8DA256d07Eb378Cb8195a92BDc8488] = 1;
        _whitelist[0x8F4171a5d9540EeBe4bA9D021a6364d744514865] = 1;
        _whitelist[0x748c18cb8D115328bbED99CF98f4EbCE56F7D113] = 1;
        _whitelist[0xdFA18950c01320c307B3C8c10C7e7E622E26D800] = 1;
        _whitelist[0x13e256196FA6CE8CC7968333c7813819BB8a04e9] = 1;
        _whitelist[0x192B27876BAdFdB36f8ed3862179f650aE8C73B6] = 1;
        _whitelist[0xE0Cf727fa39307eb2eb029E0f2D575258e76cB73] = 1;
        _whitelist[0x8f7641846a6CE3a34Db36cE87daD2BBba7335411] = 1;
        _whitelist[0x2C7EA2dD243b43E38055ff20fe270907597b9735] = 1;
        _whitelist[0x4d85e79e60f7532Bd054bCd04D95cAF0d75d6BF6] = 1;
        _whitelist[0xc00158E782Edf67B7f657A52993Bf1E779381E21] = 1;
        _whitelist[0x24Bd267B0fe4CeFC617B4c4A103406616a7cc145] = 1;
        _whitelist[0x7b3Dc8D59A2027053cD00eDf4Af5b6a0408e654a] = 1;
        _whitelist[0x233f1ACE42d2d405FE014802de007c0823cC4dc0] = 1;
        _whitelist[0x9021748B9fB35d7d9E82Cad87d09c535F8f389DA] = 1;
        _whitelist[0x15f386A69eb29C2D284a655957e3B96A62Fb76D9] = 1;
        _whitelist[0xe138f5Ff35fD1DEd796520638E7782D258184533] = 1;
        _whitelist[0x6D0b3F2f99E24bD4AF14CABA3a94FcfCBaEF29DC] = 1;
        _whitelist[0xf7D1224Cbfc9660584728FA9d482253F0f2625a6] = 1;
        _whitelist[0xF969eb96e2a92CCe9922229ED4179aEF03B9CF05] = 1;
        _whitelist[0x500Eb89E9724528d9e26abbD624cacF0cCb485b3] = 1;
        _whitelist[0xd5F997BBbbec8750E31f2851859aC75Fd8272bc0] = 1;
        _whitelist[0x8121AE3FBB1345cB4EddA090Af164c8e9F73a46F] = 1;
        _whitelist[0x1B8061A0aF9c4eaAE4A8C5122d8287F764f0114F] = 1;
        _whitelist[0x47bc490fe3C93780821aD5D342A18eD6BB7243eA] = 1;
        _whitelist[0x02E6AAf160283a433081BdCCa73fC5aEA84a4aE3] = 1;
        _whitelist[0xb846673c0Bc1E16CdfCBBeA737Ee7172ae3f2942] = 1;
        _whitelist[0x4B049e4EDE517194fABEBBbf56Ba3525febd99A4] = 1;
        _whitelist[0x906EBF5dcAD2Ddb580aF5fdD0339299597e7D5b4] = 1;
        _whitelist[0x5d8241e7C9D5b22478d97875Aeef3F0AD35987a3] = 1;
        _whitelist[0x51f8BBC6d4275b1428B870feDc421BfE0477473f] = 1;
        _whitelist[0xf7356754FF673F69Ab0d2E77573c3d90365BA536] = 1;
        _whitelist[0x56302bf1C52368005aBeeC50D18D2213CDC91665] = 1;
        _whitelist[0xD1b4a271F26A821960c8dc3AE67DF8157899E8fc] = 1;
        _whitelist[0xc9C174300A90da9e835D77255F289604224E23E5] = 1;
        _whitelist[0xa6E7102f702C9b00FcB0F8b0EE7D521191402162] = 1;
        _whitelist[0xfE90b996aeB7051bDFfd5d840988B8673394297b] = 1;
        _whitelist[0x9CF984Db3421D88793d73f174F3A16FAc5aD5270] = 1;
        _whitelist[0x525022ECd0de305F714E108D3b4ce68928c2D81F] = 1;
        _whitelist[0x794F0FCfcEc2a5F2bF9733b73c13FDe1803E5780] = 1;
        _whitelist[0xdF221740ca82e5168f0398Fe0c006AF8e74a1977] = 1;
        _whitelist[0x9245fC07CF68Fb2161d68d4540c72903b8ec5Fb0] = 1;
        _whitelist[0x25255a36287c9DF4B2363Fd9F998CEEc7F12BEf0] = 1;
        _whitelist[0xb90EDcADE5e8aa93Bdb52F7f092f0d122ff7e983] = 1;
        _whitelist[0xB94f7Ed85B83A65709557433dF1c3c8F19F7c94f] = 1;
        _whitelist[0x00bD256B2730FE6E9D523209919B83b806290A3A] = 1;
        _whitelist[0x1c6C8898A3E576B9FEA3027ae55888A4e1200845] = 1;
        _whitelist[0xA06651Cd0EBe9FF6F559025934e24D807e6a75Ca] = 1;
        _whitelist[0x4523273c92e01E016b863D37a885288B7e43029f] = 1;
        _whitelist[0x774Cd866CEADf1871EfD610Ad30603FFb8034aE5] = 1;
        _whitelist[0xc71204D20d5b22CB95D264AeFa7beCd74bf756ac] = 1;
        _whitelist[0x681Ad212d2E7eeabb07c6403061ffCa4faA832b7] = 1;
        _whitelist[0xDBc5cC346Ba167fb7CF5E0Be898ceCD9d03Abb80] = 1;
        _whitelist[0x09C52C99e701304332B5998227f07D2648e8a72c] = 1;
        _whitelist[0xc771972C541c4600f0337B50f2a7F1378C66a3B0] = 1;
        _whitelist[0x5711A90f5192D244153eA5BD50De14B4d63359EC] = 1;
        _whitelist[0x0a0d8dF6fE0b5653DA7f6b6b93F4a0641C42F970] = 1;
        _whitelist[0x5A8F66b24de24e1c829e03c9D3EFD3343064083c] = 1;
        _whitelist[0x9805B78cE73255F2E25CB64947648f8F2752c8e4] = 1;
        _whitelist[0x0162b179c860D536DF3cECdbD65F971b03B5F10e] = 1;
        _whitelist[0xB9B98B8F559242C9694a08B6E6c1Dc4b50Fc340F] = 1;
        _whitelist[0x9De33BeE1353E65fE86Cc274F86Ade0439021576] = 1;
        _whitelist[0x29d109d06Bba4E6e2FC98a30e35702a63e53995A] = 1;
        _whitelist[0x6829B3Be1C0c14b292549e1f2d1224764C1bDD4E] = 1;
        _whitelist[0x218d5638Bf697e22EbB3CD4B6fbf73DCD1A8F035] = 1;
        _whitelist[0x49594Fb73a7912Bc6dA5D33a1060Aca029907086] = 1;
        _whitelist[0x85047527b7184033d5B7717Db659344717e404B6] = 1;
        _whitelist[0x643cd42f6FebBB0C6417169657161CDCc0bF4AAB] = 1;
        _whitelist[0xDb09Ca3b6D92250b33bfd5Ee8F5Db46420f2775F] = 1;
        _whitelist[0x2EdB4EdDB8C23Aa25d7b8D7D669660f99Bf8B4e0] = 1;
        _whitelist[0x2DF3f91A9947B652d94040215846C2110343c399] = 1;
        _whitelist[0xe4d56f7C4ceE091494CD9E86C078B238Fc7416C6] = 1;
        _whitelist[0x074fdC302F8D3C0E8B11C80F2A07BF2a3b8ca855] = 1;
        _whitelist[0xD645Ca671cba01470bEdDEE6A5132A501b959e0E] = 1;
        _whitelist[0xD7C13c218f33CC397102319382cA24284B26F089] = 1;
        _whitelist[0x33acED828E230dBc987BDcF9e086eCD81d7D88d8] = 1;
        _whitelist[0xA2B584e5f442f73038320F9e95A490b86ec27D62] = 1;
        _whitelist[0x9246307e550fbd40bcB6Ce18f96c7E4f7bAc0b7E] = 1;
        _whitelist[0xB0354d60D76407A803Eeb313f7213B75b5384c68] = 1;
        _whitelist[0x56061DE24b5dcEB6B94561032b75CC61D7c2807c] = 1;
        _whitelist[0xe22587927937515F7FF6A6cEcC94C1b2d30aC1B7] = 1;
        _whitelist[0x809a956Ca163188dEB520f10beCa9081a11a9beD] = 1;
        _whitelist[0x5787163458669c0364E5fC7d01Fe67106A75Acd2] = 1;
        _whitelist[0xDea1C6ce3F106a5fE37Bdc21aD9c90aaef335Cef] = 1;
        _whitelist[0xa3Cd8a52Ea9ab7baBEB564E09871DC43CCa8D19b] = 1;
        _whitelist[0x14B30b46ec4fA1a993806bd5Dda4195C5a82353e] = 1;
        _whitelist[0x960e7366BA7B09178FBE091B3Ed1De4e533C5A6C] = 1;
        _whitelist[0x72cD65DA5d108746Cb9c9574b86c3c1904e0Cfe8] = 1;
        _whitelist[0x6Ee6805d588113c1a8B2737c348889f58279915f] = 1;
        _whitelist[0x2De926e06c901Ac70D78C4c56F98CE672F562F50] = 1;
        _whitelist[0x773B5337c547CE517653D35783A4f0e404AC872F] = 1;
        _whitelist[0xfDF4E9880501623392025aC549e120CB9383E60e] = 1;
        _whitelist[0x81450f038842311cd7BF878a14bcAAD9529e5170] = 1;
        _whitelist[0x85fF57abe859faDA303AA7CB3F8C03775398dd62] = 1;
        _whitelist[0x025A046F1d27e7D473d2d838F53332D0cF5401B0] = 1;
        _whitelist[0x887A3F880FbF38517D948D860DF82fE8A95206b9] = 1;
        _whitelist[0x677989D892653b0f48eE47287d3522eA1f8E4825] = 1;
        _whitelist[0xf55914186a692a3335fF44ae107FA724b1074dDC] = 1;
        _whitelist[0x2321eE6246999a80443F217066921EEA123e81E0] = 1;
        _whitelist[0xf10944D1460c3820Fb2E144cFd6C3426B5Edc533] = 2;
        _whitelist[0xB484659880945aaD7ad451A4BE1DFd058ee09c94] = 1;
        _whitelist[0xD8086758DAabc3E734EF5971eb7e2AD8f32A2f81] = 1;
        _whitelist[0x39256C222e2A16DB63F21dA9d8266fC6f95f45b9] = 1;
        _whitelist[0x7A5C4cAF90e9211D7D474918F764eBdC2f9Ec1a3] = 1;
        _whitelist[0x3a04103F99623c6D9cf2Ad1C80b985639477E5Ec] = 2;
        _whitelist[0xbc56d4DA709742D07198636117910CBe939F6176] = 2;
        _whitelist[0x182B32912D74A620124F7BdC13f6dA38c5DbE8CF] = 3;
        _whitelist[0xB03fff6ad3f1eE2A0DcA9ec942fF191890E7f0b9] = 1;
        _whitelist[0xF166fbFd63201BFa03d06BFeC356e851E8c4A976] = 1;
        _whitelist[0x383462bb37beb393F17821fcFfC2Fe712756e977] = 2;
        _whitelist[0xa0E4B623ABC39a7C472dd03466722561750a90B1] = 1;
        _whitelist[0xC809d22A9E1b21B6b84a620FB280DFd381dd70a3] = 1;
        _whitelist[0xD5D021403AaA4C59c5C1e23CA14e45e566765fE0] = 1;
        _whitelist[0x4dDE7D4dAafFA88DE922b99fa0890Ff6872cDF59] = 1;
        _whitelist[0x8208bfe9625386503fb206bB3E2D62201C804C62] = 1;
        _whitelist[0xE07f78Bf7299a73f961cf8Cb62355401D150548A] = 1;
        _whitelist[0x2D8E6C0d3a44074bD003583187a43396888F04B9] = 1;
        _whitelist[0x09678D7f6187Ce98a2333F509D9fa8F9bCaA2C5E] = 1;
        _whitelist[0x9b9dD8A8737b00946F4e35D73b3aDD447f604dba] = 1;
        _whitelist[0x0122C0C70eC38Df1658402d412E27b2553e2cFAB] = 1;
        _whitelist[0x2EDb41E7Ad7E8A7c4ff0AeeDAEa1318e664bD003] = 1;
        _whitelist[0x7213bDEEeCE54a882eA253441c320718e5af06DF] = 1;
        _whitelist[0x98571cb4562672ec251A784cf9daB82c68A366Fb] = 1;
        _whitelist[0xf8295fa75053C9eF3fD792e31EBC2E2Df01957aB] = 1;
        _whitelist[0x8A5e04ad92edCdD75435055911cc02cd4EF9Be1B] = 1;
        _whitelist[0x0DD399a7ED92283e4983C2974FE377070D67f4eB] = 1;
        _whitelist[0xb0EcC3EAE0DA5C60BF99eE3D6136d8194ef61E55] = 1;
        _whitelist[0x0Df9D7f238E96317E8ca8aE5886DF2cd62D7398E] = 1;
        _whitelist[0xE2B527C0F207c27b1746E91B3A3c1f8afb4288bA] = 1;
        _whitelist[0x8Bc4fB84aCaEEa45aDD0b8D94047f64a59f97ffe] = 1;
    }
}