/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol


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

// File: contracts/walletmonstersapus.sol


pragma solidity ^0.8.7;



 
 
contract WalletMonstersApus is ERC1155, Ownable, IERC1155Receiver{
   
    //state variable
    uint256 nextId = 0;
    uint256 eightHours = 28880; //8hour
    uint256 week = 604800; // 7 day time; - mint portal
    uint256 eightDays = 691200; //8 days - free mints
    uint public faucetPrice; //uuji
    uint public faucetHPPrice;
    uint public faucetWallePrice;
    uint public faucetRevivePrice;
    uint public faucetElixerPrice;
    uint public faucetEnjimonPrice;
    uint public marketEnjimonPrice;
    uint256 battleTimer = 10800;
     //uint256 battleTimer = 108; //how long a player can remain stale before exit battle
 
    bool mintNow;
 
    address public operatorControl; //devs
    address payable public FULLSTACKCALI;
    address escrowedValut;
    uint256 amountBurned = 0;
 
    //Mappings
    mapping(uint256 => Enjimon) private _tokenDetails;
    mapping(address => uint) balance;
    mapping(address => mapping(uint => uint)) coolDown; // timer for mints
    mapping(address => mapping(uint => bool)) alreadyMinted; // free mint tracker - needs to be false
    mapping(uint256 => uint256) itemPrice; //id to price
 
    mapping(uint256 => uint256) public enjimonTVL;
    mapping(address => uint256) public escrowedTotal;
    mapping(address => mapping(uint256 => uint256)) private nurseryEnjimon;
    mapping(address => bool) private trainersTurn;
 
       //battleMode
    mapping(address => bool)hasPendingBattle;
    mapping(address => uint256) trainerEnjimon;
    mapping(address => uint256) trainerBattle;
    mapping(address => bool) isInBattle;
    mapping(address => uint256) turnTime;
    mapping(address => uint256) public trainerLevel;
    mapping(address => mapping(uint256 => uint256)) public health;
   
 
    //Dapp Events
    event bornDate(address from, string name, uint256 enjimonID, uint256 date);
    event tokenSupplyMinted(address from, uint256 tokenID, uint256 amount, uint256 date);
    event artifactMinted(address from, uint256 tokenID, uint256 amount, uint256 date);
    event tokenSupplyBurned(address from, uint256 tokenID, uint256 amount, uint256 date);
    event itemBurned(address from, uint256 tokenID, uint256 amount, uint256 date);
    event enjimonTrained(address from, uint256 enjimonID, string name, uint lastTrainded);
    event transferEnjimon(address from, address to, uint256 tokenId, string name, uint256 amount);
    event transferItem(address from, address to, uint256 tokenId, uint256 amount);
    event burnedCount(uint256 tokenID, uint256 amount, uint256 date);
    event purchase(address buyer, uint256 tokenId, uint256 amount, uint256 cost);
 
    event battleInit(address challenger, address opponent, uint256 date);
    event battleApproved(address opponent, address challenger, uint256 date);
    event battleResults(address winner, address loser, uint256 reward, uint256 date);
    event nurseryTransfer(address trainer, uint256 enjimonId, uint256 date);
    event enjimonRevived(address trainer, uint256 enjimonId, uint256 date);
   
 
    //modifiers
    modifier userCantMint(uint256 tokenId) {
        require(alreadyMinted[msg.sender][tokenId] == false, "You already minted this token for period");
        _;
    }
 
    modifier mintingPeriod{
        require(mintNow == true,"Minting off");
        _;
    }
 
   
    modifier hasNoPendingBattle
        {
            require(hasPendingBattle[msg.sender] == false, "you can not init a battle unitl finalization of previous transaction!");
            _;
        }
   
    struct Enjimon {
            string enjimonName;
            uint256 healthPoints;
            uint256 defense;
            uint256 attack;
            uint256 level;
            uint256 lastTrained;
            string enjimonType;
            uint256 TVL;
            string sector;
    }
   
    struct Battle
        {
            uint battleId;
            address challenger;
            address opponent;
            bool accepted;
        }  
 
    Battle[] _pendingBattle;  
    constructor() ERC1155("https://i65nweyr9d9c.usemoralis.com/{id}.json") {
       
        FULLSTACKCALI = payable(msg.sender);
        operatorControl = msg.sender;
        escrowedValut = address(this);
 
        itemPrice[0] = 5000000000000000000; //UJJI
        faucetPrice = itemPrice[0];
 
        itemPrice[1] = 250000000000000000; //HP
        faucetHPPrice = itemPrice[1];
 
        itemPrice[6] = 500000000000000000; //Walle
        faucetWallePrice = itemPrice[6];
       
        itemPrice[5] = 500000000000000000; //revives
        faucetRevivePrice = itemPrice[5];
 
        itemPrice[4] = 1300000000000000000;
        faucetElixerPrice = itemPrice[4]; // elixer
 
       
        faucetEnjimonPrice = 2500000000000000000;
        marketEnjimonPrice = 7268813300000000000;
 
        mintNow = false;
        escrowedTotal[address(this)] = 0;
       
        _mint(msg.sender, nextId, 10**8, ""); //0 UUJI token
        nextId++;
        _mint(msg.sender, nextId, 1000000**1, ""); //1 potions heals enjimon health
        nextId++;
        _mint(msg.sender, nextId, 250000**1, ""); // 2 eATK  increase
        nextId++;
        _mint(msg.sender, nextId, 250000**1, ""); //3 eDef   increases def by 5
        nextId++;
        _mint(msg.sender, nextId, 800000**1, ""); //4 elixer levels up enjimon
        nextId++;
        _mint(msg.sender, nextId, 500000**1, ""); //5 revive
        nextId++;
        _mint(msg.sender, nextId, 650000**1, ""); //6 Walle
        nextId++; //id is now 7
 
        emit tokenSupplyMinted(msg.sender, 0,10**8, block.timestamp);
        emit artifactMinted(msg.sender, 1, 1000000**1, block.timestamp);
        emit artifactMinted(msg.sender, 2, 250000**1, block.timestamp);
        emit artifactMinted(msg.sender, 3, 250000**1, block.timestamp);
        emit artifactMinted(msg.sender, 4, 800000**1, block.timestamp);
        emit artifactMinted(msg.sender, 5, 500000**1, block.timestamp);
        emit artifactMinted(msg.sender, 6, 650000**1, block.timestamp);
   
        setApprovalForAll(address(this), true);
       
        //transfer to contract
        _safeTransferFrom(msg.sender, address(this), 0, 90000000 ** 1, '');
        _safeTransferFrom(msg.sender, address(this), 1, 900000**1, '');
        _safeTransferFrom(msg.sender, address(this), 2, 225000**1, '');
        _safeTransferFrom(msg.sender, address(this), 3, 225000**1, '');
        _safeTransferFrom(msg.sender, address(this), 4, 795000**1, '');
        _safeTransferFrom(msg.sender, address(this), 5, 495000**1, '');
        _safeTransferFrom(msg.sender, address(this), 6, 645000 **1, '');
 
        emit transferItem(msg.sender, address(this), 0, 90000000 ** 1);
        emit transferItem(msg.sender, address(this), 1, 900000**1);
        emit transferItem(msg.sender, address(this), 2, 225000**1);
        emit transferItem(msg.sender, address(this), 3, 225000**1);
        emit transferItem(msg.sender, address(this), 4, 795000**1);
        emit transferItem(msg.sender, address(this), 5, 495000**1);
        emit transferItem(msg.sender, address(this), 6, 645000 **1);
 
    }
   
   //Utility functions
     function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override pure returns (bytes4)
    {
 
       return this.onERC1155Received.selector;
    }
   
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override pure returns (bytes4)
    {
        return this.onERC1155BatchReceived.selector;
    }
 
         
   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual  override {
         
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
       
        if(tokenId >= 7 ){
              Enjimon storage enjimon =_tokenDetails[tokenId];
 
             _safeTransferFrom(from, to, tokenId, amount, data);
             
             emit transferEnjimon(msg.sender, to, tokenId, enjimon.enjimonName, amount);
        }
        else{
           
            _safeTransferFrom(from, to, tokenId, amount, data);
           
            emit transferItem(from, to, tokenId, amount);
           
        }
    }
 
    function Randomness() private view returns (uint) {
     
        return ((uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 10)+ 1);
    }
 
    //Authorized functions
    function setFaucet(uint _cost) public onlyOwner returns(uint){
           
            itemPrice[0] = _cost;
            faucetPrice = itemPrice[0];
 
            return faucetPrice;
    }
 
    function setHPPrice(uint _cost) public onlyOwner returns(uint){
        itemPrice[1] = _cost;
        faucetHPPrice = itemPrice[1];
 
        return faucetHPPrice;
    }
 
    function setElixerPrice(uint _cost) public onlyOwner returns(uint){
        itemPrice[4] = _cost;
        faucetElixerPrice = itemPrice[4];
 
        return faucetElixerPrice;
    }
 
    function setWALYPrice(uint _cost) public onlyOwner returns(uint){
        itemPrice[6] = _cost;
        faucetWallePrice = itemPrice[6];
 
        return faucetWallePrice;
    }
 
    function setRevivePrice(uint _cost) public onlyOwner returns(uint){
        itemPrice[5] = _cost;
        faucetRevivePrice = itemPrice[5];
 
        return faucetRevivePrice;
    }
 
    function setEnjimonPrice(uint _cost) public onlyOwner returns(uint){
        faucetEnjimonPrice = _cost;
 
        return faucetEnjimonPrice;
    }

    function setEnjimonMarketPrice(uint _cost) public onlyOwner returns(uint){
        marketEnjimonPrice = _cost;
 
        return marketEnjimonPrice;
    }
 
    function perkRewards(bool onOff) public onlyOwner returns(bool success){
       
        mintNow = onOff;
 
        return true;
 
    }
 
    function setTimer(uint256 _timer) public onlyOwner returns(bool success){
        battleTimer = _timer;
 
        return true;
    }
 
        //Critical Buy Theory (gets are free)
    function getATK() public userCantMint(2)  mintingPeriod returns(uint eATK){
        require(balanceOf(address(this), 2) >= 4, "eATK Depleted");
     
 
        alreadyMinted[msg.sender][2] = true; //stops minting
        coolDown[msg.sender][2] = block.timestamp + eightDays; //sets time action performed
       
        _safeTransferFrom(address(this), msg.sender, 2, 4, '');
 
        return eATK;
    }
 
    function getDEF() public userCantMint(3)  mintingPeriod returns(uint eDEF){
        require(balanceOf(address(this), 3) >= 4, "eATK Depleted");
     
 
        alreadyMinted[msg.sender][3] = true; //stops minting
        coolDown[msg.sender][3] = block.timestamp + eightDays; //sets time action performed
       
        _safeTransferFrom(address(this), msg.sender, 3, 4, '');
 
        return eDEF;
    }
    //(resets mint lock)
    function unlockMints(uint itemId) public returns(bool success){
        require(alreadyMinted[msg.sender][itemId] == true, "access not locked"); //ensures its locked first
        require(block.timestamp >= coolDown[msg.sender][itemId]); //ensures minting portal is closed befor unlocking
 
        alreadyMinted[msg.sender][itemId] = false; //stops minting
        coolDown[msg.sender][itemId] = 0; //sets time to 0
 
        return true;
    }
     
    //buy functions
    function buyUUJI() payable public returns(uint UUJIs){
        require(balanceOf(address(this), 0) >= 2000, "Token Supply Depleted.");
        require(msg.value >= faucetPrice, "Not enough to cover tx");
 
        require(balanceOf(address(this), 0) > escrowedTotal[escrowedValut], "Token Supply Depleted.");
       
       
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, 0, 2000, '');
 
        return UUJIs;
    }
 
    function buyHP(uint amount) payable public returns(uint HPs){
 
        require(balanceOf(address(this), 1) >= (2 * amount), "HP Depleted");
        require(msg.value >= faucetHPPrice * amount, "Not enough to cover tx");
       
        uint256 potions = 2 * amount;
 
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, 1, potions, '');
 
        emit purchase(msg.sender, 1, potions, msg.value);
 
        return HPs;
    }
 
    function buyElixer(uint amount) payable public returns(uint Elixer){
 
        require(balanceOf(address(this), 4) >= amount, "elixers Depleted");
        require(msg.value >= faucetElixerPrice * amount, "Not enough to cover tx");
       
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, 4, amount, '');
 
        return Elixer;
    }
 
    function buyWalle(uint amount) payable public returns(uint Walle){
 
        require(balanceOf(address(this), 6) >= amount, "elixers Depleted");
        require(msg.value >= faucetWallePrice * amount, "Not enough to cover tx");
       
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, 6, amount, '');
 
        return Walle;
    }
 
    function buyRevive(uint amount) payable public returns(uint Revive){
        require(balanceOf(address(this), 5) >= amount, "revives Depleted");
        require(msg.value >= faucetRevivePrice * amount, "Not enough to cover tx");
       
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, 5, amount, '');
 
        return Revive;
    }
 
    function buyEnjimon(uint id) payable public returns(bool success){
        require(balanceOf(address(this), id) > 0, "No More $Enjimon at this id");
        require(msg.value >= faucetEnjimonPrice, "Not enough to cover tx");
       
        FULLSTACKCALI.transfer(msg.value);
        _safeTransferFrom(address(this), msg.sender, id, 1, '');
 
        return true;
    }
 
    //interactions
    function mintMonster(string memory enjimonName, uint256 healthPoints, uint256 defense, uint256 attack, uint256 level, string memory enjimonType) public onlyOwner {
 
        _tokenDetails[nextId] = Enjimon(enjimonName, healthPoints, defense, attack, level, block.timestamp, enjimonType, 0,"Apus Sector");
       
        _mint(msg.sender, nextId, 1, "");
       
        emit bornDate(msg.sender, enjimonName, nextId, block.timestamp);
       
        //after first five mints, transfers to contract
        if(nextId > 11){
             _safeTransferFrom(msg.sender, address(this), nextId, 1, '');
        }
       
       
        emit transferEnjimon(msg.sender, address(this), nextId, enjimonName, 490);
       
        nextId++;
   
    }
   
    function burn(uint256 id, uint256 amount) public onlyOwner {
        require(id < 7, "cant burn $Enjimon");
       
        if(id == 0)
        {
            require(balanceOf(address(this), 0) > escrowedTotal[escrowedValut]);
            _burn(address(this), 0, amount);
           
            amountBurned+= amount;
 
             emit tokenSupplyBurned(address(this), 0, amount, block.timestamp);
             emit burnedCount(0, amountBurned, block.timestamp);
        }
        else
        {
            _burn(msg.sender, id, amount);
           
            emit itemBurned(msg.sender, id, amount, block.timestamp);
        }
     
    }
   
    function train(uint256 tokenId) public {
        require(tokenId >= 7, "invalid ID");
        require(balanceOf(msg.sender, tokenId) > 0);
       
        Enjimon storage enjimon =_tokenDetails[tokenId];
        uint uujiBalance = balanceOf(msg.sender, 0);
       
        require(block.timestamp > enjimon.lastTrained + eightHours, "still resting!");
        require(uujiBalance > (100 + (27 + enjimon.level)), "Not enough UUJI");
       
     
        _burn(msg.sender, 0, 50 );
        _escrow(50, 0);
        _safeTransferFrom(msg.sender, address(this), 0, 27 + enjimon.level, ""); //uuji fee
        _safeTransferFrom(msg.sender, escrowedValut, 0, 50, ""); //escrowedValut
 
        escrowedTotal[escrowedValut]+=50;
        amountBurned+= 50;
       
        uint index = Randomness();
     
         
        enjimon.lastTrained = block.timestamp + index;
        enjimon.level+=1;
        enjimon.defense+=(2 + index);
        enjimon.attack+=(1 + index);
        enjimon.healthPoints+=index;
       
        emit enjimonTrained(msg.sender, tokenId, enjimon.enjimonName, block.timestamp);
        emit burnedCount(0, amountBurned, block.timestamp);
    }
 
    function givePotion(uint256 enjimonId) public {
        require(enjimonId >= 7, "Invalid ID");
        require(balanceOf(msg.sender, 1) > 0);
        require(balanceOf(msg.sender, enjimonId) > 0);
       
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        uint uujiBalance = balanceOf(msg.sender, 0);
       
        require(uujiBalance > 25, "Not enough UUJI");
       
        _burn(msg.sender, 0, 15);
        _burn(msg.sender, 1, 1);
        _safeTransferFrom(msg.sender, address(this), 0, 10, "");
 
        amountBurned+= 15;
 
        uint index = Randomness();
       
        index+=5;
 
        enjimon.healthPoints+=index;
 
        emit burnedCount(0, amountBurned, block.timestamp);
 
    }
 
    function giveEATK(uint256 enjimonId) public{
        require(enjimonId >= 7, "Invalid ID");
        require(balanceOf(msg.sender, 2) > 0);
        require(balanceOf(msg.sender, enjimonId) > 0);
       
 
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        uint uujiBalance = balanceOf(msg.sender, 0);
 
        require(uujiBalance > 25, "Not enough UUJI");
       
        _burn(msg.sender, 0, 15); //burn uuji
        _burn(msg.sender, 2, 1); //burn eATK
        _safeTransferFrom(msg.sender, address(this), 0, 10, "");
 
        amountBurned+= 15;
 
        uint index = Randomness();
       
        enjimon.attack+=index;
 
        emit burnedCount(0, amountBurned, block.timestamp);
 
    }
 
    function giveEDEF(uint256 enjimonId) public{
        require(enjimonId >= 7, "Invalid ID");
        require(balanceOf(msg.sender, 3) > 0);
        require(balanceOf(msg.sender, enjimonId) > 0);
       
       
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        uint uujiBalance = balanceOf(msg.sender, 0);
 
        require(uujiBalance > 25, "Not enough UUJI");
       
        _burn(msg.sender, 0, 15);
        _burn(msg.sender, 3, 1);
        _safeTransferFrom(msg.sender, address(this), 0, 10, "");
        amountBurned+= 15;
 
        uint index = Randomness();
       
        enjimon.defense+=index;
        emit burnedCount(0, amountBurned, block.timestamp);
 
    }
 
    function giveElixer(uint256 enjimonId) public{
        require(enjimonId >= 7, "Invalid ID");
        require(balanceOf(msg.sender, 4) > 0, "no elixers!");
        require(balanceOf(msg.sender, enjimonId) > 0);
       
 
       
        Enjimon storage enjimon =_tokenDetails[enjimonId];
        uint uujiBalance = balanceOf(msg.sender, 0);
       
 
        require(uujiBalance > 30, "30 UUJI req.");
 
       
        _burn(msg.sender, 0, 15);
        _burn(msg.sender, 4, 1);
        _safeTransferFrom(msg.sender, address(this), 0, 15, "");
 
        amountBurned+= 5;
 
        uint index = Randomness();
 
        enjimon.healthPoints+= index;
        enjimon.level+= 1;
        enjimon.defense+=1;
        enjimon.attack+=1;
 
        emit burnedCount(0, amountBurned, block.timestamp);
    }
       
    function getTokenDetails(uint256 tokenId) public view returns(Enjimon memory){
        return _tokenDetails[tokenId];
 }
   
    function tradeEnjimon(address to, uint256 tokenId) public {
        require(msg.sender != to, "can't trade with self");
        require(tokenId >= 7, "invalid ID");
        require(balanceOf(msg.sender, tokenId) > 0, "invalid ID");
       
       
       
        Enjimon storage enjimon =_tokenDetails[tokenId];
     
 
       
        _safeTransferFrom(msg.sender, to, tokenId, 1, "");
       
        emit transferEnjimon(msg.sender, to, tokenId, enjimon.enjimonName, 1);
    }  
 
    function _escrow(uint amount, uint tokenId) private {
       
       uint256 previousEnjimonBalance = enjimonTVL[tokenId];
       
        enjimonTVL[tokenId] += amount;
       
       _safeTransferFrom(msg.sender, escrowedValut, 0, amount, "");
 
       assert((enjimonTVL[tokenId] - amount) == previousEnjimonBalance);
   
    }
 
    //Battle functions
 
    function pendingBattleAmount() public view returns(uint256){
        return _pendingBattle.length;
    }  
 
    function initBattle(address _opponent , uint256 challengerEnjimon) public hasNoPendingBattle
            {
               
                require(msg.sender != _opponent, "Cannot battle yourself!");
                require(balanceOf(msg.sender, 0) >= 100);
                require(balanceOf(msg.sender, challengerEnjimon) == 1);
 
                Enjimon storage enjimon =_tokenDetails[challengerEnjimon];
 
                if(isApprovedForAll(msg.sender, address(this)) == false){
                    setApprovalForAll(address(this), true);
                }
 
                _safeTransferFrom(msg.sender, address(this), 0, 50, '');
                _burn(msg.sender, 0, 50);
                amountBurned+= 50;
 
                Battle memory _pendingBattleApprovals = Battle(_pendingBattle.length, msg.sender, _opponent, false);
               
                _pendingBattle.push(_pendingBattleApprovals);
                trainerEnjimon[msg.sender] = challengerEnjimon;
                trainerBattle[msg.sender] = _pendingBattle.length;
                hasPendingBattle[msg.sender] = true;
                hasPendingBattle[_opponent] = true;
                health[msg.sender][challengerEnjimon] = enjimon.healthPoints;
               
               emit tokenSupplyBurned(msg.sender, 0, amountBurned, block.timestamp);
               emit burnedCount(0, amountBurned, block.timestamp);
               emit battleInit(msg.sender, _opponent, block.timestamp);
 
            }
 
 
    function battleDetailsPending(uint _battleId) public view returns (uint battleId, address challenger, address opponent, bool accepted)
            {
                return (_pendingBattle[_battleId].battleId, _pendingBattle[_battleId].challenger, _pendingBattle[_battleId].opponent, _pendingBattle[_battleId].accepted);
            }
 
    function approveBattle(uint _battleId, uint defendingEnjimon) public  
            {
               require(msg.sender != _pendingBattle[_battleId].challenger, "cannot approve own request!");  
               require(msg.sender == _pendingBattle[_battleId].opponent, "not your battle");
               require(balanceOf(msg.sender, defendingEnjimon) == 1);  
               require(hasPendingBattle[msg.sender] == true);
 
                Enjimon storage enjimon =_tokenDetails[defendingEnjimon];
 
                if(isApprovedForAll(msg.sender, address(this)) == false){
                    setApprovalForAll(address(this), true);
                }
 
                hasPendingBattle[msg.sender] = false;
                hasPendingBattle[_pendingBattle[_battleId].challenger] = false;
 
                trainerEnjimon[msg.sender] = defendingEnjimon;
                trainerBattle[msg.sender] = trainerBattle[_pendingBattle[_battleId].challenger];
                _pendingBattle[_battleId].accepted= true;
 
                isInBattle[msg.sender] = true;
                isInBattle[_pendingBattle[_battleId].challenger] = true;
 
                trainersTurn[_pendingBattle[_battleId].challenger] = true;
                trainersTurn[msg.sender] = false;
                health[msg.sender][defendingEnjimon] = enjimon.healthPoints;
 
                emit battleApproved(msg.sender, _pendingBattle[_battleId].challenger, block.timestamp);                
            }
 
   
    function attack(uint256 _battleId) public{
       require(isInBattle[msg.sender] == true, "must be in battle");
       require(trainersTurn[msg.sender] == true, "not your turn");
 
       
       address _opponent = _pendingBattle[_battleId].opponent;
       address _challenger =_pendingBattle[_battleId].challenger;
 
       
      Enjimon storage enjimon1 =_tokenDetails[trainerEnjimon[_challenger]]; //challenger
      Enjimon storage enjimon2 =_tokenDetails[trainerEnjimon[ _opponent]]; //opponent
 
        if(msg.sender ==  _challenger){
           turnTime[msg.sender] = block.timestamp;
           uint256 damage = enjimon2.defense - enjimon1.attack;
 
           if(enjimon2.healthPoints - damage <= 0){
               enjimon2.healthPoints = 0;
               uint256 reward = enjimon2.TVL;
               enjimon2.TVL = 0;
               escrowedTotal[escrowedValut]-= reward;
 
               _safeTransferFrom(_opponent, address(this),trainerEnjimon[_opponent] , 1,'' );
               _safeTransferFrom(address(this), _challenger, 0 , reward,'' );
 
               uint index = Randomness();
 
                enjimon1.level+=1;
                enjimon1.defense+=(2 + index);
                enjimon1.attack+=(1 + index);
                enjimon1.healthPoints = health[msg.sender][trainerEnjimon[msg.sender]] + index;
 
                trainerLevel[msg.sender]+=1;
               
               nurseryEnjimon[_opponent][trainerEnjimon[_opponent]] = 1;
 
               isInBattle[_challenger] = false;
               isInBattle[_opponent] = false;
 
               trainersTurn[msg.sender] = false;
               trainersTurn[_opponent] = false;
 
            emit battleResults(_challenger, _opponent, reward, block.timestamp);
            emit nurseryTransfer(_opponent, trainerEnjimon[_opponent], block.timestamp);
 
           }else{
 
               enjimon2.healthPoints-= damage;
 
               trainersTurn[msg.sender] = false;
               trainersTurn[_opponent] = true;
           }
 
        }else if(msg.sender ==  _opponent){
            turnTime[msg.sender] = block.timestamp;
            uint256 damage = enjimon1.defense - enjimon2.attack;
 
            if(enjimon1.healthPoints - damage <= 0){
               enjimon1.healthPoints = 0;
               uint256 reward = enjimon1.TVL;
               enjimon1.TVL = 0;
               escrowedTotal[escrowedValut]-= reward;
 
               _safeTransferFrom(_challenger, address(this), trainerEnjimon[_challenger] , 1,'' );
               _safeTransferFrom(address(this), _opponent, 0 , reward,'' );
 
                uint index = Randomness();
 
                enjimon2.level+=1;
                enjimon2.defense+=(2 + index);
                enjimon2.attack+=(1 + index);
                enjimon2.healthPoints = health[msg.sender][trainerEnjimon[msg.sender]] + index;
 
                trainerLevel[msg.sender]+=1;
               
               nurseryEnjimon[_challenger][trainerEnjimon[_challenger]] = 1;
 
               isInBattle[_challenger] = false;
               isInBattle[_opponent] = false;
 
               trainersTurn[msg.sender] = false;
               trainersTurn[_opponent] = false;
 
               emit battleResults(_opponent, _challenger, reward, block.timestamp);
               emit nurseryTransfer(_challenger, trainerEnjimon[_challenger], block.timestamp);
 
           }else{
               
                enjimon1.healthPoints-= damage;
 
               trainersTurn[msg.sender] = false;
               trainersTurn[_challenger] = true;
           }
        }
 
    }        
 
    function nursery(uint256 _id) public {
        require(balanceOf(msg.sender, 5) >= 1);
        require(balanceOf(msg.sender, 6) >= 1);
        require(nurseryEnjimon[msg.sender][_id] == 1);
 
        _burn(msg.sender, 5, 1);
        _burn(msg.sender, 6, 1);
 
        Enjimon storage enjimon =_tokenDetails[_id];
        enjimon.healthPoints = health[msg.sender][_id];
 
        nurseryEnjimon[msg.sender][_id] = 0;
        _safeTransferFrom(address(this), msg.sender, _id, 1, '');
 
        emit enjimonRevived(msg.sender, _id, block.timestamp);
    }
 
    function cancelBattle(uint256 _battleId) public returns(bool){
        require(msg.sender == _pendingBattle[_battleId].challenger);
        require(isInBattle[msg.sender] == false, "All ready in battle");
 
         hasPendingBattle[msg.sender] = false;
         hasPendingBattle[_pendingBattle[_battleId].opponent] = false;
 
         delete _pendingBattle[_battleId];
 
        return true;
    }
   
 
    function retreat(uint256 _battleId) public returns(bool){
        require(isInBattle[msg.sender] == true);
        require(balanceOf(msg.sender, 0) >= 50);
        require(trainersTurn[msg.sender] == true);
 
        safeTransferFrom(msg.sender, _pendingBattle[_battleId].opponent, 0, 25, '');
        _burn(msg.sender, 0, 25);
        amountBurned+= 25;
 
        isInBattle[_pendingBattle[_battleId].opponent] = false;
        isInBattle[_pendingBattle[_battleId].challenger] = false;
 
        delete _pendingBattle[_battleId];
 
        return true;
    }
   
 
    function stalePlayer(uint256 _battleId) public returns(bool){
        require(isInBattle[msg.sender] == true);
        require(block.timestamp >= (turnTime[msg.sender] + battleTimer));
 
   
        isInBattle[_pendingBattle[_battleId].opponent] = false;
        isInBattle[_pendingBattle[_battleId].challenger] = false;
 
        delete _pendingBattle[_battleId];
 
        return true;
    }
           
    function getLevel() public view returns(uint256 level){
        
        return trainerLevel[msg.sender];
    }       
   
}