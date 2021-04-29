/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.6.11;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
contract ReentrancyGuard {
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

    constructor () internal {
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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
    
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

/**
 * Accounting:
 *      - the smart contract maintains a ledger of token balances which changes upon actions affecting 
 *          this smart contract's token balance.
 * 
 *      - it allows owner to withdraw any extra amount of any tokens that have not been recorded, 
 *          i.e, - any tokens that are accidentally transferred to this smart contract.
 * 
 *      - care must be taken in auditing that `claimExtraTokens` function does not allow withdrawals of 
 *          any tokens in this smart contract in more amounts than necessary. In simple terms, admin can 
 *          only transfer out tokens that are accidentally sent to this smart contract. Nothing more nothing less.
 */
contract Vault is Ownable, ReentrancyGuard {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;
    
    //==================== Contract Variables =======================
    // Contract variables must be changed before live deployment
    
    uint public constant LOCKUP_DURATION = 3 days;
    uint public constant FEE_PERCENT_X_100 = 30;
    uint public constant FEE_PERCENT_TO_BUYBACK_X_100 = 2500;
    
    uint public constant REWARD_INTERVAL = 365 days;
    uint public constant ADMIN_CAN_CLAIM_AFTER = 395 days;
    uint public constant REWARD_RETURN_PERCENT_X_100 = 250;
    
    // ETH fee equivalent predefined gas price
    uint public constant MIN_ETH_FEE_IN_WEI = 40000 * 1 * 10**9;
    
    address public constant TRUSTED_DEPOSIT_TOKEN_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public constant TRUSTED_CTOKEN_ADDRESS = 0xccF4429DB6322D5C611ee964527D42E5d685DD6a;
    address public constant TRUSTED_PLATFORM_TOKEN_ADDRESS = 0x961C8c0B1aaD0c0b10a51FeF6a867E3091BCef17;
    
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    //================= End Contract Variables ======================
    
    uint public constant ONE_HUNDRED_X_100 = 10000;
    uint public immutable contractStartTime;
    
    constructor() public {
        contractStartTime = block.timestamp;
    }
    
    IUniswapV2Router public constant uniswapRouterV2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    modifier noContractsAllowed() {
        require(tx.origin == msg.sender, "No Contracts Allowed!");
        _;
    }
    
    // ------------------- event definitions -------------------
    
    event Deposit(address indexed account, uint amount);
    event Withdraw(address indexed account, uint amount);
    
    event EtherRewardDisbursed(uint amount);
    event TokenRewardDisbursed(uint amount);
    
    event PlatformTokenRewardClaimed(address indexed account, uint amount);
    event CompoundRewardClaimed(address indexed account, uint amount);
    event EtherRewardClaimed(address indexed account, uint amount);
    event TokenRewardClaimed(address indexed account, uint amount);
    
    event PlatformTokenAdded(uint amount);
    
    // ----------------- end event definitions -----------------
    
    EnumerableSet.AddressSet private holders;
    
    // view functon to get number of stakers
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    // token contract address => token balance of this contract
    mapping (address => uint) public tokenBalances;
    
    // user wallet => balance
    mapping (address => uint) public cTokenBalance;
    mapping (address => uint) public depositTokenBalance;
    
    mapping (address => uint) public totalTokensDepositedByUser;
    mapping (address => uint) public totalTokensWithdrawnByUser;
    
    mapping (address => uint) public totalEarnedCompoundDivs;
    mapping (address => uint) public totalEarnedEthDivs;
    mapping (address => uint) public totalEarnedTokenDivs;
    mapping (address => uint) public totalEarnedPlatformTokenDivs;
    
    mapping (address => uint) public depositTime;
    mapping (address => uint) public lastClaimedTime;
    
    uint public totalCTokens;
    uint public totalDepositedTokens;
    
    // -----------------
    
    uint public constant POINT_MULTIPLIER = 1e18;
    
    mapping (address => uint) public lastTokenDivPoints;
    mapping (address => uint) public tokenDivsBalance;
    uint public totalTokenDivPoints;
    
    mapping (address => uint) public lastEthDivPoints;
    mapping (address => uint) public ethDivsBalance;
    uint public totalEthDivPoints;
    
    mapping (address => uint) public platformTokenDivsBalance;
    
    uint public totalEthDisbursed;
    uint public totalTokensDisbursed;
   
    
    function tokenDivsOwing(address account) public view returns (uint) {
        uint newDivPoints = totalTokenDivPoints.sub(lastTokenDivPoints[account]);
        return depositTokenBalance[account].mul(newDivPoints).div(POINT_MULTIPLIER);
    }
    function ethDivsOwing(address account) public view returns (uint) {
        uint newDivPoints = totalEthDivPoints.sub(lastEthDivPoints[account]);
        return depositTokenBalance[account].mul(newDivPoints).div(POINT_MULTIPLIER);
    }
    
    function distributeEthDivs(uint amount) private {
        if (totalDepositedTokens == 0) return;
        totalEthDivPoints = totalEthDivPoints.add(amount.mul(POINT_MULTIPLIER).div(totalDepositedTokens));
        totalEthDisbursed = totalEthDisbursed.add(amount);
        increaseTokenBalance(address(0), amount);
        emit EtherRewardDisbursed(amount);
    }
    function distributeTokenDivs(uint amount) private {
        if (totalDepositedTokens == 0) return;
        totalTokenDivPoints = totalTokenDivPoints.add(amount.mul(POINT_MULTIPLIER).div(totalDepositedTokens));
        totalTokensDisbursed = totalTokensDisbursed.add(amount);
        increaseTokenBalance(TRUSTED_DEPOSIT_TOKEN_ADDRESS, amount);
        emit TokenRewardDisbursed(amount);
    }
    
    
    // -----------------
    
    // view function to get depositors list
    function getDepositorsList(uint startIndex, uint endIndex)
        public
        view
        returns (address[] memory stakers,
            uint[] memory stakingTimestamps,
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);

        uint length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);

        for (uint i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders.at(i);
            uint listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositTokenBalance[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }

    function updateAccount(address account) private {
        // update user account here
        uint tokensOwing = tokenDivsOwing(account);
        lastTokenDivPoints[account] = totalTokenDivPoints;
        if (tokensOwing > 0) {
            tokenDivsBalance[account] = tokenDivsBalance[account].add(tokensOwing);
        }
        
        uint weiOwing = ethDivsOwing(account);
        lastEthDivPoints[account] = totalEthDivPoints;
        if (weiOwing > 0) {
            ethDivsBalance[account] = ethDivsBalance[account].add(weiOwing);
        }
        
        uint platformTokensOwing = platformTokenDivsOwing(account);
        if (platformTokensOwing > 0) {
            platformTokenDivsBalance[account] = platformTokenDivsBalance[account].add(platformTokensOwing);
        }
        
        lastClaimedTime[account] = block.timestamp;
    }
    
    function platformTokenDivsOwing(address account) public view returns (uint) {
        if (!holders.contains(account)) return 0;
        if (depositTokenBalance[account] == 0) return 0;
        
        uint timeDiff;
        uint stakingEndTime = contractStartTime.add(REWARD_INTERVAL);
        uint _now = block.timestamp;
        if (_now > stakingEndTime) {
            _now = stakingEndTime;
        }
        
        if (lastClaimedTime[account] >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastClaimedTime[account]);
        }
        
        uint pendingDivs = depositTokenBalance[account]
                                .mul(REWARD_RETURN_PERCENT_X_100)
                                .mul(timeDiff)
                                .div(REWARD_INTERVAL)
                                .div(ONE_HUNDRED_X_100);
        return pendingDivs;
    }
    
    function getEstimatedCompoundDivsOwing(address account) public view returns (uint) {
        uint convertedBalance = getConvertedBalance(cTokenBalance[account]);
        uint depositedBalance = depositTokenBalance[account];
        return (convertedBalance > depositedBalance ? convertedBalance.sub(depositedBalance) : 0);
    }
    
    function getConvertedBalance(uint _cTokenBalance) public view returns (uint) {
        uint exchangeRateStored = getExchangeRateStored();
        uint convertedBalance = _cTokenBalance.mul(exchangeRateStored).div(10**18);
        return convertedBalance;
    }
    
    function _claimEthDivs() private {
        updateAccount(msg.sender);
        uint amount = ethDivsBalance[msg.sender];
        ethDivsBalance[msg.sender] = 0;
        if (amount == 0) return;
        decreaseTokenBalance(address(0), amount);
        msg.sender.transfer(amount);
        totalEarnedEthDivs[msg.sender] = totalEarnedEthDivs[msg.sender].add(amount);
        
        emit EtherRewardClaimed(msg.sender, amount);
    }
    function _claimTokenDivs() private {
        updateAccount(msg.sender);
        uint amount = tokenDivsBalance[msg.sender];
        tokenDivsBalance[msg.sender] = 0;
        if (amount == 0) return;
        decreaseTokenBalance(TRUSTED_DEPOSIT_TOKEN_ADDRESS, amount);
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeTransfer(msg.sender, amount);
        totalEarnedTokenDivs[msg.sender] = totalEarnedTokenDivs[msg.sender].add(amount);
        
        emit TokenRewardClaimed(msg.sender, amount);
    }
    function _claimCompoundDivs() private {
        updateAccount(msg.sender);
        uint exchangeRateCurrent = getExchangeRateCurrent();
        
        uint convertedBalance = cTokenBalance[msg.sender].mul(exchangeRateCurrent).div(10**18);
        uint depositedBalance = depositTokenBalance[msg.sender];
        
        uint amount = convertedBalance > depositedBalance ? convertedBalance.sub(depositedBalance) : 0;
        
        if (amount == 0) return;
        
        uint oldCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint oldDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        require(CErc20(TRUSTED_CTOKEN_ADDRESS).redeemUnderlying(amount) == 0, "redeemUnderlying failed!");
        uint newCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint newDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        
        uint depositTokenReceived = newDepositTokenBalance.sub(oldDepositTokenBalance);
        uint cTokenRedeemed = oldCTokenBalance.sub(newCTokenBalance);
        
        require(cTokenRedeemed <= cTokenBalance[msg.sender], "redeem exceeds balance!");
        cTokenBalance[msg.sender] = cTokenBalance[msg.sender].sub(cTokenRedeemed);
        totalCTokens = totalCTokens.sub(cTokenRedeemed);
        decreaseTokenBalance(TRUSTED_CTOKEN_ADDRESS, cTokenRedeemed);
        
        totalTokensWithdrawnByUser[msg.sender] = totalTokensWithdrawnByUser[msg.sender].add(depositTokenReceived);
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeTransfer(msg.sender, depositTokenReceived);
        
        totalEarnedCompoundDivs[msg.sender] = totalEarnedCompoundDivs[msg.sender].add(depositTokenReceived);
        
        emit CompoundRewardClaimed(msg.sender, depositTokenReceived);
    }
    function _claimPlatformTokenDivs(uint _amountOutMin_platformTokens) private {
        updateAccount(msg.sender);
        uint amount = platformTokenDivsBalance[msg.sender];
        
        if (amount == 0) return;
        
        address[] memory path = new address[](3);
        path[0] = TRUSTED_DEPOSIT_TOKEN_ADDRESS;
        path[1] = uniswapRouterV2.WETH();
        path[2] = TRUSTED_PLATFORM_TOKEN_ADDRESS;
        
        uint estimatedAmountOut = uniswapRouterV2.getAmountsOut(amount, path)[2];
        require(estimatedAmountOut >= _amountOutMin_platformTokens, "_claimPlatformTokenDivs: slippage error!");
        
        if (IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).balanceOf(address(this)) < estimatedAmountOut) {
            return;
        }
        
        platformTokenDivsBalance[msg.sender] = 0;
        
        
        decreaseTokenBalance(TRUSTED_PLATFORM_TOKEN_ADDRESS, estimatedAmountOut);
        IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).safeTransfer(msg.sender, estimatedAmountOut);
        totalEarnedPlatformTokenDivs[msg.sender] = totalEarnedPlatformTokenDivs[msg.sender].add(estimatedAmountOut);
        
        emit PlatformTokenRewardClaimed(msg.sender, estimatedAmountOut);
    }
    
    function claimEthDivs() external noContractsAllowed nonReentrant {
        _claimEthDivs();
    }
    function claimTokenDivs() external noContractsAllowed nonReentrant {
        _claimTokenDivs();
    }
    function claimCompoundDivs() external noContractsAllowed nonReentrant {
        _claimCompoundDivs();
    }
    function claimPlatformTokenDivs(uint _amountOutMin_platformTokens) external noContractsAllowed nonReentrant {
        _claimPlatformTokenDivs(_amountOutMin_platformTokens);
    }
    
    function claim(uint _amountOutMin_platformTokens) external noContractsAllowed nonReentrant {
        _claimEthDivs();
        _claimTokenDivs();
        _claimCompoundDivs();
        _claimPlatformTokenDivs(_amountOutMin_platformTokens);
    }
    
    function getExchangeRateCurrent() public returns (uint) {
        uint exchangeRateCurrent = CErc20(TRUSTED_CTOKEN_ADDRESS).exchangeRateCurrent();
        return exchangeRateCurrent;
    }
    
    function getExchangeRateStored() public view returns (uint) {
        uint exchangeRateStored = CErc20(TRUSTED_CTOKEN_ADDRESS).exchangeRateStored();
        return exchangeRateStored;
    }
    
    function deposit(uint amount, uint _amountOutMin_ethFeeBuyBack, uint deadline) external noContractsAllowed nonReentrant payable {
        require(amount > 0, "invalid amount!");
        
        updateAccount(msg.sender);
        
        // increment token balance!
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), amount);
        

        totalTokensDepositedByUser[msg.sender] = totalTokensDepositedByUser[msg.sender].add(amount);
        
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeApprove(TRUSTED_CTOKEN_ADDRESS, 0);
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeApprove(TRUSTED_CTOKEN_ADDRESS, amount);
        
        uint oldCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        require(CErc20(TRUSTED_CTOKEN_ADDRESS).mint(amount) == 0, "mint failed!");
        uint newCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint cTokenReceived = newCTokenBalance.sub(oldCTokenBalance);
        
        cTokenBalance[msg.sender] = cTokenBalance[msg.sender].add(cTokenReceived);
        totalCTokens = totalCTokens.add(cTokenReceived);    
        increaseTokenBalance(TRUSTED_CTOKEN_ADDRESS, cTokenReceived);
        
        depositTokenBalance[msg.sender] = depositTokenBalance[msg.sender].add(amount);
        totalDepositedTokens = totalDepositedTokens.add(amount);
        
        handleEthFee(msg.value, _amountOutMin_ethFeeBuyBack, deadline);
        
        holders.add(msg.sender);
        depositTime[msg.sender] = block.timestamp;
        
        emit Deposit(msg.sender, amount);
    }
    function withdraw(uint amount, uint _amountOutMin_ethFeeBuyBack, uint _amountOutMin_tokenFeeBuyBack, uint deadline) external noContractsAllowed nonReentrant payable {
        require(amount > 0, "invalid amount!");
        require(amount <= depositTokenBalance[msg.sender], "Cannot withdraw more than deposited!");
        require(block.timestamp.sub(depositTime[msg.sender]) > LOCKUP_DURATION, "You recently deposited, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        depositTokenBalance[msg.sender] = depositTokenBalance[msg.sender].sub(amount);
        totalDepositedTokens = totalDepositedTokens.sub(amount);
        
        uint oldCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint oldDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        require(CErc20(TRUSTED_CTOKEN_ADDRESS).redeemUnderlying(amount) == 0, "redeemUnderlying failed!");
        uint newCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint newDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        
        uint depositTokenReceived = newDepositTokenBalance.sub(oldDepositTokenBalance);
        uint cTokenRedeemed = oldCTokenBalance.sub(newCTokenBalance);
        
        require(cTokenRedeemed <= cTokenBalance[msg.sender], "redeem exceeds balance!");
        cTokenBalance[msg.sender] = cTokenBalance[msg.sender].sub(cTokenRedeemed);
        totalCTokens = totalCTokens.sub(cTokenRedeemed);
        decreaseTokenBalance(TRUSTED_CTOKEN_ADDRESS, cTokenRedeemed);
        
        totalTokensWithdrawnByUser[msg.sender] = totalTokensWithdrawnByUser[msg.sender].add(depositTokenReceived);
        
        uint feeAmount = depositTokenReceived.mul(FEE_PERCENT_X_100).div(ONE_HUNDRED_X_100);
        uint depositTokenReceivedAfterFee = depositTokenReceived.sub(feeAmount);
        
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeTransfer(msg.sender, depositTokenReceivedAfterFee);
        
        handleFee(feeAmount, _amountOutMin_tokenFeeBuyBack, deadline);
        handleEthFee(msg.value, _amountOutMin_ethFeeBuyBack, deadline);
        
        if (depositTokenBalance[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
        
        emit Withdraw(msg.sender, depositTokenReceived);
    }
    
    // emergency withdraw without interacting with uniswap
    function emergencyWithdraw(uint amount) external noContractsAllowed nonReentrant payable {
        require(amount > 0, "invalid amount!");
        require(amount <= depositTokenBalance[msg.sender], "Cannot withdraw more than deposited!");
        require(block.timestamp.sub(depositTime[msg.sender]) > LOCKUP_DURATION, "You recently deposited, please wait before withdrawing.");
        
        updateAccount(msg.sender);
        
        depositTokenBalance[msg.sender] = depositTokenBalance[msg.sender].sub(amount);
        totalDepositedTokens = totalDepositedTokens.sub(amount);
        
        uint oldCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint oldDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        require(CErc20(TRUSTED_CTOKEN_ADDRESS).redeemUnderlying(amount) == 0, "redeemUnderlying failed!");
        uint newCTokenBalance = IERC20(TRUSTED_CTOKEN_ADDRESS).balanceOf(address(this));
        uint newDepositTokenBalance = IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).balanceOf(address(this));
        
        uint depositTokenReceived = newDepositTokenBalance.sub(oldDepositTokenBalance);
        uint cTokenRedeemed = oldCTokenBalance.sub(newCTokenBalance);
        
        require(cTokenRedeemed <= cTokenBalance[msg.sender], "redeem exceeds balance!");
        cTokenBalance[msg.sender] = cTokenBalance[msg.sender].sub(cTokenRedeemed);
        totalCTokens = totalCTokens.sub(cTokenRedeemed);
        decreaseTokenBalance(TRUSTED_CTOKEN_ADDRESS, cTokenRedeemed);
        
        totalTokensWithdrawnByUser[msg.sender] = totalTokensWithdrawnByUser[msg.sender].add(depositTokenReceived);
        
        uint feeAmount = depositTokenReceived.mul(FEE_PERCENT_X_100).div(ONE_HUNDRED_X_100);
        uint depositTokenReceivedAfterFee = depositTokenReceived.sub(feeAmount);
        
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeTransfer(msg.sender, depositTokenReceivedAfterFee);
        
        // no uniswap interaction
        // handleFee(feeAmount, _amountOutMin_tokenFeeBuyBack, deadline);
        // handleEthFee(msg.value, _amountOutMin_ethFeeBuyBack, deadline);
        
        if (depositTokenBalance[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
        
        emit Withdraw(msg.sender, depositTokenReceived);
    }
    
    function handleFee(uint feeAmount, uint _amountOutMin_tokenFeeBuyBack, uint deadline) private {
        uint buyBackFeeAmount = feeAmount.mul(FEE_PERCENT_TO_BUYBACK_X_100).div(ONE_HUNDRED_X_100);
        uint remainingFeeAmount = feeAmount.sub(buyBackFeeAmount);
        
        // handle distribution
        distributeTokenDivs(remainingFeeAmount);
        
        
        // handle buyback
        // --- swap token to platform token here! ----
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeApprove(address(uniswapRouterV2), 0);
        IERC20(TRUSTED_DEPOSIT_TOKEN_ADDRESS).safeApprove(address(uniswapRouterV2), buyBackFeeAmount);
        
        uint oldPlatformTokenBalance = IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).balanceOf(address(this));
        address[] memory path = new address[](3);
        path[0] = TRUSTED_DEPOSIT_TOKEN_ADDRESS;
        path[1] = uniswapRouterV2.WETH();
        path[2] = TRUSTED_PLATFORM_TOKEN_ADDRESS;
        
        uniswapRouterV2.swapExactTokensForTokens(buyBackFeeAmount, _amountOutMin_tokenFeeBuyBack, path, address(this), deadline);
        uint newPlatformTokenBalance = IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).balanceOf(address(this));
        uint platformTokensReceived = newPlatformTokenBalance.sub(oldPlatformTokenBalance);
        IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).safeTransfer(BURN_ADDRESS, platformTokensReceived);
        // ---- end swap token to plaform tokens -----
    }
    
    function handleEthFee(uint feeAmount, uint _amountOutMin_ethFeeBuyBack, uint deadline) private {
        require(feeAmount >= MIN_ETH_FEE_IN_WEI, "Insufficient ETH Fee!");
        uint buyBackFeeAmount = feeAmount.mul(FEE_PERCENT_TO_BUYBACK_X_100).div(ONE_HUNDRED_X_100);
        uint remainingFeeAmount = feeAmount.sub(buyBackFeeAmount);
        
        // handle distribution
        distributeEthDivs(remainingFeeAmount);
        
        
        // handle buyback
        
        // --- swap eth to platform token here! ----
        uint oldPlatformTokenBalance = IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapRouterV2.WETH();
        path[1] = TRUSTED_PLATFORM_TOKEN_ADDRESS;
        
        uniswapRouterV2.swapExactETHForTokens{value: buyBackFeeAmount}(_amountOutMin_ethFeeBuyBack, path, address(this), deadline);
        uint newPlatformTokenBalance = IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).balanceOf(address(this));
        uint platformTokensReceived = newPlatformTokenBalance.sub(oldPlatformTokenBalance);
        IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).safeTransfer(BURN_ADDRESS, platformTokensReceived);
        // ---- end swap eth to plaform tokens -----
    }
    
    receive () external payable {
        // receive eth do nothing
    }
    
    function increaseTokenBalance(address token, uint amount) private {
        tokenBalances[token] = tokenBalances[token].add(amount);
    }
    function decreaseTokenBalance(address token, uint amount) private {
        tokenBalances[token] = tokenBalances[token].sub(amount);
    }
    
    function addPlatformTokenBalance(uint amount) external nonReentrant onlyOwner {
        increaseTokenBalance(TRUSTED_PLATFORM_TOKEN_ADDRESS, amount);
        IERC20(TRUSTED_PLATFORM_TOKEN_ADDRESS).safeTransferFrom(msg.sender, address(this), amount);
        
        emit PlatformTokenAdded(amount);
    }
    
    function claimExtraTokens(address token) external nonReentrant onlyOwner {
        if (token == address(0)) {
            uint ethDiff = address(this).balance.sub(tokenBalances[token]);
            msg.sender.transfer(ethDiff);
            return;
        }
        uint diff = IERC20(token).balanceOf(address(this)).sub(tokenBalances[token]);
        IERC20(token).safeTransfer(msg.sender, diff);
    }
    
    function claimAnyToken(address token, uint amount) external onlyOwner {
        require(now > contractStartTime.add(ADMIN_CAN_CLAIM_AFTER), "Contract not expired yet!");
        if (token == address(0)) {
            msg.sender.transfer(amount);
            return;
        }
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}