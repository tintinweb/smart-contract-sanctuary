/**
 *Submitted for verification at Etherscan.io on 2021-06-25
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @powerpool/poweroracle/contracts/interfaces/IPowerPoke.sol

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

// File: contracts/interfaces/PowerIndexPoolInterface.sol

pragma solidity 0.6.12;

interface PowerIndexPoolInterface is BPoolInterface {
  function initialize(
    string calldata name,
    string calldata symbol,
    uint256 minWeightPerSecond,
    uint256 maxWeightPerSecond
  ) external;

  function bind(
    address,
    uint256,
    uint256,
    uint256,
    uint256
  ) external;

  function setDynamicWeight(
    address token,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) external;

  function getDynamicWeightSettings(address token)
    external
    view
    returns (
      uint256 fromTimestamp,
      uint256 targetTimestamp,
      uint256 fromDenorm,
      uint256 targetDenorm
    );

  function getMinWeight() external view override returns (uint256);

  function getWeightPerSecondBounds() external view returns (uint256, uint256);

  function setWeightPerSecondBounds(uint256, uint256) external;

  function setWrapper(address, bool) external;

  function getWrapperMode() external view returns (bool);
}

// File: contracts/interfaces/TokenInterface.sol

pragma solidity 0.6.12;


interface TokenInterface is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// File: contracts/interfaces/ICurveDepositor.sol

pragma solidity 0.6.12;

interface ICurveDepositor {
  function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _index) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 _i,
    uint256 _min_amount
  ) external;
}

// File: contracts/interfaces/ICurveDepositor2.sol

pragma solidity 0.6.12;

interface ICurveDepositor2 {
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[2] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/ICurveDepositor3.sol

pragma solidity 0.6.12;

interface ICurveDepositor3 {
  function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[3] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/ICurveDepositor4.sol

pragma solidity 0.6.12;

interface ICurveDepositor4 {
  function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount) external;

  function calc_token_amount(uint256[4] memory _amounts, bool _deposit) external view returns (uint256);
}

// File: contracts/interfaces/ICurveZapDepositor.sol

pragma solidity 0.6.12;

interface ICurveZapDepositor {
  function calc_withdraw_one_coin(
    address _pool,
    uint256 _tokenAmount,
    int128 _index
  ) external view returns (uint256);

  function remove_liquidity_one_coin(
    address _pool,
    uint256 _token_amount,
    int128 _i,
    uint256 _min_amount
  ) external;
}

// File: contracts/interfaces/ICurveZapDepositor2.sol

pragma solidity 0.6.12;

interface ICurveZapDepositor2 {
  function add_liquidity(
    address _pool,
    uint256[2] memory _amounts,
    uint256 _min_mint_amount
  ) external;

  function calc_token_amount(
    address _pool,
    uint256[2] memory _amounts,
    bool _deposit
  ) external view returns (uint256);
}

// File: contracts/interfaces/ICurveZapDepositor3.sol

pragma solidity 0.6.12;

interface ICurveZapDepositor3 {
  function add_liquidity(
    address _pool,
    uint256[3] memory _amounts,
    uint256 _min_mint_amount
  ) external;

  function calc_token_amount(
    address _pool,
    uint256[3] memory _amounts,
    bool _deposit
  ) external view returns (uint256);
}

// File: contracts/interfaces/ICurveZapDepositor4.sol

pragma solidity 0.6.12;

interface ICurveZapDepositor4 {
  function add_liquidity(
    address _pool,
    uint256[4] memory _amounts,
    uint256 _min_mint_amount
  ) external;

  function calc_token_amount(
    address _pool,
    uint256[4] memory _amounts,
    bool _deposit
  ) external view returns (uint256);
}

// File: contracts/interfaces/IVault.sol

pragma solidity ^0.6.0;

interface IVault {
  function token() external view returns (address);

  function totalAssets() external view returns (uint256);

  function balanceOf(address _acc) external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function deposit(uint256 _amount) external;

  function withdraw(uint256 _amount) external;
}

// File: contracts/interfaces/ICurvePoolRegistry.sol

pragma solidity 0.6.12;

interface ICurvePoolRegistry {
  function get_virtual_price_from_lp_token(address _token) external view returns (uint256);
}

// File: contracts/interfaces/IErc20PiptSwap.sol

pragma solidity 0.6.12;

interface IErc20PiptSwap {
  function swapEthToPipt(
    uint256 _slippage,
    uint256 _minPoolAmount,
    uint256 _maxDiffPercent
  ) external payable returns (uint256 poolAmountOutAfterFee, uint256 oddEth);

  function swapErc20ToPipt(
    address _swapToken,
    uint256 _swapAmount,
    uint256 _slippage,
    uint256 _minPoolAmount,
    uint256 _diffPercent
  ) external payable returns (uint256 poolAmountOut);

  function defaultSlippage() external view returns (uint256);

  function defaultDiffPercent() external view returns (uint256);

  function swapPiptToEth(uint256 _poolAmountIn) external payable returns (uint256 ethOutAmount);

  function swapPiptToErc20(address _swapToken, uint256 _poolAmountIn) external payable returns (uint256 erc20Out);
}

// File: contracts/interfaces/IErc20VaultPoolSwap.sol

pragma solidity 0.6.12;

interface IErc20VaultPoolSwap {
  function swapErc20ToVaultPool(
    address _pool,
    address _swapToken,
    uint256 _swapAmount
  ) external returns (uint256 poolAmountOut);

  function swapVaultPoolToErc20(
    address _pool,
    uint256 _poolAmountIn,
    address _swapToken
  ) external returns (uint256 erc20Out);
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

// File: contracts/traits/ProgressiveFee.sol

pragma solidity 0.6.12;

contract ProgressiveFee is OwnableUpgradeSafe {
  using SafeMath for uint256;

  uint256[] public feeLevels;
  uint256[] public feeAmounts;
  address public feePayout;
  address public feeManager;

  event SetFees(
    address indexed sender,
    uint256[] newFeeLevels,
    uint256[] newFeeAmounts,
    address indexed feePayout,
    address indexed feeManager
  );

  modifier onlyFeeManagerOrOwner() {
    require(msg.sender == feeManager || msg.sender == owner(), "NOT_FEE_MANAGER");
    _;
  }

  function setFees(
    uint256[] calldata _feeLevels,
    uint256[] calldata _feeAmounts,
    address _feePayout,
    address _feeManager
  ) external onlyFeeManagerOrOwner {
    feeLevels = _feeLevels;
    feeAmounts = _feeAmounts;
    feePayout = _feePayout;
    feeManager = _feeManager;

    emit SetFees(msg.sender, _feeLevels, _feeAmounts, _feePayout, _feeManager);
  }

  function calcFee(uint256 amount, uint256 wrapperFee) public view returns (uint256 feeAmount, uint256 amountAfterFee) {
    uint256 len = feeLevels.length;
    for (uint256 i = 0; i < len; i++) {
      if (amount >= feeLevels[i]) {
        feeAmount = amount.mul(feeAmounts[i]).div(1 ether);
        break;
      }
    }
    feeAmount = feeAmount.add(wrapperFee);
    amountAfterFee = amount.sub(feeAmount);
  }

  function getFeeLevels() external view returns (uint256[] memory) {
    return feeLevels;
  }

  function getFeeAmounts() external view returns (uint256[] memory) {
    return feeAmounts;
  }
}

// File: contracts/Erc20VaultPoolSwap.sol

pragma solidity 0.6.12;

contract Erc20VaultPoolSwap is ProgressiveFee, IErc20VaultPoolSwap {
  using SafeERC20 for IERC20;

  event TakeFee(address indexed pool, address indexed token, uint256 amount);

  event SetVaultConfig(
    address indexed token,
    address depositor,
    uint8 depositorAmountLength,
    uint8 depositorIndex,
    address lpToken,
    address indexed vaultRegistry
  );

  event Erc20ToVaultPoolSwap(address indexed user, address indexed pool, uint256 usdcInAmount, uint256 poolOutAmount);
  event VaultPoolToErc20Swap(address indexed user, address indexed pool, uint256 poolInAmount, uint256 usdcOutAmount);
  event ClaimFee(address indexed token, address indexed payout, uint256 amount);

  IERC20 public immutable usdc;

  mapping(address => address[]) public poolTokens;

  struct VaultConfig {
    uint8 depositorLength;
    uint8 depositorIndex;
    uint8 depositorType;
    address depositor;
    address lpToken;
    address vaultRegistry;
  }
  mapping(address => VaultConfig) public vaultConfig;

  struct VaultCalc {
    address token;
    uint256 tokenBalance;
    uint256 input;
    uint256 correctInput;
    uint256 poolAmountOut;
  }

  constructor(address _usdc) public {
    __Ownable_init();
    usdc = IERC20(_usdc);
  }

  function setVaultConfigs(
    address[] memory _tokens,
    address[] memory _depositors,
    uint8[] memory _depositorTypes,
    uint8[] memory _depositorAmountLength,
    uint8[] memory _depositorIndexes,
    address[] memory _lpTokens,
    address[] memory _vaultRegistries
  ) external onlyOwner {
    uint256 len = _tokens.length;
    require(
      len == _depositors.length &&
        len == _depositorAmountLength.length &&
        len == _depositorIndexes.length &&
        len == _depositorTypes.length &&
        len == _lpTokens.length &&
        len == _vaultRegistries.length,
      "L"
    );
    for (uint256 i = 0; i < len; i++) {
      vaultConfig[_tokens[i]] = VaultConfig(
        _depositorAmountLength[i],
        _depositorIndexes[i],
        _depositorTypes[i],
        _depositors[i],
        _lpTokens[i],
        _vaultRegistries[i]
      );

      usdc.approve(_depositors[i], uint256(-1));
      IERC20(_lpTokens[i]).approve(_tokens[i], uint256(-1));
      IERC20(_lpTokens[i]).approve(_depositors[i], uint256(-1));
      emit SetVaultConfig(
        _tokens[i],
        _depositors[i],
        _depositorAmountLength[i],
        _depositorIndexes[i],
        _lpTokens[i],
        _vaultRegistries[i]
      );
    }
  }

  function updatePools(address[] memory _pools) external onlyOwner {
    uint256 len = _pools.length;
    for (uint256 i = 0; i < len; i++) {
      _updatePool(_pools[i]);
    }
  }

  function claimFee(address[] memory _tokens) external onlyOwner {
    require(feePayout != address(0), "FP_NOT_SET");

    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 amount = IERC20(_tokens[i]).balanceOf(address(this));
      IERC20(_tokens[i]).safeTransfer(feePayout, amount);
      emit ClaimFee(_tokens[i], feePayout, amount);
    }
  }

  function swapErc20ToVaultPool(
    address _pool,
    address _swapToken,
    uint256 _swapAmount
  ) external override returns (uint256 poolAmountOut) {
    require(_swapToken == address(usdc), "ONLY_USDC");
    usdc.safeTransferFrom(msg.sender, address(this), _swapAmount);

    (, uint256 _swapAmountWithFee) = calcFee(_swapAmount, 0);

    uint256[] memory tokensInPipt;
    (poolAmountOut, tokensInPipt) = _depositVaultAndGetTokensInPipt(_pool, _swapAmountWithFee);

    PowerIndexPoolInterface(_pool).joinPool(poolAmountOut, tokensInPipt);
    (, uint256 communityFee, , ) = PowerIndexPoolInterface(_pool).getCommunityFee();
    poolAmountOut = poolAmountOut.sub(poolAmountOut.mul(communityFee).div(1 ether)) - 1;

    IERC20(_pool).safeTransfer(msg.sender, poolAmountOut);

    emit Erc20ToVaultPoolSwap(msg.sender, _pool, _swapAmount, poolAmountOut);
  }

  function swapVaultPoolToErc20(
    address _pool,
    uint256 _poolAmountIn,
    address _swapToken
  ) external override returns (uint256 erc20Out) {
    require(_swapToken == address(usdc), "ONLY_USDC");
    IERC20(_pool).safeTransferFrom(msg.sender, address(this), _poolAmountIn);

    (, uint256 _poolAmountInWithFee) = calcFee(_poolAmountIn, 0);

    erc20Out = _redeemVault(_pool, _poolAmountInWithFee);

    usdc.safeTransfer(msg.sender, erc20Out);

    emit VaultPoolToErc20Swap(msg.sender, _pool, _poolAmountIn, erc20Out);
  }

  /* ==========  View Functions  ========== */

  function calcVaultOutByUsdc(address _token, uint256 _usdcIn) public view returns (uint256 amountOut) {
    VaultConfig storage vc = vaultConfig[_token];
    uint256 vaultByLpPrice = IVault(_token).pricePerShare();
    return calcDepositorTokenAmount(vc, _usdcIn, true).mul(1 ether).div(vaultByLpPrice);
  }

  function calcDepositorTokenAmount(
    VaultConfig storage vc,
    uint256 _amount,
    bool _isDeposit
  ) internal view returns (uint256) {
    if (vc.depositorLength == 2) {
      uint256[2] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        return ICurveZapDepositor2(vc.depositor).calc_token_amount(vc.lpToken, amounts, _isDeposit);
      } else {
        return ICurveDepositor2(vc.depositor).calc_token_amount(amounts, _isDeposit);
      }
    }

    if (vc.depositorLength == 3) {
      uint256[3] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        return ICurveZapDepositor3(vc.depositor).calc_token_amount(vc.lpToken, amounts, _isDeposit);
      } else {
        return ICurveDepositor3(vc.depositor).calc_token_amount(amounts, _isDeposit);
      }
    }

    if (vc.depositorLength == 4) {
      uint256[4] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        return ICurveZapDepositor4(vc.depositor).calc_token_amount(vc.lpToken, amounts, _isDeposit);
      } else {
        return ICurveDepositor4(vc.depositor).calc_token_amount(amounts, _isDeposit);
      }
    }
    return 0;
  }

  function calcVaultPoolOutByUsdc(
    address _pool,
    uint256 _usdcIn,
    bool _withFee
  ) external view returns (uint256 amountOut) {
    uint256 len = poolTokens[_pool].length;
    PowerIndexPoolInterface p = PowerIndexPoolInterface(_pool);
    uint256 piptTotalSupply = p.totalSupply();

    (VaultCalc[] memory vc, uint256 restInput, uint256 totalCorrectInput) =
      getVaultCalcsForSupply(_pool, piptTotalSupply, _usdcIn);

    uint256[] memory tokensInPipt = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 share = vc[i].correctInput.mul(1 ether).div(totalCorrectInput);
      vc[i].correctInput = vc[i].correctInput.add(restInput.mul(share).div(1 ether)).sub(100);

      tokensInPipt[i] = calcVaultOutByUsdc(vc[i].token, vc[i].correctInput);

      uint256 poolOutByToken = tokensInPipt[i].sub(1e12).mul(piptTotalSupply).div(vc[i].tokenBalance);
      if (poolOutByToken < amountOut || amountOut == 0) {
        amountOut = poolOutByToken;
      }
    }
    if (_withFee) {
      (, uint256 communityJoinFee, , ) = p.getCommunityFee();
      (amountOut, ) = p.calcAmountWithCommunityFee(amountOut, communityJoinFee, address(this));
    }
  }

  function calcUsdcOutByVault(address _token, uint256 _vaultIn) public view returns (uint256 amountOut) {
    VaultConfig storage vc = vaultConfig[_token];
    uint256 lpByUsdcPrice = ICurvePoolRegistry(vc.vaultRegistry).get_virtual_price_from_lp_token(vc.lpToken);
    uint256 vaultByLpPrice = IVault(_token).pricePerShare();
    return _vaultIn.mul(vaultByLpPrice.mul(lpByUsdcPrice).div(1 ether)).div(1e30);
  }

  function calcUsdcOutByPool(
    address _pool,
    uint256 _ppolIn,
    bool _withFee
  ) external view returns (uint256 amountOut) {
    uint256 len = poolTokens[_pool].length;
    PowerIndexPoolInterface p = PowerIndexPoolInterface(_pool);

    if (_withFee) {
      (, , uint256 communityExitFee, ) = p.getCommunityFee();
      (_ppolIn, ) = p.calcAmountWithCommunityFee(_ppolIn, communityExitFee, address(this));
    }

    uint256 ratio = _ppolIn.mul(1 ether).div(p.totalSupply());

    for (uint256 i = 0; i < len; i++) {
      address t = poolTokens[_pool][i];
      uint256 bal = p.getBalance(t);
      amountOut = amountOut.add(calcUsdcOutByVault(t, ratio.mul(bal).div(1 ether)));
    }
  }

  function getVaultCalcsForSupply(
    address _pool,
    uint256 piptTotalSupply,
    uint256 totalInputAmount
  )
    public
    view
    returns (
      VaultCalc[] memory vc,
      uint256 restInput,
      uint256 totalCorrectInput
    )
  {
    uint256 len = poolTokens[_pool].length;
    vc = new VaultCalc[](len);

    uint256 minPoolAmount;
    for (uint256 i = 0; i < len; i++) {
      vc[i].token = poolTokens[_pool][i];
      vc[i].tokenBalance = PowerIndexPoolInterface(_pool).getBalance(vc[i].token);
      vc[i].input = totalInputAmount / len;
      vc[i].poolAmountOut = calcVaultOutByUsdc(vc[i].token, vc[i].input).mul(piptTotalSupply).div(vc[i].tokenBalance);
      if (minPoolAmount == 0 || vc[i].poolAmountOut < minPoolAmount) {
        minPoolAmount = vc[i].poolAmountOut;
      }
    }

    for (uint256 i = 0; i < len; i++) {
      if (vc[i].poolAmountOut > minPoolAmount) {
        uint256 ratio = minPoolAmount.mul(1 ether).div(vc[i].poolAmountOut);
        vc[i].correctInput = ratio.mul(vc[i].input).div(1 ether);
        restInput = restInput.add(vc[i].input.sub(vc[i].correctInput));
      } else {
        vc[i].correctInput = vc[i].input;
      }
    }

    totalCorrectInput = totalInputAmount.sub(restInput).sub(100);
  }

  /* ==========  Internal Functions  ========== */

  function _depositVaultAndGetTokensInPipt(address _pool, uint256 _totalInputAmount)
    internal
    returns (uint256 poolAmountOut, uint256[] memory tokensInPipt)
  {
    require(_totalInputAmount != 0, "NULL_INPUT");
    uint256 len = poolTokens[_pool].length;
    uint256 piptTotalSupply = PowerIndexPoolInterface(_pool).totalSupply();

    (VaultCalc[] memory vc, uint256 restInput, uint256 totalCorrectInput) =
      getVaultCalcsForSupply(_pool, piptTotalSupply, _totalInputAmount);

    tokensInPipt = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 share = vc[i].correctInput.mul(1 ether).div(totalCorrectInput);
      vc[i].correctInput = vc[i].correctInput.add(restInput.mul(share).div(1 ether)).sub(100);

      uint256 balanceBefore = IVault(vc[i].token).balanceOf(address(this));
      IVault(vc[i].token).deposit(_addYearnLpTokenLiquidity(vaultConfig[vc[i].token], vc[i].correctInput));
      tokensInPipt[i] = IVault(vc[i].token).balanceOf(address(this)).sub(balanceBefore);

      uint256 poolOutByToken = tokensInPipt[i].sub(1e12).mul(piptTotalSupply).div(vc[i].tokenBalance);
      if (poolOutByToken < poolAmountOut || poolAmountOut == 0) {
        poolAmountOut = poolOutByToken;
      }
    }
    require(poolAmountOut != 0, "NULL_OUTPUT");
  }

  function _addYearnLpTokenLiquidity(VaultConfig storage vc, uint256 _amount) internal returns (uint256) {
    uint256 balanceBefore = IERC20(vc.lpToken).balanceOf(address(this));
    if (vc.depositorLength == 2) {
      uint256[2] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        ICurveZapDepositor2(vc.depositor).add_liquidity(vc.lpToken, amounts, 1);
      } else {
        ICurveDepositor2(vc.depositor).add_liquidity(amounts, 1);
      }
    }

    if (vc.depositorLength == 3) {
      uint256[3] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        ICurveZapDepositor3(vc.depositor).add_liquidity(vc.lpToken, amounts, 1);
      } else {
        ICurveDepositor3(vc.depositor).add_liquidity(amounts, 1);
      }
    }

    if (vc.depositorLength == 4) {
      uint256[4] memory amounts;
      amounts[vc.depositorIndex] = _amount;
      if (vc.depositorType == 2) {
        ICurveZapDepositor4(vc.depositor).add_liquidity(vc.lpToken, amounts, 1);
      } else {
        ICurveDepositor4(vc.depositor).add_liquidity(amounts, 1);
      }
    }
    uint256 balanceAfter = IERC20(vc.lpToken).balanceOf(address(this));
    return balanceAfter.sub(balanceBefore);
  }

  function _redeemVault(address _pool, uint256 _totalInputAmount) internal returns (uint256 totalOutputAmount) {
    require(_totalInputAmount != 0, "NULL_INPUT");
    address[] memory tokens = poolTokens[_pool];
    uint256 len = tokens.length;

    uint256[] memory amounts = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      amounts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }
    PowerIndexPoolInterface(_pool).exitPool(_totalInputAmount, amounts);
    for (uint256 i = 0; i < len; i++) {
      amounts[i] = IERC20(tokens[i]).balanceOf(address(this)).sub(amounts[i]);
    }

    uint256 outputTokenBalanceBefore = usdc.balanceOf(address(this));
    for (uint256 i = 0; i < len; i++) {
      VaultConfig storage vc = vaultConfig[tokens[i]];
      uint256 lpTokenBalanceBefore = IERC20(vc.lpToken).balanceOf(address(this));
      IVault(tokens[i]).withdraw(amounts[i]);
      uint256 lpTokenAmount = IERC20(vc.lpToken).balanceOf(address(this)).sub(lpTokenBalanceBefore);
      if (vc.depositorType == 2) {
        ICurveZapDepositor(vc.depositor).remove_liquidity_one_coin(vc.lpToken, lpTokenAmount, int8(vc.depositorIndex), 1);
      } else {
        ICurveDepositor(vc.depositor).remove_liquidity_one_coin(lpTokenAmount, int8(vc.depositorIndex), 1);
      }
    }
    totalOutputAmount = usdc.balanceOf(address(this)).sub(outputTokenBalanceBefore);
    require(totalOutputAmount != 0, "NULL_OUTPUT");
  }

  function _updatePool(address _pool) internal {
    poolTokens[_pool] = PowerIndexPoolInterface(_pool).getCurrentTokens();
    uint256 len = poolTokens[_pool].length;
    for (uint256 i = 0; i < len; i++) {
      IERC20(poolTokens[_pool][i]).approve(_pool, uint256(-1));
    }
  }
}