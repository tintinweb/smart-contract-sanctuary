/**
 *Submitted for verification at polygonscan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

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


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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



pragma solidity ^0.8.0;

interface IVelhallaComic {

    function redeembyChapter(address _from, uint256 _chapterNo, uint256 _amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

// File: contracts/VelhallaRedeemS1.sol


pragma solidity ^0.8.0;



contract VelhallaCardRedeem is ERC1155Supply, Ownable {
    using Strings for uint256;

    string public constant name = "VC";
    string public constant symbol = "VHC";
//    string public goldCardURI;
    string public goldCardExtension = ".json";

// total id number = totalSeriesNumber*chapterNumberPerSeries*pageNumberPerChapter
// page start from id=1, not id=0 

//	uint256 public totalSeriesNumber = 1;
	uint256 public chapterNumberPerSeries = 5;
	uint256 public pageNumberPerChapter = 5;
	uint256 public totalSilverCardCopy = 500;
    uint256 public maxGoldCardCopy = 500;
//	uint256 public latestRevealChapter = 0;
	uint256 public latestRevealCard = 0;
    uint256 public unitPrice = 1 ether;  //1 SCAR to redeem card
    uint256 idGoldCardNFTIndex = 1000000;
    uint256 public ID_GOLD_CARD_START = 1000000;
    uint256 public TOTAL_GOLD_CARD_COPY = 500;

    uint32 public publicSilverRedeemStart = 1639702800;
    uint32 public publicGoldRedeemStart = 1639702800;

//    uint32 public publicSaleMaxPerAddress = 5;

    bool public silverPaused = true;
    bool public goldPaused = true;
//    bool public revealed = false;
    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;

    // Track mint tokens within a address
    // IMPORTANT: The format of the mapping is:
    // tokensMintedByAddress[tokenId][account][count]
//    mapping(uint256 => mapping(address => uint256)) private tokensMintedByAddress;
    mapping(uint256 => string) private tokenURI;
    mapping(uint256 => uint256) public maxSilverCardCopy;

    // a mapping from an address to whether or not it can mint / burn
//    mapping(address => bool) controllers;

    IVelhallaComic public comicContract;
    IERC20 public tokenContract;

    constructor() ERC1155("") {}


// internal


// public

    function claimSilverCardByChapter(uint256 _chapter, uint256 _amount) public returns (bool) {
        require((!silverPaused)&&(publicSilverRedeemStart <= block.timestamp), "the redeem for Silver Card is paused");
        require(_chapter <= latestRevealCard , "need to redeem under revealed chapters");

        uint256 idtemp;
        uint256 idpagetemp;
        uint256 amount;

        idtemp = _chapter; //Chapter Number from 1 to many
        require(totalSupply(idtemp) < maxSilverCardCopy[idtemp], "max redeem of Silver Card exceed");
        amount = _amount;

        for (uint32 i = 0; i < pageNumberPerChapter; i++ ){
            idpagetemp = (idtemp - 1)* pageNumberPerChapter + i + 1;
            require(comicContract.balanceOf(msg.sender, idpagetemp) >= amount, "require enough pages to redeem for this chapter");
        }

//        require(tokenContract.allowance(msg.sender, address(this)) >= unitPrice, "allowance too low");
        comicContract.redeembyChapter(msg.sender, idtemp, amount);
//        _safeTransferFrom(tokenContract, msg.sender, address(this), unitPrice);

        _mint(msg.sender, idtemp, amount, ""); 

        return true;
	}

    function claimSilverCardBySeries(uint256 _series, uint256 _amount) public returns (bool) {
        require((!silverPaused)&&(publicSilverRedeemStart <= block.timestamp), "the redeem for Silver Card is paused");
        require((_series * chapterNumberPerSeries) <= latestRevealCard , "need to redeem under all revealed chapter of the Series");
	    uint256[] memory ids = new uint256[](uint256(chapterNumberPerSeries));
        uint256[] memory amounts = new uint256[](uint256(chapterNumberPerSeries));   
        uint256 idstart;
        uint256 idpagetemp;
        uint256 idtemp;	
        uint256 amount;

        idstart = (_series - 1) * chapterNumberPerSeries;	
        amount = _amount;
		for (uint32 i = 0; i < chapterNumberPerSeries; i++) {
            idtemp =  idstart + i + 1; //chapter 1
            require(totalSupply(idtemp) < maxSilverCardCopy[idtemp], "max redeem of Silver Card exceed");

            for (uint32 j = 0; j < pageNumberPerChapter; j++ ){
                idpagetemp = (idtemp - 1)* pageNumberPerChapter + j + 1;
                require(comicContract.balanceOf(msg.sender, idpagetemp) >= amount, "require enough page to redeem for this chapter");
            }
		
            comicContract.redeembyChapter(msg.sender, idtemp, amount); 
            ids[i] =  idtemp;		    
            amounts[i] = amount; //1 copy of Card
		}

        _mintBatch(msg.sender, ids, amounts, ""); 		

//        require(tokenContract.allowance(msg.sender, address(this)) >= unitPrice, "allowance too low");
//        _safeTransferFrom(tokenContract, msg.sender, address(this), unitPrice);
        return true;

	}

    function checkSilverCardRedeemAvailable (uint256 _series, uint256 _chapter) external view returns (uint256) {
        uint256 idstart;
		uint256 idpagetemp;
        uint256 minavailablepagenumbers = totalSilverCardCopy;

        idstart = (_series - 1) * chapterNumberPerSeries + _chapter;	
		for (uint32 i = 0; i < pageNumberPerChapter; i++) {

            idpagetemp = (idstart - 1)* pageNumberPerChapter + i + 1;

            if (minavailablepagenumbers >= comicContract.balanceOf(msg.sender, idpagetemp))
			{
                minavailablepagenumbers = comicContract.balanceOf(msg.sender, idpagetemp);
			}
		}

        return minavailablepagenumbers;
	}


    function claimSilverCardwithOneClick() public returns (uint256[] memory) {
        require((!silverPaused)&&(publicSilverRedeemStart <= block.timestamp), "the redeem for Silver Card is paused");
    //    require((_series * chapterNumberPerSerie) <= latestRevealCard , "need to redeem under all revealed chapter of the Series");
//        uint256[] memory ids = new uint256[](uint256(chapterNumberPerSeries));
//        uint256[] memory amounts = new uint256[](uint256(chapterNumberPerSeries));   
        uint256[] memory minavailablepagenumbers = new uint256[](uint256(latestRevealCard));

        uint256 idstart;
        uint256 idpagetemp;
        uint256 idtemp;	

        idstart = 0;
		for (uint32 i = 0; i < latestRevealCard; i++) {
            idtemp =  idstart + i + 1; //chapter 1
            require(totalSupply(idtemp) < maxSilverCardCopy[idtemp], "max redeem of Silver Card exceed");

            minavailablepagenumbers[i] = totalSilverCardCopy ;
            for (uint32 j = 0; j < pageNumberPerChapter; j++ ){
                idpagetemp = (idtemp - 1)* pageNumberPerChapter + j + 1;
//                require(comicContract.balanceOf(msg.sender, idpagetemp) > 0, "require at least 1 page for this chapter");
                if (minavailablepagenumbers[i] >= comicContract.balanceOf(msg.sender, idpagetemp))
			    {
                    minavailablepagenumbers[i] = comicContract.balanceOf(msg.sender, idpagetemp);
			    }
            }	

            if (minavailablepagenumbers[i] !=0 ) {
                comicContract.redeembyChapter(msg.sender, idtemp, minavailablepagenumbers[i]); 
//                ids.push(idtemp);		    
//                amounts.push(minavailablepagenumbers[i]);		
                _mint(msg.sender, idtemp, minavailablepagenumbers[i], "");
            }
        }
//        _mintBatch(msg.sender, ids, amounts, ""); 

//        require(tokenContract.allowance(msg.sender, address(this)) >= unitPrice, "allowance too low");
//        _safeTransferFrom(tokenContract, msg.sender, address(this), unitPrice);
        return minavailablepagenumbers;

	}

    function claimGoldCard(uint256 _series, uint256 _amount) public returns (bool) {
        require((!goldPaused)&&(publicGoldRedeemStart <= block.timestamp), "the redeem for Gold Card is paused");
        require(_series <= ((idGoldCardNFTIndex+TOTAL_GOLD_CARD_COPY-ID_GOLD_CARD_START)/TOTAL_GOLD_CARD_COPY), "need to redeem under revealed series");
        require((idGoldCardNFTIndex-ID_GOLD_CARD_START) < TOTAL_GOLD_CARD_COPY,  "max redeem of Gold Card under revealed series exceeded"); 
	    uint256[] memory ids = new uint256[](uint256(chapterNumberPerSeries));
	    uint256[] memory idredeems = new uint256[](uint256(chapterNumberPerSeries)); //for redeemed silver card
        uint256[] memory amounts = new uint256[](uint256(chapterNumberPerSeries));   
        uint256 idstart;
        uint256 idtemp;	
        uint256 idredeemtemp; 
        uint256 amount;

        idstart = (_series - 1) * chapterNumberPerSeries;	
        amount = _amount;
		for (uint32 i = 0; i < chapterNumberPerSeries; i++) {
            idtemp =  idstart + i + 1; //chapter 1
            idredeemtemp = idtemp + 100000000;
            require(balanceOf(msg.sender, idtemp) >= amount , "require enough silver cards to redeem");
            require(maxSilverCardCopy[(idstart + i + 1)] >=amount, "not enough silver card numbers remains" );
            ids[i] =  idtemp;		    
            idredeems[i] =  idredeemtemp;
            amounts[i] = amount; //copies of Card
		}

//        require(tokenContract.allowance(msg.sender, address(this)) >= unitPrice, "allowance too low");
		
        _burnBatch(msg.sender, ids, amounts);
        _mintBatch(msg.sender, idredeems, amounts, "");
        for (uint32 j = 0; j < chapterNumberPerSeries; j++) {
            maxSilverCardCopy[(idstart + j + 1)] -= amount ;
        }

        for (uint32 k = 0; k < amount; k++) {
		    idGoldCardNFTIndex = idGoldCardNFTIndex * _series + 1;
            _mint(msg.sender, idGoldCardNFTIndex, 1, "");
        }

//        _safeTransferFrom(tokenContract, msg.sender, address(this), unitPrice);
        return true;
	}

    function checkGoldCardRedeemAvailable (uint256 _series) external view returns (uint256) {

        uint256 idstart;
		uint256 idtemp;
        uint256 minavailablechaptercopys = totalSilverCardCopy;

        idstart = (_series - 1) * chapterNumberPerSeries;	
		for (uint32 i = 0; i < chapterNumberPerSeries; i++) {
            idtemp =  idstart + i + 1; //chapter 1

            if (minavailablechaptercopys >= balanceOf(msg.sender, idtemp))
			{
                minavailablechaptercopys = balanceOf(msg.sender, idtemp);
			}
		}

        return minavailablechaptercopys;
	}

	
    function claimGoldCardwithOneClick() public returns (uint256[] memory) {
        require((!goldPaused)&&(publicGoldRedeemStart <= block.timestamp), "the redeem for Gold Card is paused");

//        require(_series <= ((idGoldCardNFTIndex+TOTAL_GOLD_CARD_COPY-ID_GOLD_CARD_START)/TOTAL_GOLD_CARD_COPY), "need to redeem under revealed series");

        require((idGoldCardNFTIndex-ID_GOLD_CARD_START) < TOTAL_GOLD_CARD_COPY,  "max redeem of Gold Card under revealed series exceeded"); 

        uint256 series = latestRevealCard/chapterNumberPerSeries;
        uint256 idstart;
        uint256 idtemp;	
        uint256 idredeemtemp; 

        require(series > 0, "series not ready to redeem gold card");
	    uint256[] memory ids = new uint256[](uint256(chapterNumberPerSeries));
	    uint256[] memory idredeems = new uint256[](uint256(chapterNumberPerSeries)); //for redeemed silver card
        uint256[] memory amounts = new uint256[](uint256(chapterNumberPerSeries));   
        uint256[] memory minavailablechaptercopys = new uint256[](uint256(series));



        for (uint32 s = 0; s < series; s++) {
            idstart = s * chapterNumberPerSeries;	
            minavailablechaptercopys[s] = totalSilverCardCopy;
		    for (uint32 i = 0; i < chapterNumberPerSeries; i++) {
                idtemp =  idstart + i + 1; //chapter 1
//                idredeemtemp = idtemp + 100000000;
//                require(balanceOf(msg.sender, idtemp) > 0 , "require at least 1 silver card");
                if (minavailablechaptercopys[s] >= balanceOf(msg.sender, idtemp))
			    {
                    minavailablechaptercopys[s] = balanceOf(msg.sender, idtemp);
			    }
//                ids[i] =  idtemp;		    
//                idredeems[i] =  idredeemtemp;
		    }

//        require(tokenContract.allowance(msg.sender, address(this)) >= unitPrice, "allowance too low");

            if(minavailablechaptercopys[s] != 0){
		        for (uint32 j = 0; j < chapterNumberPerSeries; j++) {
                    idtemp =  idstart + j + 1; 
                    idredeemtemp = idtemp + 100000000;
                    ids[j] = idtemp;		    
                    idredeems[j] = idredeemtemp;				
                    amounts[j] = minavailablechaptercopys[s];
                }		
                _burnBatch(msg.sender, ids, amounts);
                _mintBatch(msg.sender, idredeems, amounts, "");
                for (uint32 k = 0; k < chapterNumberPerSeries; k++) {
                    require(maxSilverCardCopy[(idstart + k + 1)] > 0, "remain page numbers = 0" );
                    maxSilverCardCopy[(idstart + k + 1)] -= minavailablechaptercopys[s] ;
                }

                for (uint32 l = 0; l < minavailablechaptercopys[s]; l++) {
		            idGoldCardNFTIndex = idGoldCardNFTIndex * ( s + 1 ) + 1;
                    _mint(msg.sender, idGoldCardNFTIndex, 1, "");
                }
            }
//        _safeTransferFrom(tokenContract, msg.sender, address(this), unitPrice);
        }
        return minavailablechaptercopys;
	}	
	

    function publicSilverRedeemIsActive() public view returns (bool) {
        return ( (publicSilverRedeemStart <= block.timestamp) && (!silverPaused) );
    }

    function publicGoldRedeemIsActive() public view returns (bool) {
        return ( (publicGoldRedeemStart <= block.timestamp) && (!goldPaused) );
    }
	
    function uri(uint256 _id) public override view returns (string memory) {
        require(exists(_id), "URI: nonexistent token");
        uint256 tokenId;
        tokenId = _id;
        if (tokenId <= ID_GOLD_CARD_START)
        {
            return tokenURI[tokenId];
        }

        tokenId -= ID_GOLD_CARD_START;
        string memory currentBaseURI = tokenURI[ID_GOLD_CARD_START];
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), goldCardExtension))
            : "";

    }

/* //still buggy
    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = latestRevealPage;
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i ; i < ownerTokenCount; i++) {
            tokenIds[i] = balanceOf(_owner, i+1);
        }
        return tokenIds;
    }
*/

// private

    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }


// external

// only owner

    function setSilverCardURI(uint256 _id, string memory _uri) external onlyOwner {
		require(bytes(tokenURI[_id]).length != 0 , "only set URI to exist token id");
        tokenURI[_id] = _uri;
        emit URI(_uri, _id);
    }

    function initSilverCardURI(string memory _uri) external onlyOwner {
        uint256 _id = latestRevealCard + 1;
		require(bytes(tokenURI[_id]).length == 0 ,  "only init URI to new token id");
        
        tokenURI[_id] = _uri;
	    latestRevealCard = _id;  // page start from id=1, not id=0 
        maxSilverCardCopy[_id] = totalSilverCardCopy;
//        if(_id % pageNumberPerChapter == 0){
//		    latestRevealChapter = _id / pageNumberPerChapter;
//		}
        emit URI(_uri, _id);
    }

/* set for 721 token uri like */
    function initGoldCardURI(string memory _uri) external onlyOwner {
		require(bytes(tokenURI[ID_GOLD_CARD_START]).length == 0 ,  "only init URI to new token id");
        tokenURI[ID_GOLD_CARD_START] = _uri;
        emit URI(_uri, ID_GOLD_CARD_START);
    }

    function setGoldCardURI(string memory _uri) external onlyOwner {
		require(bytes(tokenURI[ID_GOLD_CARD_START]).length != 0 ,  "only init URI to new token id");
        tokenURI[ID_GOLD_CARD_START] = _uri;
        emit URI(_uri, ID_GOLD_CARD_START);
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function setPublicSilverRedeemStart(uint32 timestamp) public onlyOwner {
        publicSilverRedeemStart = timestamp;
    }
  
    function setPublicGoldRedeemStart(uint32 timestamp) public onlyOwner {
        publicGoldRedeemStart = timestamp;
    } 
 
    function setUnitPrice(uint256 _newCost) public onlyOwner {
        unitPrice = _newCost;
    }

    function setTotalSilverCardCopy(uint256 _totalCopy) public onlyOwner {
        totalSilverCardCopy = _totalCopy;
    }

    function setMaxSilverCardCopy(uint256 _maxCopy, uint256 _chapterNo) public onlyOwner {
        require(_chapterNo <= latestRevealCard, "chapter number out of range");
        maxSilverCardCopy[_chapterNo] = _maxCopy;
    }


    function setMaxGoldCardCopy(uint256 _maxCopy) public onlyOwner {
        maxGoldCardCopy = _maxCopy;
    }

    function setTotalGoldCardCopy(uint256 _number) public onlyOwner {
        TOTAL_GOLD_CARD_COPY = _number;
    }


    function pauseForSilverCardRedeem(bool _state) public onlyOwner {
        silverPaused = _state;
    }

    function pauseForGoldCardRedeem(bool _state) public onlyOwner {
        goldPaused = _state;
    }
  
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }
  
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    /**
     * enables an address to mint / burn
     * param controller the address to enable
     */
//    function addController(address controller) external onlyOwner {
//        controllers[controller] = true;
//    }

    /**
     * disables an address from minting / burning
     * param controller the address to disbale
     */
//    function removeController(address controller) external onlyOwner {
//        controllers[controller] = false;
//    }

    function setTokenContractAddress(address _tokenContract) external onlyOwner {
        tokenContract = IERC20(_tokenContract);
    }

    function setComicContractAddress(address _comicContract) external onlyOwner {
        comicContract = IVelhallaComic(_comicContract);
    }

    function setGoldCardExtension(string memory _newExtension) public onlyOwner {
        goldCardExtension = _newExtension;
    }


/* still buggy
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
*/

}