/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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


interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}





abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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


contract TimeartNFT is ERC1155 {
    string public constant WEBSITE ="https://timeart.co/";
    string public name="TIMEART";
    string public symbol="HubAuto Racing"; 
    
    struct NftInfo{
        string jsonCid;
    }
    mapping(uint256 => NftInfo) nftInfoList;
   
    constructor() ERC1155( "https://null/{id}.json") {
        
        nftInfoList[1] = NftInfo({jsonCid:"QmRT1UkPPDrAae335F11iyLdCsYZDHRvepXhJCYxNsy6W9"});
        nftInfoList[2] = NftInfo({jsonCid:"QmZzQYuuUAKdDtwKbGM7kkMzmeoFWd6jfrHCFiQRBfbUqg"});
        nftInfoList[3] = NftInfo({jsonCid:"QmeFqJxsQMeQuJCGyhk21LcA7VEkFJ1CXdjaid3esXn9Nb"});
        nftInfoList[4] = NftInfo({jsonCid:"QmRw4fM916aXSa6MWM8ZBSgQtarQkwtLcZ6U1CDziYks8L"});
        nftInfoList[5] = NftInfo({jsonCid:"Qmde1s5ZHHUPLQ6qcbGVTveHegWPirdG3GwXctHrchMkH3"});
        nftInfoList[6] = NftInfo({jsonCid:"QmYAcbjpsBtfw995Ct3JUFuNDKjgjNsSbgZRVsXfGw5QzR"});
        nftInfoList[7] = NftInfo({jsonCid:"QmPSJupWLmcwsiMnqR6yhgFp714BkCN7dz7fUYVdYvwUdt"});
        nftInfoList[8] = NftInfo({jsonCid:"QmSsqsmze2wE4Tzm2WwXkodwGoWobWquf9ykrkdRZpS6oa"});
        nftInfoList[9] = NftInfo({jsonCid:"QmUXxD8UF71DiicFQCQqkr91zeWzZHSvnbGtdVZa9DA8aH"});
        nftInfoList[10] = NftInfo({jsonCid:"QmVwDwQCA4W659uXcYdGspUfStzdu6QH9T8KsiffqQYtPt"});
        nftInfoList[11] = NftInfo({jsonCid:"QmRoTNhCFHB7Jfd7fzoGsifAfYHf9G7fMvcEneZnCaryLa"});
        nftInfoList[12] = NftInfo({jsonCid:"QmctPH4QN2fNcYVsBPNomtyji42LrDxRetTdnAJcVwoVyV"});
        nftInfoList[13] = NftInfo({jsonCid:"QmXeu2y9YFbJ1rU1e3TWyfLPJ4MUsPGZ59UHvrEXB46sfn"});
        nftInfoList[14] = NftInfo({jsonCid:"QmXRcM9h3iUmSUzGas8xAtsEAM5tYaKerTWN3NhvcSmZGf"});
        nftInfoList[15] = NftInfo({jsonCid:"QmYXTVZEgpT4KszRYi7oFAARtTxtocpnEYo1oz95qgD5id"});
        nftInfoList[16] = NftInfo({jsonCid:"QmUcmykyJ4bruT4ttp52bk6MphezM14LF2uju7oKkQu5q6"});
        nftInfoList[17] = NftInfo({jsonCid:"QmdoVXcUvEbjRp9B6oYLA8ZFHD35E8ZdSdfwEJcKTxUzE1"});
        nftInfoList[18] = NftInfo({jsonCid:"QmS1xkai85CrkhBqG1DaTze6n6BCfnr9xztnZrBBLCpQRS"});
        nftInfoList[19] = NftInfo({jsonCid:"QmejQYMT8e1cM12ikPD2fDUrjmNNHFVzMqJqdXKXV5az1w"});
        nftInfoList[20] = NftInfo({jsonCid:"QmWwbNQk5RAt9F5FqPc8818xqMu2Ux5mecbsw9BFsDPNLE"});
        nftInfoList[21] = NftInfo({jsonCid:"QmaHKAbyTWbCLkb95BWrdRznV7oP4dYWo7SsbaPDh17gVU"});
        nftInfoList[22] = NftInfo({jsonCid:"QmYi4iYXrb2h82APhFoDgxwskJVj7SMnGHs5ATwkwtxLwf"});
        nftInfoList[23] = NftInfo({jsonCid:"QmSnSUAgjq8CruuEbqXghqZcq1LDrRbnWXpMnZuto75c2k"});
        nftInfoList[24] = NftInfo({jsonCid:"QmaYgjdXGXCLQ9wdK1KLysqFBqu7bguXqPjXMPaDdZcAqM"});
        nftInfoList[25] = NftInfo({jsonCid:"QmYc76cBAQR7cB35G4tD63fsb3v2Ao8Pd16n28gGGb5orP"});
        nftInfoList[26] = NftInfo({jsonCid:"QmWtyX4LLmMzMLvzoFNXJqDfVmaPmAzhYm3iugty67myBQ"});
        nftInfoList[27] = NftInfo({jsonCid:"Qmdejdsp58thxTC1YLYcpAEB2tn6JN54Rhzs9xnJomqCho"});
        nftInfoList[28] = NftInfo({jsonCid:"QmSZVBEdDJkLrNhecvmFgqg574vBWLkavS5Ln8JNejTHrP"});
        nftInfoList[29] = NftInfo({jsonCid:"QmfEU7DtF1pdP5rWzoSsELwsuESSTRVVyBeUFRPEZSTfJf"});
        nftInfoList[30] = NftInfo({jsonCid:"QmZmzK26Km19cDBpK1vyejqUoU6PXHqRCjp7RfMNoM5vt6"});
        nftInfoList[31] = NftInfo({jsonCid:"QmNxizhwPcXnfHZPrxeyPusUp3F3DPQieiDhg9W2BxPhqY"});
 
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,1,2,"");
        _mint(0xeB0B4552E4ad469e01b6161472b85b0447554582,1,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,1,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,1,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,1,34,"");
        _mint(0xEAa2FE51bff163E97984d9386D924ab96336aB14,2,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,2,2,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,2,12,"");
        _mint(0x911E2C579fb81444036aF62280B83d161c91Ad26,3,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,3,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,3,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,3,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,3,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,4,5,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,4,5,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,4,30,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,5,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,5,2,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,5,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,5,11,"");
        _mint(0x5e88aB59f5f8b75cB39766E3B70B549bE9bA1c8E,6,1,"");
        _mint(0x7B26297c3d1c89697cb93812edEAd6E443e052BA,6,1,"");
        _mint(0xD035fA308469aFD2352393CF3Fa54Fc829647Cd8,6,1,"");
        _mint(0xFB0df28c50D0C9C6aB4FF6F5d0092D09bD8164ad,6,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,6,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,7,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,7,2,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,7,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,7,16,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,8,2,"");
        _mint(0x3086746Cf567157ED1c7fDCAf7Ea5b174305b166,8,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,8,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,8,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,8,10,"");
        _mint(0xB224B133E1f43931484Ad820fF3EdAa55e479A22,9,1,"");
        _mint(0xEaf9681470A98B25bDEAf3752E4671372d558173,9,1,"");
        _mint(0x3AcCd34Cd9096ca3E3707Ea43e3dDAd38402fdcd,9,1,"");
        _mint(0xFB0df28c50D0C9C6aB4FF6F5d0092D09bD8164ad,9,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,9,6,"");
        _mint(0x3086746Cf567157ED1c7fDCAf7Ea5b174305b166,10,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,10,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,10,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,10,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,10,6,"");
        _mint(0xD6bf1A7926f8fAAc7e39100D04A901243eA9ccF7,11,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,11,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,11,2,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,11,11,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,12,1,"");
        _mint(0x3Dc9cD23Ec937d36BB70823E21fd65795C9Cf412,12,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,12,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,12,12,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,13,1,"");
        _mint(0xD6bf1A7926f8fAAc7e39100D04A901243eA9ccF7,13,1,"");
        _mint(0x9aeD1548337949AcD4f3b0d61F7E3f6ae3E8Dc7A,13,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,13,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,13,11,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,14,1,"");
        _mint(0x911E2C579fb81444036aF62280B83d161c91Ad26,14,1,"");
        _mint(0xeB0B4552E4ad469e01b6161472b85b0447554582,14,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,14,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,14,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,14,5,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,15,2,"");
        _mint(0x4d014b7Fde1277b46A3d22c5DD8e9686ffc44EDf,15,1,"");
        _mint(0xE3aAC873c96E1ad87022590b53B7aCF7A99AD182,15,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,15,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,15,10,"");
        _mint(0xB6DEF4D80d7bAae5012245AE616EF32d0C31160b,16,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,16,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,16,13,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,17,5,"");
        _mint(0xB6DEF4D80d7bAae5012245AE616EF32d0C31160b,17,1,"");
        _mint(0x502A7911411A4327f04C42418b3a161593D2546d,17,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,17,2,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,17,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,17,30,"");
        _mint(0x911E2C579fb81444036aF62280B83d161c91Ad26,18,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,18,1,"");
        _mint(0xB224B133E1f43931484Ad820fF3EdAa55e479A22,18,1,"");
        _mint(0xD24D0055cE145D580F6fA8682814B31Aad0Caf47,18,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,18,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,19,1,"");
        _mint(0xB6DEF4D80d7bAae5012245AE616EF32d0C31160b,19,1,"");
        _mint(0x5f7eFD589a48D86cf707DCc7CF2abbb0a76427A4,19,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,19,12,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,20,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,20,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,20,3,"");
        _mint(0x5e88aB59f5f8b75cB39766E3B70B549bE9bA1c8E,21,1,"");
        _mint(0xbb9BF1dc59D6e474f85e965C65b663Aa5c2d8029,21,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,21,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,21,12,"");
        _mint(0x883B5D54bE575f650a597415b19eCE50cb2d6DA5,22,1,"");
        _mint(0x4D17D4A93F12482B75f46fc4Cc7e407835de2696,22,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,22,1,"");
        _mint(0xD6bf1A7926f8fAAc7e39100D04A901243eA9ccF7,22,1,"");
        _mint(0xFB0df28c50D0C9C6aB4FF6F5d0092D09bD8164ad,22,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,22,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,22,9,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,23,3,"");
        _mint(0x9670d0B0158e11281a921B34bCA75105d4764C53,23,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,23,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,23,10,"");
        _mint(0x902E591eb4f328465B92080A6F4504A59b7Bf09f,24,1,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,24,2,"");
        _mint(0xB6DEF4D80d7bAae5012245AE616EF32d0C31160b,24,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,24,11,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,25,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,25,14,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,26,2,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,26,2,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,26,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,26,5,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,27,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,27,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,27,13,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,28,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,28,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,28,13,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,29,4,"");
        _mint(0x9aeD1548337949AcD4f3b0d61F7E3f6ae3E8Dc7A,29,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,29,2,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,29,2,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,29,31,"");
        _mint(0xA25f06b190A5C8D202Bd7411686e5595749fc5e6,30,1,"");
        _mint(0xFB0df28c50D0C9C6aB4FF6F5d0092D09bD8164ad,30,1,"");
        _mint(0x7564cDA45B0A2c64a4c695940B8078E24939A90b,30,1,"");
        _mint(0x7088E06A843378FBd93A5a8c53dCD63bF53999c6,30,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,30,1,"");
        _mint(0xD6bf1A7926f8fAAc7e39100D04A901243eA9ccF7,31,1,"");
        _mint(0xFB0df28c50D0C9C6aB4FF6F5d0092D09bD8164ad,31,1,"");
        _mint(0xa202C68862A19D43F681911A176d6e62A6419062,31,13,"");

    }
    
    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                "https://ipfs.io/ipfs/"
                ,nftInfoList[_tokenId].jsonCid
                ,"?filename=",
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }
    
}