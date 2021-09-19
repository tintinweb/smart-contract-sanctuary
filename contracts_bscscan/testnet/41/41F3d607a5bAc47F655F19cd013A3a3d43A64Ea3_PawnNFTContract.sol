/**
 *Submitted for verification at BscScan.com on 2021-09-19
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

 

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

 

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

 

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

 

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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/utils/[email protected]

 

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/utils/[email protected]

 

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

 

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 

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


// File @openzeppelin/contracts-upgradeable/security/[email protected]

 

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

 

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

 

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]

 

pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

 

pragma solidity ^0.8.0;


/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

 

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

 

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File contracts/evaluation/DFY-AccessControl.sol

 

pragma solidity ^0.8.4;
contract DFYAccessControl is AccessControlUpgradeable {
    using AddressUpgradeable for address;
    
    /**
    * @dev OPERATOR_ROLE: those who have this role can assigne EVALUATOR_ROLE to others
    */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
    * @dev PAUSER_ROLE: those who can pause the contract
    * by default this role is assigned to the contract creator
    *
    * NOTE: The main contract must inherit `Pausable` or this ROLE doesn't make sense
    */ 
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
    * @dev EVALUATOR_ROLE: Whitelisted Evaluators who can mint NFT token after evaluation has been accepted.
    */
    bytes32 public constant EVALUATOR_ROLE = keccak256("EVALUATOR_ROLE");

    function __DFYAccessControl_init() internal initializer {
        __AccessControl_init();

        __DFYAccessControl_init_unchained();
    }

    function __DFYAccessControl_init_unchained() internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        
        // Set OPERATOR_ROLE as EVALUATOR_ROLE's Admin Role 
        _setRoleAdmin(EVALUATOR_ROLE, OPERATOR_ROLE);
    }

    event ContractAdminChanged(address from, address to);

    /**
    * @dev change contract's admin to a new address
    */
    function changeContractAdmin(address newAdmin) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        // Check if the new Admin address is a contract address
        require(!newAdmin.isContract(), "New admin must not be a contract");
        
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());

        emit ContractAdminChanged(_msgSender(), newAdmin);
    }
}


// File contracts/evaluation/IDFY_Physical_NFTs.sol

 

pragma solidity ^0.8.4;

interface IDFY_Physical_NFTs {

    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        returns (uint256 tokenId);
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/extensions/[email protected]

 

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/token/ERC1155/[email protected]

 

pragma solidity ^0.8.0;







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
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

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

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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
    uint256[47] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC1155/extensions/[email protected]

 

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Burnable_init_unchained();
    }

    function __ERC1155Burnable_init_unchained() internal initializer {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
    uint256[50] private __gap;
}


// File contracts/evaluation/DFY_Physical_NFTs.sol

 

pragma solidity ^0.8.4;
contract DFY_Physical_NFTs is 
    IDFY_Physical_NFTs,
    Initializable,
    UUPSUpgradeable, 
    ERC1155Upgradeable, 
    DFYAccessControl, 
    PausableUpgradeable, 
    ERC1155BurnableUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;

    // Total NFT token
    CountersUpgradeable.Counter public totalToken;
    
    // Address evaluation
    address public evaluationContract;

    // Mapping list tokenId to CID
    // TokenId => CID
    mapping(uint256 => string) public tokenIdListToCID;

    // Mapping token id to information evaluation of NFT token 
    // TokenId => NFTEvaluation
    mapping (uint256 => NFTEvaluation) public tokenIdOfEvaluation;

    // Mapping tokenId to owner
    // TokentId => address
    mapping(uint256 => address) public tokenIdByOwner;

    // Mapping address by tokenId
    // Owner => listTokenId
    mapping (address => uint256[]) public tokenIdListByOwner;

    // Mapping evaluator to NFT 
    // Address evaluator => listTokenId
    mapping (address => uint256[] ) public tokenIdListByEvaluator;

    // Struct NFT Evaluation
    struct NFTEvaluation{
        address evaluationContract;
        uint256 evaluationId;
    }

    // Name NFT token
    string public name;

    // Symbol NFT token
    string public symbol;

    // Base URI NFT Token
    string private _tokenBaseUri;

    // Event NFT create success
    event NFTCreated(
        address assetOwner,
        uint256 tokenID,
        string cid
    );

    // Modifier check contract valuation call mint NFT token
    modifier onlyEvaluation {
        require(msg.sender == evaluationContract, 'Cant mint.');
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __ERC1155_init("");
        __DFYAccessControl_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __UUPSUpgradeable_init();

        name = _name;
        symbol = _symbol;
        
        _setBaseURI(_uri);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}


    function _setBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Blank baseURI");
        _tokenBaseUri = _uri;
    }

    function _baseURI() internal view returns (string memory) {
        return _tokenBaseUri;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return bytes(tokenIdListToCID[tokenId]).length > 0;
    }

    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(_uri);
    }

    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Invalid token");

        string memory baseUri = _baseURI();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenIdListToCID[tokenId])) : "";
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
    * @dev set address evaluation contract
    * @param _evaluationContract is address evaluation contract
    */
    function setEvaluationContract(address _evaluationContract) external onlyRole(DEFAULT_ADMIN_ROLE){
        // Check address different address(0)
        require(_evaluationContract != address(0), "Zero address.");

        // Check address is contract
        require(_evaluationContract.isContract(), "Not a contract.");

        // Set address evaluation
        evaluationContract = _evaluationContract;
    }

    /**
    * @dev evaluation contract call this function mint NFT token
    * @param _assetOwner is owner of asset mint NFT token
    * @param _evaluator is evaluator mint NFT
    * @param _evaluatontId is id evaluation NFT token
    * @param _amount is amount NFT token
    * @param _cid is cid of NFT token
    * @param _data is data of NFT token
    */
    function mint(
        address _assetOwner, 
        address _evaluator, 
        uint256 _evaluatontId, 
        uint256 _amount, 
        string memory _cid, 
        bytes memory _data
    ) 
        external
        override 
        onlyEvaluation 
        returns (uint256 tokenId)
    {
        // Gennerate tokenId
        tokenId = totalToken.current();

        // Add mapping tokenId to CID
        tokenIdListToCID[tokenId] = _cid;

        // Create NFT Evaluation and add to list
        tokenIdOfEvaluation[tokenId] = NFTEvaluation({
            evaluationContract: msg.sender,
            evaluationId: _evaluatontId
        });

        // Add mapping tokenId to address owner
        tokenIdByOwner[tokenId] = _assetOwner;

        // Add tokenId to list tokenId by owner
        tokenIdListByOwner[_assetOwner].push(tokenId);

        // Add tokenId to list tokenId by evaluator
        tokenIdListByEvaluator[_evaluator].push(tokenId);

        // Mint nft
        _mint(_assetOwner, tokenId, _amount, _data);

        // Update tokenId count
        totalToken.increment();

        emit NFTCreated(_assetOwner, tokenId, _cid);

        return tokenId;
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) 
        internal 
        override whenNotPaused 
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}


// File contracts/evaluation/IBEP20.sol

 
pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/evaluation/EvaluationContract.sol

 

pragma solidity ^0.8.4;
contract AssetEvaluation is 
    Initializable,
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable,
    ERC1155HolderUpgradeable, 
    PausableUpgradeable, 
    DFYAccessControl
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint;

    // Total asset
    CountersUpgradeable.Counter public totalAssets;

    // DFY Token;
    IBEP20 public ibepDFY;

    // NFT Token;
    IDFY_Physical_NFTs public dfy_physical_nfts;

    // Address admin
    address private addressAdmin;

    // Assuming _assetBaseUri = "https://ipfs.io/ipfs"
    string private _assetBaseUri;

    // Mapping list asset
    // AssetId => Asset
    mapping (uint256 => Asset) public assetList;

    // Mapping from creator to asset
    // Creator => listAssetId
    mapping (address => uint256[]) public assetListByCreator; 

    // Mapping from creator address to assetId in his/her possession
    // Creator => (assetId => bool)
    mapping (address => mapping (uint256 => bool)) private _assetsOfCreator;

    // Total evaluation
    CountersUpgradeable.Counter public totalEvaluation;

    // Mapping list evaluation
    // EvaluationId => evaluation
    mapping (uint256 => Evaluation) public evaluationList;

    // Mapping from asset to list evaluation
    // AssetId => listEvaluationId
    mapping (uint256 => uint256[]) public evaluationByAsset;

    // Mapping from evaluator to evaluation
    // Evaluator => listEvaluation
    mapping (address => uint256[]) public evaluationListByEvaluator;

    // Mapping tokenId to asset
    // TokenId => asset
    mapping (uint256 => Asset) public tokenIdByAsset;

    // Mapping tokenId to evaluation
    // TokenId => evaluation
    mapping (uint256 => Evaluation) public tokenIdByEvaluation;

    function initialize(
        string memory _uri,
        address _dfy1155_physical_nft_address,
        address _ibep20_DFY_address
    ) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();

        _setAssetBaseURI(_uri);

        _setNFTAddress(_dfy1155_physical_nft_address);

        _setTokenIBEP20Address(_ibep20_DFY_address);

        _setAddressAdmin(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // Enum status asset
    enum AssetStatus {OPEN, EVALUATED, NFT_CREATED}

    // Asset
    struct Asset {
        string assetDataCID;
        address creator;
        AssetStatus status;
    }

    // Enum status evaluation
    enum EvaluationStatus {EVALUATED, EVALUATION_ACCEPTED, EVALUATION_REJECTED, NFT_CREATED}

    // Evaluation
    struct Evaluation {
        uint256 assetId;
        string  evaluationCID;
        uint256 depreciationRate;
        address evaluator;
        address token;
        uint256 price;
        EvaluationStatus status;
    }

    event AssetCreated (
        uint256 assetId,
        Asset asset
    );

    event AssetEvaluated(
        uint256 evaluationId,
        uint256 assetId,
        Asset asset,
        Evaluation evaluation
    );

    event ApproveEvaluator(
        address evaluator
    );

    // Modifier check address call function
    modifier OnlyEOA() {
        require(!msg.sender.isContract(), "Calling from a contract");
        _;
    }

    // Function set base uri
    function setBaseURI(string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAssetBaseURI(_uri);
    }

    // Function set asset base uri
    function _setAssetBaseURI(string memory _uri) internal {
        require(bytes(_uri).length > 0, "Empty asset URI");
        _assetBaseUri = _uri;
    }

    // Function  
    function assetURI(uint256 _assetId) external view returns (string memory){
        return bytes(_assetBaseUri).length > 0 ? string(abi.encodePacked(_assetBaseUri, assetList[_assetId].assetDataCID)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) returns (bool){
        return super.supportsInterface(interfaceId);
    }


    /**
    * @dev Set the current NFT contract address to a new address
    * @param _newAddress is the address of the new NFT contract
    */
    function setNftContractAddress(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");
        
        _setNFTAddress(_newAddress);
    }

    function _setNFTAddress(address _newAddress) internal {
        dfy_physical_nfts = IDFY_Physical_NFTs(_newAddress);
    }

    /**
    * @dev Set the current NFT contract address to a new address
    * @param _newAddress is the address of the new NFT contract
    */
    function setTokenIBEP20Address(address _newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Verify if the new address is a contract or not
        require(_newAddress.isContract(), "Not a contract");
        
        _setTokenIBEP20Address(_newAddress);
    }

    function _setTokenIBEP20Address(address _newAddress) internal {
        ibepDFY = IBEP20(_newAddress);
    }

    
    function _setAddressAdmin(address _newAddress) internal {
        addressAdmin = _newAddress;
    }

    /**
    * @dev Asset creation request by customer
    * @dev msg.sender is the asset creator's address
    * @param _cid is the CID string of the asset's JSON file stored on IFPS
    */
    function createAssetRequest(string memory _cid) external OnlyEOA {
        // TODO: Require validation of msg.sender
        // msg.sender must not be a contract address

        // Require length _cid >0
        require(bytes(_cid).length > 0, "Asset CID must not be empty.");

        // Create asset id
        uint256 _assetId = totalAssets.current();

        // Add asset from asset list
        assetList[_assetId] =  Asset({
                                assetDataCID: _cid,
                                creator: msg.sender,
                                status: AssetStatus.OPEN
                            });
        
        // Add asset id from list asset id of owner
        assetListByCreator[msg.sender].push(_assetId);

        // Update status from asset id of owner 
        _assetsOfCreator[msg.sender][_assetId] = true;

        // Update total asset
        totalAssets.increment();

        emit AssetCreated(_assetId, assetList[_assetId]);
    }

    /**
    * @dev Return a list of asset created by _creator 
    * @param _creator address representing the creator / owner of the assets.
    */
    function getAssetsByCreator(address _creator) external view returns (uint256[] memory) {
        // TODO: Input data validation
        require(_creator != address(0), "There is no asset associated with the zero address");

        return assetListByCreator[_creator];
    }

    // Function check asset of creator
    function _isAssetOfCreator(address _creator, uint256 _assetId) internal view returns (bool) {
        return _assetsOfCreator[_creator][_assetId];
    }

    /**
    * @dev Asset evaluation by evaluator
    * @dev msg.sender is evaluator address
    * @param _assetId is the ID of the asset in AssetList
    * @param _currency is address of the token who create the asset
    * @param _price value of the asset, given by the Evaluator
    * @param _evaluationCID is Evaluation CID
    * @param _depreciationRate is depreciation rate of asset
    */
    function evaluateAsset(uint256 _assetId, address _currency, uint256 _price, string memory _evaluationCID, uint256 _depreciationRate) external OnlyEOA onlyRole(EVALUATOR_ROLE) {
        // TODO
        // Require validation of msg.sender
        require(msg.sender != address(0),"Caller address different address(0).");

        // Check evaluation CID
        require(bytes(_evaluationCID).length >0, "Evaluation CID not be empty.");

        // Require address currency is contract
        require(_currency.isContract(), "Address token is not defined.");

        // Require validation is creator asset
        require(!_isAssetOfCreator(msg.sender, _assetId), "You cant evaluted your asset.");

        // Require validation of asset via _assetId
        require(_assetId >=0 ,"Asset does not exist.");

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset is exists
        require(bytes(_asset.assetDataCID).length >0, "Asset does not exists.");

        // check status asset
        require(_asset.status == AssetStatus.OPEN, "This asset evaluated.");

        // Create evaluation id
        uint256 _evaluationId = totalEvaluation.current();
        
        // Add evaluation to evaluationList 
        evaluationList[_evaluationId] = Evaluation({
                                                assetId: _assetId,
                                                evaluationCID: _evaluationCID,
                                                depreciationRate: _depreciationRate,
                                                evaluator: msg.sender,
                                                token: _currency,
                                                price: _price,
                                                status: EvaluationStatus.EVALUATED
                                            });
        
        
        // Add evaluation id to list evaluation of asset
        evaluationByAsset[_assetId].push(_evaluationId);

        // Add evaluation id to list evaluation of evaluator 
        evaluationListByEvaluator[msg.sender].push(_evaluationId);

        // Update total evaluation
        totalEvaluation.increment();

        emit AssetEvaluated(_evaluationId,_assetId,_asset,evaluationList[_evaluationId]);
    }

    /** 
    * @dev this function is check data when customer accept or reject evaluation
    * @param _assetId is the ID of the asset in AssetList
    * @param _evaluationId is the look up index of the Evaluation data in EvaluationsByAsset list
    */
    function _checkDataAcceptOrReject(uint256 _assetId, uint256 _evaluationId) internal view returns (bool) {
        
        // Check creator is address 0
        require(msg.sender != address(0), "ZERO_ADDRESS"); // msg.sender must not be the zero address

        // Check asset id
        require(_assetId >= 0, "INVALID_ASSET"); // assetId must not be zero

        // Check evaluation index
        require(_evaluationId >= 0, "INVALID_EVA"); // evaluationID must not be zero

        // Get asset to asset id;
        Asset memory _asset = assetList[_assetId];

        // Check asset to creator
        require(_asset.creator == msg.sender, "NOT_THE_OWNER"); // msg.sender must be the creator of the asset

        // Check asset is exists
        require(_asset.status == AssetStatus.OPEN, "EVA_NOT_ALLOWED"); // asset status must be Open

        // approve an evaluation by looking for its index in the array.
        Evaluation memory _evaluation = evaluationList[_evaluationId];

        // Check status evaluation
        require(_evaluation.status == EvaluationStatus.EVALUATED, "ASSET_NOT_EVALUATED"); // evaluation status must be Evaluated
        
        return true;
    }

    /**
    * @dev This function is customer accept an evaluation
    * @param _assetId is id of asset
    * @param _evaluationId is id evaluation of asset
    */    
    function acceptEvaluation(uint256 _assetId, uint256 _evaluationId) external OnlyEOA {

        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];
        
        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_ACCEPTED;
        
        // Reject all other evaluation of asset
        for(uint i = 0; i < evaluationByAsset[_assetId].length; i++) {
            if(evaluationByAsset[_assetId][i] != _evaluationId) {
                uint256  _evaluationIdReject = evaluationByAsset[_assetId][i];
                
                // Get evaluation
                Evaluation storage _otherEvaluation = evaluationList[_evaluationIdReject];
        
                // Update status evaluation
                _otherEvaluation.status = EvaluationStatus.EVALUATION_REJECTED;

                emit AssetEvaluated(_evaluationId,_assetId, _asset, _otherEvaluation);
            }
        }

        // Update status asset
        _asset.status = AssetStatus.EVALUATED;

        emit AssetEvaluated(_evaluationId, _assetId, _asset , _evaluation);
    }

    /**
    * @dev This function is customer reject an evaluation
    * @param _assetId is id of asset
    * @param _evaluationId is id evaluation of asset
    */ 
    function rejectEvaluation(uint256 _assetId, uint256 _evaluationId) external OnlyEOA {

        // Check data
        require(_checkDataAcceptOrReject(_assetId, _evaluationId));

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];
        
        // Update status evaluation
        _evaluation.status = EvaluationStatus.EVALUATION_REJECTED;

        emit AssetEvaluated(_evaluationId,_assetId, _asset, _evaluation);
    }

    
    /**
    * @dev After an evaluation is approved, the Evaluator who submit
    * @dev evaluation data will call this function to generate an NFT token
    * @dev and transfer its ownership to Asset Creator's address.
    *
    * @param _assetId is the ID of the asset being converted to NFT token
    * @param _evaluationId is the look up index of the Evaluation data in the EvaluationsByAsset list
    * @param _mintingFee is the fee when mint token
    * @param _nftCID is the NFT CID when mint token
    */

    function createNftToken(
        uint256 _assetId, 
        uint256 _evaluationId, 
        uint256 _mintingFee, 
        string memory _nftCID
    )
        external 
        OnlyEOA 
        onlyRole(EVALUATOR_ROLE) 
        nonReentrant {

        // Check minting fee
        require(_mintingFee > 0, "Not enough fee.");

        // Check nft CID
        require(bytes(_nftCID).length > 0, "NFT CID not be empty.");

        // Check asset id
        require(_assetId >=0 , "Asset does not exists.");

        // Get asset
        Asset storage _asset = assetList[_assetId];

        // Check asset CID
        require(bytes(_asset.assetDataCID).length > 0, "Asset does not exists");
        
        // Check status asset
        require(_asset.status == AssetStatus.EVALUATED, "Asset have not evaluation.");

        // Check evaluationId
        require(_evaluationId >=0 , "Evaluation does not exists.");

        // Get evaluation
        Evaluation storage _evaluation = evaluationList[_evaluationId];

        // Check evaluation CID
        require(bytes(_evaluation.evaluationCID).length > 0, "Evaluation does not exists");

        // Check status evaluation
        require(_evaluation.status == EvaluationStatus.EVALUATION_ACCEPTED, "Evaluation is not acceptable.");

        // Check evaluator
        require(msg.sender == _evaluation.evaluator, "Evaluator address does not match.");

        // Check balance
        require(ibepDFY.balanceOf(msg.sender) >= (_mintingFee), "Your balance is not enough.");
        

        require(ibepDFY.allowance(msg.sender, address(this)) >= (_mintingFee), "You have not approve DFY.");

        // Create NFT
        uint256 mintedTokenId = dfy_physical_nfts.mint(_asset.creator, msg.sender, _evaluationId, 1, _nftCID , "");

        // Tranfer minting fee to admin
        ibepDFY.transferFrom(msg.sender,addressAdmin , _mintingFee);

        // Update status asset
        _asset.status = AssetStatus.NFT_CREATED;

        // Update status evaluation
        _evaluation.status = EvaluationStatus.NFT_CREATED;

        // Add token id to list asset of owner
        tokenIdByAsset[mintedTokenId] = _asset;

        // Add token id to list nft of evaluator
        tokenIdByEvaluation[mintedTokenId] = _evaluation;

    }

    /**
    * @dev Add an Evaluator to Whitelist and grant him Minter role.
    * @param _account is the address of an Evaluator
    */ 
    function addEvaluator(address _account) external onlyRole(OPERATOR_ROLE) {
        // Grant Evaluator role
        grantRole(EVALUATOR_ROLE, _account);

        // Approve
        emit ApproveEvaluator(_account);
    }

}


// File contracts/pawn-nft/IPawnNFT.sol

 

pragma solidity ^0.8.4;

interface IPawnNFT {

    /** ========================= Collateral ============================= */
    
    // Enum 
    enum LoanDurationType {WEEK, MONTH}
    enum CollateralStatus {OPEN, DOING, COMPLETED, CANCEL}
    enum OfferStatus {PENDING, ACCEPTED, COMPLETED, CANCEL}
    enum ContractStatus {ACTIVE, COMPLETED, DEFAULT}
    enum PaymentRequestStatusEnum {ACTIVE, LATE, COMPLETE, DEFAULT}
    enum PaymentRequestTypeEnum {INTEREST, OVERDUE, LOAN}
    enum ContractLiquidedReasonType { LATE, RISK, UNPAID }

    struct Collateral {
        address owner;
        address nftContract;
        uint256 nftTokenId;
        uint256 loanAmount;
        address loanAsset;
        uint256 nftTokenQuantity;
        uint256 expectedDurationQty;
        LoanDurationType durationType;
        CollateralStatus status;
    }

    /**
    * @dev create collateral function, collateral will be stored in this contract
    * @param _nftContract is address NFT token collection
    * @param _nftTokenId is token id of NFT
    * @param _loanAmount is amount collateral
    * @param _loanAsset is address of loan token
    * @param _nftTokenQuantity is quantity NFT token
    * @param _expectedDurationQty is expected duration
    * @param _durationType is expected duration type
    * @param _UID is UID pass create collateral to event collateral
    */
    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType _durationType,
        uint256 _UID
    ) 
    external;

    /**
    * @dev withdrawCollateral function, collateral will be delete stored in contract
    * @param _nftCollateralId is id of collateral
    */
    function withdrawCollateral(
        uint256 _nftCollateralId,
        uint256 _UID
    ) external;

    /** ========================= OFFER ============================= */

    struct CollateralOfferList {
        //offerId => Offer
        mapping (uint256 => Offer) offerMapping;
        uint256[] offerIdList;
        bool isInit;
    }

    struct Offer {
        address owner;
        address repaymentAsset;
        uint256 loanToValue;
        uint256 loanAmount;
        uint256 interest;
        uint256 duration;
        OfferStatus status;
        LoanDurationType loanDurationType;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
    }

    /**
    * @dev create offer to collateral
    * @param _nftCollateralId is id collateral
    * @param _repaymentAsset is address token repayment
    * @param _loanToValue is LTV token of loan
    * @param _loanAmount is amount token of loan
    * @param _interest is interest of loan
    * @param _duration is duration of loan
    * @param _liquidityThreshold is liquidity threshold of loan
    * @param _loanDurationType is duration type of loan 
    * @param _repaymentCycleType is repayment type of loan 
    */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType _loanDurationType,
        LoanDurationType _repaymentCycleType,
        uint256 _UID
    ) external;

    /**
    * @dev cancel offer
    * @param _offerId is id offer
    * @param _nftCollateralId is id NFT collateral
    */
    function cancelOffer(
        uint256 _offerId,
        uint256 _nftCollateralId,
        uint256 _UID
    ) external;

    /** ========================= ACCEPT OFFER ============================= */
    
    struct ContractTerms {
        address borrower;
        address lender;
        uint256 nftTokenId;
        address nftCollateralAsset;
        uint256 nftCollateralAmount;
        address loanAsset;
        uint256 loanAmount;
        address repaymentAsset;
        uint256 interest;
        LoanDurationType repaymentCycleType;
        uint256 liquidityThreshold;
        uint256 contractStartDate;
        uint256 contractEndDate;
        uint256 lateThreshold;
        uint256 systemFeeRate;
        uint256 penaltyRate;
        uint256 prepaidFeeRate;
    }
    
    struct Contract {
        uint256 nftCollateralId;
        uint256 offerId;
        ContractTerms terms;
        ContractStatus status;
        uint8 lateCount;
    }

    function acceptOffer(
        uint256 _nftCollateralId, 
        uint256 _offerId,
        uint256 _UID
    ) external;


    /** ========================= REPAYMENT ============================= */
    

    struct PaymentRequest {
        uint256 requestId;
        PaymentRequestTypeEnum paymentRequestType;
        uint256 remainingLoan;
        uint256 penalty;
        uint256 interest;
        uint256 remainingPenalty;
        uint256 remainingInterest;
        uint256 dueDateTimestamp;
        bool chargePrepaidFee;
        PaymentRequestStatusEnum status;
    }

    /**
    * @dev End lend period settlement and generate invoice for next period
    * @param _contractId is id contract
    * @param _remainingLoan is remaining Loan of borrower
    * @param _nextPhrasePenalty is next Phrase Penalty
    * @param _nextPhraseInterest is token next Phrase Interest
    * @param _dueDateTimestamp is due DateTimestamp
    * @param _paymentRequestType is type of payment request
    * @param _chargePrepaidFee is charge Prepaid Fee
    */
    function closePaymentRequestAndStartNew(
        uint256 _contractId,
        uint256 _remainingLoan,
        uint256 _nextPhrasePenalty,
        uint256 _nextPhraseInterest,
        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType,
        bool _chargePrepaidFee
    ) external;

    /**
    * @dev Borrowers make repayments
    * @param _contractId is id contract
    * @param _paidPenaltyAmount is paid Penalty Amount 
    * @param _paidInterestAmount is paid Interest Amount
    * @param _paidLoanAmount is paidLoanAmount
    */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external;

    function collateralRiskLiquidationExecution(
        uint256 _contractId,
        uint256 _collateralPerRepaymentTokenExchangeRate,
        uint256 _collateralPerLoanAssetExchangeRate
    ) external;

    function lateLiquidationExecution(
        uint256 _contractId
    ) external;

    function notPaidFullAtEndContractLiquidation(
        uint256 _contractId
    ) external;
}


// File contracts/pawn-nft/PawnNFTLib.sol

 

pragma solidity ^0.8.4;
library PawnNFTLib {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
    * @dev safe transfer BNB or ERC20
    * @param  asset is address of the cryptocurrency to be transferred
    * @param  from is the address of the transferor
    * @param  to is the address of the receiver
    * @param  amount is transfer amount
    */
    function safeTransfer(
        address asset, 
        address from, 
        address to, 
        uint256 amount
    ) internal {
        if (asset == address(0)) {
            require(from.balance >= amount, 'not-enough-balance');
            // Handle BNB            
            if (to == address(this)) {
                // Send to this contract
            } else if (from == address(this)) {
                // Send from this contract
                (bool success, ) = to.call{value:amount}('');
                require(success, 'fail-transfer-bnb');
            } else {
                // Send from other address to another address
                require(false, 'not-allow-transfer');
            }
        } else {
            // Handle ERC20
            uint256 prebalance = IERC20Upgradeable(asset).balanceOf(to);
            require(IERC20Upgradeable(asset).balanceOf(from) >= amount, 'not-enough-balance');
            if (from == address(this)) {
                // transfer direct to to
                IERC20Upgradeable(asset).safeTransfer(to, amount);
            } else {
                require(IERC20Upgradeable(asset).allowance(from, address(this)) >= amount, 'not-enough-allowance');
                IERC20Upgradeable(asset).safeTransferFrom(from, to, amount);
            }
            require(IERC20Upgradeable(asset).balanceOf(to) - amount == prebalance, 'not-transfer-enough');
        }
    }

    function safeTranferNFTToken(address _nftToken, address _from, address _to, uint256 _id, uint256 _amount) internal {
        
        // check address token
        require(_nftToken != address(0), "Address token must be different address(0).");

        // check address from
        require(_from != address(0), "Address from must be different address(0).");

        // check address from
        require(_to != address(0), "Address to must be different address(0).");

        // Check amount token
        require(_amount > 0, "Amount must be grean than 0.");

        // Check balance of from,
        require(IERC1155Upgradeable(_nftToken).balanceOf(_from,_id) >= _amount, "Your balance not enough.");

        // Transfer token
        IERC1155Upgradeable(_nftToken).safeTransferFrom(_from,_to,_id,_amount,"");
    }

    /**
    * @dev Calculate the duration of the contract
    * @param  durationType is loan duration type of contract (WEEK/MONTH)
    * @param  duration is duration of contract
    */
    function calculateContractDuration(IPawnNFT.LoanDurationType durationType, uint256 duration) internal pure returns (uint256 inSeconds) {
        if (durationType == IPawnNFT.LoanDurationType.WEEK) {
            inSeconds = 7 * 24 * 3600 * duration;
        } else {
            inSeconds = 30 * 24 * 3600 * duration; 
        }
    }

    /**
    * @dev Calculate balance of wallet address 
    * @param  _token is address of token 
    * @param  from is address wallet
    */
    function calculateAmount(
        address _token, 
        address from
    ) internal view returns (uint256 _amount) {
        if (_token == address(0)) {
            // BNB
            _amount = from.balance;
        } else {
            // ERC20
            _amount = IERC20Upgradeable(_token).balanceOf(from);
        }
    }

    /**
    * @dev Calculate fee of system
    * @param  amount amount charged to the system
    * @param  feeRate is system fee rate
    */
    function calculateSystemFee(
        uint256 amount, 
        uint256 feeRate,
        uint256 zoom
    ) internal pure returns (uint256 feeAmount) {
        feeAmount = (amount * feeRate) / (zoom * 100);
    }

    // function calculateRemainingLoanAndRepaymentFromContract(
    //     IPawnNFT.Contract storage _contract,
    //     IPawnNFT.PaymentRequest[] storage _paymentRequests
    // ) 
    //     internal 
    //     view 
    //     returns (
    //         uint256 remainingRepayment, 
    //         uint256 remainingLoan
    //     )
    // {
    //     // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
    //     IPawnNFT.PaymentRequest[] storage requests = _paymentRequests;
    //     if (requests.length > 0) {
    //         // Have payment request
    //         IPawnNFT.PaymentRequest storage _paymentRequest = requests[requests.length - 1];
    //         remainingRepayment = _paymentRequest.remainingInterest + _paymentRequest.remainingPenalty;
    //         remainingLoan = _paymentRequest.remainingLoan;
    //     } else {
    //         // Haven't had payment request
    //         remainingRepayment = 0;
    //         remainingLoan = _contract.terms.loanAmount;
    //     }
    // }
}


// File contracts/pawn-nft/PawnNFTContract.sol

 

pragma solidity ^0.8.4;
contract PawnNFTContract is 
    IPawnNFT, 
    Initializable, 
    UUPSUpgradeable,
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    ERC1155HolderUpgradeable,
    DFYAccessControl
{

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    AssetEvaluation assetEvaluation;

    mapping (address => uint256) public whitelistCollateral;
    address public operator;
    address public feeWallet;
    uint256 public penaltyRate;
    uint256 public systemFeeRate;
    uint256 public lateThreshold;
    uint256 public prepaidFeeRate;
    uint256 public ZOOM;
    address public admin;

    // DFY_Physical_NFTs dfy_physical_nfts;
    // AssetEvaluation assetEvaluation;

    function initialize(uint256 _zoom) public initializer {
        __ERC1155Holder_init();
        __DFYAccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        ZOOM = _zoom;
        admin = address(msg.sender);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function supportsInterface(bytes4 interfaceId) 
        public view 
        override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable) 
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setOperator(address _newOperator) onlyRole(DEFAULT_ADMIN_ROLE) external {
        operator = _newOperator;
    }

    function setFeeWallet(address _newFeeWallet) onlyRole(DEFAULT_ADMIN_ROLE) external {
        feeWallet = _newFeeWallet;
    }

    function pause() onlyRole(DEFAULT_ADMIN_ROLE) external {
        _pause();
    }

    function unPause() onlyRole(DEFAULT_ADMIN_ROLE) external {
        _unpause();
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the transaction
    */
    function setSystemFeeRate(uint256 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        systemFeeRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _feeRate is percentage of tokens to pay for the penalty
    */
    function setPenaltyRate(uint256 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        penaltyRate = _feeRate;
    }

    /**
    * @dev set fee for each token
    * @param _threshold is number of time allowed for late repayment
    */
    function setLateThreshold(uint256 _threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lateThreshold = _threshold;
    }

    function setPrepaidFeeRate(uint256 _feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        prepaidFeeRate = _feeRate;
    }

    function setWhitelistCollateral(address _token, uint256 _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistCollateral[_token] = _status;
    }

    function emergencyWithdraw(address _token)
        external 
        whenPaused 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PawnNFTLib.safeTransfer(_token, address(this), admin, PawnNFTLib.calculateAmount(_token, address(this)));
    }

    /** ========================= EVENT ============================= */
    //create collateral & withdraw
    event CollateralEvent(
        uint256 nftCollateralId,
        Collateral data,
        uint256 UID
    );
    
    //create offer & cancel
    event OfferEvent(
        uint256 offerId,
        uint256 nftCollateralId,
        Offer data,
        uint256 UID
    );

    //accept offer
    event LoanContractCreatedEvent(
        address fromAddress,
        uint256 contractId,   
        Contract data,
        uint256 UID
    );

    //repayment
    event PaymentRequestEvent (
        uint256 contractId,
        PaymentRequest data
    );

    event RepaymentEvent (
        uint256 contractId,
        uint256 paidPenaltyAmount,
        uint256 paidInterestAmount,
        uint256 paidLoanAmount,
        uint256 paidPenaltyFeeAmount,
        uint256 paidInterestFeeAmount,
        uint256 prepaidAmount,
        uint256 UID
    );

    //liquidity & defaul
     event ContractLiquidedEvent(
        uint256 contractId,
        uint256 liquidedAmount,
        uint256 feeAmount,
        ContractLiquidedReasonType reasonType
    );

    event LoanContractCompletedEvent(
        uint256 contractId
    );

    event CancelOfferEvent(
        uint256 offerId,
        uint256 nftCollateralId,
        address offerOwner,
        uint256 UID
    );

    // Total collateral
    CountersUpgradeable.Counter public numberCollaterals;

    // Mapping collateralId => Collateral
    mapping (uint256 => Collateral) public collaterals;

    // Total offer
    CountersUpgradeable.Counter public numberOffers;
    
    // Mapping collateralId => list offer of collateral
    mapping (uint256 => CollateralOfferList) public collateralOffersMapping;

    // Total contract
    uint256 public numberContracts;

    // Mapping contractId => Contract
    mapping (uint256 => Contract) public contracts;

    // Mapping contract Id => array payment request
    mapping (uint256 => PaymentRequest[]) public contractPaymentRequestMapping;

    /**
    * @dev create collateral function, collateral will be stored in this contract
    * @param _nftContract is address NFT token collection
    * @param _nftTokenId is token id of NFT
    * @param _loanAmount is amount collateral
    * @param _loanAsset is address of loan token
    * @param _nftTokenQuantity is quantity NFT token
    * @param _expectedDurationQty is expected duration
    * @param _durationType is expected duration type
    * @param _UID is UID pass create collateral to event collateral
    */
    function createCollateral(
        address _nftContract,
        uint256 _nftTokenId,
        uint256 _loanAmount,
        address _loanAsset,
        uint256 _nftTokenQuantity,
        uint256 _expectedDurationQty,
        LoanDurationType _durationType,
        uint256 _UID
    ) external override whenNotPaused nonReentrant {
        /**
        TODO: Implementation

        Chú ý: Kiểm tra bên Physical NFT, so khớp số NFT quantity với _nftTokenQuantity
        Chỉ cho phép input <= amount của NFT
        */

        // Check white list nft contract
        require(whitelistCollateral[_nftContract] == 1, "not_sp");

        // Check loan amount
        require(_loanAmount > 0 && _expectedDurationQty > 0, "enougth_amount_duration");

        // Check loan asset
        require(_loanAsset != address(0), "zero_address");

        // Create Collateral Id
        uint256 collateralId = numberCollaterals.current();

        // Transfer token
        PawnNFTLib.safeTranferNFTToken(_nftContract, msg.sender, address(this), _nftTokenId, _nftTokenQuantity);

        // Create collateral
        collaterals[collateralId] = Collateral({
                                                owner: msg.sender,
                                                nftContract: _nftContract,
                                                nftTokenId: _nftTokenId,
                                                loanAmount: _loanAmount,
                                                loanAsset: _loanAsset,
                                                nftTokenQuantity: _nftTokenQuantity,
                                                expectedDurationQty: _expectedDurationQty,
                                                durationType: _durationType,
                                                status: CollateralStatus.OPEN
                                                });
        
        // Update number colaterals
        numberCollaterals.increment();

        emit CollateralEvent(collateralId, collaterals[collateralId],_UID);
                                                
    }

    function withdrawCollateral(
        uint256 _nftCollateralId,
        uint256 _UID
    ) external override whenNotPaused
    {
        Collateral storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(_collateral.owner == msg.sender && _collateral.status == CollateralStatus.OPEN, "not_withdraw");

        // Return NFT token to owner
        PawnNFTLib.safeTranferNFTToken(_collateral.nftContract, address(this), _collateral.owner, _collateral.nftTokenId, _collateral.nftTokenQuantity);

        // Remove relation of collateral and offers
        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_nftCollateralId];
        if (collateralOfferList.isInit == true) {
            for (uint i = 0; i < collateralOfferList.offerIdList.length; i ++) {
                uint256 offerId = collateralOfferList.offerIdList[i];
                Offer storage offer = collateralOfferList.offerMapping[offerId];
                emit CancelOfferEvent(offerId, _nftCollateralId, offer.owner, _UID);
            }
            delete collateralOffersMapping[_nftCollateralId];
        }

        // Update collateral status
        _collateral.status = CollateralStatus.CANCEL;

        emit CollateralEvent(_nftCollateralId, _collateral, _UID);


        delete collaterals[_nftCollateralId];

    }

    /**
    * @dev create offer to collateral
    * @param _nftCollateralId is id collateral
    * @param _repaymentAsset is address token repayment
    * @param _loanToValue is LTV token of loan
    * @param _loanAmount is amount token of loan
    * @param _interest is interest of loan
    * @param _duration is duration of loan
    * @param _liquidityThreshold is liquidity threshold of loan
    * @param _loanDurationType is duration type of loan 
    * @param _repaymentCycleType is repayment type of loan 
    */
    function createOffer(
        uint256 _nftCollateralId,
        address _repaymentAsset,
        uint256 _loanToValue,
        uint256 _loanAmount,
        uint256 _interest,
        uint256 _duration,
        uint256 _liquidityThreshold,
        LoanDurationType _loanDurationType,
        LoanDurationType _repaymentCycleType,
        uint256 _UID
    ) external override whenNotPaused
    {
        // Get collateral
        Collateral storage _collateral = collaterals[_nftCollateralId];

        // Check owner collateral
        require(_collateral.owner != msg.sender && _collateral.status == CollateralStatus.OPEN, "not_offer"); // You can not offer.

        // Check approve 
        require(IERC20Upgradeable(_collateral.loanAsset).allowance(msg.sender, address(this)) >= _loanAmount, "not_approve"); // You not approve.

        // Check repayment asset
        require(_repaymentAsset != address(0), "zero_address"); // Address repayment asset must be different address(0).

        // Check loan amount
        require(_loanToValue > 0 && _loanAmount > 0 && _interest > 0 && _liquidityThreshold > _loanToValue, "not_enougth"); // Loan to value must be grean that 0.

        
        // Gennerate Offer Id
        uint256 offerId = numberOffers.current();

        // Get offers of collateral
        CollateralOfferList storage _collateralOfferList = collateralOffersMapping[_nftCollateralId];

        if (!_collateralOfferList.isInit) {
            _collateralOfferList.isInit = true;
        }

        _collateralOfferList.offerMapping[offerId] = Offer({
            owner: msg.sender,
            repaymentAsset: _repaymentAsset,
            loanToValue: _loanToValue,
            loanAmount: _loanAmount,
            interest: _interest,
            duration: _duration,
            status: OfferStatus.PENDING,
            loanDurationType: _loanDurationType,
            repaymentCycleType: _repaymentCycleType,
            liquidityThreshold: _liquidityThreshold
        });
        _collateralOfferList.offerIdList.push(offerId);

        _collateralOfferList.isInit = true;

        // Update number offer
        numberOffers.increment();

        emit OfferEvent(offerId, _nftCollateralId, _collateralOfferList.offerMapping[offerId], _UID);
    }

    function cancelOffer(uint256 _offerId, uint256 _nftCollateralId, uint256 _UID) external override whenNotPaused {
        
        // Get offer
        CollateralOfferList storage _collateralOfferList = collateralOffersMapping[_nftCollateralId];

        // Check Offer Collater isnit
        require(_collateralOfferList.isInit == true, 'collateral_false');

        // Get offer
        Offer storage _offer = _collateralOfferList.offerMapping[_offerId];

        // Check owner offer
        require(_offer.owner == msg.sender && _offer.status == OfferStatus.PENDING, 'not_offer');

        delete _collateralOfferList.offerMapping[_offerId];
        for (uint i = 0; i < _collateralOfferList.offerIdList.length; i ++) {
            if (_collateralOfferList.offerIdList[i] == _offerId) {
                _collateralOfferList.offerIdList[i] = _collateralOfferList.offerIdList[_collateralOfferList.offerIdList.length - 1];
                break;
            }
        }

        delete _collateralOfferList.offerIdList[_collateralOfferList.offerIdList.length - 1];
        emit CancelOfferEvent(_offerId, _nftCollateralId, msg.sender,_UID);
    }

    /** ================================ ACCEPT OFFER ============================= */
    /**
    * @dev accept offer and create contract between collateral and offer
    * @param  _nftCollateralId is id of collateral NFT
    * @param  _offerId is id of offer
    */
    function acceptOffer(
        uint256 _nftCollateralId, 
        uint256 _offerId,
        uint256 _UID
    ) 
        external 
        override 
        whenNotPaused 
    {

        Collateral storage collateral = collaterals[_nftCollateralId];
        // Check owner of collateral
        require(msg.sender == collateral.owner, 'owner');
        // Check for collateralNFT status is OPEN
        require(collateral.status == CollateralStatus.OPEN, 'collateral');

        CollateralOfferList storage collateralOfferList = collateralOffersMapping[_nftCollateralId];
        require(collateralOfferList.isInit == true, 'collateral-offers');
        // Check for offer status is PENDING
        Offer storage offer = collateralOfferList.offerMapping[_offerId];

        require(offer.status == OfferStatus.PENDING, 'unavailable');

        uint256 contractId = createContract(_nftCollateralId, collateral, _offerId, offer.loanAmount, offer.owner, offer.repaymentAsset, offer.interest, offer.loanDurationType, offer.liquidityThreshold);
        Contract storage newContract = contracts[contractId];
        // Change status of offer and collateral
        offer.status = OfferStatus.ACCEPTED;
        collateral.status = CollateralStatus.DOING;

        // Cancel other offer sent to this collateral
        for (uint256 i = 0; i < collateralOfferList.offerIdList.length; i++) {
            uint256 thisOfferId = collateralOfferList.offerIdList[i];
            if (thisOfferId != _offerId) {
                //Offer storage thisOffer = collateralOfferList.offerMapping[thisOfferId];
                emit CancelOfferEvent(thisOfferId, _nftCollateralId,offer.owner,_UID);
                delete collateralOfferList.offerMapping[thisOfferId];
            }
        }
        delete collateralOfferList.offerIdList;
        collateralOfferList.offerIdList.push(_offerId);

        emit LoanContractCreatedEvent(msg.sender, contractId, newContract, _UID);

        // Transfer loan asset to collateral owner
        PawnNFTLib.safeTransfer(newContract.terms.loanAsset, newContract.terms.lender, newContract.terms.borrower, newContract.terms.loanAmount);
    }

    /**
    * @dev create contract between offer and collateral
    * @param  _nftCollateralId is id of Collateral
    * @param  _collateral is Collateral
    * @param  _offerId is id of offer
    * @param  _loanAmount is loan amount 
    * @param  _lender is address of lender
    * @param  _repaymentAsset is address of pay token
    * @param  _interest is interest rate payable
    * @param  _repaymentCycleType is repayment cycle type (WEEK/MONTH)
    * @param  _liquidityThreshold is rate will liquidate the contract
    */
    function createContract (
        uint256 _nftCollateralId,
        Collateral storage _collateral,
        uint256 _offerId,
        uint256 _loanAmount,
        address _lender,
        address _repaymentAsset,
        uint256 _interest,
        LoanDurationType _repaymentCycleType,
        uint256 _liquidityThreshold
    ) 
        internal 
        returns (uint256 _idx) 
    {
        
        _idx = numberContracts;
        Contract storage newContract = contracts[_idx];
        newContract.nftCollateralId = _nftCollateralId;
        newContract.offerId = _offerId;
        newContract.status = ContractStatus.ACTIVE;
        newContract.lateCount = 0;
        newContract.terms.borrower = _collateral.owner;
        newContract.terms.lender = _lender;
        newContract.terms.nftTokenId = _collateral.nftTokenId;
        newContract.terms.nftCollateralAsset = _collateral.nftContract;
        newContract.terms.nftCollateralAmount = _collateral.nftTokenQuantity;
        newContract.terms.loanAsset = _collateral.loanAsset;
        newContract.terms.loanAmount = _loanAmount;
        newContract.terms.repaymentCycleType = _repaymentCycleType;
        newContract.terms.repaymentAsset = _repaymentAsset;
        newContract.terms.interest = _interest;
        newContract.terms.liquidityThreshold = _liquidityThreshold;
        newContract.terms.contractStartDate = block.timestamp;
        newContract.terms.contractEndDate = block.timestamp + PawnNFTLib.calculateContractDuration(_collateral.durationType, _collateral.expectedDurationQty);
        newContract.terms.lateThreshold = lateThreshold;
        newContract.terms.systemFeeRate = systemFeeRate;
        newContract.terms.penaltyRate = penaltyRate;
        newContract.terms.prepaidFeeRate = prepaidFeeRate;
        ++numberContracts;
    }

    /**
    * @dev Close old Payment Request and Start New Payment Request
    * @param  _contractId is id of contract
    * @param  _remainingLoan is remaining loan of contract
    * @param  _nextPhrasePenalty is fines for the next period
    * @param  _nextPhraseInterest is interest for the next period
    * @param  _dueDateTimestamp is due date timestamp of payment request
    * @param  _paymentRequestType is payment request type 
    * @param  _chargePrepaidFee is prepaid fee payment request
    */
    function closePaymentRequestAndStartNew(
        uint256 _contractId,
        uint256 _remainingLoan,
        uint256 _nextPhrasePenalty,
        uint256 _nextPhraseInterest,
        uint256 _dueDateTimestamp,
        PaymentRequestTypeEnum _paymentRequestType,
        bool _chargePrepaidFee
    ) 
        external 
        override 
        whenNotPaused 
        onlyRole(OPERATOR_ROLE) 
    {
        //Get contract
        Contract storage currentContract = contractMustActive(_contractId);

        // Check if number of requests is 0 => create new requests, if not then update current request as LATE or COMPLETE and create new requests
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        if (requests.length > 0) {
            // not first phrase, get previous request
            PaymentRequest storage previousRequest = requests[requests.length - 1];
            
            // Validate: time must over due date of current payment
            require(block.timestamp >= previousRequest.dueDateTimestamp, 'time-not-over-due');

            // Validate: remaining loan must valid
            require(previousRequest.remainingLoan == _remainingLoan, 'remaining-loan');

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(_dueDateTimestamp <= currentContract.terms.contractEndDate, 'contract-end-date');
            require(_dueDateTimestamp > previousRequest.dueDateTimestamp || _dueDateTimestamp == 0, 'less-than-previous');

            // update previous
            // check for remaining penalty and interest, if greater than zero then is Lated, otherwise is completed
            if (previousRequest.remainingInterest > 0 || previousRequest.remainingPenalty > 0) {
                previousRequest.status = PaymentRequestStatusEnum.LATE;
                // Update late counter of contract
                currentContract.lateCount += 1;

                // Check for late threshold reach
                if (currentContract.terms.lateThreshold <= currentContract.lateCount) {
                    // Execute liquid
                    _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
                    return;
                }
            } else {
                previousRequest.status = PaymentRequestStatusEnum.COMPLETE;
            }

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                if (previousRequest.remainingInterest + previousRequest.remainingPenalty + previousRequest.remainingLoan > 0) {
                    // unpaid => liquid
                    _liquidationExecution(_contractId, ContractLiquidedReasonType.UNPAID);
                    return;
                } else {
                    // paid full => release collateral
                    _returnCollateralToBorrowerAndCloseContract(_contractId);
                    return;
                }
            }

            emit PaymentRequestEvent(_contractId, previousRequest);
        } else {
            // Validate: remaining loan must valid
            require(currentContract.terms.loanAmount == _remainingLoan, 'remaining-loan');

            // Validate: Due date timestamp of next payment request must not over contract due date
            require(_dueDateTimestamp <= currentContract.terms.contractEndDate, 'contract-end-date');
            require(_dueDateTimestamp > currentContract.terms.contractStartDate || _dueDateTimestamp == 0, 'less-than-previous');
            require(block.timestamp < _dueDateTimestamp || _dueDateTimestamp == 0, 'already-over');

            // Check for last repayment, if last repayment, all paid
            if (block.timestamp > currentContract.terms.contractEndDate) {
                // paid full => release collateral
                _returnCollateralToBorrowerAndCloseContract(_contractId);
                return;
            }
        }

        // Create new payment request and store to contract
        PaymentRequest memory newRequest = PaymentRequest({
            requestId: requests.length,
            paymentRequestType: _paymentRequestType,
            remainingLoan: _remainingLoan,
            penalty: _nextPhrasePenalty,
            interest: _nextPhraseInterest,
            remainingPenalty: _nextPhrasePenalty,
            remainingInterest: _nextPhraseInterest,
            dueDateTimestamp: _dueDateTimestamp,
            status: PaymentRequestStatusEnum.ACTIVE,
            chargePrepaidFee: _chargePrepaidFee
        });
        requests.push(newRequest);
        emit PaymentRequestEvent(_contractId, newRequest);
    }


    /**
    * @dev get Contract must active
    * @param  _contractId is id of contract
    */
    function contractMustActive(uint256 _contractId) internal view returns (Contract storage _contract) {
        // Validate: Contract must active
        _contract = contracts[_contractId];
        require(_contract.status == ContractStatus.ACTIVE, 'contract-not-active');
    }

    /**
    * @dev Perform contract liquidation
    * @param  _contractId is id of contract
    * @param  _reasonType is type of reason for liquidation of the contract
    */
    function _liquidationExecution(
        uint256 _contractId,
        ContractLiquidedReasonType _reasonType
    ) internal {
        Contract storage _contract = contracts[_contractId];

        // Execute: update status of contract to DEFAULT, collateral to COMPLETE
        _contract.status = ContractStatus.DEFAULT;
        PaymentRequest[] storage _paymentRequests = contractPaymentRequestMapping[_contractId];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[_paymentRequests.length - 1];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.DEFAULT;
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];
        _collateral.status = CollateralStatus.COMPLETED;           

        // Emit Event ContractLiquidedEvent
        emit ContractLiquidedEvent(
            _contractId,
            0,
            0,
            _reasonType
        );
        // Transfer to lender collateral
        PawnNFTLib.safeTranferNFTToken(_contract.terms.nftCollateralAsset, address(this), _contract.terms.lender,_contract.terms.nftTokenId, _contract.terms.nftCollateralAmount );
    }

    /**
    * @dev return collateral to borrower and close contract
    * @param  _contractId is id of contract
    */
    function _returnCollateralToBorrowerAndCloseContract(
        uint256 _contractId
    ) internal 
    {
        Contract storage _contract = contracts[_contractId];
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];

        // Execute: Update status of contract to COMPLETE, collateral to COMPLETE
        _contract.status = ContractStatus.COMPLETED;
        PaymentRequest[] storage _paymentRequests = contractPaymentRequestMapping[_contractId];
        PaymentRequest storage _lastPaymentRequest = _paymentRequests[_paymentRequests.length - 1];
        _lastPaymentRequest.status = PaymentRequestStatusEnum.COMPLETE;
        _collateral.status = CollateralStatus.COMPLETED;

        // Emit Event ContractLiquidedEvent
        emit LoanContractCompletedEvent(_contractId);

        // Execute: Transfer collateral to borrower
        PawnNFTLib.safeTranferNFTToken(_contract.terms.nftCollateralAsset,  address(this), _contract.terms.borrower, _contract.terms.nftTokenId,  _contract.terms.nftCollateralAmount );

    }

    /**
    * @dev the borrower repays the debt
    * @param  _contractId is id of contract
    * @param  _paidPenaltyAmount is paid penalty amount
    * @param  _paidInterestAmount is paid interest amount
    * @param  _paidLoanAmount is paid loan amount
    */
    function repayment(
        uint256 _contractId,
        uint256 _paidPenaltyAmount,
        uint256 _paidInterestAmount,
        uint256 _paidLoanAmount,
        uint256 _UID
    ) external override whenNotPaused 
    {
        // Get contract & payment request
        Contract storage _contract = contractMustActive(_contractId);
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        require(requests.length > 0, 'payment-request');
        PaymentRequest storage _paymentRequest = requests[requests.length - 1];
        
        // Validation: Contract must not overdue
        require(block.timestamp <= _contract.terms.contractEndDate, 'contract-over');

        // Validation: current payment request must active and not over due
        require(_paymentRequest.status == PaymentRequestStatusEnum.ACTIVE, 'not-active');
        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            require(block.timestamp <= _paymentRequest.dueDateTimestamp, 'over-due');
        }

        // Calculate paid amount / remaining amount, if greater => get paid amount
        if (_paidPenaltyAmount > _paymentRequest.remainingPenalty) {
            _paidPenaltyAmount = _paymentRequest.remainingPenalty;
        }

        if (_paidInterestAmount > _paymentRequest.remainingInterest) {
            _paidInterestAmount = _paymentRequest.remainingInterest;
        }

        if (_paidLoanAmount > _paymentRequest.remainingLoan) {
            _paidLoanAmount = _paymentRequest.remainingLoan;
        }

        // Calculate fee amount based on paid amount
        uint256 _feePenalty = PawnNFTLib.calculateSystemFee(_paidPenaltyAmount, _contract.terms.systemFeeRate, ZOOM);
        uint256 _feeInterest = PawnNFTLib.calculateSystemFee(_paidInterestAmount, _contract.terms.systemFeeRate, ZOOM);

        uint256 _prepaidFee = 0;
        if (_paymentRequest.chargePrepaidFee) {
            _prepaidFee = PawnNFTLib.calculateSystemFee(_paidLoanAmount, _contract.terms.prepaidFeeRate, ZOOM);
        }

        // Update paid amount on payment request
        _paymentRequest.remainingPenalty -= _paidPenaltyAmount;
        _paymentRequest.remainingInterest -= _paidInterestAmount;
        _paymentRequest.remainingLoan -= _paidLoanAmount;

        // emit event repayment
        emit RepaymentEvent(
            _contractId, 
            _paidPenaltyAmount, 
            _paidInterestAmount, 
            _paidLoanAmount, 
            _feePenalty, 
            _feeInterest, 
            _prepaidFee,
            _UID
        );

        // If remaining loan = 0 => paidoff => execute release collateral
        if (_paymentRequest.remainingLoan == 0 && _paymentRequest.remainingPenalty == 0 && _paymentRequest.remainingInterest == 0)
            _returnCollateralToBorrowerAndCloseContract(_contractId);

        uint256 _totalFee;
        uint256 _totalTransferAmount;

        if (_paidPenaltyAmount + _paidInterestAmount > 0) {
            // Transfer fee to fee wallet
            _totalFee = _feePenalty + _feeInterest;
            PawnNFTLib.safeTransfer(_contract.terms.repaymentAsset, msg.sender, feeWallet, _totalFee);

            // Transfer penalty and interest to lender except fee amount
            _totalTransferAmount = _paidPenaltyAmount + _paidInterestAmount - _feePenalty - _feeInterest;
            PawnNFTLib.safeTransfer(_contract.terms.repaymentAsset, msg.sender, _contract.terms.lender, _totalTransferAmount);   
        }

        if (_paidLoanAmount > 0) {
            // Transfer loan amount and prepaid fee to lender
            _totalTransferAmount = _paidLoanAmount + _prepaidFee;
            PawnNFTLib.safeTransfer(_contract.terms.loanAsset, msg.sender, _contract.terms.lender, _totalTransferAmount);
        }
    }
    
    function collateralRiskLiquidationExecution(
        uint256 _contractId,
        uint256 _collateralPerRepaymentTokenExchangeRate,
        uint256 _collateralPerLoanAssetExchangeRate
    ) 
        external 
        override 
        whenNotPaused
        onlyRole(OPERATOR_ROLE)
    {
        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);
        Collateral storage _collateral = collaterals[_contract.nftCollateralId];

        //get Address of EvaluationContract 
        (address _evaluationContract, ) = DFY_Physical_NFTs(_collateral.nftContract).tokenIdOfEvaluation(_collateral.nftTokenId);
        
          assetEvaluation = AssetEvaluation(_evaluationContract);

        // get Evaluation from address of EvaluationContract
        (, , , , ,uint256 price ,) = assetEvaluation.tokenIdByEvaluation(_collateral.nftTokenId);

        (uint256 remainingRepayment, uint256 remainingLoan) = calculateRemainingLoanAndRepaymentFromContract(_contractId, _contract);
        uint256 valueOfRemainingRepayment = (_collateralPerRepaymentTokenExchangeRate * remainingRepayment) / ZOOM;
        uint256 valueOfRemainingLoan = (_collateralPerLoanAssetExchangeRate * remainingLoan) / ZOOM;
        uint256 valueOfCollateralLiquidationThreshold = price * _contract.terms.liquidityThreshold / (100 * ZOOM);

        require(valueOfRemainingLoan + valueOfRemainingRepayment >= valueOfCollateralLiquidationThreshold, 'under-threshold');

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.RISK);
    }

    /**
    * @dev liquidate the contract if the borrower has not paid in full at the end of the contract
    * @param _contractId is id of contract
    */
    function lateLiquidationExecution(uint256 _contractId) external override whenNotPaused {

        // Validate: Contract must active
        Contract storage _contract = contractMustActive(_contractId);

        // validate: contract have lateCount == lateThreshold
        require(_contract.lateCount >= _contract.terms.lateThreshold, 'not-reach');

        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    /**
    * @dev liquidate the contract if the borrower has not paid in full at the end of the contract
    * @param _contractId is id of contract
    */
    function notPaidFullAtEndContractLiquidation(uint256 _contractId) external override whenNotPaused{

        Contract storage _contract = contractMustActive(_contractId);
        // validate: current is over contract end date
        require(block.timestamp >= _contract.terms.contractEndDate, 'not-over-due');

        // validate: remaining loan, interest, penalty haven't paid in full
        (
            uint256 remainingRepayment, 
            uint256 remainingLoan
        ) = calculateRemainingLoanAndRepaymentFromContract(_contractId, _contract);
        
        require(remainingRepayment + remainingLoan > 0, 'paid-full');
        
        // Execute: call internal liquidation
        _liquidationExecution(_contractId, ContractLiquidedReasonType.LATE);
    }

    function calculateRemainingLoanAndRepaymentFromContract(
        uint256 _contractId,
        Contract storage _contract
    ) 
        internal 
        view 
        returns (
            uint256 remainingRepayment, 
            uint256 remainingLoan
        )
    {
        // Validate: sum of unpaid interest, penalty and remaining loan in value must reach liquidation threshold of collateral value
        PaymentRequest[] storage requests = contractPaymentRequestMapping[_contractId];
        if (requests.length > 0) {
            // Have payment request
            PaymentRequest storage _paymentRequest = requests[requests.length - 1];
            remainingRepayment = _paymentRequest.remainingInterest + _paymentRequest.remainingPenalty;
            remainingLoan = _paymentRequest.remainingLoan;
        } else {
            // Haven't had payment request
            remainingRepayment = 0;
            remainingLoan = _contract.terms.loanAmount;
        }
    }
}