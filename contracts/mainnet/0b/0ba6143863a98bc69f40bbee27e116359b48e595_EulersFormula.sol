// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

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

// File: contracts/IETradingNFT.sol

pragma solidity 0.6.12;

interface IETradingNFT {
    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external ;
	function totalSupply(uint256 _id) external view returns (uint256);
    function maxSupply(uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
}

// File: contracts/token/interfaces/IERC20Token.sol

pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function eulerBalances(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: contracts/token/utility/Utils.sol

pragma solidity 0.6.12;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: contracts/token/ERC20Token.sol

pragma solidity 0.6.12;




/**
  * @dev ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;


    string public override name;
    string public override symbol;
    uint8 public override decimals;
    uint256 public override totalSupply;
    mapping (address => uint256) public override eulerBalances;
    mapping (address => mapping (address => uint256)) public override allowance;

    /**
      * @dev triggered when tokens are transferred between wallets
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
      * @dev triggered when a wallet allows another wallet to transfer tokens from on its behalf
      *
      * @param _owner   wallet that approves the allowance
      * @param _spender wallet that receives the allowance
      * @param _value   allowance amount
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
      * @dev initializes a new ERC20Token instance
      *
      * @param _name        token name
      * @param _symbol      token symbol
      * @param _totalSupply total supply of token units
    */
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) public {
        // validate input
        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = _totalSupply;
        eulerBalances[msg.sender] = _totalSupply;
    }

    /**
      * @dev transfers tokens to a given address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_to)
        returns (bool)
    {
        eulerBalances[msg.sender] = eulerBalances[msg.sender].sub(_value);
        eulerBalances[_to] = eulerBalances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
      * @dev transfers tokens to a given address on behalf of another address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        virtual
        override
        validAddress(_from)
        validAddress(_to)
        returns (bool)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        eulerBalances[_from] = eulerBalances[_from].sub(_value);
        eulerBalances[_to] = eulerBalances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
      * @dev allows another account/contract to transfers tokens on behalf of the caller
      * throws on any error rather then return a false flag to minimize user errors
      *
      * also, to minimize the risk of the approve/transferFrom attack vector
      * (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
      * in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
      *
      * @param _spender approved address
      * @param _value   allowance amount
      *
      * @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        virtual
        override
        validAddress(_spender)
        returns (bool)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0, "ERR_INVALID_AMOUNT");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

// File: contracts/token/utility/interfaces/IOwned.sol

pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

// File: contracts/token/utility/interfaces/ITokenHolder.sol

pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
}

// File: contracts/token/utility/interfaces/IConverterAnchor.sol

pragma solidity 0.6.12;



/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned, ITokenHolder {
}

// File: contracts/token/interfaces/IEulerToken.sol

pragma solidity 0.6.12;




/*
    Euler Token interface
*/
interface IEulerToken is IConverterAnchor, IERC20Token {
    function disableTransfers(bool _disable) external;
    function issue(address _to, uint256 _amount) external;
    function destroy(address _from, uint256 _amount) external;
}

// File: contracts/token/utility/Owned.sol

pragma solidity 0.6.12;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // error message binary size optimization
    function _onlyOwner() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnerUpdate(owner, address(0));
        owner = address(0);
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public override onlyOwner {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts/token/utility/TokenHandler.sol

pragma solidity 0.6.12;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
      * @dev executes the ERC20 token's `approve` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _spender approved address
      * @param _value   allowance amount
    */
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
        (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_APPROVE_FAILED');
    }

    /**
      * @dev executes the ERC20 token's `transfer` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FAILED');
    }

    /**
      * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       (bool success, bytes memory data) = address(_token).call(abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ERR_TRANSFER_FROM_FAILED');
    }
}

// File: contracts/token/utility/TokenHolder.sol

pragma solidity 0.6.12;






/**
  * @dev We consider every contract to be a 'token holder' since it's currently not possible
  * for a contract to deny receiving tokens.
  *
  * The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
  * the owner to send tokens that were sent to the contract by mistake back to their sender.
  *
  * Note that we use the non standard ERC-20 interface which has no return value for transfer
  * in order to support both non standard as well as standard token contracts.
  * see https://github.com/ethereum/solidity/issues/4116
*/
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    /**
      * @dev withdraws tokens held by the contract and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        virtual
        override
        onlyOwner
        validAddress(address(_token))
        validAddress(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}

// File: contracts/token/EulerToken.sol

pragma solidity 0.6.12;





/**
  * @dev Euler Token
  *
  * 'Owned' is specified here for readability reasons
*/
contract EulerToken is IEulerToken, Owned, ERC20Token, TokenHolder {
    using SafeMath for uint256;

    bool public transfersEnabled = false;    // true if transfer/transferFrom are enabled, false otherwise

    /**
      * @dev triggered when the total supply is increased
      *
      * @param _amount  amount that gets added to the supply
    */
    event Issuance(uint256 _amount);

    /**
      * @dev triggered when the total supply is decreased
      *
      * @param _amount  amount that gets removed from the supply
    */
    event Destruction(uint256 _amount);

    /**
      * @dev initializes a new EulerToken instance
      *
      * @param _name       token name
      * @param _symbol     token short symbol, minimum 1 character
    */
    constructor(string memory _name, string memory _symbol)
        public
        ERC20Token(_name, _symbol, 0)
    {
    }

    // allows execution only when transfers are enabled
    modifier transfersAllowed {
        _transfersAllowed();
        _;
    }

    // error message binary size optimization
    function _transfersAllowed() internal view {
        require(transfersEnabled, "ERR_TRANSFERS_DISABLED");
    }

    /**
      * @dev disables/enables transfers
      * can only be called by the contract owner
      *
      * @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public override onlyOwner {
        transfersEnabled = !_disable;
    }

    /**
      * @dev increases the token supply and sends the new tokens to the given account
      * can only be called by the contract owner
      *
      * @param _to      account to receive the new amount
      * @param _amount  amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        override
        onlyOwner
        validAddress(_to)
    {
        totalSupply = totalSupply.add(_amount);
        eulerBalances[_to] = eulerBalances[_to].add(_amount);

        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
      * @dev removes tokens from the given account and decreases the token supply
      * can only be called by the contract owner
      *
      * @param _from    account to remove the amount from
      * @param _amount  amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public override onlyOwner {
        eulerBalances[_from] = eulerBalances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra functionality

    /**
      * @dev send coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    /**
      * @dev an account/contract attempts to get the coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        override(IERC20Token, ERC20Token)
        transfersAllowed
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: contracts/EulersFormula.sol

pragma solidity 0.6.12;







interface IMigratorEulersFormula {
    // Perform LP token migration from legacy UniswapV2 to ESwap.
    // Take the current LP token address and return the new LP token address.
    // Migrator should have full access to the caller's LP token.
    // Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // ESwap must mint EXACTLY the same amount of ESwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

/**
Copyright 2020 PoolTogether Inc.
This file is part of PoolTogether.
PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.
PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

/**
 * @author Brendan Asselstine
 * @notice A library that uses entropy to select a random number within a bound.  Compensates for modulo bias.
 * @dev Thanks to https://medium.com/hownetworks/dont-waste-cycles-with-modulo-bias-35b6fdafcf94
 */
library UniformRandomNumber {
  /// @notice Select a random number without modulo bias using a random seed and upper bound
  /// @param _entropy The seed for randomness
  /// @param _upperBound The upper bound of the desired number
  /// @return A random number less than the _upperBound
  function uniform(uint256 _entropy, uint256 _upperBound) internal pure returns (uint256) {
    require(_upperBound > 0, "UniformRand/min-bound");
    uint256 min = -_upperBound % _upperBound;
    uint256 random = _entropy;
    while (true) {
      if (random >= min) {
        break;
      }
      random = uint256(keccak256(abi.encodePacked(random)));
    }
    return random % _upperBound;
  }
}

contract Formula is EulerToken("Euler's Formula", "EULER") {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Airdrop list
    address[] public airdropList;
    // Only deposit user can get airdrop.
    mapping(address => bool) addressAvailable;
    mapping(address => bool) addressAvailableHistory;

    // Claimable enft of user.
    struct UserEnftInfo {
        uint256 amount;
    }
    // Info of each user that claimable enft.
    mapping (address => mapping (uint256 => UserEnftInfo)) public userEnftInfo;

    // Info of each enft.
    struct EnftInfo {
        uint256 enftID;            // Enft's ID. 
        uint256 amount;            // Distribution amount.
        uint256 fixedPrice;        // Claim the enft need pay some wETH.
    }
    // Info of each enft.
    EnftInfo[] public enftInfo;
    // Total enft amount.
    uint256 public totalEnftAmount = 0;
    // Original total enft amount.
    uint256 public originalTotalEnftAmount = 0;
    // Draw Fusion
    uint256 public eulersFused = 1000 * (10 ** 18);
    // Base number
    uint256 public base = 10 ** 6;
    // Claim fee is 3%.
    // Pool's fee 1%. Artist's fee 2%.
    uint256 public totalFee = 3 * (base) / 100;

    // Enft token.
    IETradingNFT ETradingNFT;

    event Reward(address indexed user, uint256 indexed enftID);
    event AirDrop(address indexed user, uint256 indexed enftID);

    function enftLength() public view returns (uint256) {
        return enftInfo.length;
    }

    function eulerBalanceOf(address tokenOwner) public view returns (uint256) {
        return eulerBalances[tokenOwner];
    }

    function userEnftBalanceOf(address tokenOwner, uint256 _enftID) public view returns (uint256) {
        return userEnftInfo[tokenOwner][_enftID].amount;
    }

    function userUnclaimEnft(address tokenOwner) public view returns (uint256[] memory) {
        uint256[] memory userEnft = new uint256[](enftInfo.length);
        for(uint i = 0; i < enftInfo.length; i++) {
            userEnft[i] = userEnftInfo[tokenOwner][i].amount;
        }
        return userEnft;
    }

    function enftBalanceOf(uint256 _enftID) public view returns (uint256) {
        return enftInfo[_enftID].amount;
    }

    // Set setEulersFused. Can only be called by the owner.
    function setEulersFused(uint256 _newEulersFused) public onlyOwner {
        eulersFused = _newEulersFused;
    }

    // Set setTotalFee. Can only be called by the owner.
    function setTotalFee(uint256 _newTotalFee) public onlyOwner {
        totalFee = _newTotalFee;
    }

    // Add a new enft. Can only be called by the owner.
    function addEnft(uint256 _enftID, uint256 _amount, uint256 _fixedPrice) external onlyOwner {
        require(_amount.add(ETradingNFT.totalSupply(_enftID)) <= ETradingNFT.maxSupply(_enftID), "Max supply reached");
        totalEnftAmount = totalEnftAmount.add(_amount);
        originalTotalEnftAmount = originalTotalEnftAmount.add(_amount);
        enftInfo.push(EnftInfo({
            enftID: _enftID,
            amount: _amount,
            fixedPrice: _fixedPrice
        }));
    }

    // Update enft.
    // It's always decrease.
    function _updateEnft(uint256 _wid, uint256 amount) internal {
        EnftInfo storage enft = enftInfo[_wid];
        enft.amount = enft.amount.sub(amount);
        totalEnftAmount = totalEnftAmount.sub(amount);
    }

    // Update user enft
    function _addUserEnft(address user, uint256 _wid, uint256 amount) internal {
        UserEnftInfo storage userEnft = userEnftInfo[user][_wid];
        userEnft.amount = userEnft.amount.add(amount);
    }
    function _removeUserEnft(address user, uint256 _wid, uint256 amount) internal {
        UserEnftInfo storage userEnft = userEnftInfo[user][_wid];
        userEnft.amount = userEnft.amount.sub(amount);
    }

    // Draw main function
    function _draw() internal view returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(now, block.difficulty, msg.sender)));
        uint256 rnd = UniformRandomNumber.uniform(seed, totalEnftAmount);
        // Sort by rarity. Avoid gas attacks, start from the tail.
        for(uint i = enftInfo.length - 1; i > 0; --i){
            if(rnd < enftInfo[i].amount){
                return i;
            }
            rnd = rnd - enftInfo[i].amount;
        }
        // should not happen.
        return uint256(-1);
    }

    // Draw a enft
    function draw() external {
        // EOA only
        require(msg.sender == tx.origin);

        require(eulerBalances[msg.sender] >= eulersFused, "Eulers are not enough.");
        eulerBalances[msg.sender] = eulerBalances[msg.sender].sub(eulersFused);

        uint256 _rwid = _draw();
        // Reward reduced
        _updateEnft(_rwid, 1);
        _addUserEnft(msg.sender, _rwid, 1);

        emit Reward(msg.sender, _rwid);
    }

    // Airdrop by owner
    function airDrop() external onlyOwner {

        uint256 _rwid = _draw();
        // Reward reduced
        _updateEnft(_rwid, 1);

        uint256 seed = uint256(keccak256(abi.encodePacked(now, _rwid)));
        bool status = false;
        uint256 rnd = 0;

        while (!status) {
            rnd = UniformRandomNumber.uniform(seed, airdropList.length);
            status = addressAvailable[airdropList[rnd]];
            seed = uint256(keccak256(abi.encodePacked(seed, rnd)));
        }

        _addUserEnft(airdropList[rnd], _rwid, 1);
        emit AirDrop(airdropList[rnd], _rwid);
    }

    // Airdrop by user
    function airDropByUser() external {

        // EOA only
        require(msg.sender == tx.origin);

        require(eulerBalances[msg.sender] >= eulersFused, "Eulers are not enough.");
        eulerBalances[msg.sender] = eulerBalances[msg.sender].sub(eulersFused);
        
        uint256 _rwid = _draw();
        // Reward reduced
        _updateEnft(_rwid, 1);

        uint256 seed = uint256(keccak256(abi.encodePacked(now, _rwid)));
        bool status = false;
        uint256 rnd = 0;

        while (!status) {
            rnd = UniformRandomNumber.uniform(seed, airdropList.length);
            status = addressAvailable[airdropList[rnd]];
            seed = uint256(keccak256(abi.encodePacked(seed, rnd)));
        }

        _addUserEnft(airdropList[rnd], _rwid, 1);
        emit AirDrop(airdropList[rnd], _rwid);
    }

    // pool's fee & artist's fee
    function withdrawFee() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    // Compute claim fee.
    function claimFee(uint256 _wid, uint256 amount) public view returns (uint256){
        EnftInfo storage enft = enftInfo[_wid];
        return amount * enft.fixedPrice * (totalFee) / (base);
    }

    // User claim enft.
    function claim(uint256 _wid, uint256 amount) external payable {
        UserEnftInfo storage userEnft = userEnftInfo[msg.sender][_wid];
        require(amount > 0, "amount must not zero");
        require(userEnft.amount >= amount, "amount is bad");
        require(msg.value == claimFee(_wid, amount), "need payout claim fee");

        _removeUserEnft(msg.sender, _wid, amount);
        ETradingNFT.mint(msg.sender, _wid, amount, "");
    }
}


contract EulersFormula is Formula {
    // Info of each user.
    struct UserLPInfo {
        uint256 amount;       // How many LP tokens the user has provided.
        uint256 rewardEULER; // Reward euler. 
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;            // Address of LP token contract.
        uint256 allocPoint;        // How many allocation points assigned to this pool. EULERs to distribute per block.
        uint256 lastRewardBlock;   // Last block number that EULERs distribution occurs.
        uint256 accEULERPerShare; // Accumulated EULERs per share, times 1e12. See below.
    }
    // Dev address.
    address public devaddr;
    // Block number when bonus EARN period ends.
    uint256 public bonusEndBlock;
    // EULER tokens created per block.
    uint256 public eulerPerBlock = 3141592653589793238; //18 decimals
    // Bonus muliplier for early euler seekers.
    uint256 public bonusMultiplier = 2718281828459045235; //18 decimals
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorEulersFormula public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserLPInfo)) public userLPInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when EULER mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IETradingNFT _ETradingNFT,
        address _devaddr,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        ETradingNFT = _ETradingNFT;
        devaddr = _devaddr;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        enftInfo.push(EnftInfo({
            enftID: 0,
            amount: 0,
            fixedPrice: 0
        }));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accEULERPerShare: 0
        }));
    }

    // Update the given pool's Eulers allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set eulerPerBlock. Can only be called by the owner.
    function setEULERPerBlock(uint256 _eulerPerBlock) public onlyOwner {
        eulerPerBlock = _eulerPerBlock;
    }

    // Set startBlock. Can only be called by the owner.
    function setStartBlock(uint256 _startBlock) public onlyOwner {
        startBlock = _startBlock;
    }

    // Set bonusEndBlock. Can only be called by the owner.
    function setBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        bonusEndBlock = _bonusEndBlock;
    }

    // Set bonusMultiplier. Can only be called by the owner.
    function setBonusMultiplier(uint256 _bonusMultiplier) public onlyOwner {
        bonusMultiplier = _bonusMultiplier;
    }

    // Set newLpToken. Can only be called by the owner.
    function setNewLpToken(uint _pid, IERC20 _newLpToken) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.lpToken = _newLpToken;
    }

    // Set newAllocPoint. Can only be called by the owner.
    function setNewAllocPoint(uint _pid, uint256 _newAllocPoint) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.allocPoint = _newAllocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorEulersFormula _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can only be called by the owner. We trust that migrator contract is good.
    function migrate(uint256 _pid) public onlyOwner {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        //check balance equivalence on Migrator side
        //require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(bonusMultiplier).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending Eulers on frontend.
    function pendingEULER(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][_user];
        uint256 accEULERPerShare = pool.accEULERPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 eulerReward = multiplier.mul(eulerPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(1e18);
            accEULERPerShare = accEULERPerShare.add(eulerReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accEULERPerShare).div(1e12).sub(user.rewardEULER);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 eulerReward = multiplier.mul(eulerPerBlock).mul(pool.allocPoint).div(totalAllocPoint).div(1e18);
        issue(devaddr, eulerReward);
        issue(address(this), eulerReward);
        pool.accEULERPerShare = pool.accEULERPerShare.add(eulerReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Formula for EULER allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        // EOA only
        require(msg.sender == tx.origin);

        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accEULERPerShare).div(1e12).sub(user.rewardEULER);
            if(pending > 0) {
                safeEulerTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardEULER = user.amount.mul(pool.accEULERPerShare).div(1e12);
        if (user.amount > 0){
            addressAvailable[msg.sender] = true;
            if(!addressAvailableHistory[msg.sender]){
                addressAvailableHistory[msg.sender] = true;
                airdropList.push(msg.sender);
            }
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Formula.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accEULERPerShare).div(1e12).sub(user.rewardEULER);
        if(pending > 0) {
            safeEulerTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
        user.amount = user.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardEULER = user.amount.mul(pool.accEULERPerShare).div(1e12);
        if (user.amount == 0){
            addressAvailable[msg.sender] = false;
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserLPInfo storage user = userLPInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardEULER = 0;
        addressAvailable[msg.sender] = false;
    }

    // Safe euler transfer function, just in case if rounding error causes pool to not have enough EULERs.
    function safeEulerTransfer(address _to, uint256 _amount) internal {
        uint256 eulerBal = eulerBalanceOf(address(this));
        if (_amount > eulerBal) {
            transfer(_to, eulerBal);
        } else {
            transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}