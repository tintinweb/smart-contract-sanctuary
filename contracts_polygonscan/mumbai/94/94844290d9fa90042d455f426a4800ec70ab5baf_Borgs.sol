/**
 *Submitted for verification at polygonscan.com on 2021-08-30
*/

pragma solidity 0.8.1;

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
    
    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view returns (string memory);

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view returns (string memory);
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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721 {
    using Address for address;
    
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
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
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
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
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract CommonObjects{
    
    struct BorgAttribute{
        bool exists;
        string[] colors;
        int colorSize;
        mapping (string => uint256[]) colorPositions;
    }
    
    struct LayerMetaData{
        string name;
    }
    
    struct Layer{
        bool exists;
        string name;
        mapping(uint => LayerItem) layerItems;
        uint256 layerItemSize;
        uint256 layerItemsCumulativeTotal;
    }
    
    struct LayerItem{
        bool exists;
        uint256 chance;
        string borgAttributeName;
    }
    
    struct Borg{
        uint256 id;
        string name;
        bool exists;
        uint256 descendantId;
        string[] borgAttributeNames;
        uint256[] borgAttributeLayerPositions;
        uint256 borgAttributesSize;
        uint256 parentAId;
        uint256 parentBId;
    }
    
    struct Listing{
        uint256 borgId;
        bool exists;
        uint256 price;
        address seller;
        address buyer;
        uint256 timestamp;
    }
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract Ownable {
    /**
    * @dev The owner of the contract
    */
    address payable internal _owner;
    
    /**
    * @dev The new owner of the contract (for ownership swap)
    */
    address payable internal _potentialNewOwner;
 
    /**
     * @dev Emitted when ownership of the contract has been transferred and is set by 
     * a call to {AcceptOwnership}.
    */
    event OwnershipTransferred(address payable indexed from, address payable indexed to, uint date);
 
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _owner = payable(msg.sender);
    }
  
    modifier onlyOwner() {
      require(msg.sender == _owner);
      _;
    }
  
    function transferOwnership(address payable newOwner) external onlyOwner {
      _potentialNewOwner = newOwner;
    }
  
    function acceptOwnership() external {
      require(msg.sender == _potentialNewOwner);
      emit OwnershipTransferred(_owner, _potentialNewOwner, block.timestamp);
      _owner = _potentialNewOwner;
    }
  
    function getOwner() view external returns(address){
        return _owner;
    }
  
    function getPotentialNewOwner() view external returns(address){
        return _potentialNewOwner;
    }
}

/**
 * @dev Interface of the Ownable modifier handling contract ownership
 */
abstract contract ContractStates is Ownable {
    /**
    * @dev If the contract is editable
    */
    bool internal _isEditable;
    
    /**
     * @dev Sets the owner upon contract creation
     **/
    constructor() {
      _isEditable = true;
    }
  
    modifier editable() {
      require(_isEditable == true);
      _;
    }
    
    modifier usable() {
      require(_isEditable == false);
      _;
    }
    
    function lock() external onlyOwner{
        _isEditable = false;
    }
}

contract NumberUtils{
    // Intializing the state variable
    uint _randNonce = 0;
          
    function _getRandomNumber(uint256 modulus) internal returns(uint){
           // increase nonce
           _randNonce++;  
           return uint(keccak256(abi.encodePacked(block.timestamp, 
                                                  msg.sender, 
                                                  _randNonce))) % modulus;
    }
}

contract Borgs is ERC721Enumerable, ERC721Holder, Ownable, ContractStates, CommonObjects, NumberUtils{
    
    // Mapped borg attributes (image:name)
    mapping (string => BorgAttribute) private _borgAttributes;
    
    // Mapped layers (name/position:layer data)
    mapping (string => Layer) private _layers;
    
    // Mapped borg (id:borg)
    mapping (uint256 => Borg) private _borgs;
    
    // Mapped attribute usage (attribute name:usage)
    mapping (string => uint256) private _borgAttributesUsed;
    
    // All layers
    LayerMetaData[] private _layerMetaData;
    
    // The listings
    mapping (uint256 => Listing) private _listings;
    
    // Array with all listings token ids, used for enumeration
    uint256[] private _allTokenIdsInActiveListings;

    // Mapping from token id to position in the allListings array
    mapping(uint256 => uint256) private _allTokenIdsInActiveListingsIndex;
    
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedListings;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedListingsIndex;
    
    // Owners total listings
    mapping(address => uint256) private  _ownersTotalListings;
    
    // Borgs start from id1
    uint256 private _currentBorgId = 1;
    
    // Max supply (can ever be generated)
    uint256 private _supplyLimit = 500;
    
    // How many have been generated
    uint256 private _currentGeneratedCount = 0;
    
    // How many have been generated
    uint256 private _currentBredCount = 0;
    
    // The size of image to produce (sets output array size)
    uint256 public IMAGE_SIZE = 576;
    
    // The cost to call breedBorgs (wei) after the cost is no longer free
    uint256 public BREED_COST = 50000000000000000;
    
    // The cost to call generateBorgs (wei) after the cost is no longer free
    uint256 public GENERATION_COST = 100000000000000000;
    
    // Sale cost (only taken once sale has been agreed)
    uint256 public MARKETPLACE_COST = 100000000000000000;
    
    // Number of free calls to breedBorgs
    uint256 public FREE_BRED_COUNT = 99;
    
    // Number of free calls to generateBorgs
    uint256 public FREE_GENERATED_COUNT = 99;
    
    // Event for borg generation
    event GeneratedBorg(uint256 indexed borgId, address indexed creator, uint256 timestamp);
    
    // Event for borg breeding
    event BredBorg(uint256 indexed babyBorgId, uint256 indexed parentId, address indexed breeder, uint256 timestamp);
    
    // Event for creating listing
    event CreatedListing(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 timestamp);
    
    // Event for removing listing
    event RemovedListing(uint256 indexed tokenId, address indexed seller, uint256 timestamp);
    
    // Event for the purchase of a listing
    event PurchasedListing(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, uint256 timestamp);

    // Set name, shortcode and limit on construction
    constructor() ERC721("Borgs","BORG"){
    }
    
    // Get the current bred counter
    function getCurrentBredCount() public view returns(uint256){
        return _currentBredCount;
    }
    
    // Get the current generated counter
    function getCurrentGenerationCount() public view returns(uint256){
        return _currentGeneratedCount;
    }

    function getBorg(uint256 borgId) public view returns(string memory name, string[] memory image, string[] memory attributes, uint256 parentAId, uint256 parentBId, uint256 childId){
        // Find the borg in question
        Borg memory borg = _borgs[borgId];
        
        // Combine the attributes to form array of hex colors
        image = _combineBorgAttributes(borg.borgAttributeNames);
        
        // Set parents
        parentAId = borg.parentAId;
        parentBId = borg.parentBId;
        
        // Set child
        childId = borg.descendantId;
        
        // Set attributes
        attributes = borg.borgAttributeNames;
        
        // Set name
        name = borg.name;
    }
    
    function getAttributesUsedCount(string[] memory attributes) public view returns(uint256[] memory){
        uint256[] memory attributeCountsUsed = new uint256[](attributes.length);
        
        for(uint256 i=0;i<attributes.length;i++){
            attributeCountsUsed[i] = _borgAttributesUsed[attributes[i]];
        }
        // Return the count of attributes used
        return attributeCountsUsed;
    }
    
    function getBorgAttribute(string memory borgAttributeName) public view onlyOwner returns (string[] memory imagePixals){
        BorgAttribute storage borgAttribute = _borgAttributes[borgAttributeName];
        
        imagePixals = new string[](IMAGE_SIZE);
        
        for(uint256 i = 0;i<borgAttribute.colors.length;i++){
            string memory color = borgAttribute.colors[i];
            uint256[] memory positions = borgAttribute.colorPositions[color];
            for(uint256 j = 0;j<positions.length;j++){
                imagePixals[positions[j]] = color;
            }
        }
        
        return imagePixals;
    }
    
    function isPriceGreaterThanMarketPlaceListingCost(uint256 price) public view returns(bool){
        return price > MARKETPLACE_COST;
    }
    
    function getMarketPlaceListingCommission() public view returns(uint256){
        return MARKETPLACE_COST;
    }
    
    function addListing(uint256 tokenId, uint256 price, address buyer) public{
        // Ensure caller is token owner
        require(ownerOf(tokenId) == msg.sender, "Caller doesn't own Borg");
        
        // Ensure that the amount sent with the request is enough to add listing
        require(isPriceGreaterThanMarketPlaceListingCost(price), "Price of listing must at least be greater than the market place cost");
        
        // Transfer borg to Contract
        safeTransferFrom(msg.sender, address(this), tokenId);
        
        // Set listing
        Listing memory listing = Listing(tokenId,true,price,msg.sender,buyer,block.timestamp);
        _listings[tokenId] = listing;
        
        // Add to the all list
        _addListingToAllListingsEnumeration(tokenId);
        
        // Add to owner list
        _addListingToOwnerEnumeration(msg.sender, tokenId);
        
        // Create event
        emit CreatedListing(tokenId, msg.sender, buyer, price, block.timestamp);
    }
    
    function removeListing(uint256 tokenId) public{
        // Get listing
        Listing storage listing = _listings[tokenId];
        
        // Checks for listing to exist
        require(listing.exists, "Listing is not active or doesn't exist");
        
        // Checks caller is owner of listing
        require(listing.seller == msg.sender);
        
        // Remove listing
        listing.exists = false;
        
        // Transfer listing back to user
        _transfer(address(this), listing.seller, tokenId);
        
        // Remove from the all list
        _removeTokenFromAllListingsEnumeration(tokenId);
        
        // Remove from owner list
        _removeListingFromOwnerEnumeration(msg.sender, tokenId);
        
        // Create event
        emit RemovedListing(tokenId, msg.sender, block.timestamp);
    }
    
    function purchaseListing(uint256 tokenId) public payable{
        // Get listing
        Listing storage listing = _listings[tokenId];
        
        // Checks for listing to exist
        require(listing.exists, "Listing is not active or doesn't exist");
        
        // Checks caller is the set buyer of listing (or no buyer has been set)
        require(listing.buyer == msg.sender || listing.buyer == address(0), "This is a private listing where you're not the buyer");
        
        // Check amount is enough to match listing
        require(listing.price == msg.value, "Price has not been met or has been exceeded");
        
        // Remove listing
        listing.exists = false;
                
        // Transfer money to seller (minus the market place fee)
        payable(listing.seller).transfer(listing.price - MARKETPLACE_COST);  
        
        // Transfer token to Buyer
        _transfer(address(this), msg.sender, tokenId);
        
        // Remove from the all list
        _removeTokenFromAllListingsEnumeration(tokenId);
        
        // Remove from owner list
        _removeListingFromOwnerEnumeration(msg.sender, tokenId);
        
        // Create event
        emit PurchasedListing(tokenId, listing.seller, msg.sender, listing.price, block.timestamp);
    }
    
    function getListingByTokenId(uint256 tokenId) public view returns(uint256 borgId, uint256 price, address seller, address buyer, uint256 createdDate, string[] memory image){
        // Get listing
        Listing memory listing = _listings[tokenId];
        
        // Confirm listing exists
        require(listing.exists, "Listing doesn't exist");
        
         // Find the borg in question
        Borg memory borg = _borgs[tokenId];
        
        // Combine the attributes to form array of hex colors
        image = _combineBorgAttributes(borg.borgAttributeNames);
        
        // Return all other listing data
        borgId = listing.borgId;
        price = listing.price;
        seller = listing.seller;
        buyer = listing.buyer;
        createdDate = listing.timestamp;
    }
    
    function getListingByIndex(uint256 index) public view returns(uint256 tokenId, uint256 price, address seller, address buyer, uint256 createdDate, string[] memory image){
        // Get tokenId
        uint256 tokenAtIndex = getListingsTokenIdByIndex(index);
        
        // Return listing
        return getListingByTokenId(tokenAtIndex);
    }
    
    function totalTokensListed() public view virtual returns (uint256) {
        return _allTokenIdsInActiveListings.length;
    }

    function getListingsTokenIdByIndex(uint256 index) public view virtual returns (uint256) {
        return _allTokenIdsInActiveListings[index];
    }
    
    function getOwnersListingsTokenIdByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        return _ownedListings[owner][index];
    }
    
    function getOwnersListingByIndex(address owner, uint256 index) public view returns(uint256 tokenId, uint256 price, address seller, address buyer, uint256 createdDate, string[] memory image){
        // Get tokenId
        uint256 tokenAtIndex = getOwnersListingsTokenIdByIndex(owner, index);
        
        // Return listing
        return getListingByTokenId(tokenAtIndex);
    }
    
    function getOwnersTotalListings(address owner) public view virtual returns (uint256) {
        return _ownersTotalListings[owner];
    }
    
    function addLayer(string memory layerName) external onlyOwner editable{
        // Get/create layer
        Layer storage layer = _layers[layerName];
        
        // Update props
        layer.name = layerName;
        layer.exists = true;
       
        // Add meta data about the layer
        LayerMetaData memory metaData = LayerMetaData(layerName);
        _layerMetaData.push(metaData);
    }
    
    function addLayerItem(string memory layerName, uint256 chance, string memory borgAttributeName) external onlyOwner editable{
        // Get the layer
        Layer storage layer = _layers[layerName];
        
        // Basic check
        require(layer.exists, 'Layer doesnt exist');
        
        // Create a new item to add to layer
        LayerItem memory item = LayerItem(true, chance, borgAttributeName);
        
        // Get current items size
        uint256 position = layer.layerItemSize;
        
        // Add onto end
        layer.layerItems[position] = item;
        
        // Update the item size
        layer.layerItemSize = (position + 1);
        
        // Update the cumulative total of chances for the layer
        layer.layerItemsCumulativeTotal = (layer.layerItemsCumulativeTotal + chance);
    }
    
    function addColorToBorgAttribute(string memory borgAttributeName, string memory color, uint256[] memory positions) external onlyOwner editable{
        BorgAttribute storage borgAttribute = _borgAttributes[borgAttributeName];
        borgAttribute.colors.push(color);
        borgAttribute.colorSize = borgAttribute.colorSize + 1;
        borgAttribute.colorPositions[color] = positions;
        borgAttribute.exists = true;
    }
    
    function nameBorg(uint256 borgId, string memory newName) public {
        // Check the owner is the only one renaming
        require(msg.sender == ownerOf(borgId), "Borg must be owned to rename");
        
        // Get the borg and check exists
        Borg storage borg = _borgs[borgId];
        require(borg.exists, "Borg doesn't exist");  
        
        // Rename Borg
        borg.name = newName;
    }
    
    function recoverFunds(address payable toAddress, uint256 amount) public onlyOwner{
        toAddress.transfer(amount);
    } 
    
    function recoverBorg(address payable toAddress, uint256 borgId) public onlyOwner{
        safeTransferFrom(address(this), toAddress, borgId);
    } 
    
    function getGenerationPrice() public view returns(uint256){
        if(_currentGeneratedCount<=FREE_GENERATED_COUNT)
            return 0;
            
        return GENERATION_COST;
    }
    
    function getBreedPrice()public view returns(uint256){
        if(_currentBredCount<=FREE_BRED_COUNT)
            return 0;
            
        return BREED_COST;
    }
    
    function generateBorg() external payable usable returns(uint256){
        // Check layers exist
        require(_layerMetaData.length > 0, "No layers present");
        
        // Check that enough value to cover cost has been sent with request or the user is a whitelisted address (owner)
        require(msg.value == GENERATION_COST || (FREE_GENERATED_COUNT >= _currentGeneratedCount), "Value needs to equal generation cost");
        
        // Check we havent reached the limit for generation (finite supply)
        require(_supplyLimit >= _currentGeneratedCount, "Borg generation limit has been reached");
        
        // Init the selected attribute arrays
        string[] memory borgAttributeNames = new string[](_layerMetaData.length);
        uint256[] memory layerItemPositions = new uint256[](_layerMetaData.length);

        // For each of the layers available, select a random item from it
        for(uint256 i=0;i<_layerMetaData.length;i++){
            // Get the item data to select from
            LayerMetaData storage layerMetaData = _layerMetaData[i];
            
            // Get a random item from the layer
            (borgAttributeNames[i], layerItemPositions[i]) = _getRandomLayerItemName(layerMetaData.name);
            
            // Set in usage recorder
            _updateBorgAttributesUsed(borgAttributeNames[i]);
        }
        
        // Create the borg
        uint256 borgId = _createBorg(borgAttributeNames, layerItemPositions, 0, 0);
 
        // The borg and the token are 1:1 as the ids are the same
        _safeMint(msg.sender, borgId);
        
        // Up the generated count
        _currentGeneratedCount = _currentGeneratedCount + 1;
        
        // Fire event
        emit GeneratedBorg(borgId, msg.sender, block.timestamp);
        
        return borgId;
    }
    
    function breedBorgs(uint256 borgId1, uint256 borgId2) external payable usable returns(uint256){
        // Get the first borg to breed
        Borg storage borg1 = _borgs[borgId1];
        require(borg1.exists, 'Borg 1 doesnt exist');
        require(borg1.descendantId < 1, 'Borg1 already has a descendant');
        
        // Check that enough value to cover cost has been sent with request
        require(msg.value == GENERATION_COST || (FREE_BRED_COUNT >= _currentBredCount), "Value needs to equal breeding cost");
                
        // Get the second borg to breed
        Borg storage borg2 = _borgs[borgId2];
        require(borg2.exists, 'Borg 2 doesnt exist');
        require(borg2.descendantId < 1, 'Borg2 already has a descendant');
        
        // Check to breed the same
        require(borgId1 != borgId2, 'Cannot breed the same borg more than once');
        
        // Require caller is owner of both borgs
        require(ownerOf(borgId1) == msg.sender, 'Must be owner borg 1');
        require(ownerOf(borgId2) == msg.sender, 'Must be owner borg 2');
        
        // Check the attributes size is the same
        require(borg1.borgAttributeNames.length == borg2.borgAttributeNames.length, 'Borg layer counts do not match');
        
        // Burn parents
        _burn(borgId1);
        _burn(borgId2);
        
        // Select the borgs peices it is made up from (rareset from each)
        uint256[] memory layerItemPosition1 = borg1.borgAttributeLayerPositions;
        uint256[] memory layerItemPosition2 = borg2.borgAttributeLayerPositions;
        
        // Filter out the rareset of the 2 sets of items (layer by layer)
        (uint256[] memory borgAttributeLayerPositions, string[] memory borgAttributeNames) = _filterRarestBorgPeices(layerItemPosition1, layerItemPosition2);
        
        // Build the borg
        uint256 borgId = _createBorg(borgAttributeNames, borgAttributeLayerPositions, borgId1, borgId2);

        // Mint token to attach borg to
        _safeMint(msg.sender, borgId);
        
        // Set the parents new descendant
        borg1.descendantId = borgId;
        borg2.descendantId = borgId;
        
        // Up the bred count
        _currentBredCount = _currentBredCount + 1;
        
        // Fire events (1 for each parents)
        emit BredBorg(borgId, borgId1, msg.sender, block.timestamp);
        emit BredBorg(borgId, borgId2, msg.sender, block.timestamp);
        
        // Return new borgs/tokens id
        return borgId;
    }

    function _filterRarestBorgPeices(uint256[] memory layerItemPosition1, uint256[] memory layerItemPosition2) internal returns(uint256[] memory rarestLayerPositions, string[] memory borgPeiceNames){
        // Check the peices size is the same
        require(layerItemPosition1.length == layerItemPosition1.length, 'Borg layer counts do not match');
        
        // Create the new item arrays
        rarestLayerPositions = new uint256[](layerItemPosition1.length);
        string[] memory rarestBorgAttributeNames = new string[](layerItemPosition1.length);
        
        // For each layer we select the rarest of the 2 items
        for(uint256 i=0;i<_layerMetaData.length;i++){
            // Get the layer meta data
            LayerMetaData storage layerMetaData = _layerMetaData[i];
            
            // From that get the layer
            Layer storage layer = _layers[layerMetaData.name];
            
            // Get items from both parents
            LayerItem storage layerItem1 = layer.layerItems[layerItemPosition1[i]];
            LayerItem storage layerItem2 = layer.layerItems[layerItemPosition2[i]];
            
            // Compare and take the item with the lowst chance
            if(layerItem1.chance <= layerItem2.chance){
                rarestLayerPositions[i] = layerItemPosition1[i];
                rarestBorgAttributeNames[i] = layerItem1.borgAttributeName;
            }
            else{
                rarestLayerPositions[i] = layerItemPosition2[i];
                rarestBorgAttributeNames[i] = layerItem2.borgAttributeName;
            }
            
            // Set in usage recorder
            _updateBorgAttributesUsed(rarestBorgAttributeNames[i]);
        }
        
        // Return the rarest positions
        return (rarestLayerPositions, rarestBorgAttributeNames);
    }
    
    function _updateBorgAttributesUsed(string memory borgAttributeName) internal{
        // Get the peice to update count of
        uint256 amount = _borgAttributesUsed[borgAttributeName];
        
        // Update value
        _borgAttributesUsed[borgAttributeName] = amount + 1;
    }
    
    function _combineBorgAttributes(string[] memory borgAttributeNames) internal view returns (string[] memory hexPixals){
        // Init the 
        hexPixals = new string[](IMAGE_SIZE);
        
        for(uint256 i=0;i<borgAttributeNames.length;i++){
             BorgAttribute storage borgAttribute = _borgAttributes[borgAttributeNames[i]];
 
             for(uint256 j = 0;j<borgAttribute.colors.length;j++){
                string memory color = borgAttribute.colors[j];
                uint256[] memory positions = borgAttribute.colorPositions[color];
                for(uint256 k = 0;k<positions.length;k++){
                    hexPixals[positions[k]] = color;
                }
            }
        }
 
        return hexPixals;
    }
    
    function _getRandomLayerItemName(string memory layerItemName) internal returns(string memory borgAttributeName, uint256 position){
        // Get the layer to select item of
        Layer storage layer = _layers[layerItemName];
        
        // Basic checks
        require(layer.exists, "No layer was found");
        require(layer.layerItemSize > 0, "No layer was found");
        
        // Get a random number from 0-the cumulative total of all layer item chances
        uint256 randomChance = _getRandomNumber(layer.layerItemsCumulativeTotal);
        
        // Define the cumulative total to be used as we iterate
        uint256 cumulativeChance = 0;
        
        // Iterate over the layer items until we reach the cumulativeChance (weighted random)
        for(uint256 i=0;i<layer.layerItemSize;i++){
            // Get the layer item
            LayerItem memory item = layer.layerItems[i];
            
            // add the chance for the item to the running total
            cumulativeChance += item.chance;
            
            // If the running total is greater than the random number, we have a winner
            if(cumulativeChance >= randomChance){
                // Set return values
                borgAttributeName = item.borgAttributeName;
                position = i + 0;
                
                // Leave loop
                i = layer.layerItemSize;
            }
        }
    }
    
    function _createBorg(string[] memory borgAttributeNames, uint256[] memory layerItemPositions, uint256 parentAId, uint256 parentBId) internal returns(uint256){
        // Get a new id
        uint256 borgId = _currentBorgId++;
        
        // Get the storage item to fill
        Borg storage borg = _borgs[borgId];
        
        // Set props
        borg.id = borgId;
        borg.exists = true;
        borg.borgAttributesSize = _layerMetaData.length;
        borg.borgAttributeNames = borgAttributeNames;
        borg.borgAttributeLayerPositions = layerItemPositions;
        borg.parentAId = parentAId;
        borg.parentBId = parentBId;
        
        // Return generated id
        return borgId;
    }
    
    function _addListingToAllListingsEnumeration(uint256 listingId) private {
        _allTokenIdsInActiveListingsIndex[listingId] = _allTokenIdsInActiveListings.length;
        _allTokenIdsInActiveListings.push(listingId);
    }

    function _removeTokenFromAllListingsEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokenIdsInActiveListings.length - 1;
        uint256 tokenIndex = _allTokenIdsInActiveListingsIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokenIdsInActiveListings[lastTokenIndex];

        _allTokenIdsInActiveListings[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokenIdsInActiveListingsIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokenIdsInActiveListingsIndex[tokenId];
        _allTokenIdsInActiveListings.pop();
    }
    
    function _addListingToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _ownersTotalListings[to];
        
        _ownedListings[to][length] = tokenId;
        _ownedListingsIndex[tokenId] = length;
        
         // Adjust the users total count
        _ownersTotalListings[to] = length + 1;
    }
    
    function _removeListingFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownersTotalListings[from] - 1;
        uint256 tokenIndex = _ownedListingsIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedListings[from][lastTokenIndex];

            _ownedListings[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
           _ownedListingsIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedListingsIndex[tokenId];
        delete _ownedListings[from][lastTokenIndex];
        
        // Adjust the users total count
        _ownersTotalListings[from] = lastTokenIndex;
    }
}