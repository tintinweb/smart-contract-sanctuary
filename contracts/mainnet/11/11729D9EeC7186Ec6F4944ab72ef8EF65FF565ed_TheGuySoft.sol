/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

/*
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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


// File: contracts/TheGuySoft.sol

pragma solidity ^0.8.0;








contract TheGuySoft is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIdCounter;
    
    struct Payee {
        address wallet;
        string role;
        uint256 percentage;
    }
    
    modifier onlyUser(address _sender) {
        //require(tx.origin == msg.sender, "contracts are not allowed");
        uint32 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "contracts are not allowed");
        _;
    }
    
    uint256 public mintPrice = 0.01 ether;
    
    // mainnet
    IERC721 internal BLITMAP_CONTRACT = IERC721(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);
    
    // test
    //IERC721 internal BLITMAP_CONTRACT = IERC721(0x1b4C2BA0c7Ee2AAF7710A11c3a2113C24624852B);
    
    function withdrawToPayees(uint256 _amount) internal onlyUser(msg.sender) {
        //MAINNET
        Payee memory payee1 = Payee(0x3B99E794378bD057F3AD7aEA9206fB6C01f3Ee60, "artist", 25);
        Payee memory payee2 = Payee(0x575CBC1D88c266B18f1BB221C1a1a79A55A3d3BE, "developer", 25);
        Payee memory payee3 = Payee(BLITMAP_CONTRACT.ownerOf(346), "owner of #346", 50);
        Payee[3] memory payees = [payee1, payee2, payee3];
        
        
        for (uint256 i = 0; i < payees.length; i++) {
            Payee memory payee = payees[i];
            address payable to = payable(payee.wallet);
            to.transfer(_amount.mul(payee.percentage).div(100));    
        }
    }


    constructor() ERC721("The Soft Bid Guy", "BIDGUY") onlyOwner {}

    function mint(uint256 amount) external payable nonReentrant {
        require(msg.value >= mintPrice.mul(amount), "not enough ethers");
        withdrawToPayees(msg.value);
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
    
    
    function mintTo(address to, uint256 amount) external payable nonReentrant {
        require(msg.value >= mintPrice.mul(amount), "not enough ethers");
        withdrawToPayees(msg.value);
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();            
        }
        
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,ewogICAgIm5hbWUiOiAiVGhlIFNvZnQgQmlkIEd1eSIsCiAgICAiZGVzY3JpcHRpb24iOiAiaHR0cHM6Ly95b3VyYmlkc3Vja3Mud3RmIHwgT3JpZ2luYWwgQmxpdG1hcCBJRDogIzM0NiIsCiAgICAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCMlpYSnphVzl1UFNJeExqSWlJR0poYzJWUWNtOW1hV3hsUFNKMGFXNTVMWEJ6SWlCNGJXeHVjejBpYUhSMGNEb3ZMM2QzZHk1M015NXZjbWN2TWpBd01DOXpkbWNpSUhacFpYZENiM2c5SWpBZ01DQXpNakFnTXpJd0lpQjNhV1IwYUQwaU16VXdJaUJvWldsbmFIUTlJak0xTUNJK1BIUnBkR3hsUG1sdFlXZGxQQzkwYVhSc1pUNDhaR1ZtY3o0OGFXMWhaMlVnWVhKcFlTMXNZV0psYkQwaVdXOTFjaUJpYVdRZ2FYTWdjMjhnYzI5bWRDQjBhR0YwTGk0dUlpQWdkMmxrZEdnOUlqSTNNU0lnYUdWcFoyaDBQU0l5TXlJZ2FXUTlJbWx0WnpFaUlHaHlaV1k5SW1SaGRHRTZhVzFoWjJVdmNHNW5PMkpoYzJVMk5DeHBWa0pQVW5jd1MwZG5iMEZCUVVGT1UxVm9SVlZuUVVGQlVUaEJRVUZCV0VOQlRVRkJRVUZwUVhwd1QwRkJRVUZCV0U1VFVqQkpRakpqYTNObWQwRkJRVWRzVVZSR1VrWkJRVUZCTHk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2TDNZM0t5OHZMeTh2THk4dkx5OHZMeTh2THk4dmRqY3JMM1kzS3k4dkx5OHZkamNyTHk4dkx5OTJOeXN2THk4dkx5OHZMeTkyTnlzdkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OTJOeXN2ZGpjckx5OHZMeTh2THk4dkx5OHZMeTh2TDJ0TmNXWkdkMEZCUVVOT01GVnJOVlJCUlVFdlJVTkJkeTgwUkVGMk56ZG5XVXBFZDNvNUsyY3dTRU5tWmpJNFZGVlJjRWRMUkRSbU0xZ3dVa1IzYVVwVFpIQkVRVUZCUTBkRmJFVlJWbEkwYms4eVdXWllaVU5KUWxSSFoxaE1RWEpOZVcxaVlYVTVNV1ptTDJ0QlRVWjFVbVJGV2pKVmRscDZOUzlaVDJaRFpsSTNPRkpTTlZCb1JrUkhNa2wzVVUxc1psaG9RWGhSUVdoMU1IazVlRGh1YWtacVUxbDNkRWN5VEdKeU9IRjVNVE5hTWxsMlExUkZiRlpZY25FMWFWTkxUMEZFWkhGR2JUZ3ZWVmRvU21vck0xUkRkR3B3VlZkbVltRXdhRTlFU0RWdlNGQktXakZrYkU5Sk9EQnFPRXB4VTBnMVowWnFkbGd6UldWUmFTOURWMjVwWjFoVldraHNRMGw0ZDJkRFR6VXhOR3REZG5wRlRrdGxVbTAzVUdWeU0ya3lXbEpVWVU5elpETkpWazFpWTI0M2RsUnFZa0oxUmxOeWJIZEtlR3h3THpCS1RFbDZUblZYYVRCWGJYSnJSR1E1YTBOTU0zQnFkMjAzY0RSQ1F6VkVaVXRDV1hoTlRrNXBURVJtYVM5V2RVeFlOWHB2TDBoSmNFcFVjbUZyVm5sUVVqUnlWVVZMZUhRclpsSTFWRWxoYWpKcWN6Tm1TRWxsWkhKUFdUaE5OV1kwUlRoVmNEYzNVRVY1Y0doVlprOTBVbGwzVjBwblUybG5XSHBQV25wdVNFdFpiMDlaTDBFeFIzVm9iRlV2ZFdWTFEyMVFhRGRWVUVsSlJFaHFiSE5HU3pSQ09HaERkRGQ0SzNkQ1NVczVWbmhpTURWSlkzUk1VMjFDYURGa1FVeG1SMVZSUW5CamFYRnRUM2hMVFc5NU5VdFllbUpsYVZFMlZYQjRXR2RWWTFBMFRVaHlWRlZMZGpkRGR6azBZV05DYlVwb2VqSkViMHd2TVZkSlNtSlJMMDV1T0VGcFpVZzNabTFKVTNGMFNVazViRlpWY1dwUVIwUk1TbGhwYzNoUFdpdGxUVUZYU2s1VVUzTjBUbTk1YlVGbFdGTnVaRkJNV1hOamVuZFpOaXREVW5OaE1HWmhNRzlsUkRGeU9XZGFUa0pJYmxkd1kwUjFNWE5YWnl0akwxQXhWR2RKWlVKbWVHWjVhRlZEU0hNelIxSk1VRzA1VlROd2JtVjZWWFZEWkRkT1pUVmhaV1JVZVdadVYzUlFTWGwxTHk4MGFEaEtjbGtyTUdZd0sxWkhkaXRrUTFoVUwwdHNlSEJLT0hFelJUazRXbWcwVkVSNVJ6aDJhVE1yYkVWcE5VdEVSMGw2YlhFNFprRk1ORWw0VDJrMmRISlFSbU5CUVVGQlFWTlZWazlTU3pWRFdVbEpQU0l2UGp4cGJXRm5aU0JoY21saExXeGhZbVZzUFNJdUxpNTViM1VnYUdGMlpTQmlaV1Z1SUhacGMybDBaV1FnWW5raUlDQjNhV1IwYUQwaU1qZzBJaUJvWldsbmFIUTlJakk1SWlCcFpEMGlhVzFuTWlJZ2FISmxaajBpWkdGMFlUcHBiV0ZuWlM5d2JtYzdZbUZ6WlRZMExHbFdRazlTZHpCTFIyZHZRVUZCUVU1VFZXaEZWV2RCUVVGU2QwRkJRVUZrUTBGTlFVRkJRbEJCVTFCRVFVRkJRVUZZVGxOU01FbENNbU5yYzJaM1FVRkJSMnhSVkVaU1JrRkJRVUV2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2ZGpjckx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZkamNyTHk4dkx5OHZMeTh2ZGpjckwzWTNLeTkyTnlzdkx5OHZMeTh2THk4dkx5OHZMeTh2TDNZM0t5OHZMeTh2ZGpjckx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2VGxodGMzTm5RVUZCUTA0d1ZXczFWRUZDUVM5UlEwRjNMelJFUVhZNVFtYzBTa1IzWTB4RFoyWTFMMlpEVmtWVlVFUkpaR0k0T0dWMlZqUlNSRUZ4YURoTVlrbEJRVUZEVkZWc1JWRldValJ1VHpKWk5scExRMDFDUTBWSk1XVkRTMHgxYVdVNGNXVTNMeXRSVXpWcVJYcEthRXhDV1RsaE5sSXJWMHBJVkZBMVFrOXFSbU5aUjJGd1dqQlBjMjFhWkhOYWMyRkliVmN5ZVd4NVMwa3ZXVTF1ZVZCSk1rMWpjRlZYYm1zMWVsTjVRV1pZUmpOaFMwaENTVkpIT0dZelQwUk1SekJqTTBORFZDOVRaSGMwYmpOT1owVTFLemRvWlVSWVFrTmxhR05qUzBKME5WSmtiRzlSVWtSQ1kzbHVkVUZqZVVRd2NGWlRWMVY0UzFGS1dESlJNMmhMYm1zMWNIbHNTMlJIUlhCeWJVcGFhRWRyYzFwV1Z6Vk5RbTVNYzNRM2RtaE9WRUZIVmtVME1YVktVR2RyVGtsUFQwUm5Sa0pTTlV0Q2VreFJkVUozYmtkRlEyZzRVRXBNZDB0SVZraHJORWh2Tld4SldFRmxZMVZoT1dWNk9HTnFjak0wWXpoQlNuQTRWR2hYUWxsRGVERnlPSEZJUWxkbVFrZEZkM3BzV1ZWcE5qRTRjME5DUmtGS1NHTlBSM0JCY0VkUmMyOUVTVWRLZVN0UFRUaDNTRVJQZDNrNFFteEZVbmRaVDJkWFQxazJWVVZFZGpOd09GWjBTWGxqVDNGUFVEWXdLME14YjNKa2FFTkNia0phV2tGb01VOW5ObU4wU2taaFpYbDZjbHBvVDBWQkwxQkxNR3BVU0hkTGJrRXdhbE00ZVdSNGQwNTBSRmRHWlVWamRtVm1OR1I2WVdORmIyWnFLemRWZVdreFpUWk5jSGhoZWtReVYzVmFRbUZsY1haQlprRlhWeTl5TTBsRU5GTlVkeXN3UWs5RVdHTmpWMVUwWTFsMUwybHNiVGhtZDA1NGQydEhVa2hxYWs5Q2VsbEhOU3R0TlRCM2REYzNWamRtTWt4MU9GVkNkRVZ6YWxreGRHdHNjaTlGYTFOb1RrMXRWelZOZGxVeWNqbGxWek5zU1ZsSk5WbHVTbFZUWm5CVVNqRldSbUYxWVVRd01XWlNWSGhpZG5vMk5GTXpVbWw1YlVsM1Z6ZHhRbXhGVW5kWlMyNVRibUpVTHk4d1YyVjNWSHB1VUhaemR6aExURkZpWlU5RWN6VjJWVE5ZVjJkVE5raEtMelpQWnpsd09VRkVXaTl0Wm04clkyNVBSbVZGU1RKM1UwazRSM2c1WjNWSVFsaG1hVmRRZDBWYWQwRmpPWFF5U25OYUwzVTVWbVJtYlVJMWFUVTVWQzlXY2taRUsyZHRUMk00V25oSWJsRXZZMmg2VERCWWJqZGhNMnN2WTNWNFNsSkNUMk5EV1RWaVRWUm5WakUyYjNVelRtdE9hVXAyUmk5M1NFdFFiR1l3UmxwdGVUbG5RVUZCUVVKS1VsVTFSWEpyU21kblp6MDlJaTgrUEdsdFlXZGxJR0Z5YVdFdGJHRmlaV3c5SWxSb1pTQkhkWGtnVTI5bWRDd2dTMmx1WnlCdlppQmpkV05yY3lJZ0lIZHBaSFJvUFNJek1ERWlJR2hsYVdkb2REMGlNamtpSUdsa1BTSnBiV2N6SWlCb2NtVm1QU0prWVhSaE9tbHRZV2RsTDNCdVp6dGlZWE5sTmpRc2FWWkNUMUozTUV0SFoyOUJRVUZCVGxOVmFFVlZaMEZCUVZNd1FVRkJRV1JEUVUxQlFVRkVTVTFOY2taQlFVRkJRVmhPVTFJd1NVSXlZMnR6Wm5kQlFVRkdVbEZVUmxKR1FVRkJRUzh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMeTh2THk4dkwzWTNLeTh2THk4dkx5OHZMM1kzS3k4dkx5OHZMeTh2TDNZM0t5OHZMeTh2ZGpjckx5OHZMeTh2THk4dkx5OHZMM1kzS3k5Mk55c3ZMeTh2THk4dkx5OHZMeTh2THk4dkx5OHZMMWhhT1RaalFVRkJRVUo0TUZWck5WUkJSVUV2VFVKQlp5ODRRMEV3VERsbk16VkVkemN6UTNkdlQwSXZiamc1ZGxCR1JYbDJaWGRhTlM5UlFVRkJTMlpUVlZKQ1ZraHBZemRhYm5KbGNVMW5SVWxaYkVwclRGSndSekF3TmxkaU15OTFPWHBXVlRSNmR6QkdTV1pVWW5KeWRDdG1Wa2xZTldocVkwUkZiSEJXTjA5Q1ZWWTRabkEwTVdoR1pGRlRkRVEyWkRSUE5qQlVZa1UzUXpGMFdUQktjVms1TldscWNVMXdSbUZNUlVwbGNHdzFjVFJUTkU1RlN5OVpPVTFGVXpseVF6VlhURkZXYzBSclNuazJNWEJVVFZwcWFuRkpkVVUyYmtaSmRWSnNObkZWVnpkMlNYbFhiUzlYT1V0b2NVbzFhbUZVWjNOaVlUbE9TV0ZxYzNSaVRIZHdWM1pvY0VaeE1UaFhPVWhGTVRaVlIyMTVXbUZwUkVwVVJYRkZVVGhMVTJSV2IyMUxZVXB1Y1hKaFZscHBZVEJzUjFKcFlVazVlV1pXYjFKWFMzcHpWREJLZFVwclltNXhlbFZVZWt0d01YWnVaVmhHVW5SRk5ua3pabVozZHpaa1V6TlhhbXN5WlZSeFdIQjFWVFZQZVRGcWVUQnlaV3hwVUZOTE1IZE5WVFowVFVGNWRHYzBkR1F5Um1Rd1NFOVFWbWROTmtsR2IyZE9XVnB3ZDFNMGNGZG9PVkpYYkhoUFlYSk9iM1pqT1hSS1Vpc3Zjemc1ZVZkME0xbDBWM1psUjBGMlUzVnFVWFY1Y1hSd2IxRnBTVVp0Y1hoUlNYUnJWVlZuVERWS2JVazRWWEJoVmpsSE56VnJTM05UTm5OWVZqbGxTa041Um1FeFYxZzRVelZDWmtjeFJtRktRV0Z1ZEU1UmRDOW1kelpDYlZsM2NFSndaV2RLV1U5eGVuazJjMkZTTjBsV2VVMUxaRTFSY2xGRVl6bFhhVkpNUlVaUlZERkdZV2RhUldsWGMwaFZjVFIzV1ZsUWFrVkdhV2hHWVhoblEzUkJVM04yWjFGMFNuSlRaWEJxVmxaSU1pczJXVlpwVkZaMWRFdEhjMk0wY1ZGdk0zUkxlblJpVW1kSFRWZFVWV3h4YTB4U1EzVlpWa2xFVnpodVpUWlNRM1kwVkhaM2RVeFVVMWRUUVhsME5WaFZUREJsUzNwaGRYbDNZMVp5ZEZkRGNtZ3lhRzltUkV0eE1tVjBObkkxZDNKQlNsazRWMGh6UXk5UlUzUnVNMU5NUkVJeUsxTkdRekU0YTNObVRYSlVkSE0wVkhKa1JERXZVWGMxTkVkQ2JHOVJWM055YkhnclVIZ3JSbXhITmpOaE5GVldjbkZXYjNwWE1UVjNPRTQzWVU5c2F6Wk9NRVpKYm1sMll6aFhhM0J2Y21oelJtUnBiR0ZLY20xc0wxSmlXalZNU0hFeGVsUlhUV3h3U3poVVdFaHZNbFUyZUZCbFYxSm1kWFJ1WkZwUFlUWm1NVVZzY0hKeGRrRkZha0ZxVW5sc1dIRkdUekIyTVRBMGNsUTJNM00yVlhkelZtbEhkSGRIYm1kV2IxUlBLM0ExVlVsaE0wRmhaVUpYZEVGWmRIUkVkR1F4YmpsUGNURkJZbkJ0VjFCYU1GUm9kaXNyWlZZeWMyUXllamxvT1hoemJGVldjbUl6ZGk4eGJXZEJRVUZCUWtwU1ZUVkZjbXRLWjJkblBUMGlMejQ4TDJSbFpuTStQSE4wZVd4bFBuUnpjR0Z1SUhzZ2QyaHBkR1V0YzNCaFkyVTZjSEpsSUgwdWMyaHdNQ0I3SUdacGJHdzZJQ05rTlRkbFlqRWdmU0F1YzJod01TQjdJR1pwYkd3NklDTmxOV0ZqWWpNZ2ZTQXVjMmh3TWlCN0lHWnBiR3c2SUNOaVlUY3pPVE1nZlNBdWMyaHdNeUI3SUdacGJHdzZJQ05sT1dVNVpUa2dmU0E4TDNOMGVXeGxQanh3WVhSb0lHTnNZWE56UFNKemFIQXdJaUJrUFNKTk16SXdJRE15TUV3d0lETXlNRXd3SURCTU16SXdJREJNTXpJd0lETXlNRm9pSUM4K1BIQmhkR2dnWTJ4aGMzTTlJbk5vY0RFaUlHUTlJazB6TWpBZ01qa3dUREk1TUNBeU9UQk1Namt3SURJNE1Fd3lOekFnTWpnd1RESTNNQ0F5TnpCTU1qUXdJREkzTUV3eU5EQWdNall3VERJek1DQXlOakJNTWpNd0lESTFNRXd5TURBZ01qVXdUREl3TUNBeU5EQk1NVFl3SURJME1Fd3hOakFnTWpNd1RERXpNQ0F5TXpCTU1UTXdJREl5TUV3eE1UQWdNakl3VERFeE1DQXlNVEJNT0RBZ01qRXdURGd3SURJd01FdzJNQ0F5TURCTU5qQWdNVGt3VERVd0lERTVNRXcxTUNBeE9EQk1NekFnTVRnd1RETXdJREUyTUV3eU1DQXhOakJNTWpBZ01UUXdUREV3SURFME1Fd3hNQ0F4TWpCTU1qQWdNVEl3VERJd0lEa3dURE13SURrd1RETXdJRGd3VERRd0lEZ3dURFF3SURjd1REWXdJRGN3VERZd0lEWXdURGd3SURZd1REZ3dJRFV3VERFNU1DQTFNRXd4T1RBZ05qQk1Nak13SURZd1RESXpNQ0EzTUV3eU5EQWdOekJNTWpRd0lEZ3dUREkyTUNBNE1Fd3lOakFnT1RCTU1qZ3dJRGt3VERJNE1DQXhNREJNTWprd0lERXdNRXd5T1RBZ01URXdURE14TUNBeE1UQk1NekV3SURFeU1Fd3pNakFnTVRJd1RETXlNQ0F5T1RCYUlpQXZQanh3WVhSb0lHTnNZWE56UFNKemFIQXlJaUJrUFNKTk16SXdJREV4TUV3ek1UQWdNVEV3VERNeE1DQXhNREJNTXpBd0lERXdNRXd6TURBZ09UQk1Namd3SURrd1RESTRNQ0E0TUV3eU5qQWdPREJNTWpZd0lEY3dUREkwTUNBM01Fd3lOREFnTmpCTU1qTXdJRFl3VERJek1DQTFNRXd5TURBZ05UQk1NakF3SURRd1REZ3dJRFF3VERnd0lEVXdURFV3SURVd1REVXdJRFl3VERRd0lEWXdURFF3SURjd1RESXdJRGN3VERJd0lEZ3dUREV3SURnd1RERXdJREV4TUV3d0lERXhNRXd3SURFMU1Fd3hNQ0F4TlRCTU1UQWdNVGN3VERJd0lERTNNRXd5TUNBeE9EQk1NekFnTVRnd1RETXdJREU1TUV3ME1DQXhPVEJNTkRBZ01qQXdURFV3SURJd01FdzFNQ0F5TVRCTU56QWdNakV3VERjd0lESXlNRXd4TURBZ01qSXdUREV3TUNBeU16Qk1NVE13SURJek1Fd3hNekFnTWpRd1RERTFNQ0F5TkRCTU1UVXdJREkxTUV3eE9UQWdNalV3VERFNU1DQXlOakJNTWpJd0lESTJNRXd5TWpBZ01qY3dUREkwTUNBeU56Qk1NalF3SURJNE1Fd3lOakFnTWpnd1RESTJNQ0F5T1RCTU1qa3dJREk1TUV3eU9UQWdNekF3VERNeE1DQXpNREJNTXpFd0lETXhNRXd6TWpBZ016RXdURE15TUNBeU9UQk1Namt4SURJNU1Fd3lPVEFnTWpnd1RESTNNQ0F5T0RCTU1qY3dJREkzTUV3eU5ERWdNamN3VERJME1DQXlOakJNTWpNd0lESTJNRXd5TXpBZ01qVXdUREl3TUNBeU5UQk1NakF3SURJME1Fd3hOakFnTWpRd1RERTJNQ0F5TXpCTU1UTXhJREl6TUV3eE16QWdNakl3VERFeE1DQXlNakJNTVRFd0lESXhNRXc0TUNBeU1UQk1PREFnTWpBd1REWXdJREl3TUV3Mk1DQXhPVEJNTlRBZ01Ua3dURFV3SURFNE1Fd3pNU0F4T0RCTU16QWdNVFl3VERJd0lERTJNRXd5TUNBeE5EQk1NVEFnTVRRd1RERXdJREV5TUV3eU1DQXhNakJNTWpBZ09UQk1NekFnT1RCTU16QWdPREJNTkRBZ09EQk1OREVnTnpCTU5qQWdOekJNTmpBZ05qQk1PREFnTmpCTU9ERWdOVEJNTVRrd0lEVXdUREU1TUNBMk1Fd3lNamtnTmpCTU1qTXdJRGN3VERJek9TQTNNRXd5TkRBZ09EQk1NalU1SURnd1RESTJNQ0E1TUV3eU56a2dPVEJNTWpnd0lERXdNRXd5T1RBZ01UQXdUREk1TUNBeE1UQk1NekE1SURFeE1Fd3pNVEFnTVRJd1RETXlNQ0F4TWpCTU16SXdJREV4TUZwTk1qSXdJREUzTUV3eU1qQWdNVFV3VERJeE1DQXhOVEJNTWpFd0lERTJNRXcyTUNBeE5qQk1OakFnTVRVd1REVXdJREUxTUV3MU1DQXhOekJNTmpBZ01UY3dURFl3SURFNE9VdzJNU0F4T1RCTU1qQXdJREU1TUV3eU1EQWdNVGd3VERjd0lERTRNRXczTUNBeE56Qk1NakF3SURFM01Fd3lNREFnTVRjNVRESXdNU0F4T0RCTU1qRXdJREU0TUV3eU1UQWdNVGN3VERJeU1DQXhOekJhVFRFMk1DQXhNakJNTVRZd0lERTBNRXd4T1RBZ01UUXdUREU1TUNBeE1qQk1NVFl3SURFeU1GcE5OekFnTVRRd1RERXdNQ0F4TkRCTU1UQXdJREV5TUV3M01DQXhNakJNTnpBZ01UUXdXazAwTUNBeE1EQk1OREFnTVRFd1RERXhNQ0F4TVRCTU1URXdJREV3TUV3eE1qQWdNVEF3VERFeU1DQTVNRXd4TVRBZ09UQk1NVEV3SURjd1RERXdNQ0EzTUV3eE1EQWdNVEF3VERRd0lERXdNRnBOTVRVd0lEY3dUREUwTUNBM01Fd3hOREFnT1RCTU1UTXdJRGt3VERFek1DQXhNREJNTVRRd0lERXdNRXd4TkRBZ01URXdUREkxTUNBeE1UQk1NalV3SURFd01Fd3hOVEFnTVRBd1RERTFNQ0EzTUZvaUlDOCtQSEJoZEdnZ1kyeGhjM005SW5Ob2NETWlJR1E5SWswMk1DQXhOREJNTmpBZ01UVXdUREV3TUNBeE5UQk1NVEF3SURFME1FdzJNQ0F4TkRCYVRUWXdJREV3TUV3Mk1DQTVNRXd4TURBZ09UQk1NVEF3SURFd01FdzJNQ0F4TURCYVRURXlNQ0E1TUV3eE16QWdPVEJNTVRNd0lERXdNRXd4TkRBZ01UQXdUREUwTUNBeE1UQk1NVEV3SURFeE1Fd3hNVEFnTVRBd1RERXlNQ0F4TURCTU1USXdJRGt3V2sweE1qQWdOekJNTVRJd0lEZ3dUREV6TUNBNE1Fd3hNekFnTnpCTU1USXdJRGN3V2sweE5UQWdNVEF3VERFMU1DQTVNRXd5TURBZ09UQk1NakF3SURFd01Fd3hOVEFnTVRBd1drMHhOakFnTVRRd1RERTJNQ0F4TlRCTU1qQXdJREUxTUV3eU1EQWdNVFF3VERFMk1DQXhOREJhVFRFeE1DQXhPVEJNTVRFd0lESXdNRXd4TkRBZ01qQXdUREUwTUNBeE9UQk1NVEV3SURFNU1GcE5NakF3SURFNE1Fd3lNREFnTVRrd1RESXhNQ0F4T1RCTU1qRXdJREU0TUV3eU1EQWdNVGd3V2sweU1qQWdNVGd3VERJeE1TQXhPREJNTWpFd0lERTNPVXd5TVRBZ01UY3dUREl5TUNBeE56Qk1Nakl3SURFNE1Gb2lJQzgrUEhWelpTQWdhSEpsWmowaUkybHRaekVpSUhnOUlqRTBJaUI1UFNJMUlpQXZQangxYzJVZ0lHaHlaV1k5SWlOcGJXY3lJaUI0UFNJNUlpQjVQU0l5TXpZaUlDOCtQSFZ6WlNBZ2FISmxaajBpSTJsdFp6TWlJSGc5SWpraUlIazlJakk0TlNJZ0x6NDhMM04yWno0PSIKfQ==#";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    
}