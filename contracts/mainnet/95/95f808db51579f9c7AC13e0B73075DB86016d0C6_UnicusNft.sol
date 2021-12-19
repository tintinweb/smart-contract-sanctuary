/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
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

// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)





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

// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)



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

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)



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


/**
 * @dev Smart contract for NFT generation in Unicus Platform
 * Internally uses the Auction smart contract to create Auctions, place bids
 * and End Auctions
 * Creates NFTs when Auction Ends and transfers it to the Winning Bidder
 * Mapping of NFT token Ids and Ipfs Hashes are maintained.
 */




// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)




// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)





// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)



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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)





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


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)



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




// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)





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


// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)





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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)





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


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Smart contract to create Auctions, place bids and End Auctions
 * in Unicus Nft Platform
 *
 */



contract Auction  {


    // Owner of the Auction. 
    address private _owner;
    // Ipfs hash of asset metadata uploaded onto ipfs
    string  private _assetHash;
    // Auction start time
    uint256 private _startTime;
    // Base Price set for the Auction
    uint256 private _basePrice;
    // Total amount collected for the Auction
    uint256 private _totalAmount;
 
    // Is the Auction cancelled
    bool private _canceled;
    // Is the Auction finished
    bool private _finished;
    // Keep track of address of the bidder who placed the highest bid
    address private _highestBidder;
    // Array of the the bidders who placed bids in this Auction
    address[] private _bidders;
    // Mapping from bidder address to the price of the bid placed
    mapping(address => uint256) private _bidderBidPriceMappings;

    // ERC20 token that is accepted for the auction
    IERC20 private _token;

    /**
     * @dev Starts the Auction by  setting an `owner` ,`basePrice` ,`Ipfs asset hash` and a `Start time` .
     * 
     */
    constructor(address owner_,uint256 basePrice_, string memory assetHash_,IERC20 token_)   {
        require(basePrice_ > 0 , "Base price should be greater than 0" );
        _owner = owner_;
        _assetHash = assetHash_;
        _basePrice = basePrice_;
        _startTime = block.timestamp;
        _token = token_;
    }

    /**
     * @dev Places a bid on the Auction associated with the Ipfs hash. Bid price will be transfered to the Wallet 
     * of the smart contract
     * Calling conditions:
     *
     * - Any user in Unicus platform can place a bid during duration of the Auction.
     * - The Owner of the Auction cannot place a bid
     * - The bid amount should be greater than the base price set for the Auction
     *
     * @param bidder_ Address of the bidder placing the bid
     * @param bidPrice_ Price of the bid  
     * @return true if the bid is accepted and the bid price is received in address of the smart contract
     *
     * Emits a {BidPlaced} event.
     */
    function placeBid(address bidder_, uint256 bidPrice_) public 
        onlyAfterStart
        onlyNotCanceled
        returns (bool )
    {
        uint256 newBid = _bidderBidPriceMappings[bidder_] + bidPrice_;
        uint256 _highestBid = _bidderBidPriceMappings[_highestBidder];
        _bidderBidPriceMappings[bidder_] = newBid;
        if(!_isBidderAlreadyPresent(bidder_)) {
            _bidders.push(bidder_);
        }
        if (newBid > _highestBid) {
            if (msg.sender != _highestBidder) {
                _highestBidder = bidder_;
            }
        }
        _totalAmount += bidPrice_;
        return true;
    }

    /**
     * @dev validates the bid placed for the auction
     *
     * @param bidder_ Address of the bidder placing the bid
     * @param bidPrice_ Price of the bid  
     * @return true if the bid price and the bid owner are verified
     */
    function validateBid(address bidder_, uint256 bidPrice_) public view returns (bool) {
        require (bidder_ != _owner,"Owner cannont place a bid");
        if(!_isBidderAlreadyPresent(bidder_)) {
            require  (bidPrice_ > _basePrice, "Bid amount less than base price") ;
        } else {
            require  (bidPrice_ > 0, "Bid amount should not be 0") ;
        }
         return true;
    }

    /**
     * @dev Checks if the bidder_ is already participating in this Auction
     *
     * @return true if the bidder_ has already placed a bid else returns false
     */
    function _isBidderAlreadyPresent(address bidder_) internal view returns (bool ) {
        for (uint256 i; i < _bidders.length ; i++) {
                if(_bidders[i] == bidder_)
                    return true;
        }
        return false;
    }

    /**
     * @dev Returns the start time of the Auction
     * @param owner_ owner of the Auction    
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return time the Auction was register on block chain
     *
     */
    function getStartTime(address owner_) public view returns(uint256 ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        return _startTime;
    }

    /**
     * @dev Returns the total amount collected for the Auction
     * @param owner_ owner of the Auction    
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return  amount collected for the Auction.
     *
     */
    function getTotalBidAmount(address owner_) public view returns(uint256 ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        return _totalAmount;
    }    

    /**
     * @dev Returns the current highest bid of the Auction
     * @param owner_ owner of the Auction    
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return Higest bid placed so far
     *
     */
    function getCurrentHighestBid(address owner_) public view returns(uint256 ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        uint256 _highestBid = _bidderBidPriceMappings[_highestBidder];
        return _highestBid;
    }

    /**
     * @dev Initiates the cancelling of the Auction. 
     * updates state variables in this Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * - Only if this Auction was not already canceled or finished
     * @param owner_ owner of the Auction
     *
     * @return success after updating the state variables
     * Emits a {AuctionCanceled} event.
     */
    function cancelAuction(address owner_) public 
        onlyNotCanceled
        onlyNotFinished
        returns (bool )
    {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        _canceled = true;
        _startTime = 0;
        return true;
    }

    /**
     * @dev Returns the ERC20(UNIC) token 
     *
     * @return ERC20(UNIC) token smart contract.
     *
     */
    function getERC20() public view returns(IERC20 ) {
        return _token;
    } 

    /**
     * @dev Returns if the Auction is ongoing
     *
     * @return true if the Auction is currently in progress and false if its finished or cancelled
     *
     */
    function isActive() public view returns(bool ) {
        return (_startTime > 0 &&  !_finished && !_canceled);
    } 

    /**
     * @dev Returns the address of the bidder who placed the highest bid so far
     * @param owner_ owner of the Auction
     * Calling conditions:
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return address of the highest bidder of the Auction.
     *
     */
    function getHighestBidder(address owner_) public view returns(address ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
         return _highestBidder;
    }

    /**
     * @dev Returns all the bidder who participated in this Auction
     * @param owner_ owner of the Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return address of the all the bidder who placed the bids for this Auction.
     *
     */
    function getAllBidders(address owner_) public view returns(address[] memory ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        return _bidders;
    }

    /**
     * @dev Returns the bid price placed by a participating bidder
     * @param owner_ owner of the Auction    
     * @param bidder_ bidder participating in this Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return bid price placed by the bidder participating in this Auction
     *
     */
    function getBidderBidPrice(address owner_,address bidder_) public view returns(uint256 ) {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        return _bidderBidPriceMappings[bidder_];
    }

    /**
     * @dev Initiates the ending of the Auction. 
     * updates state variables in this Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param owner_ owner of the Auction
     *
     */
    function auctionFinished(address owner_) public   {
        require(owner_ == _owner, "Only Auction owner can perform this operation");
        _finished = true;
        _canceled = false;
    }
   
    modifier onlyAfterStart {
        require(_startTime > 0, "Auction has not been started");
        _;

    }

    modifier onlyNotCanceled {
        require(_canceled != true, "Auction has been cancelled");
           _;
    }

    modifier onlyNotFinished {
        require(_finished != true, "Auction has been cancelled");
           _;
    }
}


contract UnicusNft is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // GAS Limit for the smart contract
    uint256 private _GAS_LIMIT = 80000000;
    // Keep track of the token id created
    uint256  private _COUNTER;
    // Mapping from ipfs hash to the Auction
    mapping(string => Auction) private _assetHashAuctionMappings;
    // Mapping from Nft token ID to the ipfs hash
    mapping(uint256 => string) private _tokenIdAssetHashMappings;    
    // Array with all token ids of the Nfts created
    uint256[] private _nfts;
    // Array with all ongoing Auctions
    string[] private _ongoingAuctions;

    /**
     * @dev Emitted when ETH Payment is transfered from this contract .
     */
    event EthPaymentSuccess(bool success,bytes data,address from, address to,uint256 amount);

    /**
     * @dev Emitted when ERC20 Payment is transfered from this contract .
     */
    event ERC20PaymentSuccess(bool success,address from, address to,uint256 amount);

    /**
     * @dev Emitted when Auction has commenced .
     */
    event AuctionStarted(string hash,uint256 basePrice,uint256 timestamp);

    /**
     * @dev Emitted when a bidder places a bid for this Auction.
     */
    event BidPlaced(string hash,address bidder, uint bid, address highestBidder, uint highestBid);   

    /**
     * @dev Emitted when Auction is finished  .
     */    
    event AuctionFinished(string hash,uint256 tokenId,address highestBidder, uint highestBid);

    /**
     * @dev Emitted when Auction is cancelled by the Owner .
     */    
    event AuctionCancelled(string hash);    

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the Unicus NFT token collection.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {

    }

    /**
     * @dev starts an Auction in Unicus platform
     *
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can start an Auction
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs
     * @param basePrice_ Base price for the Auction. Any bids for the Auction should be more than the base price
     */
    function auctionStart(string memory assetHash_,uint256 basePrice_) public onlyOwner {
        _auctionStart(assetHash_,basePrice_,IERC20(address(0)));
    }

    /**
     * @dev starts an Auction in Unicus platform with UNIC tokens
     *
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can start an Auction
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs
     * @param basePrice_ Base price for the Auction. Any bids for the Auction should be more than the base price
     * @param token_ Address of the ERC20(UNIC) token smart contract
     */
    function auctionStartERC20(string memory assetHash_,uint256 basePrice_,IERC20 token_) public onlyOwner {
        _auctionStart(assetHash_,basePrice_,token_);
    }

    /**
     * @dev Places a bid on the Auction associated with the Ipfs hash. 
     *
     * Calling conditions:
     *
     * - Any user in Unicus platform can place a bid during duration of the Auction. The bid amount should be 
     *   greater than the base Price set for the Auction
     *
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs for which an Auction was already started
     * Emits a {BidPlaced} event.
     */
    function placeBid(string memory assetHash_) public payable returns (bool){
        Auction auction = _assetHashAuctionMappings[assetHash_];
        require( address(auction) != address(0), "Auction not started for this asset");
        if(auction.validateBid(msg.sender,msg.value) == true) {
            auction.placeBid(msg.sender,msg.value);
            emit BidPlaced(assetHash_,msg.sender, msg.value, auction.getHighestBidder(owner()), auction.getCurrentHighestBid(owner()));
            return true;
        }
        return false;
    }

    /**
     * @dev Places a bid on the Auction associated with the Ipfs hash using ERC20(UNIC) tokens. 
     *
     * Calling conditions:
     *
     * - Any user in Unicus platform can place a bid during duration of the Auction. The bid amount should be 
     *   greater than the base Price set for the Auction and the amount should be ERC20(UNIC) tokens
     *
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs for which an Auction was already started
     * @param amount_ Bid amount placed for the Auction with ERC20(UNIC) tokens.
     * Emits a {BidPlaced} event.
     */
    function placeBidERC20(string memory assetHash_,uint256 amount_) public returns (bool){
        Auction auction = _assetHashAuctionMappings[assetHash_];
        require( address(auction) != address(0), "Auction not started for this asset");
        IERC20 token = auction.getERC20();
        require( address(token) != address(0), "This Auction does not support ERC20 tokens");
        if(auction.validateBid(msg.sender,amount_) == true) {
            _transferERC20(token,msg.sender,address(this), amount_);
            auction.placeBid(msg.sender,amount_);
            emit BidPlaced(assetHash_,msg.sender, amount_, auction.getHighestBidder(owner()), auction.getCurrentHighestBid(owner()));
            return true;
        }
        return false;
    } 

    /**
     * @dev Initiates the ending of the Auction. This triggers returning of the payments made by all 
     * non winning bidders in the Auction. Minting of NFT for the ipfs hash happens here and is transfered
     * to the winning bidder.
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs for which an Auction was already started
     *
     * @return Nft token ID minted for the ipfs hash
     * Emits a {AuctionFinished} event.
     */
    function auctionEnd(string memory assetHash_) public onlyOwner returns (uint256 )  {
        Auction auction = _assetHashAuctionMappings[assetHash_];
        address winner = _returnBidAmountExceptWinner(auction);
        uint256 id = mint(winner);
        _nfts.push(id);
        _tokenIdAssetHashMappings[id] = assetHash_;
        auction.auctionFinished(msg.sender);
        _removeFinishedAuction(assetHash_);
        emit AuctionFinished(assetHash_,id,winner,auction.getCurrentHighestBid(owner()));
        return id;
    }

    /**
     * @dev Initiates the cancelling of the Auction. This triggers returning of the payments made by all 
     * bidders in the Auction. 
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs for which an Auction was already started
     *
     * @return bool indicating success or failure
     * Emits a {AuctionCanceled} event.
     */
    function auctionCancel(string memory assetHash_) public onlyOwner returns (bool )  {
        Auction auction = _assetHashAuctionMappings[assetHash_];
        _returnBidAmount(auction);
        auction.cancelAuction(msg.sender);
        _removeFinishedAuction(assetHash_);
        delete _assetHashAuctionMappings[assetHash_];
        emit AuctionCancelled(assetHash_);
        return true;
    }

    /**
     * @dev Withdraws all the accumulated payments received by the contract and 
     * transfers it to the Owner . (Unicus Platform)
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     *
     */    
    function withdraw() public payable onlyOwner {
        uint256 withdrawBalance = address(this).balance - _getOngoingAuctionsBalances(false);
        _transferETH(msg.sender,withdrawBalance);
    }

    /**
     * @dev Withdraws all the accumulated ERC20 (UNIC) payments received by the contract and 
     * transfers it to the Owner . (Unicus Platform)
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     *
     * @param token_ Address of the ERC20(UNIC) token smart contract
     */  
    function withdrawERC20(IERC20 token_) public payable onlyOwner {
        uint256 balance = token_.balanceOf(address(this)) - _getOngoingAuctionsBalances(true);
        require(balance >= 0, "Insufficient balance.to transfer");
        _transferERC20(token_,address(this),msg.sender,balance);
    }  

    /**
     * @dev  Returns balance of the ETH held by the contract.
     * The amount of ETH that are held of finished auctions
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     *
     * @return the amount of ETH held
     */
    function ethBalance() public onlyOwner view returns(uint256) {
        return address(this).balance - _getOngoingAuctionsBalances(false);
    }

    /**
     * @dev  Returns balance of the withdrawable ERC20 tokens held by the holder.
     * The amount of ERC20 tokens that are held of finished auctions
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     *
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * @param holder_ Address of the ERC20 token holder
     * @return the amount of ERC20 tokens held
     */
    function erc20Balance(IERC20 token_, address holder_) public onlyOwner view returns(uint256) {
        return token_.balanceOf(holder_) - _getOngoingAuctionsBalances(true);
    } 

    /**
     * @dev  Returns total balance of the ERC20 tokens held by the holder.
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     *
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * @param holder_ Address of the ERC20 token holder
     * @return the amount of ERC20 tokens held
     */
    function erc20TotalBalance(IERC20 token_, address holder_) public onlyOwner view returns(uint256) {
        return token_.balanceOf(holder_) ;
    }        


    /** @dev internal function that starts an Auction in Unicus platform
     *
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can start an Auction
     * @param assetHash_ Ipfs hash of asset metadata uploaded onto ipfs
     * @param basePrice_ Base price for the Auction. Any bids for the Auction should be more than the base price
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * Emits a {AuctionStarted} event.
     */   
    function _auctionStart(string memory assetHash_,uint256 basePrice_,IERC20 token_) internal  {
        require(address(_assetHashAuctionMappings[assetHash_]) == address(0) , "Auction already started for this Asset" );
        require(msg.sender == owner() , "Auction can be started only by owner" );
        Auction newAuction = new Auction(owner(),basePrice_,assetHash_,token_);
        _assetHashAuctionMappings[assetHash_] = newAuction;
        _ongoingAuctions.push(assetHash_);
        emit AuctionStarted(assetHash_,basePrice_,newAuction.getStartTime(msg.sender));
    }   
    
    /** @dev internal function that sets the allowance for ERC20(UNIC) tokens from this smart contract to the ownder or individual 
     * bidders who did not win the auction.
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can approve the token transfer
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * @param from_ Address of the owner of the ERC20(UNIC) token 
     * @param to_ Address to which the allowance will be permitted
     * @param amount_ amount of the ERC20(UNIC) tokens that will be allowed
     */ 
    function _approveTransferERC20(IERC20 token_,address from_, address to_,uint256 amount_) private onlyOwner returns (bool) {
        if(from_ == address(this)) {
            if(to_ != owner()) {
                token_.approve(to_,amount_);
                _validateTransferERC20(token_,from_,to_,amount_);
            }
            return token_.transfer(to_, amount_);
        }
        return false;
    }

    /** @dev internal function that validates the transfer of ERC20(UNIC) tokens for balance and allowance
     *
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * @param from_ Address of the owner of the ERC20(UNIC) token 
     * @param to_ Address to which the allowance will be permitted
     * @param amount_ amount of the ERC20(UNIC) tokens that will be transfered
     */ 
    function _validateTransferERC20(IERC20 token_,address from_, address to_,uint256 amount_) private view {
         uint256 allowance_ = token_.allowance(from_, to_);
        require(allowance_ >= amount_, "Insufficient allowance....");
        require(token_.balanceOf(from_) >= amount_, "Insufficient balance.");
    }

    /** @dev internal function that transfers ERC20(UNIC) tokens
     *
     * @param token_ Address of the ERC20(UNIC) token smart contract
     * @param from_ Address of the owner of the ERC20(UNIC) token 
     * @param to_ Address to which the allowance will be permitted
     * @param amount_ amount of the ERC20(UNIC) tokens that will be transfered
     */ 
    function _transferERC20(IERC20 token_,address from_, address to_,uint256 amount_) private   {
        require(amount_ > 0, "Amount to transfer should not be zero.");
        bool success;
        if(msg.sender == owner()) {
            // Transfering ERC20 tokens back to non winning bidders or the owner has called withdrawERC20
            success =_approveTransferERC20(token_,from_,to_,amount_);
        } else {
            // bidders placing bids for an auction.Transfer the bid amount to this smart contract
            success = token_.transferFrom(from_,to_, amount_);           
        }
        emit ERC20PaymentSuccess(success,from_, to_,amount_);        
        require(success);
    }  

    /** @dev internal function that transfers ETH
     *
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform transfer ETH
     *     
     * @param bidder_ Address where the ETH will be transfered
     * @param amount_ amount of the ETH that will be transfered
     */ 
    function _transferETH(address bidder_, uint256 amount_) private onlyOwner {
        require(amount_ > 0, "Amount to transfer should not be zero.");
        (bool success,bytes memory data ) = payable(bidder_).call{value:amount_,gas:_GAS_LIMIT}("");
        emit EthPaymentSuccess(success,data,address(this), bidder_, amount_);
        require(success, "Transfer failed.");
    }

    /**
     * @dev payments made by all non winning bidders in the Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param auction_ Auction which has ended
     *
     * Emits a {PaymentResponse} event. 
     * @return Address of the winning bidder.
     */
    function _returnBidAmountExceptWinner(Auction auction_) private onlyOwner returns(address ){
        require( address(auction_) != address(0), "Auction not started for this asset");
        IERC20 token = auction_.getERC20();
        address winner = auction_.getHighestBidder(msg.sender);
        address[] memory bidders = auction_.getAllBidders(msg.sender);
        for (uint256 i; i < bidders.length ; i++) {
            address bidder = bidders[i];
            if(bidder != winner) {
                uint256 amount = auction_.getBidderBidPrice(msg.sender,bidder);
                if(amount > 0) {
                    if(address(token) != address(0)) {
                       _transferERC20(token,address(this),bidder,amount);
                    } else {
                        _transferETH(bidder,amount);
                    }
                }
            }
        }
        return winner;
    }

    /**
     * @dev payments made by all bidders in the Auction
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param auction_ Auction which has ended
     *
     * Emits a {PaymentResponse} event. 
     * 
     */
    function _returnBidAmount(Auction auction_) private onlyOwner {
        require( address(auction_) != address(0), "Auction not started for this asset");
        IERC20 token = auction_.getERC20();
        address[] memory bidders = auction_.getAllBidders(msg.sender);
        for (uint256 i; i < bidders.length ; i++) {
            address bidder = bidders[i];
            uint256 amount = auction_.getBidderBidPrice(msg.sender,bidder);
            if(amount > 0) {
                if(address(token) != address(0)) {
                    _transferERC20(token,address(this),bidder,amount);
                } else {
                    _transferETH(bidder,amount);
                }
            }
        }
    }

    /**
     * @dev update the Gas limit for the smart contract
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can update the Gas limit 
     * @param gasLimit_ new Gas limit
     *
     */
    function setGasLimit(uint256  gasLimit_) public  onlyOwner{
        _GAS_LIMIT = gasLimit_;
    }    

    /**
     * @dev Returns the number of Nfts in the Smart contract
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return number of NFTs owned by this contract.
     *
     */
    function balanceOf() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    /**
     * @dev  Mints NFT for the the winning bidder.
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param winner_ Address of the winning bidder to whom the minted NFT will be assigned
     *
     * @return Nft token ID minted
     * Emits a {Transfer} event.
     */
    function mint(address winner_) internal returns (uint256 ){
        uint256 id = _COUNTER;
       _safeMint(winner_, id);
        _COUNTER++;
        return id;
    }

    /**
     * @dev Returns all the Nft token ids minted in the Smart contract
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return Array of NFTs minted by this contract
     *
     */
    function getNfts() public view returns (uint256[] memory) {
        return _nfts;
    }

    /**
     * @dev  Returns all the NFT token ids associated with Address.
     * @param owner_ Address of Nft owner
     *
     * @return Array of NFTs owned by this address
     */
    function walletOfOwner(address owner_)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIds;
    }

    /**
     * @dev  Returns all the Ipfs hash associated with the Nft token Id.
     * @param tokenId_ NFT Token Id
     *
     * @return Ipfs hash for the Nft Token Id
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId_),
        "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenIdAssetHashMappings[tokenId_];       
    }

    /**
     * @dev The total amount of ETH/ERC held for the ongoing Auctions
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param erc20_ indicating whether we need the balances of ERC20 autions or ETH auctions
     *
     * @return Total amount of ETH/ERC20.
     */
    function _getOngoingAuctionsBalances(bool erc20_)  internal view onlyOwner returns(uint256) {
        uint256 totalAmount;
        for (uint256 i; i < _ongoingAuctions.length ; i++) {
            string memory hash = _ongoingAuctions[i];
            Auction auction = _assetHashAuctionMappings[hash];
            if(auction.isActive() ) {
                if(!erc20_) {
                    totalAmount += auction.getTotalBidAmount(msg.sender);
                } else {
                    if(_isAuctionERC(auction)) {
                        totalAmount += auction.getTotalBidAmount(msg.sender);
                    }
                }
            }
        }
        return totalAmount;
    }

    /**
     * @dev is the Auction ETH /ERC20 based
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param auction_ The Auction in consideration
     *
     * @return true if Auction is ERC20 based
     */
    function _isAuctionERC(Auction auction_) private onlyOwner view returns(bool) {
        IERC20 token = auction_.getERC20();
        return (address(token) != address(0));
    }

    /**
     * @dev removes the assetHash of finished Auctions from the Array
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can end an Auction. 
     * @param assetHash_ The assetHash to remove.
     *
     */
    function _removeFinishedAuction(string memory assetHash_) private onlyOwner{
        int index = _getIndexOfOngoingAuction(assetHash_);
        if(index >= 0) {
            _ongoingAuctions[uint256(index)] = _ongoingAuctions[_ongoingAuctions.length-1];
            _ongoingAuctions.pop();
        }
    }

    /**
     * @dev Returns all the Nft token ids minted in the Smart contract
     * Calling conditions:
     *
     * - Only the owner of the smart contract i.e Unicus platform can invoke this 
     * @return index_ of the assetHash
     *
     */
    function _getIndexOfOngoingAuction(string memory assetHash_) private view returns (int index_) {
        int index = -1;
        for (uint256 i; i < _ongoingAuctions.length ; i++) {
            string memory assetHash = _ongoingAuctions[i];
            if((keccak256(abi.encodePacked((assetHash))) == keccak256(abi.encodePacked((assetHash_))))) {
                return int(i);
            }
        }
        return index;
    }

}