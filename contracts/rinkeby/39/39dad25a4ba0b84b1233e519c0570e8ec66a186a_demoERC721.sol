/**
 *Submitted for verification at Etherscan.io on 2021-05-29
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
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}















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
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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







/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

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


////////////////////////////////////////
//   #####   ######  #    #   ####    //
//   #    #  #       ##  ##  #    #   //
//   #    #  #####   # ## #  #    #   //
//   #    #  #       #    #  #    #   //
//   #    #  #       #    #  #    #   //
//   #####   ######  #    #   ####    //
////////////////////////////////////////

contract demoERC721 is  ERC721URIStorage {

    address public creator;
    uint8 public number = 1;
    mapping ( uint8 => bool ) public secured; 

    event Mint();
    event SetTokenURI( uint32 , string );
    event SecureCryptoArt( uint32 );

    constructor() ERC721("The Demo" , "DEMO" ) {
        creator = _msgSender();
    } 



    function mint() public {
        require( creator == _msgSender() );
        require( number < 109 );
        _safeMint(_msgSender() , number);
        number++;
        emit Mint();
    }



    function setTokenURI( uint8 _num , string memory _uri ) public{
        require( creator == _msgSender() );
        require( ! secured[_num] );
        _setTokenURI( _num , _uri );
        emit SetTokenURI( _num , _uri );
    }

    function secureCryptoArt( uint8 _num ) public {
        require( creator == _msgSender() );
        require( _num < number );
        secured[_num] = true;
        emit SecureCryptoArt( _num );
    }
    
    function tokenURI( uint tokenId) public view override( ERC721URIStorage ) returns (string memory ) {
        return ( "eyJuYW1lIjoiVW5pc3dhcCAtIDAuMyUgLSBEQUkvV0VUSCAtIDUwMC41NDw+MTAxMTMiLCAiZGVzY3JpcHRpb24iOiJUaGlzIE5GVCByZXByZXNlbnRzIGEgbGlxdWlkaXR5IHBvc2l0aW9uIGluIGEgVW5pc3dhcCBWMyBEQUktV0VUSCBwb29sLiBUaGUgb3duZXIgb2YgdGhpcyBORlQgY2FuIG1vZGlmeSBvciByZWRlZW0gdGhlIHBvc2l0aW9uLlxuXG5Qb29sIEFkZHJlc3M6IDB4YzJlOWYyNWJlNjI1N2MyMTBkN2FkZjBkNGNkNmUzZTg4MWJhMjVmOFxuREFJIEFkZHJlc3M6IDB4NmIxNzU0NzRlODkwOTRjNDRkYTk4Yjk1NGVlZGVhYzQ5NTI3MWQwZlxuV0VUSCBBZGRyZXNzOiAweGMwMmFhYTM5YjIyM2ZlOGQwYTBlNWM0ZjI3ZWFkOTA4M2M3NTZjYzJcbkZlZSBUaWVyOiAwLjMlXG5Ub2tlbiBJRDogMzAwXG5cbuKaoO+4jyBESVNDTEFJTUVSOiBEdWUgZGlsaWdlbmNlIGlzIGltcGVyYXRpdmUgd2hlbiBhc3Nlc3NpbmcgdGhpcyBORlQuIE1ha2Ugc3VyZSB0b2tlbiBhZGRyZXNzZXMgbWF0Y2ggdGhlIGV4cGVjdGVkIHRva2VucywgYXMgdG9rZW4gc3ltYm9scyBtYXkgYmUgaW1pdGF0ZWQuIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU1qa3dJaUJvWldsbmFIUTlJalV3TUNJZ2RtbGxkMEp2ZUQwaU1DQXdJREk1TUNBMU1EQWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRzFzYm5NNmVHeHBibXM5SjJoMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zblBqeGtaV1p6UGp4bWFXeDBaWElnYVdROUltWXhJajQ4Wm1WSmJXRm5aU0J5WlhOMWJIUTlJbkF3SWlCNGJHbHVhenBvY21WbVBTSmtZWFJoT21sdFlXZGxMM04yWnl0NGJXdzdZbUZ6WlRZMExGQklUakphZVVJellWZFNNR0ZFTUc1TmFtdDNTbmxDYjFwWGJHNWhTRkU1U25wVmQwMURZMmRrYld4c1pEQktkbVZFTUc1TlEwRjNTVVJKTlUxRFFURk5SRUZ1U1Vob2RHSkhOWHBRVTJSdlpFaFNkMDlwT0haa00yUXpURzVqZWt4dE9YbGFlVGg1VFVSQmQwd3pUakphZVdNclVFaEtiRmt6VVdka01teHJaRWRuT1VwNlNUVk5TRUkwU25sQ2IxcFhiRzVoU0ZFNVNucFZkMDFJUWpSS2VVSnRZVmQ0YzFCVFkycE9iVWw0VG5wVk1FcDVPQ3RRUXpsNlpHMWpLeUl2UGp4bVpVbHRZV2RsSUhKbGMzVnNkRDBpY0RFaUlIaHNhVzVyT21oeVpXWTlJbVJoZEdFNmFXMWhaMlV2YzNabkszaHRiRHRpWVhObE5qUXNVRWhPTWxwNVFqTmhWMUl3WVVRd2JrMXFhM2RLZVVKdldsZHNibUZJVVRsS2VsVjNUVU5qWjJSdGJHeGtNRXAyWlVRd2JrMURRWGRKUkVrMVRVTkJNVTFFUVc1SlNHaDBZa2MxZWxCVFpHOWtTRkozVDJrNGRtUXpaRE5NYm1ONlRHMDVlVnA1T0hsTlJFRjNURE5PTWxwNVl5dFFSMDV3WTIxT2MxcFRRbXBsUkRCdVRXcFJla3A1UW1wbFZEQnVUWHBSTkVwNVFubFFVMk40VFdwQ2QyVkRZMmRhYld4ellrUXdia2t5VFhkTmJVWm9XVk5qZGxCcWQzWmpNMXB1VUdjOVBTSXZQanhtWlVsdFlXZGxJSEpsYzNWc2REMGljRElpSUhoc2FXNXJPbWh5WldZOUltUmhkR0U2YVcxaFoyVXZjM1puSzNodGJEdGlZWE5sTmpRc1VFaE9NbHA1UWpOaFYxSXdZVVF3YmsxcWEzZEtlVUp2V2xkc2JtRklVVGxLZWxWM1RVTmpaMlJ0Ykd4a01FcDJaVVF3YmsxRFFYZEpSRWsxVFVOQk1VMUVRVzVKU0doMFlrYzFlbEJUWkc5a1NGSjNUMms0ZG1RelpETk1ibU42VEcwNWVWcDVPSGxOUkVGM1RETk9NbHA1WXl0UVIwNXdZMjFPYzFwVFFtcGxSREJ1VFZSWk0wcDVRbXBsVkRCdVRXcFZORXA1UW5sUVUyTjRUV3BDZDJWRFkyZGFiV3h6WWtRd2JrbDZTVE5OVjFGM1dtbGpkbEJxZDNaak0xcHVVR2M5UFNJZ0x6NDhabVZKYldGblpTQnlaWE4xYkhROUluQXpJaUI0YkdsdWF6cG9jbVZtUFNKa1lYUmhPbWx0WVdkbEwzTjJaeXQ0Yld3N1ltRnpaVFkwTEZCSVRqSmFlVUl6WVZkU01HRkVNRzVOYW10M1NubENiMXBYYkc1aFNGRTVTbnBWZDAxRFkyZGtiV3hzWkRCS2RtVkVNRzVOUTBGM1NVUkpOVTFEUVRGTlJFRnVTVWhvZEdKSE5YcFFVMlJ2WkVoU2QwOXBPSFprTTJRelRHNWpla3h0T1hsYWVUaDVUVVJCZDB3elRqSmFlV01yVUVkT2NHTnRUbk5hVTBKcVpVUXdiazFxU1RSS2VVSnFaVlF3YmsxcVJYbEtlVUo1VUZOamVFMUVRbmRsUTJObldtMXNjMkpFTUc1SmVtTXhUbTFPYWsxcFkzWlFhbmQyWXpOYWJsQm5QVDBpSUM4K1BHWmxRbXhsYm1RZ2JXOWtaVDBpYjNabGNteGhlU0lnYVc0OUluQXdJaUJwYmpJOUluQXhJaUF2UGp4bVpVSnNaVzVrSUcxdlpHVTlJbVY0WTJ4MWMybHZiaUlnYVc0eVBTSndNaUlnTHo0OFptVkNiR1Z1WkNCdGIyUmxQU0p2ZG1WeWJHRjVJaUJwYmpJOUluQXpJaUJ5WlhOMWJIUTlJbUpzWlc1a1QzVjBJaUF2UGp4bVpVZGhkWE56YVdGdVFteDFjaUJwYmowaVlteGxibVJQZFhRaUlITjBaRVJsZG1saGRHbHZiajBpTkRJaUlDOCtQQzltYVd4MFpYSStJRHhqYkdsd1VHRjBhQ0JwWkQwaVkyOXlibVZ5Y3lJK1BISmxZM1FnZDJsa2RHZzlJakk1TUNJZ2FHVnBaMmgwUFNJMU1EQWlJSEo0UFNJME1pSWdjbms5SWpReUlpQXZQand2WTJ4cGNGQmhkR2crUEhCaGRHZ2dhV1E5SW5SbGVIUXRjR0YwYUMxaElpQmtQU0pOTkRBZ01USWdTREkxTUNCQk1qZ2dNamdnTUNBd0lERWdNamM0SURRd0lGWTBOakFnUVRJNElESTRJREFnTUNBeElESTFNQ0EwT0RnZ1NEUXdJRUV5T0NBeU9DQXdJREFnTVNBeE1pQTBOakFnVmpRd0lFRXlPQ0F5T0NBd0lEQWdNU0EwTUNBeE1pQjZJaUF2UGp4d1lYUm9JR2xrUFNKdGFXNXBiV0Z3SWlCa1BTSk5Nak0wSURRME5FTXlNelFnTkRVM0xqazBPU0F5TkRJdU1qRWdORFl6SURJMU15QTBOak1pSUM4K1BHWnBiSFJsY2lCcFpEMGlkRzl3TFhKbFoybHZiaTFpYkhWeUlqNDhabVZIWVhWemMybGhia0pzZFhJZ2FXNDlJbE52ZFhKalpVZHlZWEJvYVdNaUlITjBaRVJsZG1saGRHbHZiajBpTWpRaUlDOCtQQzltYVd4MFpYSStQR3hwYm1WaGNrZHlZV1JwWlc1MElHbGtQU0puY21Ga0xYVndJaUI0TVQwaU1TSWdlREk5SWpBaUlIa3hQU0l4SWlCNU1qMGlNQ0krUEhOMGIzQWdiMlptYzJWMFBTSXdMakFpSUhOMGIzQXRZMjlzYjNJOUluZG9hWFJsSWlCemRHOXdMVzl3WVdOcGRIazlJakVpSUM4K1BITjBiM0FnYjJabWMyVjBQU0l1T1NJZ2MzUnZjQzFqYjJ4dmNqMGlkMmhwZEdVaUlITjBiM0F0YjNCaFkybDBlVDBpTUNJZ0x6NDhMMnhwYm1WaGNrZHlZV1JwWlc1MFBqeHNhVzVsWVhKSGNtRmthV1Z1ZENCcFpEMGlaM0poWkMxa2IzZHVJaUI0TVQwaU1DSWdlREk5SWpFaUlIa3hQU0l3SWlCNU1qMGlNU0krUEhOMGIzQWdiMlptYzJWMFBTSXdMakFpSUhOMGIzQXRZMjlzYjNJOUluZG9hWFJsSWlCemRHOXdMVzl3WVdOcGRIazlJakVpSUM4K1BITjBiM0FnYjJabWMyVjBQU0l3TGpraUlITjBiM0F0WTI5c2IzSTlJbmRvYVhSbElpQnpkRzl3TFc5d1lXTnBkSGs5SWpBaUlDOCtQQzlzYVc1bFlYSkhjbUZrYVdWdWRENDhiV0Z6YXlCcFpEMGlabUZrWlMxMWNDSWdiV0Z6YTBOdmJuUmxiblJWYm1sMGN6MGliMkpxWldOMFFtOTFibVJwYm1kQ2IzZ2lQanh5WldOMElIZHBaSFJvUFNJeElpQm9aV2xuYUhROUlqRWlJR1pwYkd3OUluVnliQ2dqWjNKaFpDMTFjQ2tpSUM4K1BDOXRZWE5yUGp4dFlYTnJJR2xrUFNKbVlXUmxMV1J2ZDI0aUlHMWhjMnREYjI1MFpXNTBWVzVwZEhNOUltOWlhbVZqZEVKdmRXNWthVzVuUW05NElqNDhjbVZqZENCM2FXUjBhRDBpTVNJZ2FHVnBaMmgwUFNJeElpQm1hV3hzUFNKMWNtd29JMmR5WVdRdFpHOTNiaWtpSUM4K1BDOXRZWE5yUGp4dFlYTnJJR2xrUFNKdWIyNWxJaUJ0WVhOclEyOXVkR1Z1ZEZWdWFYUnpQU0p2WW1wbFkzUkNiM1Z1WkdsdVowSnZlQ0krUEhKbFkzUWdkMmxrZEdnOUlqRWlJR2hsYVdkb2REMGlNU0lnWm1sc2JEMGlkMmhwZEdVaUlDOCtQQzl0WVhOclBqeHNhVzVsWVhKSGNtRmthV1Z1ZENCcFpEMGlaM0poWkMxemVXMWliMndpUGp4emRHOXdJRzltWm5ObGREMGlNQzQzSWlCemRHOXdMV052Ykc5eVBTSjNhR2wwWlNJZ2MzUnZjQzF2Y0dGamFYUjVQU0l4SWlBdlBqeHpkRzl3SUc5bVpuTmxkRDBpTGprMUlpQnpkRzl3TFdOdmJHOXlQU0ozYUdsMFpTSWdjM1J2Y0MxdmNHRmphWFI1UFNJd0lpQXZQand2YkdsdVpXRnlSM0poWkdsbGJuUStQRzFoYzJzZ2FXUTlJbVpoWkdVdGMzbHRZbTlzSWlCdFlYTnJRMjl1ZEdWdWRGVnVhWFJ6UFNKMWMyVnlVM0JoWTJWUGJsVnpaU0krUEhKbFkzUWdkMmxrZEdnOUlqSTVNSEI0SWlCb1pXbG5hSFE5SWpJd01IQjRJaUJtYVd4c1BTSjFjbXdvSTJkeVlXUXRjM2x0WW05c0tTSWdMejQ4TDIxaGMycytQQzlrWldaelBqeG5JR05zYVhBdGNHRjBhRDBpZFhKc0tDTmpiM0p1WlhKektTSStQSEpsWTNRZ1ptbHNiRDBpTm1JeE56VTBJaUI0UFNJd2NIZ2lJSGs5SWpCd2VDSWdkMmxrZEdnOUlqSTVNSEI0SWlCb1pXbG5hSFE5SWpVd01IQjRJaUF2UGp4eVpXTjBJSE4wZVd4bFBTSm1hV3gwWlhJNklIVnliQ2dqWmpFcElpQjRQU0l3Y0hnaUlIazlJakJ3ZUNJZ2QybGtkR2c5SWpJNU1IQjRJaUJvWldsbmFIUTlJalV3TUhCNElpQXZQaUE4WnlCemRIbHNaVDBpWm1sc2RHVnlPblZ5YkNnamRHOXdMWEpsWjJsdmJpMWliSFZ5S1RzZ2RISmhibk5tYjNKdE9uTmpZV3hsS0RFdU5TazdJSFJ5WVc1elptOXliUzF2Y21sbmFXNDZZMlZ1ZEdWeUlIUnZjRHNpUGp4eVpXTjBJR1pwYkd3OUltNXZibVVpSUhnOUlqQndlQ0lnZVQwaU1IQjRJaUIzYVdSMGFEMGlNamt3Y0hnaUlHaGxhV2RvZEQwaU5UQXdjSGdpSUM4K1BHVnNiR2x3YzJVZ1kzZzlJalV3SlNJZ1kzazlJakJ3ZUNJZ2NuZzlJakU0TUhCNElpQnllVDBpTVRJd2NIZ2lJR1pwYkd3OUlpTXdNREFpSUc5d1lXTnBkSGs5SWpBdU9EVWlJQzgrUEM5blBqeHlaV04wSUhnOUlqQWlJSGs5SWpBaUlIZHBaSFJvUFNJeU9UQWlJR2hsYVdkb2REMGlOVEF3SWlCeWVEMGlORElpSUhKNVBTSTBNaUlnWm1sc2JEMGljbWRpWVNnd0xEQXNNQ3d3S1NJZ2MzUnliMnRsUFNKeVoySmhLREkxTlN3eU5UVXNNalUxTERBdU1pa2lJQzgrUEM5blBqeDBaWGgwSUhSbGVIUXRjbVZ1WkdWeWFXNW5QU0p2Y0hScGJXbDZaVk53WldWa0lqNDhkR1Y0ZEZCaGRHZ2djM1JoY25SUFptWnpaWFE5SWkweE1EQWxJaUJtYVd4c1BTSjNhR2wwWlNJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc0lHMXZibTl6Y0dGalpTSWdabTl1ZEMxemFYcGxQU0l4TUhCNElpQjRiR2x1YXpwb2NtVm1QU0lqZEdWNGRDMXdZWFJvTFdFaVBqQjRZekF5WVdGaE16bGlNakl6Wm1VNFpEQmhNR1UxWXpSbU1qZGxZV1E1TURnell6YzFObU5qTWlEaWdLSWdWMFZVU0NBOFlXNXBiV0YwWlNCaFpHUnBkR2wyWlQwaWMzVnRJaUJoZEhSeWFXSjFkR1ZPWVcxbFBTSnpkR0Z5ZEU5bVpuTmxkQ0lnWm5KdmJUMGlNQ1VpSUhSdlBTSXhNREFsSWlCaVpXZHBiajBpTUhNaUlHUjFjajBpTXpCeklpQnlaWEJsWVhSRGIzVnVkRDBpYVc1a1pXWnBibWwwWlNJZ0x6NDhMM1JsZUhSUVlYUm9QaUE4ZEdWNGRGQmhkR2dnYzNSaGNuUlBabVp6WlhROUlqQWxJaUJtYVd4c1BTSjNhR2wwWlNJZ1ptOXVkQzFtWVcxcGJIazlJaWREYjNWeWFXVnlJRTVsZHljc0lHMXZibTl6Y0dGalpTSWdabTl1ZEMxemFYcGxQU0l4TUhCNElpQjRiR2x1YXpwb2NtVm1QU0lqZEdWNGRDMXdZWFJvTFdFaVBqQjRZekF5WVdGaE16bGlNakl6Wm1VNFpEQmhNR1UxWXpSbU1qZGxZV1E1TURnell6YzFObU5qTWlEaWdLSWdWMFZVU0NBOFlXNXBiV0YwWlNCaFpHUnBkR2wyWlQwaWMzVnRJaUJoZEhSeWFXSjFkR1ZPWVcxbFBTSnpkR0Z5ZEU5bVpuTmxkQ0lnWm5KdmJUMGlNQ1VpSUhSdlBTSXhNREFsSWlCaVpXZHBiajBpTUhNaUlHUjFjajBpTXpCeklpQnlaWEJsWVhSRGIzVnVkRDBpYVc1a1pXWnBibWwwWlNJZ0x6NGdQQzkwWlhoMFVHRjBhRDQ4ZEdWNGRGQmhkR2dnYzNSaGNuUlBabVp6WlhROUlqVXdKU0lnWm1sc2JEMGlkMmhwZEdVaUlHWnZiblF0Wm1GdGFXeDVQU0luUTI5MWNtbGxjaUJPWlhjbkxDQnRiMjV2YzNCaFkyVWlJR1p2Ym5RdGMybDZaVDBpTVRCd2VDSWdlR3hwYm1zNmFISmxaajBpSTNSbGVIUXRjR0YwYUMxaElqNHdlRFppTVRjMU5EYzBaVGc1TURrMFl6UTBaR0U1T0dJNU5UUmxaV1JsWVdNME9UVXlOekZrTUdZZzRvQ2lJRVJCU1NBOFlXNXBiV0YwWlNCaFpHUnBkR2wyWlQwaWMzVnRJaUJoZEhSeWFXSjFkR1ZPWVcxbFBTSnpkR0Z5ZEU5bVpuTmxkQ0lnWm5KdmJUMGlNQ1VpSUhSdlBTSXhNREFsSWlCaVpXZHBiajBpTUhNaUlHUjFjajBpTXpCeklpQnlaWEJsWVhSRGIzVnVkRDBpYVc1a1pXWnBibWwwWlNJZ0x6NDhMM1JsZUhSUVlYUm9QangwWlhoMFVHRjBhQ0J6ZEdGeWRFOW1abk5sZEQwaUxUVXdKU0lnWm1sc2JEMGlkMmhwZEdVaUlHWnZiblF0Wm1GdGFXeDVQU0luUTI5MWNtbGxjaUJPWlhjbkxDQnRiMjV2YzNCaFkyVWlJR1p2Ym5RdGMybDZaVDBpTVRCd2VDSWdlR3hwYm1zNmFISmxaajBpSTNSbGVIUXRjR0YwYUMxaElqNHdlRFppTVRjMU5EYzBaVGc1TURrMFl6UTBaR0U1T0dJNU5UUmxaV1JsWVdNME9UVXlOekZrTUdZZzRvQ2lJRVJCU1NBOFlXNXBiV0YwWlNCaFpHUnBkR2wyWlQwaWMzVnRJaUJoZEhSeWFXSjFkR1ZPWVcxbFBTSnpkR0Z5ZEU5bVpuTmxkQ0lnWm5KdmJUMGlNQ1VpSUhSdlBTSXhNREFsSWlCaVpXZHBiajBpTUhNaUlHUjFjajBpTXpCeklpQnlaWEJsWVhSRGIzVnVkRDBpYVc1a1pXWnBibWwwWlNJZ0x6NDhMM1JsZUhSUVlYUm9Qand2ZEdWNGRENDhaeUJ0WVhOclBTSjFjbXdvSTJaaFpHVXRjM2x0WW05c0tTSStQSEpsWTNRZ1ptbHNiRDBpYm05dVpTSWdlRDBpTUhCNElpQjVQU0l3Y0hnaUlIZHBaSFJvUFNJeU9UQndlQ0lnYUdWcFoyaDBQU0l5TURCd2VDSWdMejRnUEhSbGVIUWdlVDBpTnpCd2VDSWdlRDBpTXpKd2VDSWdabWxzYkQwaWQyaHBkR1VpSUdadmJuUXRabUZ0YVd4NVBTSW5RMjkxY21sbGNpQk9aWGNuTENCdGIyNXZjM0JoWTJVaUlHWnZiblF0ZDJWcFoyaDBQU0l5TURBaUlHWnZiblF0YzJsNlpUMGlNelp3ZUNJK1JFRkpMMWRGVkVnOEwzUmxlSFErUEhSbGVIUWdlVDBpTVRFMWNIZ2lJSGc5SWpNeWNIZ2lJR1pwYkd3OUluZG9hWFJsSWlCbWIyNTBMV1poYldsc2VUMGlKME52ZFhKcFpYSWdUbVYzSnl3Z2JXOXViM053WVdObElpQm1iMjUwTFhkbGFXZG9kRDBpTWpBd0lpQm1iMjUwTFhOcGVtVTlJak0yY0hnaVBqQXVNeVU4TDNSbGVIUStQQzluUGp4eVpXTjBJSGc5SWpFMklpQjVQU0l4TmlJZ2QybGtkR2c5SWpJMU9DSWdhR1ZwWjJoMFBTSTBOamdpSUhKNFBTSXlOaUlnY25rOUlqSTJJaUJtYVd4c1BTSnlaMkpoS0RBc01Dd3dMREFwSWlCemRISnZhMlU5SW5KblltRW9NalUxTERJMU5Td3lOVFVzTUM0eUtTSWdMejQ4WnlCdFlYTnJQU0oxY213b0kyNXZibVVwSWlCemRIbHNaVDBpZEhKaGJuTm1iM0p0T25SeVlXNXpiR0YwWlNnM01uQjRMREU0T1hCNEtTSStQSEpsWTNRZ2VEMGlMVEUyY0hnaUlIazlJaTB4Tm5CNElpQjNhV1IwYUQwaU1UZ3djSGdpSUdobGFXZG9kRDBpTVRnd2NIZ2lJR1pwYkd3OUltNXZibVVpSUM4K1BIQmhkR2dnWkQwaVRURWdNVU14SURrM0lEUTVJREUwTlNBeE5EVWdNVFExSWlCemRISnZhMlU5SW5KblltRW9NQ3d3TERBc01DNHpLU0lnYzNSeWIydGxMWGRwWkhSb1BTSXpNbkI0SWlCbWFXeHNQU0p1YjI1bElpQnpkSEp2YTJVdGJHbHVaV05oY0QwaWNtOTFibVFpSUM4K1BDOW5QanhuSUcxaGMyczlJblZ5YkNnamJtOXVaU2tpSUhOMGVXeGxQU0owY21GdWMyWnZjbTA2ZEhKaGJuTnNZWFJsS0RjeWNIZ3NNVGc1Y0hncElqNDhjbVZqZENCNFBTSXRNVFp3ZUNJZ2VUMGlMVEUyY0hnaUlIZHBaSFJvUFNJeE9EQndlQ0lnYUdWcFoyaDBQU0l4T0RCd2VDSWdabWxzYkQwaWJtOXVaU0lnTHo0OGNHRjBhQ0JrUFNKTk1TQXhRekVnT1RjZ05Ea2dNVFExSURFME5TQXhORFVpSUhOMGNtOXJaVDBpY21kaVlTZ3lOVFVzTWpVMUxESTFOU3d4S1NJZ1ptbHNiRDBpYm05dVpTSWdjM1J5YjJ0bExXeHBibVZqWVhBOUluSnZkVzVrSWlBdlBqd3ZaejQ4WTJseVkyeGxJR040UFNJM00zQjRJaUJqZVQwaU1Ua3djSGdpSUhJOUlqUndlQ0lnWm1sc2JEMGlkMmhwZEdVaUlDOCtQR05wY21Oc1pTQmplRDBpTWpFM2NIZ2lJR041UFNJek16UndlQ0lnY2owaU5IQjRJaUJtYVd4c1BTSjNhR2wwWlNJZ0x6NGdQR2NnYzNSNWJHVTlJblJ5WVc1elptOXliVHAwY21GdWMyeGhkR1VvTWpsd2VDd2dNemcwY0hncElqNDhjbVZqZENCM2FXUjBhRDBpTnpkd2VDSWdhR1ZwWjJoMFBTSXlObkI0SWlCeWVEMGlPSEI0SWlCeWVUMGlPSEI0SWlCbWFXeHNQU0p5WjJKaEtEQXNNQ3d3TERBdU5pa2lJQzgrUEhSbGVIUWdlRDBpTVRKd2VDSWdlVDBpTVRkd2VDSWdabTl1ZEMxbVlXMXBiSGs5SWlkRGIzVnlhV1Z5SUU1bGR5Y3NJRzF2Ym05emNHRmpaU0lnWm05dWRDMXphWHBsUFNJeE1uQjRJaUJtYVd4c1BTSjNhR2wwWlNJK1BIUnpjR0Z1SUdacGJHdzlJbkpuWW1Fb01qVTFMREkxTlN3eU5UVXNNQzQyS1NJK1NVUTZJRHd2ZEhOd1lXNCtNekF3UEM5MFpYaDBQand2Wno0Z1BHY2djM1I1YkdVOUluUnlZVzV6Wm05eWJUcDBjbUZ1YzJ4aGRHVW9Namx3ZUN3Z05ERTBjSGdwSWo0OGNtVmpkQ0IzYVdSMGFEMGlNVFF3Y0hnaUlHaGxhV2RvZEQwaU1qWndlQ0lnY25nOUlqaHdlQ0lnY25rOUlqaHdlQ0lnWm1sc2JEMGljbWRpWVNnd0xEQXNNQ3d3TGpZcElpQXZQangwWlhoMElIZzlJakV5Y0hnaUlIazlJakUzY0hnaUlHWnZiblF0Wm1GdGFXeDVQU0luUTI5MWNtbGxjaUJPWlhjbkxDQnRiMjV2YzNCaFkyVWlJR1p2Ym5RdGMybDZaVDBpTVRKd2VDSWdabWxzYkQwaWQyaHBkR1VpUGp4MGMzQmhiaUJtYVd4c1BTSnlaMkpoS0RJMU5Td3lOVFVzTWpVMUxEQXVOaWtpUGsxcGJpQlVhV05yT2lBOEwzUnpjR0Z1UGkwNU1qSXlNRHd2ZEdWNGRENDhMMmMrSUR4bklITjBlV3hsUFNKMGNtRnVjMlp2Y20wNmRISmhibk5zWVhSbEtESTVjSGdzSURRME5IQjRLU0krUEhKbFkzUWdkMmxrZEdnOUlqRTBNSEI0SWlCb1pXbG5hSFE5SWpJMmNIZ2lJSEo0UFNJNGNIZ2lJSEo1UFNJNGNIZ2lJR1pwYkd3OUluSm5ZbUVvTUN3d0xEQXNNQzQyS1NJZ0x6NDhkR1Y0ZENCNFBTSXhNbkI0SWlCNVBTSXhOM0I0SWlCbWIyNTBMV1poYldsc2VUMGlKME52ZFhKcFpYSWdUbVYzSnl3Z2JXOXViM053WVdObElpQm1iMjUwTFhOcGVtVTlJakV5Y0hnaUlHWnBiR3c5SW5kb2FYUmxJajQ4ZEhOd1lXNGdabWxzYkQwaWNtZGlZU2d5TlRVc01qVTFMREkxTlN3d0xqWXBJajVOWVhnZ1ZHbGphem9nUEM5MGMzQmhiajR0TmpJeE5qQThMM1JsZUhRK1BDOW5QanhuSUhOMGVXeGxQU0owY21GdWMyWnZjbTA2ZEhKaGJuTnNZWFJsS0RJeU5uQjRMQ0EwTXpOd2VDa2lQanh5WldOMElIZHBaSFJvUFNJek5uQjRJaUJvWldsbmFIUTlJak0yY0hnaUlISjRQU0k0Y0hnaUlISjVQU0k0Y0hnaUlHWnBiR3c5SW01dmJtVWlJSE4wY205clpUMGljbWRpWVNneU5UVXNNalUxTERJMU5Td3dMaklwSWlBdlBqeHdZWFJvSUhOMGNtOXJaUzFzYVc1bFkyRndQU0p5YjNWdVpDSWdaRDBpVFRnZ09VTTRMakF3TURBMElESXlMamswT1RRZ01UWXVNakE1T1NBeU9DQXlOeUF5T0NJZ1ptbHNiRDBpYm05dVpTSWdjM1J5YjJ0bFBTSjNhR2wwWlNJZ0x6NDhZMmx5WTJ4bElITjBlV3hsUFNKMGNtRnVjMlp2Y20wNmRISmhibk5zWVhSbE0yUW9PSEI0TENBeE1DNDFjSGdzSURCd2VDa2lJR040UFNJd2NIZ2lJR041UFNJd2NIZ2lJSEk5SWpSd2VDSWdabWxzYkQwaWQyaHBkR1VpTHo0OEwyYytQQzl6ZG1jKyJ9"); 
        } 
}