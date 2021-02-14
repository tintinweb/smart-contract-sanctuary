pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract GelatoAddressStorage is Ownable {
    address public executorModule;
    address public oracleAggregator;
    address public gasPriceOracle;
    address public serviceRegistry;

    constructor(
        address _executorModule,
        address _oracleAggregator,
        address _gasPriceOracle,
        address _serviceRegistry
    ) public {
        executorModule = _executorModule;
        oracleAggregator = _oracleAggregator;
        gasPriceOracle = _gasPriceOracle;
        serviceRegistry = _serviceRegistry;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

// import {
//   IERC20Ext,
//   SafeERC20
// } from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import {
//   SafeMath
// } from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import {
    SafeERC20,
    SafeMath
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20Ext} from "@kyber.network/utils-sc/contracts/IERC20Ext.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {TaskStorage} from "./TaskStorage.sol";
import {GelatoAddressStorage} from "./GelatoAddressStorage.sol";
import {ServiceRegistry} from "./ServiceRegistry.sol";

// import "hardhat/console.sol";

contract ServicePostExecFee is TaskStorage {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;

    address internal constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 internal constant _gasOverhead = 50000;

    GelatoAddressStorage public immutable gelatoAS;

    event LogExecSuccess(uint256 indexed taskId, address indexed executor);

    constructor(address _gelatoAddressStorage) public {
        gelatoAS = GelatoAddressStorage(_gelatoAddressStorage);
    }

    modifier gelatofy(
        address _outToken,
        address _user,
        bytes memory _bytesBlob,
        uint256 _id
    ) {
        // start gas measurement and check if msg.sender is Gelato
        uint256 gasStart = gasleft();

        // Check only Gelato is calling
        require(
            executor() == msg.sender,
            "GelatoServiceStandard: Caller is not the executorModule"
        );

        // Verify tasks actually exists
        require(
            verifyTask(_bytesBlob, _id, _user),
            "GelatoServiceStandard: invalid task"
        );

        // update TaskStorage state before execution
        _removeTask(_bytesBlob, _id, _user);

        // query Balance
        uint256 preBalance;
        if (_outToken == _ETH) {
            preBalance = address(this).balance;
        } else {
            // query Balance
            preBalance = IERC20Ext(_outToken).balanceOf(address(this));
        }
        //console.log("Gas Used in preExec: %s", gasStart.sub(gasleft()));

        // Execute Logic
        _;

        //uint256 gasLast = gasleft();

        // handle payment
        uint256 received;
        if (_outToken == _ETH) {
            received = address(this).balance.sub(preBalance);
        } else {
            received = IERC20Ext(_outToken).balanceOf(address(this)).sub(
                preBalance
            );
        }

        _handlePayments(received, _outToken, gasStart, _user);

        // emit event
        emit LogExecSuccess(_id, tx.origin);
        //console.log("Gas Used in postExec: %s", gasLast.sub(gasleft()));
    }

    /// ################# VIEW ################
    function currentTaskId() public view returns (uint256) {
        return taskId;
    }

    function getGasPrice() public view returns (uint256) {
        uint256 oracleGasPrice = uint256(
            IChainlinkOracle(gelatoAS.gasPriceOracle()).latestAnswer()
        );

        // Use tx.gasprice capped by 1.3x Chainlink Oracle
        return
            tx.gasprice <= oracleGasPrice.mul(130).div(100)
                ? tx.gasprice
                : oracleGasPrice.mul(130).div(100);
    }

    function verifyTask(
        bytes memory _bytesBlob,
        uint256 _id,
        address _user
    ) public view returns (bool) {
        // Check whether order is valid
        bytes32 execTaskHash = hashTask(_bytesBlob, _id);
        return taskOwner[execTaskHash] == _user;
    }

    function executor() public view returns (address) {
        return gelatoAS.executorModule();
    }

    function serviceRegistry() public view returns (address) {
        return gelatoAS.serviceRegistry();
    }

    /// ############## INTERNAL ##############
    function _getGelatoFee(
        uint256 _gasStart,
        address _outToken,
        uint256 //_received, if gelato nodes get part of the %
    ) private view returns (uint256 gelatoFee) {
        uint256 gasFeeEth = _gasStart.sub(gasleft()).add(_gasOverhead).mul(
            getGasPrice()
        );

        // returns purely the ethereum tx fee
        (uint256 ethTxFee, ) = IOracleAggregator(gelatoAS.oracleAggregator())
            .getExpectedReturnAmount(gasFeeEth, _ETH, _outToken);

        // add 7% bps on top of Ethereum tx fee
        // gelatoFee = ethTxFee.add(_received.mul(7).div(10000));
        gelatoFee = ethTxFee;
    }

    function _handlePayments(
        uint256 _received,
        address _outToken,
        uint256 _gasStart,
        address _user
    ) private {
        // Get fee payable to Gelato
        uint256 txFee = _getGelatoFee(_gasStart, _outToken, _received);
        if (_outToken == _ETH) {
            // Pay Gelato
            tx.origin.call{value: txFee, gas: 2300}("");

            // Send remaining tokens to user
            uint256 userAmt = _received.sub(txFee);
            _user.call{value: userAmt, gas: 2300}("");
        } else {
            // Pay Gelato
            IERC20Ext(_outToken).safeTransfer(tx.origin, txFee);

            // Send remaining tokens to user
            IERC20Ext(_outToken).safeTransfer(_user, _received.sub(txFee));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

import {EnumerableSet} from "@openzeppelin/contracts/utils/EnumerableSet.sol";
import {IExecutorRegistry} from "../../interfaces/gelato/IExecutorRegistry.sol";
import {IBouncer} from "../../interfaces/gelato/IBouncer.sol";

/// @title ServiceRegistry
/// @notice Global Registry for all use cases that customers want to get executed
/// @notice Each Service must be accepted by at least one executor
/// @notice Executors will guarantee to execute a service
/// @notice Gov can incentivize certain Services with tokens and blacklist them
/// @notice This contract acts as the defacto subjective binding agreement between executors
/// and Service Sumbmittors, enforced by governance
/// @notice We can later add e.g. merkle proofs to facilated slashing if agreement was not upheld
/// @dev ToDo: Implement credit system
contract ServiceRegistry is IBouncer {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice governance address for the governance contract
    address public governance;
    address public pendingGovernance;
    IExecutorRegistry public executorRegistry;

    // Called by Customer
    mapping(address => bool) public useCaseRequested;

    // Called by Executors
    mapping(address => bool) public useCaseAccepted;
    mapping(address => EnumerableSet.AddressSet) internal executorsPerUseCase;

    // Called by gov
    mapping(address => bool) public useCaseIncentivized;
    mapping(address => bool) public useCaseBlacklisted;

    address[] public useCaseList;

    constructor(IExecutorRegistry _execModule) public {
        governance = msg.sender;
        executorRegistry = _execModule;
    }

    // ################ Callable by Users ################
    /// @dev Everyone can call this method and request a service to be executed
    function request(address _newService) external {
        require(
            !useCaseAccepted[_newService],
            "ServiceRegistry: Service already accepted"
        );
        require(
            !useCaseRequested[_newService],
            "ServiceRegistry: Service already requested"
        );
        useCaseRequested[_newService] = true;
    }

    // ################ Callable by Executors ################
    function accept(address _service) external {
        require(
            executorRegistry.isExecutor(msg.sender),
            "ServiceRegistry: acccept: !whitelisted executor"
        );
        require(
            useCaseRequested[_service],
            "ServiceRegistry: accept: service requested"
        );
        require(
            !useCaseBlacklisted[_service],
            "ServiceRegistry: accept: service blacklisted"
        );
        require(
            !useCaseAccepted[_service],
            "ServiceRegistry: accept: service already accepted"
        );

        if (executorsPerUseCase[_service].length() == 0) {
            useCaseAccepted[_service] = true;
        }
        executorsPerUseCase[_service].add(msg.sender);
    }

    // Individual Executor stops to serve a requested Service
    function stop(address _service) external {
        require(
            executorRegistry.isExecutor(msg.sender),
            "ServiceRegistry:stop: !whitelisted executor"
        );
        require(
            useCaseAccepted[_service],
            "ServiceRegistry:stop: service not accepted"
        );
        executorsPerUseCase[_service].remove(msg.sender);
        if (executorsPerUseCase[_service].length() == 0) {
            useCaseAccepted[_service] = false;
        }
    }

    // ################ Callable by Gov ################
    function startIncentives(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            !useCaseIncentivized[_service],
            "ServiceRegistry: Use Case already incentivized"
        );
        useCaseIncentivized[_service] = true;
    }

    function stopIncentives(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            useCaseIncentivized[_service],
            "ServiceRegistry: Use Case not incentivized"
        );
        useCaseIncentivized[_service] = false;
    }

    function blacklist(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            !useCaseBlacklisted[_service],
            "ServiceRegistry: Use Case already blacklisted"
        );
        useCaseBlacklisted[_service] = true;
    }

    function deblacklist(address _service) external {
        require(msg.sender == governance, "ServiceRegistry: Only gov");
        require(
            useCaseBlacklisted[_service],
            "ServiceRegistry: Use Case not blacklisted"
        );
        useCaseBlacklisted[_service] = false;
    }

    /**
     * @notice Allows governance to change executor module (for future upgradability)
     * @param _execModule new governance address to set
     */
    function setExexModule(IExecutorRegistry _execModule) external {
        require(msg.sender == governance, "setGovernance: Only gov");
        executorRegistry = _execModule;
    }

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: Only gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(
            msg.sender == pendingGovernance,
            "acceptGovernance: Only pendingGov"
        );
        governance = pendingGovernance;
    }

    // ### VIEW FUNCTIONS ###
    function useCases() external view returns (address[] memory) {
        return useCaseList;
    }

    /// @notice returns true of executor accepted to serve a certain service
    /// @dev Overrides IBouncer Contract
    function preExec(
        address _service,
        bytes calldata,
        address _executor
    ) external override {
        require(
            canExecutorExec(_service, _executor),
            "Service Registry: preExec: Failure"
        );
    }

    /// @notice returns true of executor accepted to serve a certain service
    /// @dev Overrides IBouncer Contract
    function postExec(
        address _service,
        bytes calldata,
        address _executor
    ) external override {}

    function canExecutorExec(address _service, address _executor)
        public
        view
        returns (bool)
    {
        return
            executorsPerUseCase[_service].contains(_executor) &&
            !useCaseBlacklisted[_service] &&
            executorRegistry.isExecutor(_executor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

contract TaskStorage {
    uint256 public taskId;
    mapping(bytes32 => address) public taskOwner;

    event LogTaskStored(
        uint256 indexed id,
        address indexed user,
        bytes32 indexed hash,
        bytes payload
    );
    event LogTaskRemoved(address indexed remover, bytes32 indexed taskHash);

    function _storeTask(bytes memory _bytesBlob, address _owner)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = taskId + 1;
        taskId = newTaskId;

        bytes32 taskHash = hashTask(_bytesBlob, taskId);
        taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskId, _owner, taskHash, _bytesBlob);
    }

    function _removeTask(
        bytes memory _bytesBlob,
        uint256 _taskId,
        address _owner
    ) internal {
        // Only address which created task can delete it
        bytes32 taskHash = hashTask(_bytesBlob, _taskId);
        address owner = taskOwner[taskHash];
        require(_owner == owner, "Task Storage: Only Owner can remove tasks");

        // delete task
        delete taskOwner[taskHash];
        emit LogTaskRemoved(msg.sender, taskHash);
    }

    function hashTask(bytes memory _bytesBlob, uint256 _taskId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_bytesBlob, _taskId));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

// import {
//   IERC20Ext,
//   SafeERC20
// } from "../../vendor/openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import {
//   SafeMath
// } from "../../vendor/openzeppelin/contracts/math/SafeMath.sol";
import {
    SafeERC20,
    SafeMath
} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20Ext} from "@kyber.network/utils-sc/contracts/IERC20Ext.sol";

import {
    ISmartWalletSwapImplementation
} from "../../interfaces/krystal/ISmartWalletSwapImplementation.sol";
import {
    IChainlinkOracle
} from "../../interfaces/chainlink/IChainlinkOracle.sol";
import {IOracleAggregator} from "../../interfaces/gelato/IOracleAggregator.sol";
import {ITaskStorage} from "../../interfaces/gelato/ITaskStorage.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/dapps/Uniswap/IUniswapV2Router02.sol";
import {ServicePostExecFee} from "../standards/ServicePostExecFee.sol";
// import "hardhat/console.sol";

contract GelatoKrystal is ServicePostExecFee {
    struct Order {
        address user;
        address inToken;
        address outToken;
        uint256 amountPerTrade;
        uint256 nTradesLeft;
        uint256 minSlippage;
        uint256 maxSlippage;
        uint256 delay;
        uint256 gasPriceCeil;
        uint256 lastExecutionTime;
    }

    bytes public constant HINT = "";
    uint256 public constant PLATFORM_FEE_BPS = 8;

    ISmartWalletSwapImplementation public immutable smartWalletSwap;
    IUniswapV2Router02 public immutable uniRouterV2;
    IUniswapV2Router02 public immutable sushiRouterV2;
    address payable public immutable platformWallet;

    event LogTaskSubmitted(uint256 indexed taskId, Order order);
    event LogTaskCanceled(uint256 indexed taskId, Order order);

    constructor(
        ISmartWalletSwapImplementation _smartWalletSwap,
        IUniswapV2Router02 _uniRouterV2,
        IUniswapV2Router02 _sushiRouterV2,
        address payable _platformWallet,
        address gelatoAddressStorage
    ) public ServicePostExecFee(gelatoAddressStorage) {
        smartWalletSwap = _smartWalletSwap;
        platformWallet = _platformWallet;
        uniRouterV2 = _uniRouterV2;
        sushiRouterV2 = _sushiRouterV2;
    }

    function submit(
        address inToken,
        address outToken,
        uint256 amountPerTrade,
        uint256 nTradesLeft,
        uint256 minSlippage,
        uint256 maxSlippage,
        uint256 delay,
        uint256 gasPriceCeil
    ) external payable {
        if (inToken == _ETH) {
            require(
                msg.value == amountPerTrade.mul(nTradesLeft),
                "GelatoKrystal: mismatching amount of ETH deposited"
            );
        }
        Order memory order = Order({
            user: msg.sender,
            inToken: inToken,
            outToken: outToken,
            amountPerTrade: amountPerTrade,
            nTradesLeft: nTradesLeft,
            minSlippage: minSlippage,
            maxSlippage: maxSlippage,
            delay: delay,
            gasPriceCeil: gasPriceCeil,
            lastExecutionTime: block.timestamp
        });

        // store order
        _storeOrder(order, msg.sender);
    }

    function cancel(Order calldata _order, uint256 _id) external {
        _removeTask(abi.encode(_order), _id, msg.sender);
        if (_order.inToken == _ETH) {
            uint256 refundAmount = _order.amountPerTrade.mul(
                _order.nTradesLeft
            );
            _order.user.call{value: refundAmount, gas: 2300}("");
        }

        emit LogTaskCanceled(_id, _order);
    }

    function execUniOrSushi(
        Order calldata _order,
        uint256 _id,
        address[] calldata _uniswapTradePath,
        bool isUni
    ) external gelatofy(_order.outToken, _order.user, abi.encode(_order), _id) {
        // action exec
        _actionUniOrSushi(_order, _uniswapTradePath, isUni);

        // task cycle logic
        if (_order.nTradesLeft > 0) _updateAndSubmitNextTask(_order);
    }

    function execKyber(Order calldata _order, uint256 _id)
        external
        gelatofy(_order.outToken, _order.user, abi.encode(_order), _id)
    {
        // action exec
        _actionKyber(_order);

        // task cycle logic
        if (_order.nTradesLeft > 0) _updateAndSubmitNextTask(_order);
    }

    function isTaskSubmitted(Order calldata _order, uint256 _id)
        external
        view
        returns (bool)
    {
        return verifyTask(abi.encode(_order), _id, _order.user);
    }

    function getMinReturn(Order memory _order)
        public
        view
        returns (uint256 minReturn)
    {
        // 4. Rate Check
        (uint256 idealReturn, ) = IOracleAggregator(gelatoAS.oracleAggregator())
            .getExpectedReturnAmount(
            _order.amountPerTrade,
            _order.inToken,
            _order.outToken
        );

        // check time (reverts if block.timestamp is below execTime)
        // solhint-disable-next-line not-rely-on-time
        uint256 timeSinceCanExec = block.timestamp.sub(
            _order.lastExecutionTime.add(_order.delay)
        );

        uint256 slippage;
        if (_order.minSlippage > timeSinceCanExec) {
            slippage = _order.minSlippage.sub(timeSinceCanExec);
        }

        if (_order.maxSlippage > slippage) {
            slippage = _order.maxSlippage;
        }

        minReturn = idealReturn.sub(idealReturn.mul(slippage).div(10000));
    }

    // ############# PRIVATE #############
    function _actionKyber(Order memory _order) private {
        //uint256 startGas = gasleft();
        (uint256 ethToSend, uint256 minReturn) = _preExec(_order);
        //console.log("Gas Used in getMinReturn: %s", startGas.sub(gasleft()));
        //startGas = gasleft();

        smartWalletSwap.swapKyber{value: ethToSend}(
            IERC20Ext(_order.inToken),
            IERC20Ext(_order.outToken),
            _order.amountPerTrade,
            minReturn.div(_order.amountPerTrade),
            address(this),
            PLATFORM_FEE_BPS,
            platformWallet,
            HINT,
            false
        );
        //console.log("Gas used in swapKyber: %s", startGas.sub(gasleft()));
    }

    function _actionUniOrSushi(
        Order memory _order,
        address[] memory _uniswapTradePath,
        bool _isUni
    ) private {
        //uint256 startGas = gasleft();
        (uint256 ethToSend, uint256 minReturn) = _preExec(_order);
        //console.log("Gas Used in getMinReturn: %s", startGas.sub(gasleft()));
        //startGas = gasleft();

        require(
            _order.inToken == _uniswapTradePath[0] &&
                _order.outToken ==
                _uniswapTradePath[_uniswapTradePath.length - 1],
            "GelatoKrystal: Uniswap trade path does not match order."
        );
        smartWalletSwap.swapUniswap{value: ethToSend}(
            _isUni ? uniRouterV2 : sushiRouterV2,
            _order.amountPerTrade,
            minReturn,
            _uniswapTradePath,
            address(this),
            PLATFORM_FEE_BPS,
            platformWallet,
            false,
            false
        );

        //console.log("Gas used in swapKyber: %s", startGas.sub(gasleft()));
    }

    function _preExec(Order memory _order)
        private
        returns (uint256 ethToSend, uint256 minReturn)
    {
        if (_order.inToken != _ETH) {
            IERC20Ext(_order.inToken).safeTransferFrom(
                _order.user,
                address(this),
                _order.amountPerTrade
            );
            IERC20Ext(_order.inToken).safeApprove(
                address(smartWalletSwap),
                _order.amountPerTrade
            );
        } else {
            ethToSend = _order.amountPerTrade;
        }
        //uint256 startGas = gasleft();
        minReturn = getMinReturn(_order);
    }

    function _updateAndSubmitNextTask(Order memory _order) private {
        // update next order
        _order.nTradesLeft = _order.nTradesLeft.sub(1);
        _order.lastExecutionTime = block.timestamp;

        _storeOrder(_order, _order.user);
    }

    function _storeOrder(Order memory _order, address _user) private {
        uint256 id = _storeTask(abi.encode(_order), _user);
        emit LogTaskSubmitted(id, _order);
    }

    // ############# Fallback #############
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
// solhint-disable-next-line
pragma solidity >=0.6.6;

interface IChainlinkOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.6;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IBouncer {
    function preExec(
        address _to,
        bytes calldata _data,
        address _executor
    ) external;

    function postExec(
        address _to,
        bytes calldata _data,
        address _executor
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.6;

interface IExecutorRegistry {
    function isExecutor(address _executor) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

/**
 * @dev Interface of the Oracle Aggregator Contract
 */
interface IOracleAggregator {
    function getExpectedReturnAmount(
        uint256 amount,
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (uint256 returnAmount, uint256 decimals);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

interface ITaskStorage {
    // Getters
    function taskId() external view returns (uint256);

    function taskOwner(bytes32 _taskHash) external view returns (address);

    // Setters
    function storeTask(bytes calldata _bytesBlob) external returns (uint256);

    function removeTask(bytes32 _taskHash) external;
}

pragma solidity 0.6.6;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

pragma solidity 0.6.6;

interface IAaveLendingPoolV1 {
    function deposit(
        address _reserve,
        uint256 _amount,
        uint16 _referralCode
    ) external payable;

    function borrow(
        address _reserve,
        uint256 _amount,
        uint256 _interestRateMode,
        uint16 _referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 _amount,
        address payable _onBehalfOf
    ) external payable;

    function core() external view returns (address);
}

interface IAToken {
    function redeem(uint256 _amount) external;
}

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./DataTypes.sol";
import "./IProtocolDataProvider.sol";

interface IAaveLendingPoolV2 {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);
}

pragma solidity 0.6.6;

interface ICompErc20 {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function underlying() external view returns (address);
}

interface ICompEth {
    function mint() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function repayBorrow() external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface IProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    function getAllReservesTokens() external view returns (TokenData[] memory);

    function getAllATokens() external view returns (TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

pragma solidity 0.6.6;

import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";
import "./IAaveLendingPoolV2.sol";
import "./IAaveLendingPoolV1.sol";
import "./IWeth.sol";
import "./ICompErc20.sol";

interface ISmartWalletLending {
    event ClaimedComp(
        address[] holders,
        ICompErc20[] cTokens,
        bool borrowers,
        bool suppliers
    );

    enum LendingPlatform {AAVE_V1, AAVE_V2, COMPOUND}

    function updateAaveLendingPoolData(
        IAaveLendingPoolV2 poolV2,
        IAaveLendingPoolV1 poolV1,
        uint16 referalCode,
        IWeth weth,
        IERC20Ext[] calldata tokens
    ) external;

    function updateCompoundData(
        address _comToken,
        address _cEth,
        address[] calldata _cTokens
    ) external;

    function depositTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount
    ) external;

    function withdrawFrom(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn
    ) external returns (uint256 returnedAmount);

    function repayBorrowTo(
        LendingPlatform platform,
        address payable onBehalfOf,
        IERC20Ext token,
        uint256 amount,
        uint256 payAmount,
        uint256 rateMode // only for aave v2
    ) external;

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers
    ) external;

    function getLendingToken(LendingPlatform platform, IERC20Ext token)
        external
        view
        returns (address);
}

pragma solidity ^0.6.6;

import "./ISmartWalletLending.sol";
import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";
import {IUniswapV2Router02} from "../dapps/Uniswap/IUniswapV2Router02.sol";

interface ISmartWalletSwapImplementation {
    event KyberTrade(
        address indexed trader,
        IERC20Ext indexed src,
        IERC20Ext indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        address recipient,
        uint256 platformFeeBps,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTrade(
        address indexed trader,
        address indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        address recipient,
        uint256 platformFeeBps,
        address platformWallet,
        bool feeInSrc,
        bool useGasToken,
        uint256 numGasBurns
    );

    event KyberTradeAndDeposit(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20Ext src,
        IERC20Ext indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 platformFeeBps,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTradeAndDeposit(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IUniswapV2Router02 indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 platformFeeBps,
        address platformWallet,
        bool useGasToken,
        uint256 numGasBurns
    );

    event WithdrawFromLending(
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn,
        uint256 actualReturnAmount,
        bool useGasToken,
        uint256 numGasBurns
    );

    event KyberTradeAndRepay(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IERC20Ext src,
        IERC20Ext indexed dest,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 payAmount,
        uint256 feeAndRateMode,
        address platformWallet,
        bytes hint,
        bool useGasToken,
        uint256 numGasBurns
    );

    event UniswapTradeAndRepay(
        address indexed trader,
        ISmartWalletLending.LendingPlatform indexed platform,
        IUniswapV2Router02 indexed router,
        address[] tradePath,
        uint256 srcAmount,
        uint256 destAmount,
        uint256 payAmount,
        uint256 feeAndRateMode,
        address platformWallet,
        bool useGasToken,
        uint256 numGasBurns
    );

    function getExpectedReturnKyber(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external view returns (uint256 destAmount, uint256 expectedRate);

    function getExpectedReturnUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        address[] calldata tradePath,
        uint256 platformFeeBps
    ) external view returns (uint256 destAmount, uint256 expectedRate);

    function swapKyber(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswap(
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        address payable recipient,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool feeInSrc,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapKyberAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 minConversionRate,
        uint256 platformFeeBps,
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswapAndDeposit(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 minDestAmount,
        address[] calldata tradePath,
        uint256 platformFeeBps,
        address payable platformWallet,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function withdrawFromLendingPlatform(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext token,
        uint256 amount,
        uint256 minReturn,
        bool useGasToken
    ) external returns (uint256 returnedAmount);

    function swapKyberAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 payAmount,
        uint256 feeAndRateMode, // in case aave v2, fee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
        address payable platformWallet,
        bytes calldata hint,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function swapUniswapAndRepay(
        ISmartWalletLending.LendingPlatform platform,
        IUniswapV2Router02 router,
        uint256 srcAmount,
        uint256 payAmount,
        address[] calldata tradePath,
        uint256 feeAndRateMode, // in case aave v2, fee: feeAndRateMode % BPS, rateMode: feeAndRateMode / BPS
        address payable platformWallet,
        bool useGasToken
    ) external payable returns (uint256 destAmount);

    function claimComp(
        address[] calldata holders,
        ICompErc20[] calldata cTokens,
        bool borrowers,
        bool suppliers,
        bool useGasToken
    ) external;

    function claimPlatformFees(
        address[] calldata plaftformWallets,
        IERC20Ext[] calldata tokens
    ) external;
}

pragma solidity 0.6.6;

import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";

interface IWeth is IERC20Ext {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}