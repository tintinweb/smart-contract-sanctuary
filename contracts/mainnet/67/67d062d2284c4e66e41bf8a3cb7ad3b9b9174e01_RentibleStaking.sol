/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: MIT
// every part under MIT license

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
// See: 
// https://rentible.io/ 
// https://staking.rentible.io/ 
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

    // Rentible ERC20 token (in our case RNB, as reward)
    IERC20 public immutable erc20;

    // ------

    // NOTE: in the last changes we made 4 real days into one "contract" day!
    // in sec
    uint256 public immutable dayLength;

    // in sec
    uint256 public immutable stakingProgramTimeLength;

    // ------

    // NOTE (!!!): if you modify the array size, please modify max in getCurrentStakingDayNumber() and updateDailyTotalLptAmount() too (to array size - 1)

    // NOTE: in the last changes we made 4 real days into one "contract" day!
    // how many liquidity tokens were in the staking (per day) (add/subtract happens upon deposit, withdraw) (every user combined)
    uint256[93] public dailyTotalLptAmount;

    // liquidity tokens in the staking as of now (every user combined) (add/subtract happens upon deposit, withdraw) (every user combined)
    uint256 public currentTotalLptAmount;

    // ------

    // NOTE (!!!): if you modify the array size, please modify max in getCurrentStakingDayNumber() and updateDailyTotalLptAmount() too (to array size - 1)

    // NOTE: in the last changes we made 4 real days into one "contract" day!

    // total reward, has to equal the sum of the dailyPlannedErc20RewardAmounts (payed out rewards are not subtracted from this)
    uint256 public immutable totalErc20RewardAmount;

    // total reward per "contract" day, planned (practically treated as fixed/immutable, payed out rewards are not subtracted from this))
    // has to be equal to totalErc20RewardAmount (and after full reward funding equal to fundedErc20RewardAmount)
    // note: there is a starting 0 and a closing 0
    uint256[93] public dailyPlannedErc20RewardAmounts = [0, 5753337571515390000000, 5710955710955710000000, 5668573850392040000000, 5626191989828360000000, 5583810129264680000000, 5541428268701000000000, 5499046408137330000000, 5456664547573650000000, 5414282687009970000000, 5371900826446290000000, 5329518965882620000000, 5287137105318940000000, 5244755244755260000000, 5202373384191580000000, 5159991523627910000000, 5117609663064230000000, 5075227802500550000000, 5032845941936870000000, 4990464081373200000000, 4948082220809520000000, 4905700360245840000000, 4863318499682160000000, 4820936639118490000000, 4778554778554810000000, 4736172917991130000000, 4693791057427450000000, 4651409196863780000000, 4609027336300100000000, 4566645475736420000000, 4524263615172740000000, 4481881754609070000000, 4439499894045390000000, 4397118033481710000000, 4354736172918030000000, 4312354312354360000000, 4269972451790680000000, 4227590591227000000000, 4185208730663320000000, 4142826870099650000000, 4100445009535970000000, 4058063148972290000000, 4015681288408610000000, 3973299427844940000000, 3930917567281260000000, 3888535706717580000000, 3846153846153900000000, 3803771985590230000000, 3761390125026550000000, 3719008264462870000000, 3676626403899190000000, 3634244543335510000000, 3591862682771830000000, 3549480822208150000000, 3507098961644470000000, 3464717101080790000000, 3422335240517110000000, 3379953379953430000000, 3337571519389750000000, 3295189658826080000000, 3252807798262400000000, 3210425937698720000000, 3168044077135040000000, 3125662216571360000000, 3083280356007680000000, 3040898495444000000000, 2998516634880320000000, 2956134774316640000000, 2913752913752960000000, 2871371053189280000000, 2828989192625600000000, 2786607332061920000000, 2744225471498250000000, 2701843610934570000000, 2659461750370890000000, 2617079889807210000000, 2574698029243530000000, 2532316168679850000000, 2489934308116170000000, 2447552447552490000000, 2405170586988810000000, 2362788726425130000000, 2320406865861450000000, 2278025005297770000000, 2235643144734100000000, 2193261284170420000000, 2150879423606740000000, 2108497563043060000000, 2066115702479380000000, 2023733841915700000000, 1981351981352020000000, 1938970120788340000000, 0];

    // total reward funded (so far) (payed out rewards are not subtracted from this), 
    // eventually (after funding) has to be equal to totalErc20RewardAmount
    uint256 public fundedErc20RewardAmount = 0;

    // total reward, at start the same as dailyPlannedErc20RewardAmounts, 
    // daily counter, 
    // not yet tied to any UserInfo object, 
    // subtractions happen when reward is assigned to a UserInfo object
    // (rewards are always payed out through UserInfo object, not directly from here!)
    // note: there is a starting 0 and a closing 0
    uint256[93] public dailyErc20RewardAmounts =        [0, 5753337571515390000000, 5710955710955710000000, 5668573850392040000000, 5626191989828360000000, 5583810129264680000000, 5541428268701000000000, 5499046408137330000000, 5456664547573650000000, 5414282687009970000000, 5371900826446290000000, 5329518965882620000000, 5287137105318940000000, 5244755244755260000000, 5202373384191580000000, 5159991523627910000000, 5117609663064230000000, 5075227802500550000000, 5032845941936870000000, 4990464081373200000000, 4948082220809520000000, 4905700360245840000000, 4863318499682160000000, 4820936639118490000000, 4778554778554810000000, 4736172917991130000000, 4693791057427450000000, 4651409196863780000000, 4609027336300100000000, 4566645475736420000000, 4524263615172740000000, 4481881754609070000000, 4439499894045390000000, 4397118033481710000000, 4354736172918030000000, 4312354312354360000000, 4269972451790680000000, 4227590591227000000000, 4185208730663320000000, 4142826870099650000000, 4100445009535970000000, 4058063148972290000000, 4015681288408610000000, 3973299427844940000000, 3930917567281260000000, 3888535706717580000000, 3846153846153900000000, 3803771985590230000000, 3761390125026550000000, 3719008264462870000000, 3676626403899190000000, 3634244543335510000000, 3591862682771830000000, 3549480822208150000000, 3507098961644470000000, 3464717101080790000000, 3422335240517110000000, 3379953379953430000000, 3337571519389750000000, 3295189658826080000000, 3252807798262400000000, 3210425937698720000000, 3168044077135040000000, 3125662216571360000000, 3083280356007680000000, 3040898495444000000000, 2998516634880320000000, 2956134774316640000000, 2913752913752960000000, 2871371053189280000000, 2828989192625600000000, 2786607332061920000000, 2744225471498250000000, 2701843610934570000000, 2659461750370890000000, 2617079889807210000000, 2574698029243530000000, 2532316168679850000000, 2489934308116170000000, 2447552447552490000000, 2405170586988810000000, 2362788726425130000000, 2320406865861450000000, 2278025005297770000000, 2235643144734100000000, 2193261284170420000000, 2150879423606740000000, 2108497563043060000000, 2066115702479380000000, 2023733841915700000000, 1981351981352020000000, 1938970120788340000000, 0];

    // has to be equal to the sum of the dailyErc20RewardAmounts array, payed out rewards are subtracted from this, this is the remaing unassigned reward, not tied to any UserInfo object
    uint256 public currentTotalErc20RewardAmount = 0;

    // ------

    // info of each user (depositor)
    struct UserInfo {

        // NOTE: in the last changes we made 4 real days into one "contract" day!

        uint256 currentlyAssignedRewardAmount; // reward (ERC20 Rentible token) amount, that was already clearly assigned to this UserInfo object (meaning subtracted from dailyErc20RewardAmounts and currentTotalErc20RewardAmount)
        uint256 rewardCountedUptoDay; // the "contract" day (stakingDayNumber) up to which currentlyAssignedRewardAmount was already handled

        uint256 lptAmount;
    }

    // user (UserInfo) mapping
    mapping (address => UserInfo) public userInfo;

    /* -------------------------------------------------------------------- */
    /* --- events --------------------------------------------------------- */
    /* -------------------------------------------------------------------- */

    event Deposit(address indexed user, uint256 depositedLptAmount);
 
    event WithdrawLptCore(address indexed user, uint256 withdrawnLptAmount);
    event TakeOutSomeOfTheAccumulatedReward(address indexed user, uint256 rewardAmountTakenOut);

    event Fund(address indexed ownerUser, uint256 addedErc20Amount);

    /* -------------------------------------------------------------------- */
    /* --- constructor ---------------------------------------------------- */
    /* -------------------------------------------------------------------- */
    
    // https://abi.hashex.org/#
    // 0000000000000000000000005af3176021e2450850377d4b166364e5c52ae82f000000000000000000000000e764f66e9e165cd29116826b84e943176ac8e91c0000000000000000000000000000000000000000000000000000000000000000

    // _startTime = 0: means start instantly upon deploy
    constructor(IERC20 _erc20, IERC20 _lpToken, uint256 _startTime) public {
       
        require(_startTime == 0 || _startTime > 1621041111, "constructor: _startTime is too small");
          
        // ---

        erc20 = _erc20; // RNB (for rewards)
        lpToken = _lpToken; // RNB/ETH Uni V2 (the staked token)

        // ---

        // NOTE: in the last changes we made 4 real days into one contract day
        // variables were parameterized already (for testing etc.) and were not renamed

        uint256 dayLengthT = 345600; // 86400 sec = one day, 345600 sec = 4 days
        // uint256 dayLengthT = 600; // scaled down, for testing, ratio 10 minutes = 4 day

        dayLength = dayLengthT; // this way it can be immutable
        
        // ---

        uint256 startTimeT;
       
        if (_startTime > 0) {
            startTimeT = _startTime;
        } else {
            startTimeT = block.timestamp; // default is current time
        }
        
        startTime = SafeMath.sub(startTimeT, dayLengthT); // this way it can be immutable, we subtract 1 day to skip day 0

        // ---

        // NOTE: in the last changes we made 4 real days into one "contract" day
        // 364 real days = 91 contract days = staking program length

        uint256 stakingProgramTimeLengthT = SafeMath.mul(dayLengthT, 91);

        stakingProgramTimeLength = stakingProgramTimeLengthT; // this way it can be immutable

        // ---

        uint256 endTimeT = SafeMath.add(startTimeT, stakingProgramTimeLengthT); 

        endTime = endTimeT; // this way it can be immutable
        
        // ---

        uint256 totalErc20RewardAmountT = 350000000000000000000000; // 350000 RNB

        totalErc20RewardAmount = totalErc20RewardAmountT; // this way it can be immutable
             
    }

    /* -------------------------------------------------------------------- */
    /* --- basic write operations for the depositors ---------------------- */
    /* -------------------------------------------------------------------- */
    
    // Deposit LP tokens (by the users/investors/depositors)
    function deposit(uint256 _depositLptAmount) public {

        require(_depositLptAmount > 0, "deposit: _depositLptAmount must be positive");

        require(block.timestamp >= startTime, "deposit: cannot deposit yet, current time is before startTime");
        require(block.timestamp < endTime, "deposit: cannot deposit anymore, current time is after endTime");

        // require(fundedErc20RewardAmount == totalErc20RewardAmount, "deposit: please wait until owner funds the rewards");

        // ---
        
        UserInfo storage user = userInfo[msg.sender];

        addToTheUsersAssignedReward();
        
        // ---

        user.lptAmount = SafeMath.add(user.lptAmount, _depositLptAmount);
        lpToken.safeTransferFrom(msg.sender, address(this), _depositLptAmount);

        currentTotalLptAmount = SafeMath.add(currentTotalLptAmount, _depositLptAmount);
        updateDailyTotalLptAmount();
        
        // ---

        emit Deposit(msg.sender, _depositLptAmount);

    }

    function updateDailyTotalLptAmount() private {
        
        // NOTE: in the last changes we made 4 real days into one "contract" day

        uint256 currentStakingDayNumber = getCurrentStakingDayNumber();

        for (uint256 i = currentStakingDayNumber; i <= 92; i++) {
            dailyTotalLptAmount[i] = currentTotalLptAmount;
        } 

    }

    /*
    
    Withdraw variants:

    1) withdrawLptCore(uint256) = emergency withdraw, user receives the param amount of LPT, does not receive RNB, can unrecoverably loose some reward RNB
    2) withdrawWithoutReward(uint256) = user receives the param amount of LPT, plus the method calculates and updates the reward amount in UserInfo object (but leaves it there)
    3) withdrawAllWithoutReward() = same as 3, amount is fixed/all (user.lptAmount)
    4) takeOutSomeOfTheAccumulatedReward(uint256) = leaves deposited LPT untouched, user receives the param amount of rewards
    5) takeOutTheAccumulatedReward() = same as 4, reward amount is fixed/all (user.currentlyAssignedRewardAmount, it gets refreshed/recalculated before take out)
    6) withdrawWithAllReward(uint256) = method 4, reward amount is fixed/all (user.currentlyAssignedRewardAmount); plus after that method 2
    7) withdrawAllWithAllReward() = method 4, reward amount is fixed/all (user.currentlyAssignedRewardAmount), plus after that method 2, amount is fixed/all (user.lptAmount)
    
    */

    // 1
    // this works as the inner function of all LP token withdraws, but also on its own as a kind of emergency withdraw
    function withdrawLptCore(uint256 _withdrawLptAmount) public {

        require(_withdrawLptAmount > 0, "withdrawLptCore: _withdrawLptAmount must be positive");

        UserInfo storage user = userInfo[msg.sender];
        require(user.lptAmount >= _withdrawLptAmount, "withdrawLptCore: cannot withdraw more than the deposit, _withdrawLptAmount is too big");
         
        lpToken.safeTransfer(msg.sender, _withdrawLptAmount); // send lpt to the user
        
        user.lptAmount = SafeMath.sub(user.lptAmount, _withdrawLptAmount);  // subtract from the user's lpt
        currentTotalLptAmount = SafeMath.sub(currentTotalLptAmount, _withdrawLptAmount); // subtract from the global counter

        updateDailyTotalLptAmount(); // update the global daily (array) counters

        emit WithdrawLptCore(msg.sender, _withdrawLptAmount);

    }

    // 2
    function withdrawWithoutReward(uint256 _withdrawLptAmount) public {
        addToTheUsersAssignedReward(); // updates UserInfo object
        withdrawLptCore(_withdrawLptAmount);
    }

    // 3
    function withdrawAllWithoutReward() public {
        addToTheUsersAssignedReward(); // updates UserInfo object
        withdrawWithoutReward(depositedLptOfTheUser());
    }

    // 4
    function takeOutSomeOfTheAccumulatedReward(uint256 _rewardAmountToBeTakenOut) public returns(uint256) {

        require(_rewardAmountToBeTakenOut > 0, "takeOutSomeOfTheAccumulatedReward: _rewardAmountToBeTakenOut must be positive");

        addToTheUsersAssignedReward(); // updates UserInfo object

        UserInfo storage user = userInfo[msg.sender];
        require(user.currentlyAssignedRewardAmount >= _rewardAmountToBeTakenOut, "withdraw: user.currentlyAssignedRewardAmount is too low for this operation, _rewardAmountToBeTakenOut is too big");

        // note: will always send out only what is currently held inside the UserInfo object (never directly from the global dailyErc20RewardAmounts[] array)
        // (so addToTheUsersAssignedReward() call is needed before transfer)

        erc20.safeTransfer(msg.sender, _rewardAmountToBeTakenOut); // send erc20 reward to the user
        user.currentlyAssignedRewardAmount = SafeMath.sub(user.currentlyAssignedRewardAmount, _rewardAmountToBeTakenOut);

        emit TakeOutSomeOfTheAccumulatedReward(msg.sender, _rewardAmountToBeTakenOut);
        
        return _rewardAmountToBeTakenOut;
        
    }

    // 5
    function takeOutTheAccumulatedReward() public returns(uint256) {
        addToTheUsersAssignedReward(); // updates UserInfo object 
        takeOutSomeOfTheAccumulatedReward(assignedRewardOfTheUser());
    }

    // 6
    function withdrawWithAllReward(uint256 _withdrawLptAmount) public {

        addToTheUsersAssignedReward(); // updates UserInfo object 

        uint256 a = assignedRewardOfTheUser();
        if (a > 0) {
            takeOutSomeOfTheAccumulatedReward(a);
        }

        withdrawWithoutReward(_withdrawLptAmount);
    }

    // 7
    function withdrawAllWithAllReward() public {

        addToTheUsersAssignedReward(); // updates UserInfo object 

        uint256 a = assignedRewardOfTheUser();
        if (a > 0) {
            takeOutSomeOfTheAccumulatedReward(a);
        }

        uint256 d = depositedLptOfTheUser();
        if (d > 0) {
            withdrawWithoutReward(d);
        }

    }

    /* -------------------------------------------------------------------- */
    /* --- reward related read/write operations for the depositors -------- */
    /* -------------------------------------------------------------------- */

    // Updates the current accumulated/assigned reward (RNB) of the user (depositor) 
    // (alters state in the user's UserInfo object and other places).
    function addToTheUsersAssignedReward() public returns(uint256) {

        uint256 currentStakingDayNumber = getCurrentStakingDayNumber();
        uint256 currentStakingDayNumberMinusOne = SafeMath.sub(currentStakingDayNumber, 1);

        if (currentStakingDayNumber == 0) {
            return 0;
        }

        UserInfo storage user = userInfo[msg.sender];
        
        if (user.lptAmount == 0) { 
            // when user.lptAmount was set to 0 we did the calculations and state changes, if lptAmount is still 0, it means no change since then
            // note: important to always call addToTheUsersAssignedReward() before transfers!
            user.rewardCountedUptoDay = currentStakingDayNumberMinusOne;
            return user.currentlyAssignedRewardAmount;
        }
        
        // ---

        // NOTE: in the last changes we made 4 real days into one contract day

        uint256 rewardCountedUptoDay = user.rewardCountedUptoDay;
        uint256 rewardCountedUptoDayNextDay = SafeMath.add(rewardCountedUptoDay, 1);

        if (!(rewardCountedUptoDayNextDay <= currentStakingDayNumberMinusOne)) {
            return user.currentlyAssignedRewardAmount;
        }

        // ---
        
        uint256 usersRewardRecently = 0;
        
        for (uint256 i = rewardCountedUptoDayNextDay; i <= currentStakingDayNumberMinusOne; i++) {
                        
            if (dailyTotalLptAmount[i] == 0) {
                continue;
            }

            // logic used here is because of integer division, we improve precision (not perfect solution, good enough)
            // (sample uses 10^4 instead of 10^19 units)
            // 49.5k = users stake, 80k = total stake, 2k = daily reward)
            // correct value would be = 1237.5
            // (49 500 / 80 000 = 0.61875 = 0) * 2000 = 0; 
            // ((49 500 * 100) / 80 000 = 61,875 = 61) * 2000 = 122000) / 100 = 1220 = 1220
            // ((49 500 * 1000) / 80 000 = 618,75 = 618) * 2000 = 1236000) / 1000 = 1236 = 1236
            // ((49 500 * 10000) / 80 000 = 6187.5 = 6187) * 2000 = 12374000) / 10000 = 1237.4 = 1237

            uint256 raiser = 10000000000000000000; // 10^19
            
            // uint256 rew = (((user.lptAmount.mul(raiser)).div(dailyTotalLptAmount[i])).mul(dailyPlannedErc20RewardAmounts[i])).div(raiser);
            
            // same with SafeMath:

            uint256 rew = SafeMath.mul(user.lptAmount, raiser);
            rew = SafeMath.div(rew, dailyTotalLptAmount[i]);
            rew = SafeMath.mul(rew, dailyPlannedErc20RewardAmounts[i]);
            rew = SafeMath.div(rew, raiser);

            if (dailyErc20RewardAmounts[i] < rew) { 
                // the has to be added amount is less, than the remaining (global), can happen because of slight rounding issues at the very end
                // not really... more likely the oposite (that some small residue gets left behind)
                rew = dailyErc20RewardAmounts[i];
            }

            usersRewardRecently = SafeMath.add(usersRewardRecently, rew);
            dailyErc20RewardAmounts[i] = SafeMath.sub(dailyErc20RewardAmounts[i], rew);
           
        }

        user.currentlyAssignedRewardAmount = SafeMath.add(user.currentlyAssignedRewardAmount, usersRewardRecently);
        currentTotalErc20RewardAmount = SafeMath.sub(currentTotalErc20RewardAmount, usersRewardRecently);
        user.rewardCountedUptoDay = currentStakingDayNumberMinusOne;

        return user.currentlyAssignedRewardAmount;
    }

    // Current additionally assignable reward (RNB) of the user (depositor), meaning what wasn't added to UserInfo, but will be upon the next addToTheUsersAssignedReward() call
    // (read only, does not save/alter state)
    function calculateUsersAssignableReward() public view returns(uint256) {

        // ---
        // --- similar to addToTheUsersAssignedReward(), but without the writes, plus few other modifications
        // ---

        uint256 currentStakingDayNumber = getCurrentStakingDayNumber();
        uint256 currentStakingDayNumberMinusOne = SafeMath.sub(currentStakingDayNumber, 1);

        if (currentStakingDayNumber == 0) {
            return 0;
        }

        UserInfo storage user = userInfo[msg.sender];
        
        if (user.lptAmount == 0) {
            // user.rewardCountedUptoDay = currentStakingDayNumberMinusOne; // different from addToTheUsersAssignedReward
            return 0; // different from addToTheUsersAssignedReward
        }
        
        // ---

        uint256 rewardCountedUptoDay = user.rewardCountedUptoDay;
        uint256 rewardCountedUptoDayNextDay = SafeMath.add(rewardCountedUptoDay, 1);

        if (!(rewardCountedUptoDayNextDay <= currentStakingDayNumberMinusOne)) {
            return 0; // different from addToTheUsersAssignedReward
        }

        // ---
        
        uint256 usersRewardRecently = 0;
        
        for (uint256 i = rewardCountedUptoDayNextDay; i <= currentStakingDayNumberMinusOne; i++) {
                        
            if (dailyTotalLptAmount[i] == 0) {
                continue;
            }

            // logic used here is because of integer division, we improve precision (not perfect solution, good enough)
            // (sample use 10^4 instead of 10^19 units)
            // 49.5k = users stake, 80k = total stake, 2k = daily reward)
            // correct value would be = 1237.5
            // (49 500 / 80 000 = 0.61875 = 0) * 2000 = 0; 
            // ((49 500 * 100) / 80 000 = 61,875 = 61) * 2000 = 122000) / 100 = 1220 = 1220
            // ((49 500 * 1000) / 80 000 = 618,75 = 618) * 2000 = 1236000) / 1000 = 1236 = 1236
            // ((49 500 * 10000) / 80 000 = 6187.5 = 6187) * 2000 = 12374000) / 10000 = 1237.4 = 1237

            uint256 raiser = 10000000000000000000; // 10^19
            
            // uint256 rew = (((user.lptAmount.mul(raiser)).div(dailyTotalLptAmount[i])).mul(dailyPlannedErc20RewardAmounts[i])).div(raiser);
            
            // with SafeMath:

            uint256 rew = SafeMath.mul(user.lptAmount, raiser);
            rew = SafeMath.div(rew, dailyTotalLptAmount[i]);
            rew = SafeMath.mul(rew, dailyPlannedErc20RewardAmounts[i]);
            rew = SafeMath.div(rew, raiser);
            
            if (dailyErc20RewardAmounts[i] < rew) {
                // the has to be added amount is less, than the remaining (global), can happen because of slight rounding issues at the very end
                // not really... more likely the oposite (that some small residue gets left behind)
                rew = dailyErc20RewardAmounts[i];
            }

            usersRewardRecently = SafeMath.add(usersRewardRecently, rew);
            // dailyErc20RewardAmounts[i] = SafeMath.sub(dailyErc20RewardAmounts[i], rew); // different from addToTheUsersAssignedReward
           
        }

        // different from addToTheUsersAssignedReward
        // user.currentlyAssignedRewardAmount = SafeMath.add(user.currentlyAssignedRewardAmount, usersRewardRecently); 
        // currentTotalErc20RewardAmount = SafeMath.sub(currentTotalErc20RewardAmount, usersRewardRecently);
        // user.rewardCountedUptoDay = currentStakingDayNumberMinusOne;
        
        // ---
        // ---
        // ---

        return usersRewardRecently;

    }    

    // user.currentlyAssignedRewardAmount + calculateUsersAssignableReward()
    // (read only, does not save/alter state)
    function calculateCurrentTakeableRewardOfTheUser() public view returns(uint256) {
        UserInfo storage user = userInfo[msg.sender];
        return SafeMath.add(user.currentlyAssignedRewardAmount, calculateUsersAssignableReward());
    }

    // Current clearly accumulated and assigned RNB reward of the user (depositor), meaning what is already in UserInfo
    function assignedRewardOfTheUser() public view returns(uint256) {
        UserInfo storage user = userInfo[msg.sender];
        return user.currentlyAssignedRewardAmount;
    }

    function rewardCountedUptoDayOfTheUser() public view returns(uint256) {
        UserInfo storage user = userInfo[msg.sender];
        return user.rewardCountedUptoDay;
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
        require(SafeMath.add(fundedErc20RewardAmount, _fundErc20Amount) <= totalErc20RewardAmount, "fund: _fundErc20Amount too big, sum would exceed totalErc20RewardAmount");

        // we do not check time here, optionally reward funding can be provided any time
        // (in pratice it should happen before start, or very quickly)

        erc20.safeTransferFrom(address(msg.sender), address(this), _fundErc20Amount);

        fundedErc20RewardAmount = SafeMath.add(fundedErc20RewardAmount, _fundErc20Amount);
        currentTotalErc20RewardAmount = SafeMath.add(currentTotalErc20RewardAmount, _fundErc20Amount);

        emit Fund(msg.sender, _fundErc20Amount);
    }

    /* -------------------------------------------------------------------- */
    /* --- misc utils ----------------------------------------------------- */
    /* -------------------------------------------------------------------- */

    function getCurrentStakingDayNumber() public view returns(uint256) {
        
        uint256 elapsedTime = block.timestamp.sub(startTime);
        uint256 dayNumber = SafeMath.div(elapsedTime, dayLength); // integer division, truncated

        if (dayNumber > 92) {
            return 92;
        }
        
        return dayNumber;

    }

}