/**
 *Submitted for verification at Etherscan.io on 2021-07-28
*/

/*
https://powerpool.finance/

          wrrrw r wrr
         ppwr rrr wppr0       prwwwrp                                 prwwwrp                   wr0
        rr 0rrrwrrprpwp0      pp   pr  prrrr0 pp   0r  prrrr0  0rwrrr pp   pr  prrrr0  prrrr0    r0
        rrp pr   wr00rrp      prwww0  pp   wr pp w00r prwwwpr  0rw    prwww0  pp   wr pp   wr    r0
        r0rprprwrrrp pr0      pp      wr   pr pp rwwr wr       0r     pp      wr   pr wr   pr    r0
         prwr wrr0wpwr        00        www0   0w0ww    www0   0w     00        www0    www0   0www0
          wrr ww0rrrr

*/

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

// File: @powerpool/power-oracle/contracts/interfaces/IPowerPoke.sol

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IPowerPoke {
  /*** CLIENT'S CONTRACT INTERFACE ***/
  function authorizeReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporter(uint256 userId_, address pokerKey_) external view;

  function authorizeNonReporterWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinDeposit_
  ) external view;

  function authorizePoker(uint256 userId_, address pokerKey_) external view;

  function authorizePokerWithDeposit(
    uint256 userId_,
    address pokerKey_,
    uint256 overrideMinStake_
  ) external view;

  function slashReporter(uint256 slasherId_, uint256 times_) external;

  function reward(
    uint256 userId_,
    uint256 gasUsed_,
    uint256 compensationPlan_,
    bytes calldata pokeOptions_
  ) external;

  /*** CLIENT OWNER INTERFACE ***/
  function transferClientOwnership(address client_, address to_) external;

  function addCredit(address client_, uint256 amount_) external;

  function withdrawCredit(
    address client_,
    address to_,
    uint256 amount_
  ) external;

  function setReportIntervals(
    address client_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setSlasherHeartbeat(address client_, uint256 slasherHeartbeat_) external;

  function setGasPriceLimit(address client_, uint256 gasPriceLimit_) external;

  function setFixedCompensations(
    address client_,
    uint256 eth_,
    uint256 cvp_
  ) external;

  function setBonusPlan(
    address client_,
    uint256 planId_,
    bool active_,
    uint64 bonusNominator_,
    uint64 bonusDenominator_,
    uint64 perGas_
  ) external;

  function setMinimalDeposit(address client_, uint256 defaultMinDeposit_) external;

  /*** POKER INTERFACE ***/
  function withdrawRewards(uint256 userId_, address to_) external;

  function setPokerKeyRewardWithdrawAllowance(uint256 userId_, bool allow_) external;

  /*** OWNER INTERFACE ***/
  function addClient(
    address client_,
    address owner_,
    bool canSlash_,
    uint256 gasPriceLimit_,
    uint256 minReportInterval_,
    uint256 maxReportInterval_
  ) external;

  function setClientActiveFlag(address client_, bool active_) external;

  function setCanSlashFlag(address client_, bool canSlash) external;

  function setOracle(address oracle_) external;

  function pause() external;

  function unpause() external;

  /*** GETTERS ***/
  function creditOf(address client_) external view returns (uint256);

  function ownerOf(address client_) external view returns (address);

  function getMinMaxReportIntervals(address client_) external view returns (uint256 min, uint256 max);

  function getSlasherHeartbeat(address client_) external view returns (uint256);

  function getGasPriceLimit(address client_) external view returns (uint256);

  function getPokerBonus(
    address client_,
    uint256 bonusPlanId_,
    uint256 gasUsed_,
    uint256 userDeposit_
  ) external view returns (uint256);

  function getGasPriceFor(address client_) external view returns (uint256);
}

// File: contracts/interfaces/IUniswapV2Router01.sol

pragma solidity 0.6.12;

interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);
  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
  external
  payable
  returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/interfaces/IUniswapV2Router02.sol

pragma solidity 0.6.12;

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);
  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// File: contracts/interfaces/TokenInterface.sol

pragma solidity 0.6.12;

interface TokenInterface is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// File: contracts/interfaces/BMathInterface.sol

pragma solidity 0.6.12;

interface BMathInterface {
  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) external pure returns (uint256 tokenAmountIn);
}

// File: contracts/interfaces/BPoolInterface.sol

pragma solidity 0.6.12;

interface BPoolInterface is IERC20, BMathInterface {
  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external returns (uint256);

  function getDenormalizedWeight(address) external view returns (uint256);

  function getBalance(address) external view returns (uint256);

  function getSwapFee() external view returns (uint256);

  function getTotalDenormalizedWeight() external view returns (uint256);

  function getCommunityFee()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      address
    );

  function calcAmountWithCommunityFee(
    uint256,
    uint256,
    address
  ) external view returns (uint256, uint256);

  function getRestrictions() external view returns (address);

  function isPublicSwap() external view returns (bool);

  function isFinalized() external view returns (bool);

  function isBound(address t) external view returns (bool);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getFinalTokens() external view returns (address[] memory tokens);

  function setSwapFee(uint256) external;

  function setCommunityFeeAndReceiver(
    uint256,
    uint256,
    uint256,
    address
  ) external;

  function setController(address) external;

  function setPublicSwap(bool) external;

  function finalize() external;

  function bind(
    address,
    uint256,
    uint256
  ) external;

  function rebind(
    address,
    uint256,
    uint256
  ) external;

  function unbind(address) external;

  function gulp(address) external;

  function callVoting(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  function getMinWeight() external view returns (uint256);

  function getMaxBoundTokens() external view returns (uint256);
}

// File: contracts/interfaces/ICVPMakerStrategy.sol

pragma solidity 0.6.12;

interface ICVPMakerStrategy {
  function getExecuteDataByAmountOut(
    address poolTokenIn_,
    uint256 tokenOutAmount_,
    bytes memory config_
  )
    external
    view
    returns (
      uint256 poolTokenInAmount,
      address executeUniLikeFrom,
      bytes memory executeData,
      address executeContract
    );

  function getExecuteDataByAmountIn(
    address poolTokenIn_,
    uint256 tokenInAmount_,
    bytes memory config_
  )
    external
    view
    returns (
      address executeUniLikeFrom,
      bytes memory executeData,
      address executeContract
    );

  function estimateIn(
    address tokenIn_,
    uint256 tokenOutAmount_,
    bytes memory
  ) external view returns (uint256 amountIn);

  function estimateOut(
    address poolTokenIn_,
    uint256 tokenInAmount_,
    bytes memory
  ) external view returns (uint256);

  function getTokenOut() external view returns (address);
}

// File: contracts/balancer-core/BConst.sol
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

contract BConst {
    uint public constant BONE              = 10**18;
    // Minimum number of tokens in the pool
    uint public constant MIN_BOUND_TOKENS  = 2;
    // Maximum number of tokens in the pool
    uint public constant MAX_BOUND_TOKENS  = 9;
    // Minimum swap fee
    uint public constant MIN_FEE           = BONE / 10**6;
    // Maximum swap fee
    uint public constant MAX_FEE           = BONE / 10;
    // Minimum weight for token
    uint public constant MIN_WEIGHT        = 1000000000;
    // Maximum weight for token
    uint public constant MAX_WEIGHT        = BONE * 50;
    // Maximum total weight
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    // Minimum balance for a token
    uint public constant MIN_BALANCE       = BONE / 10**12;
    // Initial pool tokens supply
    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;
    // Maximum input tokens balance ratio for swaps.
    uint public constant MAX_IN_RATIO      = BONE / 2;
    // Maximum output tokens balance ratio for swaps.
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// File: contracts/balancer-core/BNum.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;


contract BNum is BConst {

    function btoi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function bfloor(uint a)
        internal pure
        returns (uint)
    {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b)
        internal pure
        returns (uint)
    {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b)
        internal pure
        returns (uint)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b)
        internal pure
        returns (uint)
    {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b > 0, "ERR_DIV_ZERO");
      return a / b;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n)
        internal pure
        returns (uint)
    {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole  = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = bsubSign(base, BONE);
        uint term = BONE;
        uint sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }

}

// File: contracts/balancer-core/BMath.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;



contract BMath is BConst, BNum, BMathInterface {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    )
        public pure virtual
        returns (uint spotPrice)
    {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return  (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure virtual
        returns (uint tokenAmountOut)
    {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure virtual override
        returns (uint tokenAmountIn)
    {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        public pure virtual
        returns (uint poolAmountOut)
    {
        // Charge the trading fee for the proportion of tokenAi
        ///  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        public pure virtual override
        returns (uint tokenAmountIn)
    {
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = bdiv(BONE, normalizedWeight);
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      //       pS - pAi        \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        public pure virtual
        returns (uint tokenAmountOut)
    {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        uint newPoolSupply = bsub(poolSupply, poolAmountIn);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight                                                                          //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        public pure virtual
        returns (uint poolAmountIn)
    {

        // charge swap fee on the output token side
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountIn = bsub(poolSupply, newPoolSupply);
        return poolAmountIn;
    }
}

// File: contracts/interfaces/WrappedPiErc20Interface.sol

pragma solidity 0.6.12;

interface WrappedPiErc20Interface is IERC20 {
  function deposit(uint256 _amount) external payable returns (uint256);

  function withdraw(uint256 _amount) external payable returns (uint256);

  function changeRouter(address _newRouter) external;

  function setEthFee(uint256 _newEthFee) external;

  function withdrawEthFee(address payable receiver) external;

  function approveUnderlying(address _to, uint256 _amount) external;

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) external view returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount) external view returns (uint256);

  function balanceOfUnderlying(address account) external view returns (uint256);

  function callExternal(
    address voting,
    bytes4 signature,
    bytes calldata args,
    uint256 value
  ) external;

  struct ExternalCallData {
    address destination;
    bytes4 signature;
    bytes args;
    uint256 value;
  }

  function callExternalMultiple(ExternalCallData[] calldata calls) external;

  function getUnderlyingBalance() external view returns (uint256);
}

// File: contracts/interfaces/PowerIndexWrapperInterface.sol

pragma solidity 0.6.12;

interface PowerIndexWrapperInterface {
  function getFinalTokens() external view returns (address[] memory tokens);

  function getCurrentTokens() external view returns (address[] memory tokens);

  function getBalance(address _token) external view returns (uint256);

  function setPiTokenForUnderlyingsMultiple(address[] calldata _underlyingTokens, address[] calldata _piTokens)
    external;

  function setPiTokenForUnderlying(address _underlyingTokens, address _piToken) external;

  function updatePiTokenEthFees(address[] calldata _underlyingTokens) external;

  function withdrawOddEthFee(address payable _recipient) external;

  function calcEthFeeForTokens(address[] memory tokens) external view returns (uint256 feeSum);

  function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external payable;

  function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external payable;

  function swapExactAmountIn(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external payable returns (uint256, uint256);

  function swapExactAmountOut(
    address,
    uint256,
    address,
    uint256,
    uint256
  ) external payable returns (uint256, uint256);

  function joinswapExternAmountIn(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function joinswapPoolAmountOut(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function exitswapPoolAmountIn(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);

  function exitswapExternAmountOut(
    address,
    uint256,
    uint256
  ) external payable returns (uint256);
}

// File: contracts/lib/ControllerOwnable.sol

pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an controller) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the controller account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract ControllerOwnable {
    address private _controller;

    event SetController(address indexed previousController, address indexed newController);

    /**
     * @dev Initializes the contract setting the deployer as the initial controller.
     */
    constructor () internal {
        _controller = msg.sender;
        emit SetController(address(0), _controller);
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function getController() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Give the controller permissions to a new account (`newController`).
     * Can only be called by the current controller.
     */
    function setController(address newController) public virtual onlyController {
        require(newController != address(0), "ControllerOwnable: new controller is the zero address");
        emit SetController(_controller, newController);
        _controller = newController;
    }
}

// File: contracts/powerindex-router/PowerIndexWrapper.sol

pragma solidity 0.6.12;

contract PowerIndexWrapper is ControllerOwnable, BMath, PowerIndexWrapperInterface {
  using SafeMath for uint256;

  event SetPiTokenForUnderlying(address indexed underlyingToken, address indexed piToken);
  event UpdatePiTokenEthFee(address indexed piToken, uint256 ethFee);

  BPoolInterface public immutable bpool;

  mapping(address => address) public piTokenByUnderlying;
  mapping(address => address) public underlyingByPiToken;
  mapping(address => uint256) public ethFeeByPiToken;

  constructor(address _bpool) public ControllerOwnable() {
    bpool = BPoolInterface(_bpool);
    BPoolInterface(_bpool).approve(_bpool, uint256(-1));

    address[] memory tokens = BPoolInterface(_bpool).getCurrentTokens();
    uint256 len = tokens.length;
    for (uint256 i = 0; i < len; i++) {
      IERC20(tokens[i]).approve(_bpool, uint256(-1));
    }
  }

  function withdrawOddEthFee(address payable _recipient) external override onlyController {
    _recipient.transfer(address(this).balance);
  }

  function setPiTokenForUnderlyingsMultiple(address[] calldata _underlyingTokens, address[] calldata _piTokens)
    external
    override
    onlyController
  {
    uint256 len = _underlyingTokens.length;
    require(len == _piTokens.length, "LENGTH_DONT_MATCH");

    for (uint256 i = 0; i < len; i++) {
      _setPiTokenForUnderlying(_underlyingTokens[i], _piTokens[i]);
    }
  }

  function setPiTokenForUnderlying(address _underlyingToken, address _piToken) external override onlyController {
    _setPiTokenForUnderlying(_underlyingToken, _piToken);
  }

  function updatePiTokenEthFees(address[] calldata _underlyingTokens) external override {
    uint256 len = _underlyingTokens.length;

    for (uint256 i = 0; i < len; i++) {
      _updatePiTokenEthFee(piTokenByUnderlying[_underlyingTokens[i]]);
    }
  }

  function swapExactAmountOut(
    address tokenIn,
    uint256 maxAmountIn,
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPrice
  ) external payable override returns (uint256 tokenAmountIn, uint256 spotPriceAfter) {
    (address actualTokenIn, uint256 actualMaxAmountIn) = _getActualTokenAndAmount(tokenIn, maxAmountIn);
    (address actualTokenOut, uint256 actualTokenAmountOut) = _getActualTokenAndAmount(tokenOut, tokenAmountOut);
    uint256 actualMaxPrice =
      getActualMaxPrice(maxAmountIn, actualMaxAmountIn, tokenAmountOut, actualTokenAmountOut, maxPrice);
    uint256 amountInRate = actualMaxAmountIn.mul(uint256(1 ether)).div(maxAmountIn);

    uint256 prevMaxAmount = actualMaxAmountIn;
    actualMaxAmountIn = calcInGivenOut(
      bpool.getBalance(actualTokenIn),
      bpool.getDenormalizedWeight(actualTokenIn),
      bpool.getBalance(actualTokenOut),
      bpool.getDenormalizedWeight(actualTokenOut),
      actualTokenAmountOut,
      bpool.getSwapFee()
    );
    if (prevMaxAmount > actualMaxAmountIn) {
      maxAmountIn = actualMaxAmountIn.mul(uint256(1 ether)).div(amountInRate);
    } else {
      actualMaxAmountIn = prevMaxAmount;
    }

    _processUnderlyingTokenIn(tokenIn, maxAmountIn);

    (tokenAmountIn, spotPriceAfter) = bpool.swapExactAmountOut(
      actualTokenIn,
      actualMaxAmountIn,
      actualTokenOut,
      actualTokenAmountOut,
      actualMaxPrice
    );

    _processUnderlyingOrPiTokenOutBalance(tokenOut);

    return (tokenAmountIn, spotPriceAfter);
  }

  function swapExactAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    address tokenOut,
    uint256 minAmountOut,
    uint256 maxPrice
  ) external payable override returns (uint256 tokenAmountOut, uint256 spotPriceAfter) {
    (address actualTokenIn, uint256 actualAmountIn) = _processUnderlyingTokenIn(tokenIn, tokenAmountIn);
    (address actualTokenOut, uint256 actualMinAmountOut) = _getActualTokenAndAmount(tokenOut, minAmountOut);
    uint256 actualMaxPrice =
      getActualMaxPrice(tokenAmountIn, actualAmountIn, minAmountOut, actualMinAmountOut, maxPrice);

    (tokenAmountOut, spotPriceAfter) = bpool.swapExactAmountIn(
      actualTokenIn,
      actualAmountIn,
      actualTokenOut,
      actualMinAmountOut,
      actualMaxPrice
    );

    _processUnderlyingOrPiTokenOutBalance(tokenOut);

    return (tokenAmountOut, spotPriceAfter);
  }

  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external payable override {
    address[] memory tokens = getCurrentTokens();
    uint256 len = tokens.length;
    require(maxAmountsIn.length == len, "ERR_LENGTH_MISMATCH");

    uint256 ratio = poolAmountOut.mul(1 ether).div(bpool.totalSupply()).add(100);

    for (uint256 i = 0; i < len; i++) {
      (address actualToken, uint256 actualMaxAmountIn) = _getActualTokenAndAmount(tokens[i], maxAmountsIn[i]);
      uint256 amountInRate = actualMaxAmountIn.mul(uint256(1 ether)).div(maxAmountsIn[i]);

      uint256 prevMaxAmount = actualMaxAmountIn;
      actualMaxAmountIn = ratio.mul(bpool.getBalance(actualToken)).div(1 ether);
      if (prevMaxAmount > actualMaxAmountIn) {
        maxAmountsIn[i] = actualMaxAmountIn.mul(uint256(1 ether)).div(amountInRate);
      } else {
        actualMaxAmountIn = prevMaxAmount;
      }

      _processUnderlyingTokenIn(tokens[i], maxAmountsIn[i]);
      maxAmountsIn[i] = actualMaxAmountIn;
    }
    bpool.joinPool(poolAmountOut, maxAmountsIn);
    require(bpool.transfer(msg.sender, bpool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
  }

  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external payable override {
    address[] memory tokens = getCurrentTokens();
    uint256 len = tokens.length;
    require(minAmountsOut.length == len, "ERR_LENGTH_MISMATCH");

    bpool.transferFrom(msg.sender, address(this), poolAmountIn);

    for (uint256 i = 0; i < len; i++) {
      (, minAmountsOut[i]) = _getActualTokenAndAmount(tokens[i], minAmountsOut[i]);
    }

    bpool.exitPool(poolAmountIn, minAmountsOut);

    for (uint256 i = 0; i < len; i++) {
      _processUnderlyingOrPiTokenOutBalance(tokens[i]);
    }
  }

  function joinswapExternAmountIn(
    address tokenIn,
    uint256 tokenAmountIn,
    uint256 minPoolAmountOut
  ) external payable override returns (uint256 poolAmountOut) {
    (address actualTokenIn, uint256 actualAmountIn) = _processUnderlyingTokenIn(tokenIn, tokenAmountIn);
    poolAmountOut = bpool.joinswapExternAmountIn(actualTokenIn, actualAmountIn, minPoolAmountOut);
    require(bpool.transfer(msg.sender, bpool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    return poolAmountOut;
  }

  function joinswapPoolAmountOut(
    address tokenIn,
    uint256 poolAmountOut,
    uint256 maxAmountIn
  ) external payable override returns (uint256 tokenAmountIn) {
    (address actualTokenIn, uint256 actualMaxAmountIn) = _getActualTokenAndAmount(tokenIn, maxAmountIn);
    uint256 amountInRate = actualMaxAmountIn.mul(uint256(1 ether)).div(maxAmountIn);

    uint256 prevMaxAmount = maxAmountIn;
    maxAmountIn = calcSingleInGivenPoolOut(
      getBalance(tokenIn),
      bpool.getDenormalizedWeight(actualTokenIn),
      bpool.totalSupply(),
      bpool.getTotalDenormalizedWeight(),
      poolAmountOut,
      bpool.getSwapFee()
    );
    if (prevMaxAmount > maxAmountIn) {
      maxAmountIn = maxAmountIn;
      actualMaxAmountIn = maxAmountIn.mul(amountInRate).div(uint256(1 ether));
    } else {
      maxAmountIn = prevMaxAmount;
    }

    _processUnderlyingTokenIn(tokenIn, maxAmountIn);
    tokenAmountIn = bpool.joinswapPoolAmountOut(actualTokenIn, poolAmountOut, actualMaxAmountIn);
    require(bpool.transfer(msg.sender, bpool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    return tokenAmountIn;
  }

  function exitswapPoolAmountIn(
    address tokenOut,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external payable override returns (uint256 tokenAmountOut) {
    require(bpool.transferFrom(msg.sender, address(this), poolAmountIn), "ERR_TRANSFER_FAILED");

    (address actualTokenOut, uint256 actualMinAmountOut) = _getActualTokenAndAmount(tokenOut, minAmountOut);
    tokenAmountOut = bpool.exitswapPoolAmountIn(actualTokenOut, poolAmountIn, actualMinAmountOut);
    _processUnderlyingOrPiTokenOutBalance(tokenOut);
    return tokenAmountOut;
  }

  function exitswapExternAmountOut(
    address tokenOut,
    uint256 tokenAmountOut,
    uint256 maxPoolAmountIn
  ) external payable override returns (uint256 poolAmountIn) {
    require(bpool.transferFrom(msg.sender, address(this), maxPoolAmountIn), "ERR_TRANSFER_FAILED");

    (address actualTokenOut, uint256 actualTokenAmountOut) = _getActualTokenAndAmount(tokenOut, tokenAmountOut);
    poolAmountIn = bpool.exitswapExternAmountOut(actualTokenOut, actualTokenAmountOut, maxPoolAmountIn);
    _processUnderlyingOrPiTokenOutBalance(tokenOut);
    require(bpool.transfer(msg.sender, maxPoolAmountIn.sub(poolAmountIn)), "ERR_TRANSFER_FAILED");
    return poolAmountIn;
  }

  function calcInGivenOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super.calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee).add(
        1
      );
  }

  function calcSingleInGivenPoolOut(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountOut,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super
        .calcSingleInGivenPoolOut(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, poolAmountOut, swapFee)
        .add(1);
  }

  function calcPoolInGivenSingleOut(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountOut,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super
        .calcPoolInGivenSingleOut(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, tokenAmountOut, swapFee)
        .add(1);
  }

  function calcSpotPrice(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return super.calcSpotPrice(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, swapFee).add(1);
  }

  function calcOutGivenIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee).sub(
        10
      );
  }

  function calcPoolOutGivenSingleIn(
    uint256 tokenBalanceIn,
    uint256 tokenWeightIn,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 tokenAmountIn,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super
        .calcPoolOutGivenSingleIn(tokenBalanceIn, tokenWeightIn, poolSupply, totalWeight, tokenAmountIn, swapFee)
        .sub(10);
  }

  function calcSingleOutGivenPoolIn(
    uint256 tokenBalanceOut,
    uint256 tokenWeightOut,
    uint256 poolSupply,
    uint256 totalWeight,
    uint256 poolAmountIn,
    uint256 swapFee
  ) public pure override returns (uint256) {
    return
      super
        .calcSingleOutGivenPoolIn(tokenBalanceOut, tokenWeightOut, poolSupply, totalWeight, poolAmountIn, swapFee)
        .sub(10);
  }

  function getDenormalizedWeight(address token) external view returns (uint256) {
    return bpool.getDenormalizedWeight(_getActualToken(token));
  }

  function getSwapFee() external view returns (uint256) {
    return bpool.getSwapFee();
  }

  function calcEthFeeForTokens(address[] memory tokens) external view override returns (uint256 feeSum) {
    uint256 len = tokens.length;
    for (uint256 i = 0; i < len; i++) {
      address piToken = address(0);
      if (underlyingByPiToken[tokens[i]] != address(0)) {
        piToken = tokens[i];
      } else if (piTokenByUnderlying[tokens[i]] != address(0)) {
        piToken = piTokenByUnderlying[tokens[i]];
      }
      if (piToken != address(0)) {
        feeSum = feeSum.add(WrappedPiErc20EthFeeInterface(piToken).ethFee());
      }
    }
  }

  function getCurrentTokens() public view override returns (address[] memory tokens) {
    tokens = bpool.getCurrentTokens();

    uint256 len = tokens.length;
    for (uint256 i = 0; i < len; i++) {
      if (underlyingByPiToken[tokens[i]] != address(0)) {
        tokens[i] = underlyingByPiToken[tokens[i]];
      }
    }
  }

  function getFinalTokens() public view override returns (address[] memory tokens) {
    return getCurrentTokens();
  }

  function getBalance(address _token) public view override returns (uint256) {
    address piTokenAddress = piTokenByUnderlying[_token];
    if (piTokenAddress == address(0)) {
      return bpool.getBalance(_token);
    }
    return WrappedPiErc20EthFeeInterface(piTokenAddress).getUnderlyingEquivalentForPi(bpool.getBalance(piTokenAddress));
  }

  function getActualMaxPrice(
    uint256 amountIn,
    uint256 actualAmountIn,
    uint256 amountOut,
    uint256 actualAmountOut,
    uint256 maxPrice
  ) public returns (uint256 actualMaxPrice) {
    uint256 amountInRate = amountIn.mul(uint256(1 ether)).div(actualAmountIn);
    uint256 amountOutRate = actualAmountOut.mul(uint256(1 ether)).div(amountOut);
    return
      amountInRate > amountOutRate
        ? maxPrice.mul(amountInRate).div(amountOutRate)
        : maxPrice.mul(amountOutRate).div(amountInRate);
  }

  function _processUnderlyingTokenIn(address _underlyingToken, uint256 _amount)
    internal
    returns (address actualToken, uint256 actualAmount)
  {
    if (_amount == 0) {
      return (_underlyingToken, _amount);
    }
    require(IERC20(_underlyingToken).transferFrom(msg.sender, address(this), _amount), "ERR_TRANSFER_FAILED");

    actualToken = piTokenByUnderlying[_underlyingToken];
    if (actualToken == address(0)) {
      return (_underlyingToken, _amount);
    }
    actualAmount = WrappedPiErc20Interface(actualToken).deposit{ value: ethFeeByPiToken[actualToken] }(_amount);
  }

  function _processPiTokenOutBalance(address _piToken) internal {
    uint256 balance = WrappedPiErc20EthFeeInterface(_piToken).balanceOfUnderlying(address(this));

    WrappedPiErc20Interface(_piToken).withdraw{ value: ethFeeByPiToken[_piToken] }(balance);

    require(IERC20(underlyingByPiToken[_piToken]).transfer(msg.sender, balance), "ERR_TRANSFER_FAILED");
  }

  function _processUnderlyingTokenOutBalance(address _underlyingToken) internal returns (uint256 balance) {
    balance = IERC20(_underlyingToken).balanceOf(address(this));
    require(IERC20(_underlyingToken).transfer(msg.sender, balance), "ERR_TRANSFER_FAILED");
  }

  function _processUnderlyingOrPiTokenOutBalance(address _underlyingOrPiToken) internal {
    address piToken = piTokenByUnderlying[_underlyingOrPiToken];
    if (piToken == address(0)) {
      _processUnderlyingTokenOutBalance(_underlyingOrPiToken);
    } else {
      _processPiTokenOutBalance(piToken);
    }
  }

  function _getActualToken(address token) internal view returns (address) {
    address piToken = piTokenByUnderlying[token];
    return piToken == address(0) ? token : piToken;
  }

  function _getActualTokenAndAmount(address token, uint256 amount)
    internal
    view
    returns (address actualToken, uint256 actualAmount)
  {
    address piToken = piTokenByUnderlying[token];
    if (piToken == address(0)) {
      return (token, amount);
    }
    return (piToken, WrappedPiErc20EthFeeInterface(piToken).getPiEquivalentForUnderlying(amount));
  }

  function _setPiTokenForUnderlying(address underlyingToken, address piToken) internal {
    piTokenByUnderlying[underlyingToken] = piToken;
    if (piToken == address(0)) {
      IERC20(underlyingToken).approve(address(bpool), uint256(-1));
    } else {
      underlyingByPiToken[piToken] = underlyingToken;
      IERC20(piToken).approve(address(bpool), uint256(-1));
      IERC20(underlyingToken).approve(piToken, uint256(-1));
      _updatePiTokenEthFee(piToken);
    }
    emit SetPiTokenForUnderlying(underlyingToken, piToken);
  }

  function _updatePiTokenEthFee(address piToken) internal {
    if (piToken == address(0)) {
      return;
    }
    uint256 ethFee = WrappedPiErc20EthFeeInterface(piToken).ethFee();
    if (ethFeeByPiToken[piToken] == ethFee) {
      return;
    }
    ethFeeByPiToken[piToken] = ethFee;
    emit UpdatePiTokenEthFee(piToken, ethFee);
  }
}

interface WrappedPiErc20EthFeeInterface {
  function ethFee() external view returns (uint256);

  function router() external view returns (address);

  function getPiEquivalentForUnderlying(uint256 _underlyingAmount) external view returns (uint256);

  function getUnderlyingEquivalentForPi(uint256 _piAmount) external view returns (uint256);

  function balanceOfUnderlying(address _account) external view returns (uint256);
}

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


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
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
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
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: contracts/interfaces/IPoolRestrictions.sol

pragma solidity 0.6.12;

interface IPoolRestrictions {
  function getMaxTotalSupply(address _pool) external view returns (uint256);

  function isVotingSignatureAllowed(address _votingAddress, bytes4 _signature) external view returns (bool);

  function isVotingSenderAllowed(address _votingAddress, address _sender) external view returns (bool);

  function isWithoutFee(address _addr) external view returns (bool);
}

// File: contracts/pvp/CVPMakerStorage.sol

pragma solidity 0.6.12;

contract CVPMakerStorage is OwnableUpgradeSafe {
  IPowerPoke public powerPoke;

  uint256 public cvpAmountOut;

  uint256 public lastReporterPokeFrom;

  IPoolRestrictions public restrictions;

  // token => router
  mapping(address => address) public routers;

  // token => [path, to, cvp]
  mapping(address => address[]) public customPaths;

  // token => strategyId
  mapping(address => uint256) public customStrategies;

  struct ExternalStrategiesConfig {
    address strategy;
    bool maxAmountIn;
    bytes config;
  }

  // token => strategyAddress
  mapping(address => ExternalStrategiesConfig) public externalStrategiesConfig;

  struct Strategy1Config {
    address bPoolWrapper;
  }

  struct Strategy2Config {
    address bPoolWrapper;
    uint256 nextIndex;
    address[] tokens;
  }

  struct Strategy3Config {
    address bPool;
    address bPoolWrapper;
    address underlying;
  }

  mapping(address => Strategy1Config) public strategy1Config;

  mapping(address => Strategy2Config) public strategy2Config;

  mapping(address => Strategy3Config) public strategy3Config;
}

// File: contracts/interfaces/ICVPMakerViewer.sol

pragma solidity 0.6.12;

interface ICVPMakerViewer {
  function getRouter(address token_) external view returns (address);

  function getPath(address token_) external view returns (address[] memory);

  function getDefaultPath(address token_) external view returns (address[] memory);

  /*** ESTIMATIONS ***/

  function estimateEthStrategyIn() external view returns (uint256);

  function estimateEthStrategyOut(address tokenIn_, uint256 _amountIn) external view returns (uint256);

  function estimateUniLikeStrategyIn(address token_) external view returns (uint256);

  function estimateUniLikeStrategyOut(address token_, uint256 amountIn_) external view returns (uint256);

  /*** CUSTOM STRATEGIES OUT ***/

  function calcBPoolGrossAmount(uint256 tokenAmountNet_, uint256 communityFee_)
    external
    view
    returns (uint256 tokenAmountGross);
}

// File: contracts/pvp/CVPMakerViewer.sol

pragma solidity 0.6.12;

contract CVPMakerViewer is ICVPMakerViewer, CVPMakerStorage {
  using SafeMath for uint256;

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  uint256 public constant COMPENSATION_PLAN_1_ID = 1;
  uint256 public constant BONE = 10**18;

  // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address public immutable uniswapRouter;

  // 0x38e4adb44ef08f22f5b5b76a8f0c2d0dcbe7dca1
  address public immutable cvp;

  // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  address public immutable weth;

  address public immutable xcvp;

  constructor(
    address cvp_,
    address xcvp_,
    address weth_,
    address uniswapRouter_
  ) public {
    cvp = cvp_;
    xcvp = xcvp_;
    weth = weth_;
    uniswapRouter = uniswapRouter_;
  }

  function wethCVPPath() public view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = weth;
    path[1] = cvp;
    return path;
  }

  function _wethTokenPath(address _token) internal view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = _token;
    path[1] = weth;
    return path;
  }

  function getRouter(address token_) public view override returns (address) {
    address router = routers[token_];

    if (router == address(0)) {
      return uniswapRouter;
    }

    return router;
  }

  function getPath(address token_) public view override returns (address[] memory) {
    address[] storage customPath = customPaths[token_];

    if (customPath.length == 0) {
      return getDefaultPath(token_);
    }

    return customPath;
  }

  function getDefaultPath(address token_) public view override returns (address[] memory) {
    address[] memory path = new address[](3);

    path[0] = token_;
    path[1] = weth;
    path[2] = cvp;

    return path;
  }

  function getStrategy1Config(address token_) external view returns (address bPoolWrapper) {
    Strategy1Config memory strategy = strategy1Config[token_];
    return (strategy.bPoolWrapper);
  }

  function getStrategy2Config(address token_) external view returns (address bPoolWrapper, uint256 nextIndex) {
    Strategy2Config storage strategy = strategy2Config[token_];
    return (strategy.bPoolWrapper, strategy.nextIndex);
  }

  function getStrategy2Tokens(address token_) external view returns (address[] memory) {
    return strategy2Config[token_].tokens;
  }

  function getStrategy3Config(address token_)
    external
    view
    returns (
      address bPool,
      address bPoolWrapper,
      address underlying
    )
  {
    Strategy3Config storage strategy = strategy3Config[token_];
    return (strategy.bPool, strategy.bPoolWrapper, strategy.underlying);
  }

  function getExternalStrategyConfig(address token_)
    external
    view
    returns (
      address strategy,
      bool maxAmountIn,
      bytes memory config
    )
  {
    ExternalStrategiesConfig memory strategy = externalStrategiesConfig[token_];
    return (strategy.strategy, strategy.maxAmountIn, strategy.config);
  }

  function getCustomPaths(address token_) public view returns (address[] memory) {
    return customPaths[token_];
  }

  /*** ESTIMATIONS ***/

  function estimateEthStrategyIn() public view override returns (uint256) {
    uint256[] memory results = IUniswapV2Router02(uniswapRouter).getAmountsIn(cvpAmountOut, wethCVPPath());
    return results[0];
  }

  function estimateEthStrategyOut(address tokenIn_, uint256 _amountIn) public view override returns (uint256) {
    uint256[] memory results = IUniswapV2Router02(uniswapRouter).getAmountsOut(_amountIn, _wethTokenPath(tokenIn_));
    return results[0];
  }

  /**
   * @notice Estimates how much token_ need to swap for cvpAmountOut
   * @param token_ The token to swap for CVP
   * @return The estimated token_ amount in
   */
  function estimateUniLikeStrategyIn(address token_) public view override returns (uint256) {
    address router = getRouter(token_);
    address[] memory path = getPath(token_);

    if (router == uniswapRouter) {
      uint256[] memory results = IUniswapV2Router02(router).getAmountsIn(cvpAmountOut, path);
      return results[0];
    } else {
      uint256 wethToSwap = estimateEthStrategyIn();
      uint256[] memory results = IUniswapV2Router02(router).getAmountsIn(wethToSwap, path);
      return results[0];
    }
  }

  function estimateUniLikeStrategyOut(address token_, uint256 amountIn_) public view override returns (uint256) {
    address router = getRouter(token_);
    address[] memory path = getPath(token_);

    if (router == uniswapRouter) {
      uint256[] memory results = IUniswapV2Router02(router).getAmountsOut(amountIn_, path);
      return results[2];
    } else {
      uint256 wethToSwap = estimateEthStrategyOut(token_, amountIn_);
      uint256[] memory results = IUniswapV2Router02(router).getAmountsOut(wethToSwap, path);
      return results[2];
    }
  }

  /*** CUSTOM STRATEGIES OUT ***/

  /**
   * @notice Calculates the gross amount based on a net and a fee values. The function is opposite to
   * the BPool.calcAmountWithCommunityFee().
   */
  function calcBPoolGrossAmount(uint256 tokenAmountNet_, uint256 communityFee_)
    public
    view
    override
    returns (uint256 tokenAmountGross)
  {
    if (address(restrictions) != address(0) && restrictions.isWithoutFee(address(this))) {
      return (tokenAmountNet_);
    }
    uint256 adjustedIn = bsub(BONE, communityFee_);
    return bdiv(tokenAmountNet_, adjustedIn);
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "ERR_SUB_UNDERFLOW");
    return c;
  }

  function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "ERR_DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
    uint256 c2 = c1 / b;
    return c2;
  }
}

// File: contracts/pvp/CVPMaker.sol

pragma solidity 0.6.12;

contract CVPMaker is OwnableUpgradeSafe, CVPMakerStorage, CVPMakerViewer {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /// @notice The event emitted when the owner updates the powerOracleStaking address
  event SetPowerPoke(address powerPoke);
  /// @notice The event emitted when a poker calls swapFromReporter to convert token to CVP
  event Swap(
    address indexed caller,
    address indexed token,
    SwapType indexed swapType,
    uint256 amountIn,
    uint256 amountOut,
    uint256 xcvpCvpBefore,
    uint256 xcvpCvpAfter
  );
  /// @notice The event emitted when the owner updates cvpAmountOut value
  event SetPoolRestrictions(address poolRestrictions);
  /// @notice The event emitted when the owner updates cvpAmountOut value
  event SetCvpAmountOut(uint256 cvpAmountOut);
  /// @notice The event emitted when the owner updates a token custom uni-like path
  event SetCustomPath(address indexed token_, address router_, address[] path);
  /// @notice The event emitted when the owner assigns a custom strategy for the token
  event SetCustomStrategy(address indexed token, uint256 strategyId);
  /// @notice The event emitted when the owner configures an external strategy for the token
  event SetExternalStrategy(address indexed token_, address indexed strategy, bool maxAmountIn);

  enum SwapType { NULL, CVP, ETH, CUSTOM_STRATEGY, EXTERNAL_STRATEGY, UNI_LIKE_STRATEGY }

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "NOT_EOA");
    _;
  }

  modifier onlyReporter(uint256 reporterId_, bytes calldata rewardOpts_) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(reporterId_, msg.sender);
    _;
    powerPoke.reward(reporterId_, gasStart.sub(gasleft()), COMPENSATION_PLAN_1_ID, rewardOpts_);
  }

  modifier onlySlasher(uint256 slasherId_, bytes calldata rewardOpts_) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(slasherId_, msg.sender);
    _;
    powerPoke.reward(slasherId_, gasStart.sub(gasleft()), COMPENSATION_PLAN_1_ID, rewardOpts_);
  }

  constructor(
    address cvp_,
    address xcvp_,
    address weth_,
    address uniswapRouter_
  ) public CVPMakerViewer(cvp_, xcvp_, weth_, uniswapRouter_) {}

  receive() external payable {}

  function initialize(
    address powerPoke_,
    address restrictions_,
    uint256 cvpAmountOut_
  ) external initializer {
    require(cvpAmountOut_ > 0, "CVP_AMOUNT_OUT_0");

    powerPoke = IPowerPoke(powerPoke_);
    restrictions = IPoolRestrictions(restrictions_);
    cvpAmountOut = cvpAmountOut_;

    emit SetPowerPoke(powerPoke_);
    emit SetCvpAmountOut(cvpAmountOut_);

    __Ownable_init();
  }

  /**
   * @notice The swap call from the reporter
   * @param reporterId_ The current reporter id
   * @param token_ The token to swap to CVP
   * @param rewardOpts_ Custom settings for the reporter reward
   */
  function swapFromReporter(
    uint256 reporterId_,
    address token_,
    bytes calldata rewardOpts_
  ) external onlyEOA onlyReporter(reporterId_, rewardOpts_) {
    (uint256 minInterval, ) = _getMinMaxReportInterval();
    require(block.timestamp.sub(lastReporterPokeFrom) > minInterval, "MIN_INTERVAL_NOT_REACHED");
    _swap(token_);
  }

  /**
   * @notice The swap call from a slasher in case if the reporter has missed his call
   * @param slasherId_ The current slasher id
   * @param token_ The token to swap to CVP
   * @param rewardOpts_ Custom settings for the slasher reward
   */
  function swapFromSlasher(
    uint256 slasherId_,
    address token_,
    bytes calldata rewardOpts_
  ) external onlyEOA onlySlasher(slasherId_, rewardOpts_) {
    (, uint256 maxInterval) = _getMinMaxReportInterval();
    require(block.timestamp.sub(lastReporterPokeFrom) > maxInterval, "MAX_INTERVAL_NOT_REACHED");
    _swap(token_);
  }

  /*** SWAP HELPERS ***/

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    return powerPoke.getMinMaxReportIntervals(address(this));
  }

  function _swap(address token_) internal {
    uint256 cvpBefore = IERC20(cvp).balanceOf(xcvp);
    lastReporterPokeFrom = block.timestamp;
    uint256 cvpAmountOut_ = cvpAmountOut;
    SwapType sType;
    uint256 amountIn = 0;

    // Just transfer CVPs to xCVP contract
    if (token_ == cvp) {
      sType = SwapType.CVP;
      amountIn = IERC20(cvp).balanceOf(address(this));
      IERC20(cvp).safeTransfer(xcvp, amountIn);
      cvpAmountOut_ = amountIn;
    } else if (token_ == weth || token_ == ETH) {
      // Wrap ETH -> WETH
      if (token_ == ETH) {
        amountIn = address(this).balance;
        require(amountIn > 0, "ETH_BALANCE_IS_0");
        TokenInterface(weth).deposit{ value: amountIn }();
      }

      // Use a single pair path to swap WETH -> CVP
      amountIn = _swapWETHToCVP();
      sType = SwapType.ETH;
    } else {
      uint256 customStrategyId = customStrategies[token_];
      if (customStrategyId > 0) {
        amountIn = _executeCustomStrategy(token_, customStrategyId);
        sType = SwapType.CUSTOM_STRATEGY;
      } else if (externalStrategiesConfig[token_].strategy != address(0)) {
        amountIn = _executeExternalStrategy(token_);
        sType = SwapType.EXTERNAL_STRATEGY;
      } else {
        // Use a Uniswap-like strategy
        amountIn = _executeUniLikeStrategy(token_);
        sType = SwapType.UNI_LIKE_STRATEGY;
      }
    }
    uint256 cvpAfter = IERC20(cvp).balanceOf(xcvp);
    if (sType != SwapType.EXTERNAL_STRATEGY) {
      require(cvpAfter.sub(cvpBefore) >= (cvpAmountOut * 99) / 100, "LESS_THAN_CVP_AMOUNT_OUT");
    }

    emit Swap(msg.sender, token_, sType, amountIn, cvpAmountOut_, cvpBefore, cvpAfter);
  }

  function _executeUniLikeStrategy(address token_) internal returns (uint256 amountOut) {
    address router = getRouter(token_);
    address[] memory path = getPath(token_);

    if (router == uniswapRouter) {
      amountOut = _swapTokensForExactCVP(router, token_, path);
    } else {
      uint256 wethAmountIn = estimateEthStrategyIn();
      amountOut = _swapTokensForExactWETH(router, token_, path, wethAmountIn);
      _swapWETHToCVP();
    }
  }

  function _swapTokensForExactWETH(
    address router_,
    address token_,
    address[] memory path_,
    uint256 amountOut_
  ) internal returns (uint256 amountIn) {
    IERC20(token_).approve(router_, type(uint256).max);
    uint256[] memory amounts =
      IUniswapV2Router02(router_).swapTokensForExactTokens(
        amountOut_,
        type(uint256).max,
        path_,
        address(this),
        block.timestamp
      );
    IERC20(token_).approve(router_, 0);
    return amounts[0];
  }

  function _swapWETHToCVP() internal returns (uint256) {
    address[] memory path = new address[](2);

    path[0] = weth;
    path[1] = cvp;
    IERC20(weth).approve(uniswapRouter, type(uint256).max);
    uint256[] memory amounts =
      IUniswapV2Router02(uniswapRouter).swapTokensForExactTokens(
        cvpAmountOut,
        type(uint256).max,
        path,
        xcvp,
        block.timestamp
      );
    IERC20(weth).approve(uniswapRouter, 0);
    return amounts[0];
  }

  function _swapTokensForExactCVP(
    address router_,
    address token_,
    address[] memory path_
  ) internal returns (uint256) {
    IERC20(token_).approve(router_, type(uint256).max);
    uint256[] memory amounts =
      IUniswapV2Router02(router_).swapTokensForExactTokens(
        cvpAmountOut,
        type(uint256).max,
        path_,
        xcvp,
        block.timestamp
      );
    IERC20(token_).approve(router_, 0);
    return amounts[0];
  }

  function _executeExternalStrategy(address token_) internal returns (uint256 amountIn) {
    ExternalStrategiesConfig memory config = externalStrategiesConfig[token_];
    address executeUniLikeFrom;
    address executeContract;
    bytes memory executeData;

    if (config.maxAmountIn) {
      amountIn = IERC20(token_).balanceOf(address(this));
      uint256 strategyAmountOut = ICVPMakerStrategy(config.strategy).estimateOut(token_, amountIn, config.config);
      uint256 resultCvpOut =
        estimateUniLikeStrategyOut(ICVPMakerStrategy(config.strategy).getTokenOut(), strategyAmountOut);
      require(resultCvpOut >= cvpAmountOut, "INSUFFICIENT_CVP_AMOUNT_OUT");

      (executeUniLikeFrom, executeData, executeContract) = ICVPMakerStrategy(config.strategy).getExecuteDataByAmountIn(
        token_,
        amountIn,
        config.config
      );
    } else {
      (amountIn, executeUniLikeFrom, executeData, executeContract) = ICVPMakerStrategy(config.strategy)
        .getExecuteDataByAmountOut(
        token_,
        estimateUniLikeStrategyIn(ICVPMakerStrategy(config.strategy).getTokenOut()),
        config.config
      );
    }

    IERC20(token_).approve(executeContract, amountIn);
    (bool success, bytes memory data) = executeContract.call(executeData);
    require(success, "NOT_SUCCESS");

    if (executeUniLikeFrom != address(0)) {
      _executeUniLikeStrategy(executeUniLikeFrom);
    }
  }

  function _executeCustomStrategy(address token_, uint256 strategyId_) internal returns (uint256 amountIn) {
    if (strategyId_ == 1) {
      return _customStrategy1(token_);
    } else if (strategyId_ == 2) {
      return _customStrategy2(token_);
    } else if (strategyId_ == 3) {
      return _customStrategy3(token_);
    } else {
      revert("INVALID_STRATEGY_ID");
    }
  }

  /*** CUSTOM STRATEGIES ***/

  /**
   * @notice The Strategy 1 exits a PowerIndex pool to CVP token. The pool should have CVP token bound.
   * (For PIPT & YETI - like pools)
   * @param bPoolToken_ PowerIndex Pool Token
   * @return amountIn The amount of bPoolToken_ used as an input for the swap
   */
  function _customStrategy1(address bPoolToken_) internal returns (uint256 amountIn) {
    uint256 cvpAmountOut_ = cvpAmountOut;
    Strategy1Config memory config = strategy1Config[bPoolToken_];
    address iBPool = bPoolToken_;

    if (config.bPoolWrapper != address(0)) {
      iBPool = config.bPoolWrapper;
    }

    (, , uint256 communityExitFee, ) = BPoolInterface(bPoolToken_).getCommunityFee();
    uint256 amountOutGross = calcBPoolGrossAmount(cvpAmountOut_, communityExitFee);

    uint256 currentBalance = IERC20(bPoolToken_).balanceOf(address(this));
    IERC20(bPoolToken_).approve(iBPool, currentBalance);
    amountIn = BPoolInterface(iBPool).exitswapExternAmountOut(cvp, amountOutGross, currentBalance);
    IERC20(bPoolToken_).approve(iBPool, 0);

    IERC20(cvp).safeTransfer(xcvp, cvpAmountOut_);
  }

  /**
   * @notice The Strategy 2 exits from a PowerIndex pool token to one of it's bound tokens. Then it swaps this token
   * for CVP using a uniswap-like strategy. The pool should have CVP token bound. (For ASSY - like pools)
   * @param bPoolToken_ PowerIndex Pool Token
   * @return amountIn The amount of bPoolToken_ used as an input for the swap
   */
  function _customStrategy2(address bPoolToken_) internal returns (uint256 amountIn) {
    Strategy2Config storage config = strategy2Config[bPoolToken_];
    uint256 nextIndex = config.nextIndex;
    address underlyingOrPiToExit = config.tokens[nextIndex];
    require(underlyingOrPiToExit != address(0), "INVALID_EXIT_TOKEN");

    address underlyingToken = underlyingOrPiToExit;
    if (nextIndex + 1 >= config.tokens.length) {
      config.nextIndex = 0;
    } else {
      config.nextIndex = nextIndex + 1;
    }

    address iBPool = bPoolToken_;

    if (config.bPoolWrapper != address(0)) {
      iBPool = config.bPoolWrapper;
      address underlyingCandidate = PowerIndexWrapper(config.bPoolWrapper).underlyingByPiToken(underlyingOrPiToExit);
      if (underlyingCandidate != address(0)) {
        underlyingToken = underlyingCandidate;
      }
    }

    uint256 tokenAmountUniIn = estimateUniLikeStrategyIn(underlyingToken);
    (, , uint256 communityExitFee, ) = BPoolInterface(bPoolToken_).getCommunityFee();
    uint256 amountOutGross = calcBPoolGrossAmount(tokenAmountUniIn, communityExitFee);

    uint256 currentBalance = IERC20(bPoolToken_).balanceOf(address(this));
    IERC20(bPoolToken_).approve(iBPool, currentBalance);
    amountIn = BPoolInterface(iBPool).exitswapExternAmountOut(underlyingToken, amountOutGross, currentBalance);
    IERC20(bPoolToken_).approve(iBPool, 0);

    _executeUniLikeStrategy(underlyingToken);
  }

  /**
   * @notice The Strategy 3 swaps the given token at the corresponding PowerIndex pool for CVP
   * @param underlyingOrPiToken_ Token to swap for CVP. If it is a piToken, all the balance is swapped for it's
   * underlying first.
   * @return amountIn The amount used as an input for the swap. For a piToken it returns the amount in underlying tokens
   */
  function _customStrategy3(address underlyingOrPiToken_) internal returns (uint256 amountIn) {
    Strategy3Config memory config = strategy3Config[underlyingOrPiToken_];
    BPoolInterface bPool = BPoolInterface(config.bPool);
    BPoolInterface bPoolWrapper = config.bPoolWrapper != address(0) ? BPoolInterface(config.bPoolWrapper) : bPool;
    address tokenIn = underlyingOrPiToken_;

    if (config.underlying != address(0)) {
      tokenIn = config.underlying;
      uint256 underlyingBalance = WrappedPiErc20Interface(underlyingOrPiToken_).balanceOfUnderlying(address(this));
      if (underlyingBalance > 0) {
        WrappedPiErc20Interface(underlyingOrPiToken_).withdraw(underlyingBalance);
      }
    }

    (uint256 communitySwapFee, , , ) = bPool.getCommunityFee();
    uint256 cvpAmountOut_ = cvpAmountOut;
    uint256 amountOutGross = calcBPoolGrossAmount(cvpAmountOut_, communitySwapFee);

    uint256 currentBalance = IERC20(tokenIn).balanceOf(address(this));
    IERC20(tokenIn).approve(address(bPoolWrapper), currentBalance);
    (amountIn, ) = bPoolWrapper.swapExactAmountOut(
      // tokenIn
      tokenIn,
      // maxAmountIn
      currentBalance,
      // tokenOut
      cvp,
      // tokenAmountOut
      amountOutGross,
      // maxPrice
      type(uint64).max
    );
    IERC20(tokenIn).approve(address(bPoolWrapper), 0);
    IERC20(cvp).safeTransfer(xcvp, cvpAmountOut_);
  }

  /*** PERMISSIONLESS METHODS ***/

  /**
   * @notice Syncs the bound tokens for the Strategy2 PowerIndex pool token
   * @param token_ The pool token to sync
   */
  function syncStrategy2Tokens(address token_) external {
    require(customStrategies[token_] == 2, "CUSTOM_STRATEGY_2_FORBIDDEN");

    Strategy2Config storage config = strategy2Config[token_];
    address[] memory newTokens = BPoolInterface(token_).getCurrentTokens();
    require(newTokens.length > 0, "NEW_LENGTH_IS_0");
    config.tokens = newTokens;
    if (config.nextIndex >= newTokens.length) {
      config.nextIndex = 0;
    }
  }

  /*** OWNER METHODS ***/

  function setPoolRestrictions(address restrictions_) external onlyOwner {
    restrictions = IPoolRestrictions(restrictions_);
    emit SetPoolRestrictions(restrictions_);
  }

  function setCvpAmountOut(uint256 cvpAmountOut_) external onlyOwner {
    require(cvpAmountOut_ > 0, "CVP_AMOUNT_OUT_0");
    cvpAmountOut = cvpAmountOut_;
    emit SetCvpAmountOut(cvpAmountOut_);
  }

  function setCustomStrategy(address token_, uint256 strategyId_) public onlyOwner {
    customStrategies[token_] = strategyId_;
    emit SetCustomStrategy(token_, strategyId_);
  }

  function setCustomStrategy1Config(address bPoolToken_, address bPoolWrapper_) external onlyOwner {
    strategy1Config[bPoolToken_].bPoolWrapper = bPoolWrapper_;
    setCustomStrategy(bPoolToken_, 1);
  }

  function setCustomStrategy2Config(address bPoolToken, address bPoolWrapper_) external onlyOwner {
    strategy2Config[bPoolToken].bPoolWrapper = bPoolWrapper_;
    setCustomStrategy(bPoolToken, 2);
  }

  function setCustomStrategy3Config(
    address token_,
    address bPool_,
    address bPoolWrapper_,
    address underlying_
  ) external onlyOwner {
    strategy3Config[token_] = Strategy3Config(bPool_, bPoolWrapper_, underlying_);
    setCustomStrategy(token_, 3);
  }

  function setExternalStrategy(
    address token_,
    address strategy_,
    bool maxAmountIn_,
    bytes memory config_
  ) external onlyOwner {
    address prevStrategy = externalStrategiesConfig[token_].strategy;
    if (prevStrategy != address(0)) {
      IERC20(token_).safeApprove(prevStrategy, uint256(0));
    }

    externalStrategiesConfig[token_] = ExternalStrategiesConfig(strategy_, maxAmountIn_, config_);

    IERC20(token_).safeApprove(strategy_, type(uint256).max);

    emit SetExternalStrategy(token_, strategy_, maxAmountIn_);
  }

  function setCustomPath(
    address token_,
    address router_,
    address[] calldata customPath_
  ) external onlyOwner {
    if (router_ == uniswapRouter) {
      require(customPath_.length == 0 || customPath_[customPath_.length - 1] == cvp, "NON_CVP_END_ON_UNISWAP_PATH");
    } else {
      require(customPath_[customPath_.length - 1] == weth, "NON_WETH_END_ON_NON_UNISWAP_PATH");
    }

    routers[token_] = router_;
    customPaths[token_] = customPath_;

    emit SetCustomPath(token_, router_, customPath_);
  }
}