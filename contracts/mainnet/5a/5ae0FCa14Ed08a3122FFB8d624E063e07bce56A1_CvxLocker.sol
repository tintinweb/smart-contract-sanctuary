/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: MIT

// File: contracts\interfaces\MathUtil.sol

pragma solidity 0.6.12;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUtil {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// File: contracts\interfaces\IStakingProxy.sol

pragma solidity 0.6.12;

interface IStakingProxy {
    function getBalance() external view returns(uint256);

    function withdraw(uint256 _amount) external;

    function stake() external;

    function distribute() external;
}

// File: contracts\interfaces\IRewardStaking.sol

pragma solidity 0.6.12;

interface IRewardStaking {
    function stakeFor(address, uint256) external;
    function stake( uint256) external;
    function withdraw(uint256 amount, bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external;
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account, bool _claimExtras) external;
    function extraRewardsLength() external view returns (uint256);
    function extraRewards(uint256 _pid) external view returns (address);
    function rewardToken() external view returns (address);
    function balanceOf(address _account) external view returns (uint256);
}

// File: contracts\interfaces\BoringMath.sol

pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "BoringMath: division by zero");
        return a / b;
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function to40(uint256 a) internal pure returns (uint40 c) {
        require(a <= uint40(-1), "BoringMath: uint40 Overflow");
        c = uint40(a);
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        require(a <= uint112(-1), "BoringMath: uint112 Overflow");
        c = uint112(a);
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= uint224(-1), "BoringMath: uint224 Overflow");
        c = uint224(a);
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        require(a <= uint208(-1), "BoringMath: uint208 Overflow");
        c = uint208(a);
    }

    function to216(uint256 a) internal pure returns (uint216 c) {
        require(a <= uint216(-1), "BoringMath: uint216 Overflow");
        c = uint216(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "BoringMath: division by zero");
        return a / b;
    }
}


/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint112.
library BoringMath112 {
    function add(uint112 a, uint112 b) internal pure returns (uint112 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint112 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint112 a, uint112 b) internal pure returns (uint112 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }
    
    function div(uint112 a, uint112 b) internal pure returns (uint112) {
        require(b > 0, "BoringMath: division by zero");
        return a / b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library BoringMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint224 a, uint224 b) internal pure returns (uint224 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }
    
    function div(uint224 a, uint224 b) internal pure returns (uint224) {
        require(b > 0, "BoringMath: division by zero");
        return a / b;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: node_modules\@openzeppelin\contracts\math\SafeMath.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Address.sol

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

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

// File: @openzeppelin\contracts\math\Math.sol

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

// File: node_modules\@openzeppelin\contracts\utils\Context.sol
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

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol
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

// File: contracts\CvxLocker.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


// CVX Locking contract for https://www.convexfinance.com/
// CVX locked in this contract will be entitled to voting rights for the Convex Finance platform
// Based on EPS Staking contract for http://ellipsis.finance/
// Based on SNX MultiRewards by iamdefinitelyahuman - https://github.com/iamdefinitelyahuman/multi-rewards
contract CvxLocker is ReentrancyGuard, Ownable {

    using BoringMath for uint256;
    using BoringMath224 for uint224;
    using BoringMath112 for uint112;
    using BoringMath32 for uint32;
    using SafeERC20
    for IERC20;

    /* ========== STATE VARIABLES ========== */

    struct Reward {
        bool useBoost;
        uint40 periodFinish;
        uint208 rewardRate;
        uint40 lastUpdateTime;
        uint208 rewardPerTokenStored;
    }
    struct Balances {
        uint112 locked;
        uint112 boosted;
        uint32 nextUnlockIndex;
    }
    struct LockedBalance {
        uint112 amount;
        uint112 boosted;
        uint32 unlockTime;
    }
    struct EarnedData {
        address token;
        uint256 amount;
    }
    struct Epoch {
        uint224 supply; //epoch boosted supply
        uint32 date; //epoch start date
    }

    //token constants
    IERC20 public constant stakingToken = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B); //cvx
    address public constant cvxCrv = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);

    //rewards
    address[] public rewardTokens;
    mapping(address => Reward) public rewardData;

    // Duration that rewards are streamed over
    uint256 public constant rewardsDuration = 86400 * 7;

    // Duration of lock/earned penalty period
    uint256 public constant lockDuration = rewardsDuration * 17;

    // reward token -> distributor -> is approved to add rewards
    mapping(address => mapping(address => bool)) public rewardDistributors;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    //supplies and epochs
    uint256 public lockedSupply;
    uint256 public boostedSupply;
    Epoch[] public epochs;

    //mappings for balance data
    mapping(address => Balances) public balances;
    mapping(address => LockedBalance[]) public userLocks;

    //boost
    address public boostPayment = address(0x1389388d01708118b497f59521f6943Be2541bb7);
    uint256 public maximumBoostPayment = 0;
    uint256 public boostRate = 10000;
    uint256 public nextMaximumBoostPayment = 0;
    uint256 public nextBoostRate = 10000;
    uint256 public constant denominator = 10000;

    //staking
    uint256 public minimumStake = 10000;
    uint256 public maximumStake = 10000;
    address public stakingProxy;
    address public constant cvxcrvStaking = address(0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
    uint256 public constant stakeOffsetOnLock = 500; //allow broader range for staking when depositing

    //management
    uint256 public kickRewardPerEpoch = 100;
    uint256 public kickRewardEpochDelay = 4;

    //shutdown
    bool public isShutdown = false;

    //erc20-like interface
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    /* ========== CONSTRUCTOR ========== */

    constructor() public Ownable() {
        _name = "Vote Locked Convex Token";
        _symbol = "vlCVX";
        _decimals = 18;

        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        epochs.push(Epoch({
            supply: 0,
            date: uint32(currentEpoch)
        }));
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /* ========== ADMIN CONFIGURATION ========== */

    // Add a new reward token to be distributed to stakers
    function addReward(
        address _rewardsToken,
        address _distributor,
        bool _useBoost
    ) public onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime == 0);
        require(_rewardsToken != address(stakingToken));
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].lastUpdateTime = uint40(block.timestamp);
        rewardData[_rewardsToken].periodFinish = uint40(block.timestamp);
        rewardData[_rewardsToken].useBoost = _useBoost;
        rewardDistributors[_rewardsToken][_distributor] = true;
    }

    // Modify approval for an address to call notifyRewardAmount
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external onlyOwner {
        require(rewardData[_rewardsToken].lastUpdateTime > 0);
        rewardDistributors[_rewardsToken][_distributor] = _approved;
    }

    //Set the staking contract for the underlying cvx. immutable to avoid foul play
    function setStakingContract(address _staking) external onlyOwner {
        require(stakingProxy == address(0), "staking contract immutable");

        stakingProxy = _staking;
    }

    //set staking limits. will stake the mean of the two once either ratio is crossed
    function setStakeLimits(uint256 _minimum, uint256 _maximum) external onlyOwner {
        require(_minimum <= denominator, "min range");
        require(_maximum <= denominator, "max range");
        minimumStake = _minimum;
        maximumStake = _maximum;
        updateStakeRatio(0);
    }

    //set boost parameters
    function setBoost(uint256 _max, uint256 _rate, address _receivingAddress) external onlyOwner {
        require(maximumBoostPayment < 1500, "over max payment"); //max 15%
        require(boostRate < 30000, "over max rate"); //max 3x
        require(_receivingAddress != address(0), "invalid address"); //must point somewhere valid
        nextMaximumBoostPayment = _max;
        nextBoostRate = _rate;
        boostPayment = _receivingAddress;
    }

    //set kick incentive
    function setKickIncentive(uint256 _rate, uint256 _delay) external onlyOwner {
        require(_rate <= 500, "over max rate"); //max 5% per epoch
        require(_delay >= 2, "min delay"); //minimum 2 epochs of grace
        kickRewardPerEpoch = _rate;
        kickRewardEpochDelay = _delay;
    }

    //shutdown the contract. unstake all tokens. release all locks
    function shutdown() external onlyOwner {
        if (stakingProxy != address(0)) {
            uint256 stakeBalance = IStakingProxy(stakingProxy).getBalance();
            IStakingProxy(stakingProxy).withdraw(stakeBalance);
        }
        isShutdown = true;
    }

    //set approvals for staking cvx and cvxcrv
    function setApprovals() external {
        IERC20(cvxCrv).safeApprove(cvxcrvStaking, 0);
        IERC20(cvxCrv).safeApprove(cvxcrvStaking, uint256(-1));

        IERC20(stakingToken).safeApprove(stakingProxy, 0);
        IERC20(stakingToken).safeApprove(stakingProxy, uint256(-1));
    }

    /* ========== VIEWS ========== */

    function _rewardPerToken(address _rewardsToken) internal view returns(uint256) {
        if (boostedSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        uint256(rewardData[_rewardsToken].rewardPerTokenStored).add(
            _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish).sub(
                rewardData[_rewardsToken].lastUpdateTime).mul(
                rewardData[_rewardsToken].rewardRate).mul(1e18).div(rewardData[_rewardsToken].useBoost ? boostedSupply : lockedSupply)
        );
    }

    function _earned(
        address _user,
        address _rewardsToken,
        uint256 _balance
    ) internal view returns(uint256) {
        return _balance.mul(
            _rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[_user][_rewardsToken])
        ).div(1e18).add(rewards[_user][_rewardsToken]);
    }

    function _lastTimeRewardApplicable(uint256 _finishTime) internal view returns(uint256){
        return Math.min(block.timestamp, _finishTime);
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns(uint256) {
        return _lastTimeRewardApplicable(rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) external view returns(uint256) {
        return _rewardPerToken(_rewardsToken);
    }

    function getRewardForDuration(address _rewardsToken) external view returns(uint256) {
        return uint256(rewardData[_rewardsToken].rewardRate).mul(rewardsDuration);
    }

    // Address and claimable amount of all reward tokens for the given account
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards) {
        userRewards = new EarnedData[](rewardTokens.length);
        Balances storage userBalance = balances[_account];
        uint256 boostedBal = userBalance.boosted;
        for (uint256 i = 0; i < userRewards.length; i++) {
            address token = rewardTokens[i];
            userRewards[i].token = token;
            userRewards[i].amount = _earned(_account, token, rewardData[token].useBoost ? boostedBal : userBalance.locked);
        }
        return userRewards;
    }

    // Total BOOSTED balance of an account, including unlocked but not withdrawn tokens
    function rewardWeightOf(address _user) view external returns(uint256 amount) {
        return balances[_user].boosted;
    }

    // total token balance of an account, including unlocked but not withdrawn tokens
    function lockedBalanceOf(address _user) view external returns(uint256 amount) {
        return balances[_user].locked;
    }

    //BOOSTED balance of an account which only includes properly locked tokens as of the most recent eligible epoch
    function balanceOf(address _user) view external returns(uint256 amount) {
        LockedBalance[] storage locks = userLocks[_user];
        Balances storage userBalance = balances[_user];
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;

        //start with current boosted amount
        amount = balances[_user].boosted;

        uint256 locksLength = locks.length;
        //remove old records only (will be better gas-wise than adding up)
        for (uint i = nextUnlockIndex; i < locksLength; i++) {
            if (locks[i].unlockTime <= block.timestamp) {
                amount = amount.sub(locks[i].boosted);
            } else {
                //stop now as no futher checks are needed
                break;
            }
        }

        //also remove amount in the current epoch
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        if (locksLength > 0 && uint256(locks[locksLength - 1].unlockTime).sub(lockDuration) == currentEpoch) {
            amount = amount.sub(locks[locksLength - 1].boosted);
        }

        return amount;
    }

    //BOOSTED balance of an account which only includes properly locked tokens at the given epoch
    function balanceAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount) {
        LockedBalance[] storage locks = userLocks[_user];

        //get timestamp of given epoch index
        uint256 epochTime = epochs[_epoch].date;
        //get timestamp of first non-inclusive epoch
        uint256 cutoffEpoch = epochTime.sub(lockDuration);

        //current epoch is not counted
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);

        //need to add up since the range could be in the middle somewhere
        //traverse inversely to make more current queries more gas efficient
        for (uint i = locks.length - 1; i + 1 != 0; i--) {
            uint256 lockEpoch = uint256(locks[i].unlockTime).sub(lockDuration);
            //lock epoch must be less or equal to the epoch we're basing from.
            //also not include the current epoch
            if (lockEpoch <= epochTime && lockEpoch < currentEpoch) {
                if (lockEpoch > cutoffEpoch) {
                    amount = amount.add(locks[i].boosted);
                } else {
                    //stop now as no futher checks matter
                    break;
                }
            }
        }

        return amount;
    }

    //supply of all properly locked BOOSTED balances at most recent eligible epoch
    function totalSupply() view external returns(uint256 supply) {

        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        uint256 cutoffEpoch = currentEpoch.sub(lockDuration);
        uint256 epochindex = epochs.length;

        //do not include current epoch's supply
        if ( uint256(epochs[epochindex - 1].date) == currentEpoch) {
            epochindex--;
        }

        //traverse inversely to make more current queries more gas efficient
        for (uint i = epochindex - 1; i + 1 != 0; i--) {
            Epoch storage e = epochs[i];
            if (uint256(e.date) <= cutoffEpoch) {
                break;
            }
            supply = supply.add(e.supply);
        }

        return supply;
    }

    //supply of all properly locked BOOSTED balances at the given epoch
    function totalSupplyAtEpoch(uint256 _epoch) view external returns(uint256 supply) {

        uint256 epochStart = uint256(epochs[_epoch].date).div(rewardsDuration).mul(rewardsDuration);
        uint256 cutoffEpoch = epochStart.sub(lockDuration);
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);

        //do not include current epoch's supply
        if (uint256(epochs[_epoch].date) == currentEpoch) {
            _epoch--;
        }

        //traverse inversely to make more current queries more gas efficient
        for (uint i = _epoch; i + 1 != 0; i--) {
            Epoch storage e = epochs[i];
            if (uint256(e.date) <= cutoffEpoch) {
                break;
            }
            supply = supply.add(epochs[i].supply);
        }

        return supply;
    }

    //find an epoch index based on timestamp
    function findEpochId(uint256 _time) view external returns(uint256 epoch) {
        uint256 max = epochs.length - 1;
        uint256 min = 0;

        //convert to start point
        _time = _time.div(rewardsDuration).mul(rewardsDuration);

        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) break;

            uint256 mid = (min + max + 1) / 2;
            uint256 midEpochBlock = epochs[mid].date;
            if(midEpochBlock == _time){
                //found
                return mid;
            }else if (midEpochBlock < _time) {
                min = mid;
            } else{
                max = mid - 1;
            }
        }
        return min;
    }


    // Information on a user's locked balances
    function lockedBalances(
        address _user
    ) view external returns(
        uint256 total,
        uint256 unlockable,
        uint256 locked,
        LockedBalance[] memory lockData
    ) {
        LockedBalance[] storage locks = userLocks[_user];
        Balances storage userBalance = balances[_user];
        uint256 nextUnlockIndex = userBalance.nextUnlockIndex;
        uint256 idx;
        for (uint i = nextUnlockIndex; i < locks.length; i++) {
            if (locks[i].unlockTime > block.timestamp) {
                if (idx == 0) {
                    lockData = new LockedBalance[](locks.length - i);
                }
                lockData[idx] = locks[i];
                idx++;
                locked = locked.add(locks[i].amount);
            } else {
                unlockable = unlockable.add(locks[i].amount);
            }
        }
        return (userBalance.locked, unlockable, locked, lockData);
    }

    //number of epochs
    function epochCount() external view returns(uint256) {
        return epochs.length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function checkpointEpoch() external {
        _checkpointEpoch();
    }

    //insert a new epoch if needed. fill in any gaps
    function _checkpointEpoch() internal {
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        uint256 epochindex = epochs.length;

        //first epoch add in constructor, no need to check 0 length

        //check to add
        if (epochs[epochindex - 1].date < currentEpoch) {
            //fill any epoch gaps
            while(epochs[epochs.length-1].date != currentEpoch){
                uint256 nextEpochDate = uint256(epochs[epochs.length-1].date).add(rewardsDuration);
                epochs.push(Epoch({
                    supply: 0,
                    date: uint32(nextEpochDate)
                }));
            }

            //update boost parameters on a new epoch
            if(boostRate != nextBoostRate){
                boostRate = nextBoostRate;
            }
            if(maximumBoostPayment != nextMaximumBoostPayment){
                maximumBoostPayment = nextMaximumBoostPayment;
            }
        }
    }

    // Locked tokens cannot be withdrawn for lockDuration and are eligible to receive stakingReward rewards
    function lock(address _account, uint256 _amount, uint256 _spendRatio) external nonReentrant updateReward(_account) {

        //pull tokens
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        //lock
        _lock(_account, _amount, _spendRatio);
    }

    //lock tokens
    function _lock(address _account, uint256 _amount, uint256 _spendRatio) internal {
        require(_amount > 0, "Cannot stake 0");
        require(_spendRatio <= maximumBoostPayment, "over max spend");
        require(!isShutdown, "shutdown");

        Balances storage bal = balances[_account];

        //must try check pointing epoch first
        _checkpointEpoch();

        //calc lock and boosted amount
        uint256 spendAmount = _amount.mul(_spendRatio).div(denominator);
        uint256 boostRatio = boostRate.mul(_spendRatio).div(maximumBoostPayment==0?1:maximumBoostPayment);
        uint112 lockAmount = _amount.sub(spendAmount).to112();
        uint112 boostedAmount = _amount.add(_amount.mul(boostRatio).div(denominator)).to112();

        //add user balances
        bal.locked = bal.locked.add(lockAmount);
        bal.boosted = bal.boosted.add(boostedAmount);

        //add to total supplies
        lockedSupply = lockedSupply.add(lockAmount);
        boostedSupply = boostedSupply.add(boostedAmount);

        //add user lock records or add to current
        uint256 currentEpoch = block.timestamp.div(rewardsDuration).mul(rewardsDuration);
        uint256 unlockTime = currentEpoch.add(lockDuration);
        uint256 idx = userLocks[_account].length;
        if (idx == 0 || userLocks[_account][idx - 1].unlockTime < unlockTime) {
            userLocks[_account].push(LockedBalance({
                amount: lockAmount,
                boosted: boostedAmount,
                unlockTime: uint32(unlockTime)
            }));
        } else {
            LockedBalance storage userL = userLocks[_account][idx - 1];
            userL.amount = userL.amount.add(lockAmount);
            userL.boosted = userL.boosted.add(boostedAmount);
        }

        
        //update epoch supply, epoch checkpointed above so safe to add to latest
        Epoch storage e = epochs[epochs.length - 1];
        e.supply = e.supply.add(uint224(boostedAmount));

        //send boost payment
        if (spendAmount > 0) {
            stakingToken.safeTransfer(boostPayment, spendAmount);
        }

        //update staking, allow a bit of leeway for smaller deposits to reduce gas
        updateStakeRatio(stakeOffsetOnLock);

        emit Staked(_account, _amount, lockAmount, boostedAmount);
    }

    // Withdraw all currently locked tokens where the unlock time has passed
    function _processExpiredLocks(address _account, bool _relock, uint256 _spendRatio, address _withdrawTo, address _rewardAddress, uint256 _checkDelay) internal updateReward(_account) {
        LockedBalance[] storage locks = userLocks[_account];
        Balances storage userBalance = balances[_account];
        uint112 locked;
        uint112 boostedAmount;
        uint256 length = locks.length;
        uint256 reward = 0;
        
        if (isShutdown || locks[length - 1].unlockTime <= block.timestamp.sub(_checkDelay)) {
            //if time is beyond last lock, can just bundle everything together
            locked = userBalance.locked;
            boostedAmount = userBalance.boosted;

            //dont delete, just set next index
            userBalance.nextUnlockIndex = length.to32();

            //check for kick reward
            //this wont have the exact reward rate that you would get if looped through
            //but this section is supposed to be for quick and easy low gas processing of all locks
            //we'll assume that if the reward was good enough someone would have processed at an earlier epoch
            if (_checkDelay > 0) {
                uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(rewardsDuration).mul(rewardsDuration);
                uint256 epochsover = currentEpoch.sub(uint256(locks[length - 1].unlockTime)).div(rewardsDuration);
                uint256 rRate = MathUtil.min(kickRewardPerEpoch.mul(epochsover+1), denominator);
                reward = uint256(locks[length - 1].amount).mul(rRate).div(denominator);
            }
        } else {

            //use a processed index(nextUnlockIndex) to not loop as much
            //deleting does not change array length
            uint32 nextUnlockIndex = userBalance.nextUnlockIndex;
            for (uint i = nextUnlockIndex; i < length; i++) {
                //unlock time must be less or equal to time
                if (locks[i].unlockTime > block.timestamp.sub(_checkDelay)) break;

                //add to cumulative amounts
                locked = locked.add(locks[i].amount);
                boostedAmount = boostedAmount.add(locks[i].boosted);

                //check for kick reward
                //each epoch over due increases reward
                if (_checkDelay > 0) {
                    uint256 currentEpoch = block.timestamp.sub(_checkDelay).div(rewardsDuration).mul(rewardsDuration);
                    uint256 epochsover = currentEpoch.sub(uint256(locks[i].unlockTime)).div(rewardsDuration);
                    uint256 rRate = MathUtil.min(kickRewardPerEpoch.mul(epochsover+1), denominator);
                    reward = reward.add( uint256(locks[i].amount).mul(rRate).div(denominator));
                }
                //set next unlock index
                nextUnlockIndex++;
            }
            //update next unlock index
            userBalance.nextUnlockIndex = nextUnlockIndex;
        }
        require(locked > 0, "no exp locks");

        //update user balances and total supplies
        userBalance.locked = userBalance.locked.sub(locked);
        userBalance.boosted = userBalance.boosted.sub(boostedAmount);
        lockedSupply = lockedSupply.sub(locked);
        boostedSupply = boostedSupply.sub(boostedAmount);

        emit Withdrawn(_account, locked, _relock);

        //send process incentive
        if (reward > 0) {
            //if theres a reward(kicked), it will always be a withdraw only
            //preallocate enough cvx from stake contract to pay for both reward and withdraw
            allocateCVXForTransfer(uint256(locked));

            //reduce return amount by the kick reward
            locked = locked.sub(reward.to112());
            
            //transfer reward
            transferCVX(_rewardAddress, reward, false);

            emit KickReward(_rewardAddress, _account, reward);
        }else if(_spendRatio > 0){
            //preallocate enough cvx to transfer the boost cost
            allocateCVXForTransfer( uint256(locked).mul(_spendRatio).div(denominator) );
        }

        //relock or return to user
        if (_relock) {
            _lock(_withdrawTo, locked, _spendRatio);
        } else {
            transferCVX(_withdrawTo, locked, true);
        }
    }

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock, uint256 _spendRatio, address _withdrawTo) external nonReentrant {
        _processExpiredLocks(msg.sender, _relock, _spendRatio, _withdrawTo, msg.sender, 0);
    }

    // Withdraw/relock all currently locked tokens where the unlock time has passed
    function processExpiredLocks(bool _relock) external nonReentrant {
        _processExpiredLocks(msg.sender, _relock, 0, msg.sender, msg.sender, 0);
    }

    function kickExpiredLocks(address _account) external nonReentrant {
        //allow kick after grace period of 'kickRewardEpochDelay'
        _processExpiredLocks(_account, false, 0, _account, msg.sender, rewardsDuration.mul(kickRewardEpochDelay));
    }

    //pull required amount of cvx from staking for an upcoming transfer
    function allocateCVXForTransfer(uint256 _amount) internal{
        uint256 balance = stakingToken.balanceOf(address(this));
        if (_amount > balance) {
            IStakingProxy(stakingProxy).withdraw(_amount.sub(balance));
        }
    }

    //transfer helper: pull enough from staking, transfer, updating staking ratio
    function transferCVX(address _account, uint256 _amount, bool _updateStake) internal {
        //allocate enough cvx from staking for the transfer
        allocateCVXForTransfer(_amount);
        //transfer
        stakingToken.safeTransfer(_account, _amount);

        //update staking
        if(_updateStake){
            updateStakeRatio(0);
        }
    }

    //calculate how much cvx should be staked. update if needed
    function updateStakeRatio(uint256 _offset) internal {
        if (isShutdown) return;

        //get balances
        uint256 local = stakingToken.balanceOf(address(this));
        uint256 staked = IStakingProxy(stakingProxy).getBalance();
        uint256 total = local.add(staked);
        
        if(total == 0) return;

        //current staked ratio
        uint256 ratio = staked.mul(denominator).div(total);
        //mean will be where we reset to if unbalanced
        uint256 mean = maximumStake.add(minimumStake).div(2);
        uint256 max = maximumStake.add(_offset);
        uint256 min = Math.min(minimumStake, minimumStake - _offset);
        if (ratio > max) {
            //remove
            uint256 remove = staked.sub(total.mul(mean).div(denominator));
            IStakingProxy(stakingProxy).withdraw(remove);
        } else if (ratio < min) {
            //add
            uint256 increase = total.mul(mean).div(denominator).sub(staked);
            stakingToken.safeTransfer(stakingProxy, increase);
            IStakingProxy(stakingProxy).stake();
        }
    }

    // Claim all pending rewards
    function getReward(address _account, bool _stake) public nonReentrant updateReward(_account) {
        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[_account][_rewardsToken];
            if (reward > 0) {
                rewards[_account][_rewardsToken] = 0;
                if (_rewardsToken == cvxCrv && _stake) {
                    IRewardStaking(cvxcrvStaking).stakeFor(_account, reward);
                } else {
                    IERC20(_rewardsToken).safeTransfer(_account, reward);
                }
                emit RewardPaid(_account, _rewardsToken, reward);
            }
        }
    }

    // claim all pending rewards
    function getReward(address _account) external{
        getReward(_account,false);
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function _notifyReward(address _rewardsToken, uint256 _reward) internal {
        Reward storage rdata = rewardData[_rewardsToken];

        if (block.timestamp >= rdata.periodFinish) {
            rdata.rewardRate = _reward.div(rewardsDuration).to208();
        } else {
            uint256 remaining = uint256(rdata.periodFinish).sub(block.timestamp);
            uint256 leftover = remaining.mul(rdata.rewardRate);
            rdata.rewardRate = _reward.add(leftover).div(rewardsDuration).to208();
        }

        rdata.lastUpdateTime = block.timestamp.to40();
        rdata.periodFinish = block.timestamp.add(rewardsDuration).to40();
    }

    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external updateReward(address(0)) {
        require(rewardDistributors[_rewardsToken][msg.sender]);
        require(_reward > 0, "No reward");

        _notifyReward(_rewardsToken, _reward);

        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the _reward amount
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), _reward);
        
        emit RewardAdded(_rewardsToken, _reward);

        if(_rewardsToken == cvxCrv){
            //update staking ratio if main reward
            updateStakeRatio(0);
        }
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakingToken), "Cannot withdraw staking token");
        require(rewardData[_tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
        IERC20(_tokenAddress).safeTransfer(owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        {//stack too deep
            Balances storage userBalance = balances[_account];
            uint256 boostedBal = userBalance.boosted;
            for (uint i = 0; i < rewardTokens.length; i++) {
                address token = rewardTokens[i];
                rewardData[token].rewardPerTokenStored = _rewardPerToken(token).to208();
                rewardData[token].lastUpdateTime = _lastTimeRewardApplicable(rewardData[token].periodFinish).to40();
                if (_account != address(0)) {
                    //check if reward is boostable or not. use boosted or locked balance accordingly
                    rewards[_account][token] = _earned(_account, token, rewardData[token].useBoost ? boostedBal : userBalance.locked );
                    userRewardPerTokenPaid[_account][token] = rewardData[token].rewardPerTokenStored;
                }
            }
        }
        _;
    }

    /* ========== EVENTS ========== */
    event RewardAdded(address indexed _token, uint256 _reward);
    event Staked(address indexed _user, uint256 _paidAmount, uint256 _lockedAmount, uint256 _boostedAmount);
    event Withdrawn(address indexed _user, uint256 _amount, bool _relocked);
    event KickReward(address indexed _user, address indexed _kicked, uint256 _reward);
    event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
    event Recovered(address _token, uint256 _amount);
}