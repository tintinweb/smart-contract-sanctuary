// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./../lib/uniswap/UniswapV2Library.sol";
import "./../lib/uniswap/UniswapV2OracleLibrary.sol";
import "./../lib/uniswap/FixedPoint.sol";

import "./../lib/math/MathUtils.sol";

import "./../external-interfaces/compound-finance/ICToken.sol";
import "./../external-interfaces/compound-finance/IComptroller.sol";
import "./../external-interfaces/compound-finance/IUniswapAnchoredOracle.sol";
import "./../external-interfaces/uniswap/IUniswapV2Router.sol";

import "./CompoundProvider.sol";

import "./../IController.sol";
import "./ICompoundCumulator.sol";
import "./../oracle/IYieldOracle.sol";
import "./../oracle/IYieldOraclelizable.sol";

contract CompoundController is IController, ICompoundCumulator, IYieldOraclelizable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant UNISWAP_ROUTER_V2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public constant MAX_UINT256 = uint256(-1);
    uint256 public constant DOUBLE_SCALE = 1e36;

    uint256 public constant BLOCKS_PER_DAY = 5760; // 4 * 60 * 24 (assuming 4 blocks per minute)

    uint256 public harvestedLast;

    // last time we cumulated
    uint256 public prevCumulationTime;

    // exchnageRateStored last time we cumulated
    uint256 public prevExchnageRateCurrent;

    // cumulative supply rate += ((new underlying) / underlying)
    uint256 public cumulativeSupplyRate;

    // cumulative COMP distribution rate += ((new underlying) / underlying)
    uint256 public cumulativeDistributionRate;

    // compound.finance comptroller.compSupplyState right after the previous deposit/withdraw
    IComptroller.CompMarketState public prevCompSupplyState;

    uint256 public underlyingDecimals;

    // uniswap path for COMP to underlying
    address[] public uniswapPath;

    // uniswap pairs for COMP to underlying
    address[] public uniswapPairs;

    // uniswap cumulative prices needed for COMP to underlying
    uint256[] public uniswapPriceCumulatives;

    // keys for uniswap cumulativePrice{0 | 1}
    uint8[] public uniswapPriceKeys;


    event Harvest(address indexed caller, uint256 compRewardTotal, uint256 compRewardSold, uint256 underlyingPoolShare, uint256 underlyingReward, uint256 harvestCost);


    modifier onlyPool {
      require(
        msg.sender == pool,
        "CC: only pool"
      );
      _;
    }

    constructor(
      address pool_,
      address smartYield_,
      address bondModel_,
      address[] memory uniswapPath_
    )
      IController()
    {
      pool = pool_;
      smartYield = smartYield_;
      underlyingDecimals = ERC20(ICToken(CompoundProvider(pool).cToken()).underlying()).decimals();
      setBondModel(bondModel_);
      setUniswapPath(uniswapPath_);

      updateAllowances();
    }

    function updateAllowances()
      public
    {

      ICToken cToken = ICToken(CompoundProvider(pool).cToken());
      IComptroller comptroller = IComptroller(cToken.comptroller());
      IERC20 rewardToken = IERC20(comptroller.getCompAddress());
      IERC20 uToken = IERC20(CompoundProvider(pool).uToken());

      uint256 routerRewardAllowance = rewardToken.allowance(address(this), uniswapRouter());
      rewardToken.safeIncreaseAllowance(uniswapRouter(), MAX_UINT256.sub(routerRewardAllowance));

      uint256 poolUnderlyingAllowance = uToken.allowance(address(this), address(pool));
      uToken.safeIncreaseAllowance(address(pool), MAX_UINT256.sub(poolUnderlyingAllowance));
    }

    // should start with rewardCToken and with uToken, and have intermediary hops if needed
    // path[0] = address(rewardCToken);
    // path[1] = address(wethToken);
    // path[2] = address(uToken);
    function setUniswapPath(address[] memory newUniswapPath_)
      public virtual
      onlyDao
    {
        require(
          2 <= newUniswapPath_.length,
          "CC: setUniswapPath length"
        );

        uniswapPath = newUniswapPath_;

        address[] memory newUniswapPairs = new address[](newUniswapPath_.length - 1);
        uint8[] memory newUniswapPriceKeys = new uint8[](newUniswapPath_.length - 1);

        for (uint256 f = 0; f < newUniswapPath_.length - 1; f++) {
          newUniswapPairs[f] = UniswapV2Library.pairFor(UNISWAP_FACTORY, newUniswapPath_[f], newUniswapPath_[f + 1]);
          (address token0, ) = UniswapV2Library.sortTokens(newUniswapPath_[f], newUniswapPath_[f + 1]);
          newUniswapPriceKeys[f] = token0 == newUniswapPath_[f] ? 0 : 1;
        }

        uniswapPairs = newUniswapPairs;
        uniswapPriceKeys = newUniswapPriceKeys;
        uniswapPriceCumulatives = uniswapPriceCumulativesNow();
    }

    function uniswapRouter()
      public view virtual returns(address)
    {
      // mockable
      return UNISWAP_ROUTER_V2;
    }

    // claims and sells COMP on uniswap, returns total received comp and caller reward
    function harvest(uint256 maxCompAmount_)
      public
    returns (uint256 compGot, uint256 underlyingHarvestReward)
    {
        require(
          harvestedLast < block.timestamp,
          "PPC: harvest later"
        );

        ICToken cToken = ICToken(CompoundProvider(pool).cToken());
        IERC20 uToken = IERC20(CompoundProvider(pool).uToken());
        IComptroller comptroller = IComptroller(cToken.comptroller());
        IERC20 rewardToken = IERC20(comptroller.getCompAddress());

        address caller = msg.sender;

        // claim pool comp
        address[] memory holders = new address[](1);
        holders[0] = pool;
        address[] memory markets = new address[](1);
        markets[0] = address(cToken);
        comptroller.claimComp(holders, markets, false, true);

        // transfer all comp from pool to self
        rewardToken.safeTransferFrom(pool, address(this), rewardToken.balanceOf(pool));
        uint256 compRewardTotal = rewardToken.balanceOf(address(this)); // COMP

        // only sell upmost maxCompAmount_, if maxCompAmount_ sell all
        maxCompAmount_ = (maxCompAmount_ == 0) ? compRewardTotal : maxCompAmount_;
        uint256 compRewardSold = MathUtils.min(maxCompAmount_, compRewardTotal);

        require(
          compRewardSold > 0,
          "PPC: harvested nothing"
        );

        // pool share is (comp to underlying) - (harvest cost percent)
        uint256 poolShare = MathUtils.fractionOf(
          quoteSpotCompToUnderlying(compRewardSold),
          EXP_SCALE.sub(HARVEST_COST)
        );

        // make sure we get at least the poolShare
        IUniswapV2Router(uniswapRouter()).swapExactTokensForTokens(
            compRewardSold,
            poolShare,
            uniswapPath,
            address(this),
            block.timestamp
        );

        uint256 underlyingGot = uToken.balanceOf(address(this));

        require(
          underlyingGot >= poolShare,
          "PPC: harvest poolShare"
        );

        // deposit pool reward share with liquidity provider
        CompoundProvider(pool)._takeUnderlying(address(this), poolShare);
        CompoundProvider(pool)._depositProvider(poolShare, 0);

        // pay caller
        uint256 callerReward = uToken.balanceOf(address(this));
        uToken.safeTransfer(caller, callerReward);

        harvestedLast = block.timestamp;

        emit Harvest(caller, compRewardTotal, compRewardSold, poolShare, callerReward, HARVEST_COST);

        return (compRewardTotal, callerReward);
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
        return cumulativeSupplyRate.add(cumulativeDistributionRate);
      }

      uint256 cTokenBalance = CompoundProvider(pool).cTokenBalance();
      updateCumulativesInternal(cTokenBalance, true);

      return cumulativeSupplyRate.add(cumulativeDistributionRate);
    }

    function updateCumulativesInternal(uint256 prevCTokenBalance_, bool pingCompound_)
      private
    {
      uint256 timeElapsed = block.timestamp - prevCumulationTime;

      // only cumulate once per block
      if (0 == timeElapsed) {
        return;
      }

      ICToken cToken = ICToken(CompoundProvider(pool).cToken());
      IComptroller comptroller = IComptroller(cToken.comptroller());

      uint256[] memory currentUniswapPriceCumulatives = uniswapPriceCumulativesNow();

      if (pingCompound_) {
        // echangeRateStored will be up to date below
        cToken.accrueInterest();
        // compSupplyState will be up to date below
        comptroller.mintAllowed(address(cToken), address(this), 0);
      }

      uint256 exchangeRateStoredNow = cToken.exchangeRateStored();
      (uint224 nowSupplyStateIndex, uint32 blk) = comptroller.compSupplyState(address(cToken));

      if (prevExchnageRateCurrent > 0) {
        // cumulate a new supplyRate delta: cumulativeSupplyRate += (cToken.exchangeRateCurrent() - prevExchnageRateCurrent) / prevExchnageRateCurrent
        // cumulativeSupplyRate eventually overflows, but that's ok due to the way it's used in the oracle
        cumulativeSupplyRate += exchangeRateStoredNow.sub(prevExchnageRateCurrent).mul(EXP_SCALE).div(prevExchnageRateCurrent);

        if (prevCTokenBalance_ > 0) {
          uint256 expectedComp = expectedDistributeSupplierComp(prevCTokenBalance_, nowSupplyStateIndex, prevCompSupplyState.index);
          uint256 expectedCompInUnderlying = quoteCompToUnderlying(
            expectedComp,
            timeElapsed,
            uniswapPriceCumulatives,
            currentUniswapPriceCumulatives
          );

          uint256 poolShare = MathUtils.fractionOf(expectedCompInUnderlying, EXP_SCALE.sub(HARVEST_COST));
          // cumulate a new distributionRate delta: cumulativeDistributionRate += (expectedDistributeSupplierComp in underlying - harvest cost) / prevUnderlyingBalance
          // cumulativeDistributionRate eventually overflows, but that's ok due to the way it's used in the oracle

          cumulativeDistributionRate += poolShare.mul(EXP_SCALE).div(cTokensToUnderlying(prevCTokenBalance_, prevExchnageRateCurrent));
        }
      }

      prevCumulationTime = block.timestamp;

      // uniswap cumulatives only change once per block
      uniswapPriceCumulatives = currentUniswapPriceCumulatives;

      // compSupplyState changes only once per block
      prevCompSupplyState = IComptroller.CompMarketState(nowSupplyStateIndex, blk);

      // exchangeRateStored can increase multiple times per block
      prevExchnageRateCurrent = exchangeRateStoredNow;
    }

    // computes how much COMP tokens compound.finance will have given us after a mint/redeem/redeemUnderlying
    // source: https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol#L1145
    function expectedDistributeSupplierComp(
      uint256 cTokenBalance_, uint224 nowSupplyStateIndex_, uint224 prevSupplyStateIndex_
    ) public pure returns (uint256) {
      uint256 supplyIndex = uint256(nowSupplyStateIndex_);
      uint256 supplierIndex = uint256(prevSupplyStateIndex_);
      uint256 deltaIndex = (supplyIndex).sub(supplierIndex); // a - b
      return (cTokenBalance_).mul(deltaIndex).div(DOUBLE_SCALE); // a * b / doubleScale => uint
    }

    function cTokensToUnderlying(
      uint256 cTokens_, uint256 exchangeRate_
    ) public pure returns (uint256) {
      return cTokens_.mul(exchangeRate_).div(EXP_SCALE);
    }

    function uniswapPriceCumulativeNow(
      address pair_, uint8 priceKey_
    ) public view returns (uint256) {
      (uint256 price0, uint256 price1, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair_);
      return 0 == priceKey_ ? price0 : price1;
    }

    function uniswapPriceCumulativesNow()
      public view virtual returns (uint256[] memory)
    {
      uint256[] memory newUniswapPriceCumulatives = new uint256[](uniswapPairs.length);
      for (uint256 f = 0; f < uniswapPairs.length; f++) {
        newUniswapPriceCumulatives[f] = uniswapPriceCumulativeNow(uniswapPairs[f], uniswapPriceKeys[f]);
      }
      return newUniswapPriceCumulatives;
    }

    function quoteCompToUnderlying(
      uint256 compIn_, uint256 timeElapsed_, uint256[] memory prevUniswapPriceCumulatives_, uint256[] memory nowUniswapPriceCumulatives_
    ) public pure returns (uint256) {
      uint256 amountIn = compIn_;
      for (uint256 f = 0; f < prevUniswapPriceCumulatives_.length; f++) {
        amountIn = uniswapAmountOut(prevUniswapPriceCumulatives_[f], nowUniswapPriceCumulatives_[f], timeElapsed_, amountIn);
      }
      return amountIn;
    }

    function quoteSpotCompToUnderlying(
      uint256 compIn_
    ) public view virtual returns (uint256) {

      ICToken cToken = ICToken(CompoundProvider(pool).cToken());
      IUniswapAnchoredOracle compOracle = IUniswapAnchoredOracle(IComptroller(cToken.comptroller()).oracle());
      uint256 underlyingOut = compIn_.mul(compOracle.price("COMP")).mul(10**24).div(compOracle.getUnderlyingPrice(address(cToken))).div(10**(2 * underlyingDecimals));

      return underlyingOut;
    }

    function uniswapAmountOut(
      uint256 prevPriceCumulative_, uint256 nowPriceCumulative_, uint256 timeElapsed_, uint256 amountIn_
    ) public pure returns (uint256) {
      // per: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol#L93
      FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
        uint224((nowPriceCumulative_ - prevPriceCumulative_) / timeElapsed_)
      );
      return FixedPoint.decode144(FixedPoint.mul(priceAverage, amountIn_));
    }

    // compound spot supply rate per day
    function spotDailySupplyRateProvider()
      public view returns (uint256)
    {
      // supplyRatePerBlock() * BLOCKS_PER_DAY
      return ICToken(CompoundProvider(pool).cToken()).supplyRatePerBlock().mul(BLOCKS_PER_DAY);
    }

    // compound spot distribution rate per day
    function spotDailyDistributionRateProvider()
      public view returns (uint256)
    {
      ICToken cToken = ICToken(CompoundProvider(pool).cToken());
      IComptroller comptroller = IComptroller(cToken.comptroller());
      IUniswapAnchoredOracle compOracle = IUniswapAnchoredOracle(comptroller.oracle());

      // compSpeeds(cToken) * price("COMP") * BLOCKS_PER_DAY
      uint256 compDollarsPerDay = comptroller.compSpeeds(address(cToken)).mul(compOracle.price("COMP")).mul(BLOCKS_PER_DAY);

      // (totalBorrows() + getCash()) * getUnderlyingPrice(cToken)
      uint256 totalSuppliedDollars = cToken.totalBorrows().add(cToken.getCash()).mul(compOracle.getUnderlyingPrice(address(cToken)));

      // (compDollarsPerDay / totalSuppliedDollars)
      return compDollarsPerDay.mul(10**42).div(totalSuppliedDollars).div(10**(2 * underlyingDecimals));
    }

    // smart yield spot daily rate includes: spot supply + spot distribution
    function spotDailyRate()
      public view returns (uint256)
    {
      uint256 expectedSpotDailyDistributionRate = MathUtils.fractionOf(spotDailyDistributionRateProvider(), EXP_SCALE.sub(HARVEST_COST));
      // spotDailySupplyRateProvider() + (spotDailyDistributionRateProvider() - fraction lost to harvest)
      return spotDailySupplyRateProvider().add(expectedSpotDailyDistributionRate);
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

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
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

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "@openzeppelin/contracts/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './FixedPoint.sol';

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

import './FullMath.sol';
import './Babylonian.sol';
import './BitMath.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
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

    // computes a * f / EXP_SCALE
    function fractionOf(uint256 a, uint256 f) internal pure returns (uint256) {
      return a.mul(f).div(EXP_SCALE);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface ICToken {
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

interface ICTokenErc20 {
   function balanceOf(address to) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IComptroller {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IUniswapAnchoredOracle {
  function price(string memory symbol) external view returns (uint256);
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./../external-interfaces/compound-finance/ICToken.sol";
import "./../external-interfaces/compound-finance/IComptroller.sol";

import "./CompoundController.sol";

import "./ICompoundCumulator.sol";
import "./../IProvider.sol";

contract CompoundProvider is IProvider {
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
        "PPC: only smartYield"
      );
      _;
    }

    modifier onlyController {
      require(
        msg.sender == controller,
        "PPC: only controller"
      );
      _;
    }

    modifier onlySmartYieldOrController {
      require(
        msg.sender == smartYield || msg.sender == controller,
        "PPC: only smartYield/controller"
      );
      _;
    }

    modifier onlyControllerOrDao {
      require(
        msg.sender == controller || msg.sender == CompoundController(controller).dao(),
        "PPC: only controller/DAO"
      );
      _;
    }

    constructor(address cToken_)
    {
        cToken = cToken_;
        uToken = ICToken(cToken_).underlying();
    }

    function setup(
        address smartYield_,
        address controller_
    )
      external
    {
        require(
          false == _setup,
          "PPC: already setup"
        );

        smartYield = smartYield_;
        controller = controller_;

        _enterMarket();

        updateAllowances();

        _setup = true;
    }

    function setController(address newController_)
      external override
      onlyControllerOrDao
    {
      // remove allowance on old controller
      IERC20 rewardToken = IERC20(IComptroller(ICToken(cToken).comptroller()).getCompAddress());
      rewardToken.safeApprove(controller, 0);

      controller = newController_;

      // give allowance to new controler
      updateAllowances();
    }

    function updateAllowances()
      public
    {
        IERC20 rewardToken = IERC20(IComptroller(ICToken(cToken).comptroller()).getCompAddress());

        uint256 controllerRewardAllowance = rewardToken.allowance(address(this), controller);
        rewardToken.safeIncreaseAllowance(controller, MAX_UINT256.sub(controllerRewardAllowance));
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
          "PPC: _takeUnderlying amount"
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
          "PPC: _sendUnderlying amount"
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

        ICompoundCumulator(controller)._beforeCTokenBalanceChange();
        IERC20(uToken).approve(address(cToken), underlyingAmount_);
        uint256 err = ICToken(cToken).mint(underlyingAmount_);
        require(0 == err, "PPC: _depositProvider mint");
        ICompoundCumulator(controller)._afterCTokenBalanceChange(cTokenBalance);

        // cTokenBalance is used to compute the pool yield, make sure no one interferes with the computations between deposits/withdrawls
        cTokenBalance = ICTokenErc20(cToken).balanceOf(address(this));
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

        ICompoundCumulator(controller)._beforeCTokenBalanceChange();
        uint256 err = ICToken(cToken).redeemUnderlying(underlyingAmount_);
        require(0 == err, "PPC: _withdrawProvider redeemUnderlying");
        ICompoundCumulator(controller)._afterCTokenBalanceChange(cTokenBalance);

        // cTokenBalance is used to compute the pool yield, make sure no one interferes with the computations between deposits/withdrawls
        cTokenBalance = ICTokenErc20(cToken).balanceOf(address(this));
    }

    function transferFees()
      external
      override
    {
      _withdrawProviderInternal(underlyingFees, 0);
      underlyingFees = 0;

      uint256 fees = IERC20(uToken).balanceOf(address(this));
      address to = CompoundController(controller).feesOwner();

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
    // get exchangeRateCurrent from compound and cache it for the current block
    function exchangeRateCurrent()
      public virtual
    returns (uint256)
    {
      // only once per block
      if (block.timestamp > exchangeRateCurrentCachedAt) {
        exchangeRateCurrentCachedAt = block.timestamp;
        exchangeRateCurrentCached = ICToken(cToken).exchangeRateCurrent();
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
        uint256[] memory err = IComptroller(ICToken(cToken).comptroller()).enterMarkets(markets);
        require(err[0] == 0, "PPC: _enterMarket");
    }

    // /internals

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

interface ICompoundCumulator {
  function _beforeCTokenBalanceChange() external;

  function _afterCTokenBalanceChange(uint256 prevCTokenBalance_) external;
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

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::leastSignificantBit: zero');

        r = 255;
        if (x & uint128(-1) > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & uint64(-1) > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & uint32(-1) > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & uint16(-1) > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & uint8(-1) > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
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