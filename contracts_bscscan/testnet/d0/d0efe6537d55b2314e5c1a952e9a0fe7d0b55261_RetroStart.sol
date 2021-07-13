/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <0.8.0;




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

// File: @openzeppelin/contracts/math/Math.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: solowei/contracts/AttoDecimal.sol


pragma solidity ^0.6.12;


library AttoDecimal {
    using SafeMath for uint256;

    struct Instance {
        uint256 mantissa;
    }

    uint256 internal constant BASE = 10;
    uint256 internal constant EXPONENTIATION = 18;
    uint256 internal constant ONE_MANTISSA = BASE**EXPONENTIATION;
    uint256 internal constant ONE_TENTH_MANTISSA = ONE_MANTISSA / 10;
    uint256 internal constant HALF_MANTISSA = ONE_MANTISSA / 2;
    uint256 internal constant SQUARED_ONE_MANTISSA = ONE_MANTISSA * ONE_MANTISSA;
    uint256 internal constant MAX_INTEGER = uint256(-1) / ONE_MANTISSA;

    function maximum() internal pure returns (Instance memory) {
        return Instance({mantissa: uint256(-1)});
    }

    function zero() internal pure returns (Instance memory) {
        return Instance({mantissa: 0});
    }

    function one() internal pure returns (Instance memory) {
        return Instance({mantissa: ONE_MANTISSA});
    }

    function convert(uint256 integer) internal pure returns (Instance memory) {
        return Instance({mantissa: integer.mul(ONE_MANTISSA)});
    }

    function compare(Instance memory a, Instance memory b) internal pure returns (int8) {
        if (a.mantissa < b.mantissa) return -1;
        return int8(a.mantissa > b.mantissa ? 1 : 0);
    }

    function compare(Instance memory a, uint256 b) internal pure returns (int8) {
        return compare(a, convert(b));
    }

    function add(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.add(b.mantissa)});
    }

    function add(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.add(b.mul(ONE_MANTISSA))});
    }

    function sub(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.sub(b.mantissa)});
    }

    function sub(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.sub(b.mul(ONE_MANTISSA))});
    }

    function sub(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(ONE_MANTISSA).sub(b.mantissa)});
    }

    function mul(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(b.mantissa) / ONE_MANTISSA});
    }

    function mul(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(b)});
    }

    function div(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mul(ONE_MANTISSA).div(b.mantissa)});
    }

    function div(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.div(b)});
    }

    function div(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(SQUARED_ONE_MANTISSA).div(b.mantissa)});
    }

    function div(uint256 a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mul(ONE_MANTISSA).div(b)});
    }

    function idiv(Instance memory a, Instance memory b) internal pure returns (uint256) {
        return a.mantissa.div(b.mantissa);
    }

    function idiv(Instance memory a, uint256 b) internal pure returns (uint256) {
        return a.mantissa.div(b.mul(ONE_MANTISSA));
    }

    function idiv(uint256 a, Instance memory b) internal pure returns (uint256) {
        return a.mul(ONE_MANTISSA).div(b.mantissa);
    }

    function mod(Instance memory a, Instance memory b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mod(b.mantissa)});
    }

    function mod(Instance memory a, uint256 b) internal pure returns (Instance memory) {
        return Instance({mantissa: a.mantissa.mod(b.mul(ONE_MANTISSA))});
    }

    function mod(uint256 a, Instance memory b) internal pure returns (Instance memory) {
        if (a > MAX_INTEGER) return Instance({mantissa: a.mod(b.mantissa).mul(ONE_MANTISSA) % b.mantissa});
        return Instance({mantissa: a.mul(ONE_MANTISSA).mod(b.mantissa)});
    }

    function floor(Instance memory a) internal pure returns (uint256) {
        return a.mantissa / ONE_MANTISSA;
    }

    function ceil(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + (a.mantissa % ONE_MANTISSA > 0 ? 1 : 0);
    }

    function round(Instance memory a) internal pure returns (uint256) {
        return (a.mantissa / ONE_MANTISSA) + ((a.mantissa / ONE_TENTH_MANTISSA) % 10 >= 5 ? 1 : 0);
    }

    function eq(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa == b.mantissa;
    }

    function eq(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa == b * ONE_MANTISSA;
    }

    function gt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa > b.mantissa;
    }

    function gt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa > b * ONE_MANTISSA;
    }

    function gte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa >= b.mantissa;
    }

    function gte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return false;
        return a.mantissa >= b * ONE_MANTISSA;
    }

    function lt(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa < b.mantissa;
    }

    function lt(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa < b * ONE_MANTISSA;
    }

    function lte(Instance memory a, Instance memory b) internal pure returns (bool) {
        return a.mantissa <= b.mantissa;
    }

    function lte(Instance memory a, uint256 b) internal pure returns (bool) {
        if (b > MAX_INTEGER) return true;
        return a.mantissa <= b * ONE_MANTISSA;
    }

    function isInteger(Instance memory a) internal pure returns (bool) {
        return a.mantissa % ONE_MANTISSA == 0;
    }

    function isPositive(Instance memory a) internal pure returns (bool) {
        return a.mantissa > 0;
    }

    function isZero(Instance memory a) internal pure returns (bool) {
        return a.mantissa == 0;
    }

    function sum(Instance[] memory array) internal pure returns (Instance memory result) {
        uint256 length = array.length;
        for (uint256 index = 0; index < length; index++) result = add(result, array[index]);
    }

    function toTuple(Instance memory a)
        internal
        pure
        returns (
            uint256 mantissa,
            uint256 base,
            uint256 exponentiation
        )
    {
        return (a.mantissa, BASE, EXPONENTIATION);
    }
}

// File: solowei/contracts/TwoStageOwnable.sol


pragma solidity ^0.6.12;

abstract contract TwoStageOwnable {
    address private _nominatedOwner;
    address private _owner;

    function nominatedOwner() public view returns (address) {
        return _nominatedOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    event OwnerChanged(address indexed newOwner);
    event OwnerNominated(address indexed nominatedOwner);

    constructor(address owner_) internal {
        require(owner_ != address(0), "Owner is zero");
        _setOwner(owner_);
    }

    function acceptOwnership() external returns (bool success) {
        require(msg.sender == _nominatedOwner, "Not nominated to ownership");
        _setOwner(_nominatedOwner);
        return true;
    }

    function nominateNewOwner(address owner_) external onlyOwner returns (bool success) {
        _nominateNewOwner(owner_);
        return true;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function _nominateNewOwner(address owner_) internal {
        if (_nominatedOwner == owner_) return;
        require(_owner != owner_, "Already owner");
        _nominatedOwner = owner_;
        emit OwnerNominated(owner_);
    }

    function _setOwner(address newOwner) internal {
        if (_owner == newOwner) return;
        _owner = newOwner;
        _nominatedOwner = address(0);
        emit OwnerChanged(newOwner);
    }
}

// File: contracts/RetroStart.sol


pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;








contract RetroStart is ReentrancyGuard, TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AttoDecimal for AttoDecimal.Instance;

    enum Type {SIMPLE, INTERVAL, LINEAR}

    struct Props {
        uint256 issuanceLimit;
        uint256 startsAt;
        uint256 endsAt;
        IERC20 paymentToken;
        IERC20 issuanceToken;
        AttoDecimal.Instance fee;
        AttoDecimal.Instance rate;
    }

    struct AccountState {
        uint256 limitIndex;
        uint256 paymentSum;
    }

    struct ComplexAccountState {
        uint256 issuanceAmount;
        uint256 withdrawnIssuanceAmount;
    }

    struct Account {
        AccountState state;
        ComplexAccountState complex;
        uint256 immediatelyUnlockedAmount; // linear
        uint256 unlockedIntervalsCount; // interval
    }

    struct State {
        uint256 available;
        uint256 issuance;
        uint256 lockedPayments;
        uint256 unlockedPayments;
        address nominatedOwner;
        address owner;
        uint256[] paymentLimits;
    }

    struct Interval {
        uint256 startsAt;
        AttoDecimal.Instance unlockingPart;
    }

    struct LinearProps {
        uint256 endsAt;
        uint256 duration;
    }

    struct Pool {
        Type type_;
        uint256 index;
        AttoDecimal.Instance immediatelyUnlockingPart;
        Props props;
        LinearProps linear;
        State state;
        Interval[] intervals;
        mapping(address => Account) accounts;
    }

    Pool[] private _pools;
    mapping(IERC20 => uint256) private _collectedFees;

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function poolsCount() public view returns (uint256) {
        return _pools.length;
    }

    function poolProps(uint256 poolIndex) public view returns (Type type_, Props memory props) {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.props);
    }

    function intervalPoolProps(uint256 poolIndex)
        public
        view
        returns (
            Props memory props,
            AttoDecimal.Instance memory immediatelyUnlockingPart,
            Interval[] memory intervals
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.intervals);
    }

    function linearPoolProps(uint256 poolIndex)
        public
        view
        returns (
            Props memory props,
            AttoDecimal.Instance memory immediatelyUnlockingPart,
            LinearProps memory linear
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        return (pool.props, pool.immediatelyUnlockingPart, pool.linear);
    }

    function poolState(uint256 poolIndex) public view returns (State memory state) {
        return _getPool(poolIndex).state;
    }

    function poolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (Type type_, AccountState memory state)
    {
        Pool storage pool = _getPool(poolIndex);
        return (pool.type_, pool.accounts[address_].state);
    }

    function intervalPoolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (
            AccountState memory state,
            ComplexAccountState memory complex,
            uint256 unlockedIntervalsCount
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.unlockedIntervalsCount);
    }

    function linearPoolAccount(uint256 poolIndex, address address_)
        public
        view
        returns (
            AccountState memory state,
            ComplexAccountState memory complex,
            uint256 immediatelyUnlockedAmount
        )
    {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        Account storage account = pool.accounts[address_];
        return (account.state, account.complex, account.immediatelyUnlockedAmount);
    }

    function collectedFees(IERC20 token) public view returns (uint256) {
        return _collectedFees[token];
    }

    event AccountLimitChanged(uint256 indexed poolIndex, address indexed address_, uint256 indexed limitIndex);
    event FeeWithdrawn(address indexed token, uint256 amount);
    event ImmediatelyUnlockingPartUpdated(uint256 indexed poolIndex, uint256 mantissa);
    event IntervalCreated(uint256 indexed poolIndex, uint256 startsAt, uint256 unlockingPart);
    event IssuanceIncreased(uint256 indexed poolIndex, uint256 amount);
    event LinearUnlockingEndingTimestampUpdated(uint256 indexed poolIndex, uint256 timestamp);
    event LinearPoolUnlocking(uint256 indexed poolIndex, address indexed account, uint256 amount);
    event PaymentLimitCreated(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 limit);
    event PaymentLimitChanged(uint256 indexed poolIndex, uint256 indexed limitIndex, uint256 newLimit);
    event PaymentUnlocked(uint256 indexed poolIndex, uint256 unlockedAmount, uint256 collectedFee);
    event PaymentsWithdrawn(uint256 indexed poolIndex, uint256 amount);
    event PoolOwnerChanged(uint256 indexed poolIndex, address indexed newOwner);
    event PoolOwnerNominated(uint256 indexed poolIndex, address indexed nominatedOwner);
    event UnsoldWithdrawn(uint256 indexed poolIndex, uint256 amount);

    event PoolCreated(
        Type type_,
        IERC20 indexed paymentToken,
        IERC20 indexed issuanceToken,
        uint256 poolIndex,
        uint256 issuanceLimit,
        uint256 startsAt,
        uint256 endsAt,
        uint256 fee,
        uint256 rate,
        uint256 paymentLimit
    );

    event Swap(
        uint256 indexed poolIndex,
        address indexed caller,
        uint256 requestedPaymentAmount,
        uint256 paymentAmount,
        uint256 issuanceAmount
    );

    constructor(address owner_) public TwoStageOwnable(owner_) {
        return;
    }

    function createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        return (true, _createSimplePool(props, paymentLimit, owner_, Type.SIMPLE).index);
    }

    function createIntervalPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        Interval[] memory intervals
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.INTERVAL);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        uint256 intervalsCount = intervals.length;
        AttoDecimal.Instance memory lastUnlockingPart = immediatelyUnlockingPart;
        uint256 lastIntervalStartingTimestamp = props.endsAt - 1;
        for (uint256 i = 0; i < intervalsCount; i++) {
            Interval memory interval = intervals[i];
            require(interval.unlockingPart.gt(lastUnlockingPart), "Invalid interval unlocking part");
            lastUnlockingPart = interval.unlockingPart;
            uint256 startingTimestamp = interval.startsAt;
            require(startingTimestamp > lastIntervalStartingTimestamp, "Invalid interval starting timestamp");
            lastIntervalStartingTimestamp = startingTimestamp;
            pool.intervals.push(interval);
            emit IntervalCreated(pool.index, interval.startsAt, interval.unlockingPart.mantissa);
        }
        require(lastUnlockingPart.eq(1), "Unlocking part not equal to one");
        return (true, pool.index);
    }

    function createLinearPool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        AttoDecimal.Instance memory immediatelyUnlockingPart,
        uint256 linearUnlockingEndsAt
    ) external onlyOwner returns (bool success, uint256 poolIndex) {
        require(linearUnlockingEndsAt > props.endsAt, "Linear unlocking less than or equal to pool ending timestamp");
        Pool storage pool = _createSimplePool(props, paymentLimit, owner_, Type.LINEAR);
        _setImmediatelyUnlockingPart(pool, immediatelyUnlockingPart);
        pool.linear.endsAt = linearUnlockingEndsAt;
        pool.linear.duration = linearUnlockingEndsAt - props.endsAt;
        emit LinearUnlockingEndingTimestampUpdated(pool.index, linearUnlockingEndsAt);
        return (true, pool.index);
    }

    function increaseIssuance(uint256 poolIndex, uint256 amount) external returns (bool success) {
        require(amount > 0, "Amount is zero");
        Pool storage pool = _getPool(poolIndex);
        require(getTimestamp() < pool.props.endsAt, "Pool ended");
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        pool.state.issuance = pool.state.issuance.add(amount);
        require(pool.state.issuance <= pool.props.issuanceLimit, "Issuance limit exceeded");
        pool.state.available = pool.state.available.add(amount);
        emit IssuanceIncreased(poolIndex, amount);
        pool.props.issuanceToken.safeTransferFrom(caller, address(this), amount);
        return true;
    }

    function swap(uint256 poolIndex, uint256 requestedPaymentAmount)
        external
        nonReentrant
        returns (uint256 paymentAmount, uint256 issuanceAmount)
    {
        require(requestedPaymentAmount > 0, "Requested payment amount is zero");
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        uint256 timestamp = getTimestamp();
        require(timestamp >= pool.props.startsAt, "Pool not started");
        require(timestamp < pool.props.endsAt, "Pool ended");
        require(pool.state.available > 0, "No available issuance");
        (paymentAmount, issuanceAmount) = _calculateSwapAmounts(pool, requestedPaymentAmount, caller);
        Account storage account = pool.accounts[caller];
        if (paymentAmount > 0) {
            pool.state.lockedPayments = pool.state.lockedPayments.add(paymentAmount);
            account.state.paymentSum = account.state.paymentSum.add(paymentAmount);
            pool.props.paymentToken.safeTransferFrom(caller, address(this), paymentAmount);
        }
        if (issuanceAmount > 0) {
            if (pool.type_ == Type.SIMPLE) pool.props.issuanceToken.safeTransfer(caller, issuanceAmount);
            else {
                uint256 totalIssuanceAmount = account.complex.issuanceAmount.add(issuanceAmount);
                account.complex.issuanceAmount = totalIssuanceAmount;
                uint256 newWithdrawnIssuanceAmount = pool.immediatelyUnlockingPart.mul(totalIssuanceAmount).floor();
                uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
                account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
                if (pool.type_ == Type.LINEAR) account.immediatelyUnlockedAmount = newWithdrawnIssuanceAmount;
                if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
            }
            pool.state.available = pool.state.available.sub(issuanceAmount);
        }
        emit Swap(poolIndex, caller, requestedPaymentAmount, paymentAmount, issuanceAmount);
    }

    function unlockInterval(uint256 poolIndex, uint256 intervalIndex)
        external
        returns (uint256 withdrawnIssuanceAmount)
    {
        address caller = msg.sender;
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsInterval(pool);
        require(intervalIndex < pool.intervals.length, "Invalid interval index");
        Interval storage interval = pool.intervals[intervalIndex];
        require(interval.startsAt <= getTimestamp(), "Interval not started");
        Account storage account = pool.accounts[caller];
        require(intervalIndex >= account.unlockedIntervalsCount, "Already unlocked");
        uint256 newWithdrawnIssuanceAmount = interval.unlockingPart.mul(account.complex.issuanceAmount).floor();
        uint256 issuanceToWithdraw = newWithdrawnIssuanceAmount - account.complex.withdrawnIssuanceAmount;
        account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
        if (issuanceToWithdraw > 0) pool.props.issuanceToken.safeTransfer(caller, issuanceToWithdraw);
        account.unlockedIntervalsCount = intervalIndex.add(1);
        return issuanceToWithdraw;
    }

    function unlockLinear(uint256 poolIndex) external returns (uint256 withdrawalAmount) {
        address caller = msg.sender;
        uint256 timestamp = getTimestamp();
        Pool storage pool = _getPool(poolIndex);
        _assertPoolIsLinear(pool);
        require(pool.props.endsAt < timestamp, "Pool not ended");
        Account storage account = pool.accounts[caller];
        uint256 issuanceAmount = account.complex.issuanceAmount;
        require(account.complex.withdrawnIssuanceAmount < issuanceAmount, "All funds already unlocked");
        uint256 passedTime = timestamp - pool.props.endsAt;
        uint256 freezedAmount = issuanceAmount.sub(account.immediatelyUnlockedAmount);
        uint256 unfreezedAmount = passedTime.mul(freezedAmount).div(pool.linear.duration);
        uint256 newWithdrawnIssuanceAmount = timestamp >= pool.linear.endsAt
            ? issuanceAmount
            : Math.min(account.immediatelyUnlockedAmount.add(unfreezedAmount), issuanceAmount);
        withdrawalAmount = newWithdrawnIssuanceAmount.sub(account.complex.withdrawnIssuanceAmount);
        if (withdrawalAmount > 0) {
            account.complex.withdrawnIssuanceAmount = newWithdrawnIssuanceAmount;
            emit LinearPoolUnlocking(pool.index, caller, withdrawalAmount);
            pool.props.issuanceToken.safeTransfer(caller, withdrawalAmount);
        }
    }

    function createPaymentLimit(uint256 poolIndex, uint256 limit) external returns (uint256 limitIndex) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        limitIndex = pool.state.paymentLimits.length;
        pool.state.paymentLimits.push(limit);
        emit PaymentLimitCreated(poolIndex, limitIndex, limit);
    }

    function changeLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        uint256 newLimit
    ) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        pool.state.paymentLimits[limitIndex] = newLimit;
        emit PaymentLimitChanged(poolIndex, limitIndex, newLimit);
        return true;
    }

    function setAccountsLimit(
        uint256 poolIndex,
        uint256 limitIndex,
        address[] memory accounts
    ) external returns (bool succcess) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        _validateLimitIndex(pool, limitIndex);
        uint256 accountsCount = accounts.length;
        require(accountsCount > 0, "No accounts provided");
        for (uint256 i = 0; i < accountsCount; i++) {
            address account = accounts[i];
            Account storage poolAccount_ = pool.accounts[account];
            if (poolAccount_.state.limitIndex == limitIndex) continue;
            poolAccount_.state.limitIndex = limitIndex;
            emit AccountLimitChanged(poolIndex, account, limitIndex);
        }
        return true;
    }

    function withdrawPayments(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        _unlockPayments(pool);
        uint256 collectedPayments = pool.state.unlockedPayments;
        require(collectedPayments > 0, "No collected payments");
        pool.state.unlockedPayments = 0;
        emit PaymentsWithdrawn(poolIndex, collectedPayments);
        pool.props.paymentToken.safeTransfer(caller, collectedPayments);
        return true;
    }

    function withdrawUnsold(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        _assertPoolOwnership(pool, caller);
        require(getTimestamp() >= pool.props.endsAt, "Not ended");
        uint256 amount = pool.state.available;
        require(amount > 0, "No unsold");
        pool.state.available = 0;
        emit UnsoldWithdrawn(poolIndex, amount);
        pool.props.issuanceToken.safeTransfer(caller, amount);
        return true;
    }

    function collectFee(uint256 poolIndex) external onlyOwner returns (bool success) {
        _unlockPayments(_getPool(poolIndex));
        return true;
    }

    function withdrawFee(IERC20 token) external onlyOwner returns (bool success) {
        uint256 collectedFee = _collectedFees[token];
        require(collectedFee > 0, "No collected fees");
        _collectedFees[token] = 0;
        emit FeeWithdrawn(address(token), collectedFee);
        token.safeTransfer(owner(), collectedFee);
        return true;
    }

    function nominateNewPoolOwner(uint256 poolIndex, address nominatedOwner_) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        _assertPoolOwnership(pool, msg.sender);
        require(nominatedOwner_ != pool.state.owner, "Already owner");
        if (pool.state.nominatedOwner == nominatedOwner_) return true;
        pool.state.nominatedOwner = nominatedOwner_;
        emit PoolOwnerNominated(poolIndex, nominatedOwner_);
        return true;
    }

    function acceptPoolOwnership(uint256 poolIndex) external returns (bool success) {
        Pool storage pool = _getPool(poolIndex);
        address caller = msg.sender;
        require(pool.state.nominatedOwner == caller, "Not nominated to pool ownership");
        pool.state.owner = caller;
        pool.state.nominatedOwner = address(0);
        emit PoolOwnerChanged(poolIndex, caller);
        return true;
    }

    function _assertPoolIsInterval(Pool storage pool) private view {
        require(pool.type_ == Type.INTERVAL, "Not interval pool");
    }

    function _assertPoolIsLinear(Pool storage pool) private view {
        require(pool.type_ == Type.LINEAR, "Not linear pool");
    }

    function _assertPoolOwnership(Pool storage pool, address account) private view {
        require(account == pool.state.owner, "Permission denied");
    }

    function _calculateSwapAmounts(
        Pool storage pool,
        uint256 requestedPaymentAmount,
        address account
    ) private view returns (uint256 paymentAmount, uint256 issuanceAmount) {
        paymentAmount = requestedPaymentAmount;
        Account storage poolAccount_ = pool.accounts[account];
        uint256 paymentLimit = pool.state.paymentLimits[poolAccount_.state.limitIndex];
        require(poolAccount_.state.paymentSum < paymentLimit, "Account payment limit exceeded");
        if (poolAccount_.state.paymentSum.add(paymentAmount) > paymentLimit) {
            paymentAmount = paymentLimit.sub(poolAccount_.state.paymentSum);
        }
        issuanceAmount = pool.props.rate.mul(paymentAmount).floor();
        if (issuanceAmount > pool.state.available) {
            issuanceAmount = pool.state.available;
            paymentAmount = AttoDecimal.div(issuanceAmount, pool.props.rate).ceil();
        }
    }

    function _getPool(uint256 index) private view returns (Pool storage) {
        require(index < _pools.length, "Pool not found");
        return _pools[index];
    }

    function _validateLimitIndex(Pool storage pool, uint256 limitIndex) private view {
        require(limitIndex < pool.state.paymentLimits.length, "Limit not found");
    }

    function _createSimplePool(
        Props memory props,
        uint256 paymentLimit,
        address owner_,
        Type type_
    ) private returns (Pool storage) {
        // {
            uint256 timestamp = getTimestamp();
            if (props.startsAt < timestamp) props.startsAt = timestamp;
            require(props.fee.lt(100), "Fee gte 100%");
            require(props.startsAt < props.endsAt, "Invalid ending timestamp");
        // }
        uint256 poolIndex = _pools.length;
        _pools.push();
        Pool storage pool = _pools[poolIndex];
        pool.index = poolIndex;
        pool.type_ = type_;
        pool.props = props;
        pool.state.paymentLimits = new uint256[](1);
        pool.state.paymentLimits[0] = paymentLimit;
        pool.state.owner = owner_;
        emit PoolCreated(
            type_,
            props.paymentToken,
            props.issuanceToken,
            poolIndex,
            props.issuanceLimit,
            props.startsAt,
            props.endsAt,
            pool.props.fee.mantissa,
            pool.props.rate.mantissa,
            pool.state.paymentLimits[0]
        );
        emit PoolOwnerChanged(poolIndex, owner_);
        return pool;
    }

    function _setImmediatelyUnlockingPart(Pool storage pool, AttoDecimal.Instance memory immediatelyUnlockingPart)
        private
    {
        require(immediatelyUnlockingPart.lt(1), "Invalid immediately unlocking part value");
        pool.immediatelyUnlockingPart = immediatelyUnlockingPart;
        emit ImmediatelyUnlockingPartUpdated(pool.index, immediatelyUnlockingPart.mantissa);
    }

    function _unlockPayments(Pool storage pool) private {
        if (pool.state.lockedPayments == 0) return;
        uint256 fee = pool.props.fee.mul(pool.state.lockedPayments).ceil();
        _collectedFees[pool.props.paymentToken] = _collectedFees[pool.props.paymentToken].add(fee);
        uint256 unlockedAmount = pool.state.lockedPayments.sub(fee);
        pool.state.unlockedPayments = pool.state.unlockedPayments.add(unlockedAmount);
        pool.state.lockedPayments = 0;
        emit PaymentUnlocked(pool.index, unlockedAmount, fee);
    }
}