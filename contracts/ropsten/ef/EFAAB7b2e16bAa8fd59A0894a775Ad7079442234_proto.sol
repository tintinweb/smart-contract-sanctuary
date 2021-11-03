/**
 *Submitted for verification at Etherscan.io on 2021-11-02
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;

/** =============================================================================
*                              PROTO SMART CONTRACT
*   =============================================================================
*   The below method routines make us the business logic of the proto smart 
*   contract. Routines are commented to exlain functionality and aid assessment 
*   of this smart contract and it's features. Reach out to the team with any
*   questions. 
* 
*   =============================================================================
*/
contract proto is IERC721Receiver, Ownable {
/** -----------------------------------------------------------------------------
*   State variable definitions
*   -----------------------------------------------------------------------------
*/
    // struct object that represents a single instance of a loan:
    struct LoanItem {
        // Storage packing - try and use the smallest number of slots!
        // (One slot is 32 bytes, or 256 bits, and you have to declare
        // these in order for the EVM to pack them together. . .)
        // Addresses are 20 bytes.
        // Slot 1, 256:
        uint256 loanId;
        // Slot 2, 168:
        bool    isCurrent;
        address tokenAddress;
        // slot 3, 240:
        address payable borrower;
        uint32  startDate;
        uint32  endDate;
        uint16  tokenId;
        // slot 4: 192
        uint64  loanAmount;
        uint64  serviceFee;
        uint64  currentBalance;
    }

    // This designates the eligible NFT address, i.e. the address from which NFTs can 
    // receive loans in exchange for custodied collateral (the NFT itself):
    address public ELIGIBLE_NFT_ADDRESS = 0x11a6041D9F77F999Eb27574AA55F5b29eDb1d471;
    // In this version the loan amount is a fixed amount:
    uint64  public LOAN_AMOUNT = 10000000000000000;
    // Term in days:
    uint32  public TERM_IN_DAYS = 90;
    // Reposession address - this is the address that NFTs will be send to on the expiry
    // of the loan term.
    address public REPO_ADDRESS = 0xcbA729de243974dBCc5cd90f248F989f5aED40Bb;
    // Each loan attracts a service fee. The amount the borrower has to repay to redeem the
    // NFT is the loan amount plus the service fee:
    uint64  public SERVICE_FEE = 1000000000000000;
    // A fee to extend the loan by another loan term:
    uint64  public EXTENSION_FEE = 0;
    // How close to the end date do we need to be to extend in days?
    uint64  public EXTENSION_HORIZON = 14;
    // The array of items under loan (an array of the struct defined above - a struct is an
    // object which is a collection of other objects):
    LoanItem[] public itemsUnderLoan;
    // Mapping to allow easy tracking of active loans:
    mapping (address => mapping (uint256 => bool)) activeLoans;
    // Mapping borrower address to active loan count
    mapping (address => uint256) private activeLoanCount;
    // Mapping from loan ID to owner address
    mapping (uint256 => address) private borrowersToLoans;
    // Mapping from borrower to list of loan IDs
    mapping(address => mapping(uint256 => uint256)) private borrowersLoans;
    // Mapping from loan ID to index of the borrowers loan list
    mapping(uint256 => uint256) private borrowersLoanIndex;

/** -----------------------------------------------------------------------------
*   Contract event definitions
*   -----------------------------------------------------------------------------
*/
    // Events are broadcast and can be watched and tracked on chain:
    event lendingTransaction    (uint256 loanId, uint256 transactionCode, address tokenAddress, uint16 tokenId, address borrower, uint256 debit, uint256 credit, uint256 effectiveDate);
    event eligibleNFTAddressSet (address);
    event repoAddressSet        (address);
    event loanAmountSet         (uint64);
    event serviceFeeSet         (uint64);
    event extensionFeeSet       (uint64);
    event termInDaysSet         (uint32);
    event extensionHorizonSet   (uint32);
    event ethWithdrawn          (uint256);

/** -----------------------------------------------------------------------------
*   Modifier definitions
*   -----------------------------------------------------------------------------
*/
    // Modifier to allow us to easily assess that the sender is the owner of the 
    // specified asset:
    modifier OnlyItemOwner(address _tokenAddress, uint256 _tokenId){
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(tokenContract.ownerOf(_tokenId) == msg.sender, "Sender has to be owner of the NFT");
        _;
    }

    // Check to see if the array item has the borrower as the calling address:
    modifier OnlyItemBorrower(uint256 _loanId){
        require(itemsUnderLoan[_loanId].borrower == msg.sender, "Payments can only be made by the borrower");
        _;
    }

    // Modifier to determins if THIS contract has transfer approval for the specified asset:
    modifier HasTransferApproval(address _tokenAddress, uint256 _tokenId){
        IERC721 tokenContract = IERC721(_tokenAddress);
        require(tokenContract.getApproved(_tokenId) == address(this), "Loan contract must have approval to transfer this NFT");
        _;
    }

    // Modifier to determins if this item is currently custodied:
    modifier IsCurrentlyCustodied(uint256 _loanId){
        IERC721 tokenContract = IERC721(itemsUnderLoan[_loanId].tokenAddress);
        require(tokenContract.ownerOf(itemsUnderLoan[_loanId].tokenId) == address(this), "NFT item is already custodied under an existing loan");
        _;
    }

    // Check that we have a loan for this item:
    modifier ItemExists(uint256 _loanId){
        require(_loanId < itemsUnderLoan.length && itemsUnderLoan[_loanId].loanId == _loanId, "Could not find item");
        _;
    }

    // Check to see if the array item returned is no longer current:
    modifier IsUnderLoan(uint256 _loanId){
        require(itemsUnderLoan[_loanId].isCurrent == true, "Item is not currently under loan");
        _;
    }

/** -----------------------------------------------------------------------------
*   Set routines - these routines allow the owner to set parameters on this contract:
*   -----------------------------------------------------------------------------
*/
    // Set the address for assets that can be borrowed against:
    function setEligibleNFTAddress(address _ELIGIBLE_NFT_ADDRESS) public onlyOwner returns (bool) {
        ELIGIBLE_NFT_ADDRESS = _ELIGIBLE_NFT_ADDRESS;
        emit eligibleNFTAddressSet(_ELIGIBLE_NFT_ADDRESS);
        return true;
    }
    // Set the address that assets are transfered to on repossession:
    function setRepoAddress(address _REPO_ADDRESS) public onlyOwner returns (bool) {
        REPO_ADDRESS = _REPO_ADDRESS;
        emit repoAddressSet(_REPO_ADDRESS);
        return true;
    }

    // Set the loan amount:
    function setLoanAmount(uint64 _LOAN_AMOUNT) public onlyOwner returns (bool) {
        LOAN_AMOUNT = _LOAN_AMOUNT;
        emit loanAmountSet(_LOAN_AMOUNT);
        return true;
    }

    // Set the service fee:
    function setServiceFee(uint64 _SERVICE_FEE) public onlyOwner returns (bool) {
        SERVICE_FEE = _SERVICE_FEE;
        emit serviceFeeSet(_SERVICE_FEE);
        return true;
    }

    // Set the extension fee:
    function setExtensionFee(uint64 _EXTENSION_FEE) public onlyOwner returns (bool) {
        EXTENSION_FEE = _EXTENSION_FEE;
        emit extensionFeeSet(_EXTENSION_FEE);
        return true;
    }

    // Set the term in days:
    function setTermInDays(uint32 _TERM_IN_DAYS) public onlyOwner returns (bool) {
        TERM_IN_DAYS = _TERM_IN_DAYS;
        emit termInDaysSet(_TERM_IN_DAYS);
        return true;
    }

    // Set extension horizon in days:
    function setExtensionHorizon(uint32 _EXTENSION_HORIZON) public onlyOwner returns (bool) {
        EXTENSION_HORIZON = _EXTENSION_HORIZON;
        emit extensionHorizonSet(_EXTENSION_HORIZON);
        return true;
    }

/** -----------------------------------------------------------------------------
*   Contract routines - these do all the work:
*   -----------------------------------------------------------------------------
*/
    //Always returns `IERC721Receiver.onERC721Received.selector`. We need this to custody NFTs on the contract:
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }  
    
    // Allow contract to receive ETH:
    receive() external payable {}

    // The fallback function is executed on a call to the contract if
    // none of the other functions match the given function signature.
    fallback() external payable {}

    function getParameters() public view returns (address nftContractAddress, uint32 term, uint64 loanAmount, uint64 lendingFee, 
        uint64 extensionHorizon, uint64 extensionFee) {
        return (ELIGIBLE_NFT_ADDRESS, TERM_IN_DAYS, LOAN_AMOUNT, SERVICE_FEE, EXTENSION_HORIZON, EXTENSION_FEE);
    }

    function canBeExtended(uint256 _loanId) public view returns(bool) {
        bool itemCanExtend;
        if ((EXTENSION_FEE > 0) && (block.timestamp + (EXTENSION_HORIZON * 60 * 60 * 24)) >= itemsUnderLoan[_loanId].endDate) (itemCanExtend = true);
            else (itemCanExtend = false);
        return(itemCanExtend);
    }
    
    function borrowerOf(uint256 loanId) public view returns (address) {
        address borrower = borrowersToLoans[loanId];
        require(borrower != address(0), "Borrower query for nonexistent loan");
        return borrower;
    }

    function numberOfLoansOf(address borrower) public view returns (uint256) {
        require(borrower != address(0), "Number of loans query for the zero address");
        return activeLoanCount[borrower];
    }

    function loanExists(uint256 loanId) internal view returns (bool) {
        return borrowersToLoans[loanId] != address(0);
    }

    function loansOfBorrowerByIndex(address borrower, uint256 index) public view returns (uint256) {
        require(index < numberOfLoansOf(borrower), "Borrower index out of bounds");
        return borrowersLoans[borrower][index];
    }

    function addLoanToBorrowerEnumeration(address borrower, uint256 loanId) private {
        uint256 length = numberOfLoansOf(borrower);
        borrowersLoans[borrower][length] = loanId;
        borrowersLoanIndex[loanId] = length;
    }

     // Private function to remove a loan from the loan tracking data structures. 
    function removeLoanFromBorrowerEnumeration(address borrower, uint256 loanId) private {
        // To prevent a gap in borrowers loan array, we store the last loan in the index of the loan to delete, and
        // then delete the last slot (swap and pop).
        uint256 lastLoanIndex = numberOfLoansOf(borrower) - 1;
        uint256 loanIndex = borrowersLoanIndex[loanId];
        // When the loan to delete is the last loan, the swap operation is unnecessary
        if (loanIndex != lastLoanIndex) {
            uint256 lastLoanId = borrowersLoans[borrower][lastLoanIndex];
            borrowersLoans[borrower][loanIndex] = lastLoanId; // Move the last loan to the slot of the to-delete token
            borrowersLoanIndex[lastLoanId] = loanIndex; // Update the moved loan's index
        }
        // This also deletes the contents at the last position of the array
        delete borrowersLoanIndex[loanId];
        delete borrowersLoans[borrower][lastLoanIndex];
    }

    function loanHoldings(address borrower) external view returns (uint256[] memory) {
        uint256 loanCount = numberOfLoansOf(borrower);
        uint256[] memory loans = new uint256[](loanCount);
        for (uint256 i = 0; i < loanCount; i++) {
          loans[i] = loansOfBorrowerByIndex(borrower, i);
        }
        return loans;
    }

    // Ensure that the owner can withdraw deposited ETH:
    function withdraw(uint256 _withdrawal) public onlyOwner returns (bool) {
        payable(msg.sender).transfer(_withdrawal);
        emit ethWithdrawn(_withdrawal);
        return true;
    }

    // This function is called to advance the borrower ETH in exchange for taking 
    // custody of the asset.
    function takeLoan(uint16 tokenId) OnlyItemOwner(ELIGIBLE_NFT_ADDRESS,tokenId) HasTransferApproval(ELIGIBLE_NFT_ADDRESS,tokenId) external returns (uint256){
        // Check this isn't already under loan!
        require(activeLoans[ELIGIBLE_NFT_ADDRESS][tokenId] == false, "Item is already under loan");
        require(address(this).balance >= LOAN_AMOUNT, "Insufficient balance in treasury for loan");
        // The id is the length of the current array as this is the next item:
        uint256 newItemId = itemsUnderLoan.length;
        // Add this to the array:
        itemsUnderLoan.push(LoanItem(newItemId, true, ELIGIBLE_NFT_ADDRESS, payable(msg.sender), uint32(block.timestamp), uint32(block.timestamp) + (TERM_IN_DAYS * 60 * 60 * 24), tokenId, LOAN_AMOUNT, SERVICE_FEE, LOAN_AMOUNT + SERVICE_FEE));
        activeLoans[ELIGIBLE_NFT_ADDRESS][tokenId] = true;
        assert(itemsUnderLoan[newItemId].loanId == newItemId);
        // Custody the asset to this contract:
        IERC721(ELIGIBLE_NFT_ADDRESS).safeTransferFrom(msg.sender, address(this), tokenId);
        addLoanToBorrowerEnumeration(msg.sender, newItemId);
        activeLoanCount[msg.sender] += 1;
        borrowersToLoans[newItemId] = msg.sender;
        // Send the borrower their ETH:
        payable(msg.sender).transfer(LOAN_AMOUNT);
        emit lendingTransaction(newItemId, 1000, ELIGIBLE_NFT_ADDRESS, tokenId, msg.sender, LOAN_AMOUNT, 0, block.timestamp);
        emit lendingTransaction(newItemId, 1010, ELIGIBLE_NFT_ADDRESS, tokenId, msg.sender, SERVICE_FEE, 0, block.timestamp);
        return newItemId;
    }

    // This function is called when the borrower makes a payment. If the payment 
    // clears the balance of the loan this routine will also return the NFT to the 
    // borrower:
    function makeLoanPayment(uint256 _loanId) payable public ItemExists(_loanId) IsUnderLoan(_loanId) OnlyItemBorrower(_loanId) IsCurrentlyCustodied(_loanId){
        require(itemsUnderLoan[_loanId].currentBalance >= msg.value, "Payment exceeds current balance");
        // Reduce the balance outstanding by the amount of ETH received:
        itemsUnderLoan[_loanId].currentBalance = (itemsUnderLoan[_loanId].currentBalance - uint64(msg.value));
        // Emit this payment event: 
        emit lendingTransaction(_loanId, 2000, itemsUnderLoan[_loanId].tokenAddress, itemsUnderLoan[_loanId].tokenId, msg.sender, 0, msg.value, block.timestamp);
        // See if this payment means the loan is done and we can return the asset:
        if (itemsUnderLoan[_loanId].currentBalance == 0)
        {   
            // Well done borrower! Paid on time - here is your NFT back:
            IERC721(itemsUnderLoan[_loanId].tokenAddress).safeTransferFrom(address(this), msg.sender, itemsUnderLoan[_loanId].tokenId);
            itemsUnderLoan[_loanId].isCurrent = false;
            activeLoans[itemsUnderLoan[_loanId].tokenAddress][itemsUnderLoan[_loanId].tokenId] = false;
            removeLoanFromBorrowerEnumeration(msg.sender, _loanId);
            activeLoanCount[msg.sender] -= 1;
            delete borrowersToLoans[_loanId];
            emit lendingTransaction(_loanId, 3000, itemsUnderLoan[_loanId].tokenAddress, itemsUnderLoan[_loanId].tokenId, msg.sender, 0, 0, block.timestamp);
        }
    }

    // This function is called when the borrower extends a loan. The loan can be extended
    // by the original term in days for payment of the extension service fee (if allowed):
    function extendLoan(uint256 _loanId) payable public ItemExists(_loanId) IsUnderLoan(_loanId) OnlyItemBorrower(_loanId) IsCurrentlyCustodied(_loanId){
        require(EXTENSION_FEE > 0, "Extensions are not currently permitted");
        require(msg.value == EXTENSION_FEE, "Payment must equal the extension fee");
        // See where we are relative to the extension horizon i.e. are we close enough to the end of the loan to allow extension:
        require(block.timestamp + (EXTENSION_HORIZON * 60 * 60 * 24) >= itemsUnderLoan[_loanId].endDate, "Too early in term to extend the loan");
        // Extend the term, that's all we need to do
        itemsUnderLoan[_loanId].endDate      = (itemsUnderLoan[_loanId].endDate + (TERM_IN_DAYS * 60 * 60 * 24));
        // Emit this extension event: 
        emit lendingTransaction(_loanId, 4000, itemsUnderLoan[_loanId].tokenAddress, itemsUnderLoan[_loanId].tokenId, msg.sender, msg.value, msg.value, block.timestamp);        
    }

    // This function is called when an item is repossessed. This is ONLY possible when the 
    // loan has lapsed.
    function repossessItem(uint256 _loanId) public ItemExists(_loanId) IsUnderLoan(_loanId) onlyOwner IsCurrentlyCustodied(_loanId){
        require(itemsUnderLoan[_loanId].endDate < block.timestamp, "Loan still current, what you trying to do?!");
        // Shouldn't be possible, but double-check this isn't a loan with a 0 outstanding balance:
        require(itemsUnderLoan[_loanId].currentBalance > 0, "Loan balance is 0, cannot repossess");
        // repo the item to the repo address:
        IERC721(itemsUnderLoan[_loanId].tokenAddress).safeTransferFrom(address(this), REPO_ADDRESS, itemsUnderLoan[_loanId].tokenId);
        itemsUnderLoan[_loanId].isCurrent = false;
        activeLoans[itemsUnderLoan[_loanId].tokenAddress][itemsUnderLoan[_loanId].tokenId] = false;
        removeLoanFromBorrowerEnumeration(msg.sender, _loanId);
        activeLoanCount[itemsUnderLoan[_loanId].borrower] -= 1;
        delete borrowersToLoans[_loanId];
        emit lendingTransaction(_loanId, 5000, itemsUnderLoan[_loanId].tokenAddress, itemsUnderLoan[_loanId].tokenId, itemsUnderLoan[_loanId].borrower, 0, itemsUnderLoan[_loanId].currentBalance, block.timestamp);
    }

    // Repossess all eligible items:
    function repossessItems() public onlyOwner{
        for (uint i =1; i <= itemsUnderLoan.length; i++) {
            if (itemsUnderLoan[i].isCurrent && itemsUnderLoan[i].endDate < block.timestamp)
            {
                repossessItem(itemsUnderLoan[i].loanId);
            }
        }
    }
}