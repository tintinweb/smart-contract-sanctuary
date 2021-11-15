// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./../lib/math/MathUtils.sol";

import "./../external-interfaces/cream-finance/ICrCToken.sol";

import "./../IController.sol";
import "./../oracle/IYieldOracle.sol";
import "./../oracle/IYieldOraclelizable.sol";

import "./ICreamCumulator.sol";
import "./CreamProvider.sol";

contract CreamController is IController, ICreamCumulator, IYieldOraclelizable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BLOCKS_PER_DAY = 5760; // 4 * 60 * 24 (assuming 4 blocks per minute)

    uint256 public constant MAX_UINT256 = uint256(-1);

    // claimed aave rewards are sent to this address
    address public rewardsCollector;

    // last time we cumulated
    uint256 public prevCumulationTime;

    // exchnageRateStored last time we cumulated
    uint256 public prevExchnageRateCurrent;

    // cumulative supply rate += ((new underlying) / underlying)
    uint256 public cumulativeSupplyRate;

    event Harvest(address indexed caller, uint256 rewardTotal, uint256 rewardSold, uint256 underlyingPoolShare, uint256 underlyingReward, uint256 harvestCost);

    modifier onlyPool {
      require(
        msg.sender == pool,
        "CrC: only pool"
      );
      _;
    }

    constructor(
      address pool_,
      address smartYield_,
      address bondModel_,
      address rewardsCollector_
    )
      IController()
    {
      pool = pool_;
      smartYield = smartYield_;
      setBondModel(bondModel_);
      setHarvestCost(0);
      setRewardsCollector(rewardsCollector_);
    }

    function setRewardsCollector(address newRewardsCollector_)
      public
      onlyDao
    {
      rewardsCollector = newRewardsCollector_;
    }

    // claims and sells COMP on uniswap, returns total received comp and caller reward
    function harvest(uint256)
      public
    returns (uint256 rewardAmountGot, uint256 underlyingHarvestReward)
    {
        uint256 amountRewarded = CreamProvider(pool).claimRewardsTo(MAX_UINT256, rewardsCollector);

        emit Harvest(msg.sender, amountRewarded, 0, 0, 0, HARVEST_COST);
        return (amountRewarded, 0);
    }

    function _beforeCTokenBalanceChange()
      external override
      onlyPool
    { }

    function _afterCTokenBalanceChange(uint256 prevCTokenBalance_)
      external override
      onlyPool
    {
      // at this point compound.finance state is updated since the pool did a deposit or withdrawl just before, so no need to ping
      updateCumulativesInternal(prevCTokenBalance_, false);
      IYieldOracle(oracle).update();
    }

    function providerRatePerDay()
      public override virtual
    returns (uint256)
    {
      return MathUtils.min(
        MathUtils.min(BOND_MAX_RATE_PER_DAY, spotDailyRate()),
        IYieldOracle(oracle).consult(1 days)
      );
    }

    function cumulatives()
      external override
      returns (uint256)
    {
      uint256 timeElapsed = block.timestamp - prevCumulationTime;

      // only cumulate once per block
      if (0 == timeElapsed) {
        return cumulativeSupplyRate;
      }

      uint256 cTokenBalance = CreamProvider(pool).cTokenBalance();
      updateCumulativesInternal(cTokenBalance, true);

      return cumulativeSupplyRate;
    }

    function updateCumulativesInternal(uint256, bool pingCompound_)
      private
    {
      uint256 timeElapsed = block.timestamp - prevCumulationTime;

      // only cumulate once per block
      if (0 == timeElapsed) {
        return;
      }

      ICrCToken cToken = ICrCToken(CreamProvider(pool).cToken());

      if (pingCompound_) {
        // exchangeRateStored will be up to date below
        cToken.accrueInterest();
      }

      uint256 exchangeRateStoredNow = cToken.exchangeRateStored();

      if (prevExchnageRateCurrent > 0) {
        // cumulate a new supplyRate delta: cumulativeSupplyRate += (cToken.exchangeRateCurrent() - prevExchnageRateCurrent) / prevExchnageRateCurrent
        // cumulativeSupplyRate eventually overflows, but that's ok due to the way it's used in the oracle
        cumulativeSupplyRate += exchangeRateStoredNow.sub(prevExchnageRateCurrent).mul(EXP_SCALE).div(prevExchnageRateCurrent);
      }

      prevCumulationTime = block.timestamp;

      // exchangeRateStored can increase multiple times per block
      prevExchnageRateCurrent = exchangeRateStoredNow;
    }

    // compound spot supply rate per day
    function spotDailySupplyRateProvider()
      public view returns (uint256)
    {
      // supplyRatePerBlock() * BLOCKS_PER_DAY
      return ICrCToken(CreamProvider(pool).cToken()).supplyRatePerBlock().mul(BLOCKS_PER_DAY);
    }

    // compound spot distribution rate per day
    function spotDailyDistributionRateProvider()
      public pure returns (uint256)
    {
      return 0;
    }

    // smart yield spot daily rate includes: spot supply + spot distribution
    function spotDailyRate()
      public view returns (uint256)
    {
      return spotDailySupplyRateProvider();
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

library MathUtils {

    using SafeMath for uint256;

    uint256 public constant EXP_SCALE = 1e18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function compound(
        // in wei
        uint256 principal,
        // rate is * EXP_SCALE
        uint256 ratePerPeriod,
        uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
          // principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
      }

      return principal;
    }

    function compound2(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      if (0 == ratePerPeriod) {
        return principal;
      }

      while (periods > 0) {
        if (periods % 2 == 1) {
          //principal += principal * ratePerPeriod / EXP_SCALE;
          principal = principal.add(principal.mul(ratePerPeriod).div(EXP_SCALE));
          periods -= 1;
        } else {
          //ratePerPeriod = ((2 * ratePerPeriod * EXP_SCALE) + (ratePerPeriod * ratePerPeriod)) / EXP_SCALE;
          ratePerPeriod = ((uint256(2).mul(ratePerPeriod).mul(EXP_SCALE)).add(ratePerPeriod.mul(ratePerPeriod))).div(EXP_SCALE);
          periods /= 2;
        }
      }

      return principal;
    }

    function linearGain(
      uint256 principal,
      uint256 ratePerPeriod,
      uint16 periods
    ) internal pure returns (uint256) {
      return principal.add(
        fractionOf(principal, ratePerPeriod.mul(periods))
      );
    }

    // computes a * f / EXP_SCALE
    function fractionOf(uint256 a, uint256 f) internal pure returns (uint256) {
      return a.mul(f).div(EXP_SCALE);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ICrCToken {
    function mint(uint mintAmount) external returns (uint256);
    function redeemUnderlying(uint redeemAmount) external returns (uint256);
    function accrueInterest() external returns (uint256);
    function exchangeRateStored() external view returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function supplyRatePerBlock() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function getCash() external view returns (uint256);
    function underlying() external view returns (address);
    function comptroller() external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./Governed.sol";
import "./IProvider.sol";
import "./ISmartYield.sol";

abstract contract IController is Governed {

    uint256 public constant EXP_SCALE = 1e18;

    address public pool; // compound provider pool

    address public smartYield; // smartYield

    address public oracle; // IYieldOracle

    address public bondModel; // IBondModel

    address public feesOwner; // fees are sent here

    // max accepted cost of harvest when converting COMP -> underlying,
    // if harvest gets less than (COMP to underlying at spot price) - HARVEST_COST%, it will revert.
    // if it gets more, the difference goes to the harvest caller
    uint256 public HARVEST_COST = 40 * 1e15; // 4%

    // fee for buying jTokens
    uint256 public FEE_BUY_JUNIOR_TOKEN = 3 * 1e15; // 0.3%

    // fee for redeeming a sBond
    uint256 public FEE_REDEEM_SENIOR_BOND = 100 * 1e15; // 10%

    // max rate per day for sBonds
    uint256 public BOND_MAX_RATE_PER_DAY = 719065000000000; // APY 30% / year

    // max duration of a purchased sBond
    uint16 public BOND_LIFE_MAX = 90; // in days

    bool public PAUSED_BUY_JUNIOR_TOKEN = false;

    bool public PAUSED_BUY_SENIOR_BOND = false;

    function setHarvestCost(uint256 newValue_)
      public
      onlyDao
    {
        require(
          HARVEST_COST < EXP_SCALE,
          "IController: HARVEST_COST too large"
        );
        HARVEST_COST = newValue_;
    }

    function setBondMaxRatePerDay(uint256 newVal_)
      public
      onlyDao
    {
      BOND_MAX_RATE_PER_DAY = newVal_;
    }

    function setBondLifeMax(uint16 newVal_)
      public
      onlyDao
    {
      BOND_LIFE_MAX = newVal_;
    }

    function setFeeBuyJuniorToken(uint256 newVal_)
      public
      onlyDao
    {
      FEE_BUY_JUNIOR_TOKEN = newVal_;
    }

    function setFeeRedeemSeniorBond(uint256 newVal_)
      public
      onlyDao
    {
      FEE_REDEEM_SENIOR_BOND = newVal_;
    }

    function setPaused(bool buyJToken_, bool buySBond_)
      public
      onlyDaoOrGuardian
    {
      PAUSED_BUY_JUNIOR_TOKEN = buyJToken_;
      PAUSED_BUY_SENIOR_BOND = buySBond_;
    }

    function setOracle(address newVal_)
      public
      onlyDao
    {
      oracle = newVal_;
    }

    function setBondModel(address newVal_)
      public
      onlyDao
    {
      bondModel = newVal_;
    }

    function setFeesOwner(address newVal_)
      public
      onlyDao
    {
      feesOwner = newVal_;
    }

    function yieldControllTo(address newController_)
      public
      onlyDao
    {
      IProvider(pool).setController(newController_);
      ISmartYield(smartYield).setController(newController_);
    }

    function providerRatePerDay() external virtual returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IYieldOracle {
    function update() external;

    function consult(uint256 forInterval) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IYieldOraclelizable {
    // accumulates/updates internal state and returns cumulatives 
    // oracle should call this when updating
    function cumulatives()
      external
    returns(uint256 cumulativeYield);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ICreamCumulator {
  function _beforeCTokenBalanceChange() external;

  function _afterCTokenBalanceChange(uint256 prevCTokenBalance_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./../lib/math/MathUtils.sol";

import "./../external-interfaces/cream-finance/ICrCToken.sol";
import "./../external-interfaces/cream-finance/ICrComptroller.sol";

import "./../IController.sol";
import "./../IProvider.sol";

import "./ICreamCumulator.sol";

contract CreamProvider is IProvider {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_UINT256 = uint256(-1);
    uint256 public constant EXP_SCALE = 1e18;

    address public override smartYield;

    address public override controller;

    // fees colected in underlying
    uint256 public override underlyingFees;

    // underlying token (ie. DAI)
    address public uToken; // IERC20

    // claim token (ie. cDAI)
    address public cToken;

    // cToken.balanceOf(this) measuring only deposits by users (excludes direct cToken transfers to pool)
    uint256 public cTokenBalance;

    uint256 public exchangeRateCurrentCached;
    uint256 public exchangeRateCurrentCachedAt;

    bool public _setup;

    event TransferFees(address indexed caller, address indexed feesOwner, uint256 fees);

    modifier onlySmartYield {
      require(
        msg.sender == smartYield,
        "CrP: only smartYield"
      );
      _;
    }

    modifier onlyController {
      require(
        msg.sender == controller,
        "CrP: only controller"
      );
      _;
    }

    modifier onlySmartYieldOrController {
      require(
        msg.sender == smartYield || msg.sender == controller,
        "CrP: only smartYield/controller"
      );
      _;
    }

    modifier onlyControllerOrDao {
      require(
        msg.sender == controller || msg.sender == IController(controller).dao(),
        "CrP: only controller/DAO"
      );
      _;
    }

    constructor(address cToken_)
    {
        cToken = cToken_;
        uToken = ICrCToken(cToken_).underlying();
    }

    function setup(
        address smartYield_,
        address controller_
    )
      external
    {
        require(
          false == _setup,
          "CrP: already setup"
        );

        smartYield = smartYield_;
        controller = controller_;

        _enterMarket();

        _setup = true;
    }

    function setController(address newController_)
      external override
      onlyControllerOrDao
    {
      controller = newController_;
    }

  // externals

    // take underlyingAmount_ from from_
    function _takeUnderlying(address from_, uint256 underlyingAmount_)
      external override
      onlySmartYieldOrController
    {
        uint256 balanceBefore = IERC20(uToken).balanceOf(address(this));
        IERC20(uToken).safeTransferFrom(from_, address(this), underlyingAmount_);
        uint256 balanceAfter = IERC20(uToken).balanceOf(address(this));
        require(
          0 == (balanceAfter - balanceBefore - underlyingAmount_),
          "CrP: _takeUnderlying amount"
        );
    }

    // transfer away underlyingAmount_ to to_
    function _sendUnderlying(address to_, uint256 underlyingAmount_)
      external override
      onlySmartYield
    {
        uint256 balanceBefore = IERC20(uToken).balanceOf(to_);
        IERC20(uToken).safeTransfer(to_, underlyingAmount_);
        uint256 balanceAfter = IERC20(uToken).balanceOf(to_);
        require(
          0 == (balanceAfter - balanceBefore - underlyingAmount_),
          "CrP: _sendUnderlying amount"
        );
    }

    // deposit underlyingAmount_ with the liquidity provider, callable by smartYield or controller
    function _depositProvider(uint256 underlyingAmount_, uint256 takeFees_)
      external override
      onlySmartYieldOrController
    {
        _depositProviderInternal(underlyingAmount_, takeFees_);
    }

    // deposit underlyingAmount_ with the liquidity provider, store resulting cToken balance in cTokenBalance
    function _depositProviderInternal(uint256 underlyingAmount_, uint256 takeFees_)
      internal
    {
        // underlyingFees += takeFees_
        underlyingFees = underlyingFees.add(takeFees_);

        ICreamCumulator(controller)._beforeCTokenBalanceChange();
        IERC20(uToken).safeApprove(address(cToken), underlyingAmount_);
        uint256 err = ICrCToken(cToken).mint(underlyingAmount_);
        require(0 == err, "CrP: _depositProvider mint");
        ICreamCumulator(controller)._afterCTokenBalanceChange(cTokenBalance);

        // cTokenBalance is used to compute the pool yield, make sure no one interferes with the computations between deposits/withdrawls
        cTokenBalance = IERC20(cToken).balanceOf(address(this));
    }

    // withdraw underlyingAmount_ from the liquidity provider, callable by smartYield
    function _withdrawProvider(uint256 underlyingAmount_, uint256 takeFees_)
      external override
      onlySmartYield
    {
      _withdrawProviderInternal(underlyingAmount_, takeFees_);
    }

    // withdraw underlyingAmount_ from the liquidity provider, store resulting cToken balance in cTokenBalance
    function _withdrawProviderInternal(uint256 underlyingAmount_, uint256 takeFees_)
      internal
    {
        // underlyingFees += takeFees_;
        underlyingFees = underlyingFees.add(takeFees_);

        ICreamCumulator(controller)._beforeCTokenBalanceChange();
        uint256 err = ICrCToken(cToken).redeemUnderlying(underlyingAmount_);
        require(0 == err, "CrP: _withdrawProvider redeemUnderlying");
        ICreamCumulator(controller)._afterCTokenBalanceChange(cTokenBalance);

        // cTokenBalance is used to compute the pool yield, make sure no one interferes with the computations between deposits/withdrawls
        cTokenBalance = IERC20(cToken).balanceOf(address(this));
    }

    // claims rewards we have accumulated and sends them to "to" address
    // only callable by controller
    function claimRewardsTo(uint256 amount, address to)
      external
      onlyController
      returns (uint256)
    {
      address[] memory holders = new address[](1);
      holders[0] = address(this);

      address[] memory cTokens = new address[](1);
      cTokens[0] = cToken;

      ICrComptroller comptroller = ICrComptroller(ICrCToken(cToken).comptroller());
      IERC20 Comp = IERC20(comptroller.getCompAddress());

      comptroller.claimComp(
        holders,
        cTokens,
        false,
        true
      );

      amount = MathUtils.min(amount, Comp.balanceOf(address(this)));

      Comp.safeTransfer(to, amount);

      return amount;
    }

    function transferFees()
      external
      override
    {
      _withdrawProviderInternal(underlyingFees, 0);
      underlyingFees = 0;

      uint256 fees = IERC20(uToken).balanceOf(address(this));
      address to = IController(controller).feesOwner();

      IERC20(uToken).safeTransfer(to, fees);

      emit TransferFees(msg.sender, to, fees);
    }

    // current total underlying balance, as measured by pool, without fees
    function underlyingBalance()
      external virtual override
    returns (uint256)
    {
        // https://compound.finance/docs#protocol-math
        // (total balance in underlying) - underlyingFees
        // cTokenBalance * exchangeRateCurrent() / EXP_SCALE - underlyingFees;
        return cTokenBalance.mul(exchangeRateCurrent()).div(EXP_SCALE).sub(underlyingFees);
    }
  // /externals

  // public
    // get exchangeRateCurrent from cream and cache it for the current block
    function exchangeRateCurrent()
      public virtual
    returns (uint256)
    {
      // only once per block
      if (block.timestamp > exchangeRateCurrentCachedAt) {
        exchangeRateCurrentCachedAt = block.timestamp;
        exchangeRateCurrentCached = ICrCToken(cToken).exchangeRateCurrent();
      }
      return exchangeRateCurrentCached;
    }
  // /public

  // internals

    // call comptroller.enterMarkets()
    // needs to be called only once BUT before any interactions with the provider
    function _enterMarket()
      internal
    {
        address[] memory markets = new address[](1);
        markets[0] = cToken;
        uint256[] memory err = ICrComptroller(ICrCToken(cToken).comptroller()).enterMarkets(markets);
        require(err[0] == 0, "CrP: _enterMarket");
    }

    // /internals

}

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

abstract contract Governed {

  address public dao;
  address public guardian;

  modifier onlyDao {
    require(
        dao == msg.sender,
        "GOV: not dao"
      );
    _;
  }

  modifier onlyDaoOrGuardian {
    require(
      msg.sender == dao || msg.sender == guardian,
      "GOV: not dao/guardian"
    );
    _;
  }

  constructor()
  {
    dao = msg.sender;
    guardian = msg.sender;
  }

  function setDao(address dao_)
    external
    onlyDao
  {
    dao = dao_;
  }

  function setGuardian(address guardian_)
    external
    onlyDao
  {
    guardian = guardian_;
  }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IProvider {

    function smartYield() external view returns (address);

    function controller() external view returns (address);

    function underlyingFees() external view returns (uint256);

    // deposit underlyingAmount_ into provider, add takeFees_ to fees
    function _depositProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

    // withdraw underlyingAmount_ from provider, add takeFees_ to fees
    function _withdrawProvider(uint256 underlyingAmount_, uint256 takeFees_) external;

    function _takeUnderlying(address from_, uint256 amount_) external;

    function _sendUnderlying(address to_, uint256 amount_) external;

    function transferFees() external;

    // current total underlying balance as measured by the provider pool, without fees
    function underlyingBalance() external returns (uint256);

    function setController(address newController_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

interface ISmartYield {

    // a senior BOND (metadata for NFT)
    struct SeniorBond {
        // amount seniors put in
        uint256 principal;
        // amount yielded at the end. total = principal + gain
        uint256 gain;
        // bond was issued at timestamp
        uint256 issuedAt;
        // bond matures at timestamp
        uint256 maturesAt;
        // was it liquidated yet
        bool liquidated;
    }

    // a junior BOND (metadata for NFT)
    struct JuniorBond {
        // amount of tokens (jTokens) junior put in
        uint256 tokens;
        // bond matures at timestamp
        uint256 maturesAt;
    }

    // a checkpoint for all JuniorBonds with same maturity date JuniorBond.maturesAt
    struct JuniorBondsAt {
        // sum of JuniorBond.tokens for JuniorBonds with the same JuniorBond.maturesAt
        uint256 tokens;
        // price at which JuniorBonds will be paid. Initially 0 -> unliquidated (price is in the future or not yet liquidated)
        uint256 price;
    }

    function controller() external view returns (address);

    function buyBond(uint256 principalAmount_, uint256 minGain_, uint256 deadline_, uint16 forDays_) external returns (uint256);

    function redeemBond(uint256 bondId_) external;

    function unaccountBonds(uint256[] memory bondIds_) external;

    function buyTokens(uint256 underlyingAmount_, uint256 minTokens_, uint256 deadline_) external;

    /**
     * sell all tokens instantly
     */
    function sellTokens(uint256 tokens_, uint256 minUnderlying_, uint256 deadline_) external;

    function buyJuniorBond(uint256 tokenAmount_, uint256 maxMaturesAt_, uint256 deadline_) external;

    function redeemJuniorBond(uint256 jBondId_) external;

    function liquidateJuniorBonds(uint256 upUntilTimestamp_) external;

    /**
     * token purchase price
     */
    function price() external returns (uint256);

    function abondPaid() external view returns (uint256);

    function abondDebt() external view returns (uint256);

    function abondGain() external view returns (uint256);

    /**
     * @notice current total underlying balance, without accruing interest
     */
    function underlyingTotal() external returns (uint256);

    /**
     * @notice current underlying loanable, without accruing interest
     */
    function underlyingLoanable() external returns (uint256);

    function underlyingJuniors() external returns (uint256);

    function bondGain(uint256 principalAmount_, uint16 forDays_) external returns (uint256);

    function maxBondDailyRate() external returns (uint256);

    function setController(address newController_) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ICrComptroller {
    struct CompMarketState {
        uint224 index;
        uint32 block;
    }

    function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
    function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) external;
    function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256);

    function getCompAddress() external view returns(address);
    function compSupplyState(address cToken) external view returns (uint224, uint32);
    function compSpeeds(address cToken) external view returns (uint256);
    function oracle() external view returns (address);
}

