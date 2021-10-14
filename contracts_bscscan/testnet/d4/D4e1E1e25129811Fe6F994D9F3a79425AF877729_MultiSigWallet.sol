// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

/// @title Multisignature wallet - Allows multiple parties to agree on transactions before execution.
contract MultiSigWallet {
  using SafeMath for uint256;
  using SafeCast for uint8;
  using SafeERC20 for IERC20;

  event TransactionApproved(address indexed sender, uint256 indexed transactionId);
  event ApprovalRevoked(address indexed sender, uint256 indexed transactionId);
  event TransactionSubmitted(uint256 indexed transactionId);
  event TransactionExecuted(uint256 indexed transactionId);
  event ExecutionFailed(uint256 indexed transactionId);
  event Deposited(address indexed sender, uint256 value);
  event TokenDeposited(address indexed sender, IERC20 indexed token, uint256 value);
  event NewOwnerAdded(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event RequirementChanged(uint256 required);

  enum Kind {
    Transfer,
    ChangeApprovals,
    AddOwner,
    RemoveOwner,
    ReplaceOwner
  }

  struct Transaction {
    Kind kind;
    address to;
    uint value;
    bytes data;
    address token;
    uint8 approval;
    bool executed;
  }

  uint8 constant public MAX_OWNER = 50;

  mapping (uint256 => Transaction) public transactions;
  mapping (uint256 => mapping (address => bool)) public approvals;
  mapping (address => bool) public owners;
  // address[] public owners;
  uint8 public required;
  uint8 public ownerCount;
  uint256 public transactionCount;

  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param _owners List of initial owners.
  /// @param _required Number of required confirmations.
  constructor(address[] memory _owners, uint8 _required) 
    validate(uint8(_owners.length), _required) 
  {
    required = _required;
    ownerCount = uint8(_owners.length);

    for (uint8 i=0; i<_owners.length; i++) {
      require(!owners[_owners[i]], "initial owners are duplicated");
      owners[_owners[i]] = true;
    }
  }

  /// @dev deposit native token into this contract.
  receive() external payable {
    if (msg.value > 0)
      emit Deposited(msg.sender, msg.value);
  }

  /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
  /// @param _owner Address of new owner.
  function addOwner(address _owner) external
    isValid(_owner)
    notOwner(_owner)
    validate(ownerCount + 1, required)
    returns (uint256 txnId)
  {
    txnId = _addTransaction(Kind.AddOwner, address(0), address(0), 0, abi.encode(_owner));
    approve(txnId);
  }

  /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
  /// @param _owner Address of owner.
  function removeOwner(address _owner) external
    isOwner(_owner)
    returns (uint256 txnId)
  {
    txnId = _addTransaction(Kind.RemoveOwner, address(0), address(0), 0, abi.encode(_owner));
    approve(txnId);
  }

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param _owner Address of owner to be replaced.
  /// @param _newOwner Address of new owner.
  function replaceOwner(address _owner, address _newOwner) external
    isValid(_newOwner)
    isOwner(_owner)
    notOwner(_newOwner)
    returns (uint256 txnId)
  {
    txnId = _addTransaction(Kind.ReplaceOwner, address(0), address(0), 0, abi.encode(_owner, _newOwner));
    approve(txnId);
  }

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param _required Number of required confirmations.
  function changeRequired(uint8 _required) public
    validate(ownerCount, _required)
    returns (uint256 txnId)
  {
    txnId = _addTransaction(Kind.ChangeApprovals, address(0), address(0), 0, abi.encode(_required));
    approve(txnId);
  }

  /// @dev Allows an owner to submit and approve a transaction.
  /// @param _to transaction destination address
  /// @param _value transaction value in Wei.
  /// @param _data transaction data payload.
  /// @return txnId returns transaction ID.
  function transfer(address payable _to, uint256 _value, bytes memory _data) external
    isValid(_to)
    isEnough(_value)
    returns (uint256 txnId)
  {
    txnId = _addTransaction(Kind.Transfer, address(0), _to, _value, _data);
    approve(txnId);
  }

  /// @dev Allows an owner to submit and approve a transaction on BEP-20 tokens.
  /// @param _token a BEP-20 token address
  /// @param _to transaction destination address
  /// @param _value transaction value in Wei.
  /// @param _data transaction data payload.
  /// @return txnId returns transaction ID.
  function transferToken(IERC20 _token, address payable _to, uint256 _value, bytes memory _data) external 
    isValid(_to)
    isTokenEnough(_token, _value)
    returns (uint256 txnId) 
  {
    txnId = _addTransaction(Kind.Transfer, address(_token), _to, _value, _data);
    approve(txnId);
  }

  /// @dev Allows an owner to approve a transaction.
  /// @param _txnId transaction ID.
  function approve(uint256 _txnId) public
    isOwner(msg.sender)
    hasTransaction(_txnId)
    notApproved(_txnId, msg.sender)
  {
    transactions[_txnId].approval++;
    approvals[_txnId][msg.sender] = true;

    emit TransactionApproved(msg.sender, _txnId);
    execute(_txnId);
  }

  /// @dev Allows an owner to revoke a approval for a transaction.
  /// @param _txnId transaction ID.
  function revokeApproval(uint256 _txnId) external
    isOwner(msg.sender)
    approved(_txnId, msg.sender)
    notExecuted(_txnId)
  {
    transactions[_txnId].approval--;
    approvals[_txnId][msg.sender] = false;
    
    emit ApprovalRevoked(msg.sender, _txnId);
  }

  /// @dev Allows anyone to execute a approved transaction.
  /// @param _txnId transaction ID.
  /// @return success wether it's success
  function execute(uint256 _txnId) public
    isOwner(msg.sender)
    approved(_txnId, msg.sender)
    notExecuted(_txnId)
    returns (bool success)
  {
    if (isConfirmed(_txnId)) {
      Transaction storage txn = transactions[_txnId];

      if (txn.kind == Kind.ChangeApprovals) {
        (required) = abi.decode(txn.data, (uint8));

        emit RequirementChanged(required);
      } else if (txn.kind == Kind.AddOwner) {
        (address newOwner) = abi.decode(txn.data, (address));
        owners[newOwner] = true;
        ownerCount++;

        emit NewOwnerAdded(newOwner);
      } else if (txn.kind == Kind.RemoveOwner) {
        (address oldOwner) = abi.decode(txn.data, (address));
        delete owners[oldOwner];
        ownerCount--;

        emit OwnerRemoval(oldOwner);

        if (required > ownerCount) {
          required = ownerCount;

          emit RequirementChanged(required);
        }
      } else if (txn.kind == Kind.ReplaceOwner) {
        (address oldOwner, address newOwner) = abi.decode(txn.data, (address, address));
        delete owners[oldOwner];
        owners[newOwner] = true;

        emit OwnerRemoval(oldOwner);
        emit NewOwnerAdded(newOwner);
      } else if (txn.kind == Kind.Transfer) {
        if (txn.token == address(0)) 
          payable(txn.to).transfer(txn.value);
        else 
          IERC20(txn.token).safeTransfer(payable(txn.to), txn.value);
      }
      txn.executed = true;
      emit TransactionExecuted(_txnId);

      return txn.executed;
    }
  }

  /// @dev Returns the confirmation status of a transaction.
  /// @param _txnId transaction ID.
  /// @return status confirmation status.
  function isConfirmed(uint _txnId) public view returns (bool status) {
    status = transactions[_txnId].approval >= required;
  }

  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param _token `0x` if token is native, otherwise is BEP20 token address
  /// @param _to transaction destination address
  /// @param _value transaction value in Wei.
  /// @param _data transaction data payload.
  /// @return txnId returns transaction ID.
  function _addTransaction(Kind kind, address _token, address _to, uint _value, bytes memory _data) internal
    returns (uint txnId)
  {
    txnId = transactionCount++;
    transactions[txnId] = Transaction({
      kind: kind,
      to: _to,
      value: _value,
      data: _data,
      token: _token,
      approval: 0,
      executed: false
    });
    
    emit TransactionSubmitted(txnId);
  }

  /// @dev Returns number of approvals of a transaction.
  /// @param _txnId transaction ID.
  /// @return count Number of approvals.
  function getApprovalCount(uint _txnId) external view returns (uint8 count) {
    count = transactions[_txnId].approval;
  }

  /// @dev Returns total number of transactions which filers are applied.
  /// @param _pending Include pending transactions.
  /// @param _executed Include executed transactions.
  /// @return count Total number of transactions after filters are applied.
  function getTransactionCount(bool _pending, bool _executed) external view returns (uint256 count)
  {
    for (uint256 i=0; i<transactionCount; i++)
      if (_pending && !transactions[i].executed || _executed && transactions[i].executed)
        count++;
  }

  // /// @dev Returns list of owners.
  // /// @return List of owner addresses.
  // function getOwners()
  //     public
  //     constant
  //     returns (address[])
  // {
  //     return owners;
  // }

  // /// @dev Returns array with owner addresses, which confirmed transaction.
  // /// @param transactionId Transaction ID.
  // /// @return Returns array of owner addresses.
  // function getConfirmations(uint transactionId)
  //     public
  //     constant
  //     returns (address[] _confirmations)
  // {
  //     address[] memory confirmationsTemp = new address[](owners.length);
  //     uint count = 0;
  //     uint i;
  //     for (i=0; i<owners.length; i++)
  //         if (confirmations[transactionId][owners[i]]) {
  //             confirmationsTemp[count] = owners[i];
  //             count += 1;
  //         }
  //     _confirmations = new address[](count);
  //     for (i=0; i<count; i++)
  //         _confirmations[i] = confirmationsTemp[i];
  // }

  // /// @dev Returns list of transaction IDs in defined range.
  // /// @param _from Index start position of transaction array.
  // /// @param _to Index end position of transaction array.
  // /// @param __pending Include pending transactions.
  // /// @param _executed Include executed transactions.
  // /// @return Returns array of transaction IDs.
  // function getTransactionIds(uint256 _from, uint256 _to, bool _pending, bool _executed) external view
  //   returns (uint256[] memory transactionIds)
  // {
  //   uint256[] memory temp;
  //   for (uint256 i=_from; i<=_to; i++)
  //     if (_pending && !transactions[i].executed || _executed && transactions[i].executed)
  //       temp.push(i);
    
  //   transactionIds = temp;
  // }

  modifier notOwner(address _owner) {
    require(!owners[_owner], "this address is one of the owners");
    _;
  }

  modifier isOwner(address _owner) {
    require(owners[_owner], "this address is not one of the owners");
    _;
  }

  modifier hasTransaction(uint256 _txnId) {
    require(_txnId < transactionCount, "transaction is not exist");
    _;
  }

  modifier approved(uint256 _txnId, address _owner) {
    require(approvals[_txnId][_owner], "transaction has not been approved by this owner");
    _;
  }

  modifier notApproved(uint256 _txnId, address _owner) {
    require(!approvals[_txnId][_owner], "transaction has been approved by this owner");
    _;
  }

  modifier notExecuted(uint256 _txnId) {
    require(!transactions[_txnId].executed, "transaction is executed");
    _;
  }

  modifier isValid(address _address) {
    require(_address != address(0), "this address is zero address");
    _;
  }

  modifier validate(uint8 _ownerCount, uint8 _required) {
    require(_required > 1 && _ownerCount <= MAX_OWNER && _required <= _ownerCount,
      "required and owner count is not sufficient"
    );
    _;
  }

  modifier isEnough(uint256 _value) {
    require(address(this).balance >= _value, "balance is not enough for transfer");
    _;
  }

  modifier isTokenEnough(IERC20 _token, uint256 _value) {
    require(_token.balanceOf(address(this)) >= _value, "BEP20 balance is not enough for transfer");
    _;
  }
}