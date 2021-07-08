/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;


// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// 
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// 
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
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
        return address(uint256(_at(set._inner, index)));
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
}

// 
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

    // constructor () internal {
    //     _status = _NOT_ENTERED;
    // }

    function _ReentrancyGuard() internal {
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
}

// 
// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// 
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

// 
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// 
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
interface IERC20Decimals {
    function decimals() external pure returns (uint8);
}

// 
interface IMintable {
    function mint(address account, uint256 amount) external;
}

// 
interface IBurnable {
    function burnFrom(address account, uint256 amount) external;
}

// 
interface IOracle {
    function getLatestPrice() external view returns (uint256);
}

// 
interface IWrappedNativeToken {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// 
interface IFlashLoanReceiver {
    function execute(address token, uint256 amount, uint256 fee, address back, bytes calldata params) external;
}

// 
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// 
contract Admined is AccessControl {
    function _Admined(address admin) internal {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins");
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function getAdminCount() public view returns(uint256) {
        return getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    }

    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    function renounceAdmin() public virtual {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        require(
            getRoleMemberCount(DEFAULT_ADMIN_ROLE) >= 1,
            "At least one admin required"
        );
    }

    uint256[50] private __gap;
}

// 
contract Owned is Admined {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event AddedOwner(address indexed account);
    event RemovedOwner(address indexed account);
    event RenouncedOwner(address indexed account);

    //constructor
    function _Owned(address admin, address owner) internal {
        _Admined(admin);
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(OWNER_ROLE, owner);
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "restricted-to-owners");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return hasRole(OWNER_ROLE, account);
    }

    function getOwners() public view returns (address[] memory) {
        uint256 count = getRoleMemberCount(OWNER_ROLE);
        address[] memory owners = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            owners[i] = getRoleMember(OWNER_ROLE, i);
        }
        return owners;
    }

    function addOwner(address account) public onlyAdmin {
        grantRole(OWNER_ROLE, account);
        emit AddedOwner(account);
    }

    function removeOwner(address account) public onlyAdmin {
        revokeRole(OWNER_ROLE, account);
        emit RemovedOwner(account);
    }

    function renounceOwner() public {
        renounceRole(OWNER_ROLE, msg.sender);
        emit RenouncedOwner(msg.sender);
    }

    uint256[50] private __gap;
}

// 
contract Lockable is Owned {
    
    mapping(bytes4 => bool) public disabledList; 
    bool public globalDisable; 

    function _Lockable() internal {
    }

    modifier notLocked() {
        require(!globalDisable && !disabledList[msg.sig], "locked");
        _;
    }

    function enableListAccess(bytes4 sig) public onlyOwner {
        disabledList[sig] = false;
    }

    function disableListAccess(bytes4 sig) public onlyOwner {
        disabledList[sig] = true;
    }

    function enableGlobalAccess() public onlyOwner {
        globalDisable = false;
    }

    function disableGlobalAccess() public onlyOwner {
        globalDisable = true;
    }

    uint256[50] private __gap;
}

// 
contract Vault is Initializable, ReentrancyGuard, Lockable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    event MintCollateral(address indexed sender, address indexed collateralToken, uint256 collateralAmount, uint256 mintAmount, uint256 mintFeeAmount);
    event MintShare(address indexed sender, uint256 shareAmount, uint256 mintAmount);
    event MintCollateralAndShare(address indexed sender, address indexed collateralToken, uint256 collateralAmount, uint256 shareAmount, uint256 mintAmount, uint256 mintFeeCollateralAmount, uint256 globalCollateralRatio);
    event RedeemCollateral(address indexed sender, uint256 stableAmount, address indexed collateralToken, uint256 redeemAmount, uint256 redeemFeeAmount);
    event RedeemShare(address indexed sender, uint256 shareAmount, uint256 redeemAmount);
    event RedeemCollateralAndShare(address indexed sender, uint256 stableAmount, address indexed collateralToken, uint256 redeemCollateralAmount, uint256 redeemShareAmount, uint256 redeemCollateralFeeAmount, uint256 globalCollateralRatio);
    event ExchangeShareBond(address indexed sender, uint256 shareBondAmount);
    event Recollateralize(address indexed sender, uint256 recollateralizeAmount, address indexed collateralToken, uint256 paidbackShareAmount);
    event Buyback(address indexed sender, uint256 shareAmount, address indexed receivedCollateralToken, uint256 buybackAmount, uint256 buybackFeeAmount);
    event FlashLoan(address indexed receiver, address indexed token, uint256 amount, uint256 fee, uint256 timestamp);

    address constant public NATIVE_TOKEN_ADDRESS = address(0x0000000000000000000000000000000000000000);
    uint256 constant public TARGET_PRICE = 1000000000000000000; //$1
    uint256 constant public SHARE_TOKEN_PRECISION = 1000000000000000000;    //1e18
    uint256 constant public STABLE_TOKEN_PRECISION = 1000000000000000000;   //1e18
    uint256 constant public DELAY_CLAIM_BLOCK = 3;  //prevent flash redeem!! 

    uint256 public redeemFee;               //赎回手续费率 [1e18] 0.45% => 4500000000000000
    uint256 public mintFee;                 //增发手续费率 [1e18] 0.45% => 4500000000000000
    uint256 public buybackFee;              //回购手续费率 [1e18] 0.45% => 4500000000000000
    uint256 public globalCollateralRatio;   //全局质押率 [1e18] 1000000000000000000
    uint256 public flashloanFee;            //闪电贷手续费率
    uint256 public shareBondCeiling;        //股份币债券发行上限.
    uint256 public shareBondSupply;         //股份币债券当前发行量
    uint256 public lastRefreshTime;         //全局质押率的最后调节时间.

    uint256 public refreshStep;             //全局质押率的单次调节幅度 [1e18] 0.05 => 50000000000000000
    uint256 public refreshPeriod;           //全局质押率的调节周期(seconds)
    uint256 public refreshBand;             //全局质押率的调节线 [1e18] 0.05 => 50000000000000000 

    address public stableToken;             //stable token
    address public shareToken;              //share token
    address public stableBondToken;         //锚定稳定币的债券代币, 在适当的时候可以赎回. [废弃]
    address public shareBondToken;          //锚定股份币的债券代币, 在适当的时候可以赎回 
    address payable public protocolFund;    //收益基金

    struct Collateral {
        bool deprecated;                    //抵押物废弃标记 
        uint256 recollateralizeFee;         //在抵押奖励率 [1e18]
        uint256 ceiling;                    //抵押物的铸币上限
        uint256 precision;                  //抵押物的精度
        address oracle;                     //抵押物的预言机
    }

    mapping(address => uint256) public lastRedeemBlock;         //账户的最后赎回交易块号. account => block.number
    mapping(address => uint256) public redeemedShareBonds;      //账户已赎回但未取回的share代币总量. account => shareAmount
    mapping(address => uint256) public unclaimedCollaterals;    //系统内已赎回但未取回的某抵押物总量. collateralToken => collateralAmount
    mapping(address => mapping(address => uint256)) public redeemedCollaterals; //账户已赎回但未取回的某抵押物总量. account => token => amount
    
    address public shareTokenOracle;
    address public stableTokenOracle;
    
    EnumerableSet.AddressSet private collateralTokens;  //抵押物代币集合.
    mapping(address => Collateral) public collaterals;  //抵押物配置. collateralToken => Collateral 

    address public wrappedNativeToken;    
    bool public kbtToKunImmediately;
    uint256 public buybackBonus;

    function initialize(
        address _stableToken,
        address _shareToken,
        address _shareBondToken,
        address _wrappedNativeToken,
        address _admin,
        address _stableTokenOracle,
        address _shareTokenOracle
    ) public initializer {
        _Owned(_admin, msg.sender); 
        _ReentrancyGuard();
        stableToken = _stableToken;
        shareToken = _shareToken;
        wrappedNativeToken = _wrappedNativeToken;
        shareBondToken = _shareBondToken;
        stableTokenOracle = _stableTokenOracle;
        shareTokenOracle = _shareTokenOracle;
        globalCollateralRatio = 1e18;
    }

    //计算抵押物价值
    function calculateCollateralValue(address collateralToken, uint256 collateralAmount) public view returns (uint256) {
        return collateralAmount.mul(getCollateralPrice(collateralToken)).div(collaterals[collateralToken].precision); 
    }

    //计算抵押物的铸币数量和手续费(以抵押物计)
    function calculateCollateralMintAmount(address collateralToken, uint256 collateralAmount) public view returns (uint256, uint256) {
        uint256 mintFeeAmount = collateralAmount.mul(mintFee).div(1e18);
        collateralAmount = collateralAmount.sub(mintFeeAmount);
        return (calculateCollateralValue(collateralToken, collateralAmount), mintFeeAmount);
    }

    //计算股份币的铸币数量
    function calculateShareMintAmount(uint256 shareAmount) public view returns(uint256) {
        return shareAmount.mul(getShareTokenPrice()).div(SHARE_TOKEN_PRECISION);
    }

    //计算抵押物和股份币的铸币数量
    //@RETURN1 铸币量
    //@RETURN2 所需的股份币的数量
    //@RETURN3 抵押物部分的手续费(以抵押物计)

    function calculateCollateralAndShareMintAmount(address collateralToken, uint256 collateralAmount) public view returns(uint256, uint256, uint256) {
        uint256 collateralValue = calculateCollateralValue(collateralToken, collateralAmount);
        uint256 shareTokenPrice = getShareTokenPrice();
        //https://docs.qian.finance/qian-v2-whitepaper/minting
        //(1 - Cr) * Cv = Cr * Sv
        //Sv = ((1 - Cr) * Cv) / Cr
        //   = (Cv - (Cv * Cr)) / Cr
        //   = (Cv / Cr) - ((Cv * Cr) / Cr)
        //   = (Cv / Cr) - Cv

        uint256 shareValue = collateralValue.mul(1e18).div(globalCollateralRatio).sub(collateralValue);
        uint256 shareAmount = shareValue.mul(SHARE_TOKEN_PRECISION).div(shareTokenPrice);

        uint256 mintFeeValue = collateralValue.mul(mintFee).div(1e18);
        uint256 mintFeeCollateralAmount = calculateEquivalentCollateralAmount(mintFeeValue, collateralToken);
        
        uint256 mintAmount = collateralValue.sub(mintFeeValue).add(shareValue); 
        return (mintAmount, shareAmount, mintFeeCollateralAmount);
    }

    //计算赎回抵押物的数量和手续费(以抵押物计)
    function calculateCollateralRedeemAmount(uint256 stableAmount, address collateralToken) public view returns (uint256, uint256) {
        uint256 redeemAmount = calculateEquivalentCollateralAmount(stableAmount, collateralToken);
        uint256 redeemFeeAmount = redeemAmount.mul(redeemFee).div(1e18);
        return (redeemAmount.sub(redeemFeeAmount), redeemFeeAmount);
    }

    //计算赎回股份币的数量(以股份币计)
    function calculateShareRedeemAmount(uint256 stableAmount) public view returns (uint256) {
        uint256 shareAmount = stableAmount.mul(SHARE_TOKEN_PRECISION).div(getShareTokenPrice());
        return shareAmount;
    }

    //计算赎回股份币和抵押物的数量.
    //@RETURN1 抵押物的数量
    //@RETURN2 股份币的数量
    //@RETURN4 抵押物部分的手续费

    function calculateCollateralAndShareRedeemAmount(uint256 stableAmount, address collateralToken) public view returns (uint256, uint256, uint256) {
        uint256 collateralValue = stableAmount.mul(globalCollateralRatio).div(1e18);
        uint256 collateralAmount = calculateEquivalentCollateralAmount(collateralValue, collateralToken);

        uint256 shareValue = stableAmount.sub(collateralValue);
        uint256 shareAmount = shareValue.mul(SHARE_TOKEN_PRECISION).div(getShareTokenPrice());

        uint256 redeemFeeCollateralAmount = collateralAmount.mul(redeemFee).div(1e18);
        
        return (collateralAmount.sub(redeemFeeCollateralAmount), shareAmount, redeemFeeCollateralAmount);
    }

    //计算同等美元价值的抵押物数量
    //注: 系统中@stableToken的价格总是$1, 所以@stableAmount等价于相同数量的美元.
    function calculateEquivalentCollateralAmount(uint256 stableAmount, address collateralToken) public view returns (uint256) {
        //stableAmount / collateralPrice
        return stableAmount.mul(collaterals[collateralToken].precision).div(getCollateralPrice(collateralToken));    //1e18
    }

    //100% collateral-backed
    function mint(address collateralToken, uint256 collateralAmount, uint256 minimumReceived) external payable notLocked nonReentrant {
        require(isCollateralToken(collateralToken) && !collaterals[collateralToken].deprecated, "invalid/deprecated-collateral-token");
        require(globalCollateralRatio >= 1e18, "mint-not-allowed");
        (uint256 mintAmount, uint256 mintFeeAmount) = calculateCollateralMintAmount(collateralToken, collateralAmount);
        require(minimumReceived <= mintAmount, "slippage-limit-reached");
        require(getCollateralizedBalance(collateralToken).add(collateralAmount) <= collaterals[collateralToken].ceiling, "ceiling-reached");

        _depositFrom(collateralToken, msg.sender, collateralAmount);
        _withdrawTo(collateralToken, protocolFund, mintFeeAmount);

        IMintable(stableToken).mint(msg.sender, mintAmount);
        emit MintCollateral(msg.sender, collateralToken, collateralAmount, mintAmount, mintFeeAmount);
    }

    // 0% collateral-backed
    function mint(uint256 shareAmount, uint256 minimumReceived) external notLocked nonReentrant {
        require(globalCollateralRatio == 0, "mint-not-allowed");
        uint256 mintAmount = calculateShareMintAmount(shareAmount);
        require(minimumReceived <= mintAmount, "slippage-limit-reached");
        IBurnable(shareToken).burnFrom(msg.sender, shareAmount);
        IMintable(stableToken).mint(msg.sender, mintAmount);
        emit MintShare(msg.sender, shareAmount, mintAmount);
    }

    // > 0% and < 100% collateral-backed
    function mint(address collateralToken, uint256 collateralAmount, uint256 shareAmount, uint256 minimumReceived) external payable notLocked nonReentrant {
        require(isCollateralToken(collateralToken) && !collaterals[collateralToken].deprecated, "invalid/deprecated-collateral-token");
        require(globalCollateralRatio < 1e18 && globalCollateralRatio > 0, "mint-not-allowed");
        require(getCollateralizedBalance(collateralToken).add(collateralAmount) <= collaterals[collateralToken].ceiling, "ceiling-reached");
        (uint256 mintAmount, uint256 shareNeeded, uint256 mintFeeCollateralAmount) = calculateCollateralAndShareMintAmount(collateralToken, collateralAmount);
        require(minimumReceived <= mintAmount, "slippage-limit-reached");
        require(shareNeeded <= shareAmount, "need-more-shares");
        
        IBurnable(shareToken).burnFrom(msg.sender, shareNeeded);

        _depositFrom(collateralToken, msg.sender, collateralAmount);
        _withdrawTo(collateralToken, protocolFund, mintFeeCollateralAmount);

        IMintable(stableToken).mint(msg.sender, mintAmount);
        emit MintCollateralAndShare(msg.sender, collateralToken, collateralAmount, shareNeeded, mintAmount, mintFeeCollateralAmount, globalCollateralRatio);
    }

    // Redeem collateral. 100% collateral-backed
    function redeem(uint256 stableAmount, address receivedCollateralToken, uint256 minimumReceivedCollateralAmount) external notLocked nonReentrant {
        require(globalCollateralRatio == 1e18, "redeem-not-allowed");
        (uint256 redeemAmount, uint256 redeemFeeAmount) = calculateCollateralRedeemAmount(stableAmount, receivedCollateralToken);
        require(redeemAmount.add(redeemFeeAmount) <= getCollateralizedBalance(receivedCollateralToken), "not-enough-collateral");
        require(minimumReceivedCollateralAmount <= redeemAmount, "slippage-limit-reached");
        redeemedCollaterals[msg.sender][receivedCollateralToken] = redeemedCollaterals[msg.sender][receivedCollateralToken].add(redeemAmount);
        unclaimedCollaterals[receivedCollateralToken] = unclaimedCollaterals[receivedCollateralToken].add(redeemAmount);
        lastRedeemBlock[msg.sender] = block.number;
        IBurnable(stableToken).burnFrom(msg.sender, stableAmount);
        _withdrawTo(receivedCollateralToken, protocolFund, redeemFeeAmount);
        emit RedeemCollateral(msg.sender, stableAmount, receivedCollateralToken, redeemAmount, redeemFeeAmount);
    }

    // Redeem QSD for collateral and KUN. > 0% and < 100% collateral-backed
    function redeem(uint256 stableAmount, address collateralToken, uint256 minimumReceivedCollateralAmount, uint256 minimumReceivedShareAmount) external notLocked nonReentrant {
        require(globalCollateralRatio < 1e18 && globalCollateralRatio > 0, "redeem-not-allowed");
        (uint256 collateralAmount, uint256 shareAmount, uint256 redeemFeeCollateralAmount) = calculateCollateralAndShareRedeemAmount(stableAmount, collateralToken);
        require(collateralAmount.add(redeemFeeCollateralAmount) <= getCollateralizedBalance(collateralToken), "not-enough-collateral");
        require(minimumReceivedCollateralAmount <= collateralAmount && minimumReceivedShareAmount <= shareAmount, "collaterals/shares-slippage-limit-reached");
        redeemedCollaterals[msg.sender][collateralToken] = redeemedCollaterals[msg.sender][collateralToken].add(collateralAmount);
        unclaimedCollaterals[collateralToken] = unclaimedCollaterals[collateralToken].add(collateralAmount);
        redeemedShareBonds[msg.sender] = redeemedShareBonds[msg.sender].add(shareAmount);
        shareBondSupply = shareBondSupply.add(shareAmount);
        require(shareBondSupply <= shareBondCeiling, "sharebond-ceiling-reached");
        lastRedeemBlock[msg.sender] = block.number;
        IBurnable(stableToken).burnFrom(msg.sender, stableAmount);
        _withdrawTo(collateralToken, protocolFund, redeemFeeCollateralAmount);
        emit RedeemCollateralAndShare(msg.sender, stableAmount, collateralToken, collateralAmount, shareAmount, redeemFeeCollateralAmount, globalCollateralRatio);
    }

    // Redeem QSD for KUN. 0% collateral-backed
    function redeem(uint256 stableAmount, uint256 minimumReceivedShareAmount) external notLocked nonReentrant {
        require(globalCollateralRatio == 0, "redeem-not-allowed");
        uint256 shareAmount = calculateShareRedeemAmount(stableAmount);
        require(minimumReceivedShareAmount <= shareAmount, "slippage-limit-reached");
        redeemedShareBonds[msg.sender] = redeemedShareBonds[msg.sender].add(shareAmount);
        shareBondSupply = shareBondSupply.add(shareAmount);
        require(shareBondSupply <= shareBondCeiling, "sharebond-ceiling-reached");
        lastRedeemBlock[msg.sender] = block.number;
        IBurnable(stableToken).burnFrom(msg.sender, stableAmount);
        emit RedeemShare(msg.sender, stableAmount, shareAmount);
    }

    function claim() external notLocked nonReentrant {
        require(lastRedeemBlock[msg.sender].add(DELAY_CLAIM_BLOCK) <= block.number,"not-delay-claim-redeemed");
        uint256 length = collateralTokens.length();
        for (uint256 i = 0; i < length; ++i) {
            address collateralToken = collateralTokens.at(i);
            if (redeemedCollaterals[msg.sender][collateralToken] > 0) {
                uint256 collateralAmount = redeemedCollaterals[msg.sender][collateralToken];
                redeemedCollaterals[msg.sender][collateralToken] = 0;
                unclaimedCollaterals[collateralToken] = unclaimedCollaterals[collateralToken].sub(collateralAmount);
                _withdrawTo(collateralToken, msg.sender, collateralAmount);
            }
        }
        if (redeemedShareBonds[msg.sender] > 0) {
            uint256 shareAmount = redeemedShareBonds[msg.sender];
            redeemedShareBonds[msg.sender] = 0;
            IMintable(shareBondToken).mint(msg.sender, shareAmount);
        }
    }

    //当系统的实际质押率低于全局质押率时, 需要用户向系统补充抵押物。 用户会获得相应价值的KUN债券和部分额外的KUN债券奖励.
    function recollateralize(address collateralToken, uint256 collateralAmount, uint256 minimumReceivedShareAmount) external payable notLocked nonReentrant {
        require(isCollateralToken(collateralToken) && !collaterals[collateralToken].deprecated, "deprecated-collateral-token");
        
        uint256 gapCollateralValue = getGapCollateralValue();
        require(gapCollateralValue > 0, "no-gap-collateral-to-recollateralize");
        uint256 recollateralizeValue = Math.min(gapCollateralValue, calculateCollateralValue(collateralToken, collateralAmount));
        uint256 paidbackShareAmount = recollateralizeValue.mul(uint256(1e18).add(collaterals[collateralToken].recollateralizeFee)).div(getShareTokenPrice());
        require(minimumReceivedShareAmount <= paidbackShareAmount, "slippage-limit-reached");
       
        uint256 recollateralizeAmount = recollateralizeValue.mul(1e18).div(getCollateralPrice(collateralToken));
        require(getCollateralizedBalance(collateralToken).add(recollateralizeAmount) <= collaterals[collateralToken].ceiling, "ceiling-reached");
        shareBondSupply = shareBondSupply.add(paidbackShareAmount);
        require(shareBondSupply <= shareBondCeiling, "sharebond-ceiling-reached");
        
        _depositFrom(collateralToken, msg.sender, collateralAmount);
        _withdrawTo(collateralToken, msg.sender, collateralAmount.sub(recollateralizeAmount));

        IMintable(shareBondToken).mint(msg.sender, paidbackShareAmount);
        emit Recollateralize(msg.sender, recollateralizeAmount, collateralToken, paidbackShareAmount);
    }

    //当系统的实际质押率高于全局质押率时, 需要可以使用KUN向系统购买抵押物。
    function buyback(uint256 shareAmount, address receivedCollateralToken) external notLocked nonReentrant {
        uint256 excessCollateralValue = getExcessCollateralValue();
        require(excessCollateralValue > 0, "no-excess-collateral-to-buyback");
        uint256 shareTokenPrice = getShareTokenPrice();
        uint256 shareValue = shareAmount.mul(shareTokenPrice).div(1e18);
        shareValue = shareValue.mul(uint256(1e18).add(buybackBonus)).div(1e18); //0.01e18
        uint256 buybackValue = excessCollateralValue > shareValue ? shareValue : excessCollateralValue;
        uint256 neededAmount = buybackValue.mul(1e18).div(shareTokenPrice);
        neededAmount = neededAmount.mul(1e18).div(uint256(1e18).add(buybackBonus));
        IBurnable(shareToken).burnFrom(msg.sender, neededAmount);
        uint256 buybackAmount = calculateEquivalentCollateralAmount(buybackValue, receivedCollateralToken);
        require(buybackAmount <= getCollateralizedBalance(receivedCollateralToken), "insufficient-collateral-amount");
        uint256 buybackFeeAmount = buybackAmount.mul(buybackFee).div(1e18);
        buybackAmount = buybackAmount.sub(buybackFeeAmount);

        _withdrawTo(receivedCollateralToken, msg.sender, buybackAmount);
        _withdrawTo(receivedCollateralToken, protocolFund, buybackFeeAmount);

        emit Buyback(msg.sender, shareAmount, receivedCollateralToken, buybackAmount, buybackFeeAmount);
    }

    //在同时满足下面两个条件的时候, KUN债券可以1:1兑换为KUN:
    //  1. 当系统的实际质押率高于全局质押率时
    //  &&
    //  2. QSD的价格在目标价格以上(>$1)
    function exchangeShareBond(uint256 shareBondAmount) external notLocked nonReentrant {
        if(!kbtToKunImmediately) {
            uint256 excessCollateralValue = getExcessCollateralValue();
            require(excessCollateralValue > 0, "no-excess-collateral-to-buyback");
            uint256 stableTokenPrice = getStableTokenPrice(); 
            require(stableTokenPrice > TARGET_PRICE, "price-not-eligible-for-bond-redeem");
        }
        shareBondSupply = shareBondSupply.sub(shareBondAmount);
        IBurnable(shareBondToken).burnFrom(msg.sender, shareBondAmount);
        IMintable(shareToken).mint(msg.sender, shareBondAmount);
        emit ExchangeShareBond(msg.sender, shareBondAmount);
    }

    //调节全局质押率.
    function refreshCollateralRatio() public notLocked {
        uint256 stableTokenPrice = getStableTokenPrice();
        require(block.timestamp - lastRefreshTime >= refreshPeriod, "refresh-cooling-period");
        if (stableTokenPrice > TARGET_PRICE.add(refreshBand)) { //decrease collateral ratio
            if (globalCollateralRatio <= refreshStep) {  
                globalCollateralRatio = 0;  //if within a step of 0, go to 0
            } else {
                globalCollateralRatio = globalCollateralRatio.sub(refreshStep);
            }
        } else if (stableTokenPrice < TARGET_PRICE.sub(refreshBand)) { //increase collateral ratio
            if (globalCollateralRatio.add(refreshStep) >= 1e18) {  
                globalCollateralRatio = 1e18; // cap collateral ratio at 1
            } else {
                globalCollateralRatio = globalCollateralRatio.add(refreshStep);
            }
        }
        lastRefreshTime = block.timestamp; // Set the time of the last expansion
    }

    function flashloan(
        address receiver,
        address token,
        uint256 amount,
        bytes memory params
    ) public notLocked nonReentrant {
        require(isCollateralToken(token), "invalid-collateral-token");
        require(amount > 0, "invalid-flashloan-amount");

        address t = (token == NATIVE_TOKEN_ADDRESS) ? wrappedNativeToken : token;
        uint256 balancesBefore = IERC20(t).balanceOf(address(this));
        require(balancesBefore >= amount, "insufficient-balance");

        uint256 balance = address(this).balance;

        uint256 fee = amount.mul(flashloanFee).div(1e18);
        require(fee > 0, "invalid-flashloan-fee");

        IFlashLoanReceiver flashLoanReceiver = IFlashLoanReceiver(receiver);
        address payable _receiver = address(uint160(receiver));

        // withdraw ether from WXXX to _receiver
        _withdrawTo(token, _receiver, amount);
        flashLoanReceiver.execute(token, amount, fee, address(this), params);

        if(token == NATIVE_TOKEN_ADDRESS) {
            //move _receiver repaid ether to WXXX
            require(address(this).balance >= balance.add(amount).add(fee), "ether-balance-exception");
            IWrappedNativeToken(wrappedNativeToken).deposit{value: amount.add(fee)}();
        }

        uint256 balancesAfter = IERC20(t).balanceOf(address(this));
        require(balancesAfter >= balancesBefore.add(fee), "balance-exception");

        _withdrawTo(token, protocolFund, fee);
        emit FlashLoan(receiver, token, amount, fee, block.timestamp);
    }

    function getNeededCollateralValue() public view returns(uint256) {
        uint256 stableSupply = IERC20(stableToken).totalSupply();
        // Calculates collateral needed to back each 1 QSD with $1 of collateral at current collat ratio
        return stableSupply.mul(globalCollateralRatio).div(1e18);
    }

    // Returns the value of excess collateral held in this pool, compared to what is needed to maintain the global collateral ratio
    function getExcessCollateralValue() public view returns (uint256) {
        uint256 totalCollateralValue = getTotalCollateralValue(); 
        uint256 neededCollateralValue = getNeededCollateralValue();
        if (totalCollateralValue > neededCollateralValue)
            return totalCollateralValue.sub(neededCollateralValue);
        return 0;
    }

    function getGapCollateralValue() public view returns(uint256) {
        uint256 totalCollateralValue = getTotalCollateralValue();
        uint256 neededCollateralValue = getNeededCollateralValue();
        if(totalCollateralValue < neededCollateralValue)
            return neededCollateralValue.sub(totalCollateralValue);
        return 0;
    }
    
    function getShareTokenPrice() public view returns(uint256) {
        return IOracle(shareTokenOracle).getLatestPrice();
    }
    function getStableTokenPrice() public view returns(uint256) {
        return IOracle(stableTokenOracle).getLatestPrice();
    }
    function getCollateralPrice(address token) public view returns (uint256) {
        return IOracle(collaterals[token].oracle).getLatestPrice();
    }

    function getTotalCollateralValue() public view returns (uint256) {
        uint256 totalCollateralValue = 0;
        uint256 length = collateralTokens.length();
        for (uint256 i = 0; i < length; ++i)
            totalCollateralValue = totalCollateralValue.add(getCollateralValue(collateralTokens.at(i)));
        return totalCollateralValue;
    }

    function getCollateralValue(address token) public view returns (uint256) {
        if(isCollateralToken(token))
            return getCollateralizedBalance(token).mul(getCollateralPrice(token)).div(collaterals[token].precision);
        return 0;
    }

    function isCollateralToken(address token) public view returns (bool) {
        return collateralTokens.contains(token);
    }

    function getCollateralTokens() public view returns (address[] memory) {
        uint256 length = collateralTokens.length();
        address[] memory tokens = new address[](length);
        for (uint256 i = 0; i < length; ++i)
            tokens[i] = collateralTokens.at(i);
        return tokens;
    }

    function getCollateralizedBalance(address token) public view returns(uint256) {
        address tt = (token == NATIVE_TOKEN_ADDRESS) ? wrappedNativeToken : token;
        uint256 balance = IERC20(tt).balanceOf(address(this));
        return balance.sub(Math.min(balance, unclaimedCollaterals[token]));
    }

    function setStableTokenOracle(address newStableTokenOracle) public onlyOwner {
        stableTokenOracle = newStableTokenOracle;
    }

    function setShareTokenOracle(address newShareTokenOracle) public onlyOwner {
        shareTokenOracle = newShareTokenOracle;
    }

    function setRedeemFee(uint256 newRedeemFee) external onlyOwner {
        redeemFee = newRedeemFee;
    }

    function setMintFee(uint256 newMintFee) external onlyOwner {
        mintFee = newMintFee;
    }

    function setBuybackFee(uint256 newBuybackFee) external onlyOwner {
        buybackFee = newBuybackFee;
    }

    function addCollateralToken(address token, address oracle, uint256 ceiling, uint256 recollateralizeFee) external onlyOwner {
        require(collateralTokens.add(token) || collaterals[token].deprecated, "duplicated-collateral-token");
        if(token == NATIVE_TOKEN_ADDRESS) {
            collaterals[token].precision = 10**18;
        } else {
            uint256 decimals = IERC20Decimals(token).decimals();
            require(decimals <= 18, "unexpected-collateral-token");
            collaterals[token].precision = 10**decimals;
        }
        collaterals[token].deprecated = false;
        collaterals[token].oracle = oracle;
        collaterals[token].ceiling = ceiling;
        collaterals[token].recollateralizeFee = recollateralizeFee;
    }

    function deprecateCollateralToken(address token) external onlyOwner {
        require(isCollateralToken(token), "not-found-collateral-token");
        collaterals[token].deprecated = true;
    }

    function removeCollateralToken(address token) external onlyOwner {
        require(collaterals[token].deprecated, "undeprecated-collateral-token");
        require(collateralTokens.remove(token), "not-found-token");
        delete collaterals[token];
    }

    function updateCollateralToken(address token, address newOracle, uint256 newCeiling, uint256 newRecollateralizeFee) public onlyOwner {
        require(isCollateralToken(token), "not-found-collateral-token");
        collaterals[token].ceiling = newCeiling;
        collaterals[token].oracle = newOracle;
        collaterals[token].recollateralizeFee = newRecollateralizeFee;
    }

    function setRefreshPeriod(uint256 newRefreshPeriod) external onlyOwner {
        refreshPeriod = newRefreshPeriod;
    }

    function setRefreshStep(uint256 newRefreshStep) external onlyOwner {
        refreshStep = newRefreshStep;
    }

    function setRefreshBand(uint256 newRefreshBand) external onlyOwner {
        refreshBand = newRefreshBand;
    }

    function setProtocolFund(address payable newProtocolFund) public onlyOwner {
        protocolFund =  newProtocolFund;
    }

    function setFlashloanFee(uint256 newFlashloanFee) public onlyOwner {
        flashloanFee = newFlashloanFee;
    }

    function setGlobalCollateralRatio(uint256 newGlobalCollateralRatio) public onlyOwner {
        globalCollateralRatio = newGlobalCollateralRatio;
    }

    function setShareBondCeiling(uint256 newShareBondCeiling) public onlyOwner {
        shareBondCeiling = newShareBondCeiling;
    }

    function setBuybackBonus(uint256 newBuybackBonus) public onlyOwner {
        buybackBonus = newBuybackBonus;
    }
    
    function setKbtToKunImmediately() public onlyOwner {
        kbtToKunImmediately = !kbtToKunImmediately;
    }

    function _withdrawTo(address token, address payable to, uint256 amount) internal {
        if(token == NATIVE_TOKEN_ADDRESS) {
            IWrappedNativeToken(wrappedNativeToken).withdraw(amount);
            to.transfer(amount);
        } else {
           IERC20(token).transfer(to, amount);
        }
    }

    function _depositFrom(address token, address from, uint256 amount) internal {
        if(token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == amount, "msg.value != amount");
            IWrappedNativeToken(wrappedNativeToken).deposit{value: amount}();
        } else {
           IERC20(token).transferFrom(from, address(this), amount);
        }
    }

    receive() external payable {
        // require(msg.sender == wrappedNativeToken, "Only WXXX can send ether");
    }   
}