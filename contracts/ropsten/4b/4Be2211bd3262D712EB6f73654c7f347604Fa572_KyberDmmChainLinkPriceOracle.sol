// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {ILiquidationPriceOracleBase} from '../../interfaces/liquidation/ILiquidationPriceOracleBase.sol';
import {IChainLinkAggregatorProxy} from '../../interfaces/liquidation/thirdParty/IChainLinkAggregatorProxy.sol';
import {IDMMPool} from '../../interfaces/liquidation/thirdParty/IDMMPool.sol';
import {PermissionAdmin, PermissionOperators} from '@kyber.network/utils-sc/contracts/PermissionOperators.sol';
import {Utils} from '@kyber.network/utils-sc/contracts/Utils.sol';
import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/EnumerableSet.sol';


/**
* @dev Contract to calculate expected return amounts for a liquidation call
*   Also work with Kyber Dmm LP tokens
*   Can use hint to:
*     2. Calculate price of a LP token to a dest token
*     3. Calculate price of a normal token to a dest token
*   It may not work for LPs of token with fees
*/
contract KyberDmmChainLinkPriceOracle is ILiquidationPriceOracleBase, PermissionOperators, Utils {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  // LIQUIDATE_LP: liquidate list of LP tokens to a single token
  // LIQUIDATE_TOKEN: liquidate list of tokens to a single token
  enum LiquidationType { LIQUIDATE_LP, LIQUIDATE_TOKEN }

  uint64 constant public MAX_PREMIUM_BPS = 2000; // 20%
  // min duration to consider the chainlink rate as a valid data
  uint64 constant public MIN_DURATION_VALID_CHAINLINK_RATE = 30 minutes;

  address public immutable weth;

  struct AggregatorProxyData {
    address quoteEthProxy;
    uint8 quoteEthProxyDecimals;
    address quoteUsdProxy;
    uint8 quoteUsdProxyDecimals;
  }
  mapping (address => AggregatorProxyData) internal _tokenData;

  struct Config {
    uint64 liquidateLpBps;            // default liquidate lp bps
    uint64 liquidateTokenBps;         // default liquidate token bps
    uint64 minValidDurationInSeconds; // min valid duration in seconds for chainlink
    uint64 lpDiffThreshold;           // different threshold for price of 2 tokens in the LP 
  }
  Config internal _config;

  struct PremiumData {
    uint64 liquidateLpBps;
    uint64 liquidateTokenBps;
  }
  mapping (address => PremiumData) internal _groupPremiumData;

  // list of tokens that can be liquidate to
  EnumerableSet.AddressSet private _whitelistedTokens;

  event DefaultPremiumDataSet(
    uint64 liquidateLpBps,
    uint64 liquidateTokenBps
  );
  event UpdateGroupPremiumData(
    address indexed liquidator,
    uint64 liquidateLpBps,
    uint64 liquidateTokenBps
  );
  event UpdateAggregatorProxyData(
    address indexed token,
    address indexed quoteEthProxy,
    address indexed quoteUsdProxy
  );
  event WhitelistedTokenUpdated(address indexed token, bool indexed isAdd);
  event UpdatedMinValidDurationInSeconds(uint64 duration);
  event UpdatedLpDiffThreshold(uint64 threshold);

  constructor(
    address admin,
    address wethAddress,
    address[] memory whitelistedTokens,
    uint64 chainlinkValidDuration,
    uint64 lpDiffThreshold
  ) PermissionAdmin(admin) {
    weth = wethAddress;
    _updateWhitelistedToken(whitelistedTokens, true);
    _setMinValidDuration(chainlinkValidDuration);
    _setLpDiffThreshold(lpDiffThreshold);
  }

  /**
  * @dev Update list of aggregator proxies for tokens
  *   Need to check the data carefully, Aggregator contract doesn't have function to
  *     get the supported token or base, so can not do any safe check here
  *   For flexibility, it should be done by trusted operators
  */
  function updateAggregatorProxyData(
    address[] calldata tokens,
    address[] calldata quoteEthProxies,
    address[] calldata quoteUsdProxies
  ) external onlyOperator {

    require(
      tokens.length == quoteEthProxies.length &&
      tokens.length == quoteUsdProxies.length,
      'invalid length'
    );

    uint8 quoteEthProxyDecimals;
    uint8 quoteUsdProxyDecimals;

    for(uint256 i = 0; i < tokens.length; i++) {
      quoteEthProxyDecimals = quoteEthProxies[i] == address(0) ? 0 :
        IChainLinkAggregatorProxy(quoteEthProxies[i]).decimals();
      quoteUsdProxyDecimals = quoteUsdProxies[i] == address(0) ? 0 :
        IChainLinkAggregatorProxy(quoteUsdProxies[i]).decimals();

      _tokenData[tokens[i]] = AggregatorProxyData({
        quoteEthProxy: quoteEthProxies[i],
        quoteUsdProxy: quoteUsdProxies[i],
        quoteEthProxyDecimals: quoteEthProxyDecimals,
        quoteUsdProxyDecimals: quoteUsdProxyDecimals
      });
      emit UpdateAggregatorProxyData(tokens[i], quoteEthProxies[i], quoteUsdProxies[i]);
    }
  }

  function updateMinValidDuration(uint64 newDuration)
    external onlyOperator
  {
    _setMinValidDuration(newDuration);
  }

  function updateLpDiffThreshold(uint64 threshold)
    external onlyOperator
  {
    _setLpDiffThreshold(threshold);
  }

  function updateGroupPremiumData(
    address[] calldata _liquidators,
    uint64[] calldata _liquidateLpBps,
    uint64[] calldata _liquidateTokenBps
  )
    external onlyAdmin
  {
    require(
      _liquidators.length == _liquidateLpBps.length &&
      _liquidators.length == _liquidateTokenBps.length,
      'invalid length'
    );
    for(uint256 i = 0; i < _liquidators.length; i++) {
      _setGroupPremiumData(
        _liquidators[i],
        _liquidateLpBps[i],
        _liquidateTokenBps[i]
      );
    }
  }

  function updateDefaultPremiumData(
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) external onlyAdmin {
    _setDefaultPremiumData(_liquidateLpBps, _liquidateTokenBps);
  }

  function updateWhitelistedTokens(address[] calldata tokens, bool isAdd)
    external onlyAdmin
  {
    _updateWhitelistedToken(tokens, isAdd);
  }

  /**
   * @dev Return list of min amounts that expected to get in return
   *  when liquidating corresponding list of src tokens
   *  2 LiquidationType for hint: LIQUIDATE_TOKEN, LIQUIDATE_LP
   *  - LIQUIDATE_TOKEN: Liquidate a normal token to the tokenOut (the token should have chainlink data)
   *  - LIQUIDATE_LP: Liquidate a LP token to the tokenOut (underlying tokens should have chainlink data)
   *  Apply premium discount, can be a different value for each liquidator.
   * @param liquidator address of the liquidator
   * @param tokenIns list of src tokens
   * @param amountIns list of src amounts
   * @param tokenOut dest token
   * @param hint hint for getting conversion rates, list of LiquidationType,
   *     corresponding to the list source token
   * @return minAmountOut min expected amount for the token out
   */
  function getExpectedReturn(
    address liquidator,
    IERC20Ext[] calldata tokenIns,
    uint256[] calldata amountIns,
    IERC20Ext tokenOut,
    bytes calldata hint
  )
    external override view
    returns (uint256 minAmountOut)
  {
    require(tokenIns.length == amountIns.length, 'invalid lengths');

    (LiquidationType[] memory hintTypes) = abi.decode(hint, (LiquidationType[]));
    require(hintTypes.length == tokenIns.length, 'invalid lengths');

    require(isWhitelistedToken(address(tokenOut)), 'token out must be whitelisted');

    // get rate data of token out in advance to reduce gas cost
    uint256 tokenOutRateEth = getRateOverEth(address(tokenOut));
    uint256 tokenOutRateUsd = getRateOverUsd(address(tokenOut));

    // total amount out from LP tokens
    uint256 amountOutLpTokens;
    // total amount out from normal tokens
    uint256 amountOutNormalTokens;

    for(uint256 i = 0; i < tokenIns.length; i++) {
      if (hintTypes[i] == LiquidationType.LIQUIDATE_TOKEN) {
        if (tokenIns[i] == tokenOut) {
          // allow to forward a whitelist token from treasury -> reward without premium
          minAmountOut = minAmountOut.add(amountIns[i]);
          continue;
        } else {
          // not allow to liquidate from a whitelisted token to another whitelisted token
          require(
            !isWhitelistedToken(address(tokenIns[i])),
            'token in can not be a whitelisted token'
          );
        }
      }
      uint256 expectedReturn = _getExpectedReturnFromToken(
        tokenIns[i],
        amountIns[i],
        tokenOut,
        tokenOutRateEth,
        tokenOutRateUsd,
        hintTypes[i] == LiquidationType.LIQUIDATE_LP
      );
      if (hintTypes[i] == LiquidationType.LIQUIDATE_LP) {
        amountOutLpTokens = amountOutLpTokens.add(expectedReturn);
      } else {
        amountOutNormalTokens = amountOutNormalTokens.add(expectedReturn);
      }
    }

    (amountOutLpTokens, amountOutNormalTokens) =
      _applyPremiumFor(liquidator, amountOutLpTokens, amountOutNormalTokens);

    minAmountOut = minAmountOut.add(amountOutLpTokens).add(amountOutNormalTokens);
  }

  // Whitelisted tokens
  function getWhitelistedTokensLength() external view returns (uint256) {
    return _whitelistedTokens.length();
  }

  function getWhitelistedTokenAt(uint256 index) external view returns (address) {
    return _whitelistedTokens.at(index);
  }

  function getAllWhitelistedTokens()
    external view returns (address[] memory tokens)
  {
    uint256 length = _whitelistedTokens.length();
    tokens = new address[](length);
    for(uint256 i = 0; i < length; i++) {
      tokens[i] = _whitelistedTokens.at(i);
    }
  }

  /**
   * @dev Return expect amounts given pool and number of lp tokens
   * @return tokens [token0, token1]
   * @return amounts [expectedAmount0, expectedAmount1s, virtualBalance0, virtualBalance1]
   */
  function getExpectedTokensFromLp(
    address pool,
    uint256 lpAmount
  )
    public view
    returns (
      IERC20Ext[2] memory tokens,
      uint256[4] memory amounts
    )
  {
    uint256 totalSupply = IERC20Ext(pool).totalSupply();
    (tokens[0], tokens[1]) = (IDMMPool(pool).token0(), IDMMPool(pool).token1());
    uint256 amount0;
    uint256 amount1;
    (
      amount0,
      amount1,
      amounts[2], // virtual balance 0
      amounts[3], // virtual balance 1
      // fee in precision
    ) = IDMMPool(pool).getTradeInfo();

    (amounts[0], amounts[1]) = (
      amount0.mul(lpAmount) / totalSupply,
      amount1.mul(lpAmount) / totalSupply
    );
  }

  function getTokenAggregatorProxyData(address token)
    external view returns (
      address quoteEthProxy,
      address quoteUsdProxy,
      uint8 quoteEthDecimals,
      uint8 quoteUsdDecimals
    )
  {
    (quoteEthProxy, quoteUsdProxy) = (_tokenData[token].quoteEthProxy, _tokenData[token].quoteUsdProxy);
    (quoteEthDecimals, quoteUsdDecimals) = (
      _tokenData[token].quoteEthProxyDecimals,
      _tokenData[token].quoteUsdProxyDecimals
    );
  }

  function getConfig()
    external view
    returns (
      uint64 liquidateLpBps,
      uint64 liquidateTokenBps,
      uint64 minValidDurationInSeconds,
      uint64 lpDiffThreshold
    )
  {
    (
      liquidateLpBps,
      liquidateTokenBps,
      minValidDurationInSeconds,
      lpDiffThreshold
    ) = (
        _config.liquidateLpBps,
        _config.liquidateTokenBps,
        _config.minValidDurationInSeconds,
        _config.lpDiffThreshold
      );
  }

  /**
  *   @dev Get token rate over eth with units of PRECISION
  */
  function getRateOverEth(address token) public view returns (uint256 rate) {
    if (token == address(ETH_TOKEN_ADDRESS) || token == weth) return PRECISION;
    int256 answer;
    uint256 updatedAt;
    IChainLinkAggregatorProxy proxy = IChainLinkAggregatorProxy(_tokenData[token].quoteEthProxy);
    if (proxy != IChainLinkAggregatorProxy(0)) {
      (, answer, , updatedAt,) = proxy.latestRoundData();
    }
    if (answer <= 0) return 0; // safe check in case ChainLink returns invalid data
    if (updatedAt.add(_config.minValidDurationInSeconds) < block.timestamp) return 0;
    rate = uint256(answer);
    uint256 decimals = uint256(_tokenData[token].quoteEthProxyDecimals);
    rate = (decimals < MAX_DECIMALS) ? rate.mul(10 ** (MAX_DECIMALS - decimals)) :
      rate / (10 ** (decimals - MAX_DECIMALS));
  }

  /**
  *   @dev Get token rate over usd with units of PRECISION
  */
  function getRateOverUsd(address token) public view returns (uint256 rate) {
    int256 answer;
    uint256 updatedAt;
    IChainLinkAggregatorProxy proxy = IChainLinkAggregatorProxy(_tokenData[token].quoteUsdProxy);
    if (proxy != IChainLinkAggregatorProxy(0)) {
      (, answer, , updatedAt,) = proxy.latestRoundData();
    }
    if (answer <= 0) return 0; // safe check in case ChainLink returns invalid data
    if (updatedAt.add(_config.minValidDurationInSeconds) < block.timestamp) return 0;
    rate = uint256(answer);
    uint256 decimals = uint256(_tokenData[token].quoteUsdProxyDecimals);
    rate = (decimals < MAX_DECIMALS) ? rate.mul(10 ** (MAX_DECIMALS - decimals)) :
      rate / (10 ** (decimals - MAX_DECIMALS));
  }

  function isWhitelistedToken(address token)
    public view returns (bool)
  {
    return _whitelistedTokens.contains(token);
  }

  function getPremiumData(address liquidator)
    public view
    returns (
      uint64 liquidateLpBps,
      uint64 liquidateTokenBps
    )
  {
    PremiumData memory data = _groupPremiumData[liquidator];
    if (data.liquidateLpBps == 0 && data.liquidateTokenBps == 0) {
      liquidateLpBps = _config.liquidateLpBps;
      liquidateTokenBps = _config.liquidateTokenBps;
    } else {
      liquidateLpBps = data.liquidateLpBps;
      liquidateTokenBps = data.liquidateTokenBps;
    }
  }

  function _updateWhitelistedToken(address[] memory _tokens, bool _isAdd) internal {
    for(uint256 i = 0; i < _tokens.length; i++) {
      if (_isAdd) {
        _whitelistedTokens.add(_tokens[i]);
      } else {
        _whitelistedTokens.remove(_tokens[i]);
      }
      emit WhitelistedTokenUpdated(_tokens[i], _isAdd);
    }
  }

  function _setDefaultPremiumData(
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) internal {
    require(_liquidateLpBps <= MAX_PREMIUM_BPS, 'invalid liquidate lp bps');
    require(_liquidateTokenBps <= MAX_PREMIUM_BPS, 'invalid liquidate token bps');
    _config.liquidateLpBps = _liquidateLpBps;
    _config.liquidateTokenBps = _liquidateTokenBps;
    emit DefaultPremiumDataSet(_liquidateLpBps, _liquidateTokenBps);
  }

  function _setGroupPremiumData(
    address _liquidator,
    uint64 _liquidateLpBps,
    uint64 _liquidateTokenBps
  ) internal {
    require(_liquidateLpBps <= MAX_PREMIUM_BPS, 'invalid liquidate lp bps');
    require(_liquidateTokenBps <= MAX_PREMIUM_BPS, 'invalid liquidate token bps');
    _groupPremiumData[_liquidator].liquidateLpBps = _liquidateLpBps;
    _groupPremiumData[_liquidator].liquidateTokenBps = _liquidateTokenBps;
    emit UpdateGroupPremiumData(_liquidator, _liquidateLpBps, _liquidateTokenBps);
  }

  function _setMinValidDuration(uint64 _duration) internal {
    require(_duration >= MIN_DURATION_VALID_CHAINLINK_RATE, 'duration is too low');
    _config.minValidDurationInSeconds = _duration;
    emit UpdatedMinValidDurationInSeconds(_duration);
  }

  function _setLpDiffThreshold(uint64 _threshold) internal {
    require(_threshold <= MAX_PREMIUM_BPS, 'threshold is too high');
    _config.lpDiffThreshold = _threshold;
    emit UpdatedLpDiffThreshold(_threshold);
  }

  function _applyPremiumFor(address liquidator, uint256 amountFromLPs, uint256 amountFromTokens)
    internal view
    returns (uint256 amountFromLPsAfter, uint256 amountFromTokensAfter)
  {
    (uint64 premiumLpBps, uint64 premiumTokenBps) = getPremiumData(liquidator);
    if (amountFromLPs > 0) {
      amountFromLPsAfter = amountFromLPs.sub(
        amountFromLPs.mul(premiumLpBps) / BPS
      );
    }
    if (amountFromTokens > 0) {
      amountFromTokensAfter = amountFromTokens.sub(
        amountFromTokens.mul(premiumTokenBps) / BPS
      );
    }
  }

  /**
  *   @dev Get expected return amount from src token given dest token data
  *   Save gas when liquidating multiple tokens or LP tokens
  */
  function _getExpectedReturnFromToken(
    IERC20Ext tokenIn,
    uint256 amountIn,
    IERC20Ext dest,
    uint256 destRateEth,
    uint256 destRateUsd,
    bool isFromLpToken
  )
    internal view
    returns (uint256 totalReturn)
  {
    bool isDestEth = dest == ETH_TOKEN_ADDRESS || dest == IERC20Ext(weth);
    uint256 rate;

    if (!isFromLpToken) {
      rate = isDestEth ? getRateOverEth(address(tokenIn)) :
        _getRateWithDestTokenData(address(tokenIn), destRateEth, destRateUsd);
      require(rate > 0, '0 aggregator rate');
      return _calculateReturnAmount(amountIn, getDecimals(tokenIn), getDecimals(dest), rate);
    }

    (IERC20Ext[2] memory tokens, uint256[4] memory amounts) = getExpectedTokensFromLp(
      address(tokenIn), amountIn
    );

    uint256 destTokenDecimals = getDecimals(dest);
    uint256 totalDestInToken0;
    uint256 totalDestInToken1;

    // calc equivalent (tokens[0], amounts[0]) -> tokenOut
    if (tokens[0] == dest) {
      totalReturn = totalReturn.add(amounts[0]);
      totalDestInToken0 = amounts[2];
    } else {
      rate = isDestEth ? getRateOverEth(address(tokens[0])) :
        _getRateWithDestTokenData(address(tokens[0]), destRateEth, destRateUsd);
      require(rate > 0, '0 aggregator rate');
      uint256 _decimals = getDecimals(tokens[0]);
      totalReturn = totalReturn.add(
        _calculateReturnAmount(amounts[0], _decimals, destTokenDecimals, rate)
      );
      totalDestInToken0 = _calculateReturnAmount(amounts[2], _decimals, destTokenDecimals, rate);
    }

    // calc equivalent (tokens[1], amounts[1]) -> tokenOut
    if (tokens[1] == dest) {
      totalReturn = totalReturn.add(amounts[1]);
      totalDestInToken1 = amounts[3];
    } else {
      rate = isDestEth ? getRateOverEth(address(tokens[1])) :
        _getRateWithDestTokenData(address(tokens[1]), destRateEth, destRateUsd);
        require(rate > 0, '0 aggregator rate');
        uint256 _decimals = getDecimals(tokens[1]);
      totalReturn = totalReturn.add(
        _calculateReturnAmount(amounts[1], _decimals, destTokenDecimals, rate)
      );
      totalDestInToken1 = _calculateReturnAmount(amounts[3], _decimals, destTokenDecimals, rate);
    }
    // verify if equivalent dest tokens from virtual balances is within the threshold
    // note: if the pool is out of support price range, most likely this check will fail
    if (totalDestInToken0 < totalDestInToken1) {
      require(
        totalDestInToken0.mul(BPS + _config.lpDiffThreshold) >= totalDestInToken1.mul(BPS),
        'lpDiffThreshold: out of range'
      );
    } else {
      require(
        totalDestInToken1.mul(BPS + _config.lpDiffThreshold) >= totalDestInToken0.mul(BPS),
        'lpDiffThreshold: out of range'
      );
    }
  }

  /**
  *   @dev Get rate from src token given dest token rates over eth and usd
  *   It is used to save gas when liquidating multiple tokens or LP tokens
  */
  function _getRateWithDestTokenData(
    address src,
    uint256 destTokenRateEth,
    uint256 destTokenRateUsd
  ) internal view returns (uint256) {
    if (src == address(ETH_TOKEN_ADDRESS) || src == weth) {
      if (destTokenRateEth == 0) return 0;
      return PRECISION.mul(PRECISION) / destTokenRateEth;
    }

    uint256 rateQuoteEth;
    uint256 rateQuoteUsd;

    if (destTokenRateEth > 0) {
      uint256 srcTokenRateEth = getRateOverEth(src);
      rateQuoteEth = PRECISION.mul(srcTokenRateEth) / destTokenRateEth;
    }

    if (destTokenRateUsd > 0) {
      uint256 srcTokenRateUsd = getRateOverUsd(src);
      rateQuoteUsd = PRECISION.mul(srcTokenRateUsd) / destTokenRateUsd;
    }

    if (rateQuoteEth == 0) return rateQuoteUsd;
    if (rateQuoteUsd == 0) return rateQuoteEth;
    return rateQuoteEth.add(rateQuoteUsd) / 2;
  }

  function _calculateReturnAmount(
    uint256 srcQty,
    uint256 srcDecimals,
    uint256 dstDecimals,
    uint256 rate
  ) internal pure returns (uint256) {
    if (dstDecimals >= srcDecimals) {
      require(dstDecimals - srcDecimals <= MAX_DECIMALS, 'dst - src > MAX_DECIMALS');
      return srcQty.mul(rate).mul(10**(dstDecimals - srcDecimals)) / PRECISION;
    }
    require(srcDecimals - dstDecimals <= MAX_DECIMALS, 'src - dst > MAX_DECIMALS');
    return srcQty.mul(rate) / (PRECISION.mul(10**(srcDecimals - dstDecimals)));
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';

/**
* Use different logics to compute price oracle
* If token is not supported, it should return 0 as conversion rate
*/
interface ILiquidationPriceOracleBase {

  /**
   * @dev Return list of min amounts that expected to get in return
   *  when liquidating corresponding list of src tokens
   * @param liquidator address of the liquidator
   * @param tokenIns list of src tokens
   * @param amountIns list of src amounts
   * @param tokenOut dest token
   * @param hint hint for getting conversion rates
   * @return minAmountOut min expected amount for the token out
   */
  function getExpectedReturn(
    address liquidator,
    IERC20Ext[] calldata tokenIns,
    uint256[] calldata amountIns,
    IERC20Ext tokenOut,
    bytes calldata hint
  ) external view returns (uint256 minAmountOut);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


// solhint-disable-next-line max-line-length
// Refer to https://github.com/smartcontractkit/chainlink/blob/develop/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
interface IChainLinkAggregatorProxy {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer, // rate in decimals of the token
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import {IERC20Ext} from '@kyber.network/utils-sc/contracts/IERC20Ext.sol';


interface IDMMPool {
  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1);
  function getTradeInfo()
    external view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint112 _vReserve0,
      uint112 _vReserve1,
      uint256 feeInPrecision
  );

  function token0() external view returns (IERC20Ext);

  function token1() external view returns (IERC20Ext);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./PermissionAdmin.sol";


abstract contract PermissionOperators is PermissionAdmin {
    uint256 private constant MAX_GROUP_SIZE = 50;

    mapping(address => bool) internal operators;
    address[] internal operatorsGroup;

    event OperatorAdded(address newOperator, bool isAdd);

    modifier onlyOperator() {
        require(operators[msg.sender], "only operator");
        _;
    }

    function getOperators() external view returns (address[] memory) {
        return operatorsGroup;
    }

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator], "operator exists"); // prevent duplicates.
        require(operatorsGroup.length < MAX_GROUP_SIZE, "max operators");

        emit OperatorAdded(newOperator, true);
        operators[newOperator] = true;
        operatorsGroup.push(newOperator);
    }

    function removeOperator(address operator) public onlyAdmin {
        require(operators[operator], "not operator");
        operators[operator] = false;

        for (uint256 i = 0; i < operatorsGroup.length; ++i) {
            if (operatorsGroup[i] == operator) {
                operatorsGroup[i] = operatorsGroup[operatorsGroup.length - 1];
                operatorsGroup.pop();
                emit OperatorAdded(operator, false);
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IERC20Ext.sol";


/**
 * @title Kyber utility file
 * mostly shared constants and rate calculation helpers
 * inherited by most of kyber contracts.
 * previous utils implementations are for previous solidity versions.
 */
abstract contract Utils {
    // Declared constants below to be used in tandem with
    // getDecimalsConstant(), for gas optimization purposes
    // which return decimals from a constant list of popular
    // tokens.
    IERC20Ext internal constant ETH_TOKEN_ADDRESS = IERC20Ext(
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
    );
    IERC20Ext internal constant USDT_TOKEN_ADDRESS = IERC20Ext(
        0xdAC17F958D2ee523a2206206994597C13D831ec7
    );
    IERC20Ext internal constant DAI_TOKEN_ADDRESS = IERC20Ext(
        0x6B175474E89094C44Da98b954EedeAC495271d0F
    );
    IERC20Ext internal constant USDC_TOKEN_ADDRESS = IERC20Ext(
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    );
    IERC20Ext internal constant WBTC_TOKEN_ADDRESS = IERC20Ext(
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
    );
    IERC20Ext internal constant KNC_TOKEN_ADDRESS = IERC20Ext(
        0xdd974D5C2e2928deA5F71b9825b8b646686BD200
    );
    uint256 public constant BPS = 10000; // Basic Price Steps. 1 step = 0.01%
    uint256 internal constant PRECISION = (10**18);
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens
    uint256 internal constant MAX_RATE = (PRECISION * 10**7); // up to 10M tokens per eth
    uint256 internal constant MAX_DECIMALS = 18;
    uint256 internal constant ETH_DECIMALS = 18;
    uint256 internal constant MAX_ALLOWANCE = uint256(-1); // token.approve inifinite

    mapping(IERC20Ext => uint256) internal decimals;

    /// @dev Sets the decimals of a token to storage if not already set, and returns
    ///      the decimals value of the token. Prefer using this function over
    ///      getDecimals(), to avoid forgetting to set decimals in local storage.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getSetDecimals(IERC20Ext token) internal returns (uint256 tokenDecimals) {
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        tokenDecimals = decimals[token];
        if (tokenDecimals == 0) {
            tokenDecimals = token.decimals();
            decimals[token] = tokenDecimals;
        }
    }

    /// @dev Get the balance of a user
    /// @param token The token type
    /// @param user The user's address
    /// @return The balance
    function getBalance(IERC20Ext token, address user) internal view returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return user.balance;
        } else {
            return token.balanceOf(user);
        }
    }

    /// @dev Get the decimals of a token, read from the constant list, storage,
    ///      or from token.decimals(). Prefer using getSetDecimals when possible.
    /// @param token The token type
    /// @return tokenDecimals The decimals of the token
    function getDecimals(IERC20Ext token) internal view returns (uint256 tokenDecimals) {
        // return token decimals if has constant value
        tokenDecimals = getDecimalsConstant(token);
        if (tokenDecimals > 0) return tokenDecimals;

        // handle case where token decimals is not a declared decimal constant
        tokenDecimals = decimals[token];
        // moreover, very possible that old tokens have decimals 0
        // these tokens will just have higher gas fees.
        return (tokenDecimals > 0) ? tokenDecimals : token.decimals();
    }

    function calcDestAmount(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 srcAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcDstQty(srcAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcSrcAmount(
        IERC20Ext src,
        IERC20Ext dest,
        uint256 destAmount,
        uint256 rate
    ) internal view returns (uint256) {
        return calcSrcQty(destAmount, getDecimals(src), getDecimals(dest), rate);
    }

    function calcDstQty(
        uint256 srcQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(srcQty <= MAX_QTY, "srcQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return (srcQty * rate * (10**(dstDecimals - srcDecimals))) / PRECISION;
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return (srcQty * rate) / (PRECISION * (10**(srcDecimals - dstDecimals)));
        }
    }

    function calcSrcQty(
        uint256 dstQty,
        uint256 srcDecimals,
        uint256 dstDecimals,
        uint256 rate
    ) internal pure returns (uint256) {
        require(dstQty <= MAX_QTY, "dstQty > MAX_QTY");
        require(rate <= MAX_RATE, "rate > MAX_RATE");

        //source quantity is rounded up. to avoid dest quantity being too low.
        uint256 numerator;
        uint256 denominator;
        if (srcDecimals >= dstDecimals) {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            numerator = (PRECISION * dstQty * (10**(srcDecimals - dstDecimals)));
            denominator = rate;
        } else {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            numerator = (PRECISION * dstQty);
            denominator = (rate * (10**(dstDecimals - srcDecimals)));
        }
        return (numerator + denominator - 1) / denominator; //avoid rounding down errors
    }

    function calcRateFromQty(
        uint256 srcAmount,
        uint256 destAmount,
        uint256 srcDecimals,
        uint256 dstDecimals
    ) internal pure returns (uint256) {
        require(srcAmount <= MAX_QTY, "srcAmount > MAX_QTY");
        require(destAmount <= MAX_QTY, "destAmount > MAX_QTY");

        if (dstDecimals >= srcDecimals) {
            require((dstDecimals - srcDecimals) <= MAX_DECIMALS, "dst - src > MAX_DECIMALS");
            return ((destAmount * PRECISION) / ((10**(dstDecimals - srcDecimals)) * srcAmount));
        } else {
            require((srcDecimals - dstDecimals) <= MAX_DECIMALS, "src - dst > MAX_DECIMALS");
            return ((destAmount * PRECISION * (10**(srcDecimals - dstDecimals))) / srcAmount);
        }
    }

    /// @dev save storage access by declaring token decimal constants
    /// @param token The token type
    /// @return token decimals
    function getDecimalsConstant(IERC20Ext token) internal pure returns (uint256) {
        if (token == ETH_TOKEN_ADDRESS) {
            return ETH_DECIMALS;
        } else if (token == USDT_TOKEN_ADDRESS) {
            return 6;
        } else if (token == DAI_TOKEN_ADDRESS) {
            return 18;
        } else if (token == USDC_TOKEN_ADDRESS) {
            return 6;
        } else if (token == WBTC_TOKEN_ADDRESS) {
            return 8;
        } else if (token == KNC_TOKEN_ADDRESS) {
            return 18;
        } else {
            return 0;
        }
    }

    function minOf(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev Interface extending ERC20 standard to include decimals() as
 *      it is optional in the OpenZeppelin IERC20 interface.
 */
interface IERC20Ext is IERC20 {
    /**
     * @dev This function is required as Kyber requires to interact
     *      with token.decimals() with many of its operations.
     */
    function decimals() external view returns (uint8 digits);
}

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
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
pragma solidity 0.7.6;


abstract contract PermissionAdmin {
    address public admin;
    address public pendingAdmin;

    event AdminClaimed(address newAdmin, address previousAdmin);

    event TransferAdminPending(address pendingAdmin);

    constructor(address _admin) {
        require(_admin != address(0), "admin 0");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "new admin 0");
        emit TransferAdminPending(newAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0), "admin 0");
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender, "not pending");
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

