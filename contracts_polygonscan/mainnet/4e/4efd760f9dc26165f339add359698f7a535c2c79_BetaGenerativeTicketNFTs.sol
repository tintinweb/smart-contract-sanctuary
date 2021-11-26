/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File contracts/interfaces/IPawnLoans.sol

pragma solidity 0.8.6;

interface IPawnLoans {
    // function mintLoan(address to, uint256 pawnTicketId) external;
    function mintMirrorTicket(address to, uint256 nftIndex) external;

    // function transferLoan(address from, address to, uint256 loanId) external;
}


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


// File base64-sol/[email protected]


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


// File contracts/generative/generative_nfts_get/NFTSVGGET.sol

pragma solidity 0.8.6;

library NFTSVGGET{

    struct SVGParams{
        string nftType; // "ticket" or "loan"
        string collateralAssetColor; // colour effect part 1
        string loanAssetColor; // colour efect part 2
        string id;
        string status;
        string interestRate;
        string loanAssetContract;
        string loanAssetContractPartial;
        string loanAssetSymbol;
        string collateralContract;
        string collateralContractPartial;
        string collateralAssetSymbol;
        string collateralId;
        string loanAmount;
        string interestAccrued;
        string endBlock;
    }

    // struct SVGParamsGET{
    //     string nftType; // header or name of event
    //     string collateralAssetColor; // 
    //     string loanAssetColor; // 
    //     string id; // nftIndex 
    //     string status; // ticket state
    //     string interestRate; // ticket price
    //     string loanAssetContract; // event address
    //     string loanAssetContractPartial; // 
    //     string loanAssetSymbol; // 
    //     string collateralContract; // shop address
    //     string collateralContractPartial; // 
    //     string collateralAssetSymbol; // WL
    //     string collateralId; // 
    //     string loanAmount; // backpack balance ticket
    //     string interestAccrued; // backpack value usd
    //     string endBlock; // startTime event
    // }

    function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
        return string(
                abi.encodePacked(
                    
                    
                    generateSvgHead(
                        params.nftType, 
                        params.id, 
                        params.loanAssetColor, 
                        params.collateralAssetColor
                    ),
                    
                    svgStatusAndRate(params.status, params.interestRate),
                    
                    svgAssetsInfo(
                        params.loanAssetContract,
                        params.loanAssetContractPartial,
                        params.loanAssetSymbol,
                        params.collateralContract,
                        params.collateralContractPartial,
                        params.collateralAssetSymbol, 
                        params.collateralId
                    ),
                    
                    
                    amountsSvg(
                        params.loanAmount, 
                        params.interestAccrued, 
                        params.loanAssetSymbol, 
                        params.endBlock
                    )
                ));
    }

    // function generateSVGGET(SVGParamsGET memory params) internal pure returns (string memory svg) {
    //     return string(
    //             abi.encodePacked(
    //                 generateSvgHead(params.nftType, params.id, params.loanAssetColor, params.collateralAssetColor),
    //                 svgStatusAndRate(params.status, params.interestRate),
    //                 svgAssetsInfo(
    //                     params.loanAssetContract,
    //                     params.loanAssetContractPartial,
    //                     params.loanAssetSymbol,
    //                     params.collateralContract,
    //                     params.collateralContractPartial,
    //                     params.collateralAssetSymbol, params.collateralId),
                    
    //                 amountsSvg(params.loanAmount, params.interestAccrued, params.loanAssetSymbol, params.endBlock)
    //             ));
    // }

    function generateSvgHead(
        string memory nftType,
        string memory nftIndex,
        string memory loanAssetColor,
        string memory collateralAssetColor) 
        private pure returns (string memory) {
        return string(
            abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 300 488" width="300" height="488" xml:space="preserve">',
        '<style type="text/css">',
            '.st0{fill:#FFFFFF; opacity:0.7;}',
            '.st1{font-family:sans-serif;}',
            '.st2{font-size:14px;}',
            '.st3{fill: purple;}',
            '.st4{fill: blue;}',
            '.st6{font-family:sans-serif; font-weight:bold; font-size: 18px;}',
            '.st8{fill:url(#wash);}',
            '.highlight-hue{stop-color:hsl(',
            collateralAssetColor,
            ',100%,85%)}',
            '.highlight-offset{stop-color:hsl(',
            loanAssetColor,
            ',100%,85%)}',
        '</style>',
        '<defs>',
            '<mask id="mask-marquee">',
            '<rect x="20" y="70" width="260" height="30" fill="#fff"/>',
            '</mask>',
            '<mask id="mask-amount">',
            '<rect x="124" y="341" width="146" height="30" fill="#fff"/>',
            '</mask>',
            '<mask id="mask-accrued">',
            '<rect x="146" y="382" width="124" height="30" fill="#fff"/>',
            '</mask>',
            '<radialGradient id="wash" cx="120" cy="40" r="140" gradientTransform="skewY(30)" gradientUnits="userSpaceOnUse">',
                '<stop  offset="0%" class="highlight-offset"/>',
                '<stop  offset="100%" class="highlight-hue"/>',
                '<animate attributeName="r" values="200;320;220;320;200" dur="15s" repeatCount="indefinite"/>',
                '<animate attributeName="cx" values="120;220;160;120;60;120" dur="15s" repeatCount="indefinite"/>',
                '<animate attributeName="cy" values="40;300;40;100;390;40" dur="15s" repeatCount="indefinite"/>',
            '</radialGradient>',
        '</defs>',
        '<use xlink:href="#:example" x="20" y="20"></use>',
        '<rect x="0" y="0" rx="10" ry="10" width="300" height="488" class="st8"/>',
        '<text x="300" y="90" mask="url(#mask-marquee)"><a href="https://explorer.get-protocol.io/ticket/',
        nftIndex,
        '" target="_blank"> <tspan class="st1 st2 st4"> https://explorer.get-protocol.io/ticket/',
        nftIndex,
            '</tspan></a><animate attributeName="x" values="300;-200" dur="10s" repeatCount="indefinite"/></text>'
        '<text x="300" y="90" class="st1 st2 st3" mask="url(#mask-marquee)">',
        keccak256(abi.encodePacked((nftType))) == keccak256(abi.encodePacked(('ticket'))),
        '<animate attributeName="x" values="300;-200" dur="10s" begin="4s" repeatCount="indefinite"/></text>',
        '<rect x="20" y="20" class="st0" width="260" height="50"/>',
        '<rect x="20" y="100" class="st0" width="260" height="40"/>',
        '<rect x="20" y="141" class="st0" width="260" height="40"/>',
        '<rect x="20" y="182" class="st0" width="260" height="40"/>',
        '<rect x="20" y="223" class="st0" width="260" height="40"/>',
        '<rect x="20" y="264" class="st0" width="260" height="40"/>',
        '<rect x="20" y="305" class="st0" width="260" height="40"/>',
        '<rect x="20" y="346" class="st0" width="260" height="40"/>',
        '<rect x="20" y="387" class="st0" width="260" height="40"/>',
        '<rect x="20" y="428" class="st0" width="260" height="40"/>',
        '<text transform="matrix(1 0 0 1 70 50)" class="st3 st6">',
        nftType,
        '</text>',
        '<text transform="matrix(1 0 0 1 35 125)"><tspan x="0" y="0" class="st1 st2">',
        "nftIndex: ", 
        '</tspan><tspan x="96" y="0" class="st4 st1 st2">',
        nftIndex,
        '</tspan></text>'
        ));
    }

    function svgStatusAndRate(string memory status, string memory interestRate) private pure returns (string memory svg) {
        return string(abi.encodePacked(
            '<text transform="matrix(1 0 0 1 35 166)"><tspan x="0" y="0" class="st1 st2">State:</tspan><tspan x="47" y="0" class="st3 st1 st2">',
            status,
            '</tspan></text>',
            '<text transform="matrix(1 0 0 1 35 207)"><tspan x="0" y="0" class="st1 st2">Price ($):</tspan><tspan x="80" y="0" class="st3 st1 st2">',
            interestRate,
            '</tspan></text>'
        ));
    }

    // function svgAssetsInfo(
    //     string memory loanAssetContract,
    //     string memory loanAssetContractPartial,
    //     string memory loanAssetSymbol,
    //     string memory collateralContract,
    //     string memory collateralAssetPartial,
    //     string memory collateralAssetSymbol,
    //     string memory collateralId
    //     ) internal pure returns (string memory svg) {
    //     return string(abi.encodePacked(
    //         '<text transform="matrix(1 0 0 1 35 248)"><tspan x="0" y="0" class="st1 st2">TicketFuel:</tspan><a href="https://polygonscan.io/address/',
    //         loanAssetContract,
    //         '" target="_blank"><tspan x="76" y="0" class="st4 st1 st2">(',
    //         loanAssetSymbol,
    //         ') ', 
    //         loanAssetContractPartial,
    //         '</tspan></a></text>',
    //         '<text transform="matrix(1 0 0 1 35 289)"><tspan x="0" y="0" class="st1 st2">Relayer:</tspan><a href="https://polygonscan.io/address/',
    //         collateralContract,
    //         '" target="_blank"><tspan x="120" y="0" class="st4 st1 st2">(',
    //         collateralAssetSymbol,
    //         ') ', 
    //         collateralAssetPartial,
    //         '</tspan></a></text>',
    //         '<text transform="matrix(1 0 0 1 35 330)"><tspan x="0" y="0" class="st1 st2">Owner address:</tspan><tspan x="82" y="0" class="st3 st1 st2">',
    //         collateralId,
    //         '</tspan></text>'
    //     ));
    // }
    


    function svgAssetsInfo(
        string memory loanAssetContract,
        string memory loanAssetContractPartial,
        string memory loanAssetSymbol,
        string memory collateralContract,
        string memory collateralAssetPartial,
        string memory collateralAssetSymbol,
        string memory collateralId
        ) internal pure returns (string memory svg) {
        return string(abi.encodePacked(
            '<text transform="matrix(1 0 0 1 35 248)"><tspan x="0" y="0" class="st1 st2">TicketFuel:</tspan><a href="https://polygonscan.io/address/',
            loanAssetContract,
            '" target="_blank"><tspan x="76" y="0" class="st4 st1 st2">', 
            loanAssetContract,
            '</tspan></a></text>',
            '<text transform="matrix(1 0 0 1 35 288)">Shop:<a href="',
            collateralAssetPartial,
            '" target="_blank"> <tspan class="st1 st2 st4"> ',
            collateralAssetPartial,
            '</tspan></a><animate attributeName="x" values="300;-200" dur="10s" repeatCount="indefinite"/></text>'

            '<text transform="matrix(1 0 0 1 35 330)"><tspan x="0" y="0" class="st1 st2">Owner:</tspan><a href="https://polygonscan.io/address/',
            collateralId,
            '" target="_blank"><tspan x="76" y="0" class="st4 st1 st2">', 
            collateralId,
            '</tspan></a></text>'
        ));
    }


    function amountsSvg(string memory loanAmount, string memory interestAccrued, string memory loanAssetSymbol, string memory endBlock) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<text transform="matrix(1 0 0 1 35 371)"><tspan x="0" y="0" class="st1 st2">Backpack bal:</tspan></text>',
                '<text x="300" y="371" class="st3 st1 st2" mask="url(#mask-amount)">',
                loanAmount,
                ' ',
                loanAssetSymbol,
                    '<animate attributeName="x" values="280;-60" dur="8s" repeatCount="indefinite"/></text>',
                '<text x="300" y="371" class="st3 st1 st2" mask="url(#mask-amount)">',
                loanAmount,
                ' ',
                loanAssetSymbol,
                    '<animate attributeName="x" values="280;-60" dur="8s" begin="4s" repeatCount="indefinite"/></text>',
                '<text transform="matrix(1 0 0 1 35 412)"><tspan x="0" y="0" class="st1 st2">Backpack $:</tspan></text>',
                '<text x="300" y="412" class="st3 st1 st2" mask="url(#mask-accrued)">',
                interestAccrued,
                ' ',
                "$ owned by DAO",
                    '<animate attributeName="x" values="280;-60" dur="8s" repeatCount="indefinite"/></text>',
                '<text x="300" y="412" class="st3 st1 st2" mask="url(#mask-accrued)">',
                interestAccrued,
                ' ',
                "$ fee owned by GET DAO $",
                    '<animate attributeName="x" values="280;-60" dur="8s" begin="4s" repeatCount="indefinite"/></text>',
                '<text transform="matrix(1 0 0 1 35 453)"><tspan x="0" y="0" class="st1 st2">Event start: </tspan><tspan x="88" y="0" class="st3 st1 st2">',
                endBlock,
                '</tspan></text>',
                '</svg>'
            )
        );
    }
}


// File contracts/generative/HexStrings.sol

pragma solidity 0.8.6;

library HexStrings {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function partialHexString(uint160 value) internal pure returns (string memory) {
        uint8 length = 2;
        bytes memory buffer = new bytes(2 * length + 5);
        buffer[0] = '0';
        buffer[1] = 'x';
        uint8 offset = 2 * length + 1;
        for (uint8 i = offset; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        // uint8 offset 
        buffer[offset + 1] = '.';
        buffer[offset + 2] = '.';
        buffer[offset + 3] = '.';
        return string(buffer);
    }

    /// @notice Converts a `uint160` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint160 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
}


// File contracts/generative/UintStrings.sol

pragma solidity 0.8.6;


library UintStrings {
    function decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns(string memory){
        if(number == 0){
            return isPercent ? "0%" : "0";
        }
        
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if(tenPowDecimals > number){
                // number is less than one
                // in this case, there may be leading zeros after the decimal place 
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    // With modifications, From https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/NFTDescriptor.sol#L189-L231

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}


// File contracts/interfaces/IBaseGET.sol

pragma solidity ^0.8.0;

interface IBaseGET {
    enum TicketStates {
        UNSCANNED,
        SCANNED,
        CLAIMABLE,
        INVALIDATED,
        PREMINTED,
        COLLATERALIZED,
        CLAIMED
    }
    // enum TicketStates { UNSCANNED, SCANNED, CLAIMABLE, INVALIDATED }

    struct TicketData {
        address eventAddress;
        bytes32[] ticketMetadata;
        uint256[2] salePrices;
        TicketStates state;
    }

    function primarySale(
        address eventAddress,
        uint256 id,
        uint256 primaryPrice,
        uint256 basePrice,
        uint256 orderTime,
        bytes memory data,
        bytes32[] memory ticketMetadata
    ) external;

    function primaryBatchSale(
        address eventAddress,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory basePrices,
        uint256 orderTime,
        bytes memory meta
    ) external;

    function secondaryTransfer(
        uint256 id,
        address eventAddress,
        uint256 orderTime,
        uint256 primaryPrice,
        uint256 secondaryPrice
    ) external;

    function collateralMint(
        address basketAddress,
        address eventAddress,
        uint256 primaryPrice,
        bytes32[] calldata ticketMetadata
    ) external returns (uint256);

    function scanNFT(address originAddress, uint256 orderTime) external;

    function invalidateNFT(
        uint256 id,
        uint256 orderTime,
        address eventAddress
    ) external;

    function claimGetNFT(
        uint256 id,
        address eventAddress,
        address externalAddress,
        uint256 orderTime,
        bytes memory data
    ) external;

    function setOnChainSwitch(bool _switchState, uint256 _refactorSwapIndex) external;

    /// VIEW FUNCTIONS

    function ticketMetadataIndex(
        uint256 _nftIndex
    ) external view returns(
          address _eventAddress,
          bytes32[] memory _ticketMetadata,
          uint32[2] memory _salePrices,
          TicketStates _stateTicket
    );

    // function ticketMetadataIndex(
    //     uint256 _nftIndex
    // ) external view returns(
    //       address _eventAddress,
    //       bytes32[] memory _ticketMetadata,
    //       uint32[2] memory _salePrices,
    //       uint8 _stateTicket
    // );

    function isNFTClaimable(uint256 nftIndex, address ownerAddress) external view returns (bool);

    function returnStruct(uint256 nftIndex) external view returns (TicketData memory);

    function returnStructTicket(uint256 nftIndex) external view returns (TicketData memory);

    function addressToIndex(address ownerAddress) external view returns (uint256);

    function viewPrimaryPrice(uint256 nftIndex) external view returns (uint32);

    function viewLatestResalePrice(uint256 nftIndex) external view returns (uint32);

    function viewEventOfIndex(uint256 nftIndex) external view returns (address);

    function viewTicketMetadata(uint256 nftIndex) external view returns (bytes32[] memory);

    function viewTicketState(uint256 nftIndex) external view returns (uint256);
}


// File contracts/interfaces/IEventMetadataStorage.sol

pragma solidity ^0.8.0;

interface IEventMetadataStorage {
    function registerEvent(
        address eventAddress,
        address integratorAccountPublicKeyHash,
        string calldata eventName,
        string calldata shopUrl,
        string calldata imageUrl,
        bytes32[4] calldata eventMeta, // -> [bytes32 latitude, bytes32 longitude, bytes32  currency, bytes32 ticketeerName]
        uint256[2] calldata eventTimes, // -> [uin256 startingTime, uint256 endingTime]
        bool setAside, // -> false = default
        bytes32[] calldata extraData,
        bool isPrivate
    ) external;

    function getEventData(
      address eventAddress)
        external view
        returns (
          address _relayerAddress,
          address _underWriterAddress,
          string memory _eventName,
          string memory _shopUrl,
          string memory _imageUrl,
          bytes32[4] memory _eventMeta,
          uint256[2] memory _eventTimes,
          bool _setAside,
          bytes32[] memory _extraData,
          bool _privateEvent
        );

    function doesEventExist(address eventAddress) external view returns (bool);

    event NewEventRegistered(address indexed eventAddress, string indexed eventName, uint256 indexed timestamp);
    
    event UnderWriterSet(address eventAddress, address underWriterAddress, address requester);
}


// File contracts/interfaces/IEconomicsGET.sol

pragma solidity ^0.8.0;

interface IEconomicsGET {
    struct DynamicRateStruct {
        bool configured; // 0
        uint32 mintRate; // 1
        uint32 resellRate; // 2
        uint32 claimRate; // 3
        uint32 crowdRate; // 4
        uint32 scalperFee; // 5
        uint32 extraFee; // 6
        uint32 shareRate; // 7
        uint32 editRate; // 8
        uint32 maxBasePrice; // 9
        uint32 minBasePrice; // 10
        uint32 reserveSlot_1; // 11
        uint32 reserveSlot_2; // 12
    }

    function fuelBackpackTicket(address relayerAddress, uint256 basePrice) external returns (uint256);

    function fuelBatchBackpackTickets(
        uint256[] memory ids,
        address relayerAddress,
        uint256[] memory basePrices
    ) external returns (uint256 fuel);

    function emptyBackpackBasic(address relayerAddress) external returns (uint256 _bal);

    function chargeTaxRateBasic(address relayerAddress) external returns (uint256 _tax);

    function swipeDepotBalance() external;

    function emergencyWithdrawAllFuel() external;

    function topUpBuffer(
        uint256 topUpAmount,
        uint256 priceGETTopUp,
        address relayerAddress,
        address bufferAddress
    ) external returns (uint256);

    function setRelayerBuffer(address _relayerAddress, address _bufferAddressRelayer) external;

    /// VIEW FUNCTIONS

    function checkRelayerConfiguration(address _relayerAddress) external view returns (bool);

    function balanceRelayerSilo(address relayerAddress) external view returns (uint256);

    function valueRelayerSilo(address _relayerAddress) external view returns (uint256);

    function estimateNFTMints(address _relayerAddress) external view returns (uint256);

    function viewRelayerFactor(address _relayerAddress) external view returns (uint256);

    function viewRelayerGETPrice(address _relayerAddress) external view returns (uint256);

    function viewBackPackValue(uint256 _nftIndex, address _relayerAddress) external view returns (uint256);

    function viewBackPackBalance(uint256 _nftIndex) external view returns (uint256);

    function viewDepotBalance() external view returns (uint256);

    function viewDepotValue() external view returns (uint256);
}


// File contracts/interfaces/INFT_ERC721V3.sol

pragma solidity ^0.8.0;

interface IGET_ERC721V3 {
    
    function mintERC721(
        address destinationAddress,
        string calldata ticketURI
    ) external returns(uint256);

    function mintERC721_V3(
        address destinationAddress
    ) external returns(uint256);
    
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns(uint256);
    
    function balanceOf(
        address owner
    ) external view returns(uint256);
    
    function relayerTransferFrom(
        address originAddress, 
        address destinationAddress, 
        uint256 nftIndex
    ) external;
    
    function changeBouncer(
        address _newBouncerAddress
    ) external;

    function isNftIndex(
        uint256 nftIndex
    ) external view returns(bool);

    function ownerOf(
        uint256 nftIndex
    ) external view returns (address);

    function setApprovalForAll(
        address operator, 
        bool _approved) external;

}


// File contracts/generative/generative_nfts_get/NFTDescriptorGET.sol

pragma solidity 0.8.6;








contract NFTDescriptorGET {
    bytes32 ticketTypeHash; 
    address public BaseGET721;
    address public MetadataStorage;
    address public EconomicsGET;
    address public ERC721;

    constructor(
        address _BaseGET721,
        address _MetadataStorage,
        address _EconomicsGET,
        address _ERC721
    ) public {
        ticketTypeHash = keccak256(abi.encodePacked(("ticket")));
        BaseGET721 = _BaseGET721;
        MetadataStorage = _MetadataStorage;
        EconomicsGET = _EconomicsGET;
        ERC721 = _ERC721;
    }

    function ticketURI(uint256 nftIndex)
        external
        view
        returns (string memory)
    {
        NFTSVGGET.SVGParams memory svgParams;
        svgParams.nftType = "ticket";
        return uri(svgParams, nftIndex);
    }

    function uri(NFTSVGGET.SVGParams memory svgParams, uint256 nftIndex)
        private
        view
        returns (string memory)
    {
        (address _eventAddress, ,uint32[2] memory _salesPrices, IBaseGET.TicketStates _ticketState) = IBaseGET(BaseGET721).ticketMetadataIndex(nftIndex);

        (address _relayerAddress, , string memory _eventName, string memory _shopURL, , , uint256[2] memory _eventTimes, , ,) = IEventMetadataStorage(MetadataStorage).getEventData(_eventAddress);

        svgParams.loanAssetColor = UintStrings.decimalString(uint8(keccak256(abi.encodePacked(_eventAddress))[0]), 0, false);

        svgParams.collateralAssetColor = UintStrings.decimalString(uint8(keccak256(abi.encodePacked(IGET_ERC721V3(ERC721).ownerOf(nftIndex)))[0]), 0, false);

        svgParams.nftType = _eventName;

        svgParams.id = UintStrings.decimalString(nftIndex, 0, false);

        svgParams.status = ticketStatus(uint8(_ticketState));

        svgParams.interestRate = primaryTicketPriceString(_salesPrices); 

        svgParams.loanAssetContract = HexStrings.toHexString(uint160(0xdb725f82818De83e99F1dAc22A9b5B51d3d04DD4), 20);

        svgParams.loanAssetContractPartial = HexStrings.partialHexString(uint160(0xdb725f82818De83e99F1dAc22A9b5B51d3d04DD4));

        svgParams.loanAssetSymbol = "GET";
        
        svgParams.collateralContract = HexStrings.toHexString(uint160(_relayerAddress), 20);

        svgParams.collateralContractPartial = _shopURL;

        svgParams.collateralId = HexStrings.toHexString(uint160(IGET_ERC721V3(ERC721).ownerOf(nftIndex)), 20);

        svgParams.loanAmount = fuelAmountString(IEconomicsGET(EconomicsGET).viewBackPackBalance(nftIndex));

        svgParams.interestAccrued = fuelValueString(IEconomicsGET(EconomicsGET).viewBackPackValue(nftIndex, _relayerAddress));

        svgParams.endBlock = UintStrings.decimalString(_eventTimes[0], 0, false);

        return generateDescriptor(svgParams);
    }

    function primaryTicketPriceString(uint32[2] memory _salesPrices) private view returns (string memory){
        return UintStrings.decimalString(_salesPrices[0], 3, false);
    }

    // function secondaryTicketPriceString(uint32[2] memory _salesPrices) private view returns (string memory){
    //     if (_salesPrices[1] == 0) {
    //         return "Ticket not resold";
    //     } else {
    //         return UintStrings.decimalString(_salesPrices[1], 2, false);
    //     }
    // }

    // function loanAmountString(uint256 amount, address asset) private view returns (string memory){
    //     return UintStrings.decimalString(amount, IERC20(asset).decimals(), false);
    // }

    function fuelAmountString(uint256 amount) private view returns (string memory){
        return UintStrings.decimalString(amount, 18, false);
    }

    function fuelValueString(uint256 amount) private view returns (string memory){
    return UintStrings.decimalString(amount, 3, false);
}

    // function loanAssetSymbol(address asset) private view returns (string memory){
    //     return "GET";
    // }

    // function collateralAssetSymbol(address asset) private view returns (string memory){
    //     return ERC721(asset).symbol();
    // }

    // function relayerSymbol(address _relayerAddress) private view returns (string memory){
    //     if (_relayerAddress == "0x383F07EccE503801F636Ad455106e270748bdE05") {
    //         return "GUTS";
    //     } else {
    //         return "YTP";
    //     }
    // }

    // function accruedInterest(NFTPawnShopGET pawnShop, uint256 pawnTicketId, address loanAsset) private view returns(string memory){
    //     return UintStrings.decimalString(pawnShop.interestOwed(pawnTicketId), IERC20(loanAsset).decimals(), false);
    // }

    // function accruedInterest(NFTPawnShopGET pawnShop, uint256 pawnTicketId, address loanAsset) private view returns(string memory){
    //     return UintStrings.decimalString(pawnShop.interestOwed(pawnTicketId), IERC20(loanAsset).decimals(), false);
    // }

    // function perBlockInterestToAnnual(uint256 perBlockInterest) private pure returns(uint256) {
    //     return perBlockInterest * 2252571; // block every 14s, (60/14)*60*24*365 ~= 2252571 blocks per year
    // }

    // function loanStatus(uint256 lastAccumulatedBlock, uint256 blockDuration, bool closed, bool collateralSeized) view private returns(string memory){
    //     if(lastAccumulatedBlock == 0){
    //         return "awaiting underwriter";
    //     }

    //     if(collateralSeized){
    //         return "collateral seized";
    //     }

    //     if(closed){
    //         return "repaid and closed";
    //     }

    //     if(block.number > (lastAccumulatedBlock + blockDuration)){
    //         return "past due";
    //     }

    //     return 'underwritten';
    // }

    function ticketStatus(
        uint8 _ticketState
    ) view private returns(string memory){
        if(_ticketState == 0){
            return "unscanned (valid ticket)";
        }

        if(_ticketState == 1){
            return "scanned (invalid ticket)";
        }

        if(_ticketState == 2){
            return "claimed / ready to be claimed";
        }

        if(_ticketState == 3){
            return "invalidated by issuer";
        }

        if(_ticketState == 4){
            return "preminted (event financing)";
        }

        if(_ticketState == 5){
            return "colleterized (event financing)";
        }

        return "unknown state";
    }


    function generateDescriptor(NFTSVGGET.SVGParams memory svgParams)
        private
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                'GET Protocol generative NFT representing a smart ticket  - POC/TESTING/BETA DESIGN  - Event name: ',
                                svgParams.nftType,
                                ' #',
                                svgParams.id,
                                '", "ticket description":"',
                                generateDescription(
                                    svgParams.id,
                                    svgParams.nftType),
                                generateDescriptionDetails(
                                    svgParams.id,
                                    svgParams.nftType,
                                    svgParams.collateralContract), 
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                Base64.encode(bytes(NFTSVGGET.generateSVG(svgParams))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateDescription(
        string memory pawnTicketId,
        string memory nftType
        ) private view returns (string memory){
        if (keccak256(abi.encodePacked((nftType))) == ticketTypeHash){
            return generateTicketDescription();
        }
        return generateLoanDescription(pawnTicketId);
    }

    function generateLoanDescription(string memory pawnTicketId) private pure returns (string memory){
            return string(
                abi.encodePacked(
                    'TESTING This is a generative ticket NFT of the GET Protocol. Ticket nftIndex:', 
                    pawnTicketId,
                    'By GET Protocol.'
                )
            );
    }

    function generateTicketDescription() private pure returns (string memory){
            return string(
                abi.encodePacked(
                    'This generative NFT was minted to test the possibilies.'
                )
            );
    }

    function generateDescriptionDetails(
        string memory nftIndex,
        string memory eventName,
        string memory relayerAdress
        ) private pure returns (string memory){
            return string(
                abi.encodePacked(
                    'Ticket Fuel token address: ',
                    "0xdb725f82818de83e99f1dac22a9b5b51d3d04dd4",
                    ' (',
                    "GET",
                    ')\\n',
                    'Ticket nftIndex: ',
                    nftIndex,
                    '\\n',
                    'Relayer address: ',
                    relayerAdress,
                    ' (',
                    "",
                    ')\\n',
                    'Event name: ',
                    eventName,
                    ' (',
                    "",
                    ')\\n',
                    'WARNING: Do your own research to verify the legitimacy of this ticket'
                )
            );
    }
}


// File contracts/generative/generative_nfts_get/BetaGenerativeTicketNFTs.sol

pragma solidity 0.8.6;




contract BetaGenerativeTicketNFTs is ERC721, IPawnLoans {
    address public minter;
    // address private immutable _tokenDescriptor;

    string private tokenURICheating = "data:application/json;base64,eyJuYW1lIjoiSW1wcmVzc2l2ZSBPbmlpIDEwMCIsICJkZXNjcmlwdGlvbiI6IkdlbmVyYXRlZCBieSAweDMzYjE3M2E3OTU3NmY1ZjY2MTM3ZjNmMzRmYjY4NzVmZmI4ZTU2ZDcgYXQgMTYzMTMwMDQ4MCIsICJhdHRyaWJ1dGVzIjpbeyAidHJhaXRfdHlwZSIgOiAiQm9keSIsICJ2YWx1ZSIgOiAiSHVtYW4iIH0seyAidHJhaXRfdHlwZSIgOiAiSGFpciIsICJ2YWx1ZSIgOiAiU3Bpa2UgQmxhY2siIH0seyAidHJhaXRfdHlwZSIgOiAiTW91dGgiLCAidmFsdWUiIDogIkV2aWwiIH0seyAidHJhaXRfdHlwZSIgOiAiTm9zZSIsICJ2YWx1ZSIgOiAiQ2xhc3NpYyIgfSx7ICJ0cmFpdF90eXBlIiA6ICJFeWVzIiwgInZhbHVlIiA6ICJTdHVudCIgfSx7ICJ0cmFpdF90eXBlIiA6ICJFeWVicm93IiwgInZhbHVlIiA6ICJTbWFsbCIgfSx7ICJ0cmFpdF90eXBlIiA6ICJNYXJrIiwgInZhbHVlIiA6ICJNb29uIiB9LHsgInRyYWl0X3R5cGUiIDogIkFjY2Vzc29yeSIsICJ2YWx1ZSIgOiAiRXllIFBhdGNoIiB9LHsgInRyYWl0X3R5cGUiIDogIkVhcnJpbmdzIiwgInZhbHVlIiA6ICJDbGFzc2ljIiB9LHsgInRyYWl0X3R5cGUiIDogIk1hc2siLCAidmFsdWUiIDogIk1hc2tsZXNzIiB9LHsgInRyYWl0X3R5cGUiIDogIkJhY2tncm91bmQiLCAidmFsdWUiIDogIkltcHJlc3NpdmUiIH0seyAidHJhaXRfdHlwZSIgOiAiT3JpZ2luYWwiLCAidmFsdWUiIDogInRydWUiIH1dLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCMlpYSnphVzl1UFNJeExqRWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRDBpTUhCNElpQjVQU0l3Y0hnaUlIWnBaWGRDYjNnOUlqQWdNQ0EwTWpBZ05ESXdJaUJ6ZEhsc1pUMGlaVzVoWW14bExXSmhZMnRuY205MWJtUTZibVYzSURBZ01DQTBNakFnTkRJd095SWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0krUEdjZ2FXUTlJa0poWTJ0bmNtOTFibVFpUGp4eVlXUnBZV3hIY21Ga2FXVnVkQ0JwWkQwaVozSmhaR2xsYm5RaUlHTjRQU0l5TVRBaUlHTjVQU0l0TVRNMExqQTFJaUJ5UFNJeU1UQXVNREkxSWlCbmNtRmthV1Z1ZEZSeVlXNXpabTl5YlQwaWJXRjBjbWw0S0RFZ01DQXdJQzB4SURBZ056WXBJaUJuY21Ga2FXVnVkRlZ1YVhSelBTSjFjMlZ5VTNCaFkyVlBibFZ6WlNJK1BITjBlV3hsUGk1amIyeHZjaTFoYm1sdElIdGhibWx0WVhScGIyNDZJR052YkNBMmN5QnBibVpwYm1sMFpUdGhibWx0WVhScGIyNHRkR2x0YVc1bkxXWjFibU4wYVc5dU9pQmxZWE5sTFdsdUxXOTFkRHQ5UUd0bGVXWnlZVzFsY3lCamIyd2dlekFsTERVeEpTQjdjM1J2Y0MxamIyeHZjanB1YjI1bGZTQTFNaVVnZTNOMGIzQXRZMjlzYjNJNkkwWkdRa0ZHTjMwZ05UTWxMREV3TUNVZ2UzTjBiM0F0WTI5c2IzSTZibTl1WlgxOVBDOXpkSGxzWlQ0OGMzUnZjQ0J2Wm1aelpYUTlKekFuSUdOc1lYTnpQU2RqYjJ4dmNpMWhibWx0SnlCemRIbHNaVDBuYzNSdmNDMWpiMnh2Y2pvak16Z3dNVEV6Snk4K1BITjBiM0FnYjJabWMyVjBQU2N3TGpZMkp5QnpkSGxzWlQwbmMzUnZjQzFqYjJ4dmNqb2pSRGczUVVVMkp6NDhZVzVwYldGMFpTQmhkSFJ5YVdKMWRHVk9ZVzFsUFNkdlptWnpaWFFuSUdSMWNqMG5NVGh6SnlCMllXeDFaWE05SnpBdU5UUTdNQzQ0T3pBdU5UUW5JSEpsY0dWaGRFTnZkVzUwUFNkcGJtUmxabWx1YVhSbEp5QnJaWGxVYVcxbGN6MG5NRHN1TkRzeEp5OCtQQzl6ZEc5d1BqeHpkRzl3SUc5bVpuTmxkRDBuTVNjZ2MzUjViR1U5SjNOMGIzQXRZMjlzYjNJNkl6aEJNRGRDUVNjK1BHRnVhVzFoZEdVZ1lYUjBjbWxpZFhSbFRtRnRaVDBuYjJabWMyVjBKeUJrZFhJOUp6RTRjeWNnZG1Gc2RXVnpQU2N3TGpnMk96RTdNQzQ0TmljZ2NtVndaV0YwUTI5MWJuUTlKMmx1WkdWbWFXNXBkR1VuTHo0OEwzTjBiM0ErUEM5eVlXUnBZV3hIY21Ga2FXVnVkRDQ4Y0dGMGFDQm1hV3hzUFNKMWNtd29JMmR5WVdScFpXNTBLU0lnWkQwaVRUTTVNQ3cwTWpCSU16QmpMVEUyTGpZc01DMHpNQzB4TXk0MExUTXdMVE13VmpNd1F6QXNNVE11TkN3eE15NDBMREFzTXpBc01HZ3pOakJqTVRZdU5pd3dMRE13TERFekxqUXNNekFzTXpCMk16WXdRelF5TUN3ME1EWXVOaXcwTURZdU5pdzBNakFzTXprd0xEUXlNSG9pTHo0OGNHRjBhQ0JwWkQwaVFtOXlaR1Z5SWlCdmNHRmphWFI1UFNJd0xqUWlJR1pwYkd3OUltNXZibVVpSUhOMGNtOXJaVDBpSTBaR1JrWkdSaUlnYzNSeWIydGxMWGRwWkhSb1BTSXlJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlHUTlJazB6T0RNdU5DdzBNVEJJTXpZdU5rTXlNUzQ1TERReE1Dd3hNQ3d6T1RndU1Td3hNQ3d6T0RNdU5GWXpOaTQyUXpFd0xESXhMamtzTWpFdU9Td3hNQ3d6Tmk0MkxERXdhRE0wTmk0NFl6RTBMamNzTUN3eU5pNDJMREV4TGprc01qWXVOaXd5Tmk0MmRqTTBOaTQ0SUVNME1UQXNNems0TGpFc016azRMakVzTkRFd0xETTRNeTQwTERReE1Ib2lMejQ4Y0dGMGFDQnBaRDBpVFdGemF5SWdiM0JoWTJsMGVUMGlNQzR4SWlCbWFXeHNQU0lqTkRnd01EVkZJaUJrUFNKTk16Z3hMalFzTkRFd1NETTRMalpETWpJdU9DdzBNVEFzTVRBc016azNMaklzTVRBc016Z3hMalJXTXpndU5pQkRNVEFzTWpJdU9Dd3lNaTQ0TERFd0xETTRMallzTVRCb016UXlMamxqTVRVdU9Dd3dMREk0TGpZc01USXVPQ3d5T0M0MkxESTRMaloyTXpReUxqbEROREV3TERNNU55NHlMRE01Tnk0eUxEUXhNQ3d6T0RFdU5DdzBNVEI2SWk4K1BDOW5QanhuSUdsa1BTSkNiMlI1SWo0OGNHRjBhQ0JtYVd4c0xYSjFiR1U5SjJWMlpXNXZaR1FuSUdOc2FYQXRjblZzWlQwblpYWmxibTlrWkNjZ1ptbHNiRDBuSTBaR1JVSkNOQ2NnYzNSeWIydGxQU2NqTURBd01EQXdKeUJ6ZEhKdmEyVXRiR2x1WldOaGNEMG5jbTkxYm1RbklITjBjbTlyWlMxdGFYUmxjbXhwYldsMFBTY3hNQ2NnWkQwblRURTNOeTR4TERJNE55NHhZekF1T0N3NUxqWXNNQzR6TERFNUxqTXRNUzQxTERJNUxqSmpMVEF1TlN3eUxqVXRNaTR4TERRdU55MDBMalVzTm1NdE1UVXVOeXc0TGpVdE5ERXVNU3d4Tmk0MExUWTRMamdzTWpRdU1tTXROeTQ0TERJdU1pMDVMakVzTVRFdU9TMHlMREUxTGpkak5qa3NNemNzTVRRd0xqUXNOREF1T1N3eU1UVXVOQ3cyTGpkak5pNDVMVE11TWl3M0xURXlMaklzTUM0eExURTFMalJqTFRJeExqUXRPUzQ1TFRReUxqRXRNVGt1TnkwMU15NHhMVEkyTGpKakxUSXVOUzB4TGpVdE5DMHpMamt0TkM0ekxUWXVOV010TUM0M0xUY3VOQzB3TGprdE1UWXVNUzB3TGpNdE1qVXVOV013TGpjdE1UQXVPQ3d5TGpVdE1qQXVNeXcwTGpRdE1qZ3VNaWN2UGp4d1lYUm9JR1pwYkd3dGNuVnNaVDBuWlhabGJtOWtaQ2NnWTJ4cGNDMXlkV3hsUFNkbGRtVnViMlJrSnlCbWFXeHNQU2NqUmtaQ1JUazBKeUJrUFNkTk1UYzNMakVzTWpnNVl6QXNNQ3d5TXk0eUxETXpMamNzTXprdU15d3lPUzQxY3pRd0xqa3RNakF1TlN3ME1DNDVMVEl3TGpWak1TNHlMVGd1Tnl3eUxqUXRNVGN1TlN3ekxqVXRNall1TW1NdE5DNDJMRFF1TnkweE1DNDVMREV3TGpJdE1Ua3NNVFV1TTJNdE1UQXVPQ3cyTGpndE1qRXNNVEF1TkMweU9DNDFMREV5TGpSTU1UYzNMakVzTWpnNWVpY3ZQanh3WVhSb0lHWnBiR3d0Y25Wc1pUMG5aWFpsYm05a1pDY2dZMnhwY0MxeWRXeGxQU2RsZG1WdWIyUmtKeUJtYVd4c1BTY2pSa1pGUWtJMEp5QnpkSEp2YTJVOUp5TXdNREF3TURBbklITjBjbTlyWlMxc2FXNWxZMkZ3UFNkeWIzVnVaQ2NnYzNSeWIydGxMVzFwZEdWeWJHbHRhWFE5SnpFd0p5QmtQU2ROTXpBeExqTXNNVGt6TGpaak1pNDFMVFF1Tml3eE1DNDNMVFk0TGpFdE1Ua3VPQzA1T1M0eFl5MHlPUzQxTFRJNUxqa3RPVFl0TXpRdE1USTRMakV0TUM0emN5MHlNeTQzTERFd05TNDJMVEl6TGpjc01UQTFMalp6TVRJdU5DdzFPUzQ0TERJMExqSXNOekpqTUN3d0xETXlMak1zTWpRdU9DdzBNQzQzTERJNUxqVmpPQzQwTERRdU9Dd3hOaTQwTERJdU1pd3hOaTQwTERJdU1tTXhOUzQwTFRVdU55d3lOUzR4TFRFd0xqa3NNek11TXkweE55NDBKeTgrUEhCaGRHZ2dabWxzYkMxeWRXeGxQU2RsZG1WdWIyUmtKeUJqYkdsd0xYSjFiR1U5SjJWMlpXNXZaR1FuSUdacGJHdzlKeU5HUmtWQ1FqUW5JSE4wY205clpUMG5JekF3TURBd01DY2djM1J5YjJ0bExXeHBibVZqWVhBOUozSnZkVzVrSnlCemRISnZhMlV0YldsMFpYSnNhVzFwZEQwbk1UQW5JR1E5SjAweE5ERXVPQ3d5TkRjdU1tTXdMakVzTVM0eExURXhMallzTnk0MExURXlMamt0Tnk0eFl5MHhMak10TVRRdU5TMHpMamt0TVRndU1pMDVMak10TXpRdU5YTTVMakV0T0M0MExEa3VNUzA0TGpRbkx6NDhjR0YwYUNCbWFXeHNMWEoxYkdVOUoyVjJaVzV2WkdRbklHTnNhWEF0Y25Wc1pUMG5aWFpsYm05a1pDY2dabWxzYkQwbkkwWkdSVUpDTkNjZ2MzUnliMnRsUFNjak1EQXdNREF3SnlCemRISnZhMlV0YkdsdVpXTmhjRDBuY205MWJtUW5JSE4wY205clpTMXRhWFJsY214cGJXbDBQU2N4TUNjZ1pEMG5UVEkxTkM0NExESTNPQzR4WXpjdE9DNDJMREV6TGprdE1UY3VNaXd5TUM0NUxUSTFMamhqTVM0eUxURXVOQ3d5TGprdE1pNHhMRFF1TmkweExqZGpNeTQ1TERBdU9Dd3hNUzR5TERFdU1pd3hNaTQ0TFRZdU4yTXlMak10TVRFc05pNDFMVEl6TGpVc01USXVNeTB6TXk0Mll6TXVNaTAxTGpjc01DNDNMVEV4TGpRdE1pNHlMVEUxTGpOakxUSXVNUzB5TGpndE5pNHhMVEl1TnkwM0xqa3NNQzR5WXkweUxqWXNOQzAxTERjdU9TMDNMallzTVRFdU9TY3ZQanh3YjJ4NVoyOXVJR1pwYkd3dGNuVnNaVDBuWlhabGJtOWtaQ2NnWTJ4cGNDMXlkV3hsUFNkbGRtVnViMlJrSnlCbWFXeHNQU2NqUmtaRlFrSTBKeUJ3YjJsdWRITTlKekkzTWl3eU16Y3VOQ0F5TlRFdU5Dd3lOekF1TkNBeU5qQXVPU3d5TmpndU5pQXlOell1T1N3eU16SXVOQ2N2UGp4d1lYUm9JR1E5SjAweE9UTXVNeXd4T1RZdU5HTXdMamdzTlM0eExERXNNVEF1TWl3eExERTFMalJqTUN3eUxqWXRNQzR4TERVdU1pMHdMalFzTnk0M1l5MHdMak1zTWk0MkxUQXVOeXcxTGpFdE1TNHpMRGN1Tm1ndE1DNHhZekF1TVMweUxqWXNNQzR6TFRVdU1Td3dMalF0Tnk0M1l6QXVNaTB5TGpVc01DNDBMVFV1TVN3d0xqWXROeTQyWXpBdU1TMHlMallzTUM0eUxUVXVNU3d3TGpFdE55NDNRekU1TXk0MUxESXdNUzQxTERFNU15NDBMREU1T0M0NUxERTVNeTR6TERFNU5pNDBUREU1TXk0ekxERTVOaTQwZWljdlBqeHdZWFJvSUdacGJHdzlKeU5HUmtKRk9UUW5JR1E5SjAweE9UY3VPQ3d5TkRJdU9Hd3ROeTQ1TFRNdU5XTXRNQzQwTFRBdU1pMHdMalV0TUM0M0xUQXVNaTB4TGpGc015NHlMVE11TTJNd0xqUXRNQzQwTERFdE1DNDFMREV1TlMwd0xqTnNNVEl1Tnl3MExqWmpNQzQyTERBdU1pd3dMallzTVM0eExUQXVNU3d4TGpOc0xUZ3VOeXd5TGpSRE1UazRMakVzTWpReUxqa3NNVGszTGprc01qUXlMamtzTVRrM0xqZ3NNalF5TGpoNkp5OCtQQzluUGp4bklHbGtQU0pOWVhKcklqNDhjR0YwYUNCbWFXeHNQU0lqTjBZd01EWTRJaUJrUFNKTk1UazNMaklzTVRReUxqRmpMVFV1T0N3d0xURXdMamtzTWk0NUxURXpMamtzTnk0ell6SXVNeTB5TGpNc05TNDBMVE11Tnl3NExqa3RNeTQzWXpjdU1Td3dMREV5TGprc05TNDVMREV5TGprc01UTXVNeUJ6TFRVdU9Dd3hNeTR6TFRFeUxqa3NNVE11TTJNdE15NDBMREF0Tmk0MkxURXVOQzA0TGprdE15NDNZek11TVN3MExqUXNPQzR5TERjdU15d3hNeTQ1TERjdU0yTTVMak1zTUN3eE5pNDVMVGN1Tml3eE5pNDVMVEUyTGpsVE1qQTJMallzTVRReUxqRXNNVGszTGpJc01UUXlMakY2SWk4K1BDOW5QanhuSUdsa1BTSk5iM1YwYUNJK1BIQmhkR2dnWm1sc2JEMGlJMFpHUmtaR1JpSWdjM1J5YjJ0bFBTSWpNREF3TURBd0lpQnpkSEp2YTJVdGJXbDBaWEpzYVcxcGREMGlNVEFpSUdROUlrMHhOelF1Tnl3eU5qRXVOMk13TERBc01UWXVNUzB4TGpFc01UY3VOUzB4TGpWek16UXVOU3cyTGpNc016WXVOU3cxTGpWek5DNDJMVEV1T1N3MExqWXRNUzQ1Y3kweE5DNHhMRGd0TkRNdU5pdzNMamxqTUN3d0xUTXVPUzB3TGpjdE5DNDNMVEV1T0ZNeE56Y3VNU3d5TmpJdU1Td3hOelF1Tnl3eU5qRXVOM29pTHo0OGNHOXNlV3hwYm1VZ1ptbHNiRDBpYm05dVpTSWdjM1J5YjJ0bFBTSWpNREF3TURBd0lpQnpkSEp2YTJVdGJXbDBaWEpzYVcxcGREMGlNVEFpSUhCdmFXNTBjejBpTVRneExqWXNNalkyTGpjZ01UZzFMalVzTWpZMUxqTWdNVGc1TGpFc01qWTJMalVnTVRrd0xqTXNNalkxTGpraUx6NDhjRzlzZVd4cGJtVWdabWxzYkQwaWJtOXVaU0lnYzNSeWIydGxQU0lqTURBd01EQXdJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlIQnZhVzUwY3owaU1UazRMaklzTWpZM0lESXdOaTR6TERJMk5pNHlJREl3T1M0MkxESTJOeTQzSURJeE15NDVMREkyTmk0eklESXhOaTQ1TERJMk55NDFJREl5TlM0ekxESTJOeUl2UGp3dlp6NDhaeUJwWkQwaVJYbGxjeUkrUEhCaGRHZ2dabWxzYkQwbkkwWTNSamRHTnljZ1pEMG5UVEUzTlM0M0xERTVPUzQwWXpJdU5DdzNMakV0TUM0MkxERXpMak10TkM0eExERXpMamtnWXkwMUxEQXVPQzB4TlM0NExERXRNVGd1T0N3d1l5MDFMVEV1TnkwMkxqRXRNVEl1TkMwMkxqRXRNVEl1TkVNeE5UWXVOaXd4T1RFdU5Dd3hOalVzTVRnNUxqVXNNVGMxTGpjc01UazVMalI2Snk4K1BIQmhkR2dnWkQwaVRURTBOeTQxTERFNU9DNDNZeTB3TGpnc01TMHhMalVzTWk0eExUSXNNeTR6WXpjdU5TMDRMalVzTWpRdU55MHhNQzR6TERNeExqY3RNQzQ1WXkwMUxqZ3RNVEF1TXkweE55NDFMVEV6TFRJMkxqUXROUzQ0SWk4K1BIQmhkR2dnWkQwaVRURTBPUzQwTERFNU5pNDJZeTB3TGpJc01DNHlMVEF1TkN3d0xqUXRNQzQyTERBdU5pSXZQanh3WVhSb0lHUTlJazB4TmpZdU1pd3hPRGN1TVdNdE5DNHpMVEF1T0MwNExqZ3NNQzR4TFRFekxERXVORU14TlRjc01UZzJMalFzTVRZeUxERTROUzQ0TERFMk5pNHlMREU0Tnk0eGVpSXZQanh3WVhSb0lHUTlJazB4TmprdU9Dd3hPRGd1TldNeUxqSXNNQzQ0TERRdU1Td3lMaklzTlM0MkxETXVPRU14TnpNdU5Td3hPVEV1TVN3eE56RXVOaXd4T0RrdU55d3hOamt1T0N3eE9EZ3VOWG9pTHo0OGNHRjBhQ0JrUFNKTk1UYzBMalFzTWpFeExqaGpMVEF1TWl3d0xqVXRNQzQ0TERBdU9DMHhMaklzTVdNdE1DNDFMREF1TWkweExEQXVOQzB4TGpVc01DNDJZeTB4TERBdU15MHlMakVzTUM0MUxUTXVNU3d3TGpkakxUSXVNU3d3TGpRdE5DNHlMREF1TlMwMkxqTXNNQzQzSUdNdE1pNHhMREF1TVMwMExqTXNNQzR4TFRZdU5DMHdMak5qTFRFdU1TMHdMakl0TWk0eExUQXVOUzB6TGpFdE1DNDVZeTB3TGprdE1DNDFMVEl0TVM0eExUSXVOQzB5TGpGak1DNDJMREF1T1N3eExqWXNNUzQwTERJdU5Td3hMamRqTVN3d0xqTXNNaXd3TGpZc015d3dMamNnWXpJdU1Td3dMak1zTkM0eUxEQXVNeXcyTGpJc01DNHlZekl1TVMwd0xqRXNOQzR5TFRBdU1pdzJMak10TUM0MVl6RXRNQzR4TERJdU1TMHdMak1zTXk0eExUQXVOV013TGpVdE1DNHhMREV0TUM0eUxERXVOUzB3TGpSak1DNHlMVEF1TVN3d0xqVXRNQzR5TERBdU55MHdMak1nUXpFM05DNHhMREl4TWk0eUxERTNOQzR6TERJeE1pNHhMREUzTkM0MExESXhNUzQ0ZWlJdlBqeHdZWFJvSUdacGJHdzlKeU5HTjBZM1JqY25JR1E5SjAweU1qQXVPU3d5TURNdU5tTXdMalVzTXk0eExERXVOeXc1TGpZc055NHhMREV3TGpFZ1l6Y3NNUzR4TERJeExEUXVNeXd5TXk0eUxUa3VNMk14TGpNdE55NHhMVGt1T0MweE1TNDBMVEUxTGpRdE1URXVNa015TXpBdU55d3hPVFF1Tnl3eU1qQXVOU3d4T1RRdU55d3lNakF1T1N3eU1ETXVObm9uTHo0OGNHRjBhQ0JrUFNKTk1qVXdMalFzTVRrNExqWmpMVEF1TWkwd0xqSXRNQzQwTFRBdU5TMHdMall0TUM0M0lpOCtQSEJoZEdnZ1pEMGlUVEkwT0M0MkxERTVOaTQyWXkwM0xqWXROeTQ1TFRJekxqUXROaTR5TFRJNUxqTXNNeTQzWXpFd0xUZ3VNaXd5Tmk0eUxUWXVOeXd6TkM0MExETXVOR013TFRBdU15MHdMamN0TVM0NExUSXRNeTQzSWk4K1BIQmhkR2dnWkQwaVRUSXlPUzQyTERFNE55NDJZelF1TWkweExqTXNPUzR4TFRFc01UTXNNUzR5UXpJek9DNDBMREU0Tnk0MExESXpOQ3d4T0RZdU5pd3lNamt1Tml3eE9EY3VOa3d5TWprdU5pd3hPRGN1Tm5vaUx6NDhjR0YwYUNCa1BTSk5NakkyTGpFc01UZzVZeTB4TGpnc01TNHpMVE11Tnl3eUxqY3ROUzQyTERNdU9VTXlNakV1T1N3eE9URXVNU3d5TWpRc01UZzVMallzTWpJMkxqRXNNVGc1ZWlJdlBqeHdZWFJvSUdROUlrMHlNalF1TlN3eU1USXVOR00xTGpJc01pNDFMREU1TGpjc015NDFMREkwTFRBdU9VTXlORFF1TWl3eU1UWXVPQ3d5TWprdU5pd3lNVFV1T0N3eU1qUXVOU3d5TVRJdU5Ib2lMejQ4Y0dGMGFDQmtQU0pOTWpNekxqWXNNakExTGpKak1DNHlMVEF1T0N3d0xqWXRNUzQzTERFdU15MHlMak5qTUM0MExUQXVNeXd3TGprdE1DNDFMREV1TXkwd0xqUmpNQzQxTERBdU1Td3dMamtzTUM0MExERXVNaXd3TGpoak1DNDFMREF1T0N3d0xqWXNNUzQ0TERBdU5pd3lMamRqTUN3d0xqa3RNQzQwTERFdU9TMHhMakVzTWk0Mll5MHdMamNzTUM0M0xURXVOeXd4TGpFdE1pNDNMREZqTFRFdE1DNHhMVEV1T0Mwd0xqY3RNaTQxTFRFdU1tTXRNQzQzTFRBdU5TMHhMalF0TVM0eUxURXVPUzB5WXkwd0xqVXRNQzQ0TFRBdU9DMHhMamd0TUM0M0xUSXVPR013TGpFdE1Td3dMalV0TVM0NUxERXVNUzB5TGpaak1DNDJMVEF1Tnl3eExqUXRNUzR6TERJdU1pMHhMamRqTVM0M0xUQXVPQ3d6TGpZdE1TdzFMak10TUM0Mll6QXVPU3d3TGpJc01TNDRMREF1TlN3eUxqVXNNUzR4WXpBdU55d3dMallzTVM0eUxERXVOU3d4TGpNc01pNDBZekF1TXl3eExqZ3RNQzR6TERNdU55MHhMalFzTkM0NVl6RXRNUzQwTERFdU5DMHpMaklzTVMwMExqaGpMVEF1TWkwd0xqZ3RNQzQyTFRFdU5TMHhMak10TW1NdE1DNDJMVEF1TlMweExqUXRNQzQ0TFRJdU1pMHdMamxqTFRFdU5pMHdMakl0TXk0MExEQXROQzQ0TERBdU4yTXRNUzQwTERBdU55MHlMamNzTWkweUxqZ3NNeTQxWXkwd0xqSXNNUzQxTERBdU9Td3pMREl1TWl3MFl6QXVOeXd3TGpVc01TNHpMREVzTWk0eExERXVNV013TGpjc01DNHhMREV1TlMwd0xqSXNNaTR4TFRBdU4yTXdMall0TUM0MUxEQXVPUzB4TGpNc01TMHlMakZqTUM0eExUQXVPQ3d3TFRFdU55MHdMalF0TWk0ell5MHdMakl0TUM0ekxUQXVOUzB3TGpZdE1DNDRMVEF1TjJNdE1DNDBMVEF1TVMwd0xqZ3NNQzB4TGpFc01DNHlRekl6TkM0MExESXdNeTQyTERJek15NDVMREl3TkM0MExESXpNeTQyTERJd05TNHllaUl2UGp4d1lYUm9JR1E5SWsweE5qQXVNaXd5TURRdU9HTXdMamN0TUM0MExERXVOaTB3TGpnc01pNDFMVEF1TjJNd0xqUXNNQ3d3TGprc01DNHpMREV1TWl3d0xqZGpNQzR6TERBdU5Dd3dMak1zTUM0NUxEQXVNaXd4TGpSakxUQXVNaXd3TGprdE1DNDRMREV1TnkweExqVXNNaTR6WXkwd0xqY3NNQzQyTFRFdU5pd3hMakV0TWk0MkxERmpMVEVzTUMweUxUQXVOQzB5TGpZdE1TNHlZeTB3TGpjdE1DNDRMVEF1T0MweExqZ3RNUzB5TGpaakxUQXVNUzB3TGprdE1DNHhMVEV1T0N3d0xqRXRNaTQ0WXpBdU1pMHdMamtzTUM0M0xURXVPQ3d4TGpVdE1pNDBZekF1T0Mwd0xqWXNNUzQzTFRFc01pNDNMVEZqTUM0NUxUQXVNU3d4TGprc01DNHhMREl1Tnl3d0xqUmpNUzQzTERBdU5pd3pMaklzTVM0NExEUXVNaXd6TGpOak1DNDFMREF1Tnl3d0xqa3NNUzQyTERFc01pNDJZekF1TVN3d0xqa3RNQzR5TERFdU9TMHdMamdzTWk0Mll5MHhMakVzTVM0MUxUSXVPQ3d5TGpRdE5DNDFMREl1TldNeExqY3RNQzR6TERNdU15MHhMak1zTkM0eExUSXVOMk13TGpRdE1DNDNMREF1TmkweExqVXNNQzQxTFRJdU0yTXRNQzR4TFRBdU9DMHdMalV0TVM0MUxURXRNaTR5WXkweExURXVNeTB5TGpRdE1pNDBMVE11T1MweUxqbGpMVEV1TlMwd0xqVXRNeTR6TFRBdU5TMDBMalVzTUM0MVl5MHhMaklzTVMweExqVXNNaTQzTFRFdU15dzBMak5qTUM0eExEQXVPQ3d3TGpJc01TNDJMREF1Tnl3eUxqSmpNQzQwTERBdU5pd3hMaklzTUM0NUxERXVPU3d4WXpBdU9Dd3dMREV1TlMwd0xqSXNNaTR5TFRBdU9HTXdMall0TUM0MUxERXVNaTB4TGpJc01TNDBMVEV1T1dNd0xqRXRNQzQwTERBdU1TMHdMamd0TUM0eExURXVNV010TUM0eUxUQXVNeTB3TGpVdE1DNDJMVEF1T1Mwd0xqWkRNVFl4TGprc01qQTBMaklzTVRZeExESXdOQzQwTERFMk1DNHlMREl3TkM0NGVpSXZQand2Wno0OFp5QnBaRDBpUlhsbFluSnZkeUkrUEhCaGRHZ2dabWxzYkMxeWRXeGxQU0psZG1WdWIyUmtJaUJqYkdsd0xYSjFiR1U5SW1WMlpXNXZaR1FpSUdROUlrMHlNell1TXl3eE56ZGpMVEV4TGpNdE5TNHhMVEU0TFRNdU1TMHlNQzR6TFRJdU1XTXRNQzR4TERBdE1DNHlMREF1TVMwd0xqTXNNQzR5WXkwd0xqTXNNQzR4TFRBdU5Td3dMak10TUM0MkxEQXVNMnd3TERCc01Dd3diREFzTUdNdE1Td3dMamN0TVM0M0xERXVOeTB4TGprc00yTXRNQzQxTERJdU5pd3hMaklzTlN3ekxqZ3NOUzQxY3pVdE1TNHlMRFV1TlMwekxqaGpNQzR4TFRBdU15d3dMakV0TUM0MkxEQXVNUzB4UXpJeU55NDBMREUzTlM0MkxESXpOaTR6TERFM055d3lNell1TXl3eE56ZDZJaTgrUEhCaGRHZ2dabWxzYkMxeWRXeGxQU0psZG1WdWIyUmtJaUJqYkdsd0xYSjFiR1U5SW1WMlpXNXZaR1FpSUdROUlrMHhOakF1TWl3eE56WXVNMk14TUM0NExUUXVOaXd4Tnk0eExUSXVOU3d4T1M0eUxURXVNMk13TGpFc01Dd3dMaklzTUM0eExEQXVNeXd3TGpKak1DNHpMREF1TVN3d0xqUXNNQzR6TERBdU5Td3dMak5zTUN3d2JEQXNNR3d3TERCak1DNDVMREF1Tnl3eExqWXNNUzQ0TERFdU9Dd3pMakZqTUM0MExESXVOaTB4TGpJc05TMHpMamNzTlM0MGN5MDBMamN0TVM0MExUVXVNUzAwWXkwd0xqRXRNQzR6TFRBdU1TMHdMall0TUM0eExURkRNVFk0TGpZc01UYzFMaklzTVRZd0xqSXNNVGMyTGpNc01UWXdMaklzTVRjMkxqTjZJaTgrUEM5blBqeG5JR2xrUFNKSVlXbHlJajQ4Y0dGMGFDQm1hV3hzUFNjak16TXpNek5FSnlCa1BTZE5NamczTGpNc01qQTNMakZqTUN3d0xUQXVOQzB4Tnk0M0xUTXVOQzB5TUM0Mll5MHpMakV0TWk0NUxUY3VNeTA0TGpjdE55NHpMVGd1TjNNd0xqWXRNalF1T0MweUxqa3RNekV1T0dNdE15NDJMVGN0TXk0NUxUSTBMak10TXpVdE1qTXVObU10TXpBdU15d3dMamN0TkRJdU5TdzFMalF0TkRJdU5TdzFMalJ6TFRFMExqSXRPQzR5TFRRekxUTXVPR010TVRrdU15dzBMamt0TVRjdU1pdzFNQzR4TFRFM0xqSXNOVEF1TVhNdE5TNDJMRGt1TlMwMkxqSXNNVFF1T0dNdE1DNDJMRFV1TXkwd0xqTXNPQzR6TFRBdU15dzRMak5qTUM0NUxUQXVNaTB4T1M0eExURXlOaTR6TERnMkxqY3RNVEkyTGpoak1UQTRMalF0TUM0ekxEZzNMakVzTVRJeExqY3NPRFV1TVN3eE1qSXVORU15T1RRdU5Td3hPVEV1Tml3eU9UTXVOeXd4T1Rnc01qZzNMak1zTWpBM0xqRjZKeTgrUEhCaGRHZ2dabWxzYkMxeWRXeGxQU0psZG1WdWIyUmtJaUJqYkdsd0xYSjFiR1U5SW1WMlpXNXZaR1FpSUdacGJHdzlJaU15TVRJeE1qRWlJSE4wY205clpUMGlJekF3TURBd01DSWdjM1J5YjJ0bExXMXBkR1Z5YkdsdGFYUTlJakV3SWlCa1BTSk5NVGsyTERFeU5DNDJZekFzTUMwek1DNHpMVE0zTGpVdE1qQXVOaTAzTnk0M1l6QXNNQ3d3TGpjc01UZ3NNVElzTWpVdU1XTXdMREF0T0M0MkxURXpMalF0TUM0ekxUTXpMalJqTUN3d0xESXVOeXd4TlM0NExERXdMamNzTWpNdU5HTXdMREF0TWk0M0xURTRMalFzTWk0eUxUSTVMalpqTUN3d0xEa3VOeXd5TXk0eUxERXpMamtzTWpZdU0yTXdMREF0Tmk0MUxURTNMaklzTlM0MExUSTNMamRqTUN3d0xUQXVPQ3d4T0M0MkxEa3VPQ3d5TlM0MFl6QXNNQzB5TGpjdE1URXNOQzB4T0M0NVl6QXNNQ3d4TGpJc01qVXVNU3cyTGpZc01qa3VOR013TERBdE1pNDNMVEV5TERJdU1TMHlNR013TERBc05pd3lOQ3c0TGpZc01qZ3VOV010T1M0eExUSXVOaTB4Tnk0NUxUTXVNaTB5Tmk0MkxUTkRNakl6TGpjc056SXVNeXd4T1Rnc09EQXVPQ3d4T1RZc01USTBMalo2SWk4K1BHY2dhV1E5SWt4cFoyaDBJaUJ2Y0dGamFYUjVQU0l3TGpFMElqNDhaV3hzYVhCelpTQjBjbUZ1YzJadmNtMDlJbTFoZEhKcGVDZ3dMamN3TnpFZ0xUQXVOekEzTVNBd0xqY3dOekVnTUM0M01EY3hJREF1TVRZd015QXlNall1TlRrMk5Ta2lJR1pwYkd3OUlpTkdSa1pHUmtZaUlHTjRQU0l5TnpNdU5pSWdZM2s5SWpFeE15NHhJaUJ5ZUQwaU1TNDBJaUJ5ZVQwaU5TNHpJaTgrUEdWc2JHbHdjMlVnZEhKaGJuTm1iM0p0UFNKdFlYUnlhWGdvTUM0MU5UTTFJQzB3TGpnek1qZ2dNQzQ0TXpJNElEQXVOVFV6TlNBek1pNHdPVFk1SURJMU5DNDBPRFkxS1NJZ1ptbHNiRDBpSTBaR1JrWkdSaUlnWTNnOUlqSTFNeTQwSWlCamVUMGlPVGN1TXlJZ2NuZzlJalF1TWlJZ2NuazlJakUyTGpNaUx6NDhMMmMrUEhCaGRHZ2diM0JoWTJsMGVUMGlNQzR3TlNJZ1ptbHNiQzF5ZFd4bFBTSmxkbVZ1YjJSa0lpQmpiR2x3TFhKMWJHVTlJbVYyWlc1dlpHUWlJR1E5SWsweU56WXVOQ3d4TmpNdU4yTXdMREFzTUM0eUxURXVPU3d3TGpJc01UUXVNV013TERBc05pNDFMRGN1TlN3NExqVXNNVEZ6TWk0MkxERTNMamdzTWk0MkxERTNMamhzTnkweE1TNHlZekFzTUN3eExqZ3RNeTR5TERZdU5pMHlMalpqTUN3d0xEVXVOaTB4TXk0eExESXVNaTAwTWk0eVF6TXdNeTQxTERFMU1DNDJMREk1TkM0eUxERTJNaTR4TERJM05pNDBMREUyTXk0M2VpSXZQanh3WVhSb0lHOXdZV05wZEhrOUlqQXVNU0lnWm1sc2JDMXlkV3hsUFNKbGRtVnViMlJrSWlCamJHbHdMWEoxYkdVOUltVjJaVzV2WkdRaUlHUTlJazB4TWprdU1pd3hPVFF1TkdNd0xEQXRNQzQzTFRndU9TdzJMamd0TWpBdU0yTXdMREF0TUM0eUxUSXhMaklzTVM0ekxUSXlMamxqTFRNdU55d3dMVFl1Tnkwd0xqVXROeTQzTFRJdU5FTXhNamt1Tml3eE5EZ3VPQ3d4TWpVdU9Dd3hPREV1TlN3eE1qa3VNaXd4T1RRdU5Ib2lMejQ4TDJjK1BHY2dhV1E5SWtGalkyVnpjMjl5ZVNJK1BIQmhkR2dnWm1sc2JEMGlJMFpEUmtWR1JpSWdjM1J5YjJ0bFBTSWpORUUyTXpZeUlpQnpkSEp2YTJVdGJXbDBaWEpzYVcxcGREMGlNVEFpSUdROUlrMHlOVE11Tml3eU1qSXVOMGd5TVRsakxUUXVOeXd3TFRndU5TMHpMamd0T0M0MUxUZ3VOWFl0TWpBdU9DQmpNQzAwTGpjc015NDRMVGd1TlN3NExqVXRPQzQxYURNMExqWmpOQzQzTERBc09DNDFMRE11T0N3NExqVXNPQzQxZGpJd0xqaERNall5TGpFc01qRTRMamtzTWpVNExqTXNNakl5TGpjc01qVXpMallzTWpJeUxqZDZJaTgrUEhCaGRHZ2dabWxzYkQwaWJtOXVaU0lnYzNSeWIydGxQU0lqTkVFMk16WXlJaUJ6ZEhKdmEyVXRkMmxrZEdnOUlqQXVOelVpSUhOMGNtOXJaUzF0YVhSbGNteHBiV2wwUFNJeE1DSWdaRDBpVFRJMU1DNHhMREl4T0M0NWFDMHlOeTQyWXkwekxqZ3NNQzAyTGpndE15NHhMVFl1T0MwMkxqZ2dkaTB4Tmk0ell6QXRNeTQ0TERNdU1TMDJMamdzTmk0NExUWXVPR2d5Tnk0Mll6TXVPQ3d3TERZdU9Dd3pMakVzTmk0NExEWXVPRll5TVRKRE1qVTNMREl4TlM0NExESTFNeTQ1TERJeE9DNDVMREkxTUM0eExESXhPQzQ1ZWlJdlBqeHNhVzVsSUdacGJHdzlJbTV2Ym1VaUlITjBjbTlyWlQwaUl6TkRORVkwUlNJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlIZ3hQU0l5TVRFdU9TSWdlVEU5SWpFNE9DNDBJaUI0TWowaU1UTXhMamdpSUhreVBTSXhPRE11TVNJdlBqeHNhVzVsSUdacGJHdzlJbTV2Ym1VaUlITjBjbTlyWlQwaUl6TkRORVkwUlNJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlIZ3hQU0l5TlRrdU9TSWdlVEU5SWpFNE9DNHhJaUI0TWowaU1qa3pMalFpSUhreVBTSXhPVFl1TnlJdlBqeHNhVzVsSUdacGJHdzlJbTV2Ym1VaUlITjBjbTlyWlQwaUl6TkRORVkwUlNJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlIZ3hQU0l5TlRrdU1pSWdlVEU5SWpJeU1DNDJJaUI0TWowaU1qYzNMalVpSUhreVBTSXlOVEV1TmlJdlBqeHNhVzVsSUdacGJHdzlJbTV2Ym1VaUlITjBjbTlyWlQwaUl6TkRORVkwUlNJZ2MzUnliMnRsTFd4cGJtVmpZWEE5SW5KdmRXNWtJaUJ6ZEhKdmEyVXRiV2wwWlhKc2FXMXBkRDBpTVRBaUlIZ3hQU0l5TVRFdU5DSWdlVEU5SWpJeE9TNHhJaUI0TWowaU1UUXdMalVpSUhreVBTSXlORElpTHo0OFp5Qm1hV3hzTFhKMWJHVTlJbVYyWlc1dlpHUWlJR05zYVhBdGNuVnNaVDBpWlhabGJtOWtaQ0lnWm1sc2JEMGlJell6TmpNMk15SWdjM1J5YjJ0bFBTSWpORUUyTXpZeUlpQnpkSEp2YTJVdGQybGtkR2c5SWpBdU1qVWlJSE4wY205clpTMXRhWFJsY214cGJXbDBQU0l4TUNJK1BHVnNiR2x3YzJVZ1kzZzlJakkxTUM0NUlpQmplVDBpTWpFMUlpQnllRDBpTUM0NElpQnllVDBpTVM0eElpOCtQR1ZzYkdsd2MyVWdZM2c5SWpJek5pNDVJaUJqZVQwaU1qRTFJaUJ5ZUQwaU1DNDRJaUJ5ZVQwaU1TNHhJaTgrUEdWc2JHbHdjMlVnWTNnOUlqSTFNQzQ1SWlCamVUMGlNakF6TGpraUlISjRQU0l3TGpnaUlISjVQU0l4TGpFaUx6NDhaV3hzYVhCelpTQmplRDBpTWpVd0xqa2lJR041UFNJeE9UTXVPQ0lnY25nOUlqQXVPQ0lnY25rOUlqRXVNU0l2UGp4bGJHeHBjSE5sSUdONFBTSXlNell1T1NJZ1kzazlJakU1TXk0NElpQnllRDBpTUM0NElpQnllVDBpTVM0eElpOCtQR1ZzYkdsd2MyVWdZM2c5SWpJeU1TNHpJaUJqZVQwaU1qRTFJaUJ5ZUQwaU1DNDRJaUJ5ZVQwaU1TNHhJaTgrUEdWc2JHbHdjMlVnWTNnOUlqSXlNUzR6SWlCamVUMGlNakF6TGpraUlISjRQU0l3TGpnaUlISjVQU0l4TGpFaUx6NDhaV3hzYVhCelpTQmplRDBpTWpJeExqTWlJR041UFNJeE9UTXVPQ0lnY25nOUlqQXVPQ0lnY25rOUlqRXVNU0l2UGp3dlp6NDhMMmMrUEM5emRtYysifQ==";

    constructor() ERC721("Generative Ticket NFT", "mirrored getNFT") {
        minter = msg.sender;
    }

    modifier onlyMinter(){ 
        require(msg.sender == minter, "Only Minter");
        _; 
    }

    function mintMirrorTicket(address to, uint256 nftIndex) override external {
        _mint(to, nftIndex);
    }
    

    function tokenURI(uint256 nftIndex) public override view returns (string memory) {
        return tokenURICheating;
    }
}