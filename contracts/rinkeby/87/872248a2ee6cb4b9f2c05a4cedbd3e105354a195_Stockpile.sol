/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// hevm: flattened sources of src/Stockpile.sol
// SPDX-License-Identifier: MIT AND Unlicense AND GPL-3.0-or-later AND GPL-3.0
pragma solidity >=0.8.0 <0.9.0 >=0.8.4 <0.9.0 >=0.8.6 <0.9.0;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol

/* pragma solidity ^0.8.0; */

/* import "../IERC1155.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol

/* pragma solidity ^0.8.0; */

/* import "./IERC1155.sol"; */
/* import "./IERC1155Receiver.sol"; */
/* import "./extensions/IERC1155MetadataURI.sol"; */
/* import "../../utils/Address.sol"; */
/* import "../../utils/Context.sol"; */
/* import "../../utils/introspection/ERC165.sol"; */

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
    mapping(uint256 => mapping(address => uint256)) internal _balances;

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
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
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
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
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

////// lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

/* pragma solidity ^0.8.0; */

/* import "../../utils/introspection/IERC165.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/math/Math.sol

/* pragma solidity ^0.8.0; */

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Arrays.sol

/* pragma solidity ^0.8.0; */

/* import "./math/Math.sol"; */

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Counters.sol

/* pragma solidity ^0.8.0; */

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

////// src/MetadataUtils.sol
/* pragma solidity ^0.8.0; */

function toString(uint256 value) pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

////// src/Components.sol

/*

    Components.sol
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), clothesComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint8[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.

*/

/* pragma solidity ^0.8.4; */

/* import '@openzeppelin/contracts/access/Ownable.sol'; */

/* import { toString } from './MetadataUtils.sol'; */

library ComponentTypes {
    uint8 internal constant WEAPON = 0x0;
    uint8 internal constant CLOTHES = 0x1;
    uint8 internal constant VEHICLE = 0x2;
    uint8 internal constant WAIST = 0x3;
    uint8 internal constant FOOT = 0x4;
    uint8 internal constant HAND = 0x5;
    uint8 internal constant DRUGS = 0x6;
    uint8 internal constant NECK = 0x7;
    uint8 internal constant RING = 0x8;
    uint8 internal constant NAME_PREFIX = 0x9;
    uint8 internal constant NAME_SUFFIX = 0xa;
    uint8 internal constant SUFFIX = 0xb;
    uint8 internal constant SET = 0xc;
}

contract Components is Ownable {
    string constant UnexpectedComponent = 'unexpected component type';

    string[] internal slots = ['Weapon', 'Clothes', 'Vehicle', 'Waist', 'Foot', 'Hand', 'Drugs', 'Neck', 'Ring'];

    string[] public weapons = [
        'Pocket Knife', // 0
        'Chain', // 1
        'Knife', // 2
        'Crowbar', // 3
        'Handgun', // 4
        'AK47', // 5
        'Shovel', // 6
        'Baseball Bat', // 7
        'Tire Iron', // 8
        'Police Baton', // 9
        'Pepper Spray', // 10
        'Razor Blade', // 11
        'Chain', // 12
        'Taser', // 13
        'Brass Knuckles', // 14
        'Shotgun', // 15
        'Glock', // 16
        'Uzi' // 17
    ];
    uint256 private constant weaponsLength = 18;

    string[] public clothes = [
        'White T Shirt', // 0
        'Black T Shirt', // 1
        'White Hoodie', // 2
        'Black Hoodie', // 3
        'Bulletproof Vest', // 4
        '3 Piece Suit', // 5
        'Checkered Shirt', // 6
        'Bikini', // 7
        'Golden Shirt', // 8
        'Leather Vest', // 9
        'Blood Stained Shirt', // 10
        'Police Uniform', // 11
        'Combat Jacket', // 12
        'Basketball Jersey', // 13
        'Track Suit', // 14
        'Trenchcoat', // 15
        'White Tank Top', // 16
        'Black Tank Top', // 17
        'Shirtless', // 18
        'Naked' // 19
    ];
    uint256 private constant clothesLength = 20;

    string[] public vehicle = [
        'Dodge', // 0
        'Porsche', // 1
        'Tricycle', // 2
        'Scooter', // 3
        'ATV', // 4
        'Push Bike', // 5
        'Electric Scooter', // 6
        'Golf Cart', // 7
        'Chopper', // 8
        'Rollerblades', // 9
        'Lowrider', // 10
        'Camper', // 11
        'Rolls Royce', // 12
        'BMW M3', // 13
        'Bike', // 14
        'C63 AMG', // 15
        'G Wagon' // 16
    ];
    uint256 private constant vehicleLength = 17;

    string[] public waistArmor = [
        'Gucci Belt', // 0
        'Versace Belt', // 1
        'Studded Belt', // 2
        'Taser Holster', // 3
        'Concealed Holster', // 4
        'Diamond Belt', // 5
        'D Ring Belt', // 6
        'Suspenders', // 7
        'Military Belt', // 8
        'Metal Belt', // 9
        'Pistol Holster', // 10
        'SMG Holster', // 11
        'Knife Holster', // 12
        'Laces', // 13
        'Sash', // 14
        'Fanny Pack' // 15
    ];
    uint256 private constant waistLength = 16;

    string[] public footArmor = [
        'Black Air Force 1s', // 0
        'White Forces', // 1
        'Air Jordan 1 Chicagos', // 2
        'Gucci Tennis 84', // 3
        'Air Max 95', // 4
        'Timberlands', // 5
        'Reebok Classics', // 6
        'Flip Flops', // 7
        'Nike Cortez', // 8
        'Dress Shoes', // 9
        'Converse All Stars', // 10
        'White Slippers', // 11
        'Gucci Slides', // 12
        'Alligator Dress Shoes', // 13
        'Socks', // 14
        'Open Toe Sandals', // 15
        'Barefoot' // 16
    ];
    uint256 private constant footLength = 17;

    string[] public handArmor = [
        'Rubber Gloves', // 0
        'Baseball Gloves', // 1
        'Boxing Gloves', // 2
        'MMA Wraps', // 3
        'Winter Gloves', // 4
        'Nitrile Gloves', // 5
        'Studded Leather Gloves', // 6
        'Combat Gloves', // 7
        'Leather Gloves', // 8
        'White Gloves', // 9
        'Black Gloves', // 10
        'Kevlar Gloves', // 11
        'Surgical Gloves', // 12
        'Fingerless Gloves' // 13
    ];
    uint256 private constant handLength = 14;

    string[] public necklaces = [
        'Bronze Chain', // 0
        'Silver Chain', // 1
        'Gold Chain' // 2
    ];
    uint256 private constant necklacesLength = 3;

    string[] public rings = [
        'Gold Ring', // 0
        'Silver Ring', // 1
        'Diamond Ring', // 2
        'Platinum Ring', // 3
        'Titanium Ring', // 4
        'Pinky Ring', // 5
        'Thumb Ring' // 6
    ];
    uint256 private constant ringsLength = 7;

    string[] public drugs = [
        'Weed', // 0
        'Cocaine', // 1
        'Ludes', // 2
        'Acid', // 3
        'Speed', // 4
        'Heroin', // 5
        'Oxycontin', // 6
        'Zoloft', // 7
        'Fentanyl', // 8
        'Krokodil', // 9
        'Coke', // 10
        'Crack', // 11
        'PCP', // 12
        'LSD', // 13
        'Shrooms', // 14
        'Soma', // 15
        'Xanax', // 16
        'Molly', // 17
        'Adderall' // 18
    ];
    uint256 private constant drugsLength = 19;

    string[] public suffixes = [
        // <no suffix>          // 0
        'from the Bayou', // 1
        'from Atlanta', // 2
        'from Compton', // 3
        'from Oakland', // 4
        'from SOMA', // 5
        'from Hong Kong', // 6
        'from London', // 7
        'from Chicago', // 8
        'from Brooklyn', // 9
        'from Detroit', // 10
        'from Mob Town', // 11
        'from Murdertown', // 12
        'from Sin City', // 13
        'from Big Smoke', // 14
        'from the Backwoods', // 15
        'from the Big Easy', // 16
        'from Queens', // 17
        'from BedStuy', // 18
        'from Buffalo' // 19
    ];
    uint256 private constant suffixesLength = 19;

    string[] public namePrefixes = [
        // <no name>            // 0
        'OG', // 1
        'King of the Street', // 2
        'Cop Killer', // 3
        'Blasta', // 4
        'Lil', // 5
        'Big', // 6
        'Tiny', // 7
        'Playboi', // 8
        'Snitch boi', // 9
        'Kingpin', // 10
        'Father of the Game', // 11
        'Son of the Game', // 12
        'Loose Trigger Finger', // 13
        'Slum Prince', // 14
        'Corpse', // 15
        'Mother of the Game', // 16
        'Daughter of the Game', // 17
        'Slum Princess', // 18
        'Da', // 19
        'Notorious', // 20
        'The Boss of Bosses', // 21
        'The Dog Killer', // 22
        'The Killer of Dog Killer', // 23
        'Slum God', // 24
        'Candyman', // 25
        'Candywoman', // 26
        'The Butcher', // 27
        'Yung Capone', // 28
        'Yung Chapo', // 29
        'Yung Blanco', // 30
        'The Fixer', // 31
        'Jail Bird', // 32
        'Corner Cockatoo', // 33
        'Powder Prince', // 34
        'Hippie', // 35
        'John E. Dell', // 36
        'The Burning Man', // 37
        'The Burning Woman', // 38
        'Kid of the Game', // 39
        'Street Queen', // 40
        'The Killer of Dog Killers Killer', // 41
        'Slum General', // 42
        'Mafia Prince', // 43
        'Crooked Cop', // 44
        'Street Mayor', // 45
        'Undercover Cop', // 46
        'Oregano Farmer', // 47
        'Bloody', // 48
        'High on the Supply', // 49
        'The Orphan', // 50
        'The Orphan Maker', // 51
        'Ex Boxer', // 52
        'Ex Cop', // 53
        'Ex School Teacher', // 54
        'Ex Priest', // 55
        'Ex Engineer', // 56
        'Street Robinhood', // 57
        'Hell Bound', // 58
        'SoundCloud Rapper', // 59
        'Gang Leader', // 60
        'The CEO', // 61
        'The Freelance Pharmacist', // 62
        'Soccer Mom', // 63
        'Soccer Dad' // 64
    ];
    uint256 private constant namePrefixesLength = 64;

    string[] public nameSuffixes = [
        // <no name>            // 0
        'Feared', // 1
        'Baron', // 2
        'Vicious', // 3
        'Killer', // 4
        'Fugitive', // 5
        'Triggerman', // 6
        'Conman', // 7
        'Outlaw', // 8
        'Assassin', // 9
        'Shooter', // 10
        'Hitman', // 11
        'Bloodstained', // 12
        'Punishment', // 13
        'Sin', // 14
        'Smuggled', // 15
        'LastResort', // 16
        'Contraband', // 17
        'Illicit' // 18
    ];
    uint256 private constant nameSuffixesLength = 18;

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function seed(uint256 tokenId, uint8 componentType) public pure returns (uint256, uint256) {
        string memory keyPrefix;
        if (componentType == ComponentTypes.WEAPON) {
            keyPrefix = 'WEAPON';
        } else if (componentType == ComponentTypes.CLOTHES) {
            keyPrefix = 'CLOTHES';
        } else if (componentType == ComponentTypes.VEHICLE) {
            keyPrefix = 'VEHICLE';
        } else if (componentType == ComponentTypes.WAIST) {
            keyPrefix = 'WAIST';
        } else if (componentType == ComponentTypes.FOOT) {
            keyPrefix = 'FOOT';
        } else if (componentType == ComponentTypes.HAND) {
            keyPrefix = 'HAND';
        } else if (componentType == ComponentTypes.DRUGS) {
            keyPrefix = 'DRUGS';
        } else if (componentType == ComponentTypes.NECK) {
            keyPrefix = 'NECK';
        } else if (componentType == ComponentTypes.RING) {
            keyPrefix = 'RING';
        } else {
            revert(UnexpectedComponent);
        }

        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return (rand, rand % 21);
    }

    function pluck(
        uint256 tokenId,
        uint8 componentType,
        uint256 sourceArrayLength
    ) internal pure returns (uint8[5] memory) {
        uint8[5] memory components;

        (uint256 rand, uint256 greatness) = seed(tokenId, componentType);

        components[0] = uint8(rand % sourceArrayLength);
        components[1] = 0;
        components[2] = 0;

        if (greatness > 14) {
            components[1] = uint8((rand % suffixesLength) + 1);
        }
        if (greatness >= 19) {
            components[2] = uint8((rand % namePrefixesLength) + 1);
            components[3] = uint8((rand % nameSuffixesLength) + 1);
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }

        return components;
    }

    function getComponent(uint256 tokenId, uint8 componentType) public pure returns (uint8[5] memory) {
        if (componentType == ComponentTypes.WEAPON) {
            return pluck(tokenId, componentType, weaponsLength);
        } else if (componentType == ComponentTypes.CLOTHES) {
            return pluck(tokenId, componentType, clothesLength);
        } else if (componentType == ComponentTypes.VEHICLE) {
            return pluck(tokenId, componentType, vehicleLength);
        } else if (componentType == ComponentTypes.WAIST) {
            return pluck(tokenId, componentType, waistLength);
        } else if (componentType == ComponentTypes.FOOT) {
            return pluck(tokenId, componentType, footLength);
        } else if (componentType == ComponentTypes.HAND) {
            return pluck(tokenId, componentType, handLength);
        } else if (componentType == ComponentTypes.DRUGS) {
            return pluck(tokenId, componentType, drugsLength);
        } else if (componentType == ComponentTypes.NECK) {
            return pluck(tokenId, componentType, necklacesLength);
        } else if (componentType == ComponentTypes.RING) {
            return pluck(tokenId, componentType, ringsLength);
        } else {
            revert(UnexpectedComponent);
        }
    }

    function addComponent(uint8 componentType, string calldata component) public onlyOwner returns (uint8) {
        string[] storage arr;
        if (componentType == ComponentTypes.WEAPON) {
            arr = weapons;
        } else if (componentType == ComponentTypes.CLOTHES) {
            arr = clothes;
        } else if (componentType == ComponentTypes.VEHICLE) {
            arr = vehicle;
        } else if (componentType == ComponentTypes.WAIST) {
            arr = waistArmor;
        } else if (componentType == ComponentTypes.FOOT) {
            arr = footArmor;
        } else if (componentType == ComponentTypes.HAND) {
            arr = handArmor;
        } else if (componentType == ComponentTypes.DRUGS) {
            arr = drugs;
        } else if (componentType == ComponentTypes.NECK) {
            arr = necklaces;
        } else if (componentType == ComponentTypes.RING) {
            arr = rings;
        } else if (componentType == ComponentTypes.NAME_PREFIX) {
            arr = namePrefixes;
        } else if (componentType == ComponentTypes.NAME_SUFFIX) {
            arr = nameSuffixes;
        } else if (componentType == ComponentTypes.SUFFIX) {
            arr = suffixes;
        } else {
            revert(UnexpectedComponent);
        }

        require(arr.length < 255, 'component full');
        arr.push(component);
        uint8 id = uint8(arr.length) - 1;

        // prefix/suffix components are handled differently since they aren't always set.
        if (
            componentType == ComponentTypes.NAME_PREFIX ||
            componentType == ComponentTypes.NAME_SUFFIX ||
            componentType == ComponentTypes.SUFFIX
        ) {
            id = id + 1;
        }

        return id;
    }

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function name(uint8 componentType, uint256 idx) public view returns (string memory) {
        if (componentType == ComponentTypes.WEAPON) {
            return weapons[idx];
        } else if (componentType == ComponentTypes.CLOTHES) {
            return clothes[idx];
        } else if (componentType == ComponentTypes.VEHICLE) {
            return vehicle[idx];
        } else if (componentType == ComponentTypes.WAIST) {
            return waistArmor[idx];
        } else if (componentType == ComponentTypes.FOOT) {
            return footArmor[idx];
        } else if (componentType == ComponentTypes.HAND) {
            return handArmor[idx];
        } else if (componentType == ComponentTypes.DRUGS) {
            return drugs[idx];
        } else if (componentType == ComponentTypes.NECK) {
            return necklaces[idx];
        } else if (componentType == ComponentTypes.RING) {
            return rings[idx];
        } else {
            revert('Unexpected gear piece');
        }
    }

    function prefix(uint8 prefixComponent, uint8 suffixComponent) public view returns (string memory) {
        if (prefixComponent == 0) {
            return '';
        }

        string memory namePrefixSuffix = string(abi.encodePacked('\\"', namePrefixes[prefixComponent - 1]));

        if (suffixComponent > 0) {
            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, ' ', nameSuffixes[suffixComponent - 1]));
        }

        return string(abi.encodePacked(namePrefixSuffix, '\\"'));
    }

    function suffix(uint8 suffixComponent) public view returns (string memory) {
        if (suffixComponent == 0) {
            return '';
        }

        return suffixes[suffixComponent - 1];
    }

    /// @notice Returns the attributes associated with this item.
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint8[5] calldata components, uint8 componentType) external view returns (string memory) {
        string memory slot = slots[componentType];
        string memory res = string(abi.encodePacked('[', trait('Slot', slot)));

        string memory item = name(componentType, components[0]);
        res = string(abi.encodePacked(res, ', ', trait('Item', item)));

        if (components[1] > 0) {
            string memory data = suffixes[components[1] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Suffix', data)));
        }

        if (components[2] > 0) {
            string memory data = namePrefixes[components[2] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Name Prefix', data)));
        }

        if (components[3] > 0) {
            string memory data = nameSuffixes[components[3] - 1];
            res = string(abi.encodePacked(res, ', ', trait('Name Suffix', data)));
        }

        if (components[4] > 0) {
            res = string(abi.encodePacked(res, ', ', trait('Augmentation', 'Yes')));
        }

        res = string(abi.encodePacked(res, ']'));

        return res;
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked('{', '"trait_type": "', traitType, '", ', '"value": "', value, '"', '}'));
    }
}

////// src/ERC1155Snapshot.sol
/* pragma solidity ^0.8.0; */

/* import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol'; */
/* import '@openzeppelin/contracts/utils/Arrays.sol'; */
/* import '@openzeppelin/contracts/utils/Counters.sol'; */

/**
 * @dev This contract extends an ERC1155 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC1155 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the begining of each new block. When overridding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC1155Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC1155 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC1155Snapshot is ERC1155 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => mapping(uint256 => Snapshots)) private _accountBalanceSnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC1155 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(
        address account,
        uint256 id,
        uint256 snapshotId
    ) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account][id]);

        return snapshotted ? value : balanceOf(account, id);
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
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
            // mint
            for (uint256 i = 0; i < ids.length; i++) {
                _updateAccountSnapshot(to, ids[i]);
            }
        } else if (to == address(0)) {
            // burn
            for (uint256 i = 0; i < ids.length; i++) {
                _updateAccountSnapshot(from, ids[i]);
            }
        } else {
            // transfer
            for (uint256 i = 0; i < ids.length; i++) {
                _updateAccountSnapshot(from, ids[i]);
                _updateAccountSnapshot(to, ids[i]);
            }
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, 'ERC1155Snapshot: id is 0');
        require(snapshotId <= _getCurrentSnapshotId(), 'ERC1155Snapshot: nonexistent id');

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account, uint256 id) internal {
        _updateSnapshot(_accountBalanceSnapshots[account][id], balanceOf(account, id));
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

////// src/MetadataBuilder.sol

/// @title A library used to convert multi-part RLE compressed images to SVG
/// From: https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/libs/MetadataBuilder.sol

/* pragma solidity ^0.8.6; */

/* import { Base64 } from './MetadataUtils.sol'; */

library MetadataBuilder {
    struct SVGParams {
        string text;
        string subtext;
        string name;
        string description;
        string attributes;
        bytes[] parts;
        string background;
    }

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<style>@font-face { font-family: "d"; src: url(data:application/octet-stream;base64,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);}</style>'
                '<style>.base { fill: #fff; font-family: d; font-size: 14px; }</style>',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '<text x="160" y="25" with="320" text-anchor="middle" class="base">', params.text, '</text><text x="160" y="303" with="320" text-anchor="middle" class="base">', params.subtext, '</text>',
                '</svg>'
            )
        );
    }

    /// @dev Opensea contract metadata: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI(string calldata name, string calldata description) external pure returns (string memory) {
        string memory json = string(abi.encodePacked('{ "name": "', name, '", ', '"description" : ', description, '}'));
        string memory encodedJson = Base64.encode(bytes(json));
        string memory output = string(abi.encodePacked('data:application/json;base64,', encodedJson));
        return output;
    }

    function tokenURI(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        external
        view
        returns (string memory)
    {
        string memory output = Base64.encode(bytes(generateSVG(params, palettes)));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        params.name,
                        '", ',
                        '"description" : "',
                        params.description,
                        '", ',
                        '"image": "data:image/svg+xml;base64,',
                        output,
                        '", '
                        '"attributes": ',
                        params.attributes,
                        '}'
                    )
                )
            )
        );
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        string[65] memory lookup = [
            '0', '5', '10', '15', '20', '25', '30', '35', '40', '45', '50', '55', '60', '65', '70', '75', 
            '80', '85', '90', '95', '100', '105', '110', '115', '120', '125', '130', '135', '140', '145', '150', '155', 
            '160', '165', '170', '175', '180', '185', '190', '195', '200', '205', '210', '215', '220', '225', '230', '235', 
            '240', '245', '250', '255', '260', '265', '270', '275', '280', '285', '290', '295', '300', '305', '310', '315',
            '320'
        ];
        string memory rects;
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="5" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }

        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }
}

////// src/TokenId.sol
/* pragma solidity ^0.8.0; */

/// @title Encoding / decoding utilities for token ids
/// @author Georgios Konstantopoulos
/// @dev Token ids are generated from the components via a bijective encoding
/// using the token type and its attributes. We shift left by 16 bits, i.e. 2 bytes
/// each time so that the IDs do not overlap, assuming that components are smaller than 256
library TokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of Loot components and an item type (weapon, chest etc.)
    /// to a token id
    function toId(uint8[5] memory components, uint256 itemType) internal pure returns (uint256) {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id) internal pure returns (uint8[5] memory components, uint8 itemType) {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx) internal pure returns (uint256) {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) internal pure returns (uint8) {
        return uint8((id >> (SHIFT * idx)) & 0xff);
    }
}

////// src/StockpileMetadata.sol
/* pragma solidity ^0.8.0; */

/* import './Components.sol'; */
/* import './TokenId.sol'; */

/* import { MetadataBuilder } from './MetadataBuilder.sol'; */

library Gender {
    uint8 internal constant MALE = 0x0;
    uint8 internal constant FEMALE = 0x1;
}

/// @title Helper contract for generating ERC-1155 token ids and descriptions for
/// the individual items inside a Loot bag.
/// @author Tarrence van As, forked from Georgios Konstantopoulos
/// @dev Inherit from this contract and use it to generate metadata for your tokens
contract StockpileMetadata {
    string private constant _name = 'Dope St. Swap Meet';
    string private constant description =
        'Get fitted with the freshest drip, strapped with the latest gat, rolling in the hottest ride, and re-up your supply at the Dope St. Swap Meet.';

    bytes internal constant female =
        hex'000a26361a050004240300040006240200040007240100020009240100020008240200020002240100052402000300012401000524020006000324030006000224040006000224040004000624020003000824010002000a2402000a2401000224010008240100012402000624010001240100012403000524010001240100012403000424020001240100012403000424020001240100012403000424020001240100012403000424020001240100012402000624010001240224020008240224020006240100012401240300022402000324010004000224020002240200040002240200022402000400022402000224020004000224020002240200040002240200022402000400022402000224020004000224020002240200040002240200022402000400012403000124030004000124030001240300040001240300012403000400012403000124030004000124030001240300040001240300012403000400012403000124030004000124030001240300040001240300012403000400012403000124030003000324020003240100';
    bytes internal constant man =
        hex'000927361907000324040006000524030006000524030006000524030006000524030007000424030007000324040007000224050004000724030002000b24010001000d2401000d2401000d240e240e24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b240c240100012402240100032402000524010003000324020004240200030003240300032402000300032403000324020003000324030003240200030003240300032402000300032403000324020003000324030003240200030003240300032402000300022404000224030003000224040002240300030002240400022403000300022404000224030003000224040002240300030002240400022403000300022404000224030003000224040002240300030002240400022403000300022404000324020003000324030004240100';
    bytes internal constant shadow = hex'0036283818024801000d48050009480200';

    // green, blue, red, yellow
    string[4] internal backgrounds = ['a3beb5', '8aa3c3', 'e0afae', 'f5d8a5'];

    // Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) internal palettes;

    // Item RLE (TokenID => RLE)
    mapping(uint256 => bytes[2]) internal rles;

    Components internal sc;

    constructor(address _components) {
        sc = Components(_components);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return 'SWAP';
    }

    /// @dev Opensea contract metadata: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external pure returns (string memory) {
        return MetadataBuilder.contractURI(_name, description);
    }

    /// @notice Returns an SVG for the provided token id
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        bytes[] memory parts = new bytes[](6);

        bytes[3] memory male = genderParts(man, tokenId, Gender.MALE);
        bytes[3] memory female = genderParts(female, tokenId, Gender.FEMALE);

        parts[0] = male[0];
        parts[1] = male[1];
        parts[2] = male[2];
        parts[3] = female[0];
        parts[4] = female[1];
        parts[5] = female[2];

        MetadataBuilder.SVGParams memory p = params(tokenId);
        p.parts = parts;

        return MetadataBuilder.tokenURI(p, palettes);
    }

    function params(uint256 tokenId) internal view returns (MetadataBuilder.SVGParams memory) {
        (uint8[5] memory components, uint8 componentType) = TokenId.fromId(tokenId);

        uint8 bg = 0;
        string memory name = sc.name(componentType, components[0]);
        MetadataBuilder.SVGParams memory meta;
        meta.name = name;
        meta.description = description;
        meta.attributes = sc.attributes(components, componentType);

        if (components[1] > 0) {
            meta.name = string(abi.encodePacked(meta.name, ' ', sc.suffix(components[1])));
            meta.subtext = name;
            bg = 1;
        } else {
            meta.subtext = name;
        }

        if (components[2] > 0) {
            meta.text = sc.prefix(components[2], components[3]);
            meta.name = string(abi.encodePacked(meta.text, ' ', meta.name));
            bg = 2;
        }

        if (components[4] > 0) {
            meta.subtext = string(abi.encodePacked(meta.subtext, ' +1'));
            meta.name = string(abi.encodePacked(meta.name, ' +1'));
            bg = 3;
        }

        meta.background = backgrounds[bg];

        return meta;
    }

    function tokenRle(uint256 id, uint8 gender) public view returns (bytes memory) {
        if (rles[id][gender].length > 0) {
            return rles[id][gender];
        }

        (uint8[5] memory components, uint8 componentType) = TokenId.fromId(id);
        components[1] = 0;
        components[2] = 0;
        components[3] = 0;
        components[4] = 0;
        return rles[TokenId.toId(components, componentType)][gender];
    }

    function toId(uint8[5] memory components, uint8 componentType) public pure returns (uint256) {
        return TokenId.toId(components, componentType);
    }

    function genderParts(
        bytes memory silouette,
        uint256 id,
        uint8 gender
    ) internal view returns (bytes[3] memory) {
        bytes[3] memory parts;

        bytes memory shadow_ = shadow;
        shadow_[2] = bytes1(uint8(shadow_[2]) + (gender * uint8(12)));
        shadow_[4] = bytes1(uint8(shadow_[4]) + (gender * uint8(12)));
        parts[0] = shadow_;

        silouette[2] = bytes1(uint8(silouette[2]) + (gender * uint8(12)));
        silouette[4] = bytes1(uint8(silouette[4]) + (gender * uint8(12)));
        parts[1] = silouette;

        bytes memory item = tokenRle(id, gender);
        item[2] = bytes1(uint8(item[2]) + (gender * uint8(12)));
        item[4] = bytes1(uint8(item[4]) + (gender * uint8(12)));
        parts[2] = item;

        return parts;
    }
}

////// src/interfaces/IStockpile.sol
// Taken from https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/interfaces/INounsDescriptor.sol

// @title Dope gear stockpile

/* import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol'; */

/* pragma solidity ^0.8.6; */

interface IStockpile is IERC1155 {
    function attribute(uint256 id) external view returns (bytes memory value);

    function valueOfBatch(uint256[] memory ids) external view returns (bytes[] memory values);

    function ownedValueOfBatch(uint256[] memory ids) external view returns (bytes[] memory values);
}

////// src/Stockpile.sol
/* pragma solidity ^0.8.0; */

// ============ Imports ============

/* import '@openzeppelin/contracts/token/ERC721/IERC721.sol'; */
/* import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol'; */
/* import '@openzeppelin/contracts/access/Ownable.sol'; */

/* import { ComponentTypes } from './Components.sol'; */
/* import { ERC1155Snapshot } from './ERC1155Snapshot.sol'; */
/* import './StockpileMetadata.sol'; */
/* import './interfaces/IStockpile.sol'; */

library Errors {
    string constant DoesNotOwnBag = 'you do not own this bag';
    string constant AlreadyOpened = 'bag already opened';
}

/// @title Dope Gear Stockpile
/// @author Tarrence van As, forked from Georgios Konstantopoulos
/// @notice Allows "opening" your ERC721 Loot bags and extracting the items inside it
/// The created tokens are ERC1155 compatible, and their on-chain SVG is their name
contract Stockpile is ERC1155Snapshot, StockpileMetadata, Ownable {
    // The DOPE bags contract
    IERC721 immutable bags;

    mapping(uint256 => bool) private opened;

    // No need for a URI since we're doing everything onchain
    constructor(
        address _components,
        address _bags,
        address _owner
    ) StockpileMetadata(_components) ERC1155('') {
        bags = IERC721(_bags);
        transferOwnership(_owner);
    }

    /// @notice Opens the provided tokenId if the sender is owner. This
    /// can only be done once per DOPE token.
    function open(uint256 tokenId) public {
        require(msg.sender == bags.ownerOf(tokenId), Errors.DoesNotOwnBag);
        require(!opened[tokenId], Errors.AlreadyOpened);
        opened[tokenId] = true;
        open(msg.sender, tokenId);
    }

    /// @notice Bulk opens the provided tokenIds. This
    /// can only be done once per DOPE token.
    function batchOpen(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            open(ids[i]);
        }
    }

    /// @notice Opens your Loot bag and mints you 9 ERC-1155 tokens for each item
    /// in that bag
    function open(address who, uint256 tokenId) private {
        // NB: We patched ERC1155 to expose `_balances` so
        // that we can manually mint to a user, and manually emit a `TransferBatch`
        // event. If that's unsafe, we can fallback to using _mint
        uint256[] memory ids = new uint256[](9);
        uint256[] memory amounts = new uint256[](9);
        ids[0] = itemId(tokenId, ComponentTypes.WEAPON);
        ids[1] = itemId(tokenId, ComponentTypes.CLOTHES);
        ids[2] = itemId(tokenId, ComponentTypes.VEHICLE);
        ids[3] = itemId(tokenId, ComponentTypes.WAIST);
        ids[4] = itemId(tokenId, ComponentTypes.FOOT);
        ids[5] = itemId(tokenId, ComponentTypes.HAND);
        ids[6] = itemId(tokenId, ComponentTypes.DRUGS);
        ids[7] = itemId(tokenId, ComponentTypes.NECK);
        ids[8] = itemId(tokenId, ComponentTypes.RING);

        for (uint256 i = 0; i < ids.length; i++) {
            // Since we are directly minting, we need to handle the snapshot logic.
            _updateAccountSnapshot(who, ids[i]);

            amounts[i] = 1;
            _balances[ids[i]][who] += 1;
        }

        emit TransferBatch(_msgSender(), address(0), who, ids, amounts);
    }

    function itemId(uint256 tokenId, uint8 componentType) private view returns (uint256) {
        uint8[5] memory components = sc.getComponent(tokenId, componentType);
        return TokenId.toId(components, componentType);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURI(tokenId);
    }

    function mint(
        address to,
        uint8[5] memory components,
        uint8 componentType,
        uint256 amount,
        bytes memory data
    ) external onlyOwner returns (uint256) {
        uint256 id = TokenId.toId(components, componentType);
        _mint(to, id, amount, data);
        return id;
    }

    function mintBatch(
        address to,
        uint8[] memory components,
        uint8[] memory componentTypes,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyOwner returns (uint256[] memory) {
        require(components.length % 5 == 0, 'invalid components shape');
        require(components.length / 5 == componentTypes.length, 'component componentType mismatch');
        uint256[] memory ids = new uint256[](componentTypes.length);

        for (uint256 i = 0; i < components.length; i += 5) {
            uint8[5] memory _components;
            _components[0] = components[i];
            _components[1] = components[i + 1];
            _components[2] = components[i + 2];
            _components[3] = components[i + 3];
            _components[4] = components[i + 4];
            ids[i / 5] = TokenId.toId(_components, componentTypes[i / 5]);
        }

        _mintBatch(to, ids, amounts, data);
        return ids;
    }

    // function burn(uint256 id, uint256 amount) external {
    //     _burn(msg.sender, id, amount);
    // }

    function setPalette(uint8 id, string[] memory palette) public onlyOwner {
        palettes[id] = palette;
    }

    function setRle(
        uint256 id,
        bytes memory male,
        bytes memory female
    ) public onlyOwner {
        rles[id][Gender.MALE] = male;
        rles[id][Gender.FEMALE] = female;
    }

    function batchSetRle(uint256[] calldata ids, bytes[] calldata rles) public onlyOwner {
        require(ids.length == rles.length / 2, 'ids rles mismatch');

        for (uint256 i = 0; i < rles.length; i += 2) {
            setRle(i / 2, rles[i], rles[i + 1]);
        }
    }
}