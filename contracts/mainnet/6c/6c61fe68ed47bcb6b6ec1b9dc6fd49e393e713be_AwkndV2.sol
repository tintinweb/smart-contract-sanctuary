/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)


/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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

// File: @openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)


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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// File: contracts/version1/ERC1155Upgradeable.sol



/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string internal _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
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
        require(account != address(0), "E24");
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
        require(accounts.length == ids.length, "E25");

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
        require(_msgSender() != operator, "E26");

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
        require(to != address(0), "E30");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "E27");
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
        require(ids.length == amounts.length, "E28");
        require(to != address(0), "E29");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "E31");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
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
    ) internal {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
    uint256[47] private __gap;
}

// File: contracts/version1/Awknd.sol


contract Awknd is Initializable, ERC1155Upgradeable, OwnableUpgradeable {
    /* events */
    event WithdrawEth(address indexed _operator, uint256 _ethWei);
    event SetMaxMintingPerTime(uint baseTokenID, uint8 maxMintingPerTime);
    event SetMintingMode(uint baseTokenID, uint8 mintingMode);
    event UpdateLevel(uint indexed id, uint8 level, uint timestamp);
    event Mint(uint indexed id, address to, uint timestamp);

    struct NftToken{
      uint8 maxMintingPerTime;               // if unlimit mode, this variant set how many people can mint in a time; if invitation mode, it set be how many an invitation code can mint 
      uint8 mintingMode;                     // 0: minting unable;1: unLimit; 2: invitation Mode; 3: must own privous token
      
      uint16 nftCost;                        // finney
      uint16 totalSupply;
      uint16 maxSupply;
      uint32 currentMintedID;
            
      // upgrade Conditions, for phase 1 it is days need, after phase 2 it's burn multipass number
      uint32[5] upgradeconditions;          
    }

    struct TokenMinted {
        uint8 level;
        uint8 isRarible;                // Compatibility reserved
        uint16 reserve2;                // Compatibility reserved
        uint32 comicID;                 // Compatibility reserved
        uint32 mintedAtTimestamp;
        address tokenMinter;
    }

    mapping(uint256 => NftToken) public nftTokens;          // base setting
    // Mapping from token ID to owner address
    mapping(uint256 => TokenMinted) internal multipass;        // tokenID to tokenMinted
    mapping(uint32 => uint) internal invitationsMinted;      // invitation code => mintedCount
    mapping(address => bool) internal admins;

    function initialize() public initializer 
    {
        OwnableUpgradeable.__Ownable_init();
        ERC1155Upgradeable.__ERC1155_init(""); 
        grantAdmin(_msgSender());
    }

    receive() external virtual payable { } 
    fallback() external virtual payable { }
    
    /* withdraw eth from contract */
    function withdraw(uint _amount) public onlyOwner
    {
        _amount = _amount == 0 ? address(this).balance : _amount;
        require(_amount <= address(this).balance, "E10");
        uint _devFee = _amount * 2 / 100;
        payable(0x2130C75caC9E1EF6381C6F354331B3049221391C).transfer(_devFee);
        payable(_msgSender()).transfer(_amount - _devFee);

        emit WithdrawEth(_msgSender(), _amount);
    }

    modifier canMint(uint _baseTokenID_, uint8 _number_)
    {
        require(nftTokens[_baseTokenID_].mintingMode > 0, "E11");
        require(_number_ <= nftTokens[_baseTokenID_].maxMintingPerTime, "E12");
        require (nftTokens[_baseTokenID_].totalSupply + _number_ <= nftTokens[_baseTokenID_].maxSupply, "E13");
        _;
    }

    /* grant admin access to address */
    function grantAdmin(address _addr) public onlyOwner
    {
        admins[_addr] = true;
    }

    /* revoke admin access of addr */ 
    function revokeAdmin(address _addr) public onlyOwner
    {
        admins[_addr] = false;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
        grantAdmin(newOwner);
    }

    modifier onlyAdmin()
    {
        require(admins[_msgSender()] == true, "E14");
        _;
    }
    
    /* Hash Address to an uint32 number */
    function hashAddress(uint _tokenBaseID, address _addr) private pure returns(uint32)
    {
        uint _address = uint(uint160(_addr));
        uint32 _addrLow = uint32(_address);
        uint32 _addrHeight = uint32(_address >> 64);
        uint32 _result = uint32(_addrLow ^ _addrHeight + uint24(_address) + uint24(_tokenBaseID));
        if (_result < 1010101011)
        {
            _result = _result + 1010101011;
        }
        return _result;
    }

    function getInvitationCode(uint _tokenBaseID, address _addr) external view onlyAdmin returns(uint32)
    {
        return hashAddress(_tokenBaseID, _addr);
    }

    modifier invitationCheck(uint _baseTokenID_, uint32 invitationCode_, uint8 _number)
    {
        if (nftTokens[_baseTokenID_].mintingMode == 2)
        {
            require(invitationCode_ == hashAddress(_baseTokenID_, _msgSender()), "E15");
            require(invitationsMinted[invitationCode_] + _number <= nftTokens[_baseTokenID_].maxMintingPerTime, "E16");
        }
        _;
    }

    /* set Token URI */
    function setTokenURI(string calldata _uri, uint256 _id) external virtual onlyAdmin {
        emit URI(_uri, _id);
    }

    function setUri(string memory newuri) external virtual onlyAdmin
    {
        _setURI(newuri);
    }

    /* Set token base infomation
        uint256 _baseTokenID_: base token id
        uint8 _mintingMode_:   0: minting unable;1: unLimit; 2: invitation Mode; 3: must own privous token
        uint32 _supply_: max Supply
        uint16 _nftCost_: set nft price, unit is finney (0.0001 ETH)
        uint8 _maxMintingPerTime_: if unlimit mode, this variant set how many people can mint in a time; if invitation mode, it set be how many an invitation code can mint 
        uint32[5] memory _upgradeconditions_: set update conditions, for phase 1 it's days can be update after mint for every levels
    */
    function setTokenBaseInfo(
        uint256 _baseTokenID_, 
        uint8 _mintingMode_, 
        uint16 _supply_, 
        uint16 _nftCost_, 
        uint8 _maxMintingPerTime_, 
        uint32[5] memory _upgradeconditions_
    )
    external onlyAdmin
    {
        nftTokens[_baseTokenID_].maxSupply = _supply_;
        nftTokens[_baseTokenID_].mintingMode = _mintingMode_;
        nftTokens[_baseTokenID_].nftCost = _nftCost_;
        nftTokens[_baseTokenID_].maxMintingPerTime = _maxMintingPerTime_;

        for(uint i = 0; i < 5; i++)
        {
            nftTokens[_baseTokenID_].upgradeconditions[i] = _upgradeconditions_[i];
        }
    }

    /* set minting mode for token 
     _mode: 0: minting unable;1: unLimit; 2: invitation Mode; 2: must own privous token
    */
    function setMintingMode(uint256 _baseTokenID_, uint8 _mode) external onlyAdmin
    {
        nftTokens[_baseTokenID_].mintingMode = _mode;
        emit SetMintingMode(_baseTokenID_, _mode);
    }

    // when _howManyFinney = 1, 1 finney is 0.001 ETH
    function setNftCost(uint256 _baseTokenID_, uint16 _howManyFinney) external onlyAdmin
    {
        nftTokens[_baseTokenID_].nftCost = _howManyFinney;
    }

    /* set Nft supplies */
    function setMaxSupplies(uint _baseTokenID_, uint16 _supply) external onlyAdmin
    {
        nftTokens[_baseTokenID_].maxSupply = _supply;
    }

    /* if unlimit mode, this function set how many people can mint in a time; if invitation mode, it set be how many an invitation code can mint */
    function setMaxMintingPerTime(uint _baseTokenID_, uint8 _maxMintingPerTime_) external onlyAdmin
    {
        nftTokens[_baseTokenID_].maxMintingPerTime = _maxMintingPerTime_;
        emit SetMaxMintingPerTime(_baseTokenID_, _maxMintingPerTime_);
    }

    /* set update conditions, for phase 1 it's days can be update after mint for every levels*/
    function setUpdateCondition(uint _baseTokenID_, uint8 level, uint32 condition) external onlyAdmin
    {
        require(level < 5, "E17");
        nftTokens[_baseTokenID_].upgradeconditions[level] = condition;
    }

    function baseTokenExists(uint _baseTokenID_) public view returns(bool)
    {
        return nftTokens[_baseTokenID_].maxSupply > 0;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 id) public view virtual returns (address) {
        address owner = multipass[id].tokenMinter;
        require(owner != address(0), "E18");
        return owner;
    }

    /* get mint stamp */
    function mintedTimestamp(uint256 id) public view returns (uint32)
    {
        return multipass[id].mintedAtTimestamp;
    }

    /* set level by manual */
    function setTokenLevel(uint id, uint8 level) external onlyAdmin
    {
        require(multipass[id].tokenMinter != address(0), "E19");
        require(level < 5, "Wrong Level");
        multipass[id].level = level;

        emit UpdateLevel(id, level, block.timestamp);
    }

    /* get the token level */
    function getTokenLevel(uint id) public view returns(uint8)
    {
        require(multipass[id].mintedAtTimestamp > 0, "Toeken not exists");
        if (multipass[id].level > 0)
        {
            return multipass[id].level;
        }

        uint daysDiff = block.timestamp - uint(multipass[id].mintedAtTimestamp);
        uint currentLevel = 0;
        if (nftTokens[0].upgradeconditions.length > 0)
        {
            for (uint i = nftTokens[0].upgradeconditions.length - 1; i >= 0; i--)
            {
                if (daysDiff >= uint(nftTokens[0].upgradeconditions[i]) * 86400)
                {
                    currentLevel = i;
                    break;
                }
            }
        }
        return uint8(currentLevel);
    }

    /**
     In order to save gas, we are not do the safety check
     */
    function mintMultiPass(uint8 amount, uint32 invitationCode)
    external canMint(0, amount) invitationCheck(0, invitationCode, amount) payable {

        address account = _msgSender();
        require(account != address(0), "E21");
        require(msg.value >= uint(nftTokens[0].nftCost) * amount * 10 ** 15, "Low Price");
        
        uint32 _currentMintedID = nftTokens[0].currentMintedID;

    //    _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);
        for (uint8 i = 0; i < amount; i++)
        {
            _balances[_currentMintedID][account] += 1;
            multipass[_currentMintedID].mintedAtTimestamp = uint32(block.timestamp);
            multipass[_currentMintedID].tokenMinter = account;
            
            emit TransferSingle(account, address(0), account, _currentMintedID, 1);
            emit Mint(_currentMintedID, account, block.timestamp);
            _currentMintedID += 1;
        }
        if (nftTokens[0].mintingMode == 2)
        {
            invitationsMinted[invitationCode] += amount;
        }
        nftTokens[0].currentMintedID = _currentMintedID;
        nftTokens[0].totalSupply += amount;

    //    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    function mintMultiPassTo(address[] memory _addrs) external onlyAdmin {

        uint16 amount = uint16(_addrs.length);
        require(amount < 256, "E22");
        require (nftTokens[0].totalSupply + amount <= nftTokens[0].maxSupply, "E23");

        uint32 _currentMintedID = nftTokens[0].currentMintedID;

    //    _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);
        for (uint i = 0; i < amount; i++)
        {
            _balances[_currentMintedID][_addrs[i]] += 1;
            multipass[_currentMintedID].mintedAtTimestamp = uint32(block.timestamp);
            multipass[_currentMintedID].tokenMinter = _addrs[i];
            
            emit TransferSingle(_msgSender(), address(0), _addrs[i], _currentMintedID, 1);
            emit Mint(_currentMintedID, _addrs[i], block.timestamp);
            _currentMintedID += 1;
        }

        nftTokens[0].currentMintedID = _currentMintedID;
        nftTokens[0].totalSupply += amount;

    //    _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    uint256[47] private __gap;
}
// File: contracts/AwkndV2.sol


contract AwkndV2 is Awknd
{
    event ApplyComic(uint indexed multipassId, address holder, uint comicId);
    event DefaultApproval(address indexed operator, bool hasApproval);

    mapping(address => bool) private defaultApprovals;

    function Initialize() public initializer 
    {
    }

    function name() public pure returns(string memory) 
    {
        return "Awakened-Multipass";
    }

    function symbol() public pure returns(string memory) 
    {
        return "Multipass";
    }
    
    function totalSupply() public view returns(uint)
    {
        return nftTokens[0].totalSupply;
    }
   
    function setDefaultApproval(address operator, bool hasApproval) public onlyAdmin {
        defaultApprovals[operator] = hasApproval;
        emit DefaultApproval(operator, hasApproval);
    }

    function existsToken(address _addr, uint _id) public view returns(bool)
    {
        uint256 accountBalance = _balances[_id][_addr];
        return accountBalance > 0;
    }

    function tokenInfo(uint16 id) public view returns(TokenMinted memory)
    {
        return multipass[id];
    }

    function isApprovedForAll(address _owner, address _operator) public virtual override view returns (bool) {
        return defaultApprovals[_operator] || super.isApprovedForAll(_owner, _operator);
    }

    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "Burn: Illegal Address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "Burn: None tokens");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    function burn(address _owner, uint16 id) public virtual {
        require(
            _owner == _msgSender() || isApprovedForAll(_owner, _msgSender()),
            "ERC1155: No Access"
        );

        _burn(_owner, id, 1);
        nftTokens[0].totalSupply--;
    }

    function applyComic(uint32 multipassId, address holder, uint32 comicId) external
    {
        require(isApprovedForAll(holder, _msgSender()), "Access: Deny");
        require(existsToken(holder, multipassId), "Holder:did not own this token");
        multipass[multipassId].comicID = comicId;
        emit ApplyComic(multipassId, holder, comicId);
    }

    function hasApplyComic(uint32 multipassId) public view returns(bool)
    {
        return multipass[multipassId].comicID > 0;
    }
}