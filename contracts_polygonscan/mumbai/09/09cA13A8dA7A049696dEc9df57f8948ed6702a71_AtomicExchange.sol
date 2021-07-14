/**
 *Submitted for verification at polygonscan.com on 2021-07-14
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














// From @openzeppelin/contracts 4.1.0










/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}







/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}







/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


/** An implementation of ERC1155 from OpenZeppelin.

- Hold NFTs.
- Hold a currency for fees.
*/
contract BaseNFT is ERC1155 {
    /** The token ID that represents the CERE currency for all payments in this contract. */
    uint256 public constant CURRENCY = 0;

    /** The global supply of CERE tokens on all chains.
     * That is 10 billion tokens, with 10 decimals.
     */
    uint256 public constant CURRENCY_SUPPLY = 10e9 * 1e10;

    constructor() ERC1155("https://cere.network/nft/{id}.json") {}

    function _forceTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount)
    internal {
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        address operator = _msgSender();
        emit TransferSingle(operator, from, to, id, amount);
    }
}

/** An implementation of ChildERC20 used by the Polygon bridge.
 *
 * This contract contains a bridge account. The balance of the bridge represents all the tokens
 * that exist on other chains (Cere Chain and Cere ERC20 on Ethereum).
 *
 * See https://docs.matic.network/docs/develop/ethereum-matic/pos/mapping-assets
 */
contract ChildERC20 is BaseNFT {

    /** ERC20 Transfer event for bridging this ERC1155 contract to ERC20 on Ethereum.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /** The address of the bridge account in this contract. */
    address constant BRIDGE = address(0);

    /** The address of the Polygon bridge contract that is allowed to deposit tokens. */
    address public childChainManagerProxy;

    /** Fill the bridge with the supply of CERE tokens on all chains.
     *
     * Sets the deployer account as ChainManager. To enable the bridge, change it to the actual ChainManager
     * using updateChildChainManager.
     */
    constructor() {
        // _mint(BRIDGE, CURRENCY, CURRENCY_SUPPLY, "");
        //     OR
        _balances[CURRENCY][BRIDGE] = CURRENCY_SUPPLY;

        childChainManagerProxy = _msgSender();
    }

    /** Return the total amount of currency available in the bridge, which can be deposited into this contract.
     */
    function currencyInBridge()
    external view returns (uint256) {
        return _balances[CURRENCY][BRIDGE];
    }

    /** Change the ChainManager, which can deposit currency into any account.
     *
     * Only the current ChainManager is allowed to change the ChainManager.
     */
    function updateChildChainManager(address newChildChainManagerProxy)
    external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(_msgSender() == childChainManagerProxy, "Only the current ChainManager is allowed to change the ChainManager.");

        childChainManagerProxy = newChildChainManagerProxy;
    }

    /** Deposit currency from Ethereum into a user account in this contract.
     *
     * This is implemented by moving tokens from the bridge account to the user account.
     *
     * Two events will be emitted: ERC20 Transfer for the relayers, and ERC1155 TransferSingle like all transfers.
     *
     * There is an extra encoding necessary for the amount. In JavaScript, add this:
     * `web3.eth.abi.encodeParameter('uint256', amount)`
     */
    function deposit(address user, bytes calldata depositData)
    external {
        require(_msgSender() == childChainManagerProxy, "Only the ChainManager is allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        _forceTransfer(BRIDGE, user, CURRENCY, amount);

        emit Transfer(BRIDGE, user, amount);
    }

    /** Withdraw currency from a user account in this contract to Ethereum.
     *
     * This is implemented by moving tokens from the user account to the bridge account.
     *
     * Two events will be emitted: ERC20 Transfer for the relayers, and ERC1155 TransferSingle like all transfers.
     */
    function withdraw(uint256 amount)
    external {
        address user = _msgSender();

        _forceTransfer(user, BRIDGE, CURRENCY, amount);

        emit Transfer(user, BRIDGE, amount);
    }
}


/**
- Issue NFTs.
- Keep track of the address of the issuer of an NFT.
- Enforce rules of issuance: the supply is fixed.

##### Structure of an NFT

The following attributes of a type of NFT are immutable. They are used to derive the ID of the NFTs.
- Issuer: the address of the issuer of this type of NFT.
- Supply: how many NFT of this type exists.

*/
contract Issuance is ChildERC20 {
    /** A counter of NFT types issued by each issuer.
     * This is used to generate unique NFT IDs.
     */
    mapping(address => uint32) public issuanceNonces;

    /** Issue a supply of NFTs of a new type, and return its ID.
     *
     * No more NFT of this type can be issued again.
     *
     * The caller will be recorded as the issuer and it will initially own the entire supply.
     */
    function issue(uint64 supply, bytes memory data)
    public returns (uint256) {
        return _issueAs(_msgSender(), supply, data);
    }

    /** Internal implementation of the function issue.
     */
    function _issueAs(address issuer, uint64 supply, bytes memory data)
    internal returns (uint256) {
        uint32 nonce = issuanceNonces[issuer];
        issuanceNonces[issuer] = nonce + 1;

        uint256 nftId = getNftId(issuer, nonce, supply);

        require(supply > 0);
        _mint(issuer, nftId, supply, data);

        return nftId;
    }

    /** Return whether an address is the issuer of an NFT type.
     *
     * This does not imply that the NFTs exist.
     */
    function _isIssuer(address addr, uint256 nftId)
    internal pure returns (bool) {
        (address issuer, uint32 nonce, uint64 supply) = _parseNftId(nftId);
        return addr == issuer;
    }

    /** Return whether the address is the issuer of an NFT type, and
     * currently owns all NFT of this type (normally right after issuance).
     */
    function _isIssuerAndOnlyOwner(address addr, uint256 id)
    internal view returns (bool) {
        (address issuer, uint32 nonce, uint64 supply) = _parseNftId(id);
        uint64 balance = uint64(balanceOf(issuer, id));

        bool isIssuer = addr == issuer;
        bool ownsAll = balance == supply;
        return isIssuer && ownsAll;
    }

    /** Calculate the ID of an NFT type, identifying its issuer, its supply, and an arbitrary nonce.
     */
    function getNftId(address issuer, uint32 nonce, uint64 supply)
    public pure returns (uint256) {
        // issuer || nonce || supply: 160 + 32 + 64 = 256 bits
        uint256 id = (uint256(uint160(issuer)) << (32 + 64))
        | (uint256(nonce) << 64)
        | uint256(supply);
        return id;
    }

    /** Parse an NFT ID into its issuer, its supply, and an arbitrary nonce.
     *
     * This does not imply that the NFTs exist.
     */
    function _parseNftId(uint256 id)
    internal pure returns (address issuer, uint32 nonce, uint64 supply) {
        issuer = address(uint160((id & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000) >> (32 + 64)));
        nonce = /*     */ uint32((id & 0x0000000000000000000000000000000000000000FFFFFFFF0000000000000000) >> 64);
        supply = /*    */ uint64((id & 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF));
        return (issuer, nonce, supply);
    }
}

/**
A Joint Account (JA) is an account such that multiple owners have a claim on their respective share of the funds.

Joint Accounts support the contract currency only. They cannot be used for NFTs.

An owner may be another Joint Account, or a smart contract.
It is possible to withdraw funds through nested JAs,
because anyone can trigger a withdrawal from a JA to its owners,
including if that owner is itself a JA.

[An implementation that distributes to all owners at once.]
*/
contract JointAccounts is Issuance {
    /** The total fraction representing 100% of an account.
     */
    uint256 public BASIS_POINTS = 100 * 100;

    uint256 public MAX_JOINT_ACCOUNT_SHARES = 10;

    struct JointAccountShare {
        address owner;
        uint256 fraction;
    }

    mapping(address => JointAccountShare[]) public jointAccounts;

    /** Notify that a Joint Account was created at the address `account`.
     *
     * One such event is emitted for each owner, including his fraction of the account in basis points (1% of 1%).
     */
    event JointAccountShareCreated(
        address indexed account,
        address indexed owner,
        uint256 fraction);

    /** Create an account such that multiple owners have a claim on their respective share.
     *
     * The size of a share is given as a fraction in basis points (1% of 1%). The sum of share fractions must equal 10,000.
     *
     * Anyone can create Joint Accounts including any owners.
     */
    function createJointAccount(address[] memory owners, uint256[] memory fractions)
    public returns (address) {
        require(owners.length == fractions.length, "Arrays of owners and fractions must have the same length");
        require(owners.length <= MAX_JOINT_ACCOUNT_SHARES, "Too many shares");

        address account = makeAddressOfJointAccount(owners, fractions);
        JointAccountShare[] storage newShares = jointAccounts[account];

        require(newShares.length == 0, "The account already exists");

        uint256 totalFraction = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint256 fraction = fractions[i];
            require(owner != address(0) && fraction != 0, "0 values are not permitted");

            newShares.push(JointAccountShare({owner : owner, fraction : fraction}));
            totalFraction += fraction;

            emit JointAccountShareCreated(account, owner, fraction);
        }
        require(totalFraction == BASIS_POINTS, "Total fractions must be 10,000");

        return account;
    }

    /** Distribute all tokens available to all owners of a Joint Account.
     *
     * The function createJointAccount must be called beforehand.
     *
     * Anyone can trigger the distribution.
     */
    function distributeJointAccount(address account)
    public {
        uint accountBalance = balanceOf(account, CURRENCY);
        JointAccountShare[] storage shares = jointAccounts[account];

        for (uint i = 0; i < shares.length; i++) {
            JointAccountShare storage share = shares[i];
            uint256 ownerBalance = accountBalance * share.fraction / BASIS_POINTS;

            _forceTransfer(account, share.owner, CURRENCY, ownerBalance);
        }
    }

    /** Generate a unique address identifying a list of owners and shares.
     *
     * It may be used to predict the address of a Joint Account and receive payments
     * even before calling the function createJointAccount.
     */
    function makeAddressOfJointAccount(address[] memory owners, uint256[] memory fractions)
    public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(owners, fractions));
        return address(bytes20(hash));
    }

    /** Return the fraction of an account owned by the given address, in basis points (1% of 1%).
     *
     * If the account does not exist, or if the given address is not an owner of it, this returns 0.
     * If the owner appears more than once in the account, this reports only the first share.
     */
    function fractionOfJAOwner(address account, address maybeOwner)
    public view returns (uint) {
        JointAccountShare[] storage shares = jointAccounts[account];

        for (uint256 i = 0; i < shares.length; i++) {
            JointAccountShare storage share = shares[i];
            if (share.owner == maybeOwner) {
                return share.fraction;
            }
        }
        return 0;
    }

    /** Calculate the amount of tokens that an owner of a Joint Account can withdraw right now.
     */
    function balanceOfJAOwner(address account, address owner)
    public view returns (uint256) {
        uint fraction = fractionOfJAOwner(account, owner);
        uint accountBalance = balanceOf(account, CURRENCY);
        uint256 ownerBalance = accountBalance * fraction / BASIS_POINTS;
        return ownerBalance;
    }

}

/**
- Hold configuration of NFTs: services, royalties.
- Capture royalties on primary and secondary transfers.
- Report configured royalties to service providers (supports Joint Accounts).
 */
contract TransferFees is JointAccounts {

    // Royalties configurable per NFT by issuers.
    mapping(uint256 => address) primaryRoyaltyAccounts;
    mapping(uint256 => uint256) primaryRoyaltyCuts;
    mapping(uint256 => uint256) primaryRoyaltyMinimums;
    mapping(uint256 => address) secondaryRoyaltyAccounts;
    mapping(uint256 => uint256) secondaryRoyaltyCuts;
    mapping(uint256 => uint256) secondaryRoyaltyMinimums;
    mapping(uint256 => uint256) royaltiesConfigLockedUntil;

    /** Notify that royalties were configured on an NFT type.
     */
    event RoyaltiesConfigured(
        uint256 indexed nftId,
        address primaryRoyaltyAccount,
        uint256 primaryRoyaltyCut,
        uint256 primaryRoyaltyMinimum,
        address secondaryRoyaltyAccount,
        uint256 secondaryRoyaltyCut,
        uint256 secondaryRoyaltyMinimum);

    /** Notify that royalties are locked and cannot change, until the given time (in UNIX seconds),
     * or forever (lockUntil = 0xFFFFFFFF).
     */
    event RoyaltiesLocked(
        uint256 indexed nftId,
        uint256 lockUntil);

    /** Return the current configuration of royalties for NFTs of type nftId, as set by configureRoyalties.
     */
    function getRoyalties(uint256 nftId)
    public view returns (
        address primaryRoyaltyAccount,
        uint256 primaryRoyaltyCut,
        uint256 primaryRoyaltyMinimum,
        address secondaryRoyaltyAccount,
        uint256 secondaryRoyaltyCut,
        uint256 secondaryRoyaltyMinimum
    ) {
        return (primaryRoyaltyAccounts[nftId], primaryRoyaltyCuts[nftId], primaryRoyaltyMinimums[nftId],
        secondaryRoyaltyAccounts[nftId], secondaryRoyaltyCuts[nftId], secondaryRoyaltyMinimums[nftId]);
    }

    /** Return the amount of royalties earned by a beneficiary on each primary and secondary transfer of an NFT.
     *
     * This function supports Joint Accounts. If royalties are paid to a JA and beneficiary is an owner of the JA,
     * the shares of the royalties for this owner are returned.
     */
    function getRoyaltiesForBeneficiary(uint256 nftId, address beneficiary)
    public view returns (uint256 primaryCut, uint256 primaryMinimum, uint256 secondaryCut, uint256 secondaryMinimum) {

        // If the royalty account is the given beneficiary, return the configured fees.
        // Otherwise, the royalty account may be a Joint Account, and the beneficiary a share owner of it.
        // Otherwise, "fraction" will be 0, and 0 values will be returned.

        // Primary royalties.
        primaryCut = primaryRoyaltyCuts[nftId];
        primaryMinimum = primaryRoyaltyMinimums[nftId];
        address primaryAccount = primaryRoyaltyAccounts[nftId];
        if (primaryAccount != beneficiary) {
            uint256 fraction = fractionOfJAOwner(primaryAccount, beneficiary);
            primaryCut = primaryCut * fraction / BASIS_POINTS;
            primaryMinimum = primaryMinimum * fraction / BASIS_POINTS;
        }

        // Secondary royalties.
        secondaryCut = secondaryRoyaltyCuts[nftId];
        secondaryMinimum = secondaryRoyaltyMinimums[nftId];
        address secondaryAccount = secondaryRoyaltyAccounts[nftId];
        if (secondaryAccount != beneficiary) {
            uint256 fraction = fractionOfJAOwner(secondaryAccount, beneficiary);
            secondaryCut = secondaryCut * fraction / BASIS_POINTS;
            secondaryMinimum = secondaryMinimum * fraction / BASIS_POINTS;
        }

        return (primaryCut, primaryMinimum, secondaryCut, secondaryMinimum);
    }

    /** Configure the amounts and beneficiaries of royalties on primary and secondary transfers of this NFT.
     * This configuration is available to the issuer of this NFT.
     *
     * A transfer is primary if it comes from the issuer of this NFT (normally the first sale after issuance).
     * Otherwise, it is a secondary transfer.
     *
     * A royalty is defined in two parts (both optional):
     * a cut of the sale price of an NFT, and a minimum royalty per transfer.
     * For simple transfers not attached to a price, or a too low price, the minimum royalty is charged.
     *
     * The cuts are given in basis points (1% of 1%). The minimums are given in currency amounts.
     *
     * The configuration can be changed at any time by default. However, the issuer may commit to it for a period of time,
     * effectively giving up his ability to modify the royalties. See the function lockRoyalties.
     *
     * There can be one beneficiary account for each primary and secondary royalties. To distribute revenues amongst
     * several parties, use a Joint Account (see function createJointAccount).
     */
    function configureRoyalties(
        uint256 nftId,
        address primaryRoyaltyAccount,
        uint256 primaryRoyaltyCut,
        uint256 primaryRoyaltyMinimum,
        address secondaryRoyaltyAccount,
        uint256 secondaryRoyaltyCut,
        uint256 secondaryRoyaltyMinimum)
    public {
        address issuer = _msgSender();
        require(_isIssuer(issuer, nftId), "Only the issuer of this NFT can set royalties");
        require(block.timestamp >= royaltiesConfigLockedUntil[nftId], "Royalties configuration is locked for now");

        require(primaryRoyaltyAccount != address(0) || (primaryRoyaltyCut == 0 && primaryRoyaltyMinimum == 0),
            "The account must not be 0, unless fees are 0");
        primaryRoyaltyAccounts[nftId] = primaryRoyaltyAccount;
        primaryRoyaltyCuts[nftId] = primaryRoyaltyCut;
        primaryRoyaltyMinimums[nftId] = primaryRoyaltyMinimum;

        require(secondaryRoyaltyAccount != address(0) || (secondaryRoyaltyCut == 0 && secondaryRoyaltyMinimum == 0),
            "The account must not be 0, unless fees are 0");
        secondaryRoyaltyAccounts[nftId] = secondaryRoyaltyAccount;
        secondaryRoyaltyCuts[nftId] = secondaryRoyaltyCut;
        secondaryRoyaltyMinimums[nftId] = secondaryRoyaltyMinimum;

        emit RoyaltiesConfigured(
            nftId,
            primaryRoyaltyAccount,
            primaryRoyaltyCut,
            primaryRoyaltyMinimum,
            secondaryRoyaltyAccount,
            secondaryRoyaltyCut,
            secondaryRoyaltyMinimum);
    }

    /** Lock the configuration of royalties for this NFT type. Only the issuer may lock the configuration,
     * after which he himself will no longer be able to change the configuration, for some time, or forever.
     *
     * Set lockUntil to a time in the future to lock the configuration until the specified time (in UNIX seconds).
     * Set to 0xFFFFFFFF to lock forever.
     */
    function lockRoyalties(
        uint256 nftId,
        uint256 lockUntil)
    public {
        address issuer = _msgSender();
        require(_isIssuer(issuer, nftId));

        require(lockUntil > royaltiesConfigLockedUntil[nftId], "Royalties configuration cannot be unlocked earlier");
        royaltiesConfigLockedUntil[nftId] = lockUntil;

        emit RoyaltiesLocked(nftId, lockUntil);
    }

    /** Internal hook to trigger the collection of royalties due on a batch of transfers.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data)
    internal override {
        // Pay a fee per transfer to a beneficiary, if any.
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _captureFee(from, tokenIds[i], /*price*/ 0, amounts[i]);
        }
    }

    /** Calculate the royalty due on a transfer.
     *
     * Collect the royalty using an internal transfer of currency.
     */
    function _captureFee(address from, uint256 nftId, uint256 price, uint256 amount)
    internal {
        if (nftId == CURRENCY) return;

        uint256 cut;
        uint256 minimum;
        address royaltyAccount;
        bool isPrimary = _isPrimaryTransfer(from, nftId);
        if (isPrimary) {
            cut = primaryRoyaltyCuts[nftId];
            minimum = primaryRoyaltyMinimums[nftId];
            royaltyAccount = primaryRoyaltyAccounts[nftId];
        } else {
            cut = secondaryRoyaltyCuts[nftId];
            minimum = secondaryRoyaltyMinimums[nftId];
            royaltyAccount = secondaryRoyaltyAccounts[nftId];
        }

        uint256 perTransferFee = price * cut / BASIS_POINTS;
        if (perTransferFee < minimum) perTransferFee = minimum;

        uint256 totalFee = perTransferFee * amount;
        if (totalFee != 0) {
            _forceTransfer(from, royaltyAccount, CURRENCY, totalFee);
        }
    }

    /** Determine whether a transfer is primary (true) or secondary (false).
     *
     * See the function setRoyalties.
     */
    function _isPrimaryTransfer(address from, uint256 nftId)
    internal pure returns (bool) {
        (address issuer, uint32 nonce, uint64 supply) = _parseNftId(nftId);
        return from == issuer;
    }

}

/**
- Owner creates an offer to sell NFTs.
- Buyer pays and receives the NFT.

- TODO: Support for single transaction compatible with OpenSea / Wyvern Protocol (using a signature from the seller).
*/
contract AtomicExchange is TransferFees {

    /** Seller => NFT ID => Price => Remaining amount offered.
     */
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) sellerNftPriceOffers;

    /** Create an offer to sell an amount of NFTs for a price per unit.
     *
     * To cancel, call again with an amount of 0.
     */
    function offerToSell(uint256 nftId, uint256 price, uint256 amount)
    public {
        address seller = _msgSender();
        sellerNftPriceOffers[seller][nftId][price] = amount;
    }

    /** Accept an offer, paying the price per unit for an amount of NFTs.
     *
     * The offer must have been created beforehand by offerToSell.
     */
    function buyOffer(address seller, uint256 nftId, uint256 price, uint256 amount)
    public {
        // Check and update the amount offered.
        sellerNftPriceOffers[seller][nftId][price] -= amount;

        address buyer = _msgSender();

        // Pay.
        _forceTransfer(buyer, seller, CURRENCY, price * amount);

        // Get NFTs.
        _forceTransfer(seller, buyer, nftId, amount);

        _captureFee(seller, nftId, price, amount);
    }

    /** Accept an offer, paying the price per unit for an amount of NFTs.
     *
     * The offer is proved using sellerSignature generated offchain.
     *
     * [Not implemented]
     */
    function buySignedOffer(uint256 nftId, uint256 price, uint256 amount, bytes memory sellerSignature)
    public {
        revert("not implemented");
    }

    /** Guarantee that a version of Solidity with safe math is used.
     */
    function _mathIsSafe() internal pure {
    unchecked {} // Use a keyword from Solidity 0.8.0.
    }
}

/** Main contract, including all components.

- Hold and transfer NFTs using ERC1155.
- Support atomic exchanges of NFTs for currency.
- Issuance of NFTs with fixed supply.
- Joint Accounts that distribute their funds over multiple owners.
- Capture royalties on primary and secondary transfers, configurable per NFT type.
*/
contract Davinci is /* BaseNFT, ChildERC20, Issuance, JointAccounts, TransferFees, */ AtomicExchange {

}