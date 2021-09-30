/**
 *Submitted for verification at polygonscan.com on 2021-09-30
*/

// SPDX-License-Identifier: MIT
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

interface IMIRGTOKEN {
    function mint(address to, uint amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
}

contract MirLoot is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;
    using Strings for uint8;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 private _rancount = 0;
    uint256 private UnitPrice = 1 ether;
    uint256 public currentPriceInWei = 0;
    address public GToken;
    
    struct S_Item2 {
        string name;
        uint8 job;      // 0 all, 1 zhanshi, 2 fashi, 3 daoshi
        uint8 tp;       // 1 wuqi, 2 yifu, 3 toukui, 4 xianglian, 5 shouzuo, 6 jiezhi, 7 shu
        uint8 level;
        uint8 luck;
        uint8 gmin;
        uint8 gmax;
        uint8 gplus;
        
        uint8 amin;
        uint8 amax;
        uint8 aplus;
        
        uint8 mmin;
        uint8 mmax;
        uint8 mplus;
        
        uint8 dmin;
        uint8 dmax;
        uint8 dplus;
    }
    // 0 all, 1 zhanshi, 2 fashi, 3 daoshi
    // 1 wuqi, 2 yifu, 3 toukui, 4 xianglian, 5 shouzuo, 6 jiezhi, 7 shu
    struct S_Item {
        uint256 index;
        uint8 luck;
        uint8 gplus;
        uint8 aplus;
        uint8 mplus;
        uint8 dplus;
    }
    
    mapping(uint256 => S_Item) private list;
    
    string[] private iname = [unicode"屠龙", unicode"嗜魂法杖", unicode"逍遥扇",
    unicode"怒斩", unicode"龙牙", unicode"霸者之刃", unicode"圣战头盔", unicode"圣战项链", unicode"圣战手镯", unicode"圣战戒指", unicode"法神头盔", unicode"法神项链", unicode"法神手镯", unicode"法神戒指", unicode"天尊头盔", unicode"天尊项链", unicode"天尊手镯", unicode"天尊戒指", unicode"烈火剑法", unicode"冰咆哮", unicode"召唤神兽", 
    unicode"裁决之杖", unicode"骨玉权杖", unicode"龙纹剑", unicode"天魔神甲", unicode"法神披风", unicode"天尊道袍", unicode"圣战宝甲", unicode"霓裳羽衣", unicode"天师长袍", unicode"黑铁头盔", unicode"绿色项链", unicode"骑士手镯", unicode"力量戒指", unicode"恶魔铃铛", unicode"龙之手镯", unicode"紫碧螺", unicode"灵魂项链", unicode"三眼手镯", unicode"泰坦戒指",
    unicode"命运之刃", unicode"血饮", unicode"无极棍", unicode"战神盔甲", unicode"恶魔长袍", unicode"幽灵战衣", unicode"祈祷头盔", unicode"幽灵项链", unicode"幽灵手套", unicode"龙之戒指", unicode"生命项链", unicode"思贝儿手镯", unicode"红宝石戒指", unicode"天珠项链", unicode"心灵手镯", unicode"铂金戒指", unicode"刺杀剑术", unicode"雷电术", unicode"灵魂火符",
    unicode"炼狱", unicode"魔杖", unicode"银蛇", unicode"重盔甲", unicode"魔法长袍", unicode"灵魂战衣", unicode"骷髅头盔", unicode"蓝翡翠项链", unicode"死神手套", unicode"珊瑚戒指", unicode"放大镜", unicode"黑檀手镯", unicode"魅力戒指", unicode"竹笛", unicode"道士手镯", unicode"道德戒指",
    unicode"修罗", unicode"青铜斧", unicode"偃月", unicode"海魂", unicode"乌木剑", unicode"降魔", unicode"半月", unicode"中型盔甲", unicode"布衣", unicode"道士头盔", unicode"青铜头盔", unicode"魔鬼项链", unicode"金项链", unicode"坚固手套", unicode"皮制手套", unicode"骷髅戒指", unicode"古铜戒指", unicode"白金项链", unicode"黑檀项链", unicode"蛇眼戒指", unicode"六角戒指", unicode"凤凰明珠", unicode"黄色水晶项链", unicode"珍珠戒指", unicode"玻璃戒指"];
    uint8[] private ijob = [1, 2, 3,    1, 2, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 1, 2, 3,   1, 2, 3, 1, 2, 3, 1, 2, 3, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3,    1, 2, 3, 1, 2, 3, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 1, 2, 3,   1, 2, 3, 1, 2, 3, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3,    1, 1, 2, 2, 0, 3, 3, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3];
    uint8[] private itp =  [1, 1, 1,    1, 1, 1, 3, 4, 5, 6, 3, 4, 5, 6, 3, 4, 5, 6, 7, 7, 7,   1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 4, 5, 6, 4, 5, 6,    1, 1, 1, 2, 2, 2, 3, 4, 5, 6, 4, 5, 6, 4, 5, 6, 7, 7, 7,   1, 1, 1, 2, 2, 2, 3, 4, 5, 6, 4, 5, 6, 4, 5, 6,    1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 4, 4, 6, 6, 4, 4, 6, 6];
    
    uint8[] private gmin = [0, 0, 0,    0, 0, 0, 4, 0, 0, 0, 4, 0, 0, 0, 4, 0, 1, 0, 0, 0, 0,   0, 0, 0, 5, 4, 4, 5, 4, 4, 4, 0, 0, 0, 0, 0, 0, 0, 1, 0,    0, 0, 0, 5, 4, 4, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 4, 3, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 3, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint8[] private gmax = [0, 0, 0,    0, 0, 0, 5, 0, 1, 1, 5, 0, 1, 1, 5, 0, 2, 1, 0, 0, 0,   0, 0, 0,12, 9, 9,12, 9, 9, 5, 0, 1, 1, 0, 0, 0, 0, 1, 0,    0, 0, 0, 9, 7, 7, 4, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 7, 5, 6, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,    0, 0, 0, 0, 0, 0, 0, 5, 2, 2, 1, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    
    uint8[] private amin = [5, 6, 5,   12,10, 6, 0, 3, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 6, 8, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0,   12, 3, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 7, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0,    0, 0, 4, 3, 4, 6, 5, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint8[] private amax = [35,13,13,  26,18,32, 1, 6, 3, 7, 0, 0, 0, 0, 0, 0, 0, 0,30, 0, 0,  30,12,20, 2, 0, 0, 2, 0, 0, 0, 5, 2, 6, 0, 0, 0, 0, 0, 0,   16,14,16, 1, 0, 0, 0, 5, 1, 5, 0, 0, 0, 0, 0, 0,10, 0, 0,   25,0,14, 0, 0, 0, 0, 2, 2, 4, 0, 0, 0, 0, 0, 0,    20,15,10,10,8,11,10, 0, 0, 0, 0, 0, 1, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0];
    
    uint8[] private mmin = [0, 2, 0,    0, 3, 2, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0,   0, 2, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,    0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,   0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0,    0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint8[] private mmax = [0, 8, 0,    0, 6, 7, 0, 0, 0, 0, 1, 8, 4, 6, 0, 0, 0, 0, 0,50, 0,   0, 6, 0, 0, 5, 0, 0, 5, 0, 0, 0, 0, 0, 7, 3, 5, 0, 0, 0,    0, 5, 0, 0, 4, 0, 0, 0, 0, 0, 5, 2, 4, 0, 0, 0, 0,20, 0,   0, 5, 0, 0, 2, 0, 0, 0, 0, 0, 3, 1, 2, 0, 0, 0,    0, 0, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1, 0, 0, 0, 0];
    
    uint8[] private dmin = [0, 0, 4,    0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 0, 0, 0,   0, 0, 3, 0, 0, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2,    0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0,   0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,    0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0];
    uint8[] private dmax = [0, 0,10,    0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 1, 7, 4, 7, 0, 0,40,   0, 0, 6, 0, 0, 5, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 6, 3, 6,    0, 0, 5, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 5, 2, 4, 0, 0,15,   0, 0, 3, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 3, 1, 2,    0, 0, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 2, 1];
    uint8[] private ilevel=[6, 6, 6,    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,   4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,   2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    
    constructor() ERC721("MirLoot", "MIR") Ownable() {
    }

    function setMirGToken(address tokenAddress) public onlyOwner() returns (bool) {
        GToken = tokenAddress;
        return true;
    } 

    function _claim() internal returns (uint256){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        _getTokenAttribute(newItemId);
        return newItemId;
    }
    
    function _updatePrice(uint256 id) internal {
        currentPriceInWei = id / 100 * UnitPrice;
    }

    function claim() public payable nonReentrant {
        require(msg.value >= currentPriceInWei, "Do not have enough ETH");
        uint256 id = _claim();
        _updatePrice(id);
    }
    
    function claimWithAmount(uint256 amount) public payable nonReentrant {
        uint256 id;
        require(totalSupply() >= 100, "This function has not been activated");
        require(msg.value >= (currentPriceInWei * amount), "Do not have enough ETH");
        for (uint256 i = 0; i < amount; i++) {
            id = _claim();            
        }
        _updatePrice(id);
    }
    
    function withdraw(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
    
    function _reward(uint256 tokenId) internal view returns (uint) {
        return random(tokenId) % (10000000000000000000000);   // 0 ~ 10000
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */

    function burn(uint256 tokenId) public virtual {
        require(GToken != address(0), "This function has not been activated");
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "burn: caller is not owner nor approved");
        address to = ownerOf(tokenId);
        uint amount = _reward(tokenId) * ilevel[list[tokenId].index];
        _burn(tokenId);
        IMIRGTOKEN(GToken).mint(to, amount);
    }
    
    // note: the caller should approve this contract use GToken first.
    // success rate 50%
    // attribute
    // 0 : G
    // 1 : A
    // 2 : M
    // 3 : D
    function add_dc(uint256 tokenId) public returns (bool) {
        uint256 index = list[tokenId].index;
        require(_msgSender() == ownerOf(tokenId), "add_dc: caller is not owner");
        require((itp[index] != 1 && itp[index] != 7), "add_dc: weapon and book can not add defence");
        require(list[tokenId].gplus < 3, "add_dc: the attribute plus is already at its maximum");
        uint256 amount = ilevel[index] * (list[tokenId].gplus + 1) * 10000000000000000000000;
        IMIRGTOKEN(GToken).burnFrom(_msgSender(), amount);
        uint a = random(++_rancount) % 2;
        if (a == 0) {
            return false;
        }
        list[tokenId].gplus += 1;
        return true;
    }
    
    function add_ac(uint256 tokenId) public returns (bool) {
        uint256 index = list[tokenId].index;
        require(_msgSender() == ownerOf(tokenId), "add_ac: caller is not owner");
        require(itp[index] != 7, "book can not add attribute");
        uint256 max = 3;
        if (itp[index] == 1) {
            max = 7;
        }
        require(list[tokenId].aplus < max, "add_ac: the attribute plus is already at its maximum");
        uint256 amount = ilevel[index] * (list[tokenId].aplus + 1) * 10000000000000000000000;
        IMIRGTOKEN(GToken).burnFrom(_msgSender(), amount);
        uint a = random(++_rancount) % 2;
        if (a == 0) {
            return false;
        }
        list[tokenId].aplus += 1;
        return true;
    }
    
    function add_mc(uint256 tokenId) public returns (bool) {
        uint256 index = list[tokenId].index;
        require(_msgSender() == ownerOf(tokenId), "add_mc: caller is not owner");
        require(itp[index] != 7, "book can not add attribute");
        uint256 max = 3;
        if (itp[index] == 1) {
            max = 7;
        }
        require(list[tokenId].mplus < max, "add_mc: the attribute plus is already at its maximum");
        uint256 amount = ilevel[index] * (list[tokenId].mplus + 1) * 10000000000000000000000;
        IMIRGTOKEN(GToken).burnFrom(_msgSender(), amount);
        uint a = random(++_rancount) % 2;
        if (a == 0) {
            return false;
        }
        list[tokenId].mplus += 1;
        return true;
    }
    
    function add_sc(uint256 tokenId) public returns (bool) {
        uint256 index = list[tokenId].index;
        require(_msgSender() == ownerOf(tokenId), "add_sc: caller is not owner");
        require(itp[index] != 7, "book can not add attribute");
        uint256 max = 3;
        if (itp[index] == 1) {
            max = 7;
        }
        require(list[tokenId].dplus < max, "add_sc: the attribute plus is already at its maximum");
        uint256 amount = ilevel[index] * (list[tokenId].dplus + 1) * 10000000000000000000000;
        IMIRGTOKEN(GToken).burnFrom(_msgSender(), amount);
        uint a = random(++_rancount) % 2;
        if (a == 0) {
            return false;
        }
        list[tokenId].dplus += 1;
        return true;
    }
    
    function add_luck(uint256 tokenId) public returns (bool) {
        uint256 index = list[tokenId].index;
        require(_msgSender() == ownerOf(tokenId), "add_luck: caller is not owner");
        require((itp[index] == 1) || (itp[index] == 4), "add_luck: only weapon and necklace could be added luck");
        uint256 max;
        uint256 amount;
        if (itp[index] == 1) {
            max = 7;
            amount = ilevel[index] * (list[tokenId].luck + 1) * 20000000000000000000000;
        } else {
            max = 2;
            amount = ilevel[index] * (list[tokenId].luck + 1) * 50000000000000000000000;
        }
        require(list[tokenId].luck < max, "add_luck: Lucky value has been the largest");

        IMIRGTOKEN(GToken).burnFrom(_msgSender(), amount);
        uint a = random(++_rancount) % 2;
        if (a == 0) {
            return false;
        }
        list[tokenId].luck += 1;
        return true;
    }
    /*************************************************************************/

    function random(uint256 input) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input, block.timestamp)));
    }
    
    function _getTokenAttribute(uint256 tokenId) internal {
        uint a = random(tokenId);
        uint b = a >> 32;
        a = a % (1000);
        uint256 index;
        if (a > 450) {                   
            index = 75 + b % 25;
        } else if (a > 210) {               // 45
            index = 59 + b % 16;
        } else if (a > 90) {                // 21
            index = 40 + b % 19;
        } else if (a > 30) {                // 9
            index = 21 + b % 19;
        } else if (a > 1) {                 // 3
            index = 3 + b % 18;
        } else {
            index = b % 3;
        }
        list[tokenId].index = index;
    }

    function getItemInfo(uint256 tokenId) public view returns (S_Item2 memory) {
        S_Item2 memory info;
        uint256 i = list[tokenId].index;
        info.name = iname[i];
        info.job = ijob[i];
        info.tp = itp[i];
        info.luck = list[tokenId].luck;
        info.gmin = gmin[i];
        info.gmax = gmax[i];
        info.gplus = list[tokenId].gplus;
        info.amin = amin[i];
        info.amax = amax[i];
        info.aplus = list[tokenId].aplus;
        info.mmin = mmin[i];
        info.mmax = mmax[i];
        info.mplus = list[tokenId].mplus;
        info.dmin = dmin[i];
        info.dmax = dmax[i];
        info.dplus = list[tokenId].dplus;
        return info;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[20] memory item;
        S_Item2 memory temp = getItemInfo(tokenId);
        uint256 i = list[tokenId].index;
 
        uint index = 0;
        item[index] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 160 200"><style>.base {font-family: serif; font-size: 14px;';
        if (ilevel[i] < 4) {
            item[index] = string(abi.encodePacked(item[index], 'fill: white'));
        } else if (ilevel[i] == 4) {
            item[index] = string(abi.encodePacked(item[index], 'fill: yellow'));
        } else if (ilevel[i] == 5) {
            item[index] = string(abi.encodePacked(item[index], 'fill: goldenrod'));
        } else if (ilevel[i] == 6) {
            item[index] = string(abi.encodePacked(item[index], 'fill: red'));
        }
        item[index] = string(abi.encodePacked(item[index], ';}</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">'));
        index++;
        item[index++] = iname[i];

        item[index++] = '</text><text x="10" y="40" class="base">';
        item[index] = unicode"职业：";

        if (temp.job == 1) {
            item[index] = string(abi.encodePacked(item[index], unicode"战士"));
        } else if (temp.job == 2) {
            item[index] = string(abi.encodePacked(item[index], unicode"法师"));
        } else if (temp.job == 3) {
            item[index] = string(abi.encodePacked(item[index], unicode"道士"));
        } else {
             item[index] = string(abi.encodePacked(item[index], unicode"不限"));           
        }
        index++;
        
        item[index++] = '</text><text x="10" y="60" class="base">';
        if (temp.gmin + temp.gmax + temp.gplus > 0) {
            item[index] = string(abi.encodePacked(unicode"防御: ", temp.gmin.toString(), " - ", temp.gmax.toString()));
            if (temp.gplus != 0) {
                item[index] = string(abi.encodePacked(item[index], " (+", temp.gplus.toString(), ")"));                
            }
            index++;
        }
        
        item[index++] = '</text><text x="10" y="80" class="base">';
        if (temp.amin + temp.amax + temp.aplus > 0) {
            if (temp.tp != 7) {
                item[index] = string(abi.encodePacked(unicode"攻击: ", temp.amin.toString(), " - ", temp.amax.toString()));
                if (temp.aplus != 0) {
                    item[index] = string(abi.encodePacked(item[index], " (+", temp.aplus.toString(), ")"));                
                }               
            } else {
                item[index] = string(abi.encodePacked(unicode"攻击: ", '+ ', temp.amax.toString(), "%"));
            }
            index++;
        }
        
        item[index++] = '</text><text x="10" y="100" class="base">';
        if (temp.mmin + temp.mmax + temp.mplus > 0) {
            if (temp.tp != 7) {
                item[index] = string(abi.encodePacked(unicode"魔法: ", temp.mmin.toString(), " - ", temp.mmax.toString()));
                if (temp.mplus != 0) {
                    item[index] = string(abi.encodePacked(item[index], " (+", temp.mplus.toString(), ")"));                
                }
            } else {
                item[index] = string(abi.encodePacked(unicode"魔法: ", '+ ', temp.mmax.toString(), "%"));
            }
            index++;
        }

        item[index++] = '</text><text x="10" y="120" class="base">';
        if (temp.dmin + temp.dmax + temp.dplus > 0) {
            if (temp.tp != 7) {
                item[index] = string(abi.encodePacked(unicode"道术: ", temp.dmin.toString(), " - ", temp.dmax.toString()));
                if (temp.dplus != 0) {
                    item[index] = string(abi.encodePacked(item[index], " (+", temp.dplus.toString(), ")"));                
                }
            } else {
                item[index] = string(abi.encodePacked(unicode"道术: ", '+ ', temp.dmax.toString(), "%"));
            }
            index++;
        }

        item[index++] = '</text><text x="10" y="140" class="base">';
        if (temp.luck > 0) { 
            item[index++] = string(abi.encodePacked(unicode"幸运: + ", temp.luck.toString()));
        }
        
        item[index++] = '</text></svg>';

        string memory output = string(abi.encodePacked(item[0], item[1], item[2], item[3], item[4], item[5], item[6], item[7], item[8]));
        output = string(abi.encodePacked(output, item[9], item[10], item[11], item[12], item[13], item[14], item[15]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Item #', tokenId.toString(), '", "description": "MirLoot", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}