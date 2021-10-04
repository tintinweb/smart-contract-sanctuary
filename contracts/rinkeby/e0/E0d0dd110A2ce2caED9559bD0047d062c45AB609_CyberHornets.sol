/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

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


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/finance/[email protected]



pragma solidity ^0.8.0;



/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + _totalReleased;
        uint256 payment = (totalReceived * _shares[account]) / _totalShares - _released[account];

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account] + payment;
        _totalReleased = _totalReleased + payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}


// File contracts/CyberHornets.sol


pragma solidity ^0.8.0;



contract CyberHornets is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.08 ether;

    string public _baseTokenURI = '';
    
    string public HORNET_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;

    uint256 public MAX_SUPPLY = 8888;

    uint256 public _startTime = 1633687200;
    uint256 public _presaleStartTime = 1633600800;

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

    mapping(address => bool) private _hasPresaleAccess;

    // Withdrawal addresses
    address t1 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;
    address t2 = 0xe26CD2A3d583a1141f62Ec16c4A0a2d8f95027c9;

    address[] addressList = [t1, t2];
    uint256[] shareList = [10, 90];

    constructor()
    ERC721("Cyber Hornets Colony Club", "CHCC")
    PaymentSplitter(addressList, shareList)  {}

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= _presaleStartTime,                           "Presale has not started yet" );
        require( block.timestamp >= _startTime || _hasPresaleAccess[msg.sender], "General sale has not started yet" );
        require( _count <= MAX_TOKENS_PER_TRANSACTION,                           "You can mint a maximum of 20 Hornets per transaction" );
        require( supply + _count <= MAX_SUPPLY,                                  "Exceeds max Hornet supply" );
        require( msg.value >= _price * _count,                                   "Ether sent is not correct" );

        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Hornet supply");
        
        for(uint256 i; i < _count; i++){
            _safeMint(_wallet, supply + i );
        }
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        HORNET_PROVENANCE = _provenanceHash;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        _startTime = _newStartTime;
    }
    
    function setPresaleStartTime(uint256 _newStartTime) public onlyOwner {
        _presaleStartTime = _newStartTime;
    }

    function setPresaleAccessList(address[] memory _addressList) public onlyOwner {
        for(uint256 i; i < _addressList.length; i++){
            _hasPresaleAccess[_addressList[i]] = true;
        }
    }

    function hasPresaleAccess(address wallet) public view returns(bool) {
        return _hasPresaleAccess[wallet];
    }
}


// File contracts/PresaleAppend.sol


pragma solidity ^0.8.0;



contract PresaleAppend is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.08 ether;

    string public _baseTokenURI = '';
    
    string public HORNET_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;

    uint256 public MAX_SUPPLY = 8888;

    uint256 public _startTime = 1641013200;
    uint256 public _presaleStartTime = 1641013200;

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

    address[] private _presaleAccessList;
    mapping(address => bool) private _hasPresaleAccess;

    // Withdrawal addresses
    address t1 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;
    address t2 = 0xe26CD2A3d583a1141f62Ec16c4A0a2d8f95027c9;

    address[] addressList = [t1, t2];
    uint256[] shareList = [10, 90];

    constructor()
    ERC721("Cyber Hornets Colony Club", "CHCC")
    PaymentSplitter(addressList, shareList)  {}

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= _presaleStartTime,                           "Presale has not started yet" );
        require( block.timestamp >= _startTime || _hasPresaleAccess[msg.sender], "General sale has not started yet" );
        require( _count <= MAX_TOKENS_PER_TRANSACTION,                           "You can mint a maximum of 20 Hornets per transaction" );
        require( supply + _count <= MAX_SUPPLY,                                  "Exceeds max Hornet supply" );
        require( msg.value >= _price * _count,                                   "Ether sent is not correct" );

        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Hornet supply");
        
        for(uint256 i; i < _count; i++){
            _safeMint(_wallet, supply + i );
        }
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        HORNET_PROVENANCE = _provenanceHash;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        _startTime = _newStartTime;
    }
    
    function setPresaleStartTime(uint256 _newStartTime) public onlyOwner {
        _presaleStartTime = _newStartTime;
    }

    function setPresaleAccessList(address[] memory _addressList) public onlyOwner {
        for(uint256 i; i < _addressList.length; i++){
            _hasPresaleAccess[_addressList[i]] = true;
        }
    }

    function getPresaleAccessList() public onlyOwner view returns(address[] memory) {
        return _presaleAccessList;
    }

    function hasPresaleAccess(address checkAddress) public onlyOwner view returns(bool) {
        return _hasPresaleAccess[checkAddress];
    }
}


// File contracts/PresaleTest.sol


pragma solidity ^0.8.0;



contract PresaleTest is ERC721Enumerable, Ownable, PaymentSplitter {

    using Strings for uint256;

    uint256 private _price = 0.08 ether;

    string public _baseTokenURI = '';
    
    string public HORNET_PROVENANCE = '';

    uint256 public MAX_TOKENS_PER_TRANSACTION = 20;

    uint256 public MAX_SUPPLY = 8888;

    uint256 public _startTime = 1641013200;
    uint256 public _presaleStartTime = 1641013200;

    string public LICENSE_TEXT = ""; // IT IS WHAT IT SAYS

    bool licenseLocked = false; // TEAM CAN'T EDIT THE LICENSE AFTER THIS GETS TRUE

    mapping(uint => string) private _owners;

    event licenseisLocked(string _licenseText);

        address[] private _presaleAccessList = [
    0xa98B09073245c827A4DCd986af9ebe0e4CD849bf,
  0xD7dd3063623f14f375cca7ABfDa9Af084Eac25B0,
  0x1598EBD3c55cf30C93Bb873f4718ff6a64184801,
  0xaa036c491bf2E55E311a8f4f16924d42c391aa98,
  0x926C194a2D1e9A46898ff0586407020bEfbb14F6,
  0x45D70932b090DF1273C76Bf137EdFcc117F9EA62,
  0xe581583DB360B9c370F10860f773e8F4c6515171,
  0xBBDc1b572278B6A9C8A7eaB4e0EF412C4b37671A,
  0x0f68541Ee619507558aC272D8DfCa9f54C83B736,
  0xCAb76B2Aa06ecB68bff119cBE3D0153C4058092D,
  0x951218f5C3f34345FDA6efB300814Afa8511733b,
  0x7b32Ef94C0AcB12B19d92055f9bE30292b8c8843,
  0x6C9e67b3c8E7f2D068c995F60229ca19469f13ce,
  0x089a504508C380f2acDA079C4fceCb4091384211,
  0xbe3375D9479FdF8dEc07a477DC9697a1088afB44,
  0xA1f8074b5102bdB2CEFf6538d84055AD04E5Ff20,
  0x5f7588a6BE2fF068e284EFe95Cb7C697004feE42,
  0x831ee4c1DaFA579323DA76Ec935D585dd2A3bCcB,
  0x8cC1986A6d85F72DAE766Bb0AC6225B0f89945F8,
  0x4a29A2215A97e5CC7e2F1D004c0C39a1b09CD78b,
  0xaEba07fD76494841Fe6A237F24D3cd7fF9927dCe,
  0x6E937bB405D2A1F6775700Ec9f9D6BF0f614872c,
  0x3eDFd0637EC3fE645fe65FE32583cEebe6A984Ae,
  0xeCCf58a7Ea34C033796A2c38697b7f84B3293997,
  0x9f85FfedfAA5167496f86032adb9B07aA5253B14,
  0xC06cE7327634B3EED168161De517c34B6F4BF017,
  0x912468464ECd2A4EeddDf9349d955DCBc5b6f7DD,
  0xfEac6127D359121B59CC582175043d46593c5785,
  0xA02C1F62F7F90a046Ec4c3f059222735d98B7494,
  0x4997e2Fd05ff2aEc58548fD8E7eA2C37326Ff2A8,
  0x6e212f0e4AEA39ad6E65f2E347237edA1935E2A8,
  0x87b9B81E4042a989A591E257751daD23DC975dcb,
  0xafbd7f34AA3Aa9a37Cb7Cf01592f4a229D622c07,
  0x7989066C61e778Bf20d76dfb8E83F9f838D47425,
  0x613004112C61ED86e7a692aC9Ba1ad37FD9AB821,
  0x9fB3BD43d28655cD83c675fD21baB18c75581165,
  0x95aA33E6027c88B8ce98135A6FD62cB12d853fa3,
  0x23Ae059d512CA4d3eCe0A9f8aF3F0e371D9EBdC1,
  0xF63324a25Ac5429B2df493D5c1c43c0fC59a8455,
  0x384e3cc690e1d53b9579557609beeFb51E6F9FA8,
  0xD35a79BF159A3F386fE1bd4351e67fa5dfa8297e,
  0x2a770115469D19Ae38C3ff52676Bfa8aBE319Fb2,
  0x8Ba5abf500EDfe8C054db0F5BB4c28b3104d6093,
  0x7F821d2644Ad62B7ff185d1115f2D9833ec12a89,
  0xd6702Bc58e6458A94df2cc448951491A60aB9c86,
  0xAe1ed0Bf653e2bE1b6054FaB24C8732f98F9c50e,
  0x1406541ec756914D29996DbbC095BD514d77D59F,
  0xF89e224E90cD3dba26c651B0c61296aAfd64f2FB,
  0xbed2097A82C592882571E8b1069b6E5e3F10bF66,
  0x0D8FdAC93B2887bD79D4445Ce924ea0c75C10e49,
  0xCc7b4311Bbf99be553Ac9Daf0C6b04696ae7d5F5,
  0xfC343Fc5c6BbdB2B5059f2465CEb74F2Dc87ACa1,
  0xD06497b4830CD8Dd2106CE3C209bBB30460F13e2,
  0xe237D10bEE1cEc1e199dD23627868f271b9d6034,
  0xb40779Fbeec52B98c94F411B95994CdBfB42988E,
  0x0FbDB2C7937ad5a7719902c98216b2CBD4afd1bD,
  0x8B273c72D6C2856239fcF5DCCe97E82C4517Cd0D,
  0x2C2c80512003049c9acf7348F8B704761eFc010d,
  0x5E365fAb786643569AC771d46FFBb46d19fDd365,
  0xF8FeefB17854D491B144da119467a9351CCF96B8,
  0xE4299d0CA83C5aF2aEe037929414E19E7D0e49EE,
  0xa0a2EB44e0824EdE7bD24D49032ed6FA12200f70,
  0xd49Ca7b5f43A1BeeC4B555bEF041e5e4Fd3ace92,
  0xFB2Fe43cE425246D9Be270510ac0BfCBCd03CaB3,
  0x2596e158792c5c7bb88e4CaFe8Da67bC1C9576bB,
  0xA215caFEd88b11DC9bdacF0ea2FdfE4691d98918,
  0xdFD5582af14dA4A944763b7Fc7762aEa0a851c37,
  0x59037ae42e7FDff2a699756C0C2d6ae57c36044B,
  0x51309f19505742E68fEF676b838025121Fa6c3bf,
  0x12FB1BA56CdaBF6A2B5e148c91cDf6bd174897d0,
  0x1aaCa2f6c4B4C8A0cBE15D2948e9b61e1a83E3Ad,
  0x11167b8241F2e430e797754714d4039705F01c25,
  0x406df5660a3e1f364e8b2d125c1e0dF27aDe06B2,
  0xfbfC53dB4F9456D20D97914A24a54e2128ab1fAa,
  0xCa2aD69869009ba290b9d5A865E307F3a035B6f4,
  0xBBC9D8e583bdF3c35b186BED3e28c2B7c556437C,
  0xA42069f8BE7bA3641aDa5DA21Df765166501E229,
  0x2619C0Cf7261C86763563905a7b7624155B20107,
  0xC9Cfc92C5061960180B3A1e3BD2961Cd4424B205,
  0x426466201925fa2A0eDE04042EF652CF1a5FC077,
  0x0EA6ab297c2Bb997501B542c8C4585Bd83b3636e,
  0xf24295ef9b5e063fBc2fe392FE2e8c260f48b451,
  0xCa0b242ba182290c11C1569F7E9a7B7a1e66B009,
  0xB98a4C5f52949315dd2c1FFaBdC347413795158C,
  0xcfB213f3B3b120f5A25c5780aB1Fe8F405035912,
  0xe29FbFd33599fEAD75571C47EDd4B2C3e94C465D,
  0x2923331F61078D0D65bBA7367633244921A010Ab,
  0xf4a4A9F29850875bE1FF1227b2aC04DB14d58afe,
  0xEDeC999E609d2aEfd070bF6B369bed289A84c763,
  0xAB134Df8681fd3ABfd11D5eA66d892B7df593a6E,
  0xB45523eDCEBbC59e6531a4589cbB017172DA2588,
  0x34a24CCe6D519f1954FEDbd1ff46251Fc18dEb8B,
  0x3DeFDEE8c95FF2cbae4f331ff71F8d1FE1393E52,
  0x0e9C92148eB6ec2b24E7e5aa73A1cC92FFF06051,
  0xbcC56c191E6ADAE598382A914b2185BC31F0591D,
  0x4eBE2951b32E072356864972561Ce3888c7Ab09a,
  0x478551ce07C65d5fbEB2F1CDfcB6888ec383CB2F,
  0x16Bcc1e1C2A68Beb5F77Ed2C3D24F4E313808D72,
  0x5540D9000796682B9754997E78847453244fEC96,
  0x9E7e437763c778A55C4EB0aa15F1109eCEF890e4,
    0xa98B09073245c827A4DCd986af9ebe0e4CD849bf,
  0xD7dd3063623f14f375cca7ABfDa9Af084Eac25B0,
  0x1598EBD3c55cf30C93Bb873f4718ff6a64184801,
  0xaa036c491bf2E55E311a8f4f16924d42c391aa98,
  0x926C194a2D1e9A46898ff0586407020bEfbb14F6,
  0x45D70932b090DF1273C76Bf137EdFcc117F9EA62,
  0xe581583DB360B9c370F10860f773e8F4c6515171,
  0xBBDc1b572278B6A9C8A7eaB4e0EF412C4b37671A,
  0x0f68541Ee619507558aC272D8DfCa9f54C83B736,
  0xCAb76B2Aa06ecB68bff119cBE3D0153C4058092D,
  0x951218f5C3f34345FDA6efB300814Afa8511733b,
  0x7b32Ef94C0AcB12B19d92055f9bE30292b8c8843,
  0x6C9e67b3c8E7f2D068c995F60229ca19469f13ce,
  0x089a504508C380f2acDA079C4fceCb4091384211,
  0xbe3375D9479FdF8dEc07a477DC9697a1088afB44,
  0xA1f8074b5102bdB2CEFf6538d84055AD04E5Ff20,
  0x5f7588a6BE2fF068e284EFe95Cb7C697004feE42,
  0x831ee4c1DaFA579323DA76Ec935D585dd2A3bCcB,
  0x8cC1986A6d85F72DAE766Bb0AC6225B0f89945F8,
  0x4a29A2215A97e5CC7e2F1D004c0C39a1b09CD78b,
  0xaEba07fD76494841Fe6A237F24D3cd7fF9927dCe,
  0x6E937bB405D2A1F6775700Ec9f9D6BF0f614872c,
  0x3eDFd0637EC3fE645fe65FE32583cEebe6A984Ae,
  0xeCCf58a7Ea34C033796A2c38697b7f84B3293997,
  0x9f85FfedfAA5167496f86032adb9B07aA5253B14,
  0xC06cE7327634B3EED168161De517c34B6F4BF017,
  0x912468464ECd2A4EeddDf9349d955DCBc5b6f7DD,
  0xfEac6127D359121B59CC582175043d46593c5785,
  0xA02C1F62F7F90a046Ec4c3f059222735d98B7494,
  0x4997e2Fd05ff2aEc58548fD8E7eA2C37326Ff2A8,
  0x6e212f0e4AEA39ad6E65f2E347237edA1935E2A8,
  0x87b9B81E4042a989A591E257751daD23DC975dcb,
  0xafbd7f34AA3Aa9a37Cb7Cf01592f4a229D622c07,
  0x7989066C61e778Bf20d76dfb8E83F9f838D47425,
  0x613004112C61ED86e7a692aC9Ba1ad37FD9AB821,
  0x9fB3BD43d28655cD83c675fD21baB18c75581165,
  0x95aA33E6027c88B8ce98135A6FD62cB12d853fa3,
  0x23Ae059d512CA4d3eCe0A9f8aF3F0e371D9EBdC1,
  0xF63324a25Ac5429B2df493D5c1c43c0fC59a8455,
  0x384e3cc690e1d53b9579557609beeFb51E6F9FA8,
  0xD35a79BF159A3F386fE1bd4351e67fa5dfa8297e,
  0x2a770115469D19Ae38C3ff52676Bfa8aBE319Fb2,
  0x8Ba5abf500EDfe8C054db0F5BB4c28b3104d6093,
  0x7F821d2644Ad62B7ff185d1115f2D9833ec12a89,
  0xd6702Bc58e6458A94df2cc448951491A60aB9c86,
  0xAe1ed0Bf653e2bE1b6054FaB24C8732f98F9c50e,
  0x1406541ec756914D29996DbbC095BD514d77D59F,
  0xF89e224E90cD3dba26c651B0c61296aAfd64f2FB,
  0xbed2097A82C592882571E8b1069b6E5e3F10bF66,
  0x0D8FdAC93B2887bD79D4445Ce924ea0c75C10e49,
  0xCc7b4311Bbf99be553Ac9Daf0C6b04696ae7d5F5,
  0xfC343Fc5c6BbdB2B5059f2465CEb74F2Dc87ACa1,
  0xD06497b4830CD8Dd2106CE3C209bBB30460F13e2,
  0xe237D10bEE1cEc1e199dD23627868f271b9d6034,
  0xb40779Fbeec52B98c94F411B95994CdBfB42988E,
  0x0FbDB2C7937ad5a7719902c98216b2CBD4afd1bD,
  0x8B273c72D6C2856239fcF5DCCe97E82C4517Cd0D,
  0x2C2c80512003049c9acf7348F8B704761eFc010d,
  0x5E365fAb786643569AC771d46FFBb46d19fDd365,
  0xF8FeefB17854D491B144da119467a9351CCF96B8,
  0xE4299d0CA83C5aF2aEe037929414E19E7D0e49EE,
  0xa0a2EB44e0824EdE7bD24D49032ed6FA12200f70,
  0xd49Ca7b5f43A1BeeC4B555bEF041e5e4Fd3ace92,
  0xFB2Fe43cE425246D9Be270510ac0BfCBCd03CaB3,
  0x2596e158792c5c7bb88e4CaFe8Da67bC1C9576bB,
  0xA215caFEd88b11DC9bdacF0ea2FdfE4691d98918,
  0xdFD5582af14dA4A944763b7Fc7762aEa0a851c37,
  0x59037ae42e7FDff2a699756C0C2d6ae57c36044B,
  0x51309f19505742E68fEF676b838025121Fa6c3bf,
  0x12FB1BA56CdaBF6A2B5e148c91cDf6bd174897d0,
  0x1aaCa2f6c4B4C8A0cBE15D2948e9b61e1a83E3Ad,
  0x11167b8241F2e430e797754714d4039705F01c25,
  0x406df5660a3e1f364e8b2d125c1e0dF27aDe06B2,
  0xfbfC53dB4F9456D20D97914A24a54e2128ab1fAa,
  0xCa2aD69869009ba290b9d5A865E307F3a035B6f4,
  0xBBC9D8e583bdF3c35b186BED3e28c2B7c556437C,
  0xA42069f8BE7bA3641aDa5DA21Df765166501E229,
  0x2619C0Cf7261C86763563905a7b7624155B20107,
  0xC9Cfc92C5061960180B3A1e3BD2961Cd4424B205,
  0x426466201925fa2A0eDE04042EF652CF1a5FC077,
  0x0EA6ab297c2Bb997501B542c8C4585Bd83b3636e,
  0xf24295ef9b5e063fBc2fe392FE2e8c260f48b451,
  0xCa0b242ba182290c11C1569F7E9a7B7a1e66B009,
  0xB98a4C5f52949315dd2c1FFaBdC347413795158C,
  0xcfB213f3B3b120f5A25c5780aB1Fe8F405035912,
  0xe29FbFd33599fEAD75571C47EDd4B2C3e94C465D,
  0x2923331F61078D0D65bBA7367633244921A010Ab,
  0xf4a4A9F29850875bE1FF1227b2aC04DB14d58afe,
  0xEDeC999E609d2aEfd070bF6B369bed289A84c763,
  0xAB134Df8681fd3ABfd11D5eA66d892B7df593a6E,
  0xB45523eDCEBbC59e6531a4589cbB017172DA2588,
  0x34a24CCe6D519f1954FEDbd1ff46251Fc18dEb8B,
  0x3DeFDEE8c95FF2cbae4f331ff71F8d1FE1393E52,
  0x0e9C92148eB6ec2b24E7e5aa73A1cC92FFF06051,
  0xbcC56c191E6ADAE598382A914b2185BC31F0591D,
  0x4eBE2951b32E072356864972561Ce3888c7Ab09a,
  0x478551ce07C65d5fbEB2F1CDfcB6888ec383CB2F,
  0x16Bcc1e1C2A68Beb5F77Ed2C3D24F4E313808D72,
  0x5540D9000796682B9754997E78847453244fEC96,
  0x9E7e437763c778A55C4EB0aa15F1109eCEF890e4,
    0xa98B09073245c827A4DCd986af9ebe0e4CD849bf,
  0xD7dd3063623f14f375cca7ABfDa9Af084Eac25B0,
  0x1598EBD3c55cf30C93Bb873f4718ff6a64184801,
  0xaa036c491bf2E55E311a8f4f16924d42c391aa98,
  0x926C194a2D1e9A46898ff0586407020bEfbb14F6,
  0x45D70932b090DF1273C76Bf137EdFcc117F9EA62,
  0xe581583DB360B9c370F10860f773e8F4c6515171,
  0xBBDc1b572278B6A9C8A7eaB4e0EF412C4b37671A,
  0x0f68541Ee619507558aC272D8DfCa9f54C83B736,
  0xCAb76B2Aa06ecB68bff119cBE3D0153C4058092D,
  0x951218f5C3f34345FDA6efB300814Afa8511733b,
  0x7b32Ef94C0AcB12B19d92055f9bE30292b8c8843,
  0x6C9e67b3c8E7f2D068c995F60229ca19469f13ce,
  0x089a504508C380f2acDA079C4fceCb4091384211,
  0xbe3375D9479FdF8dEc07a477DC9697a1088afB44,
  0xA1f8074b5102bdB2CEFf6538d84055AD04E5Ff20,
  0x5f7588a6BE2fF068e284EFe95Cb7C697004feE42,
  0x831ee4c1DaFA579323DA76Ec935D585dd2A3bCcB,
  0x8cC1986A6d85F72DAE766Bb0AC6225B0f89945F8,
  0x4a29A2215A97e5CC7e2F1D004c0C39a1b09CD78b,
  0xaEba07fD76494841Fe6A237F24D3cd7fF9927dCe,
  0x6E937bB405D2A1F6775700Ec9f9D6BF0f614872c,
  0x3eDFd0637EC3fE645fe65FE32583cEebe6A984Ae,
  0xeCCf58a7Ea34C033796A2c38697b7f84B3293997,
  0x9f85FfedfAA5167496f86032adb9B07aA5253B14,
  0xC06cE7327634B3EED168161De517c34B6F4BF017,
  0x912468464ECd2A4EeddDf9349d955DCBc5b6f7DD,
  0xfEac6127D359121B59CC582175043d46593c5785,
  0xA02C1F62F7F90a046Ec4c3f059222735d98B7494,
  0x4997e2Fd05ff2aEc58548fD8E7eA2C37326Ff2A8,
  0x6e212f0e4AEA39ad6E65f2E347237edA1935E2A8,
  0x87b9B81E4042a989A591E257751daD23DC975dcb,
  0xafbd7f34AA3Aa9a37Cb7Cf01592f4a229D622c07,
  0x7989066C61e778Bf20d76dfb8E83F9f838D47425,
  0x613004112C61ED86e7a692aC9Ba1ad37FD9AB821,
  0x9fB3BD43d28655cD83c675fD21baB18c75581165,
  0x95aA33E6027c88B8ce98135A6FD62cB12d853fa3,
  0x23Ae059d512CA4d3eCe0A9f8aF3F0e371D9EBdC1,
  0xF63324a25Ac5429B2df493D5c1c43c0fC59a8455,
  0x384e3cc690e1d53b9579557609beeFb51E6F9FA8,
  0xD35a79BF159A3F386fE1bd4351e67fa5dfa8297e,
  0x2a770115469D19Ae38C3ff52676Bfa8aBE319Fb2,
  0x8Ba5abf500EDfe8C054db0F5BB4c28b3104d6093,
  0x7F821d2644Ad62B7ff185d1115f2D9833ec12a89,
  0xd6702Bc58e6458A94df2cc448951491A60aB9c86,
  0xAe1ed0Bf653e2bE1b6054FaB24C8732f98F9c50e,
  0x1406541ec756914D29996DbbC095BD514d77D59F,
  0xF89e224E90cD3dba26c651B0c61296aAfd64f2FB,
  0xbed2097A82C592882571E8b1069b6E5e3F10bF66,
  0x0D8FdAC93B2887bD79D4445Ce924ea0c75C10e49,
  0xCc7b4311Bbf99be553Ac9Daf0C6b04696ae7d5F5,
  0xfC343Fc5c6BbdB2B5059f2465CEb74F2Dc87ACa1,
  0xD06497b4830CD8Dd2106CE3C209bBB30460F13e2,
  0xe237D10bEE1cEc1e199dD23627868f271b9d6034,
  0xb40779Fbeec52B98c94F411B95994CdBfB42988E,
  0x0FbDB2C7937ad5a7719902c98216b2CBD4afd1bD,
  0x8B273c72D6C2856239fcF5DCCe97E82C4517Cd0D,
  0x2C2c80512003049c9acf7348F8B704761eFc010d,
  0x5E365fAb786643569AC771d46FFBb46d19fDd365,
  0xF8FeefB17854D491B144da119467a9351CCF96B8,
  0xE4299d0CA83C5aF2aEe037929414E19E7D0e49EE,
  0xa0a2EB44e0824EdE7bD24D49032ed6FA12200f70,
  0xd49Ca7b5f43A1BeeC4B555bEF041e5e4Fd3ace92,
  0xFB2Fe43cE425246D9Be270510ac0BfCBCd03CaB3,
  0x2596e158792c5c7bb88e4CaFe8Da67bC1C9576bB,
  0xA215caFEd88b11DC9bdacF0ea2FdfE4691d98918,
  0xdFD5582af14dA4A944763b7Fc7762aEa0a851c37,
  0x59037ae42e7FDff2a699756C0C2d6ae57c36044B,
  0x51309f19505742E68fEF676b838025121Fa6c3bf,
  0x12FB1BA56CdaBF6A2B5e148c91cDf6bd174897d0,
  0x1aaCa2f6c4B4C8A0cBE15D2948e9b61e1a83E3Ad,
  0x11167b8241F2e430e797754714d4039705F01c25,
  0x406df5660a3e1f364e8b2d125c1e0dF27aDe06B2,
  0xfbfC53dB4F9456D20D97914A24a54e2128ab1fAa,
  0xCa2aD69869009ba290b9d5A865E307F3a035B6f4,
  0xBBC9D8e583bdF3c35b186BED3e28c2B7c556437C,
  0xA42069f8BE7bA3641aDa5DA21Df765166501E229,
  0x2619C0Cf7261C86763563905a7b7624155B20107,
  0xC9Cfc92C5061960180B3A1e3BD2961Cd4424B205,
  0x426466201925fa2A0eDE04042EF652CF1a5FC077,
  0x0EA6ab297c2Bb997501B542c8C4585Bd83b3636e,
  0xf24295ef9b5e063fBc2fe392FE2e8c260f48b451,
  0xCa0b242ba182290c11C1569F7E9a7B7a1e66B009,
  0xB98a4C5f52949315dd2c1FFaBdC347413795158C,
  0xcfB213f3B3b120f5A25c5780aB1Fe8F405035912,
  0xe29FbFd33599fEAD75571C47EDd4B2C3e94C465D,
  0x2923331F61078D0D65bBA7367633244921A010Ab,
  0xf4a4A9F29850875bE1FF1227b2aC04DB14d58afe,
  0xEDeC999E609d2aEfd070bF6B369bed289A84c763,
  0xAB134Df8681fd3ABfd11D5eA66d892B7df593a6E,
  0xB45523eDCEBbC59e6531a4589cbB017172DA2588,
  0x34a24CCe6D519f1954FEDbd1ff46251Fc18dEb8B,
  0x3DeFDEE8c95FF2cbae4f331ff71F8d1FE1393E52,
  0x0e9C92148eB6ec2b24E7e5aa73A1cC92FFF06051,
  0xbcC56c191E6ADAE598382A914b2185BC31F0591D,
  0x4eBE2951b32E072356864972561Ce3888c7Ab09a,
  0x478551ce07C65d5fbEB2F1CDfcB6888ec383CB2F,
  0x16Bcc1e1C2A68Beb5F77Ed2C3D24F4E313808D72,
  0x5540D9000796682B9754997E78847453244fEC96,
  0x9E7e437763c778A55C4EB0aa15F1109eCEF890e4,
    0xa98B09073245c827A4DCd986af9ebe0e4CD849bf,
  0xD7dd3063623f14f375cca7ABfDa9Af084Eac25B0,
  0x1598EBD3c55cf30C93Bb873f4718ff6a64184801,
  0xaa036c491bf2E55E311a8f4f16924d42c391aa98,
  0x926C194a2D1e9A46898ff0586407020bEfbb14F6,
  0x45D70932b090DF1273C76Bf137EdFcc117F9EA62,
  0xe581583DB360B9c370F10860f773e8F4c6515171,
  0xBBDc1b572278B6A9C8A7eaB4e0EF412C4b37671A,
  0x0f68541Ee619507558aC272D8DfCa9f54C83B736,
  0xCAb76B2Aa06ecB68bff119cBE3D0153C4058092D,
  0x951218f5C3f34345FDA6efB300814Afa8511733b,
  0x7b32Ef94C0AcB12B19d92055f9bE30292b8c8843,
  0x6C9e67b3c8E7f2D068c995F60229ca19469f13ce,
  0x089a504508C380f2acDA079C4fceCb4091384211,
  0xbe3375D9479FdF8dEc07a477DC9697a1088afB44,
  0xA1f8074b5102bdB2CEFf6538d84055AD04E5Ff20,
  0x5f7588a6BE2fF068e284EFe95Cb7C697004feE42,
  0x831ee4c1DaFA579323DA76Ec935D585dd2A3bCcB,
  0x8cC1986A6d85F72DAE766Bb0AC6225B0f89945F8,
  0x4a29A2215A97e5CC7e2F1D004c0C39a1b09CD78b,
  0xaEba07fD76494841Fe6A237F24D3cd7fF9927dCe,
  0x6E937bB405D2A1F6775700Ec9f9D6BF0f614872c,
  0x3eDFd0637EC3fE645fe65FE32583cEebe6A984Ae,
  0xeCCf58a7Ea34C033796A2c38697b7f84B3293997,
  0x9f85FfedfAA5167496f86032adb9B07aA5253B14,
  0xC06cE7327634B3EED168161De517c34B6F4BF017,
  0x912468464ECd2A4EeddDf9349d955DCBc5b6f7DD,
  0xfEac6127D359121B59CC582175043d46593c5785,
  0xA02C1F62F7F90a046Ec4c3f059222735d98B7494,
  0x4997e2Fd05ff2aEc58548fD8E7eA2C37326Ff2A8,
  0x6e212f0e4AEA39ad6E65f2E347237edA1935E2A8,
  0x87b9B81E4042a989A591E257751daD23DC975dcb,
  0xafbd7f34AA3Aa9a37Cb7Cf01592f4a229D622c07,
  0x7989066C61e778Bf20d76dfb8E83F9f838D47425,
  0x613004112C61ED86e7a692aC9Ba1ad37FD9AB821,
  0x9fB3BD43d28655cD83c675fD21baB18c75581165,
  0x95aA33E6027c88B8ce98135A6FD62cB12d853fa3,
  0x23Ae059d512CA4d3eCe0A9f8aF3F0e371D9EBdC1,
  0xF63324a25Ac5429B2df493D5c1c43c0fC59a8455,
  0x384e3cc690e1d53b9579557609beeFb51E6F9FA8,
  0xD35a79BF159A3F386fE1bd4351e67fa5dfa8297e,
  0x2a770115469D19Ae38C3ff52676Bfa8aBE319Fb2,
  0x8Ba5abf500EDfe8C054db0F5BB4c28b3104d6093,
  0x7F821d2644Ad62B7ff185d1115f2D9833ec12a89,
  0xd6702Bc58e6458A94df2cc448951491A60aB9c86,
  0xAe1ed0Bf653e2bE1b6054FaB24C8732f98F9c50e,
  0x1406541ec756914D29996DbbC095BD514d77D59F,
  0xF89e224E90cD3dba26c651B0c61296aAfd64f2FB,
  0xbed2097A82C592882571E8b1069b6E5e3F10bF66,
  0x0D8FdAC93B2887bD79D4445Ce924ea0c75C10e49,
  0xCc7b4311Bbf99be553Ac9Daf0C6b04696ae7d5F5,
  0xfC343Fc5c6BbdB2B5059f2465CEb74F2Dc87ACa1,
  0xD06497b4830CD8Dd2106CE3C209bBB30460F13e2,
  0xe237D10bEE1cEc1e199dD23627868f271b9d6034,
  0xb40779Fbeec52B98c94F411B95994CdBfB42988E,
  0x0FbDB2C7937ad5a7719902c98216b2CBD4afd1bD,
  0x8B273c72D6C2856239fcF5DCCe97E82C4517Cd0D,
  0x2C2c80512003049c9acf7348F8B704761eFc010d,
  0x5E365fAb786643569AC771d46FFBb46d19fDd365,
  0xF8FeefB17854D491B144da119467a9351CCF96B8,
  0xE4299d0CA83C5aF2aEe037929414E19E7D0e49EE,
  0xa0a2EB44e0824EdE7bD24D49032ed6FA12200f70,
  0xd49Ca7b5f43A1BeeC4B555bEF041e5e4Fd3ace92,
  0xFB2Fe43cE425246D9Be270510ac0BfCBCd03CaB3,
  0x2596e158792c5c7bb88e4CaFe8Da67bC1C9576bB,
  0xA215caFEd88b11DC9bdacF0ea2FdfE4691d98918,
  0xdFD5582af14dA4A944763b7Fc7762aEa0a851c37,
  0x59037ae42e7FDff2a699756C0C2d6ae57c36044B,
  0x51309f19505742E68fEF676b838025121Fa6c3bf,
  0x12FB1BA56CdaBF6A2B5e148c91cDf6bd174897d0,
  0x1aaCa2f6c4B4C8A0cBE15D2948e9b61e1a83E3Ad,
  0x11167b8241F2e430e797754714d4039705F01c25,
  0x406df5660a3e1f364e8b2d125c1e0dF27aDe06B2,
  0xfbfC53dB4F9456D20D97914A24a54e2128ab1fAa,
  0xCa2aD69869009ba290b9d5A865E307F3a035B6f4,
  0xBBC9D8e583bdF3c35b186BED3e28c2B7c556437C,
  0xA42069f8BE7bA3641aDa5DA21Df765166501E229,
  0x2619C0Cf7261C86763563905a7b7624155B20107,
  0xC9Cfc92C5061960180B3A1e3BD2961Cd4424B205,
  0x426466201925fa2A0eDE04042EF652CF1a5FC077,
  0x0EA6ab297c2Bb997501B542c8C4585Bd83b3636e,
  0xf24295ef9b5e063fBc2fe392FE2e8c260f48b451,
  0xCa0b242ba182290c11C1569F7E9a7B7a1e66B009,
  0xB98a4C5f52949315dd2c1FFaBdC347413795158C,
  0xcfB213f3B3b120f5A25c5780aB1Fe8F405035912,
  0xe29FbFd33599fEAD75571C47EDd4B2C3e94C465D,
  0x2923331F61078D0D65bBA7367633244921A010Ab,
  0xf4a4A9F29850875bE1FF1227b2aC04DB14d58afe,
  0xEDeC999E609d2aEfd070bF6B369bed289A84c763,
  0xAB134Df8681fd3ABfd11D5eA66d892B7df593a6E,
  0xB45523eDCEBbC59e6531a4589cbB017172DA2588,
  0x34a24CCe6D519f1954FEDbd1ff46251Fc18dEb8B,
  0x3DeFDEE8c95FF2cbae4f331ff71F8d1FE1393E52,
  0x0e9C92148eB6ec2b24E7e5aa73A1cC92FFF06051,
  0xbcC56c191E6ADAE598382A914b2185BC31F0591D,
  0x4eBE2951b32E072356864972561Ce3888c7Ab09a,
  0x478551ce07C65d5fbEB2F1CDfcB6888ec383CB2F,
  0x16Bcc1e1C2A68Beb5F77Ed2C3D24F4E313808D72,
  0x5540D9000796682B9754997E78847453244fEC96,
  0x9E7e437763c778A55C4EB0aa15F1109eCEF890e4,
    0xa98B09073245c827A4DCd986af9ebe0e4CD849bf
    ];
    mapping(address => bool) private _hasPresaleAccess;

    // Withdrawal addresses
    address t1 = 0xda73C4DFa2F04B189A7f8EafB586501b4D0B73dC;
    address t2 = 0xe26CD2A3d583a1141f62Ec16c4A0a2d8f95027c9;

    address[] addressList = [t1, t2];
    uint256[] shareList = [10, 90];

    constructor()
    ERC721("Cyber Hornets Colony Club", "CHCC")
    PaymentSplitter(addressList, shareList)  {
        for(uint256 i; i < _presaleAccessList.length; i++){
            _hasPresaleAccess[_presaleAccessList[i]] = true;
        }
    }

    function mint(uint256 _count) public payable {
        uint256 supply = totalSupply();
        require( block.timestamp >= _presaleStartTime,                           "Presale has not started yet" );
        require( block.timestamp >= _startTime || _hasPresaleAccess[msg.sender], "General sale has not started yet" );
        require( _count <= MAX_TOKENS_PER_TRANSACTION,                           "You can mint a maximum of 20 Hornets per transaction" );
        require( supply + _count <= MAX_SUPPLY,                                  "Exceeds max Hornet supply" );
        require( msg.value >= _price * _count,                                   "Ether sent is not correct" );

        for(uint256 i; i < _count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function airdrop(address _wallet, uint256 _count) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_SUPPLY, "Exceeds maximum Hornet supply");
        
        for(uint256 i; i < _count; i++){
            _safeMint(_wallet, supply + i );
        }
    }

    // Just in case Eth does some crazy stuff
    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        HORNET_PROVENANCE = _provenanceHash;
    }
    
    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Invalid ID");
        return LICENSE_TEXT;
    }
    
    // Locks the license to prevent further changes 
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }
    
    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        _startTime = _newStartTime;
    }
    
    function setPresaleStartTime(uint256 _newStartTime) public onlyOwner {
        _presaleStartTime = _newStartTime;
    }

    function getPresaleAccessList() public onlyOwner view returns(address[] memory) {
        return _presaleAccessList;
    }
}


// File contracts/Migations.sol


pragma solidity >=0.4.22 <0.9.0;

contract Migrations {
  address public owner = msg.sender;

  // A function with the signature `last_completed_migration()`, returning a uint, is required.
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  // A function with the signature `setCompleted(uint)` is required.
  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}