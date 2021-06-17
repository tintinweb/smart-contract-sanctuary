/**
 *Submitted for verification at Etherscan.io on 2021-06-16
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

// SPDX-License-Identifier: GPL-3.0

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

// File: contracts/interfaces/IYearnVaultV2.sol

pragma solidity ^0.6.0;

interface IYearnVaultV2 {
  function token() external view returns (address);

  function totalAssets() external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address recipient) external;

  function withdraw(uint256 maxShares) external;

  function withdraw(uint256 maxShares, address recipient) external;

  function withdraw(
    uint256 maxShares,
    address recipient,
    uint256 maxLoss
  ) external;

  function report(
    uint256 gain,
    uint256 loss,
    uint256 debtPayment
  ) external returns (uint256);
}

// File: contracts/interfaces/PowerIndexPoolControllerInterface.sol

pragma solidity 0.6.12;

interface PowerIndexPoolControllerInterface {
  function rebindByStrategyAdd(
    address token,
    uint256 balance,
    uint256 denorm,
    uint256 deposit
  ) external;

  function rebindByStrategyRemove(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function bindByStrategy(
    address token,
    uint256 balance,
    uint256 denorm
  ) external;

  function unbindByStrategy(address token) external;
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

// File: contracts/interfaces/ICurvePoolRegistry.sol

pragma solidity 0.6.12;

interface ICurvePoolRegistry {
  function get_virtual_price_from_lp_token(address _token) external view returns (uint256);
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

// File: contracts/weight-strategies/blocks/SinglePoolManagement.sol

pragma solidity 0.6.12;

abstract contract SinglePoolManagement is OwnableUpgradeSafe {
  address public immutable pool;
  address public poolController;

  constructor(address _pool) public {
    pool = _pool;
  }

  function __SinglePoolManagement_init(address _poolController) internal {
    poolController = _poolController;
  }
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
    uint public constant MAX_BOUND_TOKENS  = 21;
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

  function isSwapsDisabled() external view returns (bool);

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

  function setSwapsDisabled(bool) external;

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

// File: contracts/interfaces/IPowerOracle.sol

pragma solidity 0.6.12;

interface IPowerOracle {
  function assetPrices(address _token) external view returns (uint256);
}

// File: contracts/weight-strategies/WeightValueAbstract.sol

pragma solidity 0.6.12;

abstract contract WeightValueAbstract is BNum, OwnableUpgradeSafe {
  event UpdatePoolWeights(
    address indexed pool,
    uint256 indexed timestamp,
    address[] tokens,
    uint256[3][] weightsChange,
    uint256[] newTokenValues
  );

  event SetTotalWeight(uint256 totalWeight);

  struct TokenConfigItem {
    address token;
    address[] excludeTokenBalances;
  }

  IPowerOracle public oracle;
  uint256 public totalWeight;

  function getTokenValue(PowerIndexPoolInterface _pool, address _token) public view virtual returns (uint256) {
    return getTVL(_pool, _token);
  }

  function getTVL(PowerIndexPoolInterface _pool, address _token) public view returns (uint256) {
    uint256 balance = _pool.getBalance(_token);
    return bdiv(bmul(balance, oracle.assetPrices(_token)), 1 ether);
  }

  function setTotalWeight(uint256 _totalWeight) external onlyOwner {
    totalWeight = _totalWeight;
    emit SetTotalWeight(_totalWeight);
  }

  function _computeWeightsChangeWithEvent(
    PowerIndexPoolInterface _pool,
    address[] memory _tokens,
    address[] memory _piTokens,
    uint256 _minWPS,
    uint256 fromTimestamp,
    uint256 toTimestamp
  )
    internal
    returns (
      uint256[3][] memory weightsChange,
      uint256 lenToPush,
      uint256[] memory newTokensValues
    )
  {
    (weightsChange, lenToPush, newTokensValues, ) = computeWeightsChange(
      _pool,
      _tokens,
      _piTokens,
      _minWPS,
      fromTimestamp,
      toTimestamp
    );
    emit UpdatePoolWeights(address(_pool), block.timestamp, _tokens, weightsChange, newTokensValues);
  }

  function computeWeightsChange(
    PowerIndexPoolInterface _pool,
    address[] memory _tokens,
    address[] memory _piTokens,
    uint256 _minWPS,
    uint256 fromTimestamp,
    uint256 toTimestamp
  )
    public
    view
    returns (
      uint256[3][] memory weightsChange,
      uint256 lenToPush,
      uint256[] memory newTokenValues,
      uint256 newTokenValueSum
    )
  {
    uint256 len = _tokens.length;
    newTokenValues = new uint256[](len);

    for (uint256 i = 0; i < len; i++) {
      uint256 value = getTokenValue(_pool, _tokens[i]);
      newTokenValues[i] = value;
      newTokenValueSum = badd(newTokenValueSum, value);
    }

    weightsChange = new uint256[3][](len);
    for (uint256 i = 0; i < len; i++) {
      uint256 oldWeight;
      if (_piTokens.length == _tokens.length) {
        try _pool.getDenormalizedWeight(_piTokens[i]) returns (uint256 _weight) {
          oldWeight = _weight;
        } catch {
          oldWeight = 0;
        }
      } else {
        try _pool.getDenormalizedWeight(_tokens[i]) returns (uint256 _weight) {
          oldWeight = _weight;
        } catch {
          oldWeight = 0;
        }
      }
      uint256 newWeight = bmul(bdiv(newTokenValues[i], newTokenValueSum), totalWeight);
      weightsChange[i] = [i, oldWeight, newWeight];
    }

    for (uint256 i = 0; i < len; i++) {
      uint256 wps = getWeightPerSecond(weightsChange[i][1], weightsChange[i][2], fromTimestamp, toTimestamp);
      if (wps >= _minWPS) {
        lenToPush++;
      }
    }

    if (lenToPush > 1) {
      _sort(weightsChange);
    }
  }

  function getWeightPerSecond(
    uint256 fromDenorm,
    uint256 targetDenorm,
    uint256 fromTimestamp,
    uint256 targetTimestamp
  ) public pure returns (uint256) {
    uint256 delta = targetDenorm > fromDenorm ? bsub(targetDenorm, fromDenorm) : bsub(fromDenorm, targetDenorm);
    return div(delta, bsub(targetTimestamp, fromTimestamp));
  }

  function _quickSort(
    uint256[3][] memory wightsChange,
    int256 left,
    int256 right
  ) internal pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256[3] memory pivot = wightsChange[uint256(left + (right - left) / 2)];
    int256 pDiff = int256(pivot[2]) - int256(pivot[1]);
    while (i <= j) {
      while (int256(wightsChange[uint256(i)][2]) - int256(wightsChange[uint256(i)][1]) < pDiff) i++;
      while (pDiff < int256(wightsChange[uint256(j)][2]) - int256(wightsChange[uint256(j)][1])) j--;
      if (i <= j) {
        (wightsChange[uint256(i)], wightsChange[uint256(j)]) = (wightsChange[uint256(j)], wightsChange[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) _quickSort(wightsChange, left, j);
    if (i < right) _quickSort(wightsChange, i, right);
  }

  function _sort(uint256[3][] memory weightsChange) internal pure {
    _quickSort(weightsChange, int256(0), int256(weightsChange.length - 1));
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }
}

// File: contracts/weight-strategies/WeightValueChangeRateAbstract.sol

pragma solidity 0.6.12;

abstract contract WeightValueChangeRateAbstract is WeightValueAbstract {
  mapping(address => uint256) public lastValue;
  mapping(address => uint256) public valueChangeRate;

  bool public rateChangeDisabled;

  event UpdatePoolTokenValue(
    address indexed token,
    uint256 oldTokenValue,
    uint256 newTokenValue,
    uint256 lastChangeRate,
    uint256 newChangeRate
  );
  event SetValueChangeRate(address indexed token, uint256 oldRate, uint256 newRate);
  event SetRateChangeDisabled(bool rateChangeDisabled);

  constructor() public WeightValueAbstract() {}

  function _updatePoolByPoke(
    address _pool,
    address[] memory _tokens,
    uint256[] memory _newTokenValues
  ) internal {
    uint256 len = _tokens.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 oldValue = lastValue[_tokens[i]];
      lastValue[_tokens[i]] = _newTokenValues[i];

      uint256 lastChangeRate;
      (lastChangeRate, valueChangeRate[_tokens[i]]) = getValueChangeRate(_tokens[i], oldValue, _newTokenValues[i]);

      emit UpdatePoolTokenValue(_tokens[i], oldValue, _newTokenValues[i], lastChangeRate, valueChangeRate[_tokens[i]]);
    }
  }

  function getValueChangeRate(
    address _token,
    uint256 oldTokenValue,
    uint256 newTokenValue
  ) public view returns (uint256 lastChangeRate, uint256 newChangeRate) {
    lastChangeRate = valueChangeRate[_token] == 0 ? 1 ether : valueChangeRate[_token];
    if (oldTokenValue == 0) {
      newChangeRate = lastChangeRate;
      return (lastChangeRate, newChangeRate);
    }
    newChangeRate = rateChangeDisabled ? lastChangeRate : bmul(bdiv(newTokenValue, oldTokenValue), lastChangeRate);
  }

  function getTokenValue(PowerIndexPoolInterface _pool, address _token)
    public
    view
    virtual
    override
    returns (uint256 value)
  {
    value = getTVL(_pool, _token);
    if (valueChangeRate[_token] != 0) {
      value = bmul(value, valueChangeRate[_token]);
    }
  }

  function setValueChangeRates(address[] memory _tokens, uint256[] memory _newTokenRates) public onlyOwner {
    uint256 len = _tokens.length;
    require(len == _newTokenRates.length, "LENGTHS_MISMATCH");
    for (uint256 i = 0; i < len; i++) {
      emit SetValueChangeRate(_tokens[i], valueChangeRate[_tokens[i]], _newTokenRates[i]);

      valueChangeRate[_tokens[i]] = _newTokenRates[i];
    }
  }

  function setRateUpdateDisabled(bool _disabled) public onlyOwner {
    rateChangeDisabled = _disabled;
    emit SetRateChangeDisabled(rateChangeDisabled);
  }
}

// File: contracts/weight-strategies/YearnVaultInstantRebindStrategy.sol

pragma solidity 0.6.12;

contract YearnVaultInstantRebindStrategy is SinglePoolManagement, WeightValueChangeRateAbstract {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 internal constant COMPENSATION_PLAN_1_ID = 1;

  event ChangePoolTokens(address[] poolTokensBefore, address[] poolTokensAfter);
  event InstantRebind(uint256 poolCurrentTokensCount, uint256 usdcPulled, uint256 usdcRemainder);
  event UpdatePool(address[] poolTokensBefore, address[] poolTokensAfter);
  event VaultWithdrawFee(address indexed vaultToken, uint256 crvAmount);
  event SeizeERC20(address indexed token, address indexed to, uint256 amount);
  event SetMaxWithdrawalLoss(uint256 maxWithdrawalLoss);

  event PullLiquidity(
    address indexed vaultToken,
    address crvToken,
    uint256 vaultAmount,
    uint256 crvAmountExpected,
    uint256 crvAmountActual,
    uint256 usdcAmount,
    uint256 vaultReserve
  );

  event PushLiquidity(
    address indexed vaultToken,
    address crvToken,
    uint256 vaultAmount,
    uint256 crvAmount,
    uint256 usdcAmount
  );

  event SetPoolController(address indexed poolController);

  event SetCurvePoolRegistry(address curvePoolRegistry);

  event SetVaultConfig(
    address indexed vault,
    address indexed depositor,
    uint8 depositorType,
    uint8 depositorTokenLength,
    int8 usdcIndex
  );

  event SetStrategyConstraints(uint256 minUSDCRemainder, bool useVirtualPriceEstimation);

  struct RebindConfig {
    address token;
    uint256 newWeight;
    uint256 oldBalance;
    uint256 newBalance;
  }

  struct VaultConfig {
    address depositor;
    uint8 depositorType;
    uint8 depositorTokenLength;
    int8 usdcIndex;
  }

  struct StrategyConstraints {
    uint256 minUSDCRemainder;
    bool useVirtualPriceEstimation;
  }

  struct PullDataHelper {
    address crvToken;
    uint256 yDiff;
    uint256 ycrvBalance;
    uint256 crvExpected;
    uint256 crvActual;
    uint256 usdcBefore;
    uint256 vaultReserve;
  }

  IERC20 public immutable USDC;

  IPowerPoke public powerPoke;
  ICurvePoolRegistry public curvePoolRegistry;
  uint256 public lastUpdate;
  uint256 public maxWithdrawalLoss;

  StrategyConstraints public constraints;

  address[] internal poolTokens;
  mapping(address => VaultConfig) public vaultConfig;

  modifier onlyEOA() {
    require(msg.sender == tx.origin, "ONLY_EOA");
    _;
  }

  modifier onlyReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  modifier onlyNonReporter(uint256 _reporterId, bytes calldata _rewardOpts) {
    uint256 gasStart = gasleft();
    powerPoke.authorizeNonReporter(_reporterId, msg.sender);
    _;
    _reward(_reporterId, gasStart, COMPENSATION_PLAN_1_ID, _rewardOpts);
  }

  constructor(address _pool, address _usdc) public SinglePoolManagement(_pool) OwnableUpgradeSafe() {
    USDC = IERC20(_usdc);
  }

  function initialize(
    address _powerPoke,
    address _curvePoolRegistry,
    address _poolController,
    uint256 _maxWithdrawalLoss,
    StrategyConstraints memory _constraints
  ) external initializer {
    __Ownable_init();

    __SinglePoolManagement_init(_poolController);

    maxWithdrawalLoss = _maxWithdrawalLoss;
    powerPoke = IPowerPoke(_powerPoke);
    curvePoolRegistry = ICurvePoolRegistry(_curvePoolRegistry);
    constraints = _constraints;
    totalWeight = 25 * BONE;
  }

  /*** GETTERS ***/
  function getTokenValue(PowerIndexPoolInterface, address _token) public view override returns (uint256 value) {
    value = getVaultVirtualPriceEstimation(_token, IYearnVaultV2(_token).totalAssets());
    (, uint256 newValueChangeRate) = getValueChangeRate(_token, lastValue[_token], value);
    if (newValueChangeRate != 0) {
      value = bmul(value, newValueChangeRate);
    }
  }

  function getVaultVirtualPriceEstimation(address _token, uint256 _amount) public view returns (uint256) {
    return
      ICurvePoolRegistry(curvePoolRegistry).get_virtual_price_from_lp_token(IYearnVaultV2(_token).token()).mul(
        _amount
      ) / 1e18;
  }

  function getVaultUsdcEstimation(
    address _token,
    address _crvToken,
    uint256 _amount
  ) public returns (uint256) {
    VaultConfig memory vc = vaultConfig[_token];
    if (vc.depositorType == 2) {
      return ICurveZapDepositor(vc.depositor).calc_withdraw_one_coin(_crvToken, _amount, int128(vc.usdcIndex));
    } else {
      return ICurveDepositor(vc.depositor).calc_withdraw_one_coin(_amount, int128(vc.usdcIndex));
    }
  }

  function getPoolTokens() public view returns (address[] memory) {
    return poolTokens;
  }

  /*** OWNER'S SETTERS ***/
  function setCurvePoolRegistry(address _curvePoolRegistry) external onlyOwner {
    curvePoolRegistry = ICurvePoolRegistry(_curvePoolRegistry);
    emit SetCurvePoolRegistry(_curvePoolRegistry);
  }

  function setVaultConfig(
    address _vault,
    address _depositor,
    uint8 _depositorType,
    uint8 _depositorTokenLength,
    int8 _usdcIndex
  ) external onlyOwner {
    vaultConfig[_vault] = VaultConfig(_depositor, _depositorType, _depositorTokenLength, _usdcIndex);
    IERC20 crvToken = IERC20(IYearnVaultV2(_vault).token());
    _checkApprove(USDC.approve(_depositor, uint256(-1)));
    _checkApprove(crvToken.approve(_vault, uint256(-1)));
    _checkApprove(crvToken.approve(_depositor, uint256(-1)));
    emit SetVaultConfig(_vault, _depositor, _depositorType, _depositorTokenLength, _usdcIndex);
  }

  function setPoolController(address _poolController) public onlyOwner {
    poolController = _poolController;
    _updatePool(poolController, _poolController);
    emit SetPoolController(_poolController);
  }

  function syncPoolTokens() external onlyOwner {
    address controller = poolController;
    _updatePool(controller, controller);
  }

  function setMaxWithdrawalLoss(uint256 _maxWithdrawalLoss) external onlyOwner {
    maxWithdrawalLoss = _maxWithdrawalLoss;
    emit SetMaxWithdrawalLoss(_maxWithdrawalLoss);
  }

  function removeApprovals(IERC20[] calldata _tokens, address[] calldata _tos) external onlyOwner {
    uint256 len = _tokens.length;

    for (uint256 i = 0; i < len; i++) {
      _checkApprove(_tokens[i].approve(_tos[i], uint256(0)));
    }
  }

  function seizeERC20(
    address[] calldata _tokens,
    address[] calldata _tos,
    uint256[] calldata _amounts
  ) external onlyOwner {
    uint256 len = _tokens.length;
    require(len == _tos.length && len == _amounts.length, "LENGTHS");

    for (uint256 i = 0; i < len; i++) {
      IERC20(_tokens[i]).safeTransfer(_tos[i], _amounts[i]);
      emit SeizeERC20(_tokens[i], _tos[i], _amounts[i]);
    }
  }

  function setStrategyConstraints(StrategyConstraints memory _constraints) external onlyOwner {
    constraints = _constraints;
    emit SetStrategyConstraints(_constraints.minUSDCRemainder, _constraints.useVirtualPriceEstimation);
  }

  function _checkApprove(bool _result) internal {
    require(_result, "APPROVE_FAILED");
  }

  function _updatePool(address _oldController, address _newController) internal {
    address[] memory poolTokensBefore = poolTokens;
    uint256 len = poolTokensBefore.length;

    if (_oldController != address(0)) {
      // remove approval
      for (uint256 i = 0; i < len; i++) {
        _removeApprovalVault(poolTokensBefore[i], address(_oldController));
      }
    }

    address[] memory poolTokensAfter = PowerIndexPoolInterface(pool).getCurrentTokens();
    poolTokens = poolTokensAfter;

    // approve
    len = poolTokensAfter.length;
    for (uint256 i = 0; i < len; i++) {
      _approveVault(poolTokensAfter[i], address(_newController));
    }

    emit UpdatePool(poolTokensBefore, poolTokensAfter);
  }

  function _approveVault(address _vaultToken, address _controller) internal {
    IERC20 vaultToken = IERC20(_vaultToken);
    _checkApprove(vaultToken.approve(pool, uint256(-1)));
    _checkApprove(vaultToken.approve(_controller, uint256(-1)));
  }

  function _removeApprovalVault(address _vaultToken, address _controller) internal {
    IERC20 vaultToken = IERC20(_vaultToken);
    _checkApprove(vaultToken.approve(pool, uint256(0)));
    _checkApprove(vaultToken.approve(_controller, uint256(0)));
  }

  function changePoolTokens(address[] memory _newTokens) external onlyOwner {
    address[] memory _currentTokens = BPoolInterface(pool).getCurrentTokens();
    uint256 cLen = _currentTokens.length;
    uint256 nLen = _newTokens.length;
    for (uint256 i = 0; i < cLen; i++) {
      bool existsInNewTokens = false;
      for (uint256 j = 0; j < nLen; j++) {
        if (_currentTokens[i] == _newTokens[j]) {
          existsInNewTokens = true;
        }
      }
      if (!existsInNewTokens) {
        PowerIndexPoolControllerInterface(poolController).unbindByStrategy(_currentTokens[i]);
        _vaultToUsdc(_currentTokens[i], IYearnVaultV2(_currentTokens[i]).token(), vaultConfig[_currentTokens[i]]);
        _removeApprovalVault(_currentTokens[i], address(poolController));
      }
    }

    for (uint256 j = 0; j < nLen; j++) {
      if (!BPoolInterface(pool).isBound(_newTokens[j])) {
        _approveVault(_newTokens[j], address(poolController));
      }
    }

    _instantRebind(_newTokens, true);

    emit ChangePoolTokens(_currentTokens, _newTokens);
  }

  /*** POKERS ***/
  function pokeFromReporter(uint256 _reporterId, bytes calldata _rewardOpts)
    external
    onlyReporter(_reporterId, _rewardOpts)
    onlyEOA
  {
    _poke(false);
  }

  function pokeFromSlasher(uint256 _reporterId, bytes calldata _rewardOpts)
    external
    onlyNonReporter(_reporterId, _rewardOpts)
    onlyEOA
  {
    _poke(true);
  }

  function _poke(bool _bySlasher) internal {
    (uint256 minInterval, uint256 maxInterval) = _getMinMaxReportInterval();
    require(lastUpdate + minInterval < block.timestamp, "MIN_INTERVAL_NOT_REACHED");
    if (_bySlasher) {
      require(lastUpdate + maxInterval < block.timestamp, "MAX_INTERVAL_NOT_REACHED");
    }
    lastUpdate = block.timestamp;

    _instantRebind(BPoolInterface(pool).getCurrentTokens(), false);
  }

  function _vaultToUsdc(
    address _token,
    address _crvToken,
    VaultConfig memory _vc
  )
    internal
    returns (
      uint256 crvBalance,
      uint256 crvReceived,
      uint256 usdcBefore
    )
  {
    crvBalance = IERC20(_token).balanceOf(address(this));
    uint256 crvBefore = IERC20(_crvToken).balanceOf(address(this));

    IYearnVaultV2(_token).withdraw(crvBalance, address(this), maxWithdrawalLoss);
    crvReceived = IERC20(_crvToken).balanceOf(address(this)).sub(crvBefore);

    usdcBefore = USDC.balanceOf(address(this));
    if (_vc.depositorType == 2) {
      ICurveZapDepositor(_vc.depositor).remove_liquidity_one_coin(_crvToken, crvReceived, _vc.usdcIndex, 0);
    } else {
      ICurveDepositor(_vc.depositor).remove_liquidity_one_coin(crvReceived, _vc.usdcIndex, 0);
    }
  }

  function _usdcToVault(
    address _token,
    VaultConfig memory _vc,
    uint256 _usdcAmount
  )
    internal
    returns (
      uint256 crvBalance,
      uint256 vaultBalance,
      address crvToken
    )
  {
    crvToken = IYearnVaultV2(_token).token();

    _addUSDC2CurvePool(crvToken, _vc, _usdcAmount);

    // 2nd step. Vault.deposit()
    crvBalance = IERC20(crvToken).balanceOf(address(this));
    IYearnVaultV2(_token).deposit(crvBalance);

    // 3rd step. Rebind
    vaultBalance = IERC20(_token).balanceOf(address(this));
  }

  function _instantRebind(address[] memory _tokens, bool _allowNotBound) internal {
    address poolController_ = poolController;
    require(poolController_ != address(0), "CFG_NOT_SET");

    RebindConfig[] memory configs = fetchRebindConfigs(PowerIndexPoolInterface(pool), _tokens, _allowNotBound);

    uint256 toPushUSDCTotal;
    uint256 len = configs.length;
    uint256[] memory toPushUSDC = new uint256[](len);
    VaultConfig[] memory vaultConfigs = new VaultConfig[](len);

    for (uint256 si = 0; si < len; si++) {
      RebindConfig memory cfg = configs[si];
      VaultConfig memory vc = vaultConfig[cfg.token];
      vaultConfigs[si] = vc;
      require(vc.depositor != address(0), "DEPOSIT_CONTRACT_NOT_SET");

      if (cfg.newBalance <= cfg.oldBalance) {
        PullDataHelper memory mem;
        mem.crvToken = IYearnVaultV2(cfg.token).token();
        mem.vaultReserve = IERC20(mem.crvToken).balanceOf(cfg.token);

        mem.yDiff = (cfg.oldBalance - cfg.newBalance);

        // 1st step. Rebind
        PowerIndexPoolControllerInterface(poolController_).rebindByStrategyRemove(
          cfg.token,
          cfg.newBalance,
          cfg.newWeight
        );

        // 3rd step. CurvePool.remove_liquidity_one_coin()
        (mem.ycrvBalance, mem.crvActual, mem.usdcBefore) = _vaultToUsdc(cfg.token, mem.crvToken, vc);

        // 2nd step. Vault.withdraw()
        mem.crvExpected = (mem.ycrvBalance * IYearnVaultV2(cfg.token).pricePerShare()) / 1e18;

        emit PullLiquidity(
          cfg.token,
          mem.crvToken,
          mem.yDiff,
          mem.crvExpected,
          mem.crvActual,
          USDC.balanceOf(address(this)) - mem.usdcBefore,
          mem.vaultReserve
        );
      } else {
        uint256 yDiff = cfg.newBalance - cfg.oldBalance;
        uint256 crvAmount = IYearnVaultV2(cfg.token).pricePerShare().mul(yDiff) / 1e18;
        uint256 usdcIn;

        address crvToken = IYearnVaultV2(cfg.token).token();
        if (constraints.useVirtualPriceEstimation) {
          uint256 virtualPrice = ICurvePoolRegistry(curvePoolRegistry).get_virtual_price_from_lp_token(crvToken);
          // usdcIn = virtualPrice * crvAmount / 1e18
          usdcIn = bmul(virtualPrice, crvAmount);
        } else {
          usdcIn = getVaultUsdcEstimation(cfg.token, crvToken, crvAmount);
        }

        // toPushUSDCTotal += usdcIn;
        toPushUSDCTotal = toPushUSDCTotal.add(usdcIn);
        toPushUSDC[si] = usdcIn;
      }
    }

    uint256 usdcPulled = USDC.balanceOf(address(this));
    require(usdcPulled > 0, "USDC_PULLED_NULL");

    for (uint256 si = 0; si < len; si++) {
      if (toPushUSDC[si] > 0) {
        RebindConfig memory cfg = configs[si];

        // 1st step. Add USDC to Curve pool
        // uint256 usdcAmount = (usdcPulled * toPushUSDC[si]) / toPushUSDCTotal;
        uint256 usdcAmount = (usdcPulled.mul(toPushUSDC[si])) / toPushUSDCTotal;

        (uint256 crvBalance, uint256 vaultBalance, address crvToken) =
          _usdcToVault(cfg.token, vaultConfigs[si], usdcAmount);

        // uint256 newBalance = IERC20(cfg.token).balanceOf(address(this)) + BPoolInterface(_pool).getBalance(cfg.token)
        uint256 newBalance;
        try BPoolInterface(pool).getBalance(cfg.token) returns (uint256 _poolBalance) {
          newBalance = IERC20(cfg.token).balanceOf(address(this)).add(_poolBalance);
        } catch {
          newBalance = IERC20(cfg.token).balanceOf(address(this));
        }
        if (cfg.oldBalance == 0) {
          require(_allowNotBound, "BIND_NOT_ALLOW");
          PowerIndexPoolControllerInterface(poolController_).bindByStrategy(cfg.token, newBalance, cfg.newWeight);
        } else {
          PowerIndexPoolControllerInterface(poolController_).rebindByStrategyAdd(
            cfg.token,
            newBalance,
            cfg.newWeight,
            vaultBalance
          );
        }
        emit PushLiquidity(cfg.token, crvToken, vaultBalance, crvBalance, usdcAmount);
      }
    }

    uint256 usdcRemainder = USDC.balanceOf(address(this));
    require(usdcRemainder <= constraints.minUSDCRemainder, "USDC_REMAINDER");

    emit InstantRebind(len, usdcPulled, usdcRemainder);
  }

  function fetchRebindConfigs(
    PowerIndexPoolInterface _pool,
    address[] memory _tokens,
    bool _allowNotBound
  ) internal returns (RebindConfig[] memory configs) {
    uint256 len = _tokens.length;
    (uint256[] memory oldBalances, uint256[] memory poolUSDCBalances, uint256 totalUSDCPool) =
      getRebindConfigBalances(_pool, _tokens);

    (uint256[3][] memory weightsChange, , uint256[] memory newTokenValuesUSDC, uint256 totalValueUSDC) =
      computeWeightsChange(_pool, _tokens, new address[](0), 0, block.timestamp, block.timestamp + 1);

    configs = new RebindConfig[](len);

    for (uint256 si = 0; si < len; si++) {
      uint256[3] memory wc = weightsChange[si];
      require(wc[1] != 0 || _allowNotBound, "TOKEN_NOT_BOUND");

      configs[si] = RebindConfig(
        _tokens[wc[0]],
        // (totalWeight * newTokenValuesUSDC[oi]) / totalValueUSDC,
        wc[2],
        oldBalances[wc[0]],
        // (totalUSDCPool * weight / totalWeight) / (poolUSDCBalances / totalSupply))
        getNewTokenBalance(_tokens, wc, poolUSDCBalances, newTokenValuesUSDC, totalUSDCPool, totalValueUSDC)
      );
    }

    _updatePoolByPoke(pool, _tokens, newTokenValuesUSDC);
  }

  function getNewTokenBalance(
    address[] memory _tokens,
    uint256[3] memory wc,
    uint256[] memory poolUSDCBalances,
    uint256[] memory newTokenValuesUSDC,
    uint256 totalUSDCPool,
    uint256 totalValueUSDC
  ) internal view returns (uint256) {
    return
      bdiv(
        bdiv(bmul(wc[2], totalUSDCPool), totalWeight),
        bdiv(poolUSDCBalances[wc[0]], IERC20(_tokens[wc[0]]).totalSupply())
      ) * 1e12;
  }

  function getRebindConfigBalances(PowerIndexPoolInterface _pool, address[] memory _tokens)
    internal
    returns (
      uint256[] memory oldBalances,
      uint256[] memory poolUSDCBalances,
      uint256 totalUSDCPool
    )
  {
    uint256 len = _tokens.length;
    oldBalances = new uint256[](len);
    poolUSDCBalances = new uint256[](len);
    totalUSDCPool = USDC.balanceOf(address(this));

    for (uint256 oi = 0; oi < len; oi++) {
      try PowerIndexPoolInterface(address(_pool)).getBalance(_tokens[oi]) returns (uint256 _balance) {
        oldBalances[oi] = _balance;
        totalUSDCPool = totalUSDCPool.add(
          getVaultUsdcEstimation(_tokens[oi], IYearnVaultV2(_tokens[oi]).token(), oldBalances[oi])
        );
      } catch {
        oldBalances[oi] = 0;
      }
      uint256 poolUSDCBalance = getVaultVirtualPriceEstimation(_tokens[oi], IYearnVaultV2(_tokens[oi]).totalAssets());
      poolUSDCBalances[oi] = poolUSDCBalance;
    }
  }

  function _addUSDC2CurvePool(
    address _crvToken,
    VaultConfig memory _vc,
    uint256 _usdcAmount
  ) internal {
    if (_vc.depositorTokenLength == 2) {
      uint256[2] memory amounts;
      amounts[uint256(_vc.usdcIndex)] = _usdcAmount;
      if (_vc.depositorType == 2) {
        ICurveZapDepositor2(_vc.depositor).add_liquidity(_crvToken, amounts, 1);
      } else {
        ICurveDepositor2(_vc.depositor).add_liquidity(amounts, 1);
      }
    }

    if (_vc.depositorTokenLength == 3) {
      uint256[3] memory amounts;
      amounts[uint256(_vc.usdcIndex)] = _usdcAmount;
      if (_vc.depositorType == 2) {
        ICurveZapDepositor3(_vc.depositor).add_liquidity(_crvToken, amounts, 1);
      } else {
        ICurveDepositor3(_vc.depositor).add_liquidity(amounts, 1);
      }
    }

    if (_vc.depositorTokenLength == 4) {
      uint256[4] memory amounts;
      amounts[uint256(_vc.usdcIndex)] = _usdcAmount;
      if (_vc.depositorType == 2) {
        ICurveZapDepositor4(_vc.depositor).add_liquidity(_crvToken, amounts, 1);
      } else {
        ICurveDepositor4(_vc.depositor).add_liquidity(amounts, 1);
      }
    }
  }

  function _reward(
    uint256 _reporterId,
    uint256 _gasStart,
    uint256 _compensationPlan,
    bytes calldata _rewardOpts
  ) internal {
    powerPoke.reward(_reporterId, bsub(_gasStart, gasleft()), _compensationPlan, _rewardOpts);
  }

  function _getMinMaxReportInterval() internal view returns (uint256 min, uint256 max) {
    (uint256 minInterval, uint256 maxInterval) = powerPoke.getMinMaxReportIntervals(address(this));
    require(minInterval > 0 && maxInterval > 0, "INTERVALS_ARE_0");
    return (minInterval, maxInterval);
  }
}