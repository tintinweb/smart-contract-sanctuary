/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.5.15;
pragma experimental ABIEncoderV2;

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
library SafeMath128 {
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
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
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
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function sub(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b <= a, errorMessage);
        uint128 c = a - b;

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
    function mul(uint128 a, uint128 b) internal pure returns (uint128) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint128 c = a * b;
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
    function div(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function div(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b > 0, errorMessage);
        uint128 c = a / b;
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
    function mod(uint128 a, uint128 b) internal pure returns (uint128) {
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
    function mod(uint128 a, uint128 b, string memory errorMessage) internal pure returns (uint128) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface WETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function balanceOf(address account) external returns (uint256);
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
        (bool success, ) = recipient.call.value(amount)("");
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
        (bool success, bytes memory returndata) = target.call.value(weiValue)(data);
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

contract SafeCast {
    uint256 constant two128 = 2**128;
    uint256 constant two32 = 2**32;

    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < two32, "safe32");
        return uint32(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < two128, "safe128");
        return uint128(n);
    }
}

/**
 * @title CoverRate
 * @author Yam Finance
 *
 * Interest setter that sets interest based on a polynomial of the usage percentage of the market.
 * Interest = C_0 + C_1 * U^(2^0) + C_2 * U^(2^1) + C_3 * U^(2^2) ... C_8 * U^(2^7)
 * i.e.: coefs = [0, 20, 10, 60, 0, 10] = 0 + 20 * util^0 + 10 * util^2 +
 */
contract CoverRate is SafeCast {
    using SafeMath for uint256;
    using SafeMath128 for uint128;

    // ============ Constants ============

    uint128 constant PERCENT = 100;

    uint128 constant BASE = 10**18;

    uint128 constant SECONDS_IN_A_YEAR = 60 * 60 * 24 * 365;

    uint128 constant BYTE = 8;

    // ============ Storage ============

    uint64 rate_storage;

    // ============ Constructor ============

    function intialize_rate(uint64 coefficients) internal {
        // verify that all coefficients add up to 100%
        uint256 sumOfCoefficients = 0;
        for (
            uint256 actual_coefficients = coefficients;
            actual_coefficients != 0;
            actual_coefficients >>= BYTE
        ) {
            sumOfCoefficients += actual_coefficients % 256;
        }
        require(sumOfCoefficients == PERCENT, "Coefficients must sum to 100");

        // store the params
        rate_storage = coefficients;
    }

    // ============ Public Functions ============

    /**
     * Get the interest rate given some utilized and total amounts. The interest function is a
     * polynomial function of the utilization (utilized / total) of the market.
     *
     *   - If both are zero, then the utilization is considered to be equal to 0.
     *
     * @return The interest rate per second (times 10 ** 18)
     */
    function getInterestRate(uint128 utilized, uint128 total)
        public
        view
        returns (uint128)
    {
        if (utilized == 0) {
            return 0;
        }
        if (utilized > total) {
            return BASE;
        }

        // process the first coefficient
        uint256 coefficients = rate_storage;
        uint256 result = uint8(coefficients) * BASE;
        coefficients >>= BYTE;

        // initialize polynomial as the utilization
        // no safeDiv since total must be non-zero at this point
        uint256 polynomial = uint256(BASE).mul(utilized) / total;

        // for each non-zero coefficient...
        while (true) {
            // gets the lowest-order byte
            uint256 coefficient = uint256(uint8(coefficients));

            // if non-zero, add to result
            if (coefficient != 0) {
                // no safeAdd since there are at most 16 coefficients
                // no safeMul since (coefficient < 256 && polynomial <= 10**18)
                result += coefficient * polynomial;

                // break if this is the last non-zero coefficient
                if (coefficient == coefficients) {
                    break;
                }
            }

            // double the order of the polynomial term
            // no safeMul since polynomial <= 10^18
            // no safeDiv since the divisor is a non-zero constant
            polynomial = (polynomial * polynomial) / BASE;

            // move to next coefficient
            coefficients >>= BYTE;
        }

        // normalize the result
        // no safeDiv since the divisor is a non-zero constant
        return uint128(result / (SECONDS_IN_A_YEAR * PERCENT));
    }

    /**
     * Get all of the coefficients of the interest calculation, starting from the coefficient for
     * the first-order utilization variable.
     *
     * @return The coefficients
     */
    function getCoefficients() public view returns (uint128[] memory) {
        // allocate new array with maximum of 16 coefficients
        uint128[] memory result = new uint128[](8);

        // add the coefficients to the array
        uint128 numCoefficients = 0;
        for (
            uint128 coefficients = rate_storage;
            coefficients != 0;
            coefficients >>= BYTE
        ) {
            result[numCoefficients] = coefficients % 256;
            numCoefficients++;
        }

        // modify result.length to match numCoefficients
        assembly {
            mstore(result, numCoefficients)
        }

        return result;
    }
}

contract CoverPricing is CoverRate {
    using SafeMath128 for uint128;

    uint128 public max_duration;

    // ============ Functions ============

    /// @notice Price a given
    function price(
        uint128 coverageAmount,
        uint128 duration,
        uint128 utilized,
        uint128 reserves
    ) public view returns (uint128) {
        return _price(coverageAmount, duration, utilized, reserves);
    }

    function _price(
        uint128 coverageAmount,
        uint128 duration,
        uint128 utilized,
        uint128 reserves
    ) internal view returns (uint128) {
        require(duration <= max_duration, "duration > max duration");
        uint128 new_util = safe128(uint256(utilized).add(coverageAmount));
        uint128 rate = getInterestRate(new_util, reserves);

        // price = amount * rate_per_second * duration / 10**18
        uint128 coverage_price =
            uint128(uint256(coverageAmount).mul(rate).mul(duration).div(BASE));

        return coverage_price;
    }
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract UmbrellaMetaPool is CoverPricing {
    using SafeMath128 for uint128;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Emitted when creating a new protection
    event NewProtection(
        string indexed concept,
        uint128 amount,
        uint32 duration,
        uint128 coverage_price
    );
    /// @dev Emitted when adding to reserves
    event ProvideCoverage(address indexed provider, uint128 amount);
    /// @dev Emitted when Arbiter is paid
    event ArbiterPaid(uint256 amount);
    /// @dev Emitted when Creator is paid
    event CreatorPaid(uint256 amount);
    /// @dev Emitted when withdrawing provided payTokens
    event Withdraw(address indexed provider, uint256 amount);
    /// @dev Emitted after claiming a protection payout
    event Claim(address indexed holder, uint256 indexed pid, uint256 payout);
    /// @dev Emitted after claiming premiums
    event ClaimPremiums(address indexed claimer, uint256 premiums_claimed);
    /// @dev Emitted after a protection's premiums are swept to premium pool
    event Swept(uint256 indexed pid, uint128 premiums_paid);
    // ============ Modifiers ============

    modifier hasArbiter() {
        require(arbSet, "ProtectionPool::hasArbiter: !arbiter");
        _;
    }

    modifier onlyArbiter() {
        require(msg.sender == arbiter, "ProtectionPool::onlyArbiter: !arbiter");
        _;
    }

    function updateGlobalTPS(uint256 timestamp) internal {
        // increase total protection seconds
        uint256 newGlobalTokenSecondsProvided =
            (timestamp - lastUpdatedTPS).mul(totalShares);
        totalProtectionSeconds = totalProtectionSeconds.add(
            newGlobalTokenSecondsProvided
        );
        lastUpdatedTPS = safe32(timestamp);
    }

    function updateTokenSecondsProvided(address account) internal {
        uint256 timestamp = block.timestamp;
        uint256 newTokenSecondsProvided =
            (timestamp - providers[account].lastUpdate).mul(
                providers[account].shares
            );

        // update user protection seconds, and last updated
        providers[account].totalTokenSecondsProvided = providers[account]
            .totalTokenSecondsProvided
            .add(newTokenSecondsProvided);
        providers[account].lastUpdate = safe32(timestamp);

        // increase total protection seconds
        updateGlobalTPS(timestamp);
    }

    // ============ Constants ============

    // TODO: Move to factory
    /// @notice Max arbiter fee, 10%.
    /*uint128 public constant MAX_ARB_FEE = 10**17;
    /// @notice Max creator fee, 5%.
    uint128 public constant MAX_CREATE_FEE = 5*10**16; */
    // :TODO

    /// @notice How long liquidity is locked up (7 days)
    uint128 public lockupPeriod;
    /// @notice How long a withdrawl request is valid for (2 weeks)
    uint128 public withdrawGracePeriod;

    /// @notice WETH address
    WETH9 public constant WETH =
        WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // ============ Storage ============
    /// @notice Whether the pool has been initialized
    bool public initialized;
    /// @notice Whether the pool has an arbiter
    bool public arbSet;
    bool public accepted;

    // === Pool storage ===
    /// @notice List of protected concepts, i.e. ["Dydx", "Compound", "Aave"]
    string[] private coveredConcepts;
    /// @notice Description of the pool; i.e. yEarn yVaults
    string private description;
    /// @notice Token used for protection payment and payout
    address public payToken;
    /// @notice utilized payToken
    uint128 public utilized;
    /// @notice total payToken
    uint128 public reserves;
    ///@notice Total shares of reserves
    uint128 public totalShares;
    /// @notice Minimum number of payTokens to open a position
    uint128 public minPay;
    /// @notice Factory used to create this contract
    address public factory;
    /// @notice Last global update to protection seconds
    uint32 public lastUpdatedTPS;
    /// @notice Total global protection seconds
    uint256 public totalProtectionSeconds;
    ///@notice Total premiums accumulated
    uint256 public premiumsAccum;

    // === Creator storage ===
    /// @notice Creator fee
    uint128 private creatorFee;
    /// @notice Accumulated Creator Fee
    uint128 private creatorFees;
    /// @notice Address that is the creator of the pool
    address private creator;

    // === Arbiter storage ===
    /// @notice Arbiter Fee
    uint128 private arbiterFee;
    /// @notice Accumulated Arbiter Fee
    uint128 private arbiterFees;
    /// @notice Address that is the arbiter over the pool
    address private arbiter;

    // === Rollover storage ===
    /// @notice % of premiums rolled into provided coverage
    uint128 public rollover;

    // === Concept status storage ===
    /// @notice Array of protections
    Protection[] public protections;

    /// @notice Claim times for concepts
    uint32[][] public claimTimes;

    ///@notice Protections mapping
    mapping(address => uint256[]) public protectionsForAddress;
    ///@notice Provider mapping
    mapping(address => ProtectionProvider) public providers;

    // ============ Structs & Enums ============
    enum Status {Active, Swept, Claimed}

    struct Parameters {
        address payToken_;
        uint64 coefficients;
        uint128 maxDuration_;
        UmbrellaMetaPool.Fees fees;
        uint128 minPay_;
        uint128 lockupPeriod_;
        uint128 withdrawGracePeriod_;
        string[] coveredConcepts_;
        string description_;
        address creator_;
        address arbiter_;
    }

    struct LastClaim {
        uint256 lastGlobalTPS;
        uint256 lastPTPS;
    }

    struct ProtectionProvider {
        uint256 totalTokenSecondsProvided;
        uint256 premiumIndex;
        LastClaim lastClaim;
        uint128 shares;
        uint32 lastUpdate;
        uint32 lastProvide;
        uint32 withdrawInitiated;
    }

    struct Protection {
        // slot 1
        uint128 coverageAmount;
        uint128 paid;
        // slot 2
        address holder;
        uint32 start;
        uint32 expiry;
        uint8 conceptIndex;
        Status status;
    }

    struct PoolInfo {
        string[] concepts;
        string description;
    }

    struct CreatorInfo {
        uint128 creatorFeePerc;
        uint128 creatorFeesAvailable;
        address creatorAddr;
    }

    struct ArbiterInfo {
        uint128 arbiterFeePerc;
        uint128 arbiterFeesAvailable;
        address arbiterAddr;
    }

    struct Fees {
        uint128 creatorFee;
        uint128 arbiterFee;
        uint128 rollover;
    }

    // ============ Constructor ============

    function initialize(Parameters memory parameters) public {
        require(!initialized, "initialized");
        initialized = true;

        // TODO: Move to factory
        /* require(coveredConcepts_.length < 16, "too many concepts");
        require(uint256(fees.creatorFee).add(fees.arbiterFee).add(fees.rollover) <= BASE, "fees > 100%"); */
        /* require(arbiterFee_ <= MAX_ARB_FEE, "!arb fee"); */
        /* require(creatorFee_ <= MAX_CREATE_FEE, "!create fee"); */
        // :TODO

        intialize_rate(parameters.coefficients);

        payToken = parameters.payToken_;
        max_duration = parameters.maxDuration_;
        arbiterFee = parameters.fees.arbiterFee;
        creatorFee = parameters.fees.creatorFee;
        rollover = parameters.fees.rollover;
        coveredConcepts = parameters.coveredConcepts_;
        description = parameters.description_;
        creator = parameters.creator_;
        arbiter = parameters.arbiter_;
        minPay = parameters.minPay_;
        lockupPeriod = parameters.lockupPeriod_;
        withdrawGracePeriod = parameters.withdrawGracePeriod_;
        claimTimes = new uint32[][](parameters.coveredConcepts_.length);

        if (parameters.creator_ == parameters.arbiter_) {
            // auto accept if creator is arbiter
            arbSet = true;
            accepted = true;
        }
    }

    // ============ View Functions ============

    function getPoolInfo() public view returns (PoolInfo memory) {
        return PoolInfo({concepts: coveredConcepts, description: description});
    }

    function getCreatorInfo() public view returns (CreatorInfo memory) {
        return
            CreatorInfo({
                creatorFeePerc: creatorFee,
                creatorFeesAvailable: creatorFees,
                creatorAddr: creator
            });
    }

    function getArbiterInfo() public view returns (ArbiterInfo memory) {
        return
            ArbiterInfo({
                arbiterFeePerc: arbiterFee,
                arbiterFeesAvailable: arbiterFees,
                arbiterAddr: arbiter
            });
    }

    function getConcepts() public view returns (string[] memory) {
        string[] memory concepts = coveredConcepts;
        return concepts;
    }

    function getConceptIndex(string memory concept)
        public
        view
        returns (uint256)
    {
        for (uint8 i = 0; i < coveredConcepts.length; i++) {
            if (
                keccak256(abi.encodePacked(coveredConcepts[i])) ==
                keccak256(abi.encodePacked(concept))
            ) {
                return i;
            }
        }
        require(false, "!concept");
    }

    function getProtectionInfo(uint256 pid)
        public
        view
        returns (Protection memory)
    {
        return protections[pid];
    }

    /// @notice Current coverage provider total protection seconds
    function currentProviderTPS(address who) public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 newTokenSecondsProvided =
            (timestamp - providers[who].lastUpdate).mul(providers[who].shares);
        return
            providers[who].totalTokenSecondsProvided.add(
                newTokenSecondsProvided
            );
    }

    /// @notice Current coverage provider total protection seconds
    function currentTotalTPS() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 newGlobalTokenSecondsProvided =
            (timestamp - lastUpdatedTPS).mul(totalShares);
        return totalProtectionSeconds.add(newGlobalTokenSecondsProvided);
    }

    /// @notice Current coverage provider total protection seconds
    function currentPrice(uint128 coverageAmount, uint128 duration)
        public
        view
        returns (uint256)
    {
        return _price(coverageAmount, duration, utilized, reserves);
    }

    // ============ Modifying Protection Buyer Functions ============

    /// @notice Purchase protection
    /// @dev accepts ETH payment if payToken is WETH
    function buyProtection(
        uint8 conceptIndex,
        uint128 coverageAmount,
        uint128 duration,
        uint128 maxPay,
        uint256 deadline
    ) public payable hasArbiter {
        // check deadline
        require(block.timestamp <= deadline, "buy:!deadline");
        require(conceptIndex < coveredConcepts.length, "buy:!conceptIndex");

        // price coverage
        uint128 coverage_price =
            _price(coverageAmount, duration, utilized, reserves);

        // check payment
        require(
            uint256(utilized).add(coverageAmount) <= reserves,
            "buy: overutilized"
        );
        require(
            coverage_price >= minPay && coverage_price <= maxPay,
            "buy:!pay"
        );
        // push protection onto array
        // protection buying stops in year 2106 due to safe cast
        protections.push(
            Protection({
                coverageAmount: coverageAmount,
                paid: coverage_price,
                holder: msg.sender,
                start: safe32(block.timestamp),
                expiry: safe32(block.timestamp + duration),
                conceptIndex: conceptIndex,
                status: Status.Active
            })
        );

        protectionsForAddress[msg.sender].push(protections.length - 1);

        // increase utilized
        utilized = utilized.add(coverageAmount);

        if (payToken == address(WETH) && msg.value > 0) {
            // wrap eth => WETH if necessary
            uint256 remainder =
                msg.value.sub(coverage_price, "buy:underpayment");
            WETH.deposit.value(coverage_price)();

            // send back excess, 2300 gas
            if (remainder > 0) {
                msg.sender.transfer(remainder);
            }
        } else {
            require(msg.value == 0, "buy:!WETH");
            IERC20(payToken).safeTransferFrom(
                msg.sender,
                address(this),
                coverage_price
            );
        }

        // events
        emit NewProtection(
            coveredConcepts[conceptIndex],
            coverageAmount,
            safe32(duration),
            coverage_price
        );
    }

    function isSettable(uint256 pid) public view returns (bool) {
        Protection memory protection = protections[pid];
        if (protection.status != Status.Active) {
            return false;
        }
        return
            _hasSettlement(
                protection.conceptIndex,
                protection.start,
                protection.expiry
            );
    }

    function _hasSettlement(
        uint32 index,
        uint32 start,
        uint32 expiry
    ) internal view returns (bool) {
        uint32[] memory claimTimesForIndex = claimTimes[index];
        // early return if no claimtimes
        if (claimTimesForIndex.length == 0) {
            return false;
        }
        // early return if start > all claimtimes
        if (start > claimTimesForIndex[claimTimesForIndex.length - 1]) {
            return false;
        }
        // early return if expiry before first claimtime
        if (expiry < claimTimesForIndex[0]) {
            return false;
        }
        for (uint32 i = 0; i < claimTimesForIndex.length; i++) {
            // continue until start < claimtime
            if (start > claimTimesForIndex[i]) {
                continue;
            }

            // check if expiry > claimtime
            if (expiry >= claimTimesForIndex[i]) {
                return true;
            } else {
                return false;
            }
        }
    }

    function claim(uint256 pid) public {
        updateGlobalTPS(block.timestamp);
        Protection storage protection = protections[pid];
        require(protection.holder == msg.sender, "claim:!owner");

        // ensure: settling, active, and !expiry
        require(protection.status == Status.Active, "claim:!active");
        require(
            _hasSettlement(
                protection.conceptIndex,
                protection.start,
                protection.expiry
            ),
            "claim:!settlement"
        );

        protection.status = Status.Claimed;

        // decrease utilized and reserves
        utilized = utilized.sub(protection.coverageAmount);
        reserves = reserves.sub(protection.coverageAmount);

        // transfer coverage + payment back to coverage holder
        uint256 payout = protection.coverageAmount.add(protection.paid);
        IERC20(payToken).safeTransfer(protection.holder, payout);
        emit Claim(protection.holder, pid, payout);
    }

    // ============ Provider Functions ===========

    /// @notice Balance of provider in terms of shares
    function balanceOf(address who) public view returns (uint256) {
        return providers[who].shares;
    }

    /// @notice Balance of a provider in terms of payToken
    function balanceOfUnderlying(address who) public view returns (uint256) {
        uint256 shares = providers[who].shares;
        return shares.mul(reserves).div(totalShares);
    }

    function provideCoverage() public payable hasArbiter {
        require(payToken == address(WETH), "paytoken!WETH");
        uint128 amount = uint128(msg.value);
        require(amount > 0, "provide:amount 0");
        WETH.deposit.value(amount)();
        updateTokenSecondsProvided(msg.sender);
        _claimPremiums();
        enter(amount);
        emit ProvideCoverage(msg.sender, amount);
    }

    ///@notice Provide coverage - liquidity is locked for at minimum 1 week
    function provideCoverage(uint128 amount) public hasArbiter {
        updateTokenSecondsProvided(msg.sender);
        require(amount > 0, "provide:amount 0");
        _claimPremiums();
        enter(amount);
        IERC20(payToken).safeTransferFrom(msg.sender, address(this), amount);
        emit ProvideCoverage(msg.sender, amount);
    }

    ///@notice initiates a withdraw request
    function initiateWithdraw() public {
        // update withdraw time iff end of grace period or have a superseding lock that ends after grace period
        uint128 wgp = withdrawGracePeriod;
        if (
            block.timestamp > providers[msg.sender].withdrawInitiated + wgp ||
            providers[msg.sender].lastProvide + lockupPeriod >
            providers[msg.sender].withdrawInitiated + wgp
        ) {
            providers[msg.sender].withdrawInitiated = safe32(block.timestamp);
        }
    }

    ///@notice Withdraw a specified number of payTokens
    function withdrawUnderlying(uint128 amount) public {
        updateTokenSecondsProvided(msg.sender);
        uint128 asShares =
            uint128(uint256(amount).mul(totalShares).div(reserves));
        _withdraw(asShares);
    }

    ///@notice Withdraw a specified number of shares
    function withdraw(uint128 amount) public {
        updateTokenSecondsProvided(msg.sender);
        _withdraw(amount);
    }

    function _withdraw(uint128 asShares) internal {
        uint128 lp = lockupPeriod;
        require(
            providers[msg.sender].withdrawInitiated + lp < block.timestamp,
            "withdraw:locked"
        );
        require(
            providers[msg.sender].lastProvide + lp < block.timestamp,
            "withdraw:locked2"
        );
        require(
            providers[msg.sender].withdrawInitiated + withdrawGracePeriod >=
                block.timestamp,
            "withdraw:expired"
        );

        // get premiums
        _claimPremiums();

        // update reserves & balance
        uint128 underlying = exit(asShares);
        require(reserves >= utilized, "withdraw:!liquidity");
        // payout
        IERC20(payToken).safeTransfer(msg.sender, underlying);
        emit Withdraw(msg.sender, underlying);
    }

    ///@notice Given an amount of payTokens, update balance, shares, and reserves
    function enter(uint128 underlying) internal {
        providers[msg.sender].lastProvide = safe32(block.timestamp);
        uint128 res = reserves;
        uint128 ts = totalShares;
        if (ts == 0 || res == 0) {
            providers[msg.sender].shares = safe128(
                uint256(providers[msg.sender].shares).add(underlying)
            );
            totalShares = totalShares.add(underlying);
        } else {
            uint128 asShares = safe128(uint256(underlying).mul(ts).div(res));
            providers[msg.sender].shares = safe128(
                uint256(providers[msg.sender].shares).add(asShares)
            );
            totalShares = safe128(uint256(ts).add(asShares));
        }

        reserves = safe128(uint256(res).add(underlying));
    }

    ///@notice Given an amount of shares, update balance, shares, and reserves
    function exit(uint128 asShares) internal returns (uint128) {
        uint128 res = reserves;
        uint128 ts = totalShares;
        providers[msg.sender].shares = uint128(
            uint256(providers[msg.sender].shares).sub(asShares)
        );
        totalShares = ts.sub(asShares);
        uint128 underlying = safe128(uint256(asShares).mul(res).div(ts));
        reserves = res.sub(underlying);
        return underlying;
    }

    /// @notice Claim premiums
    function claimPremiums() public {
        updateTokenSecondsProvided(msg.sender);
        _claimPremiums();
    }

    function _claimPremiums() internal {
        uint256 ttsp = providers[msg.sender].totalTokenSecondsProvided;
        if (ttsp > 0) {
            LastClaim memory lastClaim = providers[msg.sender].lastClaim;
            if (ttsp > lastClaim.lastPTPS) {
                uint256 globalTPS = totalProtectionSeconds;
                uint256 claimable =
                    _claimablePremiums(
                        providers[msg.sender].premiumIndex,
                        ttsp,
                        globalTPS,
                        lastClaim
                    );

                if (claimable == 0) {
                    // this means thats premiums accum has not increased,
                    // so exit early
                    return;
                }

                providers[msg.sender].premiumIndex = premiumsAccum;
                providers[msg.sender].lastClaim = LastClaim({
                    lastPTPS: ttsp,
                    lastGlobalTPS: globalTPS
                });
                // payout
                IERC20(payToken).safeTransfer(msg.sender, claimable);
                emit ClaimPremiums(msg.sender, claimable);
            } else {
                providers[msg.sender].premiumIndex = premiumsAccum;
                providers[msg.sender].lastClaim = LastClaim({
                    lastPTPS: ttsp,
                    lastGlobalTPS: totalProtectionSeconds
                });
            }
        } else {
            providers[msg.sender].premiumIndex = premiumsAccum;
            providers[msg.sender].lastClaim = LastClaim({
                lastPTPS: ttsp,
                lastGlobalTPS: totalProtectionSeconds
            });
        }
    }

    /// @notice Calculate claimable premiums for a provider
    function claimablePremiums(address who) public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 newTokenSecondsProvided =
            (timestamp - providers[who].lastUpdate).mul(providers[who].shares);
        uint256 whoTPS =
            providers[who].totalTokenSecondsProvided.add(
                newTokenSecondsProvided
            );
        uint256 newTTPS = (timestamp - lastUpdatedTPS).mul(totalShares);
        uint256 globalTPS = totalProtectionSeconds.add(newTTPS);
        LastClaim memory lastClaim = providers[who].lastClaim;
        if (
            whoTPS.sub(lastClaim.lastPTPS) == 0 ||
            premiumsAccum.sub(providers[who].premiumIndex) == 0
        ) {
            return 0;
        }
        return
            _claimablePremiums(
                providers[who].premiumIndex,
                whoTPS,
                globalTPS,
                lastClaim
            );
    }

    function _claimablePremiums(
        uint256 index,
        uint256 providerTPS,
        uint256 globalTPS,
        LastClaim memory lastClaim
    ) internal view returns (uint256) {
        //                    ΔproviderTPS
        //  ΔpremiumsAccum * --------------- = claimable
        //                    ΔglobalTPS
        return
            premiumsAccum
                .sub(index)
                .mul(providerTPS.sub(lastClaim.lastPTPS))
                .div(globalTPS.sub(lastClaim.lastGlobalTPS));
    }

    /// @notice Sweep multiple sets of premiums into reserves
    function sweepPremiums(uint256[] memory pids) public {
        updateGlobalTPS(block.timestamp);
        uint256 pidsLength = pids.length;
        uint128 totalSweptCoverage;
        uint128 totalPaid;
        for (uint256 i = 0; i < pidsLength; i++) {
            (uint128 coverageAmount, uint128 paid) = _sweep(pids[i]);
            totalSweptCoverage = safe128(
                uint256(totalSweptCoverage).add(coverageAmount)
            );
            totalPaid = safe128(uint256(totalPaid).add(paid));
        }
        _update(totalSweptCoverage, totalPaid);
    }

    /// @notice Sweep premium of a protection into reserves
    function sweep(uint256 pid) public {
        updateGlobalTPS(block.timestamp);
        (uint128 coverageAmount, uint128 paid) = _sweep(pid);
        _update(coverageAmount, paid);
    }

    /// @dev sweeps a protection plan over to swept status
    function _sweep(uint256 pid) internal returns (uint128, uint128) {
        Protection storage protection = protections[pid];

        // we keep a protection unswept until 7 days after expiry to allow arbiter to act
        require(protection.status == Status.Active, "Sweep:!active");
        require(
            protection.expiry + 86400 * 7 < block.timestamp,
            "Sweep:!expired"
        );
        require(
            !_hasSettlement(
                protection.conceptIndex,
                protection.start,
                protection.expiry
            ),
            "Sweep:!settlment"
        );

        // set status to swept
        protection.status = Status.Swept;
        emit Swept(pid, protection.paid);
        return (protection.coverageAmount, protection.paid);
    }

    /// @dev updates various vars relating to premiums and fees
    function _update(uint128 coverageRemoved, uint128 premiumsPaid) internal {
        utilized = uint128(uint256(utilized).sub(coverageRemoved));
        uint128 arbFees;
        uint128 createFees;
        uint128 rollovers;
        if (arbiterFee > 0) {
            arbFees = premiumsPaid.mul(arbiterFee).div(BASE);
            arbiterFees = safe128(uint256(arbiterFees).add(arbFees)); // pay arbiter
        }
        if (creatorFee > 0) {
            createFees = premiumsPaid.mul(creatorFee).div(BASE);
            creatorFees = safe128(uint256(creatorFees).add(createFees)); // pay creator
        }
        if (rollover > 0) {
            rollovers = premiumsPaid.mul(rollover).div(BASE);
            reserves = safe128(uint256(reserves).add(rollovers)); // rollover some % of premiums into reserves
        }

        // push remaining premiums to premium pool
        // SAFETY: BASE is 10**18, all others are bounded such that sum(r, c, a) < BASE.
        premiumsAccum = premiumsAccum.add(
            premiumsPaid - arbFees - createFees - rollovers
        );
    }

    // ============ Arbiter Functions ============

    ///@notice Sets a concept as settling (allowing claims)
    function _setSettling(
        uint8 conceptIndex,
        uint32 settleTime,
        bool needs_sort
    ) public onlyArbiter {
        require(conceptIndex < coveredConcepts.length, "setSettling:!index");
        require(settleTime < block.timestamp, "setSettling:!settleTime");
        uint256 claimsLength = claimTimes[conceptIndex].length;
        if (!needs_sort && claimsLength > 0) {
            // allow out of order if we sort, otherwise revert
            uint32 last =
                claimTimes[conceptIndex][claimTimes[conceptIndex].length - 1];
            require(settleTime > last, "_setSettling:!settleTime");
        }
        // add a claim time
        claimTimes[conceptIndex].push(settleTime);

        if (needs_sort && claimsLength > 0) {
            // if length is 0, we cannot sort so skip this branch
            uint256 lastIndex = claimTimes[conceptIndex].length - 1;
            quickSort(claimTimes[conceptIndex], int256(0), int256(lastIndex));
        }
    }

    ///@notice Arbiter accept arbiter role
    function _acceptArbiter() public onlyArbiter {
        require(!accepted, "acceptArb:accepted");
        arbSet = true;
        accepted = true;
    }

    ///@notice Arbiter get fees
    function _getArbiterFees() public onlyArbiter {
        uint128 a_fees = arbiterFees;
        arbiterFees = 0;
        IERC20(payToken).safeTransfer(arbiter, a_fees);
        emit ArbiterPaid(a_fees);
    }

    ///@notice Abdicates arbiter role, effectively shutting down the pool
    function _abdicate() public onlyArbiter {
        arbSet = false;
    }

    // ============ Creator Functions ============
    function _getCreatorFees() public {
        require(msg.sender == creator, "!creator");
        uint128 c_fees = creatorFees;
        creatorFees = 0;
        IERC20(payToken).safeTransfer(creator, c_fees);
        emit CreatorPaid(c_fees);
    }

    // ============ Helper Functions ============

    function quickSort(
        uint32[] storage arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint32 pivot = arr[uint32(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint32(i)] < pivot) i++;
            while (pivot < arr[uint32(j)]) j--;
            if (i <= j) {
                (arr[uint32(i)], arr[uint32(j)]) = (
                    arr[uint32(j)],
                    arr[uint32(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}