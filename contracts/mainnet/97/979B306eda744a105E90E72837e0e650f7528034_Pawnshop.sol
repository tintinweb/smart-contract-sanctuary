/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.7.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.7.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [// importANT]
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
     * // importANT: because control is transferred to `recipient`, care must be
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


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


// pragma solidity ^0.7.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// pragma solidity ^0.7.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


// Dependency file: @openzeppelin/contracts/utils/EnumerableSet.sol


// pragma solidity ^0.7.0;

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


// Dependency file: contracts/model/StoredOfferModel.sol


// pragma solidity 0.7.3;

abstract contract StoredOfferModel {

    // The order of fields in this struct is optimised to use the fewest storage slots
    struct StoredOffer {
        uint32 nonce;
        uint32 timelockPeriod;
        address loanTokenAddress;
        address itemTokenAddress;
        uint256 itemTokenId;
        uint256 itemValue;
        uint256 redemptionPrice;
    }
}


// Dependency file: contracts/utils/FractionMath.sol


// pragma solidity 0.7.3;

// import "@openzeppelin/contracts/math/SafeMath.sol";

library FractionMath {
    using SafeMath for uint256;

    struct Fraction {
        uint48 numerator;
        uint48 denominator;
    }

    function sanitize(Fraction calldata fraction) internal pure returns (Fraction calldata) {
        require(fraction.denominator > 0, "FractionMath: denominator must be greater than zero");
        return fraction;
    }

    function mul(Fraction storage fraction, uint256 value) internal view returns (uint256) {
        return value.mul(fraction.numerator).div(fraction.denominator);
    }
}


// Dependency file: contracts/model/LoanModel.sol


// pragma solidity 0.7.3;

// import "contracts/model/StoredOfferModel.sol";
// import "contracts/utils/FractionMath.sol";

abstract contract LoanModel is StoredOfferModel {
    enum LoanStatus {
        TAKEN,
        RETURNED,
        CLAIMED
    }

    // The order of fields in this struct is optimised to use the fewest storage slots
    struct Loan {
        StoredOffer offer;
        LoanStatus status;
        address borrowerAddress;
        address lenderAddress;
        uint48 redemptionFeeNumerator;
        uint48 redemptionFeeDenominator;
        uint256 timestamp;
    }
}


// Dependency file: contracts/model/StakingModel.sol


// pragma solidity 0.7.3;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For deeper understanding of the meaning of StakingState fields refer to `docs/PawnshopStaking.md` document

abstract contract StakingModel {
    struct StakingState {
        IERC20 token;
        uint256 totalClaimedRewards; // total amount of rewards already transferred to the stakers
        uint256 totalRewards; // total amount of rewards collected
        uint256 cRPT; // cumulative reward per token
        mapping(address => uint256) alreadyPaidCRPT; // cumulative reward per token already "paid" to the staker
        mapping(address => uint256) claimableReward; // the amount of rewards that can be withdrawn from the contract by the staker
    }
}


// Dependency file: contracts/handlers/IHandler.sol


// pragma solidity 0.7.3;

interface IHandler {
    function supportToken(address token) external;

    function stopSupportingToken(address token) external;

    function isSupported(address token) external view returns (bool);

    function deposit(address from, address token, uint256 tokenId) external;

    function withdraw(address recipient, address token, uint256 tokenId) external;

    function changeOwnership(address recipient, address token, uint256 tokenId) external;

    function ownerOf(address token, uint256 tokenId) external view returns (address);

    function depositTimestamp(address tokenContract, uint256 tokenId) external view returns (uint256);
}


// Dependency file: contracts/utils/EnumerableMap.sol


// pragma solidity 0.7.3;

/**
 * This library was copied from OpenZeppelin's EnumerableMap.sol and adjusted to our needs.
 * The only changes made are:
 * - change // pragma solidity to 0.7.3
 * - change UintToAddressMap to AddressToAddressMap by renaming and adjusting methods
 * - add SupportState enum declaration
 * - clone AddressToAddressMap and change it to AddressToSupportStateMap by renaming and adjusting methods
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // AddressToAddressMap

    struct AddressToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToAddressMap storage map, address key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(key)), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToAddressMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToAddressMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressToAddressMap storage map, uint256 index) internal view returns (address, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint256(key)), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToAddressMap storage map, address key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(uint256(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(AddressToAddressMap storage map, address key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(uint256(key)), errorMessage)));
    }


    // AddressToSupportStateMap

    struct AddressToSupportStateMap {
        Map _inner;
    }

    enum SupportState {
        UNSUPPORTED,
        SUPPORTED,
        SUPPORT_STOPPED
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToSupportStateMap storage map, address key, SupportState value) internal returns (bool) {
        return _set(map._inner, bytes32(uint256(key)), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToSupportStateMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToSupportStateMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, bytes32(uint256(key)));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToSupportStateMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToSupportStateMap storage map, uint256 index) internal view returns (address, SupportState) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (address(uint256(key)), SupportState(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToSupportStateMap storage map, address key) internal view returns (SupportState) {
        return SupportState(uint256(_get(map._inner, bytes32(uint256(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(AddressToSupportStateMap storage map, address key, string memory errorMessage) internal view returns (SupportState) {
        return SupportState(uint256(_get(map._inner, bytes32(uint256(key)), errorMessage)));
    }
}


// Dependency file: contracts/PawnshopStorage.sol


// pragma solidity 0.7.3;

// import "@openzeppelin/contracts/utils/EnumerableSet.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "contracts/model/LoanModel.sol";
// import "contracts/model/StakingModel.sol";
// import "contracts/handlers/IHandler.sol";
// import "contracts/utils/EnumerableMap.sol";
// import "contracts/utils/FractionMath.sol";

abstract contract PawnshopStorage is LoanModel, StakingModel {
    // Initializable.sol
    bool internal _initialized;
    bool internal _initializing;

    // Ownable.sol
    address internal _owner;

    // ReentrancyGuard.sol
    uint256 internal _guardStatus;

    // Pawnshop.sol
    mapping (bytes32 => Loan) internal _loans;
    mapping (bytes32 => bool) internal _usedOfferSignatures;

    // PawnshopConfig.sol
    uint256 internal _maxTimelockPeriod;
    EnumerableMap.AddressToAddressMap internal _tokenAddressToHandlerAddress;
    EnumerableMap.AddressToSupportStateMap internal _loanTokens;
    mapping (address => FractionMath.Fraction) internal _minLenderProfits;
    mapping (address => FractionMath.Fraction) internal _depositFees;
    mapping (address => FractionMath.Fraction) internal _redemptionFees;
    mapping (address => FractionMath.Fraction) internal _flashFees;

    // PawnshopStaking.sol
    IERC20 internal _stakingToken;
    mapping(address => uint256) internal _staked;
    uint256 internal _totalStaked;
    mapping(address => StakingState) internal _stakingStates;

    // EIP712Domain.sol
    bytes32 internal DOMAIN_SEPARATOR; // solhint-disable-line var-name-mixedcase
}


// Dependency file: contracts/Initializable.sol


// pragma solidity 0.7.3;

// import "contracts/PawnshopStorage.sol";

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable is PawnshopStorage {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    // bool _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    // bool _initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(_initializing || isConstructor() || !_initialized, "Contract instance has already been initialized");

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
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            cs := extcodesize(self)
        }
        return cs == 0;
    }
}


// Dependency file: contracts/Ownable.sol


// pragma solidity 0.7.3;

// import "contracts/PawnshopStorage.sol";
// import "contracts/Initializable.sol";

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
contract Ownable is PawnshopStorage, Initializable {
    // address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Ownable_init_unchained(address owner) internal initializer {
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: contracts/ReentrancyGuard.sol


// pragma solidity 0.7.3;

// import "contracts/PawnshopStorage.sol";
// import "contracts/Initializable.sol";

abstract contract ReentrancyGuard is PawnshopStorage, Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // uint256 _guardStatus;

    // solhint-disable-next-line func-name-mixedcase
    function __ReentrancyGuard_init_unchained() internal initializer {
        _guardStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_guardStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        _guardStatus = _ENTERED;
        _;
        _guardStatus = _NOT_ENTERED;
    }
}


// Dependency file: contracts/PawnshopConfig.sol


// pragma solidity 0.7.3;
// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/EnumerableSet.sol";

// import "contracts/PawnshopStorage.sol";
// import "contracts/Initializable.sol";
// import "contracts/Ownable.sol";
// import "contracts/utils/EnumerableMap.sol";
// import "contracts/utils/FractionMath.sol";

abstract contract PawnshopConfig is PawnshopStorage, Ownable {
    using SafeMath for uint256;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;
    using EnumerableMap for EnumerableMap.AddressToSupportStateMap;
    using FractionMath for FractionMath.Fraction;

    // uint256 _maxTimelockPeriod;
    // EnumerableMap.AddressToAddressMap _tokenAddressToHandlerAddress;
    // EnumerableMap.AddressToSupportStateMap _loanTokens;
    // mapping (address => FractionMath.Fraction) _minLenderProfits;
    // mapping (address => FractionMath.Fraction) _depositFees;
    // mapping (address => FractionMath.Fraction) _redemptionFees;
    // mapping (address => FractionMath.Fraction) _flashFees;

    event MaxTimelockPeriodSet(uint256 indexed time);
    event MinLenderProfitSet(address indexed loanTokenAddress, FractionMath.Fraction minProfit);
    event PawnshopFeesSet(
        address indexed loanTokenAddress,
        FractionMath.Fraction depositFee,
        FractionMath.Fraction redemptionFee,
        FractionMath.Fraction flashFee
    );
    event ItemSupported(address indexed tokenAddress);
    event LoanTokenSupported(address indexed tokenAddress);
    event ItemSupportStopped(address indexed tokenAddress);
    event LoanTokenSupportStopped(address indexed tokenAddress);

    function setMaxTimelockPeriod(uint256 time) external onlyOwner {
        _setMaxTimelockPeriod(time);
    }

    function _setMaxTimelockPeriod(uint256 time) internal {
        require(time > 0, "Pawnshop: the max timelock period must be greater than 0");
        _maxTimelockPeriod = time;
        emit MaxTimelockPeriodSet(time);
    }

    function setMinLenderProfit(address loanTokenAddress, FractionMath.Fraction calldata minProfit) public onlyOwner {
        require(isLoanTokenSupported(loanTokenAddress), "Pawnshop: the loan token is not supported");
        _minLenderProfits[loanTokenAddress] = FractionMath.sanitize(minProfit);

        emit MinLenderProfitSet(loanTokenAddress, minProfit);
    }

    function setPawnshopFees(
        address loanTokenAddress,
        FractionMath.Fraction calldata depositFee,
        FractionMath.Fraction calldata redemptionFee,
        FractionMath.Fraction calldata flashFee
    ) public onlyOwner {
        require(isLoanTokenSupported(loanTokenAddress), "Pawnshop: the loan token is not supported");
        _depositFees[loanTokenAddress] = FractionMath.sanitize(depositFee);
        _redemptionFees[loanTokenAddress] = FractionMath.sanitize(redemptionFee);
        _flashFees[loanTokenAddress] = FractionMath.sanitize(flashFee);

        emit PawnshopFeesSet(
            loanTokenAddress,
            depositFee,
            redemptionFee,
            flashFee
        );
    }

    function supportItem(IHandler handler, address tokenAddress) external onlyOwner {
        require(!handler.isSupported(tokenAddress), "Pawnshop: the item is already supported");
        handler.supportToken(tokenAddress);
        _tokenAddressToHandlerAddress.set(tokenAddress, address(handler));
        emit ItemSupported(tokenAddress);
    }

    function supportLoanToken(
        address tokenAddress,
        FractionMath.Fraction calldata minProfit,
        FractionMath.Fraction calldata depositFee,
        FractionMath.Fraction calldata redemptionFee,
        FractionMath.Fraction calldata flashFee
    ) external onlyOwner {
        require(!isLoanTokenSupported(tokenAddress), "Pawnshop: the ERC20 loan token is already supported");
        require(tokenAddress != address(_stakingToken), "Pawnshop: cannot support the staking token");
        _loanTokens.set(tokenAddress, EnumerableMap.SupportState.SUPPORTED);
        StakingState storage newStakingState = _stakingStates[tokenAddress];
        newStakingState.token = IERC20(tokenAddress);
        setMinLenderProfit(tokenAddress, minProfit);
        setPawnshopFees(tokenAddress, depositFee, redemptionFee, flashFee);
        emit LoanTokenSupported(tokenAddress);
    }

    function stopSupportingItem(address tokenAddress) external onlyOwner {
        IHandler handler = itemHandler(tokenAddress);
        handler.stopSupportingToken(tokenAddress);
        emit ItemSupportStopped(tokenAddress);
    }

    function stopSupportingLoanToken(address tokenAddress) external onlyOwner {
        require(isLoanTokenSupported(tokenAddress), "Pawnshop: the ERC20 loan token is not supported");
        _loanTokens.set(tokenAddress, EnumerableMap.SupportState.SUPPORT_STOPPED);
        emit LoanTokenSupportStopped(tokenAddress);
    }

    function isLoanTokenSupported(address tokenAddress) public view returns (bool) {
        return _loanTokens.contains(tokenAddress) &&
            _loanTokens.get(tokenAddress) == EnumerableMap.SupportState.SUPPORTED;
    }

    function wasLoanTokenEverSupported(address tokenAddress) public view returns (bool) {
        return _loanTokens.contains(tokenAddress);
    }

    function isItemTokenSupported(address tokenAddress) external view returns (bool) {
        if (!_tokenAddressToHandlerAddress.contains(tokenAddress)) {
            return false;
        }
        address handler = _tokenAddressToHandlerAddress.get(tokenAddress);
        return IHandler(handler).isSupported(tokenAddress);
    }

    function totalItemTokens() external view returns (uint256) {
        return _tokenAddressToHandlerAddress.length();
    }

    function itemTokenByIndex(uint256 index) external view returns (address tokenAddress, address handlerAddress, bool isCurrentlySupported) {
        (tokenAddress, handlerAddress) = _tokenAddressToHandlerAddress.at(index);
        isCurrentlySupported = IHandler(handlerAddress).isSupported(tokenAddress);
    }

    function maxTimelockPeriod() external view returns (uint256) {
        return _maxTimelockPeriod;
    }

    function minLenderProfit(address loanTokenAddress) external view returns (FractionMath.Fraction memory) {
        return _minLenderProfits[loanTokenAddress];
    }

    function depositFee(address loanTokenAddress) external view returns (FractionMath.Fraction memory) {
        return _depositFees[loanTokenAddress];
    }

    function redemptionFee(address loanTokenAddress) external view returns (FractionMath.Fraction memory) {
        return _redemptionFees[loanTokenAddress];
    }

    function flashFee(address loanTokenAddress) external view returns (FractionMath.Fraction memory) {
        return _flashFees[loanTokenAddress];
    }

    function totalLoanTokens() external view returns (uint256) {
        return _loanTokens.length();
    }

    function loanTokenByIndex(uint256 index) external view returns (address, EnumerableMap.SupportState) {
        return _loanTokens.at(index);
    }

    function itemHandler(address itemTokenAddress) public view returns (IHandler) {
        return IHandler(_tokenAddressToHandlerAddress.get(itemTokenAddress, "Pawnshop: the item is not supported"));
    }

    function minReturnAmount(address loanTokenAddress, uint256 loanAmount) public view returns (uint256) {
        FractionMath.Fraction storage minProfit = _minLenderProfits[loanTokenAddress];
        uint256 lenderProfit = minProfit.mul(loanAmount);
        return loanAmount.add(lenderProfit);
    }
}


// Dependency file: contracts/PawnshopStaking.sol


// pragma solidity 0.7.3;
// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// import "contracts/PawnshopStorage.sol";
// import "contracts/PawnshopConfig.sol";
// import "contracts/model/StakingModel.sol";
// import "contracts/utils/EnumerableMap.sol";


abstract contract PawnshopStaking is StakingModel, PawnshopStorage, PawnshopConfig {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableMap for EnumerableMap.AddressToSupportStateMap;

    uint256 private constant PRECISION = 1e30;

    // IERC20 _stakingToken;
    // mapping(address => uint256) _staked;
    // uint256 _totalStaked;
    // mapping(address => StakingState) _stakingStates;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardClaimed(address indexed staker, address indexed token, uint256 amount);

    // solhint-disable-next-line func-name-mixedcase
    function __PawnshopStaking_init_unchained(IERC20 stakingToken) internal initializer {
        _stakingToken = stakingToken;
    }

    function stake(uint256 amount) external {
        if (_totalStaked > 0) {
            _updateRewards();
        }
        _staked[msg.sender] = _staked[msg.sender].add(amount);
        _totalStaked = _totalStaked.add(amount);
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        require(amount <= _staked[msg.sender], "PawnshopStaking: cannot unstake more than was staked");
        _updateRewards();
        _staked[msg.sender] = _staked[msg.sender].sub(amount);
        _totalStaked = _totalStaked.sub(amount);
        _stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function claimRewards() external {
        uint256 loanTokensCount = _loanTokens.length();
        for (uint256 i = 0; i < loanTokensCount; i++) {
            (address loanToken,) = _loanTokens.at(i);
            StakingState storage state = _stakingStates[loanToken];
            if (_totalStaked > 0) {
                _updateSingleTokenRewards(state);
            }
            _transferReward(state);
        }
    }

    function emergencyStakeRecovery() external onlyOwner {
        uint256 balance = _stakingToken.balanceOf(address(this));
        uint256 recoveryAmount = balance.sub(_totalStaked);
        require(recoveryAmount > 0, "PawnshopStaking: there are no additional staking tokens for recovery in the contract");
        _stakingToken.safeTransfer(msg.sender, recoveryAmount);
    }

    function _updateRewards() private {
        uint256 loanTokensCount = _loanTokens.length();
        for (uint256 i = 0; i < loanTokensCount; i++) {
            (address loanToken,) = _loanTokens.at(i);
            _updateSingleTokenRewards(_stakingStates[loanToken]);
        }
    }

    function _updateSingleTokenRewards(StakingState storage state) private {
        uint256 newTotalRewards = _calculateNewTotalRewards(state);
        uint256 newCRPT = _calculateNewCRPT(state, newTotalRewards);
        state.claimableReward[msg.sender] = _calculateNewClaimableReward(state, newCRPT, msg.sender);
        state.alreadyPaidCRPT[msg.sender] = newCRPT;
        state.cRPT = newCRPT;
        state.totalRewards = newTotalRewards;
    }

    function _calculateNewTotalRewards(StakingState storage state) private view returns (uint256) {
        uint256 currentLoanTokenBalance = state.token.balanceOf(address(this));
        return currentLoanTokenBalance.add(state.totalClaimedRewards);
    }

    function _calculateNewCRPT(StakingState storage state, uint256 newTotalRewards) private view returns (uint256) {
        uint256 newRewards = newTotalRewards.sub(state.totalRewards);
        uint256 rewardPerToken = newRewards.mul(PRECISION).div(_totalStaked);
        return state.cRPT.add(rewardPerToken);
    }

    function _calculateNewClaimableReward(StakingState storage state, uint256 newCRPT, address staker) private view returns (uint256) {
        uint256 stakerCRPT = newCRPT.sub(state.alreadyPaidCRPT[staker]);
        uint256 stakerCurrentlyClaimableReward = _staked[staker].mul(stakerCRPT).div(PRECISION);
        return state.claimableReward[staker].add(stakerCurrentlyClaimableReward);
    }

    function _transferReward(StakingState storage state) private {
        uint256 rewardToClaim = state.claimableReward[msg.sender];
        state.totalClaimedRewards = state.totalClaimedRewards.add(rewardToClaim);
        state.claimableReward[msg.sender] = 0;
        state.token.safeTransfer(msg.sender, rewardToClaim);
        emit RewardClaimed(msg.sender, address(state.token), rewardToClaim);
    }

    function stakedAmount(address staker) external view returns (uint256) {
        return _staked[staker];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function claimableReward(address stakerAddress, address loanTokenAddress) external view returns (uint256) {
        require(wasLoanTokenEverSupported(loanTokenAddress), "PawnshopStaking: the ERC20 loan token was never supported");
        StakingState storage state = _stakingStates[loanTokenAddress];
        uint256 newTotalRewards = _calculateNewTotalRewards(state);
        uint256 newCRPT = _totalStaked > 0 ? _calculateNewCRPT(state, newTotalRewards) : state.cRPT;
        return _calculateNewClaimableReward(state, newCRPT, stakerAddress);
    }

    function totalClaimedRewards(address loanTokenAddress) external view returns (uint256) {
        require(wasLoanTokenEverSupported(loanTokenAddress), "PawnshopStaking: the ERC20 loan token was never supported");
        return _stakingStates[loanTokenAddress].totalClaimedRewards;
    }

    function totalRewards(address loanTokenAddress) external view returns (uint256) {
        require(wasLoanTokenEverSupported(loanTokenAddress), "PawnshopStaking: the ERC20 loan token was never supported");
        StakingState storage state = _stakingStates[loanTokenAddress];
        return _calculateNewTotalRewards(state);
    }

    function stakingToken() external view returns (IERC20) {
        return _stakingToken;
    }
}


// Dependency file: contracts/model/OfferModel.sol


// pragma solidity 0.7.3;

abstract contract OfferModel {
    string internal constant ITEM__TYPE = "Item(address tokenAddress,uint256 tokenId,uint256 depositTimestamp)";
    string internal constant LOAN_PARAMS__TYPE = "LoanParams(uint256 itemValue,uint256 redemptionPrice,uint32 timelockPeriod)";
    string internal constant OFFER__TYPE = "Offer(uint32 nonce,uint40 expirationTime,address loanTokenAddress,Item collateralItem,LoanParams loanParams)"
                                           "Item(address tokenAddress,uint256 tokenId,uint256 depositTimestamp)"
                                           "LoanParams(uint256 itemValue,uint256 redemptionPrice,uint32 timelockPeriod)";

    struct Item {
        address tokenAddress;
        uint256 tokenId;
        uint256 depositTimestamp;
    }

    struct LoanParams {
        uint256 itemValue;
        uint256 redemptionPrice;
        uint32 timelockPeriod;
    }

    struct Offer {
        uint32 nonce;
        uint40 expirationTime;
        address loanTokenAddress;
        Item collateralItem;
        LoanParams loanParams;
    }
}


// Dependency file: @openzeppelin/contracts/cryptography/ECDSA.sol


// pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * // importANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}


// Dependency file: contracts/verifiers/EIP712Domain.sol


// pragma solidity 0.7.3;

// import "contracts/Initializable.sol";
// import "contracts/PawnshopStorage.sol";
// import "contracts/model/OfferModel.sol";

abstract contract EIP712Domain is PawnshopStorage, Initializable {
    string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));

    // bytes32 DOMAIN_SEPARATOR;

    // solhint-disable-next-line func-name-mixedcase
    function __EIP712Domain_init_unchained() internal initializer {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("Pawnshop"),
                keccak256("1.0.0"),
                _getChainId(),
                address(this)
            ));
    }

    function _getChainId() private pure returns (uint256 id) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
    }
}


// Dependency file: contracts/verifiers/OfferSigVerifier.sol


// pragma solidity 0.7.3;

// import "@openzeppelin/contracts/cryptography/ECDSA.sol";

// import "contracts/verifiers/EIP712Domain.sol";
// import "contracts/model/OfferModel.sol";

abstract contract OfferSigVerifier is OfferModel, EIP712Domain {
    using ECDSA for bytes32;

    bytes32 private constant ITEM__TYPEHASH = keccak256(abi.encodePacked(ITEM__TYPE));
    bytes32 private constant LOAN_PARAMS__TYPEHASH = keccak256(abi.encodePacked(LOAN_PARAMS__TYPE));
    bytes32 private constant OFFER__TYPEHASH = keccak256(abi.encodePacked(OFFER__TYPE));

    function _hashItem(Item calldata item) private pure returns (bytes32) {
        return keccak256(abi.encode(
                ITEM__TYPEHASH,
                item.tokenAddress,
                item.tokenId,
                item.depositTimestamp
            ));
    }

    function _hashLoanParams(LoanParams calldata params) private pure returns (bytes32) {
        return keccak256(abi.encode(
                LOAN_PARAMS__TYPEHASH,
                params.itemValue,
                params.redemptionPrice,
                params.timelockPeriod
            ));
    }

    function _hashOffer(Offer calldata offer) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    OFFER__TYPEHASH,
                    offer.nonce,
                    offer.expirationTime,
                    offer.loanTokenAddress,
                    _hashItem(offer.collateralItem),
                    _hashLoanParams(offer.loanParams)
                ))
            ));
    }

    function _verifyOffer(address signerAddress, bytes calldata signature, Offer calldata offer) internal view returns (bool) {
        bytes32 hash = _hashOffer(offer);
        return hash.recover(signature) == signerAddress;
    }
}


// Dependency file: contracts/model/FlashOfferModel.sol


// pragma solidity 0.7.3;

abstract contract FlashOfferModel {
    string internal constant FLASH_OFFER__TYPE = "FlashOffer(uint32 nonce,uint40 expirationTime,address loanTokenAddress,uint256 loanAmount,uint256 returnAmount)";

    struct FlashOffer {
        uint32 nonce;
        uint40 expirationTime;
        address loanTokenAddress;
        uint256 loanAmount;
        uint256 returnAmount;
    }
}


// Dependency file: contracts/verifiers/FlashOfferSigVerifier.sol


// pragma solidity 0.7.3;

// import "@openzeppelin/contracts/cryptography/ECDSA.sol";

// import "contracts/verifiers/EIP712Domain.sol";
// import "contracts/model/FlashOfferModel.sol";

abstract contract FlashOfferSigVerifier is FlashOfferModel, EIP712Domain {
    using ECDSA for bytes32;

    bytes32 private constant FLASH_OFFER__TYPEHASH = keccak256(abi.encodePacked(FLASH_OFFER__TYPE));

    function _hashFlashOffer(FlashOffer calldata offer) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    FLASH_OFFER__TYPEHASH,
                    offer.nonce,
                    offer.expirationTime,
                    offer.loanTokenAddress,
                    offer.loanAmount,
                    offer.returnAmount
                ))
            ));
    }

    function _verifyFlashOffer(
        address signerAddress,
        bytes calldata signature,
        FlashOffer calldata offer
    ) internal view returns (bool) {
        bytes32 hash = _hashFlashOffer(offer);
        return hash.recover(signature) == signerAddress;
    }
}


// Dependency file: contracts/interfaces/IERC3156FlashBorrower.sol


// pragma solidity 0.7.3;

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param sender The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function onFlashLoan(
        address sender,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}


// Dependency file: contracts/FlashLoan.sol


// pragma solidity 0.7.3;
// pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";

// import "contracts/PawnshopConfig.sol";
// import "contracts/PawnshopStorage.sol";
// import "contracts/utils/FractionMath.sol";
// import "contracts/model/FlashOfferModel.sol";
// import "contracts/verifiers/FlashOfferSigVerifier.sol";
// import "contracts/interfaces/IERC3156FlashBorrower.sol";

abstract contract FlashLoan is FlashOfferModel, PawnshopStorage, FlashOfferSigVerifier, PawnshopConfig {
    using FractionMath for FractionMath.Fraction;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event FlashLoanMade(
        address indexed borrowerAddress,
        address indexed receiverAddress,
        address indexed lenderAddress,
        bytes32 signatureHash
    );

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address lenderAddress,
        bytes calldata signature,
        FlashOffer calldata offer,
        bytes calldata data
    ) external {
        require(isLoanTokenSupported(offer.loanTokenAddress), "FlashLoan: the ERC20 loan token is not supported");
        require(block.timestamp < offer.expirationTime, "FlashLoan: the offer has expired");
        require(offer.loanAmount > 0, "FlashLoan: loan amount must be greater than 0");
        require(offer.returnAmount > 0, "FlashLoan: return amount must be greater than 0");
        require(offer.returnAmount >= minReturnAmount(offer.loanTokenAddress, offer.loanAmount),
            "FlashLoan: the return amount is less then the minimum return amount for this loan token and loan amount");
        require(_verifyFlashOffer(lenderAddress, signature, offer), "FlashLoan: the signature of the offer is invalid");

        bytes32 signatureHash = keccak256(signature);
        require(!_usedOfferSignatures[signatureHash], "FlashLoan: the loan has already been taken or the offer was cancelled");
        _usedOfferSignatures[signatureHash] = true;

        IERC20(offer.loanTokenAddress).safeTransferFrom(lenderAddress, address(receiver), offer.loanAmount);

        uint256 flashFee = _flashFees[offer.loanTokenAddress].mul(offer.loanAmount);
        uint256 totalFee = offer.returnAmount.sub(offer.loanAmount).add(flashFee);
        receiver.onFlashLoan(msg.sender, offer.loanTokenAddress, offer.loanAmount, totalFee, data);

        IERC20(offer.loanTokenAddress).safeTransferFrom(address(receiver), lenderAddress, offer.returnAmount);
        IERC20(offer.loanTokenAddress).safeTransferFrom(address(receiver), address(this), flashFee);

        emit FlashLoanMade(msg.sender, address(receiver), lenderAddress, signatureHash);
    }
}


// Root file: contracts/Pawnshop.sol


pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// import "contracts/PawnshopStorage.sol";
// import "contracts/Initializable.sol";
// import "contracts/Ownable.sol";
// import "contracts/ReentrancyGuard.sol";
// import "contracts/PawnshopConfig.sol";
// import "contracts/PawnshopStaking.sol";
// import "contracts/model/LoanModel.sol";
// import "contracts/model/OfferModel.sol";
// import "contracts/verifiers/OfferSigVerifier.sol";
// import "contracts/handlers/IHandler.sol";
// import "contracts/FlashLoan.sol";
// import "contracts/utils/FractionMath.sol";

contract Pawnshop is LoanModel, PawnshopStorage, Initializable, Ownable, ReentrancyGuard, OfferSigVerifier, PawnshopConfig, PawnshopStaking, FlashLoan, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using FractionMath for FractionMath.Fraction;

    // mapping (bytes32 => Loan) _loans;
    // mapping (bytes32 => bool) _usedOfferSignatures;

    modifier onlyBorrower(bytes32 signatureHash) {
        Loan storage loan = _loans[signatureHash];
        require(msg.sender == loan.borrowerAddress, "Pawnshop: caller is not the borrower");

        _;
    }

    modifier onlyLender(bytes32 signatureHash) {
        Loan storage loan = _loans[signatureHash];
        require(msg.sender == loan.lenderAddress, "Pawnshop: caller is not the lender");

        _;
    }

    event ItemDeposited(address indexed previousOwner, address indexed tokenAddress, uint256 indexed tokenId);
    event ItemWithdrawn(address indexed ownerAddress, address indexed tokenAddress, uint256 indexed tokenId);
    event LoanTaken(address indexed borrowerAddress, address indexed lenderAddress, bytes32 signatureHash);
    event OfferCanceled(address indexed lenderAddres, bytes32 signatureHash);
    event ItemRedeemed(address indexed borrowerAddress, bytes32 signatureHash);
    event ItemClaimed(address indexed lenderAddress, bytes32 signatureHash);

    constructor(address owner) {
        __Ownable_init_unchained(owner);
    }

    function initialize(address owner, IERC20 stakingToken, uint256 maxTimelockPeriod) public initializer {
        __Ownable_init_unchained(owner);
        __ReentrancyGuard_init_unchained();
        __EIP712Domain_init_unchained();
        __PawnshopStaking_init_unchained(stakingToken);
        __Pawnshop_init_unchained(maxTimelockPeriod);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Pawnshop_init_unchained(uint256 maxTimelockPeriod) internal {
        _setMaxTimelockPeriod(maxTimelockPeriod);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        revert("Pawnshop: tokens cannot be transferred directly, use Pawnshop.depositItem function instead");
    }

    function itemOwner(address tokenAddress, uint256 tokenId) external view returns (address) {
        IHandler handler = itemHandler(tokenAddress);
        return handler.ownerOf(tokenAddress, tokenId);
    }

    function _calculateRedemptionFee(Loan storage loan) private view returns (uint256) {
        return loan.offer.redemptionPrice
            .mul(loan.redemptionFeeNumerator)
            .div(loan.redemptionFeeDenominator);
    }

    function depositItem(address tokenAddress, uint256 tokenId) external {
        IHandler handler = itemHandler(tokenAddress);
        handler.deposit(msg.sender, tokenAddress, tokenId);
        emit ItemDeposited(msg.sender, tokenAddress, tokenId);
    }

    function itemDepositTimestamp(address tokenAddress, uint256 tokenId) public view returns (uint256) {
        IHandler handler = itemHandler(tokenAddress);
        return handler.depositTimestamp(tokenAddress, tokenId);
    }

    function takeLoan(address lenderAddress, bytes calldata signature, Offer calldata offer) external nonReentrant {
        Item calldata item = offer.collateralItem;
        LoanParams calldata params = offer.loanParams;
        IHandler handler = itemHandler(item.tokenAddress);

        require(handler.isSupported(item.tokenAddress), "Pawnshop: the item is not supported");
        require(isLoanTokenSupported(offer.loanTokenAddress), "Pawnshop: the ERC20 loan token is not supported");
        require(block.timestamp < offer.expirationTime, "Pawnshop: the offer has expired");
        require(params.itemValue > 0, "Pawnshop: the item value must be greater than 0");
        require(params.redemptionPrice > 0, "Pawnshop: the redemption price must be greater than 0");
        require(params.timelockPeriod > 0, "Pawnshop: the timelock period must be greater than 0");
        require(params.timelockPeriod <= _maxTimelockPeriod, "Pawnshop: the timelock period must be less or equal to the max timelock period");
        require(params.redemptionPrice >= minReturnAmount(offer.loanTokenAddress, params.itemValue),
            "Pawnshop: the redemption price is less then the minimum return amount for this loan token and loan amount");

        require(_verifyOffer(lenderAddress, signature, offer), "Pawnshop: the signature of the offer is invalid");

        bytes32 signatureHash = keccak256(signature);
        require(!_usedOfferSignatures[signatureHash], "Pawnshop: the loan has already been taken or the offer was cancelled");
        require(handler.ownerOf(item.tokenAddress, item.tokenId) == msg.sender, "Pawnshop: the item must be deposited to the pawnshop first");
        require(handler.depositTimestamp(item.tokenAddress, item.tokenId) == item.depositTimestamp, "Pawnshop: the item was redeposited after offer signing");

        uint256 depositFee = _depositFees[offer.loanTokenAddress].mul(params.itemValue);
        IERC20(offer.loanTokenAddress).safeTransferFrom(lenderAddress, address(this), depositFee);
        IERC20(offer.loanTokenAddress).safeTransferFrom(lenderAddress, msg.sender, params.itemValue.sub(depositFee));

        _usedOfferSignatures[signatureHash] = true;
        _loans[signatureHash] = Loan({
            offer: StoredOffer({
                nonce: offer.nonce,
                timelockPeriod: offer.loanParams.timelockPeriod,
                loanTokenAddress: offer.loanTokenAddress,
                itemTokenAddress: offer.collateralItem.tokenAddress,
                itemTokenId: offer.collateralItem.tokenId,
                itemValue: offer.loanParams.itemValue,
                redemptionPrice: offer.loanParams.redemptionPrice
            }),
            status: LoanStatus.TAKEN,
            borrowerAddress: msg.sender,
            lenderAddress: lenderAddress,
            redemptionFeeNumerator: _redemptionFees[offer.loanTokenAddress].numerator,
            redemptionFeeDenominator: _redemptionFees[offer.loanTokenAddress].denominator,
            timestamp: block.timestamp
        });

        handler.changeOwnership(address(this), item.tokenAddress, item.tokenId);

        emit LoanTaken(msg.sender, lenderAddress, signatureHash);
    }

    function loan(bytes32 signatureHash) external view returns (Loan memory) {
        Loan storage _loan = _loans[signatureHash];
        require(_loan.timestamp != 0, "Pawnshop: there's no loan with given signature");
        return _loan;
    }

    function isSignatureUsed(bytes32 signatureHash) external view returns (bool) {
        return _usedOfferSignatures[signatureHash];
    }

    function cancelOffer(bytes calldata signature, Offer calldata offer) external {
        require(_verifyOffer(msg.sender, signature, offer), "Pawnshop: the transaction sender is not the offer signer");

        bytes32 signatureHash = keccak256(signature);
        _usedOfferSignatures[signatureHash] = true;

        emit OfferCanceled(msg.sender, signatureHash);
    }

    function redemptionPriceWithFee(bytes32 signatureHash) external view returns (uint256) {
        Loan storage _loan = _loans[signatureHash];
        require(_loan.timestamp != 0, "Pawnshop: there's no loan with given signature");

        return _loan.offer.redemptionPrice.add(_calculateRedemptionFee(_loan));
    }

    function redemptionDeadline(bytes32 signatureHash) public view returns (uint256) {
        Loan storage _loan = _loans[signatureHash];
        require(_loan.timestamp != 0, "Pawnshop: there's no loan with given signature");

        return _loan.timestamp.add(_loan.offer.timelockPeriod);
    }

    function _reedemItem(bytes32 signatureHash) private returns (Loan storage _loan) {
        _loan = _loans[signatureHash];
        StoredOffer storage offer = _loan.offer;
        require(block.timestamp <= redemptionDeadline(signatureHash), "Pawnshop: the redemption time has already passed");
        require(_loan.status == LoanStatus.TAKEN, "Pawnshop: the item was already redeemed/claimed");

        address loanTokenAddress = offer.loanTokenAddress;
        uint256 redemptionFee = _calculateRedemptionFee(_loan);
        IERC20(loanTokenAddress).safeTransferFrom(_loan.borrowerAddress, address(this), redemptionFee);
        IERC20(loanTokenAddress).safeTransferFrom(_loan.borrowerAddress, _loan.lenderAddress, offer.redemptionPrice);

        IHandler handler = itemHandler(offer.itemTokenAddress);
        handler.changeOwnership(msg.sender, offer.itemTokenAddress, offer.itemTokenId);
        _loan.status = LoanStatus.RETURNED;

        emit ItemRedeemed(msg.sender, signatureHash);
    }

    function redeemItem(bytes32 signatureHash) external onlyBorrower(signatureHash) {
        _reedemItem(signatureHash);
    }

    function _claimItem(bytes32 signatureHash) private returns (Loan storage _loan) {
        _loan = _loans[signatureHash];
        StoredOffer storage offer = _loan.offer;
        require(block.timestamp > redemptionDeadline(signatureHash), "Pawnshop: the item timelock period hasn't passed yet");
        require(_loan.status == LoanStatus.TAKEN, "Pawnshop: the item was already redeemed/claimed");

        IHandler handler = itemHandler(offer.itemTokenAddress);
        handler.changeOwnership(msg.sender, offer.itemTokenAddress, offer.itemTokenId);
        _loan.status = LoanStatus.CLAIMED;

        emit ItemClaimed(msg.sender, signatureHash);
    }

    function claimItem(bytes32 signatureHash) external onlyLender(signatureHash) {
        _claimItem(signatureHash);
    }

    function withdrawItem(address tokenAddress, uint256 tokenId) public {
        IHandler handler = itemHandler(tokenAddress);
        handler.withdraw(msg.sender, tokenAddress, tokenId);
        emit ItemWithdrawn(msg.sender, tokenAddress, tokenId);
    }

    function redeemAndWithdrawItem(bytes32 signatureHash) external onlyBorrower(signatureHash) {
        Loan storage _loan = _reedemItem(signatureHash);
        withdrawItem(_loan.offer.itemTokenAddress, _loan.offer.itemTokenId);
    }

    function claimAndWithdrawItem(bytes32 signatureHash) external onlyLender(signatureHash) {
        Loan storage _loan = _claimItem(signatureHash);
        withdrawItem(_loan.offer.itemTokenAddress, _loan.offer.itemTokenId);
    }
}