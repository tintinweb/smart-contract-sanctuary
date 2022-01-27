// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import '../interfaces/IVerifier.sol';

contract Presale is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;


    struct UserInfo {
        uint8 status; // 0 - 1 - 2 - 3 - 4 : times claim token
        bool finish; // time next cliff
        uint256 totalToken; // total token receive
        uint256 totalTokenClaim; // total token user has received
        uint256 amountUsdt; // amount of usdt user buy
        uint256 amountBusd; // amount of usdt user buy
    }

    struct WaitingInfo {
        uint256 amountUsdt; // amount of usdt user commit to buy
        uint256 amountBusd; // amount of usdt user commit to buy
        bool isRefunded;
    }

    // register
    EnumerableSet.AddressSet private registerList;

    // white list
    EnumerableSet.AddressSet private whiteList;

    // waiting list
    address[] private waitingList;
    mapping(address => uint256) private index;
    mapping(uint256 => bool) private userReservation;

    mapping(address => UserInfo) public userInfo;
    mapping(address => WaitingInfo) public waiting;


    // token erc20 info
    IERC20 public PandoraSpirit;
    IERC20 public USDT;
    IERC20 public BUSD;

    //Verifier claim
    IVerifier public verifier;

    //amount usd bought
    uint256 public totalAmountUSDT = 0;
    uint256 public totalAmountBUSD = 0;

    // sale setting
    uint256 public MAX_BUY_USDT = 1000 ether;
    uint256 public MAX_BUY_PSR = 1000 ether;
    uint256 public totalTokensSale;
    uint256 public remain;
    uint256 public whiteListSlots; // number of white list slot
    uint256 public waitingListSlots; // number of waiting list slot
    uint256 public startSale;
    uint256 public duration;
    // price
    // token buy = usdt * denominator / numerator;
    // rate usdt / psr = numerator / denominator;
    uint256 public numerator = 1;
    uint256 public denominator = 1;

    address public operator;

    //control variable
    bool public isSetting = false;
    bool public isApprove = false;

    modifier allowBuy(address _currency) {
        require(block.timestamp >= startSale && block.timestamp <= startSale + duration, "Token not in sale");
        require(_currency == address(USDT) || _currency == address(BUSD), "Currency not allowed");
        _;
    }

    modifier inWhiteList() {
        require(whiteList.contains(msg.sender), "User not in white list");
        _;
    }

    modifier inWaitingList() {
        require(index[msg.sender] > 0, "User not in waiting list");
        _;
    }

    modifier isWithdraw() {
        require(block.timestamp >= startSale + duration, "Not in time withdraw");
        require(isApprove, "Waiting list on buy time");
        _;
    }

    modifier isSettingTime() {
        require(!isSetting, "Contract has called setting");
        _;
        isSetting = true;
    }

    modifier isCallApprove() {
        require(!isApprove, "Contract has called approve");
        require(block.timestamp > startSale + duration, "Can not approve this time");
        _;
        isApprove = true;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator role can check");
        _;
    }

    // event
    event BuySuccess(address indexed user, uint256 indexed amount, uint256 indexed timestamp);
    event CommitSuccess(address indexed user, uint256 indexed amount, uint256 indexed timestamp);
    event ApproveWaitingBuy(address indexed user, uint256 indexed amount, uint256 indexed timestamp);
    event Claim(address indexed _to, uint256 indexed amount, uint256 indexed timestamp);
    event Withdraw(address indexed _to,uint256 indexed timestamp);

    constructor(IERC20 _psr,IERC20 _usdt, IERC20 _busd, IVerifier _verifier) {
        PandoraSpirit = _psr;
        USDT = _usdt;
        BUSD = _busd;
        verifier = _verifier;
    }

    // ================= INTERNAL FUNCTIONS ================= //
    function _getAmountToken(uint256 _amountIn) internal view returns (uint256) {
        return _amountIn * denominator / numerator;
    }

    function _addWhiteList(address _user) internal {
        require(registerList.contains(_user), "User not in register list");
        require(!(index[_user] != 0), "User already in waiting list");
        whiteList.add(_user);
    }

    function _addWaitingList(address _user) internal {
        require(registerList.contains(_user), "User not in register list");
        require(!whiteList.contains(_user), "User already in white list");
        if(index[_user] != 0) return;
        waitingList.push(_user);
        index[_user] = waitingList.length;
    }

    function _approveWaitingList(uint256 _index) internal returns (bool isBreak) {
        WaitingInfo storage _info = waiting[waitingList[_index]];
        UserInfo storage _userInfo = userInfo[waitingList[_index]];

        isBreak = true;
        if(_getAmountToken(_info.amountBusd) >= remain ) {
            uint256 exceed = (_getAmountToken(_info.amountBusd) - remain) * numerator / denominator;
            _userInfo.amountBusd += _info.amountBusd - exceed;
            _userInfo.amountUsdt = 0;
            _info.amountBusd = exceed;
        } else if(_getAmountToken(_info.amountUsdt) >= remain ) {
            uint256 exceed = (_getAmountToken(_info.amountUsdt) - remain) * numerator / denominator;
            _userInfo.amountUsdt += _info.amountUsdt - exceed;
            _userInfo.amountBusd = 0;
            _info.amountUsdt = exceed;
        } else if(_getAmountToken(_info.amountBusd + _info.amountUsdt) >= remain ) {
            uint256 exceed = (_getAmountToken(_info.amountBusd + _info.amountUsdt) - remain) * numerator / denominator;
            if(_info.amountBusd >= exceed) {
                _userInfo.amountBusd += _info.amountBusd - exceed;
                _userInfo.amountUsdt = _info.amountUsdt;
                _info.amountBusd = exceed;
                _info.amountUsdt = 0;
            } else {
                _userInfo.amountUsdt += _info.amountUsdt - exceed;
                _userInfo.amountBusd = _info.amountBusd;
                _info.amountUsdt = exceed;
                _info.amountBusd = 0;
            }
        } else {
            _userInfo.amountBusd += _info.amountBusd;
            _userInfo.amountUsdt += _info.amountUsdt;
            _info.amountUsdt = 0;
            _info.amountBusd = 0;
            isBreak = false;
        }

        _userInfo.totalToken = _getAmountToken(_userInfo.amountBusd + _userInfo.amountUsdt);
        totalAmountBUSD += _userInfo.amountBusd;
        totalAmountUSDT += _userInfo.amountUsdt;
        remain -= _userInfo.totalToken;

        emit ApproveWaitingBuy(waitingList[_index], _userInfo.totalToken, block.timestamp);
    }

    function _buy(address _currency, uint256 _amount) internal {
        UserInfo storage _info = userInfo[msg.sender];
        require(_amount + _info.amountBusd + _info.amountUsdt <= MAX_BUY_USDT, "User buy overflow allowance");

        // transfer usd to contract
        IERC20(_currency).safeTransferFrom(msg.sender, address(this), _amount);

        // store info
        uint256 _amountPSR = _getAmountToken(_amount);
        // store number of usdt buy
        if(_currency == address(USDT)) {
            _info.amountUsdt += _amount;
            totalAmountUSDT += _amount;
        } else {
            _info.amountBusd += _amount;
            totalAmountBUSD += _amount;
        }
        //        _info.nextCliff = startSale + duration;
        _info.totalToken += _amountPSR;

        //update global
        remain -= _amountPSR;

        //event
        emit BuySuccess(msg.sender, _info.totalToken, block.timestamp);
    }

    // ================= EXTERNAL FUNCTIONS ================= //
    function settingPresale(
        uint256 _whitelistSlots,
        uint256 _waitingListSlots,
        uint256 _startSale,
        uint256 _duration,
        uint256 _numerator,
        uint256 _denominator,
        uint256 _maxBuy
    )
    external
    onlyOwner
    isSettingTime
    {
        require(_startSale > block.timestamp, "_start sale in past");
        require(_numerator > 0 && _denominator > 0, "Price can not be zero");
        whiteListSlots = _whitelistSlots;
        waitingListSlots = _waitingListSlots;
        startSale = _startSale;
        duration = _duration;
        numerator = _numerator;
        denominator = _denominator;
        MAX_BUY_USDT = _maxBuy * 1 ether;
        MAX_BUY_PSR = _getAmountToken(MAX_BUY_USDT);
        totalTokensSale = _getAmountToken(MAX_BUY_USDT * whiteListSlots);
        remain = totalTokensSale;
        PandoraSpirit.safeTransferFrom(msg.sender, address(this), totalTokensSale);
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(_newOperator != address(0), "Operator must be different address 0");
        operator = _newOperator;
    }

    function addWhiteList(address[] memory _whiteList) external onlyOperator {
        require(_whiteList.length + whiteList.length() <= whiteListSlots, "white list overflow" );
        require(block.timestamp < startSale, "Can not add white list after starting sale" );
        for(uint i = 0; i < _whiteList.length; i ++) {
            _addWhiteList(_whiteList[i]);
        }
    }

    function addWaitingList(address[] memory _waitingList) external onlyOperator{
        require(_waitingList.length + waitingList.length <= waitingListSlots, "waiting list overflow" );
        require(block.timestamp < startSale, "Can not add waiting list after starting sale" );
        for(uint i = 0; i < _waitingList.length; i ++) {
            _addWaitingList(_waitingList[i]);
        }
    }


    function buy(address _currency, uint256 _amount) public allowBuy(_currency) inWhiteList whenNotPaused {
        _buy(_currency, _amount);
    }

    // user in waiting list reserve slot to buy
    function reserveSlot(address _currency, uint256 _amount) public allowBuy(_currency) inWaitingList whenNotPaused {
        WaitingInfo storage _info = waiting[msg.sender];
        require(_amount + _info.amountBusd + _info.amountUsdt <= MAX_BUY_USDT, "User buy overflow allowance");

        // transfer usd to contract
        IERC20(_currency).safeTransferFrom(msg.sender, address(this), _amount);

        // update _info
        if(_currency == address(USDT)) {
            _info.amountUsdt += _amount;
        } else {
            _info.amountBusd += _amount;
        }

        //store user in list
        userReservation[index[msg.sender] -1] = true;

        //emit event
        emit CommitSuccess(msg.sender, _amount, block.timestamp);
    }

    function approveWaitingList() public isCallApprove {
        if(remain == 0) return;
        uint256 _length = waitingList.length;
        for(uint256 i = 0; i < _length; i++) {
            if(!userReservation[i]) continue;
            if(_approveWaitingList(i)) break;
        }
    }

    function claim(address _to) public nonReentrant {
        require(_to != address(0), "address must be different 0");
        UserInfo storage _userInfo = userInfo[msg.sender];
        require(_userInfo.totalToken > 0 || !_userInfo.finish, "User not in list claim");
        (uint256 amountClaim, bool finish) = verifier.verify(msg.sender, _userInfo.totalToken, _userInfo.status);
        if(finish) {
            _userInfo.finish = finish;
            amountClaim = _userInfo.totalToken - _userInfo.totalTokenClaim;
        }
        _userInfo.totalTokenClaim += amountClaim;
        _userInfo.status += 1;
        PandoraSpirit.safeTransfer(_to, amountClaim);
        emit Claim(_to, amountClaim, block.timestamp);
    }

    function withdraw() public isWithdraw nonReentrant {
        WaitingInfo storage _waitingInfo = waiting[msg.sender];
        require(_waitingInfo.amountUsdt > 0 || _waitingInfo.amountBusd > 0, "Don't have any fund");

        if(_waitingInfo.amountUsdt > 0) {
            uint256 amountUsdt = _waitingInfo.amountUsdt;
            _waitingInfo.amountUsdt = 0;
            USDT.safeTransfer(msg.sender, amountUsdt);
        }

        if(_waitingInfo.amountBusd > 0) {
            uint256 amountBusd = _waitingInfo.amountBusd;
            _waitingInfo.amountBusd = 0;
            BUSD.safeTransfer(msg.sender, amountBusd);
        }
        _waitingInfo.isRefunded = true;
        emit Withdraw(msg.sender, block.timestamp);

    }

    function register() external {
        bool added = registerList.add(msg.sender);
        require(added, "User has registered");
    }




    // ================= VIEWS FUNCTIONS ================= //
    function isRegistered(address _user) external view returns(bool) {
        return registerList.contains(_user);
    }

    function listRegister() external view returns(address[] memory) {
        return registerList.values();
    }

    function totalRegister() external view returns(uint256) {
        return registerList.length();
    }

    function isWhiteList(address _user) external view returns(bool) {
        return whiteList.contains(_user);
    }

    function whiteListUser() external view returns(address[] memory) {
        return whiteList.values();
    }

    function totalWhiteList() external view returns(uint256) {
        return whiteList.length();
    }

    function isWaitingList(address _user) external view returns(bool) {
        return index[_user] > 0;
    }

    function waitingListUser() external view returns(address[] memory) {
        return waitingList;
    }

    function totalWaitingList() external view returns(uint256) {
        return waitingList.length;
    }

    function getAmountOfAllowBuying(address _user) external view returns(uint256) {
        return MAX_BUY_USDT - (userInfo[_user].amountUsdt + userInfo[_user].amountBusd);
    }


    // ================= ADMIN FUNCTIONS ================= //
    function emergencyWithdraw(address _to) external onlyOwner whenPaused {
        PandoraSpirit.safeTransfer(_to, PandoraSpirit.balanceOf(address(this)));
        USDT.safeTransfer(_to, USDT.balanceOf(address(this)));
        BUSD.safeTransfer(_to, BUSD.balanceOf(address(this)));
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function withdrawAdmin(address _to) public onlyOwner {
        require(block.timestamp >= startSale + duration && isApprove, "Can not withdraw before end");
        USDT.safeTransfer(_to, totalAmountUSDT);
        BUSD.safeTransfer(_to, totalAmountBUSD);
        if (remain > 0) {
            PandoraSpirit.safeTransfer(_to, remain);
        }
    }
}

pragma solidity =0.8.4;

interface IVerifier {
    function verify(address _user, uint256 _totalToken, uint256 _claimTimes) external view returns(uint,bool);
}