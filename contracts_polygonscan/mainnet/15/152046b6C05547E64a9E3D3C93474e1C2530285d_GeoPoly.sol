/**
 *Submitted for verification at polygonscan.com on 2021-12-03
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







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
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
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
        _setApprovalForAll(_msgSender(), operator, approved);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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

// File: Geopoly_NFTs.sol




pragma solidity >=0.7.0 <0.9.0;

library Nums {
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

library GeoSpecial {
    /**
     * @dev mutiple arithmatic, types and logical checks can be implemented
     * to ensure proper propogation of the contract when calling this library.
     * However, checks are actually done in the contract itself as a result of
     * the owner having the freedom in picking and choosing from the list of outcomes
     * that this library produces. mainly the functions:
     * 1- `GeoPoly.addToMints`
     * 2- `GeoPoly.resetReservedNFTs`
     */
    function disect(bytes calldata _in) public pure returns(bytes32[] memory){ //  
        bytes32[] memory output = new bytes32[](5);
        uint256 curIdx = 0;
        uint256 oIdx = 0;
        for(uint256 i=0; i<_in.length; i++){
            if(_in[i] == 0x2f){
                output[oIdx] = bytes32(_in[curIdx:i]);
                oIdx++;
                curIdx = i+1;
            }
        }
        output[4] = bytes32(_in[curIdx:_in.length]);
        return(output);
    }
        
    function format(bytes32[] memory _inArr) public pure returns(uint256 category, uint256 tier, uint256 price, string memory lat, string memory lng){
        category = uint256(asciiToInteger(_inArr[0]));
        tier = uint256(asciiToInteger(_inArr[1]));
        price = uint256(asciiToInteger(_inArr[2]));
        lat = bytes32ToString(_inArr[3]);
        lng = bytes32ToString(_inArr[4]);
    }
    
    function convertStringToByes(string calldata _in) public pure returns(bytes calldata _out){

        _out = bytes(_in);
    }
    
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint256 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
    
    function asciiToInteger(bytes32 x) public pure returns (uint256) {
            uint256 y;
            for (uint256 i = 0; i < 32; i++) {
                uint256 c = (uint256(x) >> (248 - i * 8)) & 0xff;
                if (48 <= c && c <= 57)
                    y += (c - 48) * 10 ** i;
                 else if (65 <= c && c <= 90)
                    y += (c - 65 + 10) * 10 ** i;
                else if (97 <= c && c <= 122)
                    y += (c - 97 + 10) * 10 ** i;
                else
                    break;
            }
            return y;
    }
    
    function doAll(string calldata _in) public pure returns(uint256 cat, uint256 tier, uint256 _price, string memory lat, string memory lng){

        return(format(disect(convertStringToByes(_in))));
    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
 
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

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

}

interface GEOS20 {
    function transfer(address _to, uint256 _amount) external returns(bool);
    function decimals() external view returns (uint8);
    function balanceOf(address wallet) external returns(uint256);
    function transferFrom( address sender,address recipient,uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface GeosOracle {
    function getExchangeRate(string calldata tokenName) external view returns(uint256);
}

abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

 
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

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

abstract contract Roles is Ownable {
    mapping(address => bool) private admins;
    
    constructor() {
        addToAdmins(_msgSender());
    }

    function addToAdmins(address _addr) public onlyOwner {
        admins[_addr] = true;
    }
    
    function removeFromAdmins(address _addr) public onlyOwner {
        admins[_addr] = false;
    } 
    
    modifier isAdmin() {
        require(admins[_msgSender()], "Roles: This address is not an admin");
        _;
    }
}

contract GeoPoly is ERC1155,ReentrancyGuard,Ownable,Roles {
    // using counters for index trackers
    using Nums for Nums.Counter;

    // events for topics which are cruical
    // minting an NFT
    event GeoMint(string mintingProperties, address indexed minter);
    // reserving an NFT
    event ReserveMint(string mintingProperties, address indexed minter);
    // upgrading an NFT
    event GeoUpgrade(uint256 category, uint256 previousTier, uint256 newTier, address indexed owner);

    // an array for the reserved NFTs
    string[] _reservedNFTs;
    
    // mapping for reservations
    mapping(string => address) _resNFTs;

    // a mapping for the mints
    mapping(string => NFTVars) _avalMints;

    // a reference for tokenIDs and their reference string
    mapping(uint256 => string) _mintIDs;

    // all the current avaliable categories
    mapping(uint256 => Category) _avalibleCategory;

    // different private NFT sales resulting in 
    // differnt addresses being whitelisted
    // @params keccak256(uint256 privateNFTSaleVersion, address whiteListed)
    mapping (bytes32 => bool) privateNFTSale;

    // current privateSaleVersion
    uint256 privateNFTSaleVersion;

    // a maximum cap for reservations
    uint256 public constant reservedCap = 100;

    // owner minting NFT cap
    uint256 public constant ownerNFTCap = 2500;

    // the amount of nfts avaliable for minting this season
    uint256 nftsPerSeason = 0;

    // the current season num;
    uint256 seasonNum = 0;

    // upgrade price in GEOS
    uint256 public upgradePrice = 0.1 ether;

    // all functionality for nfts is paused
    bool privateSaleLive = false;

    // all functionality for nft sales (mint) is paused
    bool allowNFTSales = true;

    // a counter to track category indexes
    Nums.Counter private catIdx;

    // a counter to track minting indexes
    Nums.Counter private mintCounter;

    // a counter to track owner mints
    Nums.Counter private oMints;

    // a counter for total season minting
    Nums.Counter private seasonMints;

    // category variables 
    struct Category{
        uint256[] _upgradesPerTier;
        uint256[] _avaliableTiers;
        string _categoryName;
    }

    // NFT variables
    struct NFTVars {
        uint256 _categoryID;
        uint256 _currentTier;
        uint256 _price;
        string _lat;
        string _lng;
        uint256 _mintIDX;
    }

    // an address for GEO$20 token
    address gToken;

    // an address for geosOracle
    address gOracle = 0x85DA2B76976Bf31103256a92c14f4398CeaB0541;

    // the USDT address in `MATIC`
    address public constant USDTToken = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;

    string private _baseURL;

    string private baseExtension = ".json";


    constructor(string memory generalURL) ERC1155(generalURL) {
        mintCounter.increment();
        catIdx.increment();

    }

    /**
     * @dev view functions are used extensivly 
     * in the onChain game, some redudency for different purposes is 
     * also necessary.
     * 
     *                          **View Functions**
     */
    // get the CategoryID from the category Name
    function getCategory(string memory _categoryName) public view returns(uint256 categoryID) {
        categoryID = 0;
        for (uint256 i=0; i< catIdx.current(); i++){
            if (GeoSpecial.compareStrings(_categoryName, _avalibleCategory[i]._categoryName)){
                categoryID = i;
                break;
            }
        }
    }    
    // get all the categories that are currently implemented
    function getAllCategories() external view returns(string[] memory){
        uint256 idx = 0;
        string[] memory _cats = new string[](catIdx.current());
        for (uint256 i=1; i<=catIdx.current(); i++){
            if (categoryExists(i)){
                _cats[idx] = _avalibleCategory[i]._categoryName;
                idx++;
            }
        }
        return _cats;
    }
    // check if a category exists
    function categoryExists(uint256 _category) public view returns(bool){

        return(_avalibleCategory[_category]._avaliableTiers.length > 0);
    }
    // get the category name by querying the category ID
    function getCategoryName(uint256 _categoryID) external view returns(string memory){

        return(_avalibleCategory[_categoryID]._categoryName);
    } 
    // get the current avaliable tiers for the category ID
    function getAvaliableTiers(uint256 _categoryID) public view returns(uint256[] memory){

        return(_avalibleCategory[_categoryID]._avaliableTiers);
    }
    // get the tier prices for the avaliable tiers for the category ID
    function getTierPrices(uint256 _categoryID) public view returns(uint256[] memory){

        return(_avalibleCategory[_categoryID]._upgradesPerTier);
    }
    // get the token id from the common string
    function getTokenId(string memory _mintString) external view returns(uint256 _mintIndex){
        _mintIndex = _avalMints[_mintString]._mintIDX;
        if (_mintIndex != 0){
            return(_mintIndex);
        }
        revert("This token is not avaliable");
    }
    // get the minted token variables
    function getTokenVars(uint256 _tokenID) public view returns(NFTVars memory _out){
        _out = _avalMints[_mintIDs[_tokenID]];
        if(_out._categoryID != 0 && _out._mintIDX != 0){
            return(_out);
        }
        revert("This NFT doesn't exist");
    }    
    // get the reference string from the token id
    function getMintingString(uint256 _tokenID) external view returns(string memory){

       return(_mintIDs[_tokenID]);
    }
    // get how many NFTs exist in a wallet
    function getNumOfNFTs(address _wallet) public view returns(uint256 _len){
        for (uint256 i=1; i<=mintCounter.current(); i++){
            if (balanceOf(_wallet, i) > 0){
                _len += 1;
            }
        }
        return _len;
    }
    // get the NFT ids of a particular wallet
    function getWalletNFTs(address _wallet) external view returns(uint256[] memory){
        uint256 _len = getNumOfNFTs(_wallet);
        uint256[] memory _wNFTs = new uint256[](_len);
        uint256 idx = 0;
        for (uint256 i=1; i<=mintCounter.current(); i++){
            if (balanceOf(_wallet, i) > 0){
                _wNFTs[idx] = i;
                idx++;
            }
        }
        return _wNFTs;
    }
    // get the nft variables using the nft common string
    function getNFTVars(string memory _mintString) public view returns(NFTVars memory _out){
        _out = _avalMints[_mintString];
        if (_out._categoryID == 0){
            revert("This NFT doesn't exist");
        }else if (_out._mintIDX != 0){
            revert("This NFT has already been minted");
        }else if (!categoryExists(_out._categoryID)){
            revert("This category doesn't exist");
        }
    }
    // get the current nft props from the common string
    function deserilazeNFTProps(string memory _mintString) public pure returns(NFTVars memory _out){
        (uint256 cat, uint256 tier, uint256 _price, string memory lat, string memory lng) = GeoSpecial.doAll(_mintString);
        _out = NFTVars(cat, tier, (_price*(10**6)), lat, lng, 0);
    }
    // get the current tier for the NFT
    function getNFTTier(uint256 _tokenID) external view returns(uint256){

        return(_avalMints[_mintIDs[_tokenID]]._currentTier);
    }
    // returns the current price of matic from a usdt value
    function oracleUSDTcalc(uint256 _humanUSDT) public view returns(uint256){

        return(_humanUSDT*(10**18)/ GeosOracle(gOracle).getExchangeRate("WMATIC"));
    }
    // calculate how much it will cost to upgrade from the current tier to the next tier
    function calcUpgradeCost(uint256 _category, uint256 _currentTier, uint256 _nextTier) public view returns(uint256) {
        if (_currentTier >= _nextTier){
            revert("This NFT has the same or greater tier than requested");
        }
        Category memory category = _avalibleCategory[_category];
        uint256 _avalLen = category._avaliableTiers.length;
        // since it's sequential no need to worry, this is sufficent
        require(_nextTier <= category._avaliableTiers[_avalLen-1],"This tier does not exist");

        uint256 upgradeCost = 0;
        
        for(uint256 i=0; i< _avalLen; i++){
            if (category._avaliableTiers[i] <= _nextTier && category._avaliableTiers[i] > _currentTier){
                upgradeCost += category._upgradesPerTier[i];
            }
        }
        uint256 _fUpgrade = upgradeCost*upgradePrice;
        if (_fUpgrade > 0){
            return(_fUpgrade);
        }else{
            revert("Cannot Upgrade");
        }
    }
    // check if an address is whitelisted to be in the NFT presale
    function isWhitelisted(address _wallet) public view returns(bool) {

        return(privateNFTSale[getKec(_wallet)]);
    }

    /**
     * @dev public payable functions in a way or another
     * either by `ETH` transfer using payable or ERC20 `transfer` || `transferFrom`
     * all calls to `transferFrom` has an `allowance` check instead of optmisitc transfers with 
     * a revert call.
     * 
     *                          **PAYABLE FUNCTIONS**
     */

    // upgrade the current NFT using the tokenID
    function upgradeNFT(uint256 _tokenID, uint256 _newTier) external nonReentrant {
        require(allowNFTSales, "NFT upgrades are currently not allowed");
        require(balanceOf(msg.sender, _tokenID) > 0, "Need To be the owner to upgrade the NFT");
        NFTVars memory _nft = getTokenVars(_tokenID);
        checkGeosPayment(msg.sender, calcUpgradeCost(_nft._categoryID, _nft._currentTier, _newTier));
        changeNFTTier(_tokenID, _newTier);
        emit GeoUpgrade(_nft._categoryID, _nft._currentTier, _newTier, msg.sender);
    }
    // a generic function for minting NFTs
    function geoMint(string memory _props, address _to) external payable nonReentrant{
        require(allowNFTSales || (privateSaleLive && isWhitelisted(msg.sender)), "NFT sales are currently not allowed");
        NFTVars memory _nft = getNFTVars(_props);
        if(msg.sender == owner()){
            require(oMints.current() < ownerNFTCap, "GeoPoly: Owner cannot mint anymore");
            oMints.increment();
        }else{
            require(checkPayment(msg.sender, uint256(msg.value), _nft._price), "Payment is required to mint an NFT");
        }
        genericMint(_props, _to);
    }
    // Reserve an NFT 
    function reserveNFT(string memory _props, address _to) external payable nonReentrant{
       require(allowNFTSales, "NFT reservations are currently not allowed");
       require(categoryExists(deserilazeNFTProps(_props)._categoryID));
       require(_reservedNFTs.length <= reservedCap,"Maximum limit for reservations, try later");
       require(checkPayment(msg.sender, uint256(msg.value), deserilazeNFTProps(_props)._price), "Payment is required to reserve an NFT");
       require(_resNFTs[_props] == address(0), "This NFT has already been reserved");
       if(_avalMints[_props]._categoryID != 0){
           if (_avalMints[_props]._mintIDX == 0){
               revert("This NFT is avaliable, mint it before it's gone.");
           }
           revert("This NFT has already been minted");
        }

        _resNFTs[_props] = _to;
        _reservedNFTs.push(_props);
        emit ReserveMint(_props, _to);
    }

    /**
     * @dev internal functions, different use cases for different
     * implementations, the ERC1155 standard `_mint` is not of much use
     * without wrappers for different functionality, i.e resevingNFTs 
     * most internal functions handle calls that are exposed by the payable
     * functions.
     * 
     *                          **INTERNAL FUNCTIONS**
     */
    // get the keccak256() to check in whitelist mapping
    function getKec(address _wallet) internal view returns(bytes32) {

        return(keccak256(abi.encodePacked(_wallet, privateNFTSaleVersion)));
    }
    // change the NFT tier
    function changeNFTTier(uint256 _tokenID, uint256 _newTier) internal {

        _avalMints[_mintIDs[_tokenID]]._currentTier = _newTier;
    }
    // check if a payment was made, either in USDT or MATIC
    function checkPayment(address _sender, uint256 _senderMsgVal, uint256 _priceUSDT) internal returns(bool) {
        if(_senderMsgVal >= oracleUSDTcalc(_priceUSDT)){
            return true;
        } else if (GEOS20(USDTToken).allowance(_sender, address(this)) >= _priceUSDT){
            if(GEOS20(USDTToken).transferFrom(_sender, address(this), _priceUSDT)){
                return true;
            }
            return false;
        }
        return false;
    }
    // check if payment was done in GEOS
    function checkGeosPayment(address _sender, uint256 _amount) internal returns(bool){
        require(GEOS20(gToken).allowance(_sender, address(this)) >= _amount, "You need to allow us to spend your GEO$ for upgrades");
        require(GEOS20(gToken).transferFrom(_sender, address(this), _amount),"You have to pay to upgrade your NFT");
        return true;
    }
    // add a mint using batches, using a single addition
    function addMint(string memory _gpMint) internal returns(bool){
        if(_avalMints[_gpMint]._categoryID != 0){
            revert("This NFT has already been added");
        }
        _avalMints[_gpMint] = deserilazeNFTProps(_gpMint);
        return(true);
    }
    // genericMint 
    function genericMint(string memory _props, address _to) internal {
        mintCounter.increment();
        uint256 nftMintIdx = mintCounter.current();
        _avalMints[_props] = deserilazeNFTProps(_props);
        _avalMints[_props]._mintIDX = nftMintIdx;
        _mint(_to, nftMintIdx, 1 ,"");
        _mintIDs[nftMintIdx] = _props;
        emit GeoMint(_props, _to);
    }

    /**
     * @dev admin functions are the heart and soul of this contract
     * in terms of continuity in development. these functions are linked
     * to services on servers that will call different functionalities in
     * cronjobs to ensure smooth and realistic gameplay. owner is also an admin
     * keeping in mind that many of these functions grow the game,
     * i.e adding new categories&tiers.
     * 
     *                            **ADMIN FUNCTIONS**
     */

    // get all the currently reserved NFTs
    function getReservedNFTs() external view isAdmin returns(string[] memory, address[] memory) {
        address[] memory _reservedAddresses = new address[](_reservedNFTs.length);
        for (uint256 i=0; i<_reservedNFTs.length; i++){
            _reservedAddresses[i] = _resNFTs[_reservedNFTs[i]];
        }
        return(_reservedNFTs, _reservedAddresses);
    }
    // add a new category
    function addCategory(string memory _categoryNew,uint256[] memory _tiersUpgrades, uint256[] memory _tiersAva) external isAdmin returns (bool){
        if (getCategory(_categoryNew) != 0){
            revert("This category already exists");
        }
        uint256 _categoryID = catIdx.current();
        _avalibleCategory[_categoryID] = Category(_tiersUpgrades, _tiersAva, _categoryNew);
        catIdx.increment();
        return(true);
    }
    // add a new tier for the categoryID and update the price of the new tier
    function addTier(uint256 _categoryID, uint256 _tierNew, uint256 _tierPrice) external isAdmin {
        uint256[] memory _tiersAval = getAvaliableTiers(_categoryID);
        uint256[] memory _tiersUpg = getTierPrices(_categoryID);
        uint256 tiersLen = _tiersAval.length;
        uint256[] memory _newTiers = new uint256[](tiersLen+1);
        uint256[] memory _newTierPrices = new uint256[](tiersLen+1);
        for(uint256 i=0; i < tiersLen; i++){
            _newTiers[i] = _tiersAval[i];
            _newTierPrices[i] = _tiersUpg[i];
        }
        _newTiers[tiersLen] = _tierNew;
        _newTierPrices[tiersLen] = _tierPrice;
        _avalibleCategory[_categoryID]._avaliableTiers = _newTiers;
        _avalibleCategory[_categoryID]._upgradesPerTier = _newTierPrices;
    }
    // change the tier price for a particular category
    function changeUpgradePerTier(uint256 _categoryID, uint256 _tierIdx, uint256 _upgrades) external isAdmin{

        _avalibleCategory[_categoryID]._upgradesPerTier[_tierIdx] = _upgrades;
    }
    // set the general upgrade price
    function changeUpgradePrice(uint256 _price) external isAdmin {

        upgradePrice = _price;
    }
    // pause the NFT sales
    function nftSalePaused(bool _state) external isAdmin  {

        allowNFTSales = _state;
    }
    // pause the private sale
    function pausePrivatePresale(bool _state) external isAdmin  {

        privateSaleLive = _state;
    }
    // change the season
    function changeSeason(uint256 _seasonNum, uint256 _nftsPer) external isAdmin  {
        seasonNum = _seasonNum;
        nftsPerSeason = _nftsPer;
        oMints.reset();
        seasonMints.reset();
    }
    // mint all reserved nfts to their respective owners
    function mintReserved() external isAdmin {
        if (_reservedNFTs.length != 0){
            for (uint256 i=0; i< _reservedNFTs.length; i++){
                genericMint(_reservedNFTs[i], _resNFTs[_reservedNFTs[i]]);
            }
            delete _reservedNFTs;
        }
    }
    // add new mints by batches
    function addToMints(string[] memory _newMints) external isAdmin {
        for (uint256 i=0; i<_newMints.length; i++){
            addMint(_newMints[i]);
        }
    }
    // set a new array for reserved NFTs
    function resetReservedNFTs(string[] memory _nfts, address[] memory _reservations) external isAdmin {
        require(_nfts.length == _reservations.length, "NFTs and RESERVATIONs needs to be the same length");
        _reservedNFTs = _nfts;
        // check if we should refund wrong NFTs;
        for(uint256 i=0; i<_nfts.length; i++){
            _resNFTs[_nfts[i]] = _reservations[i];
        }
    }
    // add addresses to whitelisting
    function addToWhitelist(address _wallet) external isAdmin {
    
        privateNFTSale[getKec(_wallet)] = true;
    }
    // remove address from whitelisting
    function removeFromWhitelist(address _wallet) external isAdmin {

        privateNFTSale[getKec(_wallet)] = false;
    }
    // add batch addresses to whitelisting
    function addBatchWhitelist(address[] calldata _wallets) external isAdmin {

        for(uint256 i=0; i<_wallets.length; i++){
            privateNFTSale[getKec(_wallets[i])] = true;
        }
    }
    // incrementing the private presale version will render old addresses `false`
    function nextPrivateSaleV() external isAdmin {

        privateNFTSaleVersion++;
    }

    function setBaseURL(string memory _nURL) external isAdmin {
        _baseURL = _nURL;
    }

    function setBaseExtention(string memory _nEXT) external isAdmin {
        baseExtension = _nEXT;
    }

    //get the specific tokenURI from the tokenID
    function tokenURI(uint256 tokenId) external view returns(string memory){
        NFTVars memory _vars = getTokenVars(tokenId);
        uint256 _mintIDX = _vars._mintIDX;
        string memory currentBaseURI = _baseURL;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, GeoSpecial.toString(_mintIDX), baseExtension))
                : "";
    }
    /**
     * @dev owner functions are mostly CFO&CEO responsibilities 
     * such as token withdrawal and managment of the external 
     * contract addresses in terms of GEO$ token or Geos Oracle,
     * adding and removing admins.
     *
     *                      **OWNER FUNCTIONS**
     */

    // set the address of GEOS token
    function setGeosToken(address _geo20) external onlyOwner {

        gToken = _geo20;
    }
    // set a new oracle address
    function setgOracle(address _newGOracle) external onlyOwner {

        gOracle = _newGOracle;
    }
    // withdraw all matic avaliable
    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount,"Not enough balance to withdraw this much");
        require(payable(msg.sender).send(amount), "cannot process withdrawal");
    }
    // withdraw an amount of GEOS which is avaliable
    function withdrawGeos(uint256 amount) external onlyOwner {

        require(GEOS20(gToken).transfer(msg.sender, amount));
    }
    // withdraw an amount of USDT which is avaliable (6 decimals)
    function withdrawUSDT(uint256 amount) external onlyOwner {

        require(GEOS20(USDTToken).transfer(msg.sender, amount));
    }
    // withdraw any other token addresses safekeeping
    function withdrawTokens(address tokenAddr) external onlyOwner {

        require(GEOS20(tokenAddr).transfer(msg.sender, GEOS20(tokenAddr).balanceOf(address(this))));
    }
    // withdraw `MATIC`&`GEOS`&`USDT` in one function
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
        require(GEOS20(gToken).transfer(msg.sender, GEOS20(gToken).balanceOf(address(this))));
        require(GEOS20(USDTToken).transfer(msg.sender, GEOS20(USDTToken).balanceOf(address(this))));
    }
}