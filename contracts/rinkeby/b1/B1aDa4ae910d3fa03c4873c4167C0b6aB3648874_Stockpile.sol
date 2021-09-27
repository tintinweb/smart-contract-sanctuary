/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

// Verified using https://dapp.tools

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

////// src/DopeComponents.sol

/*

    DopeComponents.sol
    
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

contract DopeComponents is Ownable {
    uint8 public constant WEAPON = 0x0;
    uint8 public constant CLOTHES = 0x1;
    uint8 public constant VEHICLE = 0x2;
    uint8 public constant WAIST = 0x3;
    uint8 public constant FOOT = 0x4;
    uint8 public constant HAND = 0x5;
    uint8 public constant DRUGS = 0x6;
    uint8 public constant NECK = 0x7;
    uint8 public constant RING = 0x8;
    uint8 public constant NAME_PREFIX = 0x9;
    uint8 public constant NAME_SUFFIX = 0xa;
    uint8 public constant SUFFIX = 0xb;
    uint8 public constant SET = 0xc;

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

    function weaponComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'WEAPON', weaponsLength);
    }

    function clothesComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'CLOTHES', clothesLength);
    }

    function vehicleComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'VEHICLE', vehicleLength);
    }

    function waistComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'WAIST', waistLength);
    }

    function footComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'FOOT', footLength);
    }

    function handComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'HAND', handLength);
    }

    function drugsComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'DRUGS', drugsLength);
    }

    function neckComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'NECK', necklacesLength);
    }

    function ringComponents(uint256 tokenId) public pure returns (uint8[5] memory) {
        return pluck(tokenId, 'RING', ringsLength);
    }

    function addComponent(uint8 itemType, string calldata component) public onlyOwner returns (uint8) {
        string[] storage arr;
        if (itemType == WEAPON) {
            arr = weapons;
        } else if (itemType == CLOTHES) {
            arr = clothes;
        } else if (itemType == VEHICLE) {
            arr = vehicle;
        } else if (itemType == WAIST) {
            arr = waistArmor;
        } else if (itemType == FOOT) {
            arr = footArmor;
        } else if (itemType == HAND) {
            arr = handArmor;
        } else if (itemType == DRUGS) {
            arr = drugs;
        } else if (itemType == NECK) {
            arr = necklaces;
        } else if (itemType == RING) {
            arr = rings;
        } else if (itemType == NAME_PREFIX) {
            arr = namePrefixes;
        } else if (itemType == NAME_SUFFIX) {
            arr = nameSuffixes;
        } else if (itemType == SUFFIX) {
            arr = suffixes;
        } else {
            revert('Unexpected gear piece');
        }

        require(arr.length < 255, 'component full');
        arr.push(component);
        uint8 id = uint8(arr.length) - 1;

        // prefix/suffix components are handled differently since they aren't always set.
        if (itemType == NAME_PREFIX || itemType == NAME_SUFFIX || itemType == SUFFIX) {
            id = id + 1;
        }

        return id;
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        uint256 sourceArrayLength
    ) internal pure returns (uint8[5] memory) {
        uint8[5] memory components;

        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));

        components[0] = uint8(rand % sourceArrayLength);
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = rand % 21;
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

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function itemName(uint8 itemType, uint256 idx) public view returns (string memory) {
        if (itemType == WEAPON) {
            return weapons[idx];
        } else if (itemType == CLOTHES) {
            return clothes[idx];
        } else if (itemType == VEHICLE) {
            return vehicle[idx];
        } else if (itemType == WAIST) {
            return waistArmor[idx];
        } else if (itemType == FOOT) {
            return footArmor[idx];
        } else if (itemType == HAND) {
            return handArmor[idx];
        } else if (itemType == DRUGS) {
            return drugs[idx];
        } else if (itemType == NECK) {
            return necklaces[idx];
        } else if (itemType == RING) {
            return rings[idx];
        } else {
            revert('Unexpected gear piece');
        }
    }

    // Creates the token description given its components and what type it is
    function componentsToString(uint8[5] memory components, uint8 itemType) public view returns (string memory) {
        // item type: what slot to get
        // components[0] the index in the array
        string memory item = itemName(itemType, components[0]);

        // We need to do -1 because the 'no description' is not part of loot copmonents

        // add the suffix
        if (components[1] > 0) {
            item = string(abi.encodePacked(item, ' ', suffixes[components[1] - 1]));
        }

        // add the name prefix / suffix
        if (components[2] > 0) {
            // prefix
            string memory namePrefixSuffix = string(abi.encodePacked("'", namePrefixes[components[2] - 1]));
            if (components[3] > 0) {
                namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, ' ', nameSuffixes[components[3] - 1]));
            }

            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, "' "));

            item = string(abi.encodePacked(namePrefixSuffix, item));
        }

        // add the augmentation
        if (components[4] > 0) {
            item = string(abi.encodePacked(item, ' +1'));
        }

        return item;
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

    function _updateAccountSnapshot(address account, uint256 id) private {
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

////// src/MultiPartRLEToSVG.sol

/// @title A library used to convert multi-part RLE compressed images to SVG
/// From: https://raw.githubusercontent.com/nounsDAO/nouns-monorepo/master/packages/nouns-contracts/contracts/libs/MultiPartRLEToSVG.sol

/* pragma solidity ^0.8.6; */

library MultiPartRLEToSVG {
    struct SVGParams {
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
    function generateSVG(
        string memory name,
        SVGParams memory params,
        mapping(uint8 => string[]) storage palettes
    ) internal view returns (string memory svg) {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '<text x="10" y="20" class="base">', name, '</text>',
                '</svg>'
            )
        );
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
    function toId(uint8[5] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id)
        internal
        pure
        returns (uint8[5] memory components, uint8 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint8) {
        return uint8((id >> (SHIFT * idx)) & 0xff);
    }
}

////// src/StockpileMetadata.sol
/* pragma solidity ^0.8.0; */

/* import './DopeComponents.sol'; */
/* import './TokenId.sol'; */
/* import { Base64, toString } from './MetadataUtils.sol'; */

/* import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol'; */

/// @title Helper contract for generating ERC-1155 token ids and descriptions for
/// the individual items inside a Loot bag.
/// @author Tarrence van As, forked from Georgios Konstantopoulos
/// @dev Inherit from this contract and use it to generate metadata for your tokens
contract StockpileMetadata {
    string[] internal itemTypes = ['Weapon', 'Clothes', 'Vehicle', 'Waist', 'Foot', 'Hand', 'Drugs', 'Neck', 'Ring'];

    bytes internal man = hex"000927361907000324040006000524030006000524030006000524030006000524030007000424030007000324040007000224050004000724030002000b24010001000d2401000d2401000d240e240e24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b24022401000b240c240100012402240100032402000524010003000324020004240200030003240300032402000300032403000324020003000324030003240200030003240300032402000300032403000324020003000324030003240200030003240300032402000300022404000224030003000224040002240300030002240400022403000300022404000224030003000224040002240300030002240400022403000300022404000224030003000224040002240300030002240400022403000300022404000324020003000324030004240100";

    // Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public palettes;

    // Backgrounds (Hex Colors)
    string[] public backgrounds;

    // Item RLE (TokenID => RLE)
    mapping(uint256 => string) internal _rle;

    DopeComponents internal sc;

    constructor(address _components) {
        sc = DopeComponents(_components);
    }

    function name() external pure returns (string memory) {
        return 'Dope Wars Stockpile';
    }

    function symbol() external pure returns (string memory) {
        return 'STOCK';
    }

    /// @dev Opensea contract metadata: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external pure returns (string memory) {
        string memory json = '{"name": "Dope Wars Stockpile", "description": "Stockpile for Dope Wars"}';
        string memory encodedJson = Base64.encode(bytes(json));
        string memory output = string(abi.encodePacked('data:application/json;base64,', encodedJson));

        return output;
    }

    /// @notice Returns an SVG for the provided token id
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        uint48[] memory parts = new uint48[](1);
        string memory name = tokenName(tokenId);
        string memory output = generateSVGImage(name, parts);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        name,
                        '", ',
                        '"description" : ',
                        '"Dope Gear lets you unbundle your DOPE Bags into individual ERC1155 NFTs.", ',
                        '"image": "data:image/svg+xml;base64,',
                        output,
                        '", '
                        '"attributes": ',
                        attributes(tokenId),
                        '}'
                    )
                )
            )
        );
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * @notice Given a equipment, construct a base64 encoded SVG image.
     */
    function generateSVGImage(string memory title, uint48[] memory equipment) internal view returns (string memory) {
        bytes[] memory parts = new bytes[](1);
        parts[0] = bytes(man);
        return
            Base64.encode(
                bytes(
                    MultiPartRLEToSVG.generateSVG(
                        title,
                        MultiPartRLEToSVG.SVGParams({ parts: parts, background: '#000000' }),
                        palettes
                    )
                )
            );
    }

    /// @notice Returns the attributes associated with this item.
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint256 id) public view returns (string memory) {
        (uint8[5] memory components, uint8 itemType) = TokenId.fromId(id);
        // should we also use components[0] which contains the item name?
        string memory slot = itemTypes[itemType];
        string memory res = string(abi.encodePacked('[', trait('Slot', slot)));

        string memory item = sc.itemName(itemType, components[0]);
        res = string(abi.encodePacked(res, ', ', trait('Item', item)));

        if (components[1] > 0) {
            string memory data = sc.suffixes(components[1] - 1);
            res = string(abi.encodePacked(res, ', ', trait('Suffix', data)));
        }

        if (components[2] > 0) {
            string memory data = sc.namePrefixes(components[2] - 1);
            res = string(abi.encodePacked(res, ', ', trait('Name Prefix', data)));
        }

        if (components[3] > 0) {
            string memory data = sc.nameSuffixes(components[3] - 1);
            res = string(abi.encodePacked(res, ', ', trait('Name Suffix', data)));
        }

        if (components[4] > 0) {
            res = string(abi.encodePacked(res, ', ', trait('Augmentation', 'Yes')));
        }

        res = string(abi.encodePacked(res, ']'));

        return res;
    }

    // Helper for encoding as json w/ trait_type / value from opensea
    function trait(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string(abi.encodePacked('{', '"trait_type": "', _traitType, '", ', '"value": "', _value, '"', '}'));
    }

    // @notice Given an ERC1155 token id, it returns its name by decoding and parsing
    // the id
    function tokenName(uint256 id) public view returns (string memory) {
        (uint8[5] memory components, uint8 itemType) = TokenId.fromId(id);
        return sc.componentsToString(components, itemType);
    }

    function rle(uint256 id) public view returns (string memory) {
        if (bytes(_rle[id]).length > 0) {
            return _rle[id];
        }
        return '';
        // (uint8[5] memory components, uint8 itemType) = TokenId.fromId(id);
        // return
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
/* import '@openzeppelin/contracts/access/Ownable.sol'; */

/* import './ERC1155Snapshot.sol'; */
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
contract Stockpile is ERC1155Snapshot, StockpileMetadata {
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
        // transferOwnership(_owner);
    }

    /// @notice Opens the provided tokenId if the sender is owner. This
    /// can only be done once per DOPE token.
    function open(uint256 tokenId) external {
        require(msg.sender == bags.ownerOf(tokenId), Errors.DoesNotOwnBag);
        require(!opened[tokenId], Errors.AlreadyOpened);
        opened[tokenId] = true;
        open(msg.sender, tokenId);
    }

    /// @notice Opens your Loot bag and mints you 9 ERC-1155 tokens for each item
    /// in that bag
    function open(address who, uint256 tokenId) private {
        // NB: We patched ERC1155 to expose `_balances` so
        // that we can manually mint to a user, and manually emit a `TransferBatch`
        // event. If that's unsafe, we can fallback to using _mint
        uint256[] memory ids = new uint256[](9);
        uint256[] memory amounts = new uint256[](9);
        ids[0] = itemId(tokenId, sc.weaponComponents, sc.WEAPON());
        ids[1] = itemId(tokenId, sc.clothesComponents, sc.CLOTHES());
        ids[2] = itemId(tokenId, sc.vehicleComponents, sc.VEHICLE());
        ids[3] = itemId(tokenId, sc.waistComponents, sc.WAIST());
        ids[4] = itemId(tokenId, sc.footComponents, sc.FOOT());
        ids[5] = itemId(tokenId, sc.handComponents, sc.HAND());
        ids[6] = itemId(tokenId, sc.drugsComponents, sc.DRUGS());
        ids[7] = itemId(tokenId, sc.neckComponents, sc.NECK());
        ids[8] = itemId(tokenId, sc.ringComponents, sc.RING());
        for (uint256 i = 0; i < ids.length; i++) {
            amounts[i] = 1;
            // +21k per call / unavoidable - requires patching OZ
            _balances[ids[i]][who] += 1;
        }

        emit TransferBatch(_msgSender(), address(0), who, ids, amounts);
    }

    function itemId(
        uint256 tokenId,
        function(uint256) external pure returns (uint8[5] memory) componentsFn,
        uint256 itemType
    ) private view returns (uint256) {
        uint8[5] memory components = componentsFn(tokenId);
        return TokenId.toId(components, itemType);
    }

    // function mint(
    //     address to,
    //     uint8[5] memory components,
    //     uint8 itemType,
    //     uint256 amount,
    //     bytes memory data
    // ) external onlyOwner returns (uint256) {
    //     uint256 id = TokenId.toId(components, itemType);
    //     _mint(to, id, amount, data);
    //     return id;
    // }

    // function mintBatch(
    //     address to,
    //     uint8[] memory components,
    //     uint8[] memory itemTypes,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) external onlyOwner returns (uint256[] memory) {
    //     require(components.length % 5 == 0, 'invalid components shape');
    //     require(components.length / 5 == itemTypes.length, 'component itemType mismatch');
    //     uint256[] memory ids = new uint256[](itemTypes.length);

    //     for (uint256 i = 0; i < components.length; i += 5) {
    //         uint8[5] memory _components;
    //         _components[0] = components[i];
    //         _components[1] = components[i + 1];
    //         _components[2] = components[i + 2];
    //         _components[3] = components[i + 3];
    //         _components[4] = components[i + 4];
    //         ids[i / 5] = TokenId.toId(_components, itemTypes[i / 5]);
    //     }

    //     _mintBatch(to, ids, amounts, data);
    //     return ids;
    // }

    // function burn(uint256 id, uint256 amount) external {
    //     _burn(msg.sender, id, amount);
    // }

    // function rleOf(uint256 tokenId) external view returns (bytes memory rle) {
    //     return '';
    // }

    // function rleOfBatch(uint256[] memory tokenIds) external view returns (bytes[] memory rles) {
    //     bytes[] memory _rles = new bytes[](8);
    //     return _rles;
    // }

    // function ownedBatchRLE(uint256[] memory tokenIds) external view returns (bytes[] memory rles) {
    //     bytes[] memory _rles = new bytes[](8);
    //     return _rles;
    // }
}