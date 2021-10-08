/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// File: contracts\interfaces\ILockedCvx.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ILockedCvx{
    function lock(address _account, uint256 _amount, uint256 _spendRatio) external;
    function processExpiredLocks(bool _relock, uint256 _spendRatio, address _withdrawTo) external;
    function getReward(address _account, bool _stake) external;
    function balanceAtEpochOf(uint256 _epoch, address _user) view external returns(uint256 amount);
    function totalSupplyAtEpoch(uint256 _epoch) view external returns(uint256 supply);
    function epochCount() external view returns(uint256);
    function checkpointEpoch() external;
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

// File: contracts\vlCvxExtraRewardDistribution.sol

pragma solidity 0.6.12;


//Distribute various rewards to locked cvx holders
// - Rewards added are assigned to the previous epoch (it was the previous epoch lockers who deserve today's rewards)
// - As soon as claiming for a token at an epoch is eligibe, no more tokens should be allowed to be added
// - To allow multiple txs to add to the same token, rewards added during the current epoch (and assigned to previous) will not
//     be claimable until the beginning of the next epoch. The "reward assigning phase" must be complete first
//example: 
//Current epoch: 10
//During this week all addReward() calls are assigned to users in epoch 9
//Users who were locked in epoch 9 can claim once epoch 11 begins
// -> epoch 10 is the assigning phase for epoch 9, thus we must wait until 10 is complete before claiming 9
contract vlCvxExtraRewardDistribution {
    using SafeERC20
    for IERC20;
    using BoringMath
    for uint256;

    ILockedCvx public constant cvxlocker = ILockedCvx(0xD18140b4B819b895A3dba5442F959fA44994AF50);
    uint256 public constant rewardsDuration = 86400 * 7;

    mapping(address => mapping(uint256 => uint256)) public rewardData; // token -> epoch -> amount
    mapping(address => uint256[]) public rewardEpochs; // token -> epochList
    mapping(address => mapping(address => uint256)) public userClaims; //token -> account -> last claimed epoch index

    constructor() public {}


    function rewardEpochsCount(address _token) external view returns(uint256) {
        return rewardEpochs[_token].length;
    }

    //add a reward to a specific epoch
    function addRewardToEpoch(address _token, uint256 _amount, uint256 _epoch) external {
        //checkpoint locker
        cvxlocker.checkpointEpoch();


        //if adding a reward to a specific epoch, make sure it's
        //a.) an epoch older than the previous epoch (in which case use addReward)
        //b.) more recent than the previous reward
        //this means addRewardToEpoch can only be called *once* for a specific reward for a specific epoch
        //because they will be claimable immediately and amount shouldnt change after claiming begins
        //
        //conversely rewards can be piled up with addReward() because claiming is only available to completed epochs
        require(_epoch < cvxlocker.epochCount() - 2, "!prev epoch");
        uint256 l = rewardEpochs[_token].length;
        require(l == 0 || rewardEpochs[_token][l - 1] < _epoch, "old epoch");

        _addReward(_token, _amount, _epoch);
    }

    //add a reward to the current epoch. can be called multiple times for the same reward token
    function addReward(address _token, uint256 _amount) external {
        //checkpoint locker
        cvxlocker.checkpointEpoch();

        //assign to previous epoch
        uint256 prevEpoch = cvxlocker.epochCount() - 2;

        _addReward(_token, _amount, prevEpoch);
    }

    function _addReward(address _token, uint256 _amount, uint256 _epoch) internal {
        //convert to reward per token
        uint256 supply = cvxlocker.totalSupplyAtEpoch(_epoch);
        uint256 rPerT = _amount.mul(1e20).div(supply);
        rewardData[_token][_epoch] = rewardData[_token][_epoch].add(rPerT);

        //add epoch to list
        uint256 l = rewardEpochs[_token].length;
        if (l == 0 || rewardEpochs[_token][l - 1] < _epoch) {
            rewardEpochs[_token].push(_epoch);
        }

        //pull
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    
        //event
        emit RewardAdded(_token, _epoch, _amount);
    }

    //get claimable rewards for a specific token
    function claimableRewards(address _account, address _token) external view returns(uint256) {
        (uint256 rewards,) = _allClaimableRewards(_account, _token);
        return rewards;
    }

    //get claimable rewards for a token at a specific epoch
    function claimableRewardsAtEpoch(address _account, address _token, uint256 _epoch) external view returns(uint256) {
        return _claimableRewards(_account, _token, _epoch);
    }

    //get all claimable rewards
    function _allClaimableRewards(address _account, address _token) internal view returns(uint256,uint256) {
        uint256 epochIndex = userClaims[_token][_account];
        uint256 prevEpoch = cvxlocker.epochCount() - 2;
        uint256 claimableTokens = 0;
        for (uint256 i = epochIndex; i < rewardEpochs[_token].length; i++) {
            //only claimable after rewards are "locked in"
            if (rewardEpochs[_token][i] < prevEpoch) {
                claimableTokens = claimableTokens.add(_claimableRewards(_account, _token, rewardEpochs[_token][i]));
                //return index user claims should be set to
                epochIndex = i+1;
            }
        }
        return (claimableTokens, epochIndex);
    }

    //get claimable rewards for a token at a specific epoch
    function _claimableRewards(address _account, address _token, uint256 _epoch) internal view returns(uint256) {
        //get balance and calc share
        uint256 balance = cvxlocker.balanceAtEpochOf(_epoch, _account);
        return balance.mul(rewardData[_token][_epoch]).div(1e20);
    }

    //claim rewards for a specific token at a specific epoch
    function getReward(address _account, address _token) public {
        //get claimable tokens
        (uint256 claimableTokens, uint256 index) = _allClaimableRewards(_account, _token);

        if (claimableTokens > 0) {
            //set claim checkpoint
            userClaims[_token][_account] = index;

            //send
            IERC20(_token).safeTransfer(_account, claimableTokens);

            //event
            emit RewardPaid(_account, _token, claimableTokens);
        }
    }

    //claim multiple tokens
    function getRewards(address _account, address[] calldata _tokens) external {
        for(uint i = 0; i < _tokens.length; i++){
            getReward(_account, _tokens[i]);
        }
    }

    //Because claims cycle through all periods that a specific reward was given
    //there becomes a situation where, for example, a new user could lock
    //2 years from now and try to claim a token that was given out every week prior.
    //This would result in a 2mil gas checkpoint.(about 20k gas * 52 weeks * 2 years)
    //
    //allow a user to set their claimed index forward without claiming rewards
    function forfeitRewards(address _token, uint256 _index) external {
        require(_index > 0 && _index < rewardEpochs[_token].length-1, "!past");
        require(_index >= userClaims[_token][msg.sender], "already claimed");

        //set claim checkpoint. next claim starts from index+1
        userClaims[_token][msg.sender] = _index + 1;

        emit RewardForfeited(msg.sender, _token, _index);
    }


    /* ========== EVENTS ========== */
    event RewardAdded(address indexed _token, uint256 indexed _epoch, uint256 _reward);
    event RewardPaid(address indexed _user, address indexed _rewardsToken, uint256 _reward);
    event RewardForfeited(address indexed _user, address indexed _rewardsToken, uint256 _index);
}