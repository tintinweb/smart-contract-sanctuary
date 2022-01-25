/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/harvest.sol


pragma solidity >=0.4.16 <0.9.0;



struct Harvest {
  /**
    @title This struct holds the information of a harvest NFT
    @dev
    - type: harvest type
    - harvestedAt: when the product was harvested
    TODO: define correct harvest attributes
  */
  uint256 engine;
  uint64 builtAt;
  uint64 brokenUntil;
  uint64 goodThrough;
  uint8 level;
}

contract DWHarvest is ERC721 {
  constructor() ERC721("Darling Waifu Harvest", "DWHarvest") {
  }

  function mint() public {
    
  }

  
  function balanceOf(address _owner) public view override returns (uint256){
    return 0;
  }

  function ownerOf(uint256 _farmerId) public view override returns (address){
    return address(0);
  }
  
  function _transfer(address _from, address _to, uint _farmerId) internal override {

  } 


  // function approve(address _approved, uint256 _farmerId) external payable {
    
  // }
}
// File: contracts/support/safemath.sol

pragma solidity >=0.4.16 <0.9.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/tractor.sol


pragma solidity >=0.4.16 <0.9.0;




contract Tractor is ERC721 {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    struct TractorStruct {
        /**
      @title This struct holds the information of a tractor NFT
      @dev
      - builtAt: when the tractor was minted
      - brokenUntil: time when the tractor stops being broken and can function again
      - goodThrough: time when the tractor stops being able to function properly and becomes art
      - level: the level of the tractor determines its capacity for carrying waifus
    */
        uint256 id;
        uint256 sellPrice;
        uint64 builtAt;
        uint64 brokenUntil;
        uint64 goodThrough;
        uint8 level;
        bool forSale;
    }

    TractorStruct[] public tractors;
    address private game = address(0);
    address internal owner = msg.sender;
    address private support;
    address private oracle;

    mapping(uint256 => address) public tractorToOwner;
    mapping(address => uint256) ownerTractorCount;
    mapping(address => uint256[]) private ownerToTractors;
    mapping(uint256 => uint256) private tractorAtOwnerIndex;
    uint256[] private forSale;
    uint256 public tractorTypeQuantity = 5;
    uint256 public tractorCount = 0;

    modifier onlySupport() {
        require(msg.sender == support, "You are not the support address.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner address.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the oracle.");
        _;
    }

    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    function setGame(address _game) external onlySupport {
        game = _game;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    constructor() ERC721("Darling Wwaifu Tractor", "DWTractor") {}

    function totalSupply() external view returns (uint256) {
        return tractorCount;
    }

    function mint(
        address _newOwner,
        uint256 _durability,
        uint8 _level
    ) external onlyOracle {
        uint64 _builtAt = uint64(block.timestamp);
        uint64 _brokenUntil = uint64(block.timestamp);
        uint64 _goodThrough = uint64(block.timestamp + _durability * 1 days);

        tractors.push(
            TractorStruct(
                tractorCount,
                0,
                _builtAt,
                _brokenUntil,
                _goodThrough,
                _level,
                false
            )
        );
        _transfer(address(0), _newOwner, tractorCount);
        tractorCount = tractorCount.add(1);
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return ownerTractorCount[_owner];
    }

    function ownerOf(uint256 _tractorId)
        public
        view
        override
        returns (address)
    {
        return tractorToOwner[_tractorId];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _tractorId
    ) internal override {
        if (_from != address(0)) {
            require(tractorToOwner[_tractorId] == _from);
            ownerTractorCount[_from] = ownerTractorCount[_from].sub(1);
            ownerToTractors[_from][tractorAtOwnerIndex[_tractorId]] = 10**18;
        }

        tractorToOwner[_tractorId] = _to;
        ownerTractorCount[_to] = ownerTractorCount[_to].add(1);
        ownerToTractors[_to].push(_tractorId);
        tractorAtOwnerIndex[_tractorId] = ownerToTractors[_to].length.sub(1);
        emit Transfer(_from, _to, _tractorId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tractorId
    ) public override {
        require(_from == msg.sender || msg.sender == game);
        if (msg.sender == game) {
            tractors[_tractorId].forSale = false;
        }
        _transfer(_from, _to, _tractorId);
    }

    function sellPrice(uint256 _tractorId) external view returns (uint256) {
        return tractors[_tractorId].sellPrice;
    }

    function sell(uint256 _tractorId, uint256 _sellPrice) external {
        require(
            msg.sender == tractorToOwner[_tractorId],
            "You are not the owner of such tractor."
        );
        tractors[_tractorId].forSale = true;
        tractors[_tractorId].sellPrice = _sellPrice;
        forSale.push(_tractorId);
    }

    function list(uint256 _offset) external view returns (uint256[24] memory) {
        // Max 24 items
        uint256[24] memory _forSale;
        uint256 invalidId = 10**18;
        uint256 _quantity = 0;
        for (
            uint256 i = _offset;
            i < forSale.length && _forSale.length < 24;
            i++
        ) {
            if (forSale[i] != invalidId) {
                _forSale[_quantity] = forSale[i];
                _quantity++;
            }
        }
        return _forSale;
    }

    function getSpace(uint256 _tractorId) external view returns (uint256) {
        return tractors[_tractorId].level;
    }

    function getTTL(uint256 _tractorId) external view returns (uint256) {
        return tractors[_tractorId].goodThrough;
    }

    function getBrokenUntil(uint256 _tractorId)
        external
        view
        returns (uint256)
    {
        return tractors[_tractorId].brokenUntil;
    }

    function getTractorsOf(address _owner)
        external
        view
        returns (TractorStruct[] memory)
    {
        TractorStruct[] memory _tractors;
        for (uint256 i = 0; i < ownerTractorCount[_owner]; i++) {
            _tractors[i] = tractors[ownerToTractors[_owner][i]];
        }
        return _tractors;
    }

    function getTractorIdsOf(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerToTractors[_owner];
    }

    function getTractor(uint256 _tractorId)
        external
        view
        returns (TractorStruct memory)
    {
        return tractors[_tractorId];
    }
}
// File: contracts/farmer.sol


pragma solidity >=0.4.16 <0.9.0;




contract FarmerWaifu is ERC721 {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    struct Farmer {
        /**
    @dev
    - dna: almost unique combination of traits for the waifu
    - birthday: when the farmer was minted
    - immunityUntil: time when the waifu stops being immune to desease
    - sickUntil: time when the waifu stops being sick and can work again
    - aliveUntil: time when the waifu stops being able to farm and becomes art
    - level: the level of the waifu determines its WP (waifu power)
  */
        uint256 id;
        uint256 dna;
        uint256 sellPrice;
        uint64 birthday;
        uint64 immunityUntil;
        uint64 sickUntil;
        uint64 aliveUntil;
        uint8 waifuPower;
        bool forSale;
    }

    Farmer[] public farmers;
    uint256[] public forSale;

    address private game;
    address internal owner = msg.sender;
    address private support;
    address private oracle;
    mapping(uint256 => address) private farmerToOwner;
    mapping(address => uint256) private ownerFarmerCount;
    mapping(address => uint256[]) private ownerToFarmers;
    mapping(uint256 => uint256) private farmerAtOwnerIndex;
    uint256 public farmerTypeQuantity = 5;
    uint256 public farmerCount = 0;

    constructor() ERC721("Darling Wwaifu farmer", "DWfarmer") {}

    modifier onlySupport() {
        require(msg.sender == support, "You are not the support address.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner address.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the oracle.");
        _;
    }

    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function setGame(address _game) external onlySupport {
        game = _game;
    }

    function mint(
        address _newOwner,
        uint256 _dna,
        uint256 _durability,
        uint8 _waifuPower
    ) external onlyOracle {
        uint64 _birthday = uint64(block.timestamp);
        uint64 _inmunity = uint64(block.timestamp);
        uint64 _sick = uint64(block.timestamp);
        uint64 _alive = uint64(block.timestamp + _durability * 1 days);

        farmers.push(
            Farmer(
                farmerCount,
                _dna,
                0,
                _birthday,
                _inmunity,
                _sick,
                _alive,
                _waifuPower,
                false
            )
        );

        _transfer(address(0), _newOwner, farmerCount);
        farmerCount = farmerCount.add(1);
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return ownerFarmerCount[_owner];
    }

    function ownerOf(uint256 _farmerId) public view override returns (address) {
        return farmerToOwner[_farmerId];
    }

    function totalSupply() external view returns (uint256) {
        return farmerCount;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _farmerId
    ) internal override {
        if (_from != address(0)) {
            require(farmerToOwner[_farmerId] == _from);
            ownerFarmerCount[_from] = ownerFarmerCount[_from].sub(1);
            ownerToFarmers[_from][farmerAtOwnerIndex[_farmerId]] = 10**18;
        }
        farmerToOwner[_farmerId] = _to;
        ownerFarmerCount[_to] = ownerFarmerCount[_to].add(1);
        ownerToFarmers[_to].push(_farmerId);
        farmerAtOwnerIndex[_farmerId] = ownerToFarmers[_to].length.sub(1);
        emit Transfer(_from, _to, _farmerId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _farmerId
    ) public override {
        require(_from == msg.sender || msg.sender == game);
        if (msg.sender == game) {
            farmers[_farmerId].forSale = false;
        }
        _transfer(_from, _to, _farmerId);
    }

    function sell(uint256 _farmerId, uint256 _sellPrice) external {
        require(
            msg.sender == farmerToOwner[_farmerId],
            "You are not the owner of such farmer."
        );
        farmers[_farmerId].forSale = true;
        farmers[_farmerId].sellPrice = _sellPrice;
        forSale.push(_farmerId);
    }

    function sellPrice(uint256 _farmerId) external view returns (uint256) {
        require(farmers[_farmerId].forSale, "Farmer waifu not for sale.");
        return farmers[_farmerId].sellPrice;
    }

    function list(uint256 _offset) external view returns (uint256[24] memory) {
        // Max 24 items
        uint256[24] memory _forSale;
        uint256 invalidId = 10**18;
        uint256 _quantity = 0;
        for (
            uint256 i = _offset;
            i < forSale.length && _forSale.length < 24;
            i++
        ) {
            if (forSale[i] != invalidId) {
                _forSale[_quantity] = forSale[i];
                _quantity++;
            }
        }
        return _forSale;
    }

    function getDNA(uint256 _farmerId) external view returns (uint256) {
        return farmers[_farmerId].dna;
    }

    function getTTL(uint256 _farmerId) external view returns (uint256) {
        return farmers[_farmerId].aliveUntil;
    }

    function getSickness(uint256 _farmerId) external view returns (uint256) {
        return farmers[_farmerId].sickUntil;
    }

    function getWP(uint256 _farmerId) external view returns (uint256) {
        return farmers[_farmerId].waifuPower;
    }

    function getFarmersOf(address _owner)
        external
        view
        returns (Farmer[] memory)
    {
        Farmer[] memory _farmers;
        for (uint256 i = 0; i < ownerFarmerCount[_owner]; i++) {
            _farmers[i] = farmers[ownerToFarmers[_owner][i]];
        }
        return _farmers;
    }

    function getFarmerIdsOf(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        return ownerToFarmers[_owner];
    }

    function getFarmer(uint256 _farmerId)
        external
        view
        returns (Farmer memory)
    {
        return farmers[_farmerId];
    }
}
// File: contracts/PeachStorage.sol


pragma solidity >=0.4.16 <0.9.0;


contract PeachStorage {
    using SafeMath for uint256;
    mapping(address => uint256) private balances;
    mapping(address => uint256) private locked;
    mapping(address => uint256) private claimed;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => mapping(uint256 => uint256)) expenditures;

    /**
      Liquidity pools go here
    */
    address internal manager;
    address internal owner = msg.sender;
    address internal support;
    address internal oracle;
    address rewardsPool = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    string _name = "DW Teach Storage";
    string _symbol = "TSTR";
    uint8 _decimals = 18;
    uint256 _totalSupply = 5000000 * 10**_decimals;
    uint256 TGE;
    uint256 internal currentPrice; // 3 decimals

    modifier onlyManager() {
        require(msg.sender == manager, "You are not the manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlySupport() {
        require(msg.sender == support, "You are not the owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the owner");
        _;
    }

    constructor() {
        balances[owner] = _totalSupply / 100;
        TGE = block.timestamp;
    }

    // Token information functions
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function upgradePeach(address _newPeach) external onlySupport {
        manager = _newPeach;
    }
    
    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    function setOracle(address _oracle) external onlySupport {
        oracle = _oracle;
    }

    function setCurrentPrice(uint256 _newPrice) external onlyOracle {
        currentPrice = _newPrice;
    }

    function getCurrentPrice() external view returns(uint256) {
        return currentPrice;
    }

    function getPeach() external view returns (address) {
        return manager;
    }

    function balanceOf(address _wallet) external view returns (uint256) {
        return balances[_wallet];
    }

    // ERC20 proxied functions and events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address _owner, address _spender, uint256 _value);

    function transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function transferFrom(
        address _from,
        address _spender,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) external onlyManager {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            allowances[_from][_spender] >= _amount,
            "Allowance is lower tan requested funds"
        );
        allowances[_from][_spender] = allowances[_from][_spender].sub(_amount);
        _transfer(_from, _to, _amount, _comission);
        emit Transfer(_from, _to, _amount.sub(_comission));
        emit Transfer(_from, rewardsPool, _comission);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _comission
    ) internal {
        require(balances[_from] >= _amount, "Not enough funds");
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount.sub(_comission));
        balances[rewardsPool] = balances[rewardsPool].add(_comission);
        uint256 thisHour = (block.timestamp - TGE) / 3600;
        expenditures[_from][thisHour] = expenditures[
            _from
        ][thisHour].add(_amount.mul(currentPrice));
    }

    function getExpenditure(address _target, uint256 _hours)
        external
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256 thisHour = (block.timestamp - TGE) / 3600;
        uint256 minHours = thisHour >= _hours ? thisHour - _hours + 1: 0;
        for (
            uint256 i = thisHour + 1; // We get hours this way
            i > minHours;
            i--
        ) {
            result = result.add(expenditures[_target][i - 1]);
        }
        return result;
    }

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) external onlyManager returns (bool) {
        _approve(_owner, _spender, _amount);
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        allowances[_owner][_spender] = _amount;
    }
}

// File: contracts/Peach.sol


pragma solidity >=0.4.16 <0.9.0;



contract PeachMathematician {
    using SafeMath for uint256;

    /**
    @dev
    - This contract holds the logic for mathematical calculations not built into Solidity
    - **Random number calculations shall not be done here**.
    */
    event Print(string msg);

    function getBigCommission(uint256 x) internal pure returns (uint256) {
        // Returns a percentage
        return 60 - (550000 * 10**21) / (x + 10000 * 10**21);
    }
}

contract ProxiedStorage is PeachMathematician {
    // Token parameters
    string _name = "DW Teach";
    string _symbol = "TEACH";
    uint8 _decimals = 18;

    address internal owner = msg.sender;
    address internal game = address(0);
    address internal peachStorageAddress =
        0x1Faf80b0812e01692308Fc416E408e2460ED9AdE;
    address internal rewardsPoolv2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address internal proxy;
    address internal support;
    address internal oracle;
    uint256 internal maxCashout = 100 * 10**_decimals;
    uint256 internal liquidityExtractionLimit; // 21 decimals
    uint256 internal fixedCommission = 5;
    mapping(address => bool) internal authorizedTransactors;
    mapping(address => bool) internal swaps;
    mapping(address => bool) internal banList;
    PeachStorage peachStorage = PeachStorage(peachStorage);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address _owner, address _spender, uint256 _value);

    // Get the balance of any wallet
    function balanceOf(address _target) external view returns (uint256) {
        return peachStorage.balanceOf(_target);
    }

    function _balanceOf(address _target) internal view returns (uint256) {
        return peachStorage.balanceOf(_target);
    }

    // Get the allowance of a wallet
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256)
    {
        return peachStorage.allowance(_owner, _spender);
    }

    // Approve the allowance for a wallet
    function approve(address _spender, uint256 _amount)
        external
        returns (bool)
    {
        bool success = peachStorage.approve(msg.sender, _spender, _amount);
        require(success, "Approval not successful.");
        emit Approval(msg.sender, _spender, _amount);
        return success;
    }

    // Proxy the current price
    function getCurrentPrice() external view returns (uint256) {
        return peachStorage.getCurrentPrice();
    }

    // Transfer from a wallet A to a wallet B
    function _safeTransferFrom(
        address _from,
        address _spender,
        address _to,
        uint256 _amount
    ) internal {
        uint256 _commission = _getCommission(_from, _to, _amount);
        peachStorage.transferFrom(_from, _spender, _to, _amount, _commission);
        emit Transfer(_from, _to, _amount - _commission);
        if (_commission != 0) emit Transfer(_from, rewardsPoolv2, _commission);
    }

    function _getTransactionLimit(address _target)
        internal
        view
        returns (uint256)
    {
        uint256 _balance = _balanceOf(_target);
        // This is a percentage
        uint256 limit = (3000 * 10**(_decimals + 3)) /
            (_balance *
                peachStorage.getCurrentPrice() +
                120 *
                10**(_decimals + 3));
        return (limit * _balance) / 100;
    }

    function getTransactionLimit() external view returns (uint256) {
        return _getTransactionLimit(msg.sender);
    }

    function _getCommission(
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _commission = fixedCommission;
        if (swaps[_from] || _from == game) {
            // User is purchasing tokens
            _commission = 0;
        } else if (swaps[_to]) {
            uint256 _expenditure = peachStorage.getExpenditure(_from, 24);
            uint256 _value = _amount * peachStorage.getCurrentPrice();
            uint256 _expense = _expenditure + _value;
            require(
                _expense <= liquidityExtractionLimit,
                "24h window liquidity extraction limit reached."
            );
            // User is selling tokens
            if (_value > maxCashout) {
                _commission = getBigCommission(_value);
            }
        }
        return ((_commission * _amount) / 100);
    }
}

contract Decorated is ProxiedStorage {
    modifier validSender(address from) {
        require(from == msg.sender, "Not the right sender");
        _;
    }

    modifier isntBroken(uint256 quantity, uint256 balance) {
        require(quantity <= balance, "Not enough funds");
        _;
    }

    modifier onlyProxy() {
        require(msg.sender == proxy, "You are not the proxy.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    modifier onlySupport() {
        require(msg.sender == support, "You are not the support.");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracle, "You are not the oracle.");
        _;
    }

    modifier isAllowedTransaction(
        address destination,
        uint256 amount,
        uint256 balance
    ) {
        bool limitCondition = amount * peachStorage.getCurrentPrice() <=
            _getTransactionLimit(msg.sender);
        require(
            authorizedTransactors[msg.sender] ||
                swaps[msg.sender] ||
                !swaps[destination] ||
                limitCondition,
            "This transaction exceeds your limit. You need to authorize it first."
        );
        emit Print("The transaction is within limits.");
        require(
            !banList[msg.sender],
            "You are banned. You may get in touch with the development team to address the issue."
        );
        emit Print("You are not banned, OK.");
        _;
    }
}

contract Peach is PeachMathematician, Decorated {
    address liquidityPool;
    address bnbLiquidityPool;

    constructor() {}

    // Set the support address. Maintainance tasks only
    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    // Set the oracle address. Financial tasks only
    function setOracle(address _oracle) external onlySupport {
        oracle = _oracle;
    }

    // Upgrade Peach balances. Try not to migrate balances, it could be expensive.
    function upgradeStorage(address _newStorage) external onlySupport {
        peachStorageAddress = _newStorage;
        peachStorage = PeachStorage(peachStorageAddress);
    }

    // Upgrade base commission
    function updateCommission(uint256 _commission) external onlySupport {
        fixedCommission = _commission;
    }

    // Ban a wallet
    function ban(address _target) external onlySupport {
        banList[_target] = true;
    }

    // Unban a wallet
    function unban(address _target) external onlySupport {
        banList[_target] = false;
    }

    // Token information functions for Metamask detection
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return peachStorage.totalSupply();
    }

    // Add a lp address to avoid commissions in outgoing transfers
    function addSwap(address _swap) external onlySupport {
        swaps[_swap] = true;
    }

    function setLiquidityExtractionLimit(uint256 _newLimit)
        external
        onlyOracle
    {
        liquidityExtractionLimit = _newLimit;
    }

    //////////////////////////////////
    /////////// Actual ERC20 functions
    //////////////////////////////////
    // Custom transfer with liquidity protection
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal validSender(_from) {
        emit Print("isValidSender");
        uint256 _commission = _getCommission(_from, _to, _amount);
        emit Print("isValidCommission");
        peachStorage.transfer(_from, _to, _amount, _commission);
        emit Print("Successful transfer");
        emit Transfer(_from, _to, _amount - _commission);
        if (_commission != 0) emit Transfer(_from, rewardsPoolv2, _commission);
    }

    // Transfer
    function transfer(address _to, uint256 _amount)
        public
        isAllowedTransaction(_to, _amount, _balanceOf(msg.sender))
    {
        _safeTransfer(msg.sender, _to, _amount);
        authorizedTransactors[msg.sender] = false;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public isAllowedTransaction(_to, _amount, _balanceOf(_from)) {
        _safeTransferFrom(_from, msg.sender, _to, _amount);
        authorizedTransactors[msg.sender] = false;
    }

    // Approve big liquidity extraction
    function approveTransactor() external {
        authorizedTransactors[msg.sender] = true;
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }
}
// File: contracts/DWGame.sol


pragma solidity >=0.4.16 <0.9.0;






contract DWGame {
    using SafeMath for uint256;
    address payable private refillPool = payable(address(0));
    address payable private rewardPool = payable(address(0));
    address payable private bella = payable(address(0));
    address private peachAddress = address(0);
    address private farmerAddress = address(0);
    address private tractorAddress = address(0);
    address private harvestAddress = address(0);
    address private owner = msg.sender;
    address private support;
    Peach private peach = Peach(peachAddress);
    FarmerWaifu private farmer = FarmerWaifu(farmerAddress);
    Tractor private tractor = Tractor(tractorAddress);
    DWHarvest private harvest = DWHarvest(harvestAddress);
    mapping(uint256 => uint256) mintPrices;
    mapping(uint256 => uint256) harvestPrices;
    uint256 private decimalMultiplier = 10**21;
    uint256 private mintUnitGas = 4 * 10**15 wei;
    uint256 private harvestGas = 4 * 10**9;
    uint256 private marketplaceGas = 2 * 10**9;
    uint256 private rewardComission = 5;

    event MintRequest(address _wallet, uint256 _quantity, uint256 _type);
    event HarvestRequest(address _wallet, uint256 _field);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner address.");
        _;
    }

    modifier onlySupport() {
        require(msg.sender == support, "You are not the support address.");
        _;
    }

    function setSupport(address _support) external onlyOwner {
        support = _support;
    }

    function setTractorAddress(address _tractorAddress) external onlySupport {
        tractor = Tractor(_tractorAddress);
    }

    function setFarmerAddress(address _farmerAddress) external onlySupport {
        farmer = FarmerWaifu(_farmerAddress);
    }

    function setBellaAddress(address _bella) external onlySupport {
        bella = payable(_bella);
    }

    function addMintPrice(uint256 _type, uint256 _price) external onlySupport {
        // The mapping shall have prices for different minting units:
        // Farmer waifu: 0 => 20
        // Tractor: 1 => 30
        // And so on...
        mintPrices[_type] = _price;
    }

    function addHarvestPrice(uint256 _type, uint256 _price)
        external
        onlySupport
    {
        // The mapping shall have prices for different harvesting fields:
        // Field 1: 0 => 20
        // Field 2: 1 => 30
        // And so on...
        harvestPrices[_type] = _price;
    }

    function mint(uint256 _quantity, uint256 _type) external payable {
        // Use the gas fee provided
        uint256 _gas = mintUnitGas.mul(_quantity);
        require(msg.value >= _gas, "Not enough BNB sent for minting.");
        uint256 _rewardGas = _gas.mul(rewardComission).div(100);
        uint256 _mintGas = _gas.sub(_rewardGas);
        (bool sent, bytes memory data) = rewardPool.call{value: _rewardGas}("");
        require(
            sent,
            "Failed to send BNB to Reward Pool, please contact the administrator."
        );
        (sent, data) = bella.call{value: _mintGas}("");
        require(
            sent,
            "Failed to send BNB to Bella Peach, please contact the administrator."
        );
        // Make the PEACH transaction
        peach.transferFrom(
            msg.sender,
            refillPool,
            mintPrices[_type].mul(decimalMultiplier.div(
                peach.getCurrentPrice()
            ))
        );
        // Inform the oracle about the mint request
        emit MintRequest(msg.sender, _quantity, _type);
    }

    function goHarvest(uint256 _field) external payable {
        // Use the gas fee provided
        require(msg.value < harvestGas, "Not enough BNB sent for harvesting.");
        uint256 _rewardGas = msg.value.mul(rewardComission).div(100);
        uint256 _harvestGas = msg.value.sub(_rewardGas);
        (bool sent, bytes memory data) = rewardPool.call{value: _rewardGas}("");
        require(
            sent,
            "Failed to send BNB to Reward Pool, please contact the administrator."
        );
        (sent, data) = bella.call{value: _harvestGas}("");
        require(
            sent,
            "Failed to send BNB to Bella Peach, please contact the administrator."
        );
        emit HarvestRequest(msg.sender, _field);
    }

    function buyFarmer(uint256 _farmerId) external payable {
        // Use the gas fee provided
        require(
            msg.value < marketplaceGas,
            "Not enough BNB sent for the marketplace transaction."
        );
        (bool sent, bytes memory data) = rewardPool.call{value: msg.value}("");
        require(
            sent,
            "Failed to send BNB to Reward Pool, please contact the administrator."
        );

        // Make the PEACH transaction
        address _farmerOwner = farmer.ownerOf(_farmerId);
        uint256 _farmerPrice = farmer.sellPrice(_farmerId);
        uint256 _comission = _farmerPrice.mul(rewardComission).div(100);
        peach.transferFrom(msg.sender, address(this), _farmerPrice);
        peach.transfer(refillPool, _comission);
        peach.transfer(_farmerOwner, _farmerPrice.sub(_comission));
        // Make the purchase
        farmer.transferFrom(_farmerOwner, msg.sender, _farmerId);
    }

    function buyTractor(uint256 _tractorId) external payable {
        // Use the gas fee provided
        require(
            msg.value < marketplaceGas,
            "Not enough BNB sent for the marketplace transaction."
        );
        (bool sent, bytes memory data) = rewardPool.call{value: msg.value}("");
        require(
            sent,
            "Failed to send BNB to Reward Pool, please contact the administrator."
        );

        // Make the PEACH transaction
        address _tractorOwner = tractor.ownerOf(_tractorId);
        uint256 _tractorPrice = tractor.sellPrice(_tractorId);
        uint256 _comission = _tractorPrice.mul(rewardComission).div(100);
        peach.transferFrom(msg.sender, address(this), _tractorPrice);
        peach.transfer(refillPool, _comission);
        peach.transfer(_tractorOwner, _tractorPrice.sub(_comission));
        // Make the purchase
        tractor.transferFrom(_tractorOwner, msg.sender, _tractorId);
    }

    function sellHarvestToOracle(uint256 _harvestId) external {
        // TODO: Set price here
        uint256 _price = 0;
        peach.transfer(msg.sender, _price);
        harvest.transferFrom(msg.sender, address(0), _harvestId);
    }

    function setRewardPool(address _rewardPool) external onlySupport {
        rewardPool = payable(_rewardPool);
    }

    function setRefillPool(address _refillPool) external onlySupport {
        refillPool = payable(_refillPool);
    }

    function setPeachAddress(address _peachAddress) external onlySupport {
        peach = Peach(_peachAddress);
    }
}