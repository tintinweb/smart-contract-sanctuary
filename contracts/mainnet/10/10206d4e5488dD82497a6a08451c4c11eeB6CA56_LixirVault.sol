/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: IERC20Permit

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
   * given `owner`'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// Part: LixirErrors

library LixirErrors {
  function require_INSUFFICIENT_BALANCE(bool cond) internal pure {
    require(cond, 'INSUFFICIENT_BALANCE');
  }

  function require_INSUFFICIENT_ALLOWANCE(bool cond) internal pure {
    require(cond, 'INSUFFICIENT_ALLOWANCE');
  }

  function require_PERMIT_EXPIRED(bool cond) internal pure {
    require(cond, 'PERMIT_EXPIRED');
  }

  function require_INVALID_SIGNATURE(bool cond) internal pure {
    require(cond, 'INVALID_SIGNATURE');
  }

  function require_XFER_ZERO_ADDRESS(bool cond) internal pure {
    require(cond, 'XFER_ZERO_ADDRESS');
  }

  function require_INSUFFICIENT_INPUT_AMOUNT(bool cond) internal pure {
    require(cond, 'INSUFFICIENT_INPUT_AMOUNT');
  }

  function require_INSUFFICIENT_OUTPUT_AMOUNT(bool cond) internal pure {
    require(cond, 'INSUFFICIENT_OUTPUT_AMOUNT');
  }
  function require_INSUFFICIENT_ETH(bool cond) internal pure {
    require(cond, 'INSUFFICIENT_ETH');
  }
  function require_MAX_SUPPLY(bool cond) internal pure {
    require(cond, 'MAX_SUPPLY');
  }
}

// Part: LixirRoles

library LixirRoles {
  bytes32 constant gov_role = keccak256('v1_gov_role');
  bytes32 constant delegate_role = keccak256('v1_delegate_role');
  bytes32 constant vault_role = keccak256('v1_vault_role');
  bytes32 constant strategist_role = keccak256('v1_strategist_role');
  bytes32 constant pauser_role = keccak256('v1_pauser_role');
  bytes32 constant keeper_role = keccak256('v1_keeper_role');
  bytes32 constant deployer_role = keccak256('v1_deployer_role');
  bytes32 constant strategy_role = keccak256('v1_strategy_role');
  bytes32 constant vault_implementation_role =
    keccak256('v1_vault_implementation_role');
  bytes32 constant eth_vault_implementation_role =
    keccak256('v1_eth_vault_implementation_role');
  bytes32 constant factory_role = keccak256('v1_factory_role');
  bytes32 constant fee_setter_role = keccak256('fee_setter_role');
}

// Part: OpenZeppelin/[email protected]/Address

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

// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/EnumerableSet

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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/SafeMath

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

// Part: SafeCast

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require(y < 2**255);
    z = int256(y);
  }

  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  function abs(int256 y) internal pure returns (uint256 z) {
    z = y < 0 ? uint256(-y) : uint256(y);
  }
}

// Part: Uniswap/[email protected]/FixedPoint128

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// Part: Uniswap/[email protected]/FixedPoint96

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// Part: Uniswap/[email protected]/FullMath

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(aÃbÃ·denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(aÃbÃ·denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// Part: Uniswap/[email protected]/IUniswapV3MintCallback

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// Part: Uniswap/[email protected]/IUniswapV3PoolActions

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// Part: Uniswap/[email protected]/IUniswapV3PoolDerivedState

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// Part: Uniswap/[email protected]/IUniswapV3PoolEvents

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolImmutables

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolOwnerActions

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// Part: Uniswap/[email protected]/IUniswapV3PoolState

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// Part: Uniswap/[email protected]/LowGasSafeMath

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// Part: Uniswap/[email protected]/TickMath

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// Part: Uniswap/[email protected]/UnsafeMath

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// Part: Uniswap/[email protected]/PoolAddress

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// Part: Uniswap/[email protected]/PositionKey

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// Part: Uniswap/[email protected]/TransferHelper

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// Part: ILixirVaultToken

interface ILixirVaultToken is IERC20, IERC20Permit {}

// Part: OpenZeppelin/[email protected]/AccessControl

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

// Part: OpenZeppelin/[email protected]/Initializable

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
        return !Address.isContract(address(this));
    }
}

// Part: OpenZeppelin/[email protected]/Pausable

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
    constructor () {
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

// Part: SqrtPriceMath

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? (amount << FixedPoint96.RESOLUTION) / liquidity
                        : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
                );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                        : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
                );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// Part: Uniswap/[email protected]/IUniswapV3Pool

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// Part: Uniswap/[email protected]/IWETH9

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// Part: Uniswap/[email protected]/LiquidityAmounts

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// Part: EIP712Initializable

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Initializable is Initializable {
  /* solhint-disable var-name-mixedcase */
  bytes32 private _HASHED_NAME;
  bytes32 private immutable _HASHED_VERSION;
  bytes32 private immutable _TYPE_HASH;

  constructor(string memory version) {
    _HASHED_VERSION = keccak256(bytes(version));
    _TYPE_HASH = keccak256(
      'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
  }

  /* solhint-enable var-name-mixedcase */

  /**
   * @dev Initializes the domain separator and parameter caches.
   *
   * The meaning of `name` and `version` is specified in
   * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
   *
   * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
   * - `version`: the current major version of the signing domain.
   *
   * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
   * contract upgrade].
   */
  function __EIP712__initialize(string memory name) internal initializer {
    _HASHED_NAME = keccak256(bytes(name));
  }

  /**
   * @dev Returns the domain separator for the current chain.
   */
  function _domainSeparatorV4() internal view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _TYPE_HASH,
          _HASHED_NAME,
          _HASHED_VERSION,
          _getChainId(),
          address(this)
        )
      );
  }

  /**
   * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
   * function returns the hash of the fully encoded EIP712 message for this domain.
   *
   * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
   *
   * ```solidity
   * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
   *     keccak256("Mail(address to,string contents)"),
   *     mailTo,
   *     keccak256(bytes(mailContents))
   * )));
   * address signer = ECDSA.recover(digest, signature);
   * ```
   */
  function _hashTypedDataV4(bytes32 structHash)
    internal
    view
    virtual
    returns (bytes32)
  {
    return
      keccak256(abi.encodePacked('\x19\x01', _domainSeparatorV4(), structHash));
  }

  function _getChainId() private view returns (uint256 chainId) {
    // Silence state mutability warning without generating bytecode.
    // See https://github.com/ethereum/solidity/issues/10090#issuecomment-741789128 and
    // https://github.com/ethereum/solidity/issues/2691
    this;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
  }
}

// Part: ILixirVault

interface ILixirVault is ILixirVaultToken {
  function initialize(
    string memory name,
    string memory symbol,
    address _token0,
    address _token1,
    address _strategist,
    address _keeper,
    address _strategy
  ) external;

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function activeFee() external view returns (uint24);

  function activePool() external view returns (IUniswapV3Pool);

  function strategist() external view returns (address);

  function strategy() external view returns (address);

  function keeper() external view returns (address);

  function setKeeper(address _keeper) external;

  function setStrategist(address _strategist) external;

  function setStrategy(address _strategy) external;

  function setPerformanceFee(uint24 newFee) external;

  function emergencyExit() external;

  function unpause() external;

  function mainPosition()
    external
    view
    returns (int24 tickLower, int24 tickUpper);

  function rangePosition()
    external
    view
    returns (int24 tickLower, int24 tickUpper);

  function rebalance(
    int24 mainTickLower,
    int24 mainTickUpper,
    int24 rangeTickLower0,
    int24 rangeTickUpper0,
    int24 rangeTickLower1,
    int24 rangeTickUpper1,
    uint24 fee
  ) external;

  function withdraw(
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address receiver,
    uint256 deadline
  ) external returns (uint256 amount0Out, uint256 amount1Out);

  function withdrawFrom(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  ) external returns (uint256 amount0Out, uint256 amount1Out);

  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    external
    returns (
      uint256 shares,
      uint256 amount0,
      uint256 amount1
    );

  function calculateTotalsFromTick(int24 virtualTick)
    external
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    );
}

// Part: LixirRegistry

/**
  @notice an access control contract with roles used to handle
  permissioning throughout the `Vault` and `Strategy` contracts.
 */
contract LixirRegistry is AccessControl {
  address public immutable uniV3Factory;
  IWETH9 public immutable weth9;

  /// king
  bytes32 public constant gov_role = keccak256('v1_gov_role');
  /// same privileges as `gov_role`
  bytes32 public constant delegate_role = keccak256('v1_delegate_role');
  /// configuring options within the strategy contract & vault
  bytes32 public constant strategist_role = keccak256('v1_strategist_role');
  /// can `emergencyExit` a vault
  bytes32 public constant pauser_role = keccak256('v1_pauser_role');
  /// can `rebalance` the vault via the strategy contract
  bytes32 public constant keeper_role = keccak256('v1_keeper_role');
  /// can `createVault`s from the factory contract
  bytes32 public constant deployer_role = keccak256('v1_deployer_role');
  /// verified vault in the registry
  bytes32 public constant vault_role = keccak256('v1_vault_role');
  /// can initialize vaults
  bytes32 public constant strategy_role = keccak256('v1_strategy_role');
  bytes32 public constant vault_implementation_role =
    keccak256('v1_vault_implementation_role');
  bytes32 public constant eth_vault_implementation_role =
    keccak256('v1_eth_vault_implementation_role');
  /// verified vault factory in the registry
  bytes32 public constant factory_role = keccak256('v1_factory_role');
  /// can `setPerformanceFee` on a vault
  bytes32 public constant fee_setter_role = keccak256('fee_setter_role');

  address public feeTo;

  address public emergencyReturn;

  uint24 public constant PERFORMANCE_FEE_PRECISION = 1e6;

  event FeeToChanged(address indexed previousFeeTo, address indexed newFeeTo);

  event EmergencyReturnChanged(
    address indexed previousEmergencyReturn,
    address indexed newEmergencyReturn
  );

  constructor(
    address _governance,
    address _delegate,
    address _uniV3Factory,
    address _weth9
  ) {
    uniV3Factory = _uniV3Factory;
    weth9 = IWETH9(_weth9);
    _setupRole(gov_role, _governance);
    _setupRole(delegate_role, _delegate);
    // gov is its own admin
    _setRoleAdmin(gov_role, gov_role);
    _setRoleAdmin(delegate_role, gov_role);
    _setRoleAdmin(strategist_role, delegate_role);
    _setRoleAdmin(fee_setter_role, delegate_role);
    _setRoleAdmin(pauser_role, delegate_role);
    _setRoleAdmin(keeper_role, delegate_role);
    _setRoleAdmin(deployer_role, delegate_role);
    _setRoleAdmin(factory_role, delegate_role);
    _setRoleAdmin(strategy_role, delegate_role);
    _setRoleAdmin(vault_implementation_role, delegate_role);
    _setRoleAdmin(eth_vault_implementation_role, delegate_role);
    _setRoleAdmin(vault_role, factory_role);
  }

  function addRole(bytes32 role, bytes32 roleAdmin) public {
    require(isGovOrDelegate(msg.sender));
    require(getRoleAdmin(role) == bytes32(0) && getRoleMemberCount(role) == 0);
    _setRoleAdmin(role, roleAdmin);
  }

  function isGovOrDelegate(address account) public view returns (bool) {
    return hasRole(gov_role, account) || hasRole(delegate_role, account);
  }

  function setFeeTo(address _feeTo) external {
    require(isGovOrDelegate(msg.sender));
    address previous = feeTo;
    feeTo = _feeTo;
    emit FeeToChanged(previous, _feeTo);
  }

  function setEmergencyReturn(address _emergencyReturn) external {
    require(isGovOrDelegate(msg.sender));
    address previous = emergencyReturn;
    emergencyReturn = _emergencyReturn;
    emit EmergencyReturnChanged(previous, _emergencyReturn);
  }
}

// Part: LixirBase

/**
  @notice An abstract contract that gives access to the registry
  and contains common modifiers for restricting access to
  functions based on role. 
 */
abstract contract LixirBase {
  LixirRegistry public immutable registry;

  constructor(address _registry) {
    registry = LixirRegistry(_registry);
  }

  modifier onlyRole(bytes32 role) {
    require(registry.hasRole(role, msg.sender));
    _;
  }
  modifier onlyGovOrDelegate {
    require(registry.isGovOrDelegate(msg.sender));
    _;
  }
  modifier hasRole(bytes32 role, address account) {
    require(registry.hasRole(role, account));
    _;
  }
}

// Part: LixirVaultToken

/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 */
contract LixirVaultToken is ILixirVaultToken, EIP712Initializable {
  using SafeMath for uint256;

  // State variables

  uint8 private constant _DECIMALS = 18;

  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) _allowance;
  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  mapping(address => uint256) private _nonces;

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private immutable _PERMIT_TYPE_HASH =
    keccak256(
      'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );

  constructor() EIP712Initializable('1') {}

  // Function declarations

  function __LixirVaultToken__initialize(
    string memory tokenName,
    string memory tokenSymbol
  ) internal initializer {
    __EIP712__initialize(tokenName);
    _name = tokenName;
    _symbol = tokenSymbol;
  }

  // External functions

  function allowance(address owner, address spender)
    public
    view
    override
    returns (uint256)
  {
    return _allowance[owner][spender];
  }

  function balanceOf(address account) external view override returns (uint256) {
    return _balance[account];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _setAllowance(msg.sender, spender, amount);

    return true;
  }

  function increaseApproval(address spender, uint256 amount)
    external
    returns (bool)
  {
    _setAllowance(
      msg.sender,
      spender,
      _allowance[msg.sender][spender].add(amount)
    );

    return true;
  }

  function decreaseApproval(address spender, uint256 amount)
    external
    returns (bool)
  {
    uint256 currentAllowance = _allowance[msg.sender][spender];

    if (amount >= currentAllowance) {
      _setAllowance(msg.sender, spender, 0);
    } else {
      _setAllowance(msg.sender, spender, currentAllowance.sub(amount));
    }

    return true;
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _move(msg.sender, recipient, amount);

    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    uint256 currentAllowance = _allowance[sender][msg.sender];
    LixirErrors.require_INSUFFICIENT_ALLOWANCE(
      msg.sender == sender || currentAllowance >= amount
    );
    _move(sender, recipient, amount);

    if (msg.sender != sender && currentAllowance != uint256(-1)) {
      // Because of the previous require, we know that if msg.sender != sender then currentAllowance >= amount
      _setAllowance(sender, msg.sender, currentAllowance - amount);
    }

    return true;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public virtual override {
    // solhint-disable-next-line not-rely-on-time
    LixirErrors.require_PERMIT_EXPIRED(block.timestamp <= deadline);

    uint256 nonce = _nonces[owner];

    bytes32 structHash =
      keccak256(
        abi.encode(_PERMIT_TYPE_HASH, owner, spender, value, nonce, deadline)
      );

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ecrecover(hash, v, r, s);
    LixirErrors.require_INVALID_SIGNATURE(signer != address(0));

    _nonces[owner] = nonce + 1;
    _setAllowance(owner, spender, value);
  }

  // Public functions

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function decimals() public pure returns (uint8) {
    return _DECIMALS;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function nonces(address owner) external view override returns (uint256) {
    return _nonces[owner];
  }

  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view override returns (bytes32) {
    return _domainSeparatorV4();
  }

  // Internal functions

  function _beforeMintCallback(address recipient, uint256 amount)
    internal
    virtual
  {}

  function _mintPoolTokens(address recipient, uint256 amount) internal {
    _beforeMintCallback(recipient, amount);
    _balance[recipient] = _balance[recipient].add(amount);
    _totalSupply = _totalSupply.add(amount);
    emit Transfer(address(0), recipient, amount);
  }

  function _burnPoolTokens(address sender, uint256 amount) internal {
    uint256 currentBalance = _balance[sender];
    LixirErrors.require_INSUFFICIENT_BALANCE(currentBalance >= amount);

    _balance[sender] = currentBalance - amount;
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(sender, address(0), amount);
  }

  function _move(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
    uint256 currentBalance = _balance[sender];
    LixirErrors.require_INSUFFICIENT_BALANCE(currentBalance >= amount);
    // Prohibit transfers to the zero address to avoid confusion with the
    // Transfer event emitted by `_burnPoolTokens`
    LixirErrors.require_XFER_ZERO_ADDRESS(recipient != address(0));

    _balance[sender] = currentBalance - amount;
    _balance[recipient] = _balance[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  function _setAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    _allowance[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// File: LixirVault.sol

contract LixirVault is
  ILixirVault,
  LixirVaultToken,
  LixirBase,
  IUniswapV3MintCallback,
  Pausable
{
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using SafeCast for uint128;

  IERC20 public override token0;
  IERC20 public override token1;

  uint24 public override activeFee;
  IUniswapV3Pool public override activePool;

  address public override strategy;
  address public override strategist;
  address public override keeper;

  Position public override mainPosition;
  Position public override rangePosition;

  uint24 public performanceFee;

  uint24 immutable PERFORMANCE_FEE_PRECISION;

  address immutable uniV3Factory;

  event Deposit(
    address indexed depositor,
    address indexed recipient,
    uint256 shares,
    uint256 amount0In,
    uint256 amount1In,
    uint256 total0,
    uint256 total1
  );

  event Withdraw(
    address indexed withdrawer,
    address indexed recipient,
    uint256 shares,
    uint256 amount0Out,
    uint256 amount1Out
  );

  event Rebalance(
    int24 mainTickLower,
    int24 mainTickUpper,
    int24 rangeTickLower,
    int24 rangeTickUpper,
    uint24 newFee,
    uint256 total0,
    uint256 total1
  );

  event PerformanceFeeSet(uint24 oldFee, uint24 newFee);

  event StrategySet(address oldStrategy, address newStrategy);

  struct DepositPositionData {
    uint128 LDelta;
    int24 tickLower;
    int24 tickUpper;
  }

  enum POSITION {MAIN, RANGE}

  // details about the uniswap position
  struct Position {
    // the tick range of the position
    int24 tickLower;
    int24 tickUpper;
  }

  constructor(address _registry) LixirBase(_registry) {
    PERFORMANCE_FEE_PRECISION = LixirRegistry(_registry)
      .PERFORMANCE_FEE_PRECISION();
    uniV3Factory = LixirRegistry(_registry).uniV3Factory();
  }

  /**
    @notice sets fields in the contract and initializes the `LixirVaultToken`
   */
  function initialize(
    string memory name,
    string memory symbol,
    address _token0,
    address _token1,
    address _strategist,
    address _keeper,
    address _strategy
  )
    public
    virtual
    override
    hasRole(LixirRoles.strategist_role, _strategist)
    hasRole(LixirRoles.keeper_role, _keeper)
    hasRole(LixirRoles.strategy_role, _strategy)
    initializer
  {
    require(_token0 < _token1);
    __LixirVaultToken__initialize(name, symbol);
    token0 = IERC20(_token0);
    token1 = IERC20(_token1);
    strategist = _strategist;
    keeper = _keeper;
    strategy = _strategy;
  }

  modifier onlyStrategist() {
    require(msg.sender == strategist);
    _;
  }

  modifier onlyStrategy() {
    require(msg.sender == strategy);
    _;
  }

  modifier notExpired(uint256 deadline) {
    require(block.timestamp <= deadline, 'Expired');
    _;
  }

  /**
    @dev calculates shares, totals, etc. to mint the proper amount of `LixirVaultToken`s
    to `recipient`
   */
  function _depositStepOne(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient
  )
    internal
    returns (
      DepositPositionData memory mainData,
      DepositPositionData memory rangeData,
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In,
      uint256 total0,
      uint256 total1
    )
  {
    uint256 _totalSupply = totalSupply();

    mainData = DepositPositionData({
      LDelta: 0,
      tickLower: mainPosition.tickLower,
      tickUpper: mainPosition.tickUpper
    });

    rangeData = DepositPositionData({
      LDelta: 0,
      tickLower: rangePosition.tickLower,
      tickUpper: rangePosition.tickUpper
    });

    if (_totalSupply == 0) {
      (shares, mainData.LDelta, amount0In, amount1In) = calculateInitialDeposit(
        amount0Desired,
        amount1Desired
      );
      total0 = amount0In;
      total1 = amount1In;
    } else {
      uint128 mL;
      uint128 rL;
      {
        (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
        (total0, total1, mL, rL) = _calculateTotals(
          sqrtRatioX96,
          tick,
          mainData,
          rangeData
        );
      }

      (shares, amount0In, amount1In) = calcSharesAndAmounts(
        amount0Desired,
        amount1Desired,
        total0,
        total1,
        _totalSupply
      );
      mainData.LDelta = uint128(FullMath.mulDiv(mL, shares, _totalSupply));
      rangeData.LDelta = uint128(FullMath.mulDiv(rL, shares, _totalSupply));
    }

    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
      amount0Min <= amount0In && amount1Min <= amount1In
    );

    _mintPoolTokens(recipient, shares);
  }

  /**
    @dev this function deposits the tokens into the UniV3 pool
   */
  function _depositStepTwo(
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData,
    address recipient,
    uint256 shares,
    uint256 amount0In,
    uint256 amount1In,
    uint256 total0,
    uint256 total1
  ) internal {
    uint128 mLDelta = mainData.LDelta;
    if (0 < mLDelta) {
      activePool.mint(
        address(this),
        mainData.tickLower,
        mainData.tickUpper,
        mLDelta,
        ''
      );
    }
    uint128 rLDelta = rangeData.LDelta;
    if (0 < rLDelta) {
      activePool.mint(
        address(this),
        rangeData.tickLower,
        rangeData.tickUpper,
        rLDelta,
        ''
      );
    }
    emit Deposit(
      address(msg.sender),
      address(recipient),
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    );
  }

  /**
    @notice deposit's the callers ERC20 tokens into the vault, mints them
    `LixirVaultToken`s, and adds their liquidity to the UniswapV3 pool.
    @param amount0Desired Amount of token 0 desired by user
    @param amount1Desired Amount of token 1 desired by user
    @param amount0Min Minimum amount of token 0 desired by user
    @param amount1Min Minimum amount of token 1 desired by user
    @param recipient The address for which the liquidity will be created
    @param deadline Blocktimestamp that this must execute before
    @return shares
    @return amount0In how much token0 was actually deposited
    @return amount1In how much token1 was actually deposited
   */
  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    external
    override
    whenNotPaused
    notExpired(deadline)
    returns (
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    DepositPositionData memory mainData;
    DepositPositionData memory rangeData;
    uint256 total0;
    uint256 total1;
    (
      mainData,
      rangeData,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    ) = _depositStepOne(
      amount0Desired,
      amount1Desired,
      amount0Min,
      amount1Min,
      recipient
    );
    if (0 < amount0In) {
      // token0.transferFrom(msg.sender, address(this), amount0In);
      TransferHelper.safeTransferFrom(
        address(token0),
        msg.sender,
        address(this),
        amount0In
      );
    }
    if (0 < amount1In) {
      // token1.transferFrom(msg.sender, address(this), amount1In);
      TransferHelper.safeTransferFrom(
        address(token1),
        msg.sender,
        address(this),
        amount1In
      );
    }
    _depositStepTwo(
      mainData,
      rangeData,
      recipient,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    );
  }

  function _withdrawStep(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient
  ) internal returns (uint256 amount0Out, uint256 amount1Out) {
    uint256 _totalSupply = totalSupply();
    _burnPoolTokens(withdrawer, shares); // does balance check

    (, int24 tick, , , , , ) = activePool.slot0();

    // if withdrawing everything, then burn and collect the all positions
    // else, calculate their share and return it
    if (shares == _totalSupply) {
      if (!paused()) {
        burnCollectPositions();
      }
      amount0Out = token0.balanceOf(address(this));
      amount1Out = token1.balanceOf(address(this));
    } else {
      {
        uint256 e0 = token0.balanceOf(address(this));
        amount0Out = e0 > 0 ? FullMath.mulDiv(e0, shares, _totalSupply) : 0;
        uint256 e1 = token1.balanceOf(address(this));
        amount1Out = e1 > 0 ? FullMath.mulDiv(e1, shares, _totalSupply) : 0;
      }
      if (!paused()) {
        {
          (uint256 ma0Out, uint256 ma1Out) =
            burnAndCollect(mainPosition, tick, shares, _totalSupply);
          amount0Out = amount0Out.add(ma0Out);
          amount1Out = amount1Out.add(ma1Out);
        }
        {
          (uint256 ra0Out, uint256 ra1Out) =
            burnAndCollect(rangePosition, tick, shares, _totalSupply);
          amount0Out = amount0Out.add(ra0Out);
          amount1Out = amount1Out.add(ra1Out);
        }
      }
    }
    LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
      amount0Min <= amount0Out && amount1Min <= amount1Out
    );
    emit Withdraw(
      address(msg.sender),
      address(recipient),
      shares,
      amount0Out,
      amount1Out
    );
  }

  modifier canSpend(address withdrawer, uint256 shares) {
    uint256 currentAllowance = _allowance[withdrawer][msg.sender];
    LixirErrors.require_INSUFFICIENT_ALLOWANCE(
      msg.sender == withdrawer || currentAllowance >= shares
    );

    if (msg.sender != withdrawer && currentAllowance != uint256(-1)) {
      // Because of the previous require, we know that if msg.sender != withdrawer then currentAllowance >= shares
      _setAllowance(withdrawer, msg.sender, currentAllowance - shares);
    }
    _;
  }

  /**
  @notice withdraws the desired shares from the vault on behalf of another account
  @dev same as `withdraw` except this can be called from an `approve`d address
  @param withdrawer the address to withdraw from
  @param shares number of shares to withdraw
  @param amount0Min Minimum amount of token 0 desired by user
  @param amount1Min Minimum amount of token 1 desired by user
  @param recipient address to recieve token0 and token1 withdrawals
  @param deadline blocktimestamp that this must execute by
  @return amount0Out how much token0 was actually withdrawn
  @return amount1Out how much token1 was actually withdrawn
  */
  function withdrawFrom(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    external
    override
    canSpend(withdrawer, shares)
    returns (uint256 amount0Out, uint256 amount1Out)
  {
    (amount0Out, amount1Out) = _withdraw(
      withdrawer,
      shares,
      amount0Min,
      amount1Min,
      recipient,
      deadline
    );
  }

  /**
    @notice withdraws the desired shares from the vault and transfers to caller.
    @dev `_withdrawStep` calculates how much the caller is owed
    @dev `_withdraw` transfers the tokens to the caller
    @param shares number of shares to withdraw
    @param amount0Min Minimum amount of token 0 desired by user
    @param amount1Min Minimum amount of token 1 desired by user
    @param recipient address to recieve token0 and token1 withdrawals
    @param deadline blocktimestamp that this must execute by
    @return amount0Out how much token0 was actually withdrawn
    @return amount1Out how much token1 was actually withdrawn
   */
  function withdraw(
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  ) external override returns (uint256 amount0Out, uint256 amount1Out) {
    (amount0Out, amount1Out) = _withdraw(
      msg.sender,
      shares,
      amount0Min,
      amount1Min,
      recipient,
      deadline
    );
  }

  function _withdraw(
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    internal
    notExpired(deadline)
    returns (uint256 amount0Out, uint256 amount1Out)
  {
    (amount0Out, amount1Out) = _withdrawStep(
      withdrawer,
      shares,
      amount0Min,
      amount1Min,
      recipient
    );
    if (0 < amount0Out) {
      TransferHelper.safeTransfer(address(token0), recipient, amount0Out);
    }
    if (0 < amount1Out) {
      TransferHelper.safeTransfer(address(token1), recipient, amount1Out);
    }
  }

  function setPerformanceFee(uint24 newFee)
    external
    override
    onlyRole(LixirRoles.fee_setter_role)
  {
    require(newFee < PERFORMANCE_FEE_PRECISION);
    emit PerformanceFeeSet(performanceFee, newFee);
    performanceFee = newFee;
  }

  function _setPool(uint24 fee) internal {
    activePool = IUniswapV3Pool(
      PoolAddress.computeAddress(
        uniV3Factory,
        PoolAddress.getPoolKey(address(token0), address(token1), fee)
      )
    );
    require(Address.isContract(address(activePool)));
    activeFee = fee;
  }

  function setKeeper(address _keeper)
    external
    override
    onlyStrategist
    hasRole(LixirRoles.keeper_role, _keeper)
  {
    keeper = _keeper;
  }

  function setStrategy(address _strategy)
    external
    override
    onlyStrategist
    hasRole(LixirRoles.strategy_role, _strategy)
  {
    emit StrategySet(strategy, _strategy);
    strategy = _strategy;
  }

  function setStrategist(address _strategist)
    external
    override
    onlyGovOrDelegate
    hasRole(LixirRoles.strategist_role, _strategist)
  {
    strategist = _strategist;
  }

  function emergencyExit()
    external
    override
    whenNotPaused
    onlyRole(LixirRoles.pauser_role)
  {
    burnCollectPositions();
    _pause();
  }

  function unpause() external override whenPaused onlyGovOrDelegate {
    _unpause();
  }

  /**
    @notice burns all positions collects any fees accrued since last `rebalance`
    and mints new positions.
    @dev This function is not called by an external account, but instead by the
    strategy contract, which automatically calculates the proper positions to mint.
   */
  function rebalance(
    int24 mainTickLower,
    int24 mainTickUpper,
    int24 rangeTickLower0,
    int24 rangeTickUpper0,
    int24 rangeTickLower1,
    int24 rangeTickUpper1,
    uint24 fee
  ) external override onlyStrategy whenNotPaused {
    require(
      TickMath.MIN_TICK <= mainTickLower &&
        mainTickUpper <= TickMath.MAX_TICK &&
        mainTickLower < mainTickUpper &&
        TickMath.MIN_TICK <= rangeTickLower0 &&
        rangeTickUpper0 <= TickMath.MAX_TICK &&
        rangeTickLower0 < rangeTickUpper0 &&
        TickMath.MIN_TICK <= rangeTickLower1 &&
        rangeTickUpper1 <= TickMath.MAX_TICK &&
        rangeTickLower1 < rangeTickUpper1
    );
    /// if a pool has been previously set, then take the performance fee accrued since last `rebalance`
    /// and burn and collect all positions.
    if (address(activePool) != address(0)) {
      _takeFee();
      burnCollectPositions();
    }
    /// if the strategist has changed the pool fee tier (e.g. 0.05%, 0.3%, 1%), then change the pool
    if (fee != activeFee) {
      _setPool(fee);
    }
    uint256 total0 = token0.balanceOf(address(this));
    uint256 total1 = token1.balanceOf(address(this));
    Position memory mainData = Position(mainTickLower, mainTickUpper);
    Position memory rangeData0 = Position(rangeTickLower0, rangeTickUpper0);
    Position memory rangeData1 = Position(rangeTickLower1, rangeTickUpper1);

    mintPositions(total0, total1, mainData, rangeData0, rangeData1);

    emit Rebalance(
      mainTickLower,
      mainTickUpper,
      rangePosition.tickLower,
      rangePosition.tickUpper,
      fee,
      total0,
      total1
    );
  }

  function mintPositions(
    uint256 amount0,
    uint256 amount1,
    Position memory mainData,
    Position memory rangeData0,
    Position memory rangeData1
  ) internal {
    (uint160 sqrtRatioX96, ) = getSqrtRatioX96AndTick();
    mainPosition.tickLower = mainData.tickLower;
    mainPosition.tickUpper = mainData.tickUpper;

    if (0 < amount0 || 0 < amount1) {
      uint128 mL =
        LiquidityAmounts.getLiquidityForAmounts(
          sqrtRatioX96,
          TickMath.getSqrtRatioAtTick(mainData.tickLower),
          TickMath.getSqrtRatioAtTick(mainData.tickUpper),
          amount0,
          amount1
        );

      if (0 < mL) {
        activePool.mint(
          address(this),
          mainData.tickLower,
          mainData.tickUpper,
          mL,
          ''
        );
      }
    }
    amount0 = token0.balanceOf(address(this));
    amount1 = token1.balanceOf(address(this));
    uint128 rL;
    Position memory rangeData;
    if (0 < amount0 || 0 < amount1) {
      uint128 rL0 =
        LiquidityAmounts.getLiquidityForAmount0(
          TickMath.getSqrtRatioAtTick(rangeData0.tickLower),
          TickMath.getSqrtRatioAtTick(rangeData0.tickUpper),
          amount0
        );
      uint128 rL1 =
        LiquidityAmounts.getLiquidityForAmount1(
          TickMath.getSqrtRatioAtTick(rangeData1.tickLower),
          TickMath.getSqrtRatioAtTick(rangeData1.tickUpper),
          amount1
        );

      /// only one range position will ever have liquidity (if any)
      if (rL1 < rL0) {
        rL = rL0;
        rangeData = rangeData0;
      } else if (0 < rL1) {
        rangeData = rangeData1;
        rL = rL1;
      }
    } else {
      rangeData = Position(0, 0);
    }

    rangePosition.tickLower = rangeData.tickLower;
    rangePosition.tickUpper = rangeData.tickUpper;

    if (0 < rL) {
      activePool.mint(
        address(this),
        rangeData.tickLower,
        rangeData.tickUpper,
        rL,
        ''
      );
    }
  }

  function _takeFee() internal {
    uint24 _perfFee = performanceFee;
    address _feeTo = registry.feeTo();
    if (_feeTo != address(0) && 0 < _perfFee) {
      (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
      (
        ,
        uint256 total0,
        uint256 total1,
        uint256 tokensOwed0,
        uint256 tokensOwed1
      ) =
        calculatePositionInfo(
          tick,
          sqrtRatioX96,
          mainPosition.tickLower,
          mainPosition.tickUpper
        );
      {
        (
          ,
          uint256 total0Range,
          uint256 total1Range,
          uint256 tokensOwed0Range,
          uint256 tokensOwed1Range
        ) =
          calculatePositionInfo(
            tick,
            sqrtRatioX96,
            rangePosition.tickLower,
            rangePosition.tickUpper
          );
        total0 = total0.add(total0Range).add(token0.balanceOf(address(this)));
        total1 = total1.add(total1Range).add(token1.balanceOf(address(this)));
        tokensOwed0 = tokensOwed0.add(tokensOwed0Range);
        tokensOwed1 = tokensOwed1.add(tokensOwed1Range);
      }

      uint256 _totalSupply = totalSupply();

      uint256 price =
        FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, FixedPoint96.Q96);

      total1 = total1.add(FullMath.mulDiv(total0, price, FixedPoint96.Q96));

      if (total1 > 0) {
        tokensOwed1 = tokensOwed1.add(
          FullMath.mulDiv(tokensOwed0, price, FixedPoint96.Q96)
        );
        uint256 shares =
          FullMath.mulDiv(
            FullMath.mulDiv(tokensOwed1, _totalSupply, total1),
            performanceFee,
            PERFORMANCE_FEE_PRECISION
          );
        if (shares > 0) {
          _mintPoolTokens(_feeTo, shares);
        }
      }
    }
  }

  /**
    @notice burns everyting (main and range positions) and collects any fees accrued in the pool.
    @dev this is called fairly frequently since compounding is not automatic: in UniV3,
    all fees must be manually withdrawn.
   */
  function burnCollectPositions() internal {
    uint128 mL = positionLiquidity(mainPosition);
    uint128 rL = positionLiquidity(rangePosition);

    if (0 < mL) {
      activePool.burn(mainPosition.tickLower, mainPosition.tickUpper, mL);
      activePool.collect(
        address(this),
        mainPosition.tickLower,
        mainPosition.tickUpper,
        type(uint128).max,
        type(uint128).max
      );
    }
    if (0 < rL) {
      activePool.burn(rangePosition.tickLower, rangePosition.tickUpper, rL);
      activePool.collect(
        address(this),
        rangePosition.tickLower,
        rangePosition.tickUpper,
        type(uint128).max,
        type(uint128).max
      );
    }
  }

  /**
    @notice in contrast to `burnCollectPositions`, this only burns a portion of liqudity,
    used for when a user withdraws tokens from the vault.
    @param position Storage pointer to position
    @param tick Current tick
    @param shares User shares to burn
    @param _totalSupply totalSupply of Lixir vault tokens
   */
  function burnAndCollect(
    Position storage position,
    int24 tick,
    uint256 shares,
    uint256 _totalSupply
  ) internal returns (uint256 amount0Out, uint256 amount1Out) {
    int24 tickLower = position.tickLower;
    int24 tickUpper = position.tickUpper;
    /*
     * N.B. that tokensOwed{0,1} here are calculated prior to burning,
     *  and so should only contain tokensOwed from fees and never tokensOwed from a burn
     */
    (uint128 liquidity, uint256 tokensOwed0, uint256 tokensOwed1) =
      liquidityAndTokensOwed(tick, tickLower, tickUpper);

    uint128 LDelta =
      FullMath.mulDiv(shares, liquidity, _totalSupply).toUint128();

    amount0Out = FullMath.mulDiv(tokensOwed0, shares, _totalSupply);
    amount1Out = FullMath.mulDiv(tokensOwed1, shares, _totalSupply);

    if (0 < LDelta) {
      (uint256 burnt0Out, uint256 burnt1Out) =
        activePool.burn(tickLower, tickUpper, LDelta);
      amount0Out = amount0Out.add(burnt0Out);
      amount1Out = amount1Out.add(burnt1Out);
    }
    if (0 < amount0Out || 0 < amount1Out) {
      activePool.collect(
        address(this),
        tickLower,
        tickUpper,
        amount0Out.toUint128(),
        amount1Out.toUint128()
      );
    }
  }

  /// @dev internal readonly getters and pure helper functions

  /**
   * @dev Calculates shares and amounts to deposit from amounts desired, TVL of vault, and totalSupply of vault tokens
   * @param amount0Desired Amount of token 0 desired by user
   * @param amount1Desired Amount of token 1 desired by user
   * @param total0 Total amount of token 0 available to activePool
   * @param total1 Total amount of token 1 available to activePool
   * @param _totalSupply Total supply of vault tokens
   * @return shares Shares of activePool to mint to user
   * @return amount0In Actual amount of token0 user should deposit into activePool
   * @return amount1In Actual amount of token1 user should deposit into activePool
   */
  function calcSharesAndAmounts(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 total0,
    uint256 total1,
    uint256 _totalSupply
  )
    internal
    pure
    returns (
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    (bool roundedSharesFrom0, uint256 sharesFrom0) =
      0 < total0
        ? mulDivRoundingUp(amount0Desired, _totalSupply, total0)
        : (false, 0);
    (bool roundedSharesFrom1, uint256 sharesFrom1) =
      0 < total1
        ? mulDivRoundingUp(amount1Desired, _totalSupply, total1)
        : (false, 0);
    uint8 realSharesOffsetFor0 = roundedSharesFrom0 ? 1 : 2;
    uint8 realSharesOffsetFor1 = roundedSharesFrom1 ? 1 : 2;
    if (
      realSharesOffsetFor0 < sharesFrom0 &&
      (total1 == 0 || sharesFrom0 < sharesFrom1)
    ) {
      shares = sharesFrom0 - 1 - realSharesOffsetFor0;
      amount0In = amount0Desired;
      amount1In = FullMath.mulDivRoundingUp(sharesFrom0, total1, _totalSupply);
      LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
        amount1In <= amount1Desired
      );
    } else {
      LixirErrors.require_INSUFFICIENT_INPUT_AMOUNT(
        realSharesOffsetFor1 < sharesFrom1
      );
      shares = sharesFrom1 - 1 - realSharesOffsetFor1;
      amount0In = FullMath.mulDivRoundingUp(sharesFrom1, total0, _totalSupply);
      LixirErrors.require_INSUFFICIENT_OUTPUT_AMOUNT(
        amount0In <= amount0Desired
      );
      amount1In = amount1Desired;
    }
  }

  function mulDivRoundingUp(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (bool rounded, uint256 result) {
    result = FullMath.mulDiv(a, b, denominator);
    if (mulmod(a, b, denominator) > 0) {
      require(result < type(uint256).max);
      result++;
      rounded = true;
    }
  }

  /**
   * @dev Calculates shares, liquidity deltas, and amounts in for initial deposit
   * @param amount0Desired Amount of token 0 desired by user
   * @param amount1Desired Amount of token 1 desired by user
   * @return shares Initial shares to mint
   * @return mLDelta Liquidity delta for main position
   * @return amount0In Amount of token 0 to transfer from user
   * @return amount1In Amount of token 1 to transfer from user
   */
  function calculateInitialDeposit(
    uint256 amount0Desired,
    uint256 amount1Desired
  )
    internal
    view
    returns (
      uint256 shares,
      uint128 mLDelta,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
    uint160 sqrtRatioLowerX96 =
      TickMath.getSqrtRatioAtTick(mainPosition.tickLower);
    uint160 sqrtRatioUpperX96 =
      TickMath.getSqrtRatioAtTick(mainPosition.tickUpper);

    mLDelta = LiquidityAmounts.getLiquidityForAmounts(
      sqrtRatioX96,
      sqrtRatioLowerX96,
      sqrtRatioUpperX96,
      amount0Desired,
      amount1Desired
    );

    LixirErrors.require_INSUFFICIENT_INPUT_AMOUNT(0 < mLDelta);

    (amount0In, amount1In) = getAmountsForLiquidity(
      sqrtRatioX96,
      sqrtRatioLowerX96,
      sqrtRatioUpperX96,
      mLDelta.toInt128()
    );
    shares = mLDelta;
  }

  /**
   * @dev Queries activePool for current square root price and current tick
   * @return _sqrtRatioX96 Current square root price
   * @return _tick Current tick
   */
  function getSqrtRatioX96AndTick()
    internal
    view
    returns (uint160 _sqrtRatioX96, int24 _tick)
  {
    (_sqrtRatioX96, _tick, , , , , ) = activePool.slot0();
  }

  /**
   * @dev Calculates tokens owed for a position
   * @param realTick Current tick
   * @param tickLower Lower tick of position
   * @param tickUpper Upper tick of position
   * @param feeGrowthInside0LastX128 Last fee growth of token0 between tickLower and tickUpper
   * @param feeGrowthInside1LastX128 Last fee growth of token0 between tickLower and tickUpper
   * @param liquidity Liquidity of position for which tokens owed is being calculated
   * @param tokensOwed0Last Last tokens owed to position
   * @param tokensOwed1Last Last tokens owed to position
   * @return tokensOwed0 Amount of token0 owed to position
   * @return tokensOwed1 Amount of token1 owed to position
   */
  function calculateTokensOwed(
    int24 realTick,
    int24 tickLower,
    int24 tickUpper,
    uint256 feeGrowthInside0LastX128,
    uint256 feeGrowthInside1LastX128,
    uint128 liquidity,
    uint128 tokensOwed0Last,
    uint128 tokensOwed1Last
  ) internal view returns (uint128 tokensOwed0, uint128 tokensOwed1) {
    /*
     * V3 doesn't use SafeMath here, so we don't either
     * This could of course result in a dramatic forfeiture of fees. The reality though is
     * we rebalance far frequently enough for this to never happen in any realistic scenario.
     * This has no difference from the v3 implementation, and was copied from contracts/libraries/Position.sol
     */
    (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
      getFeeGrowthInsideTicks(realTick, tickLower, tickUpper);
    tokensOwed0 = uint128(
      tokensOwed0Last +
        FullMath.mulDiv(
          feeGrowthInside0X128 - feeGrowthInside0LastX128,
          liquidity,
          FixedPoint128.Q128
        )
    );
    tokensOwed1 = uint128(
      tokensOwed1Last +
        FullMath.mulDiv(
          feeGrowthInside1X128 - feeGrowthInside1LastX128,
          liquidity,
          FixedPoint128.Q128
        )
    );
  }

  function _positionDataHelper(
    int24 realTick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    )
  {
    (
      liquidity,
      feeGrowthInside0LastX128,
      feeGrowthInside1LastX128,
      tokensOwed0,
      tokensOwed1
    ) = activePool.positions(
      PositionKey.compute(address(this), tickLower, tickUpper)
    );

    if (liquidity == 0) {
      return (
        0,
        feeGrowthInside0LastX128,
        feeGrowthInside1LastX128,
        tokensOwed0,
        tokensOwed1
      );
    }

    (tokensOwed0, tokensOwed1) = calculateTokensOwed(
      realTick,
      tickLower,
      tickUpper,
      feeGrowthInside0LastX128,
      feeGrowthInside1LastX128,
      liquidity,
      tokensOwed0,
      tokensOwed1
    );
  }

  /**
   * @dev Queries and calculates liquidity and tokens owed
   * @param tick Current tick
   * @param tickLower Lower tick of position
   * @param tickUpper Upper tick of position
   * @return liquidity Liquidity of position for which tokens owed is being calculated
   * @return tokensOwed0 Amount of token0 owed to position
   * @return tokensOwed1 Amount of token1 owed to position
   */
  function liquidityAndTokensOwed(
    int24 tick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    )
  {
    (liquidity, , , tokensOwed0, tokensOwed1) = _positionDataHelper(
      tick,
      tickLower,
      tickUpper
    );
  }

  function calculateTotals()
    external
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    (uint160 sqrtRatioX96, int24 tick) = getSqrtRatioX96AndTick();
    return
      _calculateTotals(
        sqrtRatioX96,
        tick,
        DepositPositionData(0, mainPosition.tickLower, mainPosition.tickUpper),
        DepositPositionData(0, rangePosition.tickLower, rangePosition.tickUpper)
      );
  }

  /**
   * @notice This variant is so that tick TWAP's may be used by other protocols to calculate
   * totals, allowing them to safeguard themselves from manipulation. This would be useful if
   * Lixir vault tokens were used as collateral in a lending protocol.
   * @param virtualTick Tick at which to calculate amounts from liquidity
   */
  function calculateTotalsFromTick(int24 virtualTick)
    external
    view
    override
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(virtualTick);
    (, int24 realTick) = getSqrtRatioX96AndTick();
    return
      _calculateTotalsFromTick(
        sqrtRatioX96,
        realTick,
        DepositPositionData(0, mainPosition.tickLower, mainPosition.tickUpper),
        DepositPositionData(0, rangePosition.tickLower, rangePosition.tickUpper)
      );
  }

  /**
   * @dev Helper function for calculating totals
   * @param sqrtRatioX96 *Current or virtual* sqrtPriceX96
   * @param realTick Current tick, for calculating tokensOwed correctly
   * @param mainData Main position data
   * @param rangeData Range position data
   * N.B realTick must be provided because tokensOwed calculation needs
   * the current correct tick because the ticks are only updated upon the
   * crossing of ticks
   * sqrtRatioX96 can be a current sqrtPriceX96 *or* a sqrtPriceX96 calculated
   * from a virtual tick, for external consumption
   */
  function _calculateTotalsFromTick(
    uint160 sqrtRatioX96,
    int24 realTick,
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData
  )
    internal
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    (mL, total0, total1) = calculatePositionTotals(
      realTick,
      sqrtRatioX96,
      mainData.tickLower,
      mainData.tickUpper
    );
    {
      uint256 rt0;
      uint256 rt1;
      (rL, rt0, rt1) = calculatePositionTotals(
        realTick,
        sqrtRatioX96,
        rangeData.tickLower,
        rangeData.tickUpper
      );
      total0 = total0.add(rt0);
      total1 = total1.add(rt1);
    }
    total0 = total0.add(token0.balanceOf(address(this)));
    total1 = total1.add(token1.balanceOf(address(this)));
  }

  function _calculateTotals(
    uint160 sqrtRatioX96,
    int24 tick,
    DepositPositionData memory mainData,
    DepositPositionData memory rangeData
  )
    internal
    view
    returns (
      uint256 total0,
      uint256 total1,
      uint128 mL,
      uint128 rL
    )
  {
    return _calculateTotalsFromTick(sqrtRatioX96, tick, mainData, rangeData);
  }

  /**
   * @dev Calculates total tokens obtainable and liquidity of a given position (fees + amounts in position)
   * total{0,1} is sum of tokensOwed{0,1} from each position plus sum of liquidityForAmount{0,1} for each position plus vault balance of token{0,1}
   * @param realTick Current tick (for calculating tokensOwed)
   * @param sqrtRatioX96 Current (or virtual) square root price
   * @param tickLower Lower tick of position
   * @param tickLower Upper tick of position
   * @return liquidity Liquidity of position
   * @return total0 Total amount of token0 obtainable from position
   * @return total1 Total amount of token1 obtainable from position
   */
  function calculatePositionTotals(
    int24 realTick,
    uint160 sqrtRatioX96,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint256 total0,
      uint256 total1
    )
  {
    uint256 tokensOwed0;
    uint256 tokensOwed1;
    (
      liquidity,
      total0,
      total1,
      tokensOwed0,
      tokensOwed1
    ) = calculatePositionInfo(realTick, sqrtRatioX96, tickLower, tickUpper);
    total0 = total0.add(tokensOwed0);
    total1 = total1.add(tokensOwed1);
  }

  function calculatePositionInfo(
    int24 realTick,
    uint160 sqrtRatioX96,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (
      uint128 liquidity,
      uint256 total0,
      uint256 total1,
      uint256 tokensOwed0,
      uint256 tokensOwed1
    )
  {
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
    (
      liquidity,
      feeGrowthInside0LastX128,
      feeGrowthInside1LastX128,
      tokensOwed0,
      tokensOwed1
    ) = _positionDataHelper(realTick, tickLower, tickUpper);

    uint160 sqrtPriceLower = TickMath.getSqrtRatioAtTick(tickLower);
    uint160 sqrtPriceUpper = TickMath.getSqrtRatioAtTick(tickUpper);
    (uint256 amount0, uint256 amount1) =
      getAmountsForLiquidity(
        sqrtRatioX96,
        sqrtPriceLower,
        sqrtPriceUpper,
        liquidity.toInt128()
      );
  }

  /**
   * @dev Calculates fee growth between a tick range
   * @param tick Current tick
   * @param tickLower Lower tick of range
   * @param tickUpper Upper tick of range
   * @return feeGrowthInside0X128 Fee growth of token 0 inside ticks
   * @return feeGrowthInside1X128 Fee growth of token 1 inside ticks
   */
  function getFeeGrowthInsideTicks(
    int24 tick,
    int24 tickLower,
    int24 tickUpper
  )
    internal
    view
    returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
  {
    /*
     * Underflow is Good here, actually.
     * Uniswap V3 doesn't use SafeMath here, and the cases where it does underflow,
     * it should help us get back to the rightful fee growth value of our position.
     * It would underflow only when feeGrowthGlobal{0,1}X128 has overflowed already in the V3 contract.
     * It should never underflow if feeGrowthGlobal{0,1}X128 hasn't yet overflowed.
     * Of course, if feeGrowthGlobal{0,1}X128 has overflowed twice over or more, we cannot possibly recover
     * fees from the overflow before last via underflow here, and it is possible our feeGrowthOutside values are
     * insufficently large to underflow enough to recover fees from the most recent overflow.
     * But, we rebalance frequently, so this should never be an issue.
     * This math is no different than in the v3 activePool contract and was copied from contracts/libraries/Tick.sol
     */
    uint256 feeGrowthGlobal0X128 = activePool.feeGrowthGlobal0X128();
    uint256 feeGrowthGlobal1X128 = activePool.feeGrowthGlobal1X128();
    (
      ,
      ,
      uint256 feeGrowthOutside0X128Lower,
      uint256 feeGrowthOutside1X128Lower,
      ,
      ,
      ,

    ) = activePool.ticks(tickLower);
    (
      ,
      ,
      uint256 feeGrowthOutside0X128Upper,
      uint256 feeGrowthOutside1X128Upper,
      ,
      ,
      ,

    ) = activePool.ticks(tickUpper);

    // calculate fee growth below
    uint256 feeGrowthBelow0X128;
    uint256 feeGrowthBelow1X128;
    if (tick >= tickLower) {
      feeGrowthBelow0X128 = feeGrowthOutside0X128Lower;
      feeGrowthBelow1X128 = feeGrowthOutside1X128Lower;
    } else {
      feeGrowthBelow0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Lower;
      feeGrowthBelow1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Lower;
    }

    // calculate fee growth above
    uint256 feeGrowthAbove0X128;
    uint256 feeGrowthAbove1X128;
    if (tick < tickUpper) {
      feeGrowthAbove0X128 = feeGrowthOutside0X128Upper;
      feeGrowthAbove1X128 = feeGrowthOutside1X128Upper;
    } else {
      feeGrowthAbove0X128 = feeGrowthGlobal0X128 - feeGrowthOutside0X128Upper;
      feeGrowthAbove1X128 = feeGrowthGlobal1X128 - feeGrowthOutside1X128Upper;
    }

    feeGrowthInside0X128 =
      feeGrowthGlobal0X128 -
      feeGrowthBelow0X128 -
      feeGrowthAbove0X128;
    feeGrowthInside1X128 =
      feeGrowthGlobal1X128 -
      feeGrowthBelow1X128 -
      feeGrowthAbove1X128;
  }

  /**
   * @dev Queries position liquidity
   * @param position Storage pointer to position we want to query
   */
  function positionLiquidity(Position storage position)
    internal
    view
    returns (uint128 _liquidity)
  {
    (_liquidity, , , , ) = activePool.positions(
      PositionKey.compute(address(this), position.tickLower, position.tickUpper)
    );
  }

  function getAmountsForLiquidity(
    uint160 sqrtPriceX96,
    uint160 sqrtPriceX96Lower,
    uint160 sqrtPriceX96Upper,
    int128 liquidityDelta
  ) internal pure returns (uint256 amount0, uint256 amount1) {
    if (sqrtPriceX96 <= sqrtPriceX96Lower) {
      // current tick is below the passed range; liquidity can only become in range by crossing from left to
      // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
      amount0 = SqrtPriceMath
        .getAmount0Delta(sqrtPriceX96Lower, sqrtPriceX96Upper, liquidityDelta)
        .abs();
    } else if (sqrtPriceX96 < sqrtPriceX96Upper) {
      amount0 = SqrtPriceMath
        .getAmount0Delta(sqrtPriceX96, sqrtPriceX96Upper, liquidityDelta)
        .abs();
      amount1 = SqrtPriceMath
        .getAmount1Delta(sqrtPriceX96Lower, sqrtPriceX96, liquidityDelta)
        .abs();
    } else {
      // current tick is above the passed range; liquidity can only become in range by crossing from right to
      // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
      amount1 = SqrtPriceMath
        .getAmount1Delta(sqrtPriceX96Lower, sqrtPriceX96Upper, liquidityDelta)
        .abs();
    }
  }

  /// @inheritdoc IUniswapV3MintCallback
  function uniswapV3MintCallback(
    uint256 amount0Owed,
    uint256 amount1Owed,
    bytes calldata
  ) external virtual override {
    require(msg.sender == address(activePool));
    if (amount0Owed > 0) {
      TransferHelper.safeTransfer(address(token0), msg.sender, amount0Owed);
    }
    if (amount1Owed > 0) {
      TransferHelper.safeTransfer(address(token1), msg.sender, amount1Owed);
    }
  }
}