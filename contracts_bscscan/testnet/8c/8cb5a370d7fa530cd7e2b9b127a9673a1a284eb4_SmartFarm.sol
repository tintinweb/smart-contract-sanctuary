/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



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
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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


// File @openzeppelin/contracts/utils/structs/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]



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
    uint256[49] private __gap;
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
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
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


// File contracts/libs/TransferHelper.sol



pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    address constant NATIVE_TOKEN = address(0);

    function isEther(address token) internal pure returns (bool) {
      return token == NATIVE_TOKEN;
    }

    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function safeTransferTokenOrETH(address token, address to, uint value) internal {
        isEther(token) 
            ? safeTransferETH(to, value)
            : safeTransfer(token, to, value);
    }
}


// File contracts/libs/SafeMath.sol



pragma solidity ^0.8.4;


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        return x / y;
    }

    function mod(uint x, uint y) internal pure returns (uint z) {
        return x % y;
    }
}


// File contracts/libs/StableMath.sol


pragma solidity ^0.8.4;
library StableMath {
  using SafeMath for uint;

  /**
   * @dev Scaling unit for use in specific calculations,
   * where 1 * 10**18, or 1e18 represents a unit '1'
   */
  uint private constant FULL_SCALE = 1e18;

  /**
   * @notice Token Ratios are used when converting between units of bAsset, mAsset and MTA
   * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
   * @dev bAsset ratio unit for use in exact calculations,
   * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
   */
  uint private constant RATIO_SCALE = 1e8;

  /**
   * @dev Provides an interface to the scaling unit
   * @return Scaling unit (1e18 or 1 * 10**18)
   */
  function getFullScale() internal pure returns (uint) {
    return FULL_SCALE;
  }

  /**
   * @dev Provides an interface to the ratio unit
   * @return Ratio scale unit (1e8 or 1 * 10**8)
   */
  function getRatioScale() internal pure returns (uint) {
    return RATIO_SCALE;
  }

  /**
   * @dev Scales a given integer to the power of the full scale.
   * @param x   Simple uint256 to scale
   * @return    Scaled value a to an exact number
   */
  function scaleInteger(uint x) internal pure returns (uint) {
    return x.mul(FULL_SCALE);
  }

  /***************************************
              PRECISE ARITHMETIC
    ****************************************/

  /**
   * @dev Multiplies two precise units, and then truncates by the full scale
   * @param x     Left hand input to multiplication
   * @param y     Right hand input to multiplication
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              scale unit
   */
  function mulTruncate(uint x, uint y) internal pure returns (uint) {
    return mulTruncateScale(x, y, FULL_SCALE);
  }

  /**
   * @dev Multiplies two precise units, and then truncates by the given scale. For example,
   * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
   * @param x     Left hand input to multiplication
   * @param y     Right hand input to multiplication
   * @param scale Scale unit
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              scale unit
   */
  function mulTruncateScale(
    uint x,
    uint y,
    uint scale
  ) internal pure returns (uint) {
    // e.g. assume scale = fullScale
    // z = 10e18 * 9e17 = 9e36
    uint z = x.mul(y);
    // return 9e38 / 1e18 = 9e18
    return z.div(scale);
  }

  /**
   * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
   * @param x     Left hand input to multiplication
   * @param y     Right hand input to multiplication
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              scale unit, rounded up to the closest base unit.
   */
  function mulTruncateCeil(uint x, uint y) internal pure returns (uint) {
    // e.g. 8e17 * 17268172638 = 138145381104e17
    uint scaled = x.mul(y);
    // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
    uint ceil = scaled.add(FULL_SCALE.sub(1));
    // e.g. 13814538111.399...e18 / 1e18 = 13814538111
    return ceil.div(FULL_SCALE);
  }

  /**
   * @dev Precisely divides two units, by first scaling the left hand operand. Useful
   *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
   * @param x     Left hand input to division
   * @param y     Right hand input to division
   * @return      Result after multiplying the left operand by the scale, and
   *              executing the division on the right hand input.
   */
  function divPrecisely(uint x, uint y) internal pure returns (uint) {
    // e.g. 8e18 * 1e18 = 8e36
    uint z = x.mul(FULL_SCALE);
    // e.g. 8e36 / 10e18 = 8e17
    return z.div(y);
  }

  /***************************************
                  RATIO FUNCS
  ****************************************/

  /**
   * @dev Multiplies and truncates a token ratio, essentially flooring the result
   *      i.e. How much mAsset is this bAsset worth?
   * @param x     Left hand operand to multiplication (i.e Exact quantity)
   * @param ratio bAsset ratio
   * @return c     Result after multiplying the two inputs and then dividing by the ratio scale
   */
  function mulRatioTruncate(uint x, uint ratio) internal pure returns (uint c) {
    return mulTruncateScale(x, ratio, RATIO_SCALE);
  }

  /**
   * @dev Multiplies and truncates a token ratio, rounding up the result
   *      i.e. How much mAsset is this bAsset worth?
   * @param x     Left hand input to multiplication (i.e Exact quantity)
   * @param ratio bAsset ratio
   * @return      Result after multiplying the two inputs and then dividing by the shared
   *              ratio scale, rounded up to the closest base unit.
   */
  function mulRatioTruncateCeil(uint x, uint ratio) internal pure returns (uint) {
    // e.g. How much mAsset should I burn for this bAsset (x)?
    // 1e18 * 1e8 = 1e26
    uint scaled = x.mul(ratio);
    // 1e26 + 9.99e7 = 100..00.999e8
    uint ceil = scaled.add(RATIO_SCALE.sub(1));
    // return 100..00.999e8 / 1e8 = 1e18
    return ceil.div(RATIO_SCALE);
  }

  /**
   * @dev Precisely divides two ratioed units, by first scaling the left hand operand
   *      i.e. How much bAsset is this mAsset worth?
   * @param x     Left hand operand in division
   * @param ratio bAsset ratio
   * @return      Result after multiplying the left operand by the scale, and
   *              executing the division on the right hand input.
   */
  function divRatioPrecisely(uint x, uint ratio) internal pure returns (uint) {
    // e.g. 1e14 * 1e8 = 1e22
    uint y = x.mul(RATIO_SCALE);
    // return 1e22 / 1e12 = 1e10
    return y.div(ratio);
  }

  /***************************************
                    HELPERS
    ****************************************/

  /**
   * @dev Calculates minimum of two numbers
   * @param x     Left hand input
   * @param y     Right hand input
   * @return      Minimum of the two inputs
   */
  function min(uint x, uint y) internal pure returns (uint) {
    return x > y ? y : x;
  }

  /**
   * @dev Calculated maximum of two numbers
   * @param x     Left hand input
   * @param y     Right hand input
   * @return      Maximum of the two inputs
   */
  function max(uint x, uint y) internal pure returns (uint) {
    return x > y ? x : y;
  }

  /**
   * @dev Clamps a value to an upper bound
   * @param x           Left hand input
   * @param upperBound  Maximum possible value to return
   * @return            Input x clamped to a maximum value, upperBound
   */
  function clamp(uint x, uint upperBound) internal pure returns (uint) {
    return x > upperBound ? upperBound : x;
  }
}


// File contracts/interfaces/ISmartArmy.sol


pragma solidity ^0.8.4;

interface ISmartArmy {
    /// @dev License Types
    struct LicenseType {
        uint256  level;        // level
        string   name;         // Trial, Opportunist, Runner, Visionary
        uint256  price;        // 100, 1000, 5000, 10,000
        uint256  ladderLevel;  // Level of referral system with this license
        uint256  duration;     // default 6 months
        bool     isValid;
    }

    enum LicenseStatus {
        None,
        Pending,
        Active,
        Expired
    }

    /// @dev User information on license
    struct UserLicense {
        address owner;
        uint256 level;
        uint256 startAt;
        uint256 activeAt;
        uint256 expireAt;
        uint256 lpLocked;

        LicenseStatus status;
    }

    /// @dev User Personal Information
    struct UserPersonal {
        address sponsor;
        string username;
        string telegram;
    }

    /// @dev Fee Info 
    struct FeeInfo {
        uint256 penaltyFeePercent;      // liquidate License LP fee percent
        uint256 extendFeeBNB;       // extend Fee as BNB
        address feeAddress;
    }
    
    function licenseOf(address account) external view returns(UserLicense memory);
    function lockedLPOf(address account) external view returns(uint256);
    function isActiveLicense(address account) external view returns(bool);
    function isEnabledIntermediary(address account) external view returns(bool);
    function licenseLevelOf(address account) external view returns(uint256);
    function licenseActiveDuration(address account, uint256 from, uint256 to) external view returns(uint256, uint256);
}


// File contracts/interfaces/ISmartLadder.sol


pragma solidity ^0.8.4;

interface ISmartLadder {
    /// @dev Ladder system activities
    struct Activity {
        string      name;         // buytax, farming, ...
        uint16[7]   share;        // share percentage
        address     token;        // share token address
        bool        enabled;      // enabled or disabled temporally
        bool        isValid;
        uint256     totalDistributed; // total distributed
    }
    
    function registerSponsor(address _user, address _sponsor) external;
    function distributeTax(uint256 id, address account) external; 
    function distributeBuyTax(address account) external; 
    function distributeFarmingTax(address account) external; 
    function distributeSmartLivingTax(address account) external; 
    function distributeEcosystemTax(address account) external; 
    
    function activity(uint256 id) external view returns(Activity memory);
    function sponsorOf(address account) external view returns(address);
    function sponsorsOf(address account, uint count) external returns (address[] memory); 
}


// File contracts/interfaces/ISmartFarm.sol


pragma solidity ^0.8.4;

interface ISmartFarm {
    /// @dev Pool Information
    struct PoolInfo {
        address stakingTokenAddress;     // staking contract address
        address rewardTokenAddress;      // reward token contract

        uint256 rewardPerDay;            // reward percent per day

        uint unstakingFee;
            
        uint256 totalStaked;             /* How many tokens we have successfully staked */
    }


    struct UserInfo {
        uint256 balance;
        uint256 rewards;
        uint256 rewardPerTokenPaid;     // User rewards per token paid for passive
        uint256 lastUpdated;
    }
    
    function stakeSMT(address account, uint256 amount) external returns(uint256);
    function withdrawSMT(address account, uint256 amount) external returns(uint256);
    function claimReward() external;

    function notifyRewardAmount(uint _reward) external;
}


// File contracts/interfaces/IGoldenTreePool.sol


pragma solidity ^0.8.4;

interface IGoldenTreePool {
    function swapDistribute() external;
    function notifyReward(uint256 amount, address account) external;
}


// File contracts/interfaces/ISmartAchievement.sol


pragma solidity ^0.8.4;

interface ISmartAchievement {

    struct NobilityType {
        string            title;               // Title of Nobility Folks Baron Count Viscount Earl Duke Prince King
        uint256           growthRequried;      // Required growth token
        uint256           passiveShare;        // Passive share percent

        uint256[]         chestSMTRewards;
        uint256[]         chestSMTCRewards;
    }


    function notifyGrowth(address account, uint256 oldGrowth, uint256 newGrowth) external returns(bool);
    function claimReward() external;
    function claimChestReward() external;
    function swapDistribute() external;
    
    function isUpgradeable(uint256 from, uint256 to) external view returns(bool, uint256);
    function nobilityOf(address account) external view returns(NobilityType memory);
    function nobilityTitleOf(address account) external view returns(string memory);
}


// File contracts/interfaces/IUniswapRouter.sol


pragma solidity ^0.8.4;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/interfaces/ISmartComp.sol


pragma solidity ^0.8.4;
// Smart Comptroller Interface
interface ISmartComp {
    function isComptroller() external pure returns(bool);
    function getSMT() external view returns(IERC20);
    function getBUSD() external view returns(IERC20);
    function getWBNB() external view returns(IERC20);

    function getUniswapV2Router() external view returns(IUniswapV2Router02);

    function getUniswapV2Factory() external view returns(address);

    function getSmartArmy() external view returns(ISmartArmy);

    function getSmartLadder() external view returns(ISmartLadder);

    function getSmartFarm() external view returns(ISmartFarm);

    function getGoldenTreePool() external view returns(IGoldenTreePool);

    function getSmartAchievement() external view returns(ISmartAchievement);
}


// File contracts/interfaces/IUniswapFactory.sol



pragma solidity ^0.8.4;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File contracts/SmartFarm.sol



/**
 * Smart Farming Contract
 * @author Liu
 */

pragma solidity ^0.8.4;
contract SmartFarm is UUPSUpgradeable, OwnableUpgradeable, ISmartFarm {
  using StableMath for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev Params for Passive Rewards
  uint public constant DURATION = 7 days;

  // Timestamp for current period finish
  uint256 public periodFinish;
  // RewardRate for the rest of the PERIOD
  uint256 public rewardRate;
  // Last time any user took action
  uint256 public lastUpdateTime;
  // Ever increasing rewardPerToken rate, based on % of total supply
  uint256 public rewardPerTokenStored;

  EnumerableSet.AddressSet private _rewardsDistributors;


  ISmartComp public comptroller;

  /// @dev Info of each user that stakes LP tokens.
  mapping(address => UserInfo) public userInfo;

  /// @dev Farming Tax percent to distribute
  uint256 public farmingTax_referral;
  uint256 public farmingTax_golden;
  uint256 public farmingTax_dev;
  uint256 public farmingTax_passive;
  uint256 public unstakingFee;

  uint256 public farmingRewardPercent;
  address public farmingRewardWallet;

  /// @dev Address for collecting fee
  address public feeAddress;

  uint256 public totalStaked;

  event RewardAdded(uint256 reward);
  event Staked(address indexed account, uint256 amount, uint256 lp);
  event Withdrawn(address indexed account, uint256 amount, uint256 lp);
  event Claimed(address indexed account, uint256 amount);


  function initialize(address _comp, address _rewardWallet) public initializer {
		__Ownable_init();
    __SmartFarm_init_unchained(_comp, _rewardWallet);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}


  function __SmartFarm_init_unchained(address _comp, address _rewardWallet)
        internal
        initializer
    {
      comptroller = ISmartComp(_comp);
      
      farmingTax_referral = 1000;
      farmingTax_golden = 300;
      farmingTax_dev = 100;
      farmingTax_passive = 100;

      unstakingFee = 0;
      farmingRewardPercent = 10;   // 0.1 %
      farmingRewardWallet = _rewardWallet;

      feeAddress = msg.sender;
    }
  

  /**
  * @notice Sets a new comptroller
  * @dev Admin function to set a new comptroller
  */
  function setComptroller(ISmartComp newComptroller) public onlyOwner {
    // Ensure invoke comptroller.isComptroller() returns true
    require(newComptroller.isComptroller(), "marker method returned false");

    // Set comptroller to newComptroller
    comptroller = newComptroller;
  }


  /**
   * Update Fee information
   */
  function updateFeeInfo(
    uint256 _farmingTax_referral,             // Farming tax percent for referral system
    uint256 _farmingTax_golden,               // Farming tax percent for golden tree pool
    uint256 _farmingTax_dev,                  // Farming tax percent for dev wallet
    uint256 _farmingTax_passive,              // Farming tax percent for passive share
    uint256 _unstakingFee,                    // Unstaking fee percent
    address _feeAddress
  ) external onlyOwner {
    require(_farmingTax_referral < 5000, "SmartFarm#updateFeeInfo: Too big farming tax referral");
    require(_farmingTax_golden < 5000, "SmartFarm#updateFeeInfo: Too big farming tax golden");
    require(_farmingTax_dev < 5000, "SmartFarm#updateFeeInfo: Too big farming tax dev");
    require(_farmingTax_passive < 5000, "SmartFarm#updateFeeInfo: Too big farming tax passwive");
    
    require(_unstakingFee < 5000, "SmartFarm#updateFeeInfo: Too big unstaking fee");
    
    farmingTax_referral = _farmingTax_referral;
    farmingTax_golden = _farmingTax_golden;
    farmingTax_dev = _farmingTax_dev;
    farmingTax_passive = _farmingTax_passive;
    unstakingFee = _unstakingFee;
    feeAddress = _feeAddress;
  }

  /**
   * Update farming reward pecentage and wallet address
   */
  function updateFarmingRewardParams(
    uint256 percent,
    address wallet
  ) 
    external
    onlyOwner 
  {
    require(wallet != address(0x0), "SmartFarm#updateFarmingReward: invalid wallet address");
    require(percent <= 10_000, "SmartFarm#updateFarmingReward: too big percent");

    farmingRewardPercent = percent;
    farmingRewardWallet = wallet;
  }


  /***************************************
                    ADMIN
  ****************************************/
  /**
   * @dev Add rewards distributor
   * @param _address Address of Reward Distributor
   */
  function addDistributor(address _address) external onlyOwner {
    _rewardsDistributors.add(_address);
  }


  /**
   * @dev Remove rewards distributor
   * @param _address Address of Reward Distributor
   */
  function removeDistributor(address _address) external onlyOwner {
    _rewardsDistributors.remove(_address);
  }


  /** @dev only Rewards distributors */
  modifier onlyRewardsDistributor() {
    require(_rewardsDistributors.contains(msg.sender) || msg.sender == owner(), "SmartFarm: only reward distributors");
    _;
  }

  /**
   * @dev Notifies the contract that new rewards have been added.
   * Calculates an updated rewardRate based on the rewards in period.
   * @param _reward Units of RewardToken that have been added to the pool
   */
  function notifyRewardAmount(uint _reward)
    external
    override
    onlyRewardsDistributor
    updatePassiveReward(address(0))
  {
    uint currentTime = block.timestamp;

    // transfer all SMT token for farming passive rewards to 
    IERC20 smtToken = comptroller.getSMT();
    TransferHelper.safeTransfer(address(smtToken), farmingRewardWallet, _reward);

    // If previous period over, reset rewardRate
    if (currentTime >= periodFinish) {
      rewardRate = _reward.div(DURATION);
    }
    // If additional reward to existing period, calc sum
    else {
      uint remaining = periodFinish.sub(currentTime);
      uint leftover = remaining.mul(rewardRate);
      rewardRate = _reward.add(leftover).div(DURATION);
    }

    lastUpdateTime = currentTime;
    periodFinish = currentTime.add(DURATION);

    emit RewardAdded(_reward);
  }


  /** @dev Updates the reward for a given address, before executing function */
  modifier updatePassiveReward(address account) {
    // Setting of global vars
    uint256 newRewardPerToken = rewardPerToken();
    // If statement protects against loss in initialisation case
    if (newRewardPerToken > 0) {
      rewardPerTokenStored = newRewardPerToken;
      lastUpdateTime = lastTimeRewardApplicable();
      // Setting of personal vars based on new globals
      if (account != address(0)) {
        UserInfo storage uInfo = userInfo[account];
        uInfo.rewards = earnedPassive(account);
        uInfo.rewardPerTokenPaid = newRewardPerToken;
      }
    }
    _;
  }

  modifier updateFixedReward(address account) {
      if (account != address(0)) {
          UserInfo storage uInfo = userInfo[account];
          uInfo.rewards = earned(account);
          uInfo.lastUpdated = block.timestamp;
      }
      _;
  }


  function balanceOf(address account) public view returns (uint256) {
    return userInfo[account].balance;
  }

  function rewardsOf(address account) public view returns (uint256) {
    return userInfo[account].rewards;
  }


   /**
   * @dev Gets the last applicable timestamp for this reward period
   */
  function lastTimeRewardApplicable() public view returns (uint) {
    return StableMath.min(block.timestamp, periodFinish);
  }

  /**
   * @dev Calculates the amount of unclaimed rewards per token since last update,
   * and sums with stored to give the new cumulative reward per token
   * @return 'Reward' per staked token
   */
  function rewardPerToken() public view returns (uint) {
    // If there is no StakingToken liquidity, avoid div(0)
    uint256 stakedTokens = totalStaked;
    if (stakedTokens == 0) {
      return rewardPerTokenStored;
    }
    // new reward units to distribute = rewardRate * timeSinceLastUpdate
    uint256 rewardUnitsToDistribute = rewardRate.mul(lastTimeRewardApplicable().sub(lastUpdateTime));
    // prevent overflow
    require(rewardUnitsToDistribute < type(uint256).max.div(1e18));
    // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalTokens
    uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(stakedTokens);
    // return summed rate
    return rewardPerTokenStored.add(unitsToDistributePerToken);
  }

  /**
   * Calculate earned amount from lastUpdated to block.timestamp
   * Check License activate status while staking 
   */
  function earned(address account) public view returns (uint256) {
    uint256 blockTime = block.timestamp;
    UserInfo memory uInfo = userInfo[account];

    // Check license activation duration 
    (uint256 start, uint256 end) = comptroller.getSmartArmy().licenseActiveDuration(account, uInfo.lastUpdated, blockTime);
    if(start == 0 || end == 0) {
      return uInfo.rewards;
    }
    
    uint256 duration = end.sub(start);
    uint256 amount = duration.mul(balanceOf(account)).mul(farmingRewardPercent).div(86400).div(10_000);
    return uInfo.rewards.add(amount);
  }
  

  /**
   * @dev Calculates the amount of unclaimed rewards a user has earned
   * @param _account User address
   * @return Total reward amount earned
   */
  function earnedPassive(address _account) public view returns (uint256) {
    UserInfo memory uInfo = userInfo[_account];

    // current rate per token - rate user previously received
    uint256 userRewardDelta = rewardPerToken().sub(uInfo.rewardPerTokenPaid);
    // new reward = staked tokens * difference in rate
    uint256 userNewReward = balanceOf(_account).mulTruncate(userRewardDelta);
    // add to previous rewards
    return uInfo.rewards.add(userNewReward);
  }

  /**
   * Stake SMT token
   * Swap with BUSD and add liquidity to pcs
   * Lock LP token to contract
   */
  function stakeSMT(
    address account,
    uint256 amount
  ) 
    public
    override
    updateFixedReward(account)
    updatePassiveReward(account)
    returns(uint256)
  {
    ISmartArmy smartArmy = comptroller.getSmartArmy();
    require(_msgSender() == address(smartArmy) || _msgSender() == account, "SmartFarm#stakeSMT: invalid account");

    uint256 liquidity = _tranferSmtToContract(_msgSender(), account, amount);
    require(liquidity > 0, "SmartFarm#stakeSMT: failed to add liquidity");

    UserInfo storage uInfo = userInfo[account];
    uInfo.balance = uInfo.balance.add(liquidity);

    totalStaked = totalStaked.add(liquidity);

    emit Staked(account, amount, liquidity);

    return liquidity;
  }


  /**
   * @notice Withdraw Staked SMT
   */
  function withdrawSMT(
    address account,
    uint256 lpAmount
  )
    public 
    override
    updateFixedReward(account)
    updatePassiveReward(account)
    returns(uint256)
  {
    require(lpAmount > 0, "SmartFarm#withdrawSMT: Cannot withdraw 0");
    require(lpAmount <= balanceOf(account), "SmartFarm#withdrawSMT: Cannot withdraw more than balance");

    ISmartArmy smartArmy = comptroller.getSmartArmy();
    uint256 lpLocked = smartArmy.lockedLPOf(account);

    require(_msgSender() == address(smartArmy) || _msgSender() == account, "SmartFarm#withdrawSMT: invalid account");

    if(_msgSender() == address(smartArmy)) {
      require(lpLocked == lpAmount, "SmartFarm#withdrawSMT: withdraw amount from SmartArmy is invalid");
    } else {
      require(lpLocked.add(lpAmount) <= balanceOf(account), "SmartFarm#withdrawSMT: withdraw amount is invalid");
    }

    UserInfo storage uInfo = userInfo[account];

    uint256 smtAmount = _tranferSmtToUser(_msgSender(), lpAmount);
    require(smtAmount > 0, "SmartFarm#withdrawSMT: failed to sent SMT to staker");

    uInfo.balance = uInfo.balance.sub(lpAmount);
    
    totalStaked = totalStaked.sub(lpAmount);
    
    emit Withdrawn(account, smtAmount, lpAmount);

    return smtAmount;
  }
  

  /**
   * ///@notice Redeem SMT rewards from staking
   */
  function claimReward() 
    public 
    override
    updateFixedReward(_msgSender())
    updatePassiveReward(_msgSender())
  {
      UserInfo storage uInfo = userInfo[_msgSender()];

      uint256 rewards = rewardsOf(_msgSender());

      require(rewards > 0 , "SmartFarm#stakeSMT: Not enough rewards to claim");

      TransferHelper.safeTransferFrom(address(comptroller.getSMT()), farmingRewardWallet, _msgSender(), rewards);

      uInfo.rewards = 0;
      emit Claimed(_msgSender(), rewards);
  }
  
  function exit() external {
    withdrawSMT(msg.sender, balanceOf(msg.sender));
    claimReward();
  }

  /**
   * Transfer smt token to contract.
   * Swap half as BUSD, 
   * Add Liquidity => LP token Lock
   */
  function _tranferSmtToContract(address _from, address account, uint256 _amount) 
    private 
    returns(uint) 
  {
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
  
    // Transfer SMT token from user to contract
    uint256 beforeBalance = smtToken.balanceOf(address(this));
    SafeERC20.safeTransferFrom(smtToken, _from, address(this), _amount);
    uint256 amount = smtToken.balanceOf(address(this)).sub(beforeBalance);
    require(amount > 0, "SmartFarm#_transferSmtToContract: faild to transfer SMT token");

    // distribute farming tax
    {
      uint256 totalFarmingTax = _distributeFarmingTax(account, amount);
      amount = amount.sub(totalFarmingTax);
    }

    // Swap half of SMT token to BUSD
    uint256 half = amount.div(2);
    uint256 otherHalf = amount.sub(half);

    uint256 beforeBusdBalance = busdToken.balanceOf(address(this));
    _swapTokensForBUSD(half);
    uint256 newBusdBalance = busdToken.balanceOf(address(this)).sub(beforeBusdBalance);

    // add liquidity
    (, , uint liquidity) = _addLiquidity(otherHalf, newBusdBalance);

    return liquidity;
  }

  /**
   * Distribute farming tax to ...
   */
  function _distributeFarmingTax(
    address account,
    uint256 farmingAmount
  )
    internal
    returns (uint256)
  {
    // distribute farming tax
    // 10% goes to referral system
    // 3% goes to golden tree pool
    // 1% goes to development wallet
    // 1% goes to passive global share
    IERC20 smtToken = comptroller.getSMT();

    uint256 farmingTaxReferralAmount = farmingAmount.mul(farmingTax_referral).div(10_000);
    uint256 farmingTaxGoldenAmount = farmingAmount.mul(farmingTax_golden).div(10_000);
    uint256 farmingTaxDevAmount = farmingAmount.mul(farmingTax_dev).div(10_000);
    uint256 farmingTaxPassiveAmount = farmingAmount.mul(farmingTax_passive).div(10_000);

    uint256 totalPaid = 0;

    if(farmingTaxReferralAmount > 0) {
      ISmartLadder smartLadder = comptroller.getSmartLadder();
      TransferHelper.safeTransfer(address(smtToken), address(smartLadder), farmingTaxReferralAmount);
      smartLadder.distributeFarmingTax(account);

      totalPaid = totalPaid.add(farmingTaxReferralAmount);
    }
    
    if(farmingTaxGoldenAmount > 0) {
      IGoldenTreePool pool = comptroller.getGoldenTreePool();

      TransferHelper.safeTransfer(address(smtToken), address(pool), farmingTaxGoldenAmount);
      pool.notifyReward(farmingTaxGoldenAmount, account);

      totalPaid = totalPaid.add(farmingTaxReferralAmount);
    }

    if(farmingTaxDevAmount > 0) {
      TransferHelper.safeTransfer(address(smtToken), address(feeAddress), farmingTaxDevAmount);
      totalPaid = totalPaid.add(farmingTaxReferralAmount);
    }

    if(farmingTaxPassiveAmount > 0) {
      // TODO
      // transfer smt to passive pool and sync
      ISmartAchievement ach = comptroller.getSmartAchievement();

      TransferHelper.safeTransfer(address(smtToken), address(ach), farmingTaxPassiveAmount);
      ISmartAchievement(ach).swapDistribute();

      totalPaid = totalPaid.add(farmingTaxPassiveAmount);
    }

    return totalPaid;
  }


  /**
   * Transfer smt token to user.
   * Remove liquidity
   * Swap half as SMT, 
   */
  function _tranferSmtToUser(address _to, uint256 _lpAmount) private returns(uint) {
    if(_lpAmount == 0) {
      return 0;
    }
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
    IUniswapV2Router02 uniswapV2Router = comptroller.getUniswapV2Router();

    // Tranfer Penalty Fee to fee address
    uint256 feeAmount = _lpAmount.mul(unstakingFee).div(10_1000);

    address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(smtToken), address(busdToken));
    SafeERC20.safeTransfer(IERC20(pair), feeAddress, feeAmount);

    // Remove liquidity from dex
    (uint smtAmount, uint busdAmount) = _removeLiquidity(_lpAmount.sub(feeAmount));

    // Swap BUSD to smt token
    uint256 beforeBalance = smtToken.balanceOf(address(this));
    _swapTokensForSMT(busdAmount);
    uint256 amount = uint256(smtAmount).add(smtToken.balanceOf(address(this)).sub(beforeBalance));
    
    // Transfer SMT token to user
    SafeERC20.safeTransfer(smtToken, _to, amount);
    
    return amount;
  }

  function _swapTokensForBUSD(uint256 tokenAmount) private {
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
    IUniswapV2Router02 uniswapV2Router = comptroller.getUniswapV2Router();

    // generate the uniswap pair path of token -> busd
    address[] memory path = new address[](2);
    path[0] = address(smtToken);
    path[1] = address(busdToken);

    smtToken.safeApprove(address(uniswapV2Router), tokenAmount);
    
    // make the swap
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
    );
  }

  function _swapTokensForSMT(uint256 tokenAmount) private {
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
    IUniswapV2Router02 uniswapV2Router = comptroller.getUniswapV2Router();

    // generate the uniswap pair path of token -> busd
    address[] memory path = new address[](2);
    path[1] = address(smtToken);
    path[0] = address(busdToken);

    busdToken.safeApprove(address(uniswapV2Router), tokenAmount);
    
    // make the swap
    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        tokenAmount,
        0,
        path,
        address(this),
        block.timestamp
    );
  }

  function _addLiquidity(uint256 tokenAmount, uint256 busdAmount) 
    private 
    returns (uint amountA, uint amountB, uint liquidity)
  {
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
    IUniswapV2Router02 uniswapV2Router = comptroller.getUniswapV2Router();

    // approve token transfer to cover all possible scenarios
    smtToken.safeApprove(address(uniswapV2Router), tokenAmount);
    busdToken.safeApprove(address(uniswapV2Router), busdAmount);
    
    // add the liquidity
    (amountA, amountB, liquidity) = uniswapV2Router.addLiquidity(
        address(smtToken),
        address(busdToken),
        tokenAmount,
        busdAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        address(this),
        block.timestamp
    );
  }


  function _removeLiquidity(uint256 lpAmount) 
    private 
    returns (uint amountA, uint amountB)
  {
    IERC20 smtToken = comptroller.getSMT();
    IERC20 busdToken = comptroller.getBUSD();
    IUniswapV2Router02 uniswapV2Router = comptroller.getUniswapV2Router();

    // approve token transfer to cover all possible scenarios
    address pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(smtToken), address(busdToken));
    IERC20(pair).safeApprove(address(uniswapV2Router), lpAmount);
    
    
    // add the liquidity
    (amountA, amountB) = uniswapV2Router.removeLiquidity(
        address(smtToken),
        address(busdToken),
        lpAmount,
        0, // slippage is unavoidable
        0, // slippage is unavoidable
        address(this),
        block.timestamp
    );
  }
}