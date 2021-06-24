/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}




/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
**/

pragma solidity >= 0.8.0;

abstract
contract IQLF is IERC165 {
    /**
     * @dev Check if the given address is qualified, implemented on demand.
     *
     * Requirements:
     *
     * - `account` account to be checked
     * - `data`  data to prove if a user is qualified.
     *           For instance, it can be a MerkelProof to prove if a user is in a whitelist
     *
     * Return:
     *
     * - `bool` whether the account is qualified for ITO
     * - `string` if not qualified, it contains the error message(reason)
     */
    function ifQualified (address account, bytes32[] memory data) virtual external view returns (bool, string memory);

    /**
     * @dev Logs if the given address is qualified, implemented on demand.
     */
    function logQualified (address account, bytes32[] memory data) virtual external returns (bool, string memory);

    /**
     * @dev Ensure that custom contract implements `ifQualified` amd `logQualified` correctly.
     */
    function supportsInterface(bytes4 interfaceId) virtual external override pure returns (bool) {
        return interfaceId == this.supportsInterface.selector || 
            interfaceId == (this.ifQualified.selector ^ this.logQualified.selector);
    }

    /**
     * @dev Emit when `logQualified` is called to decide if the given `address`
     * is `qualified` according to the preset rule by the contract creator and 
     * the current block `number` and the current block `timestamp`.
     */
    event Qualification(address indexed account, bool qualified, uint256 blockNumber, uint256 timestamp);
}



/**
 * @author          Yisi Liu
 * @contact         [email protected]
 * @author_time     01/06/2021
 * @maintainer      Hancheng Zhou, Yisi Liu, Andy Jiang
 * @maintain_time   06/15/2021
**/

pragma solidity >= 0.8.0;






contract HappyTokenPool is Initializable {
    struct Packed1 {
        address qualification_addr;
        uint40 password;
    }

    struct Packed2 {
        uint128 total_tokens;
        uint128 limit;
    }

    struct Packed3 {
        address token_address;
        uint32 start_time;
        uint32 end_time;
        uint32 unlock_time;
    }

    struct Pool {
        // CAUTION: DO NOT CHANGE ORDER & TYPE OF THESE VARIABLES
        // GOOGLE KEYWORDS "SOLIDITY, UPGRADEABLE CONTRACTS, STORAGE" FOR MORE INFO
        Packed1 packed1;
        Packed2 packed2;
        Packed3 packed3;
        address creator;
        address[] exchange_addrs;   // a list of ERC20 addresses for swapping
        uint128[] exchanged_tokens; // a list of amounts of swapped tokens
        uint128[] ratios;           // a list of swap ratios
                                    // length = 2 * exchange_addrs.length
                                    // [address1, target, address2, target, ...]
                                    // e.g. [1, 10]
                                    // represents 1 tokenA to swap 10 target token
                                    // note: each ratio pair needs to be coprime
        mapping(address => uint256) swapped_map;      // swapped amount of an address
    }

    // swap pool filling success event
    event FillSuccess (
        address indexed creator,
        bytes32 indexed id,
        uint256 total,
        uint256 creation_time,
        address token_address,
        string message,
        uint256 start,
        uint256 end,
        address[] exchange_addrs,
        uint128[] ratios,
        address qualification,
        uint256 limit
    );

    // swap success event
    event SwapSuccess (
        bytes32 indexed id,
        address indexed swapper,
        address from_address,
        address to_address,
        uint256 from_value,
        uint256 to_value,
        uint128 input_total
    );

    // claim success event
    event ClaimSuccess (
        bytes32 indexed id,
        address indexed claimer,
        uint256 timestamp,
        uint256 to_value,
        address token_address
    );

    // swap pool destruct success event
    event DestructSuccess (
        bytes32 indexed id,
        address indexed token_address,
        uint256 remaining_balance,
        uint128[] exchanged_values
    );

    // single token withdrawl from a swap pool success even
    event WithdrawSuccess (
        bytes32 indexed id,
        address indexed token_address,
        uint256 withdraw_balance
    );

    using SafeERC20 for IERC20;
    // CAUTION: DO NOT CHANGE ORDER & TYPE OF THESE VARIABLES
    // GOOGLE KEYWORDS "SOLIDITY, UPGRADEABLE CONTRACTS, STORAGE" FOR MORE INFO
    mapping(bytes32 => Pool) pool_by_id;    // maps an id to a Pool instance
    bytes32 private seed;
    address private DEFAULT_ADDRESS;
    uint64 public base_time;
    uint32 private nonce;

    function initialize(uint64 _base_time) public initializer {
        seed = keccak256(abi.encodePacked("MASK", block.timestamp, msg.sender));
        DEFAULT_ADDRESS = address(0);
        base_time = _base_time;
    }

    /**
     * @dev 
     * fill_pool() creates a swap pool with specific parameters from input
     * _hash                sha3-256(password)
     * _start               start time delta, real start time = base_time + _start
     * _end                 end time delta, real end time = base_time + _end
     * message              swap pool creation message, only stored in FillSuccess event
     * _exchange_addrs      swap token list (0x0 for ETH, only supports ETH and ERC20 now)
     * _ratios              swap pair ratio list
     * _unlock_time         unlock time delta real unlock time = base_time + _unlock_time
     * _token_addr          swap target token address
     * _total_tokens        target token total swap amount
     * _limit               target token single swap limit
     * _qualification       the qualification contract address based on IQLF to determine qualification
     * This function takes the above parameters and creates the pool. _total_tokens of the target token
     * will be successfully transferred to this contract securely on a successful run of this function.
    **/
    function fill_pool (bytes32 _hash, uint256 _start, uint256 _end, string memory _message,
                        address[] memory _exchange_addrs, uint128[] memory _ratios, uint256 _unlock_time,
                        address _token_addr, uint256 _total_tokens, uint256 _limit, address _qualification)
    public payable {
        nonce ++;
        require(_start < _end, "Start time should be earlier than end time.");
        require(_end < _unlock_time || _unlock_time == 0, "End time should be earlier than unlock time");
        require(_limit <= _total_tokens, "Limit needs to be less than or equal to the total supply");
        require(_total_tokens < 2 ** 128, "No more than 2^128 tokens(incluidng decimals) allowed");
        require(_exchange_addrs.length > 0, "Exchange token addresses need to be set");
        require(_ratios.length == 2 * _exchange_addrs.length, "Size of ratios = 2 * size of exchange_addrs");

        bytes32 _id = keccak256(abi.encodePacked(msg.sender, block.timestamp, nonce, seed));
        Pool storage pool = pool_by_id[_id];
        pool.packed1 = Packed1(_qualification, uint40(uint256(_hash) >> 216));
        pool.packed2 = Packed2(uint128(_total_tokens), uint128(_limit));
        pool.packed3 = Packed3(_token_addr, uint32(_start), uint32(_end), uint32(_unlock_time));
        pool.creator = msg.sender;
        pool.exchange_addrs = _exchange_addrs;

        // Init each token swapped amount to 0
        for (uint256 i = 0; i < _exchange_addrs.length; i++) {
            if (_exchange_addrs[i] != DEFAULT_ADDRESS) {
                // TODO: Is there a better way to validate an ERC20?
                require(IERC20(_exchange_addrs[i]).totalSupply() > 0, "Not a valid ERC20");
            }
            pool.exchanged_tokens.push(0); 
        }

        pool.ratios = _ratios;                                          // 256 * k
        IERC20(_token_addr).safeTransferFrom(msg.sender, address(this), _total_tokens);

        {
            // Solidity has stack depth limitation: "Stack too deep, try removing local variables"
            // add local variables as a workaround
            uint256 total_tokens = _total_tokens;
            address token_addr = _token_addr;
            string memory message = _message;
            uint256 start = _start;
            uint256 end = _end;
            address[] memory exchange_addrs = _exchange_addrs;
            uint128[] memory ratios = _ratios;
            address qualification = _qualification;
            uint256 limit = _limit;

            emit FillSuccess(
                msg.sender,
                _id,
                total_tokens,
                block.timestamp,
                token_addr,
                message,
                start,
                end,
                exchange_addrs,
                ratios,
                qualification,
                limit
            );
        }
    }

    /**
     * @dev
     * swap() allows users to swap tokens in a swap pool
     * id                   swap pool id
     * verification         sha3-256(sha3-256(password)[:40]+swapper_address)
     * validation           sha3-256(swapper_address)
     * exchange_addr_i     the index of the exchange address of the list
     * input_total          the input amount of the specific token
     * This function is called by the swapper who approves the specific ERC20 or directly transfer the ETH
     * first and wants to swap the desired amount of the target token. The swapped amount is calculated
     * based on the pool ratio. After swap successfully, the same account can not swap the same pool again.
    **/

    function swap(
        bytes32 id,
        bytes32 verification,
        uint256 exchange_addr_i,
        uint128 input_total,
        bytes32[] memory data
    )
    public payable returns (uint256 swapped) {

        uint128 from_value = input_total;
        Pool storage pool = pool_by_id[id];
        Packed1 memory packed1 = pool.packed1;
        Packed2 memory packed2 = pool.packed2;
        Packed3 memory packed3 = pool.packed3;
        {
            bool qualified;
            string memory errorMsg;
            (qualified, errorMsg) = IQLF(packed1.qualification_addr).logQualified(msg.sender, data);
            require(qualified, errorMsg);
        }
        require (packed3.start_time + base_time < block.timestamp, "Not started.");
        require (packed3.end_time + base_time > block.timestamp, "Expired.");
        // sha3(sha3(passowrd)[:40] + msg.sender) so that the raw password will never appear in the contract
        require (
            verification == keccak256(abi.encodePacked(uint256(packed1.password), msg.sender)),
            'Wrong Password'
        );

        // revert if the pool is empty
        require (packed2.total_tokens > 0, "Out of Stock");

        address exchange_addr = pool.exchange_addrs[exchange_addr_i];
        uint256 ratioA = pool.ratios[exchange_addr_i*2];
        uint256 ratioB = pool.ratios[exchange_addr_i*2 + 1];
        // check if the input is enough for the desired transfer
        if (exchange_addr == DEFAULT_ADDRESS) {
            require(msg.value == from_value, 'No enough ether.');
        }

        uint128 swapped_tokens = SafeCast.toUint128(SafeMath.div(SafeMath.mul(from_value, ratioB), ratioA));
        require(swapped_tokens > 0, "Better not draw water with a sieve");

        if (swapped_tokens > packed2.limit) {
            // don't be greedy - you can only get at most limit tokens
            swapped_tokens = packed2.limit;
            // Update from_value
            from_value = SafeCast.toUint128(SafeMath.div(SafeMath.mul(packed2.limit, ratioA), ratioB));
        } else if (swapped_tokens > packed2.total_tokens ) {
            // if the left tokens are not enough
            swapped_tokens = packed2.total_tokens;
            // Update from_value
            from_value = SafeCast.toUint128(SafeMath.div(SafeMath.mul(packed2.total_tokens , ratioA), ratioB));
            // return the eth
            if (exchange_addr == DEFAULT_ADDRESS)
                payable(msg.sender).transfer(msg.value - from_value);
        }
        // make sure again
        require(swapped_tokens <= packed2.limit);
        // update exchanged
        pool.exchanged_tokens[exchange_addr_i] = SafeCast.toUint128(
            SafeMath.add(
                pool.exchanged_tokens[exchange_addr_i],
                from_value
            )
        );

        // penalize greedy attackers by placing duplication check at the very last
        require (pool.swapped_map[msg.sender] == 0, "Already swapped");

        // update the remaining tokens and swapped token mapping
        pool.packed2.total_tokens = SafeCast.toUint128(SafeMath.sub(packed2.total_tokens, swapped_tokens));
        pool.swapped_map[msg.sender] = swapped_tokens;

        // transfer the token after state changing
        // ETH comes with the tx, but ERC20 does not - INPUT
        if (exchange_addr != DEFAULT_ADDRESS) {
            IERC20(exchange_addr).safeTransferFrom(msg.sender, address(this), from_value);
        }

        {
            // Solidity has stack depth limitation: "Stack too deep, try removing local variables"
            // add local variables as a workaround
            // Swap success event
            bytes32 _id = id;
            uint128 _input_total = input_total;
            emit SwapSuccess(
                _id,
                msg.sender,
                exchange_addr,
                packed3.token_address,
                from_value,
                swapped_tokens,
                _input_total
            );
        }

        // if unlock_time == 0, transfer the swapped tokens to the recipient address (msg.sender) - OUTPUT
        // if not, claim() needs to be called to get the token
        if (packed3.unlock_time == 0) {
            IERC20(packed3.token_address).safeTransfer(msg.sender, swapped_tokens);
            emit ClaimSuccess(id, msg.sender, block.timestamp, swapped_tokens, packed3.token_address);
        }
            
        return swapped_tokens;
    }

    /**
     * check_availability() returns a bunch of pool info given a pool id
     * id                    swap pool id
     * this function returns 1. exchange_addrs that can be used to determine the index
     *                       2. remaining target tokens
     *                       3. if started
     *                       4. if ended
     *                       5. swapped amount of the query address
     *                       5. exchanged amount of each token
    **/

    function check_availability (bytes32 id)
        external
        view
        returns (
            address[] memory exchange_addrs,
            uint256 remaining,
            bool started,
            bool expired,
            bool unlocked,
            uint256 unlock_time,
            uint256 swapped,
            uint128[] memory exchanged_tokens
        )
    {
        Pool storage pool = pool_by_id[id];
        Packed3 memory packed3 = pool.packed3;
        return (
            pool.exchange_addrs,                                                // exchange_addrs 0x0 means destructed
            pool.packed2.total_tokens,                                          // remaining
            block.timestamp > packed3.start_time + base_time,                   // started
            block.timestamp > packed3.end_time + base_time,                     // expired
            block.timestamp > packed3.unlock_time + base_time,                  // unlocked
            packed3.unlock_time + base_time,                                    // unlock_time
            pool.swapped_map[msg.sender],                                       // swapped number 
            pool.exchanged_tokens                                               // exchanged tokens
        );
    }

    function claim(bytes32[] calldata ito_ids) external {
        for (uint256 i = 0; i < ito_ids.length; i++) {
            Pool storage pool = pool_by_id[ito_ids[i]];
            Packed3 memory packed3 = pool.packed3;
            if (packed3.unlock_time == 0)
                continue;
            if (packed3.unlock_time + base_time > block.timestamp)
                continue;
            uint256 claimed_amount = pool.swapped_map[msg.sender];
            if (claimed_amount == 0)
                continue;
            pool.swapped_map[msg.sender] = 0;
            IERC20(packed3.token_address).safeTransfer(msg.sender, claimed_amount);
            emit ClaimSuccess(ito_ids[i], msg.sender, block.timestamp, claimed_amount, packed3.token_address);
        }
    }

    function setUnlockTime(bytes32 id, uint32 _unlock_time) public {
        Pool storage pool = pool_by_id[id];
        uint32 packed3_unlock_time = pool.packed3.unlock_time;
        require(pool.creator == msg.sender, "Pool Creator Only");
        require(block.timestamp < (packed3_unlock_time + base_time), "Too Late");
        require(packed3_unlock_time != 0, "Not eligible when unlock_time is 0");
        require(_unlock_time != 0, "Cannot set to 0");
        pool.packed3.unlock_time = _unlock_time;
    }

    /**
     * destruct() destructs the given pool given the pool id
     * id                    swap pool id
     * this function can only be called by the pool creator. after validation, it transfers all the remaining token 
     * (if any) and all the swapped tokens to the pool creator. it will then destruct the pool by reseting almost 
     * all the variables to zero to get the gas refund.
     * note that this function may not work if a pool needs to transfer over ~200 tokens back to the address due to 
     * the block gas limit. we have another function withdraw() to help the pool creator to withdraw a single token 
    **/

    function destruct (bytes32 id) public {
        Pool storage pool = pool_by_id[id];
        Packed3 memory packed3 = pool.packed3;
        require(msg.sender == pool.creator, "Only the pool creator can destruct.");

        uint256 expiration = pool.packed3.end_time + base_time;
        uint256 remaining_tokens = pool.packed2.total_tokens;
        // only after expiration or the pool is empty
        require(expiration <= block.timestamp || remaining_tokens == 0, "Not expired yet");

        // if any left in the pool
        if (remaining_tokens != 0) {
            IERC20(packed3.token_address).safeTransfer(msg.sender, remaining_tokens);
        }
        
        // transfer the swapped tokens accordingly
        // note this loop may exceed the block gas limit so if >200 exchange_addrs this may not work
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            if (pool.exchanged_tokens[i] > 0) {
                // ERC20
                if (pool.exchange_addrs[i] != DEFAULT_ADDRESS)
                    IERC20(pool.exchange_addrs[i]).safeTransfer(msg.sender, pool.exchanged_tokens[i]);
                // ETH
                else
                    payable(msg.sender).transfer(pool.exchanged_tokens[i]);
            }
        }
        emit DestructSuccess(id, packed3.token_address, remaining_tokens, pool.exchanged_tokens);

        // Gas Refund
        pool.packed1 = Packed1(DEFAULT_ADDRESS, 0);
        pool.packed2 = Packed2(0, 0);
        for (uint256 i = 0; i < pool.exchange_addrs.length; i++) {
            pool.exchange_addrs[i] = DEFAULT_ADDRESS;
            pool.exchanged_tokens[i] = 0;
            pool.ratios[i*2] = 0;
            pool.ratios[i*2+1] = 0;
        }
    }

    /**
     * withdraw() transfers out a single token after a pool is expired or empty 
     * id                    swap pool id
     * addr_i                withdraw token index
     * this function can only be called by the pool creator. after validation, it transfers the addr_i th token 
     * out to the pool creator address.
    **/

    function withdraw (bytes32 id, uint256 addr_i) public {
        Pool storage pool = pool_by_id[id];
        require(msg.sender == pool.creator, "Only the pool creator can withdraw.");

        uint256 withdraw_balance = pool.exchanged_tokens[addr_i];
        require(withdraw_balance > 0, "None of this token left");
        uint256 expiration = pool.packed3.end_time + base_time;
        uint256 remaining_tokens = pool.packed2.total_tokens;
        // only after expiration or the pool is empty
        require(expiration <= block.timestamp || remaining_tokens == 0, "Not expired yet");
        address token_address = pool.exchange_addrs[addr_i];

        // clear the record
        pool.exchanged_tokens[addr_i] = 0;

        // ERC20
        if (token_address != DEFAULT_ADDRESS)
            IERC20(token_address).safeTransfer(msg.sender, withdraw_balance);
        // ETH
        else
            payable(msg.sender).transfer(withdraw_balance);
        emit WithdrawSuccess(id, token_address, withdraw_balance);
    }
}