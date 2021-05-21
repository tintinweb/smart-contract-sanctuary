/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

// SPDX-License-Identifier: MIT
// every part

// File: contracts\@openzeppelin\contracts\token\ERC20\IERC20.sol



pragma solidity ^0.6.0;

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

// File: contracts\@openzeppelin\contracts\math\SafeMath.sol



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

// File: contracts\@openzeppelin\contracts\utils\Address.sol



pragma solidity ^0.6.2;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

// File: contracts\@openzeppelin\contracts\token\ERC20\SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: contracts\@openzeppelin\contracts\utils\EnumerableSet.sol



pragma solidity ^0.6.0;

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

// File: contracts\@openzeppelin\contracts\GSN\Context.sol



pragma solidity ^0.6.0;

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

// File: contracts\@openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.6.0;

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

/* =========================================================================================================== */
/* =========================================================================================================== */
/* =========================================================================================================== */

// File: contracts\RentibleStaking.sol


pragma solidity 0.6.12;

// 0.6.12+commit.27d51765

// LP token (ERC20 reward) based staking for Rentible
// 
// Inspired by:
// https://github.com/SashimiProject/sashimiswap/blob/master/contracts/MasterChef.sol
// https://github.com/ltonetwork

contract RentibleStaking is Ownable { 

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------- */
    /* --- main variables ------------------------------------------------ */
    /* -------------------------------------------------------------------- */

    // when staking starts, unix time
    uint256 public immutable startTime;
    // when staking ends, unix time
    uint256 public immutable endTime;

    // ------

    // Uniswap V2 liquidity token (the staked token)
    IERC20 public immutable lpToken; 

    // Rentible ERC20 token (as reward)
    IERC20 public immutable erc20;

    // ------

    uint256 public immutable dayLength;
    uint256 public immutable yearLength;

    // ------

    // how many liquidity tokens were in the staking (per day) (add/subtract happens)
    // (note: array index starts from 0!)
    uint256[92] public dailyTotalLptAmount;
    uint256 public currentTotalLptAmount;

    // ------

    // total reward, has to equal the sum of the dailyPlannedErc20RewardAmounts
    uint256 public immutable totalErc20RewardAmount;

    // total reward funded (so far) (payed out rewards are not subtracted from this), 
    // eventually (after funding) has to be equal to totalErc20RewardAmount
    uint256 public fundedErc20RewardAmount = 0;

    // total reward, daily planned (practically treated as fixed/immutable, no subtraction)
    // (note: array index starts from 0!)
    // has to be equal to totalErc20RewardAmount (and fundedErc20RewardAmount)
    // uint256[92] public /*immutable*/ dailyPlannedErc20RewardAmounts = [1978021978021980000000, 1963369963369960000000, 1948717948717950000000, 1934065934065930000000, 1919413919413920000000, 1904761904761910000000, 1890109890109890000000, 1875457875457880000000, 1860805860805860000000, 1846153846153850000000, 1831501831501830000000, 1816849816849820000000, 1802197802197800000000, 1787545787545790000000, 1772893772893770000000, 1758241758241760000000, 1743589743589740000000, 1728937728937730000000, 1714285714285720000000, 1699633699633700000000, 1684981684981690000000, 1670329670329670000000, 1655677655677660000000, 1641025641025640000000, 1626373626373630000000, 1611721611721610000000, 1597069597069600000000, 1582417582417580000000, 1567765567765570000000, 1553113553113550000000, 1538461538461540000000, 1523809523809530000000, 1509157509157510000000, 1494505494505500000000, 1479853479853480000000, 1465201465201470000000, 1450549450549450000000, 1435897435897440000000, 1421245421245420000000, 1406593406593410000000, 1391941391941390000000, 1377289377289380000000, 1362637362637370000000, 1347985347985350000000, 1333333333333340000000, 1318681318681320000000, 1304029304029310000000, 1289377289377290000000, 1274725274725280000000, 1260073260073260000000, 1245421245421250000000, 1230769230769230000000, 1216117216117220000000, 1201465201465200000000, 1186813186813190000000, 1172161172161180000000, 1157509157509160000000, 1142857142857150000000, 1128205128205130000000, 1113553113553120000000, 1098901098901100000000, 1084249084249090000000, 1069597069597070000000, 1054945054945060000000, 1040293040293040000000, 1025641025641030000000, 1010989010989010000000, 996336996337000000000, 981684981684985000000, 967032967032971000000, 952380952380956000000, 937728937728942000000, 923076923076927000000, 908424908424912000000, 893772893772898000000, 879120879120883000000, 864468864468868000000, 849816849816854000000, 835164835164839000000, 820512820512825000000, 805860805860810000000, 791208791208796000000, 776556776556781000000, 761904761904766000000, 747252747252752000000, 732600732600737000000, 717948717948723000000, 703296703296708000000, 688644688644693000000, 673992673992679000000, 659340659340664000000, 0];
	// TODO: for testing 1200 total instead of 120000
    uint256[92] public /*immutable*/ dailyPlannedErc20RewardAmounts = [19780219780219800000, 19633699633699600000, 19487179487179500000, 19340659340659300000, 19194139194139200000, 19047619047619100000, 18901098901098900000, 18754578754578800000, 18608058608058600000, 18461538461538500000, 18315018315018300000, 18168498168498200000, 18021978021978000000, 17875457875457900000, 17728937728937700000, 17582417582417600000, 17435897435897400000, 17289377289377300000, 17142857142857200000, 16996336996337000000, 16849816849816900000, 16703296703296700000, 16556776556776600000, 16410256410256400000, 16263736263736300000, 16117216117216100000, 15970695970696000000, 15824175824175800000, 15677655677655700000, 15531135531135500000, 15384615384615400000, 15238095238095300000, 15091575091575100000, 14945054945055000000, 14798534798534800000, 14652014652014700000, 14505494505494500000, 14358974358974400000, 14212454212454200000, 14065934065934100000, 13919413919413900000, 13772893772893800000, 13626373626373700000, 13479853479853500000, 13333333333333400000, 13186813186813200000, 13040293040293100000, 12893772893772900000, 12747252747252800000, 12600732600732600000, 12454212454212500000, 12307692307692300000, 12161172161172200000, 12014652014652000000, 11868131868131900000, 11721611721611800000, 11575091575091600000, 11428571428571500000, 11282051282051300000, 11135531135531200000, 10989010989011000000, 10842490842490900000, 10695970695970700000, 10549450549450600000, 10402930402930400000, 10256410256410300000, 10109890109890100000, 9963369963370000000, 9816849816849850000, 9670329670329710000, 9523809523809560000, 9377289377289420000, 9230769230769270000, 9084249084249120000, 8937728937728980000, 8791208791208830000, 8644688644688680000, 8498168498168540000, 8351648351648390000, 8205128205128250000, 8058608058608100000, 7912087912087960000, 7765567765567810000, 7619047619047660000, 7472527472527520000, 7326007326007370000, 7179487179487230000, 7032967032967080000, 6886446886446930000, 6739926739926790000, 6593406593406640000, 0];

    // total reward, daily counters (subtractions happen when reward is assigned to a UserInfo object)
    // (note: array index starts from 0!)
    uint256[92] public dailyErc20RewardAmounts = [19780219780219800000, 19633699633699600000, 19487179487179500000, 19340659340659300000, 19194139194139200000, 19047619047619100000, 18901098901098900000, 18754578754578800000, 18608058608058600000, 18461538461538500000, 18315018315018300000, 18168498168498200000, 18021978021978000000, 17875457875457900000, 17728937728937700000, 17582417582417600000, 17435897435897400000, 17289377289377300000, 17142857142857200000, 16996336996337000000, 16849816849816900000, 16703296703296700000, 16556776556776600000, 16410256410256400000, 16263736263736300000, 16117216117216100000, 15970695970696000000, 15824175824175800000, 15677655677655700000, 15531135531135500000, 15384615384615400000, 15238095238095300000, 15091575091575100000, 14945054945055000000, 14798534798534800000, 14652014652014700000, 14505494505494500000, 14358974358974400000, 14212454212454200000, 14065934065934100000, 13919413919413900000, 13772893772893800000, 13626373626373700000, 13479853479853500000, 13333333333333400000, 13186813186813200000, 13040293040293100000, 12893772893772900000, 12747252747252800000, 12600732600732600000, 12454212454212500000, 12307692307692300000, 12161172161172200000, 12014652014652000000, 11868131868131900000, 11721611721611800000, 11575091575091600000, 11428571428571500000, 11282051282051300000, 11135531135531200000, 10989010989011000000, 10842490842490900000, 10695970695970700000, 10549450549450600000, 10402930402930400000, 10256410256410300000, 10109890109890100000, 9963369963370000000, 9816849816849850000, 9670329670329710000, 9523809523809560000, 9377289377289420000, 9230769230769270000, 9084249084249120000, 8937728937728980000, 8791208791208830000, 8644688644688680000, 8498168498168540000, 8351648351648390000, 8205128205128250000, 8058608058608100000, 7912087912087960000, 7765567765567810000, 7619047619047660000, 7472527472527520000, 7326007326007370000, 7179487179487230000, 7032967032967080000, 6886446886446930000, 6739926739926790000, 6593406593406640000, 0];

    // has to be equal to the sum of the dailyErc20RewardAmounts array, payed out rewards are subtracted from this
    uint256 public currentTotalErc20RewardAmount = 0;

    // ------

    // info of each user (depositor)
    struct UserInfo {
        uint256 currentlyAssignedRewardAmount; // reward (ERC20 Rentible token) amount, that was already clearly assigned to this UserInfo object
        uint256 rewardCountedUptoDay; // the day (stakingDayNumber) up to which currentlyAssignedRewardAmount was already handled

        uint256 lptAmount;
    }

    // user (UserInfo) map
    mapping (address => UserInfo) public userInfo;

    /* -------------------------------------------------------------------- */
    /* --- events --------------------------------------------------------- */
    /* -------------------------------------------------------------------- */

    event Deposit(address indexed user, uint256 depositLptAmount);
 
    event WithdrawWithoutReward(address indexed user, uint256 withdrawLptAmount);
    event WithdrawAllWithoutReward(address indexed user);

    event WithdrawWithReward(address indexed user, uint256 withdrawLptAmount, uint256 erc20RewardPayedOutInThisTrans);
    event WithdrawAllWithAllReward(address indexed user);

    event TakeOutTheAccumulatedReward(address indexed user, uint256 erc20RewardPayedOutInThisTrans);

    event Fund(address indexed adminUser, uint256 fundErc20Amount, uint256 fundedErc20RewardAmount);

    /* -------------------------------------------------------------------- */
    /* --- constructor ---------------------------------------------------- */
    /* -------------------------------------------------------------------- */
    
    // https://abi.hashex.org/#
    // 0000000000000000000000005af3176021e2450850377d4b166364e5c52ae82f000000000000000000000000e764f66e9e165cd29116826b84e943176ac8e91c0000000000000000000000000000000000000000000000000000000000000000

    constructor(IERC20 erc20Param, IERC20 lpTokenParam, uint256 startTimeParam) public {
       
        require(startTimeParam == 0 || startTimeParam > 1621041111, "constructor: startTimeParam is too small");
          
        lpToken = lpTokenParam; // RNB/ETH Uni V2
        erc20 = erc20Param; // RNB 
       
        uint256 startTimeParam2;
       
        if (startTimeParam > 0) {
            startTimeParam2 = startTimeParam;
        } else {
            startTimeParam2 = block.timestamp; // default is current time
        }
        
        startTime = startTimeParam2;

        // uint256 dayLengthT = 86400; // 86400 sec = one day
        uint256 dayLengthT = 600; // scaled down, for testing, ratio 10 minute = 1 day // TODO: change back to PROD value
        dayLength = dayLengthT;
        
        uint256 yearLengthT = dayLengthT.mul(90); // TODO: rename to quarter year
        yearLength = yearLengthT;
        uint256 endTimeT = startTimeParam2.add(yearLengthT); 
        endTime = endTimeT;
        
        // uint256 tera = 120000000000000000000000;
        uint256 tera = 1200000000000000000000; // TODO: for testing 1200 instead of 120000
        totalErc20RewardAmount = tera;
             
    }

    /* -------------------------------------------------------------------- */
    /* --- basic write operations for the depositors ---------------------- */
    /* -------------------------------------------------------------------- */
    
    // Deposit LP tokens (by the users/investors = depositors)
    function deposit(uint256 _depositLptAmount) public {

        require(_depositLptAmount > 0, "deposit: _depositLptAmount must be positive");

        require(block.timestamp >= startTime, "deposit: cannot deposit yet, current time is before startTime");
        require(block.timestamp < endTime, "deposit: cannot deposit anymore, current time is after endTime");

        // ---
        
        UserInfo storage user = userInfo[msg.sender];

        if (user.lptAmount > 0) {
            addToTheTheUsersAssignedReward();
        }

        // ---

        user.lptAmount = user.lptAmount.add(_depositLptAmount);
        lpToken.safeTransferFrom(msg.sender, address(this), _depositLptAmount);

        currentTotalLptAmount = currentTotalLptAmount.add(_depositLptAmount);
        updateDailyTotalLptAmount();
        
        // ---

        emit Deposit(msg.sender, _depositLptAmount);

    }

    function updateDailyTotalLptAmount() private {

        uint256 currentStakingDayNumber = getCurrentStakingDayNumber();
        for (uint256 i = currentStakingDayNumber; i <= 91; i++) {
            dailyTotalLptAmount[i] = currentTotalLptAmount;
        } 

    }

    // Withdraw LP tokens (for depositors) (without reward)
    function withdrawWithoutReward(uint256 _withdrawLptAmount) public {

        require(_withdrawLptAmount > 0, "withdraw: _withdrawLptAmount must be positive");

        // ---

        UserInfo storage user = userInfo[msg.sender];
        require(user.lptAmount >= _withdrawLptAmount, "withdraw: cannot withdraw more than the deposit, _withdrawLptAmount is too big");
         
        lpToken.safeTransfer(msg.sender, _withdrawLptAmount); // send lpt to the user
        user.lptAmount = user.lptAmount.sub(_withdrawLptAmount);  // subtract from the user's lpt

        currentTotalLptAmount = currentTotalLptAmount.sub(_withdrawLptAmount);
        updateDailyTotalLptAmount();

        emit WithdrawWithoutReward(msg.sender, _withdrawLptAmount);
    }

    // Withdraw LP tokens (for depositors) (without reward)
    function withdrawAllWithoutReward() public {

        emit WithdrawAllWithoutReward(msg.sender);

        withdrawWithoutReward(depositedLptOfTheUser());

    }

    // Take out the rewards (for depositors) (just the accumulated rewards, leaves the LP tokens)
    function takeOutTheAccumulatedReward() public returns(uint256) {

        // ---

        addToTheTheUsersAssignedReward(); // updates UserInfo object

        // ---

        UserInfo storage user = userInfo[msg.sender];

        uint256 erc20RewardPayedOutInThisTrans = user.currentlyAssignedRewardAmount; // can be 0

        if (erc20RewardPayedOutInThisTrans == 0) {
            emit TakeOutTheAccumulatedReward(msg.sender, erc20RewardPayedOutInThisTrans);
            return erc20RewardPayedOutInThisTrans;
        }

        // ---

        require(totalErc20RewardAmount >= erc20RewardPayedOutInThisTrans, "takeOutTheAccumulatedReward: neccesary funding (reward) was not provied yet by Rentible");
        
        // ---

        // note: will always send out what is held inside the UserInfo object

        erc20.safeTransfer(msg.sender, erc20RewardPayedOutInThisTrans); // send erc20 reward to the user
        user.currentlyAssignedRewardAmount = 0;

        // ---

        emit TakeOutTheAccumulatedReward(msg.sender, erc20RewardPayedOutInThisTrans);
        
        return erc20RewardPayedOutInThisTrans;
        
    }

    // Withdraw LP tokens (for depositors), with all accumalated rewards
    function withdrawWithReward(uint256 _withdrawLptAmount) public {

        uint256 erc20RewardPayedOutInThisTrans = takeOutTheAccumulatedReward();

        emit WithdrawWithReward(msg.sender, _withdrawLptAmount, erc20RewardPayedOutInThisTrans);

        withdrawWithoutReward(_withdrawLptAmount);

    }

    // Withdraw LP tokens (for depositors), with all accumalated rewards
    function withdrawAllWithAllReward() public {

        emit WithdrawAllWithAllReward(msg.sender);
        
        withdrawWithReward(depositedLptOfTheUser());

    }

    /* -------------------------------------------------------------------- */
    /* --- reward related read/write operations for the depositors -------- */
    /* -------------------------------------------------------------------- */

    // Updates the current accumulated reward (RNB) of the user (depositor) (alters state, saves into UserInfo)
    function addToTheTheUsersAssignedReward() public {

        // similar (but not the same as) calculateCurrentTakeableRewardOfTheUser

        uint256 dayNumber = getCurrentStakingDayNumber();
        if (dayNumber < 1) {
            return;
        }

        // ---

        UserInfo storage user = userInfo[msg.sender];

        uint256 currentlyAssignedRewardAmount = user.currentlyAssignedRewardAmount;
        
        uint256 rewardCountedUptoDay = user.rewardCountedUptoDay;

        uint256 rewardCountedUptoDayNextDay;
        if (rewardCountedUptoDay == 0) {
             rewardCountedUptoDayNextDay = 0;
        } else {
           rewardCountedUptoDayNextDay = rewardCountedUptoDay.add(1);
        }

        uint256 dayNumberMinusOne = dayNumber.sub(1);

        if (!(rewardCountedUptoDayNextDay <= dayNumberMinusOne)) {
            return;
        }
    
        // ---
        
        uint256 usersCurrentLtpAmount = user.lptAmount;
        
        if (usersCurrentLtpAmount == 0) {
            return;
        }

        // ---
        
        uint256 usersRewardRecently = 0;
        
        for (uint256 i = rewardCountedUptoDayNextDay; i <= dayNumberMinusOne; i++) {
                        
            uint256 totalLtpPerUserLtp = dailyTotalLptAmount[i].div(usersCurrentLtpAmount);

            if (totalLtpPerUserLtp == 0) {
                continue;
            }

            uint256 rew = dailyPlannedErc20RewardAmounts[i].div(totalLtpPerUserLtp);

            if (dailyErc20RewardAmounts[i] >= rew) {
                usersRewardRecently = usersRewardRecently.add(rew);
                dailyErc20RewardAmounts[i] = dailyErc20RewardAmounts[i].sub(rew);
            } else {
                // relevant at the and because of possible slight rounding issues
                usersRewardRecently = usersRewardRecently.add(dailyErc20RewardAmounts[i]);
                dailyErc20RewardAmounts[i] = 0;
            }
           
        }

        user.currentlyAssignedRewardAmount = currentlyAssignedRewardAmount.add(usersRewardRecently);
        user.rewardCountedUptoDay = dayNumberMinusOne;
        currentTotalErc20RewardAmount = currentTotalErc20RewardAmount.sub(usersRewardRecently);

    }

    // Current accumulated reward (RNB) of the user (depositor) (read only, does not save/alter state)
    function calculateCurrentTakeableRewardOfTheUser() public view returns(uint256) {

        uint256 dayNumber = getCurrentStakingDayNumber();
        if (dayNumber < 1) {
            return 0;
        }

        // ---

        UserInfo storage user = userInfo[msg.sender];
        uint256 currentlyAssignedRewardAmount = user.currentlyAssignedRewardAmount;
        uint256 rewardCountedUptoDay = user.rewardCountedUptoDay;

        uint256 rewardCountedUptoDayNextDay;
        if (rewardCountedUptoDay == 0) {
             rewardCountedUptoDayNextDay = 0;
        } else {
            rewardCountedUptoDayNextDay = rewardCountedUptoDay.add(1);
        }

        uint256 dayNumberMinusOne = dayNumber.sub(1);

        if (!(rewardCountedUptoDayNextDay <= dayNumberMinusOne)) {
            return currentlyAssignedRewardAmount;
        }

        // ---
        
        uint256 usersCurrentLtpAmount = user.lptAmount;
        
        if (usersCurrentLtpAmount == 0) {
            return currentlyAssignedRewardAmount;
        }

        // ---
        
        uint256 usersRewardRecently = 0;
                
        for (uint256 i = rewardCountedUptoDayNextDay; i <= dayNumberMinusOne; i++) {
            
            uint256 totalLtpPerUserLtp = dailyTotalLptAmount[i].div(usersCurrentLtpAmount);

            if (totalLtpPerUserLtp == 0) {
                continue;
            }

            uint256 rev = dailyPlannedErc20RewardAmounts[i].div(totalLtpPerUserLtp);

            if (dailyErc20RewardAmounts[i] >= rev) {
                usersRewardRecently = usersRewardRecently.add(rev);
            } else {
                // relevant at the and because of possible slight rounding issues
                usersRewardRecently = usersRewardRecently.add(dailyErc20RewardAmounts[i]);
            }
           
        }

        return currentlyAssignedRewardAmount.add(usersRewardRecently);
    }

    /* -------------------------------------------------------------------- */
    /* --- other read operations for the depositors ----------------------- */
    /* -------------------------------------------------------------------- */

    // Current Uniswap V2 liquidity token amount of the user (depositor)
    function depositedLptOfTheUser() public view returns(uint256) {
        UserInfo storage user = userInfo[msg.sender];
        return user.lptAmount;
    }

    /* -------------------------------------------------------------------- */
    /* --- write operations for the contract owner ------------------------ */
    /* -------------------------------------------------------------------- */

    // Fund rewards (erc20 RNB) (operation is for Rentible admins)
    function fund(uint256 _fundErc20Amount) public onlyOwner {

        require(_fundErc20Amount > 0, "fund: _fundErc20Amount must be positive");

        require(fundedErc20RewardAmount < totalErc20RewardAmount, "fund: already fully funded");
        require(fundedErc20RewardAmount.add(_fundErc20Amount) <= totalErc20RewardAmount, "fund: _fundErc20Amount too big, sum would exceed totalErc20RewardAmount");

        // we do not check time here, optionally reward funding can be provided any time
        // (in pratice it should happen before start)
        // require(block.timestamp >= startTime, "fund: cannot fund yet, current time is before startTime");
        // require(block.timestamp <= endTime, "fund: cannot fund anymore, current time is after endTime");

        erc20.safeTransferFrom(address(msg.sender), address(this), _fundErc20Amount);

        fundedErc20RewardAmount = fundedErc20RewardAmount.add(_fundErc20Amount);
        currentTotalErc20RewardAmount = fundedErc20RewardAmount;

        emit Fund(msg.sender, _fundErc20Amount, fundedErc20RewardAmount);
    }

    /* -------------------------------------------------------------------- */
    /* --- misc utils ----------------------------------------------------- */
    /* -------------------------------------------------------------------- */

    function getCurrentStakingDayNumber() public view returns(uint256) {
        
        uint256 elapsedTime = block.timestamp.sub(startTime);
        uint256 dayNumber = elapsedTime.div(dayLength); // integer division

        if (dayNumber > 91) {
            return 91;
        }
        
        return dayNumber;

    }


}