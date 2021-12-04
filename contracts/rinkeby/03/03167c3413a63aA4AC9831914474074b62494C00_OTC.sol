pragma solidity ^0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

contract Ownable {
    address public owner;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }
  
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
  
interface IOracle {
    function update() external;
    function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

contract OTC is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct AskOrder {
        uint id;
        bool active;
        address owner;
        uint anchorAmount;
        uint maxBuyPrice;
        uint lastOrderId; // pointer to the last id in price list (used to retreive lastAskOrderIdPerPrice when an order is filled)
        uint nextOrderId; // pointer to the next id in the price list
    }
    mapping (uint => AskOrder) public AskOrderBook;
    uint public topAskOrder = 0; // id of the next ask order to be filled (through this is the order with the highest max buy price)
    uint public newAskId = 0;

    // front end use
    EnumerableSet.UintSet private maxPrices; // enumerable set of all max buy prices (then we can refer to lastAskOrderIdPerPrice to the the last order for a particular price)
    mapping (uint => uint) public lastAskOrderIdPerPrice; // ask order id (in AskOrderBook) per price (this return only the most recently added order to this particular price) /!\ note : price here is max buy price

    struct BidOrder {
        uint id;
        bool active;
        address owner;
        uint paprAmount;
        uint minSellPrice;
        uint lastOrderId; // pointer to the last id in price list (used to retreive lastAskOrderIdPerPrice when an order is filled)
        uint nextOrderId; // pointer to the next id in the price list
    }
    mapping (uint => BidOrder) public BidOrderBook;
    uint public topBidOrder = 0; // id of the next bid order to be filled (through this is the order with the lowest min sell price)
    uint public newBidId = 0;

    // front end use
    EnumerableSet.UintSet private minPrices; // enumerable set of all min sell prices (then we can refer to lastBidOrderIdPerPrice to the the last order for a particular price)
    mapping (uint => uint) public lastBidOrderIdPerPrice; // bid order id (in BidOrderBook) per price (this return only the most recently added order to this particular price) /!\ note : price here is min sell price

    // token address
    address public papr; // define the papr address
    address public anchor; // define the anchor address (the trading token in exchange for the papr)

    // informational use
    uint public averageAskPrice; // average price of the buy orders on the OTC
    uint public averageBidPrice; // average price of the sell orders on the OTC
    uint private totalAskPrice; // used to update averageAskPrice
    uint private totalBidPrice; // used to update averageBidPrice
    uint private totalAsk; // used to update averageAskPrice
    uint private totalBid; // used to update averageBidPrice

    constructor (address _papr, address _anchor) {
        papr = _papr;
        anchor = _anchor;
    }

    // return the entire prices list for ask (_side = 0) or bid (_side = 1) /!\ note : DONT USE THIS FUNCTION FROM A CONTRACT
    function getPricesList(uint8 _side) public view returns (uint256[] memory _priceList) {
        if (_side == 0) {
            _priceList = maxPrices.values();
        } else if (_side == 1) {
            _priceList = minPrices.values();
        }
    }

    // check if an id with a price is valid (is the correct id for this order price)
    modifier lastIdValid(uint8 _side, uint _orderExtremePrice, uint _lastId) {
        if (_side == 0) {
            uint maxBuyPrice = AskOrderBook[_lastId].maxBuyPrice;
            require(maxBuyPrice >= _orderExtremePrice || _lastId == 0, "id not good");
            uint nextOrderId = AskOrderBook[_lastId].nextOrderId;
            require(AskOrderBook[nextOrderId].maxBuyPrice < _orderExtremePrice, "id not good");
            _;
        } else if (_side == 1) {
            uint minSellPrice = BidOrderBook[_lastId].minSellPrice;
            require(minSellPrice <= _orderExtremePrice, "id not good");
            uint nextOrderId = BidOrderBook[_lastId].nextOrderId;
            require(BidOrderBook[nextOrderId].minSellPrice > _orderExtremePrice || _lastId == 0, "id not good");
            _;
        } else {
            revert("order side must be 0 or 1");
        }
    }

    // check if an extremum price (max buy price or min sell price) is in touch with the opposite side top order
    function checkBoxPrice(uint8 _side, uint _orderExtremePrice) public view returns (bool trigger) {
        if (_side == 0) {
            trigger = BidOrderBook[topBidOrder].minSellPrice <= _orderExtremePrice;
        } else if (_side == 1) {
            trigger = AskOrderBook[topAskOrder].maxBuyPrice >= _orderExtremePrice;
        }
    }

    function updateAverageOrderPrice(uint8 _side, bool _add, uint _orderExtremumPrice) private returns (bool) {
        if (_side == 0) {
            if (_add) {
                totalAskPrice += _orderExtremumPrice;
                totalAsk += 1;
            } else {
                totalAskPrice -= _orderExtremumPrice;
                totalAsk -= 1;       
            }
            if (totalAsk == 0) {
                averageAskPrice = 0;
                return true;
            }
            averageAskPrice = totalAskPrice.div(totalAsk); // update the final average buy price (max buy price)
            return true;
        } else {
            if (_add) {
                totalBidPrice += _orderExtremumPrice;
                totalBid += 1;
            } else {
                totalBidPrice -= _orderExtremumPrice;
                totalBid -= 1;       
            }
            if (totalBid == 0) {
                averageBidPrice = 0;
                return true;
            }
            averageBidPrice = totalBidPrice.div(totalBid); // update the final average sell price (min sell price)
            return true;
        }
    }

    /**
    *   create a new buy order
    *   @notice _anchorAmount is the amount of base token the user want to trade for papr 
    *   @notice _lastId is the order id that is just before the new order created in price list
    *   @notice _orderIteration is the number of sell order this order will iterate until order completion
    */
    function createBuyOrder(uint _anchorAmount, uint _maxBuyPrice, uint _lastId, uint _orderIteration) external lastIdValid(0, _maxBuyPrice, _lastId) returns (bool) {
        require(_orderIteration > 0);
        require(_maxBuyPrice > 0);
        if (_lastId == 0) { // if the user set the last order id to 0 (undefined order), its only valid if there is no possible predecessor (no topAskOrder) or it's the new topAskOrder
            require(topAskOrder == 0 || _maxBuyPrice > AskOrderBook[topAskOrder].maxBuyPrice, "cannot set last id order to 0");
            topAskOrder = newAskId + 1;
        }
        IERC20(anchor).safeTransferFrom(msg.sender, address(this), _anchorAmount);

        updateAverageOrderPrice(0, true, _maxBuyPrice);

        // orders id updates
        newAskId++;

        // create the new buy order 
        AskOrderBook[newAskId] = AskOrder(newAskId, true, msg.sender, _anchorAmount, _maxBuyPrice, _lastId, AskOrderBook[_lastId].nextOrderId); // (AskOrderBook[_lastId].nextOrderId, note) : set the next order id of the new order to the next order id of the last id order (pfiouuuuu ..)
        AskOrderBook[AskOrderBook[_lastId].nextOrderId].lastOrderId = newAskId; // set the last order id of the successor order to this new buy order id
        AskOrderBook[_lastId].nextOrderId = newAskId; // set the last order id of the predecessor order to this new buy order id

        // updates for front end use
        maxPrices.add(_maxBuyPrice);
        lastAskOrderIdPerPrice[_maxBuyPrice] = newAskId;

        if (_maxBuyPrice > AskOrderBook[topAskOrder].maxBuyPrice) { // if the max buy price is the hightest possible, the order can possibly be directly filled
            if (checkBoxPrice(0, _maxBuyPrice)) { // if there is a sell order with its min sell price under the max buy price, an exchange can proceed
                for (uint i = 0; i < _orderIteration; i++) { // for _orderIteration, continue to execute transactions until the buy amount is 0 or there are no more sell orders in touch with this buy order price
                    if (topBidOrder != 0) {
                        executeTransaction(newAskId, topBidOrder);
                        if (AskOrderBook[newAskId].anchorAmount == 0) { // if this buy order is entierly filled (anchorAmount = 0), we can exit the sell order search
                            updateAverageOrderPrice(0, false, _maxBuyPrice);
                            break;
                        }
                    }
                }
            }
        }

        return true;
    }

    /**
    *   create a new sell order
    *   @notice _anchorAmount is the amount of base token the user want to trade for papr 
    *   @notice _lastId is the order id that is just before the new order created in price list
    *   @notice _orderIteration is the number of sell order this order will iterate until order completion
    */
    function createSellOrder(uint _paprAmount, uint _minSellPrice, uint _lastId, uint _orderIteration) external lastIdValid(1, _minSellPrice, _lastId) returns (bool) {
        require(_orderIteration > 0);
        require(_minSellPrice > 0);
        uint topMinSellPrice = BidOrderBook[topBidOrder].minSellPrice; // save the top min sell price before be change it
        if (_lastId == 0) { // if the user set the last order id to 0 (undefined order), its only valid if there is no possible predecessor (no topBidOrder) or it's the new topBidOrder
            require(topBidOrder == 0 || _minSellPrice < BidOrderBook[topBidOrder].minSellPrice, "cannot set last id order to 0");
            topBidOrder = newBidId + 1;
        }
        IERC20(papr).safeTransferFrom(msg.sender, address(this), _paprAmount);

        updateAverageOrderPrice(1, true, _minSellPrice);

        // orders id updates
        newBidId++;

        // create the new buy order 
        BidOrderBook[newBidId] = BidOrder(newBidId, true, msg.sender, _paprAmount, _minSellPrice, _lastId, BidOrderBook[_lastId].nextOrderId); // (BidOrderBook[_lastId].nextOrderId, note) : set the next order id of the new order to the next order id of the last id order (pfiouuuuu ..)
        BidOrderBook[BidOrderBook[_lastId].nextOrderId].lastOrderId = newBidId; // set the last order id of the successor order to this new buy order id
        BidOrderBook[_lastId].nextOrderId = newBidId; // set the last order id of the predecessor order to this new buy order id

        // updates for front end use
        minPrices.add(_minSellPrice);
        lastBidOrderIdPerPrice[_minSellPrice] = newBidId;

        if (_minSellPrice < topMinSellPrice || topMinSellPrice == 0) { // if the max buy price is the hightest possible, the order can possibly be directly filled
            if (checkBoxPrice(1, _minSellPrice)) { // if there is a sell order with its min sell price under the max buy price, an exchange can proceed
                for (uint i = 0; i < _orderIteration; i++) { // for _orderIteration, continue to execute transactions until the buy amount is 0 or there are no more sell orders in touch with this buy order price
                    if (topAskOrder != 0) {
                        executeTransaction(topAskOrder, newBidId);
                        if (BidOrderBook[newBidId].paprAmount == 0) { // if this buy order is entierly filled (anchorAmount = 0), we can exit the sell order search
                            updateAverageOrderPrice(1, false, _minSellPrice);
                            break;
                        }
                    }
                }
            }
        }

        return true;
    }

    function removeOrder(uint8 _side, uint _orderId) private {
        if (_side == 0) {
            AskOrder storage order = AskOrderBook[_orderId];

            order.active = false;

            if (AskOrderBook[order.lastOrderId].maxBuyPrice == order.maxBuyPrice) { // if this buy order had the same price than its predecessor order, set lastBidOrderIdPerPrice to its predecessor
                lastBidOrderIdPerPrice[order.maxBuyPrice] = order.lastOrderId;
            } else { // else, we remove this price from the all available ask prices
                maxPrices.remove(order.maxBuyPrice);
            }

            if (topAskOrder == _orderId) { // if this order was the top order, we set the next order to the top order
                topAskOrder = order.nextOrderId;
            }

            // undone links to other orders
            AskOrderBook[order.lastOrderId].nextOrderId = order.nextOrderId; // set this buy order's next order id into the last order id (we remove it from the chain of orders)
            AskOrderBook[order.nextOrderId].lastOrderId = order.lastOrderId; // [..] do the same thing for the successor order
            // reset sensitive value to avoid errors
            order.anchorAmount = 0;
            order.lastOrderId = 0;
            order.nextOrderId = 0;
        } else {
            BidOrder storage order = BidOrderBook[_orderId];

            order.active = false;

            if (BidOrderBook[order.lastOrderId].minSellPrice == order.minSellPrice) { // if this sell order had the same price than its predecessor order, set lastBidOrderIdPerPrice to its predecessor
                lastBidOrderIdPerPrice[order.minSellPrice] = order.lastOrderId;
            } else { // else, we remove this price from the all available bid prices
                minPrices.remove(order.minSellPrice);
            }

            if (topBidOrder == _orderId) { // if this order was the top order, we set the next order to the top order
                topBidOrder = order.nextOrderId;
            }

            // undone links to other orders
            BidOrderBook[order.lastOrderId].nextOrderId = order.nextOrderId; // set this sell order's next order id into the last order id (we remove it from the chain of orders)
            BidOrderBook[order.nextOrderId].lastOrderId = order.lastOrderId; // [..] do the same thing for the successor order
            // reset sensitive value to avoid errors
            order.paprAmount = 0;
            order.lastOrderId = 0;
            order.nextOrderId = 0;
        }
    }

    // cancel an active buy (_side = 0) or sell (_side = 1) order
    function cancelOrder(uint8 _side, uint _orderId) external {
        require(_side <= 1);
        if (_side == 0) {
            require(AskOrderBook[_orderId].owner == msg.sender);
            require(AskOrderBook[_orderId].anchorAmount > 0);

            removeOrder(0, _orderId);
        } 
        else {
            require(BidOrderBook[_orderId].owner == msg.sender);
            require(BidOrderBook[_orderId].paprAmount > 0);

            removeOrder(1, _orderId);
        }
    }

    function executeTransaction(uint _buyOrderId, uint _sellOrderId) private {
        AskOrder storage buyOrder = AskOrderBook[_buyOrderId];
        BidOrder storage sellOrder = BidOrderBook[_sellOrderId];
        uint transactionPrice = buyOrder.maxBuyPrice.add(sellOrder.minSellPrice).div(2); // get the average price between the min and the max prices wanted

        if (buyOrder.anchorAmount >= sellOrder.paprAmount.mul(transactionPrice)) { // if the buy order anchor token amount is more than the sell order amount (converted in anchor token)
            uint transactionAmount = sellOrder.paprAmount.mul(transactionPrice);

            IERC20(papr).safeTransfer(buyOrder.owner, sellOrder.paprAmount);
            IERC20(anchor).safeTransfer(sellOrder.owner, transactionAmount);

            removeOrder(1, _sellOrderId); // entierly remove the order filled
            buyOrder.anchorAmount = buyOrder.anchorAmount.sub(transactionAmount); // update the amount remaining after this execution

            if (buyOrder.anchorAmount == 0) { // if the buy order is entierly filled too
                removeOrder(0, _buyOrderId);
            }
        }
        else { // else, the sell order amount (converted in anchor token) is more than the buy order anchor token amount
            uint transactionAmount = buyOrder.anchorAmount.div(transactionPrice);

            IERC20(papr).safeTransfer(buyOrder.owner, transactionAmount);
            IERC20(anchor).safeTransfer(sellOrder.owner, buyOrder.anchorAmount);
            
            removeOrder(0, _buyOrderId); // entierly remove the order filled
            sellOrder.paprAmount = sellOrder.paprAmount.sub(transactionAmount); // update the amount remaining after this execution
        }
    }
}