/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/utils/Pausable.sol

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: contracts/lib/ERC20Lib.sol

library ERC20Lib {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant BASE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (isBase(token)) {
            address(uint160(to)).transfer(amount);
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isBase(token)) {
            require(from == msg.sender && msg.value >= amount, "Wrong useage of ETH.universalTransferFrom()");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isBase(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isBase(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(BASE_ADDRESS));
    }

    function notExist(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(-1));
    }
}

// File: contracts/BridgeChain.sol

contract BridgeChain is Ownable, Pausable{
  
  using SafeMath for uint256;
  using Address for address;
  using ERC20Lib for IERC20;
  // 费用 token
  address private constant feeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  // 超级管理员
  address private admin;
  // 管理员
  EnumerableSet.AddressSet private managers;
  // 设置结构体
  struct BridgeConfig {
    address token;
    uint256[] supportChains;
    uint256 fee;
    uint256 singleMin;
    uint256 singleMax;
    bool enable;
  }
  //增加提取手续费方法
  struct Fee {
    uint256 totalFee;
    uint256 currentFee;
  }
  // 资产统计
  struct Assets {
    uint256 totalRecharge;
    uint256 totalWithdraw;
  }
  // 跨链设置
  mapping(address => BridgeConfig) public configMapping;
  // 跨链用户->token->记录
  mapping(address => mapping(address => uint256)) public recordMapping;
  // 资产变动累计
  mapping(address => Assets) public assetsMapping;
  // 手续费累计
  mapping(address => Fee) public feeMapping;
  // 增加管理员
  event AddManager(address indexed operator, address indexed manager);
  // 更改提币权限
  event SetAdmin(address indexed operator, address indexed admin);
  // 增加设置
  event AddConfig(address indexed operator, address indexed token, uint256[] supportChains, uint256 fee, uint256 singleMin, uint256 singleMax);
  // 修改手续费
  event UpdateFee(address indexed operator, address indexed token, uint256 fee);
  // 修改限制
  event UpdateSingle(address indexed operator, address indexed token, uint256 singleMin, uint256 singleMax);
  // 修改支持
  event UpdateSupport(address indexed operator, address indexed token, uint256[] supportChains);
  // 启停设置
  event UpdateEnable(address indexed operator, address indexed token, bool enable);
  // 跨进日志
  event BridgeIn(address indexed operator, address indexed receiver, address indexed token, uint256 toChain, uint256 amount, uint256 fee);
  // 退回日志
  event BridgeBack(address indexed operator, address indexed receiver, address indexed token, uint256 amount, uint256 fee, string fromTxid);
  // 跨出日志
  event BridgeOut(address indexed operator, address indexed receiver, address indexed token, uint256 amount, uint256 fromChain, string fromTxid);
  // 充值日志
  event Recharge(address indexed operator, address indexed token, uint256 amount);
  // 提取日志
  event Withdraw(address indexed operator, address indexed token, uint256 amount);
  // 提取费用日志
  event WithdrawFee(address indexed operator, address indexed receiver, uint256 fee);
  // 检查管理员
  modifier onlyManager() {
    require(isManager(msg.sender), "BridgeChain: caller is not the manager");
    _;
  }
  // admin
  modifier onlyAdmin() {
    require(msg.sender == admin, "BridgeChain: caller is not the admin");
    _;
  }
  // 检测单比最大 单比最小
  modifier checkBridgeIn(address _token, uint256 _toChain, uint256 _amount) {
    BridgeConfig memory bridgeConfig = configMapping[_token];
    require(bridgeConfig.token != address(0), 'BridgeChain: token config does not exist');
    require(bridgeConfig.enable, 'BridgeChain: token config not enabled');
    require(isSupport(_token, _toChain), 'BridgeChain: target chain not supported');
    require(_amount >= bridgeConfig.singleMin, 'BridgeChain: less than single minimum quantity');
    require(_amount <= bridgeConfig.singleMax, 'BridgeChain: greater than the maximum quantity');
    _;
  }

  constructor () public {}

  // 入账
  function bridgeIn(address _receiver, address _token, uint256 _toChain, uint256 _amount) external payable whenNotPaused checkBridgeIn(_token, _toChain, _amount){
    BridgeConfig memory bridgeConfig = configMapping[_token];
    // 收取手续费
    IERC20(feeToken).universalTransferFrom(msg.sender, address(this), bridgeConfig.fee);
    Fee storage fee = feeMapping[_token];
    fee.totalFee = fee.totalFee.add(bridgeConfig.fee);
    fee.currentFee = fee.currentFee.add(bridgeConfig.fee);
    // 待跨链
    IERC20(_token).universalTransferFrom(msg.sender, address(this), _amount);
    // 累计
    uint256 record = recordMapping[msg.sender][_token];
    recordMapping[msg.sender][_token] = record.add(_amount);
    emit BridgeIn(msg.sender, _receiver, _token, _toChain, _amount, bridgeConfig.fee);
  }
  // 退回(_receiver 必须与入账时的相同)
  function bridgeBack(address _receiver, address _token, uint256 _amount, uint256 _fee, string calldata _fromTxid) external onlyManager{
    //退回手续费
    uint256 feeBalance = IERC20(feeToken).universalBalanceOf(address(this));
    require(feeBalance >= _fee, 'BridgeChain: greater than current balance');
    IERC20(feeToken).universalTransfer(_receiver, _fee);
    Fee storage fee = feeMapping[_token];
    fee.totalFee = fee.totalFee.sub(_fee);
    fee.currentFee = fee.currentFee.sub(_fee);
    // 退回资产
    uint256 balance = IERC20(_token).universalBalanceOf(address(this));
    require(balance >= _amount, 'BridgeChain: greater than current balance');
    IERC20(_token).universalTransfer(_receiver, _amount);
    // 更新累计
    uint256 record = recordMapping[_receiver][_token];
    require(record >= _amount, 'BridgeChain: greater than current record');
    recordMapping[_receiver][_token] = record.sub(_amount);
    emit BridgeBack(msg.sender, _receiver, _token, _amount, _fee, _fromTxid);
  }
  // 出账
  function bridgeOut(address _receiver, address _token, uint256 _amount, uint256 _fromChain, string memory _fromTxid) external onlyManager{
    uint256 balance = IERC20(_token).universalBalanceOf(address(this));
    require(balance >= _amount, 'BridgeChain: greater than current balance');
    IERC20(_token).universalTransfer(_receiver, _amount);
    emit BridgeOut(msg.sender, _receiver, _token, _amount, _fromChain, _fromTxid);
  }
  // 充值资产
  function recharge(address _token, uint256 _amount) external {
    IERC20(_token).universalTransferFrom(msg.sender, address(this), _amount);
    Assets storage assets = assetsMapping[_token];
    assets.totalRecharge = assets.totalRecharge.add(_amount);
    emit Recharge(msg.sender, _token, _amount);
  }
  // 提取资产
  function withdraw(address _receiver, address _token, uint256 _amount) external onlyAdmin {
    uint256 balance = IERC20(_token).universalBalanceOf(address(this));
    require(balance >= _amount, 'BridgeChain: greater than current balance');
    IERC20(_token).universalTransfer(_receiver, _amount);
    Assets storage assets = assetsMapping[_token];
    assets.totalWithdraw = assets.totalWithdraw.add(_amount);
    emit Withdraw(msg.sender, _token, _amount);
  }
  // 提取手续费
  function withdrawFee(address _receiver, uint256 _fee) external onlyManager{
    uint256 balance = IERC20(feeToken).universalBalanceOf(address(this));
    require(balance >= _fee, 'BridgeChain: greater than current balance');
    IERC20(feeToken).universalTransfer(_receiver, _fee);
    Fee storage fee = feeMapping[feeToken];
    fee.currentFee = fee.currentFee.sub(_fee);
    emit WithdrawFee(msg.sender, _receiver, _fee);
  }
  // 设置提币权限
  function setAdmin(address _admin) external onlyOwner returns (bool) {
    admin = _admin;
    emit SetAdmin(msg.sender, _admin);
    return true;
  }
  // 增加权限地址
  function addManager(address _manager) external onlyOwner returns (bool) {
    require(_manager != address(0), "BridgeChain: manager is the zero address");
    emit AddManager(msg.sender, _manager);
    return EnumerableSet.add(managers, _manager);
  }
  // 删除权限地址
  function delManager(address _manager) external onlyOwner returns (bool) {
    require(_manager != address(0), "BridgeChain: manager is the zero address");
    return EnumerableSet.remove(managers, _manager);
  }
  // 管理员数量
  function getManagerLength() public view returns (uint256) {
    return EnumerableSet.length(managers);
  }
  // 根据索引获取管理员
  function getManager(uint256 _index) external view returns (address){
    require(_index <= getManagerLength() - 1, "BridgeChain: index out of bounds");
    return EnumerableSet.at(managers, _index);
  }
  // 是否是管理员
  function isManager(address _manager) public view returns (bool) {
    return EnumerableSet.contains(managers, _manager);
  }
  // 增加设置
  function addConfig(address _token, uint256[] calldata _supportChains, uint256 _fee, uint256 _singleMin, uint256 _singleMax) external onlyOwner returns (bool) {
    BridgeConfig memory bridgeConfig = configMapping[_token];
    require(_token != address(0), "BridgeChain: token is the zero address");
    require(bridgeConfig.token == address(0), 'BridgeChain: token already exists');
    require(_supportChains.length > 0, 'BridgeChain: at least one chain is supported');
    require(_singleMax > _singleMin, 'BridgeChain: singleMax must be greater than singleMin');
    configMapping[_token] = BridgeConfig({
      token: _token,
      supportChains: _supportChains,
      fee: _fee,
      singleMin: _singleMin,
      singleMax: _singleMax,
      enable: true
    });
    emit AddConfig(msg.sender, _token, _supportChains, _fee, _singleMin, _singleMax);
    return true;
  }
  // 修改费用
  function updateFee(address _token, uint256 _fee) external onlyOwner returns (bool) {
    BridgeConfig storage bridgeConfig = configMapping[_token];
    require(bridgeConfig.token != address(0), 'BridgeChain: token does not exist');
    bridgeConfig.fee = _fee;
    emit UpdateFee(msg.sender, _token, _fee);
    return true;
  }
  // 修改支持
  function updateSupport(address _token, uint256[] calldata _supportChains) external onlyOwner returns (bool) {
    BridgeConfig storage bridgeConfig = configMapping[_token];
    require(bridgeConfig.token != address(0), 'BridgeChain: token does not exist');
    require(_supportChains.length > 0, 'BridgeChain: at least one chain is supported');
    bridgeConfig.supportChains = _supportChains;
    emit UpdateSupport(msg.sender, _token, _supportChains);
    return true;
  }
  // 是否支持
  function isSupport(address _token, uint256 _toChain) public view returns (bool) {
    bool support = false;
    BridgeConfig memory bridgeConfig = configMapping[_token];
    for (uint i = 0; i < bridgeConfig.supportChains.length; i++) {
      if(bridgeConfig.supportChains[i] == _toChain){
        support = true;
        break;
      }
    }
    return support;
  }
  // 修改单笔限额
  function updateSingle(address _token, uint256 _singleMin, uint256 _singleMax) external onlyOwner returns (bool) {
    BridgeConfig storage bridgeConfig = configMapping[_token];
    require(bridgeConfig.token != address(0), 'BridgeChain: token does not exist');
    require(_singleMax > _singleMin, 'BridgeChain: singleMax must be greater than singleMin');
    bridgeConfig.singleMin = _singleMin;
    bridgeConfig.singleMax = _singleMax;
    emit UpdateSingle(msg.sender, _token, _singleMin, _singleMax);
    return true;
  }
  // 启/停设置
  function updateEnable(address _token, bool _enable) external onlyOwner returns (bool) {
    BridgeConfig storage bridgeConfig = configMapping[_token];
    require(bridgeConfig.token != address(0), 'BridgeChain: token does not exist');
    require(bridgeConfig.enable != _enable, "BridgeChain: no change required");
    bridgeConfig.enable = _enable;
    emit UpdateEnable(msg.sender, _token, _enable);
    return true;
  }
  // 设置总开关
  function pause() external onlyOwner returns (bool) {
    _pause();
    return true;
  }
  function unpause() external onlyOwner returns (bool) {
    _unpause();
    return true;
  }
  // 允许
  receive() external payable {}
}