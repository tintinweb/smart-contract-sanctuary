/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/security/Pausable.sol

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
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
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}



// File: contracts/PartyBones.sol

pragma solidity ^0.8.0;







contract PartyBones is ERC721URIStorage, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter public _mintedTokens;
    uint internal constant MAX_Bones = 10300;
    uint internal ticket_price = 60000000000000000; // 0.06 ETH
    uint private prime_seed;
    
    // No more than 10,300 bones to be sold
    modifier saleIsOpen{
        require(_mintedTokens.current() < MAX_Bones, "Sale end");
        _;
    }
    
    // Modify sale price
    function change_ticket_price(uint new_price) public onlyOwner returns(uint)
    {
        ticket_price = new_price;
        return(new_price);
    }
    
    // View price
    function price() public view returns (uint256) {
        return ticket_price; 
    }
    
    string private baseURI = "";
    
    constructor () payable ERC721("PB", "Party Bones") {}
    
    mapping (uint256 => string) boneNames;
    
    mapping(address => bool) public authorised_contracts;
    
    // Contracts for Party Bone Merging authorised and removed here
    function addAuthorisedAddress(address _address) public onlyOwner {
        authorised_contracts[_address] = true;
    }
    
    function removeAuthorisedAddress(address _address) public onlyOwner {
        authorised_contracts[_address] = false;
    }
    
    // Modifier to only alow merging contracts to interact with this function
    modifier onlyAuthorised()
    {
        require(authorised_contracts[msg.sender]);
        _;
    }
    
    // set seed number for non-serialised minting
    function set_seed_Prime(uint prime_number) onlyOwner public
    {
        prime_seed = prime_number;
    }

    // returns current token minting count
    function check_mintedCount() view public returns (uint256)
    {
        return _mintedTokens.current();
    }
    
    // modify the base URI 
    function change_base_URI(string memory new_base_URI)
        onlyOwner
        public
    {
        baseURI = new_base_URI;
    }
    
    // check token's URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    // writing bone names as metadata associated with token
    function set_tokenID_description(uint256 tokenId, string memory nameofbone)
        onlyOwner
        public
    {
        boneNames[tokenId] = nameofbone;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    // pause minting and merging
    function pause() public onlyOwner {
        _pause();
    }
    
    // unpause minting and merging 
    function unpause() public onlyOwner {
        _unpause();
    }
    
    // check name of a bone
    function check_bone_ID_name(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        string memory nameofbone = boneNames[tokenId];
        return nameofbone;
    }
    
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    // burn Party Bone (I wouldn't!)
    function burn(uint256 tokenid)
        public
        returns (uint256)
    {
        require(msg.sender == ownerOf(tokenid), "This wallet does not own the tokenID!");
        _burn(tokenid);
        return tokenid;
    }
    
    // admin only function for burning in case something messes up
    function burn_admin(uint256 tokenid)
        public
        onlyOwner
        returns (uint256)
    {
        _burn(tokenid);
        return tokenid;
    }
    
    // bones are burned when merged for a limb
    function burn_for_limb(uint256 tokenid)
        public
        onlyAuthorised
        whenNotPaused
        returns (uint256)
    {
        _burn(tokenid);
        return tokenid;
    }
    
    // primary sale function for the admin - for airdrops mainly and creator team
    function mint_primary_admin(address address_, uint256 numberOfTokens)
        public
        onlyOwner
        returns (uint256)
    {
        require(_mintedTokens.current() + numberOfTokens <= MAX_Bones, "This exceeds the maximum number of Party Bones on sale!");
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newItemId  = (((prime_seed*_mintedTokens.current()^2))) % MAX_Bones + 1;
            _mintedTokens.increment();
            _mint(address_, newItemId);
        }
        
        return _mintedTokens.current();
    }
    
    // mint function for admin - in case something goes wrong 
    
    function mint_admin(address address_, uint256[] memory tokenIds)
        public
        onlyOwner
        returns (uint256[] memory)
    {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _mint(address_, tokenIds[i]);
        }
        
        return tokenIds;
    }
    
    // mint your Party Bone!
    function createBone(uint256 numberOfTokens)
        public
        payable
        saleIsOpen
        whenNotPaused
    {   
        require(numberOfTokens < 21, "No more than 20 Tokens at one time!");
        require(_mintedTokens.current() + numberOfTokens <= MAX_Bones, "This exceeds the maximum number of Party Bones on sale!");
        require(ticket_price * numberOfTokens <= msg.value, "Please send correct amount");
        require(msg.sender == tx.origin, "Can only mint through a wallet");
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 newItemId  = (((prime_seed*_mintedTokens.current()^2))) % MAX_Bones + 1;
            _mintedTokens.increment();
            _mint(msg.sender, newItemId);
        }
    }
    
    // only owner - check contract balance
    function checkContractBalance()
        public
        onlyOwner
        view
        returns (uint256)
    {
        return address(this).balance;
    }
    
    // only owner - withdraw contract balance to wallet
    function withdraw()
        public
        payable
        onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    // retrieve tokens by owner
    function retrieveTokens(address owner) public view returns (uint256[] memory tokens) {
        uint256 iterator = balanceOf(owner);
        uint256[] memory tokenlist = new uint256[](iterator);
        for (uint256 i = 0; i < iterator; i++){
            tokenlist[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenlist;
    }
    
    // retrieve names of tokens by owner
    function retrieveTokenNames(address owner) external view returns (string[] memory tokens) {
        uint256 iterator = balanceOf(owner);
        string[] memory tokenlist = new string[](iterator);
        for (uint256 i = 0; i < iterator; i++){
            tokenlist[i] = check_bone_ID_name(tokenOfOwnerByIndex(owner, i));
        }
        return tokenlist;
    }
    
}

contract PartyBonesMinter is Ownable, Pausable{
    
    mapping(address => uint256) public eligible_bones;
    
    constructor () payable {
        eligible_bones[0x003c63EC6Dbe302504bfe1E0C0C771c89f46fe11] = 1;
        eligible_bones[0x011A991Df27Fb53637B7319d3A43e91B5dA5b4E8] = 1;
        eligible_bones[0x014C6B9e5EE1bFd155c129DF6cF228f396BE41c1] = 1;
        eligible_bones[0x01e9432a589158228D061626c537Fb11bEF0873D] = 12;
        eligible_bones[0x0282e055D3b2f7c0AD656952Ac1bB989FB6D0086] = 4;
        eligible_bones[0x02E4F367fc7cb77d9b6818440648fC4dD5d21891] = 2;
        eligible_bones[0x040845FE3c8F252C75bdeAdd61Ae00920f464662] = 1;
        eligible_bones[0x06D30f1Fb36d648Baaf2042918b02137F9f876A9] = 3;
        eligible_bones[0x080aD9D187b0fd917313BcB99B9fED79EC6b5AAe] = 1;
        eligible_bones[0x0832221806dF52ff6759fF283cD47Eb52B86C2fa] = 3;
        eligible_bones[0x08Bf8D6fA77F7Bc937E62DCb7a5d1201890C48fA] = 2;
        eligible_bones[0x08d02488C97855325Cb7Fb705BbD766416eAC017] = 1;
        eligible_bones[0x09306cFea01e396F89De0Ee00474657b4C86D55b] = 3;
        eligible_bones[0x09d520c793dd698bd910984adB4c4718bb20bEdA] = 1;
        eligible_bones[0x0A2F11af1697F563d602Ec0c7Fed18E53Cc307C2] = 1;
        eligible_bones[0x0aF9983A787B7eaA9cb6f18D872476B536c922E5] = 4;
        eligible_bones[0x0B2b93c8A18e3AAef1ff106613c3C222714388C6] = 1;
        eligible_bones[0x0C3048115677F780CABf52532A98fd0a1a19893E] = 1;
        eligible_bones[0x0d0158301E71511022362DDDd81Cb34579fd7c25] = 1;
        eligible_bones[0x0D567F4BF07BC32865595FC9b43db40cB35Ea594] = 3;
        eligible_bones[0x0De6716111df03b5FeF262154D4850A4f7455b3B] = 3;
        eligible_bones[0x0eB6bB47a071F40CCaE5f2534666Ed9b7ADFDA16] = 2;
        eligible_bones[0x0F03231440F6624881576ee8C5e0C3278815E3B0] = 3;
        eligible_bones[0x0fe60E55a8C0700b47d4a2663079c445Fc4A5893] = 1;
        eligible_bones[0x100f2EF1D7Ae71fDD792Fd3F2C18ef96C44d916F] = 1;
        eligible_bones[0x1028a8BfbA4AD62caf408Fc6c541F42A9015b0c0] = 2;
        eligible_bones[0x106b1d3E1dAF0b6Da0D4c86C23900980bFc92Ce7] = 8;
        eligible_bones[0x11a3c58F9aEeC448F9e3AC45796243c63757D402] = 1;
        eligible_bones[0x13a9518A451EDaD79079753c89Cc7197FF3f570A] = 3;
        eligible_bones[0x15af8DF7541d8d1264dd14aC6baddB04b98A89aa] = 2;
        eligible_bones[0x15b5E2A732D946D79dca83D6EC47F1C7062eB515] = 1;
        eligible_bones[0x16369Ac319D02b8dc7Ed74Fc45D496F06D5cFD60] = 2;
        eligible_bones[0x166a896bEC257b46E345BA0C207769A381ce25fC] = 1;
        eligible_bones[0x167f2028e2410E0A5C51c62F63B8c1d4D26f4cE4] = 5;
        eligible_bones[0x170b7ddA174f3EEb659b6894AE94fEf93495c675] = 1;
        eligible_bones[0x17853cbED35F3153DC144D709e01575cb75d326b] = 2;
        eligible_bones[0x17b737e3142330b7c21290568f43da1e75C55c7B] = 3;
        eligible_bones[0x180333e4433F2e1122D725151Af7E6db97d1C660] = 3;
        eligible_bones[0x184DFd1197187c8fFc88Da905fBaCd31b739fA41] = 8;
        eligible_bones[0x1878D0B936CEfcC09Bee7B1405f7E921028Ac81F] = 2;
        eligible_bones[0x1896B1a2836D24c7A0714CD5593c4b4064d3B031] = 1;
        eligible_bones[0x18BD7cC5A8add1B36346e3a723521e5db4eD1E50] = 5;
        eligible_bones[0x19308b90080eD48B2617db0943cC33482497c937] = 6;
        eligible_bones[0x1b3ae8099Ab8d9CEF0A7509b419B559e58Ce2652] = 2;
        eligible_bones[0x1b79F778Dd23Df64B7f1034Dc339615BdA57A931] = 1;
        eligible_bones[0x1b96d78736c106e8a90997B4c8ae7B2112d67d6d] = 6;
        eligible_bones[0x1BBb2295Ae8EBc67BB20B80Ec0788194d98b886c] = 2;
        eligible_bones[0x1cCb2f538e97568E3C363d3191aCaE50ba8389B8] = 1;
        eligible_bones[0x1CFEEE9b366E103b89Fd082530aAE7Cbb1Ca725B] = 18;
        eligible_bones[0x1D5C30676cA03adAe00257568B830C8D424A1e53] = 3;
        eligible_bones[0x1d92c03E25a57c0e91a675b496456ab5BB695D36] = 3;
        eligible_bones[0x1e121993b4A8bC79D18A4C409dB84c100FFf25F5] = 3;
        eligible_bones[0x1ef24F12aBF108B2516F2D0cc31892eC595AE292] = 1;
        eligible_bones[0x21f38BF3A6706dEb5a3282DE523b9e440DA7868a] = 5;
        eligible_bones[0x22801922544feFc518e1c80FBA92f633fE58161b] = 4;
        eligible_bones[0x2291E649Cc1B0a4BcFf64ab64574E35F2AE49F11] = 71;
        eligible_bones[0x23046D9aa616A390Aab7fAbAFC944A593141a66a] = 6;
        eligible_bones[0x2342989c3E1DC7A12cE91490B4D49A74FCC4D9B8] = 16;
        eligible_bones[0x23AE543c62F4602e8F143334DFc6f3d1778F35Ae] = 1;
        eligible_bones[0x245c157530233a165Cd9BD2a15C5229E87e89fB8] = 2;
        eligible_bones[0x25255a36287c9DF4B2363Fd9F998CEEc7F12BEf0] = 1;
        eligible_bones[0x25C5Cc4BC8D15fef28140CB78735A5000DCBa337] = 1;
        eligible_bones[0x261013b6398b6ad2276e8f7Edeb556DC197CB182] = 1;
        eligible_bones[0x271ae5A9e689ee106EeF2E70861122Aaf2A3135f] = 1;
        eligible_bones[0x27308C85BC218Bd1C3b946F76fb7b40C50d91479] = 1;
        eligible_bones[0x273Dc0347CB3AbA026F8A4704B1E1a81a3647Cf3] = 1;
        eligible_bones[0x27dcB67fe978CC420F8aC470dC22A0699d90da29] = 2;
        eligible_bones[0x2800D55C7d96206a3e51977b418a8AA555708726] = 1;
        eligible_bones[0x2947025a00F8CfA01a5Fb824bd1E98e129F178Cb] = 16;
        eligible_bones[0x294803520A1E7B671C105C8a3D94836f40B2b557] = 15;
        eligible_bones[0x29833F79F08C6093B3A20D584cB3aA98b0c787d3] = 1;
        eligible_bones[0x2a4A017FB570f70d84749f805a808F658d72B121] = 1;
        eligible_bones[0x2B2C869539188c28c202D086fE99c554493f72DD] = 3;
        eligible_bones[0x2d1d925F7144a3Dd56913eB4bBd011b52dc2A2F3] = 3;
        eligible_bones[0x2D3ad90fCf272135009520A310f486D12c9a4231] = 1;
        eligible_bones[0x2dBf90d5999a42C819F2950eE004d074046C87a4] = 12;
        eligible_bones[0x2e592c580435AD7794591FD9bdeF3af86e856D7f] = 2;
        eligible_bones[0x2e61f3E5E130a9B46A49cEE5B0539A08aD0F355B] = 3;
        eligible_bones[0x2f05A1f7ED11734cACB7f62F979eecB09E68b360] = 3;
        eligible_bones[0x316E30d702f47db26Cd925ca4b75ce019594e80F] = 6;
        eligible_bones[0x33593dce4236dc7c740f19512C2ac9Cb3A29A5E4] = 1;
        eligible_bones[0x348eff9be6EBF601000221F869EFbE26560CE4EF] = 2;
        eligible_bones[0x34EE160D57C7C14D018B6F751fAfd1060b560dB6] = 5;
        eligible_bones[0x36165f895d6674DA2cD19aDE30869eDDCAb1DB38] = 3;
        eligible_bones[0x36aB75710650754c32e4850D2ad050849EBb5899] = 1;
        eligible_bones[0x37910f3C21912f1689dB81264B29711Cc40d263a] = 1;
        eligible_bones[0x37BFc643769fEd7217178b19bC4A6E6365b17082] = 1;
        eligible_bones[0x38e76C87D7Bc4b0A5C31077D330804A4d0ee33f1] = 1;
        eligible_bones[0x3B9a4ec140AB95B32f93F4dCD7Eedb589297B647] = 1;
        eligible_bones[0x3C0AC57fDedFeD4e2EdD2bb7df464cE96dB2a5fE] = 1;
        eligible_bones[0x3c521687604cE4B38d2E579EE7636069eB1355F6] = 4;
        eligible_bones[0x3CFbC51d12d88EBf24196d951C5E05C665C049F2] = 4;
        eligible_bones[0x3d267A32f84d14B22822301c2659556B8FAAD930] = 1;
        eligible_bones[0x3DdeF70eec84Cd01Fd23758f0C399C839D840F2b] = 1;
        eligible_bones[0x3DFA72D396b1b1D22e39D58b203a351dDEe024e7] = 5;
        eligible_bones[0x3e00d5df867d5fE6012693D8D3C945512408927d] = 1;
        eligible_bones[0x3E8f0bcbCc283296fD831Cc5312714335F19B340] = 15;
        eligible_bones[0x3f583e18af11aB617Cd9147f7fb7dc3138DcA5EE] = 2;
        eligible_bones[0x40f249A353a66DF0ade87d7c587146FCE7531A79] = 1;
        eligible_bones[0x41Ab8f6dB3998685ee817FEf052B367Aed6E71C0] = 1;
        eligible_bones[0x4221E209640b90901c4932129bfaD744e5A7DadE] = 2;
        eligible_bones[0x42c7bFe96C02eC253f3D9e34F24d5E263935d7A4] = 1;
        eligible_bones[0x45d2baFe56c85433e0b9f9b50dd124ea3041f223] = 2;
        eligible_bones[0x468162396A915dE5c14F8F8A96D4E2F1aE520b03] = 21;
        eligible_bones[0x46c1fd5e7847a68B963AC57067741582b6d2f8d2] = 1;
        eligible_bones[0x48eA5F638f1383270b05541761163a1585988A7A] = 1;
        eligible_bones[0x49075225DF881Cd5682606732fEB168bDAFD9E68] = 22;
        eligible_bones[0x4A0A344a76327987E7e1f6682cFC60bb5aAb9660] = 2;
        eligible_bones[0x4AF143D85580d837b804852C12612Ad964DC13f8] = 34;
        eligible_bones[0x4bC4Ad70A89eBECFa5DDBE87F914edD4Bc153BC8] = 5;
        eligible_bones[0x4C9dba5fbBFddF8E006F28D0534F918d8Fcf4daa] = 2;
        eligible_bones[0x4D4803722142AFc24A469729Bf10fD88414f0F65] = 1;
        eligible_bones[0x4d8f57C23Aa81d6B2ce89249966FA185A2e93bc8] = 1;
        eligible_bones[0x4EbF1366b046950dD0F6e00C2ffBD60630a18c5E] = 1;
        eligible_bones[0x4fB9316f2EE8FB48AddCC3e996e5115A7E1F237F] = 3;
        eligible_bones[0x526Fd8f3a445Da35495e7Af42a198C80DA07f30f] = 2;
        eligible_bones[0x52AC5997d2Ac830D54b4BaD431aB95546d279144] = 10;
        eligible_bones[0x541bf8Bf17271e3eFd75a4a0c538CD09F16D9e99] = 1;
        eligible_bones[0x54aCF4977fBBB1D085e001fCDFe43c7c90891f32] = 2;
        eligible_bones[0x54d339cFD8F308D32C2F07f5Dc9dD34AF7753e20] = 9;
        eligible_bones[0x550e970E31A45b06dF01a00b1C89A478D4d5e00A] = 12;
        eligible_bones[0x58D777F9592d77f2B490A930481A0cc82128651F] = 11;
        eligible_bones[0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95] = 1;
        eligible_bones[0x5956E7A6ab0e2CC10C078C875139e6012c8e3eBb] = 4;
        eligible_bones[0x59F1875986A5EAc58Bf4959789fD5A3A3cb36C6E] = 3;
        eligible_bones[0x5a503C27F7C865e63556968EdB9540Cc67fCBB3a] = 1;
        eligible_bones[0x5E026495023fF8f31F12Da0Ce7e0A0Fb6A4d74f0] = 1;
        eligible_bones[0x5F6ceF30C7B2c200f1243eC727Fa2a25fA08d2DD] = 2;
        eligible_bones[0x61c0F6c65194aD959B72398537dE448d5F916b33] = 2;
        eligible_bones[0x6395ebaEdae3420E9D8c1A8c6268df9e829A32aC] = 1;
        eligible_bones[0x646F1ab329f5120Eb75f14B75D6F82d30A3c04B4] = 3;
        eligible_bones[0x64B110063e6b688dfa0E5f6E7a1653321891b35A] = 1;
        eligible_bones[0x65CE29640736a46C62e7d61A7337e4D3474D6192] = 1;
        eligible_bones[0x65EF8236830cC27270891868C00e689dC25d0D0E] = 1;
        eligible_bones[0x66883274f20a617E781c3f869c48eD93a041F178] = 4;
        eligible_bones[0x66F02e34Ce51397D9eCEe0bec87E09Ef9d67993e] = 1;
        eligible_bones[0x6849536eedb202f00c053652178E4B8dC1c5C1Be] = 4;
        eligible_bones[0x689fD10edf629d0345156128a189295D68594741] = 1;
        eligible_bones[0x6A9A8E67DBe22AF0Bb55eA0FA44Df8212b175a1D] = 4;
        eligible_bones[0x6b0bf3dd3F83c1776769a87cb080eF370288f355] = 15;
        eligible_bones[0x6B3878e5db0be9436D67f10B24C40Cd57B657952] = 1;
        eligible_bones[0x6C92f8A08db5cf58AE5C935fe730CA63E21497E9] = 2;
        eligible_bones[0x6d1E9895665516283b374c16148A8e8D156d7cD1] = 3;
        eligible_bones[0x6db844C3425031d2AC1B98A68e6561E32e2B7eC4] = 1;
        eligible_bones[0x6E024B6a9C58b3F941fF08b7CaF348fEbB601e84] = 3;
        eligible_bones[0x6E08A394A1545faDaD5638509cc5D388C2593653] = 2;
        eligible_bones[0x6e2E69e6eAB951baa91e7a0ab995e126F303a2e8] = 1;
        eligible_bones[0x6f312f53307925942f7D6d5d8A066f648A51F7D0] = 1;
        eligible_bones[0x6FFbc344188C05B840BDb1751de3E2c596813b1c] = 23;
        eligible_bones[0x709e8CFBE13F645D03DE08A7d3DA46a4B78144AD] = 1;
        eligible_bones[0x70Af43c7fbc3B83adBb03bf7E56e1D57Fa89870c] = 4;
        eligible_bones[0x70b1aB8FE7dD8ca86016053088A6b07187b5E4bE] = 1;
        eligible_bones[0x7137a78413Aab4a1eDCbCe16471DF28C5A0fFBdA] = 2;
        eligible_bones[0x714025F79A27D68696F86e995Cc05de47883E4A1] = 2;
        eligible_bones[0x72e4E7C510DC0db7A90a1c76Cd8Da74E205C8bf9] = 7;
        eligible_bones[0x73F4e28928E26623278159Bcf82aFff512863bA8] = 2;
        eligible_bones[0x73fc291a4740Fd0D2dF9C0aaab689726684ce300] = 1;
        eligible_bones[0x751462EC653a515Bbd9A0608A0Dca8f8173f1256] = 2;
        eligible_bones[0x7724c19b5AC3230B8b74457291A5f1c2e09496B1] = 10;
        eligible_bones[0x777d92Fcb83Ca9131B05ce579D9A951019c4Ca5c] = 1;
        eligible_bones[0x782fC2754CF28e116C63044B39d6551eFdc11d94] = 1;
        eligible_bones[0x786c9Fb9494Cc3c82d5a47A62b4392c7004106ca] = 1;
        eligible_bones[0x78c3deFFDE9C9216473cd340F3b24FDAC4c43427] = 2;
        eligible_bones[0x7904aDB48351aF7b835Cb061316795d5226b7f1a] = 20;
        eligible_bones[0x7949eb8E7b8d83eAA26D8Ad2854E6D3c59da6813] = 4;
        eligible_bones[0x79908206051bD137905680e59b8bA3F0b90D302f] = 19;
        eligible_bones[0x7a6aD84cCC994931934BEe3D66eDBEa6Ce4bFf9f] = 1;
        eligible_bones[0x7a802D75Eeac8E81eC3857412507C3426820D450] = 2;
        eligible_bones[0x7c03d483C9BFe77EF710dF050FeA54cacA4F0b46] = 1;
        eligible_bones[0x7D718c010b00a1e2e4Bb3b552653ffa21Eb6aEDA] = 1;
        eligible_bones[0x7e6F64C3052Fd641D422d57832AC61A071b9aB6E] = 1;
        eligible_bones[0x7FbE31a692C14d6F2e0F58dA3aa974CFFfaCf09e] = 1;
        eligible_bones[0x80040312D5B96eF9C459BDC68451aBA61eBFb7EF] = 1;
        eligible_bones[0x8260647ab3E9C45cC4a1EB223fdEda15a1bb08E6] = 1;
        eligible_bones[0x83890cF7c61EbAF717de7c7cdd0C1ABf85aBD559] = 3;
        eligible_bones[0x83b6d8e99539bf54b55Eb62E0064E3b8d1ccFdA9] = 5;
        eligible_bones[0x8413f65e93d31f52706C301BCc86e0727FD7c025] = 20;
        eligible_bones[0x84fB8110aD6c9fa7fA1d116a7B435895e31066A4] = 4;
        eligible_bones[0x85789EF93518E217598257130d6d9d4279f2776e] = 1;
        eligible_bones[0x8585f48e41594cB1f2D11f6cAb7980106540d9B2] = 1;
        eligible_bones[0x861fa9d749E09f3A9ED5BB5E23d7f41B65523035] = 1;
        eligible_bones[0x86A350a3b9e5e38460A21C9A0B7EC4280caEC6a4] = 2;
        eligible_bones[0x87180EC01780Ef48f9A581EE22eA8651357A464A] = 28;
        eligible_bones[0x885EB3bFe952ef8343D6B3176C1327Ba2c44a163] = 3;
        eligible_bones[0x88a70fC4662a01b809Ea51ca8c9C37843fDeA458] = 2;
        eligible_bones[0x88E3378dfb5463A0d151F802a48A104698e90e3D] = 1;
        eligible_bones[0x8981cC81Ec9d58da52ed779Fb7d8181e03Bc8CE3] = 16;
        eligible_bones[0x8A04cEA099e2D2886aea08E33446B5a52B9cF900] = 1;
        eligible_bones[0x8A23fB5DE0ed4fDF1cfC5841497E369F20597668] = 2;
        eligible_bones[0x8C2365fe0b0A9aa879B4114EB2b9b6565E431153] = 5;
        eligible_bones[0x8c4c4414522bF2daf9D886c4c2ACb4dD47B203f3] = 1;
        eligible_bones[0x8C5264230fD3124e47347cA251a7a32039E7176E] = 1;
        eligible_bones[0x8C63EA42b94678096FCF506a63F795fd760cfb39] = 1;
        eligible_bones[0x8dFf027daADEacC7898851C4e750078aba53b922] = 1;
        eligible_bones[0x8e2A6AfEe2B8d37B672A2827566bcb0c537cC3b1] = 114;
        eligible_bones[0x8F493C12c4F5FF5Fd510549E1e28EA3dD101E850] = 8;
        eligible_bones[0x9023Ef16968FFea318838A223ef2A79bd9f99F88] = 7;
        eligible_bones[0x92198Ef0013A303ef7Eb236ECba0C54c2c5483Eb] = 1;
        eligible_bones[0x928696d73C3B668D54dCa33073A07Ff26270FfE9] = 1;
        eligible_bones[0x92c7BED5bFE4fc397CDE40229f740069B5f38FD0] = 1;
        eligible_bones[0x939DC788a1902cF04788E6cC993fA4eF88400cE0] = 1;
        eligible_bones[0x9417AB659e81411DC3D0385B2dd27fa0a4f38392] = 2;
        eligible_bones[0x957794DCE9F2079f99064bC9Fb09B0edE4F6f690] = 82;
        eligible_bones[0x95EC92Ca95Bc6B8950Be47082AD0CE8C9CfE463e] = 10;
        eligible_bones[0x96f3fe3FB0D0d2BfFb718561549CF7DB3B7D91d2] = 2;
        eligible_bones[0x974d3B3E324999035d4b0e4825EE6a3Dee1A6B9f] = 10;
        eligible_bones[0x979690bD32044dFDE62eAB2eba688466ab955250] = 1;
        eligible_bones[0x9874346057faA8C5638694e1c1959f1d4bb48149] = 4;
        eligible_bones[0x9aE055f84cD047929f45BA364931839A39439957] = 1;
        eligible_bones[0x9b4211e9f022c21e6735c04f4B61b801a7cFE2b6] = 1;
        eligible_bones[0x9B541D86F6108A5351dE01243736B190c59969b9] = 1;
        eligible_bones[0x9C8456D00C3518159EaaA839132aEE399515a617] = 6;
        eligible_bones[0x9Cd9aefBd6D423F69F5c9Caf2fA9972381012b09] = 1;
        eligible_bones[0x9D1A1d3ba33FFc81346f7c608d82073a3e640fa5] = 5;
        eligible_bones[0x9d549154aEF058c1C819356353e4D0a78BE3dAc5] = 7;
        eligible_bones[0x9EB943Ba6234cDB965527470300D8b19Fcb5c4a0] = 3;
        eligible_bones[0x9f814a00565aE9cB2257e378F7cF89a586b8E3F8] = 18;
        eligible_bones[0xa06694f0EC5AB033207C5667ca6e27432f10AC50] = 5;
        eligible_bones[0xa08a7A825dD73D8cE5C7De7A99F0ca15a5DB1Ad3] = 1;
        eligible_bones[0xa144488F244978c92A1AF328134b950cc636aBe9] = 1;
        eligible_bones[0xa1d2aB323EAF3b1F79E4392A307bC8aeE2ffe4A8] = 2;
        eligible_bones[0xA41A4b84D74E085bd463386d55c3b6dDe6aa2759] = 5;
        eligible_bones[0xA44F0658F3412140DB4Ccd39B1F4CAdba1c17dA3] = 1;
        eligible_bones[0xA4A8d44646e2F4C4a74b892303A13c85fb876338] = 1;
        eligible_bones[0xa4cfd7C2B29E2b31c284Bd5e78354853a309B6e8] = 2;
        eligible_bones[0xa51486EA18aAd56a67F8570A9e71AaaEf0749CcA] = 2;
        eligible_bones[0xa54cd35E2E2D0DdFB03C677B981d9361743D82E2] = 2;
        eligible_bones[0xA6BE6842b0f0ae6E8B3C773f5893b91A01871615] = 7;
        eligible_bones[0xa800FAa33d09Da13B8CE1C4bBf1f6F642F5d8F7b] = 3;
        eligible_bones[0xA81d405F7D43373AC13eF85046b0DE017253e70c] = 1;
        eligible_bones[0xa9531D3B5483bef6FaE3B4Be62Ccd83697aB92b1] = 25;
        eligible_bones[0xaa08e0FC844cDb18Cd7176549839B79bAd5e051D] = 1;
        eligible_bones[0xaaa7C182b279edAb7f0f9B97F426E986A54b91B8] = 1;
        eligible_bones[0xAD62DA09a5faC08c802aa97707186C9BE1838700] = 3;
        eligible_bones[0xaEb3FEA566C8bCb7Ae6826A03f818d9d386169BA] = 1;
        eligible_bones[0xAED66AaE345D979Bf6d2d5f9f7a50a30B59fBbaF] = 1;
        eligible_bones[0xaf469C4a0914938e6149CF621c54FB4b1EC0c202] = 1;
        eligible_bones[0xaFE7309fD01a5E6d5a258E911461ecb9558FbFDF] = 103;
        eligible_bones[0xB029D0B856eb75eF623cd3A17Ac25FAe5BD788c9] = 1;
        eligible_bones[0xb2b2B8bE6208acb7D2D145114A9c3DF2230D5491] = 1;
        eligible_bones[0xB518E0F7F6E3C71FA8434116E1a4C63702155265] = 2;
        eligible_bones[0xB82107F361Ce6CEd8efa5BFBF85aa5C886d895a6] = 3;
        eligible_bones[0xB9942A2b7Ab89C1c3A7330C664897d4eA9aE2A88] = 4;
        eligible_bones[0xB9afA4d8cc98BD9e4Bc1B05504588Ecb63fA8B96] = 2;
        eligible_bones[0xB9f4660b106c25B3F4bf219268f39834eA3F9060] = 1;
        eligible_bones[0xba449117818563a65Bc65019138c553eb87F1474] = 2;
        eligible_bones[0xbb9a59009b299c1A0f341579744cBEB223a29703] = 2;
        eligible_bones[0xBc5e0726a49d7eFF356BFbd2B91b24Dd612B0533] = 3;
        eligible_bones[0xBeBb8063c71B9901D6C6C197e3A81dFd9E089d1f] = 3;
        eligible_bones[0xBF17142Cf515089cE4F825F3d05b4983EF7e92C7] = 2;
        eligible_bones[0xBF892063Bd9dD3A28364a68d286a9ef840712D03] = 1;
        eligible_bones[0xc05C4f2bf8c629d6F9F674e6949B6fe54832764E] = 5;
        eligible_bones[0xC08BA0cD0AAC9C1811Eb8Cd790D56A1f0D645BF9] = 5;
        eligible_bones[0xC0a945B099293AFff8E8FeA836920341C7557E23] = 1;
        eligible_bones[0xc1659D856312e211300DeFa7E0E771a93dFc315C] = 1;
        eligible_bones[0xc3A2533988CfbC268c161B92f90Ef8147de924a5] = 3;
        eligible_bones[0xc3D3f90e2210bbE23690E32B80A81745EB4dB807] = 1;
        eligible_bones[0xC457749236328D6E27FC7441cC32f273D6AD05aD] = 3;
        eligible_bones[0xC4B64403e00D1CfDB76E67378aFc6698f59F3D63] = 1;
        eligible_bones[0xc64AaA34Cf9DcE746A4C5dA2A0732CAf86BBDA5d] = 2;
        eligible_bones[0xC6c6823ad6828fc9BB7AB3931e1862d09FE3e7Ba] = 2;
        eligible_bones[0xC6D4E5C1cd5c2142C4592bBf66766e0f5f588d84] = 10;
        eligible_bones[0xc7E82FA77f32BFD6AeeD59924a1a564a924b2EA8] = 15;
        eligible_bones[0xC810cEa2B806Cd0Ff65A79B95b5Fa8A1F5E0e555] = 4;
        eligible_bones[0xC814b1E4cD1e7dDeA4b2d5e97c69089fd5634E2A] = 6;
        eligible_bones[0xcb555d047891faa7EFbFfDcFD8913F851F2e161B] = 2;
        eligible_bones[0xCCa11A8EdB05D64a654092e9551F9122D70EA80e] = 3;
        eligible_bones[0xCcDd7eCA13716F442F01d14DBEDB6C427cb86dFA] = 1;
        eligible_bones[0xCd0D4CDb238Eec15Fcf4ff9d13d5a59051E507D7] = 41;
        eligible_bones[0xcD95Cb0bEe1D1a7871FE0F2d32Fe03EcF3BF31c6] = 1;
        eligible_bones[0xCE37EdfC61141b33d3f82dc14c0639496dd6Bc90] = 3;
        eligible_bones[0xCeb3eCf5D5b116F42C63a60168a9e7734AE3dc34] = 1;
        eligible_bones[0xcEb7C97B39725844aE95c61480812F96004581B9] = 2;
        eligible_bones[0xcf9882330aE4396c5FA96F9B6bF31a61C4982dF3] = 3;
        eligible_bones[0xcFA66E92F4070a6D80cD45F4738aFA5AB6E62519] = 7;
        eligible_bones[0xD05437d15B2c3856B6DfEC5E63CAD35A8E8480FB] = 4;
        eligible_bones[0xD1e88d18a3af098D597A6df71a27B50a229165dC] = 2;
        eligible_bones[0xd2E8530F30Cc43EdE9B0403f2461320D7034Ed8b] = 2;
        eligible_bones[0xD3AF1d8132AF7274A6f5a8EfF6217588F56D617a] = 1;
        eligible_bones[0xD3Fd32e76a1cA37eC408aAc47776b10Fc099F841] = 1;
        eligible_bones[0xD433c1B56055b7aDf8e5e2982E7e2C00C378706a] = 1;
        eligible_bones[0xd47f5b1A1324Aa32Bda3e58A65e5C858CEF74bE3] = 1;
        eligible_bones[0xD5921C35813C4499e6c0749D3aA5D6615e050918] = 1;
        eligible_bones[0xd77a75F5e39eaCb523AbF2A3c97D14939697bF97] = 3;
        eligible_bones[0xd7faE3f2fD4e3294Ec61FD36fA12B4F11B2F54b3] = 1;
        eligible_bones[0xd8b07BC1bC3bAe553BCA5E94E99935dC12Df24Ff] = 1;
        eligible_bones[0xd94E3c6Cae30D5993426594fef07Ead907cBF0e6] = 1;
        eligible_bones[0xD95DBdaB08A9FED2D71ac9C3028AAc40905d8CF3] = 6;
        eligible_bones[0xD9FccC95e992B1A1D11f742144a56dec5F0ef81C] = 2;
        eligible_bones[0xDbD3a4258595Ff6Ede89df9e1032f34348876531] = 7;
        eligible_bones[0xDCaff7c8220d5C151080ac5f6083332eF764DbE0] = 35;
        eligible_bones[0xDD09E835D0Fe15ae40eF009ab26AB4e708636362] = 1;
        eligible_bones[0xdD0c252067E1197ef2C4eC48EA024D705159ED0a] = 1;
        eligible_bones[0xdD112088f343074e4Ce9B4451eb840d8FF04E914] = 1;
        eligible_bones[0xDd92a572bB0A4dC1422b0337301D98826Ad0B0ca] = 1;
        eligible_bones[0xdE07867BBdcBb0ffc65E185686E9f1214aeDdE25] = 1;
        eligible_bones[0xdF460cDD9A9C043447D308D3e22DF30e13D67bd8] = 4;
        eligible_bones[0xE14f7A9AF3F75a4Ccd33909B0046b16d82c6EC0e] = 3;
        eligible_bones[0xE19e7878AF48C2ADf4B1d3F349a11fCa60e20489] = 1;
        eligible_bones[0xE28504E04E490b40F3aEcAc2017317F86e41f3b7] = 7;
        eligible_bones[0xe2A3513936F0C52bBdDD45c2a2CE64675d59028b] = 1;
        eligible_bones[0xE3346fe6e8B2bEFa06a4e14d57651aa0fefFf674] = 8;
        eligible_bones[0xE35B68A44b3e1CdA5C9b7cA497000ED5e532e564] = 5;
        eligible_bones[0xe36740a6d9C66D971c98D4C08412A7703445e389] = 3;
        eligible_bones[0xe4f6509614bAafF74a75A0E779DbA778a3d9c225] = 1;
        eligible_bones[0xE523644625b39a406f4ea844430f6913e9e4Ad66] = 2;
        eligible_bones[0xe6685D866671Aa2F90Bfb611a04cB61B91fEf08C] = 11;
        eligible_bones[0xE6C58f8e459FE570AFfF5b4622990eA1744F0E28] = 9;
        eligible_bones[0xE7D980C7A72E3C79C05C924f89c9B8552072F3F5] = 2;
        eligible_bones[0xe8cc236D8246718e2C5129F2c6Ee263BF8349Ec5] = 3;
        eligible_bones[0xe946A890792C02c749D9e541BF67c3c3b3B0F1c6] = 3;
        eligible_bones[0xE9a0c78E17d3C782C8C4054cebE894FddF3DF515] = 1;
        eligible_bones[0xEa66f33Fb201953316dcB3a96054B664eeD7c04b] = 8;
        eligible_bones[0xEbDb626C95a25f4e304336b1adcAd0521a1Bdca1] = 10;
        eligible_bones[0xeC62a2EA480DC2eE661FEFCE3b1695EB603Fe398] = 1;
        eligible_bones[0xEe31c15C243a8B71b3848403fE229ab1Ed9363fd] = 1;
        eligible_bones[0xeF984Be913C22645Bdd7Dc1388b3D2B9C5744092] = 53;
        eligible_bones[0xEfD387fC2c15BA81AD6D7038AE914eEcc0F01582] = 1;
        eligible_bones[0xF00dae12C50c5D18389175157F51a4FD8735AEB1] = 1;
        eligible_bones[0xf04928eC019E13753aca32e2Ea2b39238DaDcAbA] = 6;
        eligible_bones[0xf0Bc457431517302d3FEF20B3d3aDe57B4441790] = 3;
        eligible_bones[0xF131640b01FD2d2C7c8cD7b33ed2Ff88297A7fD5] = 1;
        eligible_bones[0xF2dC63FaA6a204c23b9955531b8200f674EfF364] = 2;
        eligible_bones[0xF406bbE6D08F842154B7bAD648C72d07D74538E0] = 1;
        eligible_bones[0xf5262e0E634c6E1644FC96D44d88242B76B4277C] = 4;
        eligible_bones[0xf57bAa3eF4097D31242A1A6b26895f5259d03c78] = 1;
        eligible_bones[0xf6314bA91A86a7f02AbaAB53622328c2A2A2e3De] = 2;
        eligible_bones[0xF64802215563e8d324000A259363f84e970400e7] = 13;
        eligible_bones[0xF8ae11175cA54ff0A2b42DcdC6702498F3Cf0466] = 6;
        eligible_bones[0xF8F2aAED08320e4dcdd1Be7cc164793f1B5de780] = 1;
        eligible_bones[0xf91B00784DB6B28dEE6cF472512666741853Cd7D] = 1;
        eligible_bones[0xFA4b5be3F99EAfEEf5d7971eFF26aeAAf4293520] = 1;
        eligible_bones[0xFaD5447Dc0B7A85735963924bAce9B6510Baa55d] = 5;
        eligible_bones[0xfbF200bE24835E7B8A5aF5f48e788804b4ef0Cbd] = 1;
        eligible_bones[0xFc4EB75c701D9433BaadcdbAdb29Dee1B7658515] = 1;
        eligible_bones[0xFDa615e27310eB8B3e9df2A8bf0914E5c0A3e0ed] = 1;
        eligible_bones[0xFE369225C3613DdeFEa0f9776Ac3CE35054F034f] = 1;
        eligible_bones[0xFe4aDbc3EAc06C94933bC984696FB1aB2D2Ddebc] = 3;
        eligible_bones[0xFEcaa66f413b46c86C0fDF0fB139A81Df5cd3916] = 7;
        eligible_bones[0xfFCc9e99AB4674380ff0647B9eC23111C68721b0] = 1;
        eligible_bones[0xFfddCfE5B629d77F315ABC2521407C2c55aDA6C1] = 2;
    }
    
    address addressPartyBones;
    bool redemption_time = true;
    bool sale_time = true;
    uint internal ticket_price = 15000000000000000; // 0.015 ETH
    mapping(address => bool) public authorised_contracts;
    
    // Modifier to only alow merging contracts to interact with this function
    modifier onlyAuthorised()
    {
        require(authorised_contracts[msg.sender]);
        _;
    }
    
    modifier SaleOpen()
    {
        require(sale_time == true);
        _;
    }
    
    modifier RedemptionOpen()
    {
        require(redemption_time == true);
        _;
    }
    
    function open_redemption() onlyOwner public
    {
        redemption_time = true;
    }
    
    function close_redemption() onlyOwner public
    {
        redemption_time = false;
    }
    
    function open_sale() onlyOwner public
    {
        sale_time = true;
    }
    
    function close_sale() onlyOwner public
    {
        sale_time = false;
    }
    
    function edit_eligible(address address_, uint256 new_eligible_count) onlyOwner public
    {
        eligible_bones[address_] = new_eligible_count;
    }
    
    // Contracts for Party Bone Merging authorised and removed here
    function addAuthorisedAddress(address _address) public onlyOwner {
        authorised_contracts[_address] = true;
    }
    
    function removeAuthorisedAddress(address _address) public onlyOwner {
        authorised_contracts[_address] = false;
    }
    
    // pause minting and merging
    function pause() public onlyOwner {
        _pause();
    }
    
    // unpause minting and merging 
    function unpause() public onlyOwner {
        _unpause();
    }

    function setaddressPartyBones(address address_) onlyOwner public
    {
        addressPartyBones = address_;
    }
    
    function transferOwnershipPartyBones(address address_) onlyOwner public
    {
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.transferOwnership(address_);
    }

    // Modify sale price
    function change_ticket_price(uint new_price) public onlyOwner returns(uint)
    {
        ticket_price = new_price;
        return(new_price);
    }
    
    function claimBones(uint256 claim_count) RedemptionOpen public
    {   
        PartyBones partyBones = PartyBones(addressPartyBones);
        require( claim_count <= eligible_bones[msg.sender]);
        require( claim_count <= 10 );
       
        partyBones.mint_primary_admin(msg.sender, claim_count * 3);
        eligible_bones[msg.sender] -= claim_count;
    }

    // mint your Party Bone!
    function createBone(uint256 numberOfTokens) public payable SaleOpen
    {   
        PartyBones partyBones = PartyBones(addressPartyBones);
        require(numberOfTokens < 21, "No more than 20 Tokens at one time!");
        require(ticket_price * numberOfTokens <= msg.value, "Please send correct amount");
        require(msg.sender == tx.origin, "Can only mint through a wallet");
        partyBones.mint_primary_admin(msg.sender, numberOfTokens);
    }
    
    // admin minting
    function createBone_primary_admin(address address_, uint256 numberOfTokens) public onlyOwner
    {   
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.mint_primary_admin(address_, numberOfTokens);
    }
    
    // merging burn
    function burn_for_limb(uint256 tokenid)
        public
        whenNotPaused
        onlyAuthorised
        returns (uint256)
    {
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.burn_admin(tokenid);
        return tokenid;
    }
    
    // burn_admin
    function burn_admin(uint256 tokenid)
        public
        onlyOwner
        returns (uint256)
    {
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.burn_admin(tokenid);
        return tokenid;
    }
    
    function createBone_admin(address address_, uint256[] memory tokenIds) public onlyOwner
    {   
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.mint_admin(address_, tokenIds);
    }
    
    function change_base_URI(string memory new_base_URI)
        onlyOwner
        public
    {
        PartyBones partyBones = PartyBones(addressPartyBones);
        partyBones.change_base_URI(new_base_URI);
    }
    
    // only owner - withdraw contract balance to wallet
    function withdraw()
        public
        payable
        onlyOwner
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    
}