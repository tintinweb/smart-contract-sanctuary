// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import "../core/balancer/BNum.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IIndexPool.sol";
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IZapUniswapV2.sol";
import "../lib/TransferHelper.sol";


contract BisharesZapUniswapRouterMinter is BNum {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public immutable weth;
  IBisharesUniswapV2Oracle public immutable oracle;
  IZapUniswapV2 public immutable zapper;

  constructor(address weth_, address oracle_, address zapper_) {
    address zero = address(0);
    require(weth_ != zero, "BiShares: WETH is zero address");
    require(oracle_ != zero, "BiShares: Oracle is zero address");
    require(zapper_ != zero, "BiShares: Zapper is zero address");
    weth = weth_;
    oracle = IBisharesUniswapV2Oracle(oracle_);
    zapper = IZapUniswapV2(zapper_);
  }

  receive() external payable {
    require(msg.sender == weth, "BiShares: Received ether");
  }

  function swapETHForVaultsAndMint(
    address indexPool
  ) external payable returns (uint256 poolAmountOut) {
    address caller = msg.sender;
    uint256 initialAmount = msg.value;
    address this_ = address(this);
    (
      address[] memory vaults,
      address[] memory routers,
      uint256[] memory amountsIn
    ) = _getIndexPoolData(indexPool, initialAmount);
    poolAmountOut = _joinPool(indexPool, initialAmount, vaults, routers, amountsIn);
    TransferHelper.safeTransfer(indexPool, caller, poolAmountOut);
    uint256 wethBalance = IERC20(weth).balanceOf(this_);
    if (wethBalance > 0) IWETH(weth).withdraw(wethBalance);
    TransferHelper.safeTransferETH(caller, this_.balance);
  }

  function _joinPool(
    address indexPool,
    uint256 amountMax,
    address[] memory vaults,
    address[] memory routers,
    uint256[] memory amountsIn
  ) private returns (uint256 poolAmountOut) {
    poolAmountOut = uint256(-1);
    uint256[] memory amountsToPool = new uint256[](vaults.length);
    for (uint256 i = 0; i < vaults.length; i++) {
      (amountMax, amountsToPool[i], poolAmountOut) = _zapIn(
        indexPool,
        amountMax,
        poolAmountOut,
        amountsIn[i],
        routers[i],
        vaults[i]
      );
    }
    poolAmountOut = poolAmountOut.mul(999).div(1000);
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    _zapOutVaultsToETH(vaults, routers);
  }

  function _zapIn(
    address indexPool,
    uint256 amountMax,
    uint256 poolAmountOut,
    uint256 amountIn,
    address router,
    address vault
  ) private returns (uint256, uint256, uint256) {
    address zapperAddress = address(zapper);
    IWETH(weth).deposit{value: amountIn}();
    TransferHelper.safeApprove(weth, zapperAddress, amountIn);
    amountMax = SafeMath.sub(amountMax, amountIn, "BiShares: Excessive input amount");
    uint256 amountToPool = zapper.zapIn(router, vault, amountIn, 1);
    TransferHelper.safeApprove(vault, indexPool, amountToPool);
    poolAmountOut = Math.min(
      poolAmountOut,
      bmul(
        bdiv(
          amountToPool,
          IIndexPool(indexPool).getTokenRecord(vault).balance
        ),
        IERC20(indexPool).totalSupply()
      )
    );
    address[] memory tokens = new address[](2);
    IStrategy strategy = IStrategy(IVault(vault).strategy());
    tokens[0] = strategy.lpToken0();
    tokens[1] = strategy.lpToken1();
    _returnAssets(tokens);
    return (amountMax, amountToPool, poolAmountOut);
  }

  function _getIndexPoolData(
    address indexPool,
    uint256 initialAmount
  ) private view returns (address[] memory vaults, address[] memory routers, uint256[] memory amountsIn) {
    address[] memory factories = IIndexPool(indexPool).factories();
    vaults = IIndexPool(indexPool).getCurrentTokens();
    routers = IIndexPool(indexPool).routers();
    uint256 length = vaults.length;
    amountsIn = new uint256[](length);
    uint256 sum = 0;
    for (uint256 i = 0; i < length; i++) {
      uint256 balanceInNative = oracle.computeAverageEthForTokens(
        factories[i],
        vaults[i],
        IIndexPool(indexPool).getBalance(vaults[i])
      );
      amountsIn[i] = balanceInNative;
      sum = sum.add(balanceInNative);
    }
    for (uint256 j = 0; j < length; j++) amountsIn[j] = amountsIn[j].mul(initialAmount).div(sum);
    return (vaults, routers, amountsIn);
  }

  function _returnAssets(address[] memory tokens) private {
    address caller = msg.sender;
    address this_ = address(this);
    uint256 balance = 0;
    for (uint256 i; i < tokens.length; i++) {
      address token = tokens[i];
      balance = IERC20(token).balanceOf(this_);
      if (balance > 0) IERC20(token).safeTransfer(caller, balance);
    }
  }

  function _zapOutVaultsToETH(
    address[] memory vaults,
    address[] memory routers
  ) private returns (uint256 cumulativeAmount) {
    uint256 balance;
    address this_ = address(this);
    address zapperAddress = address(zapper);
    uint256 min = 1;
    for (uint256 i = 0; i < vaults.length; i++) {
      address vault = vaults[i];
      balance = IERC20(vault).balanceOf(this_);
      if (balance > 0) {
        TransferHelper.safeApprove(vault, zapperAddress, balance);
        cumulativeAmount += zapper.zapOut(routers[i], vault, balance, weth, min);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "../interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";


library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  function currentCumulativePrices(
    address pair
  ) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrices: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function currentCumulativePrice0(
    address pair
  ) internal view returns (uint256 price0Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice0: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price0Cumulative += (
        uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
        timeElapsed
      );
    }
  }

  function currentCumulativePrice1(
    address pair
  ) internal view returns (uint256 price1Cumulative, uint32 blockTimestamp) {
    blockTimestamp = currentBlockTimestamp();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();
    (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    ) = IUniswapV2Pair(pair).getReserves();
    require(
      reserve0 != 0 && reserve1 != 0,
      "UniswapV2OracleLibrary::currentCumulativePrice1: Pair has no reserves."
    );
    if (blockTimestampLast != blockTimestamp) {
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      price1Cumulative += (
        uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
        timeElapsed
      );
    }
  }

  function computeAveragePrice(
    uint224 priceCumulativeStart,
    uint224 priceCumulativeEnd,
    uint32 timeElapsed
  ) internal pure returns (FixedPoint.uq112x112 memory priceAverage) {
    priceAverage = FixedPoint.uq112x112(
      uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/IUniswapV2Pair.sol";


interface IUniswapFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

library UniswapV2Library {
  using SafeMath for uint256;

  function sortTokens(
    address tokenA,
    address tokenB
  ) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal view returns (address pair) {
    IUniswapFactory _factory = IUniswapFactory(factory);
    pair = _factory.getPair(token0, token1);
  }

  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }

  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0
      ? (reserve0, reserve1)
      : (reserve1, reserve0);
  }

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(
      reserveA > 0 && reserveB > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    amountB = amountA.mul(reserveB) / reserveA;
  }

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
    );
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";
import "../interfaces/IVault.sol";


library PriceLibrary {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  uint256 private constant PRECISION = 1e18;

  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  struct TwoWayAveragePrice {
    uint224 priceAverage;
    uint224 ethPriceAverage;
  }

  function computeAverageEthForTokens(
    PriceLibrary.TwoWayAveragePrice memory prices,
    uint256 tokenAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.priceAverage).mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
    PriceLibrary.TwoWayAveragePrice memory prices,
    uint256 wethAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.ethPriceAverage).mul(wethAmount).decode144();
  }

  function pairInitialized(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (bool isInitialized) {
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    IUniswapV2Pair vaultLP = IUniswapV2Pair(address(IVault(token).token()));
		isInitialized = _checkPairReserves(factory, vaultLP.token0(), weth);
		if (!isInitialized) {
			isInitialized = _checkPairReserves(factory, vaultLP.token1(), weth);
		}
  }

  function observePrice(
    address uniswapFactory,
    address tokenIn,
    address quoteToken,
		bool reversed
  ) internal view returns (uint32 timestamp, uint224 priceCumulativeLast) {
    uint256 lpReservesInQuote;
    (tokenIn, quoteToken) = reversed ? (quoteToken, tokenIn) : (tokenIn, quoteToken);
    IVault vault = IVault(tokenIn);
    IUniswapV2Pair vaultLP = IUniswapV2Pair(address(vault.token()));
    uint256 vaultPrice = vault.getPricePerFullShare();
    uint256 vaultLPTotalSupply = vaultLP.totalSupply();
    (timestamp, lpReservesInQuote) = _calculateVaultLPReservesInQuote(
      uniswapFactory,
      vaultLP,
      quoteToken
    );
    priceCumulativeLast = reversed
      ? _calculatePriceCumulativeLast(vaultLPTotalSupply, lpReservesInQuote, PRECISION, vaultPrice)
      : _calculatePriceCumulativeLast(lpReservesInQuote, vaultLPTotalSupply, vaultPrice, PRECISION);
  }

  function observeTwoWayPrice(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (PriceLibrary.PriceObservation memory) {
    IVault vault = IVault(token);
    IUniswapV2Pair vaultLP = IUniswapV2Pair(address(vault.token()));
    uint256 vaultPrice = vault.getPricePerFullShare();
    uint256 vaultLPTotalSupply = vaultLP.totalSupply();
    (uint32 blockTimestamp, uint256 lpReservesInQuote) = _calculateVaultLPReservesInQuote(
      uniswapFactory,
      vaultLP,
      weth
    );
		return PriceLibrary.PriceObservation({
			timestamp: blockTimestamp,
			priceCumulativeLast: _calculatePriceCumulativeLast(
        lpReservesInQuote,
        vaultLPTotalSupply,
        vaultPrice,
        PRECISION
      ),
			ethPriceCumulativeLast: _calculatePriceCumulativeLast(
        vaultLPTotalSupply,
        lpReservesInQuote,
        PRECISION,
        vaultPrice
      )
		});
  }

  function _isLPReady(address token0, address token1, address quote) private pure returns (bool) {
    return quote == token1 || quote == token0; 
  }

  function _calculatePriceCumulativeLast(
    uint256 rateNominator,
    uint256 rateDenominator,
    uint256 rateMultiplier,
    uint256 rateDivider
  ) private pure returns (uint224 priceCumulativeLast) {
    uint256 rate = rateNominator.mul(PRECISION).div(rateDenominator);
    priceCumulativeLast = uint224(rate.mul(rateMultiplier).div(rateDivider).mul(2 ** 112).div(PRECISION));
  }

  function _calculateReservesForPrice(
    address factory,
    address token0,
    address token1,
    address quote
  ) private view returns (bool isToken0, uint256 tokenReserve, uint256 quoteReserve) {
    uint256 token0Reserve = 0;
    uint256 quoteReserve0 = 0;
    uint256 token1Reserve = 0;
    uint256 quoteReserve1 = 0;
    address zero = address(0);
    if (UniswapV2Library.pairFor(factory, token0, quote) != zero) {
      (token0Reserve, quoteReserve0) = UniswapV2Library.getReserves(factory, token0, quote);
    }
    if (UniswapV2Library.pairFor(factory, token1, quote) != zero) {
      (token1Reserve, quoteReserve1) = UniswapV2Library.getReserves(factory, token1, quote);
    }
    isToken0 = quoteReserve0 > quoteReserve1;
    if (isToken0) {
      tokenReserve = token0Reserve;
      quoteReserve = quoteReserve0;
    } else {
      tokenReserve = token1Reserve;
      quoteReserve = quoteReserve1;
    }
  }

  function _calculateVaultLPReservesInQuote(
    address factory,
    IUniswapV2Pair vaultLP,
    address quote
  ) private view returns (uint32 timestamp, uint256 lpReservesInQuote) {
    address token0 = vaultLP.token0();
    address token1 = vaultLP.token1();
    uint112 vaultLPReserve0;
    uint112 vaultLPReserve1;
    (vaultLPReserve0, vaultLPReserve1, timestamp) = vaultLP.getReserves();
    if (_isLPReady(token0, token1, quote)) {
      lpReservesInQuote = uint256(
        vaultLP.token0() == quote
          ? vaultLPReserve0
          : vaultLPReserve1
      ).mul(2);
    } else {
      (bool isToken0, uint256 tokenReserve, uint256 quoteReserve) = _calculateReservesForPrice(
        factory,
        token0,
        token1,
        quote
      );
      uint256 tokenToQuotePrice = quoteReserve.mul(PRECISION).div(tokenReserve);
      lpReservesInQuote = uint256(isToken0 ? vaultLPReserve0 : vaultLPReserve1)
        .mul(tokenToQuotePrice)
        .mul(2)
        .div(PRECISION);
    }
  }

	function _checkPairReserves(
		IUniswapFactory factory,
		address token,
		address quoteToken
	) private view returns (bool isPositiveReserve) {
		if (token != quoteToken) {
			address pair = factory.getPair(token, quoteToken);
			(uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
			isPositiveReserve = reserve0 != 0 && reserve1 != 0;
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


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

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = uint256(1) << RESOLUTION;
  uint256 private constant Q224 = Q112 << RESOLUTION;

  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112(self._x / uint224(x));
  }

  function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
    uint256 z;
    require(
      y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
      "FixedPoint: MULTIPLICATION_OVERFLOW"
    );
    return uq144x112(z);
  }

  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
  }

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uq112x112(uint224(Q224 / self._x));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IZapUniswapV2 {
    function zapIn(
        address router,
        address vault,
        uint256 valueAmount,
        uint256 vaultAmountOutMin
    ) external returns (uint256 vaultAmount);

    function zapOut(
        address router,
        address vault,
        uint256 withdrawAmount,
        address desiredToken,
        uint256 desiredTokenOutMin
    ) external returns (uint256 desiredTokenAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


interface IVault is IERC20 {
    function getPricePerFullShare() external view returns (uint256);
    function token() external view returns (IERC20);
    function strategy() external view returns (address);

    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 shares) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

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
    function swapFee() external view returns (uint); // Biswap support

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IStrategy {
    function balanceOf() external view returns (uint256);
    function lpToken0() external view returns (address);
    function lpToken1() external view returns (address);

    function deposit() external returns (bool);
    function withdraw(uint256 _amount) external returns (bool);
    function retireStrat() external returns (bool);
    function harvest() external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface IIndexPool {
  /**
   * @dev Token record data structure
   * @param bound is token bound to pool
   * @param ready has token been initialized
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param desiredDenorm desired denormalized weight (used for incremental changes)
   * @param index index of address in tokens array
   * @param balance token balance
   */
  struct Record {
    bool bound;
    bool ready;
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint96 desiredDenorm;
    uint8 index;
    uint256 balance;
  }

  function configure(
    address controller,
    string memory name,
    string memory symbol,
    address[] memory uniswapV2Factories,
    address[] memory uniswapV2Routers,
    address uniswapV2Oracle
  ) external returns (bool);
  function initialize(
    address[] memory tokens,
    uint256[] memory balances,
    uint96[] memory denorms,
    address tokenProvider
  ) external returns (bool);
  function setMaxPoolTokens(uint256 maxPoolTokens) external returns (bool);
  function delegateCompLikeToken(address token, address delegatee) external returns (bool);
  function reweighTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms
  ) external returns (bool);
  function reindexTokens(
    address[] memory tokens,
    uint96[] memory desiredDenorms,
    uint256[] memory minimumBalances
  ) external returns (bool);
  function setMinimumBalance(address token, uint256 minimumBalance) external returns (bool);
  function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn) external returns (bool);
  function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut) external returns (bool);

  function oracle() external view returns (address);
  function routers() external view returns (address[] memory);
  function factories() external view returns (address[] memory);
  function isPublicSwap() external view returns (bool);
  function getController() external view returns (address);
  function getMaxPoolTokens() external view returns (uint256);
  function isBound(address t) external view returns (bool);
  function getNumTokens() external view returns (uint256);
  function getCurrentTokens() external view returns (address[] memory);
  function getCurrentDesiredTokens() external view returns (address[] memory tokens);
  function getDenormalizedWeight(address token) external view returns (uint256);
  function getTokenRecord(address token) external view returns (Record memory record);
  function extrapolatePoolValueFromToken() external view returns (address, address, uint256);
  function getTotalDenormalizedWeight() external view returns (uint256);
  function getBalance(address token) external view returns (uint256);
  function getMinimumBalance(address token) external view returns (uint256);
  function getUsedBalance(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IBisharesUniswapV2Oracle {
  function computeTwoWayAveragePrice(
    address factory,
		address token
  ) external view returns (PriceLibrary.TwoWayAveragePrice memory);
  function computeAverageTokenPrice(
    address factory,
		address token
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeAverageEthPrice(
    address factory,
		address token
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeTwoWayAveragePrices(
		address[] memory factories,
    address[] memory tokens
  ) external view returns (PriceLibrary.TwoWayAveragePrice[] memory);
  function computeAverageTokenPrices(
		address[] memory factories,
    address[] memory tokens
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthPrices(
		address[] memory factories,
    address[] memory tokens
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthForTokens(
    address factory,
    address token,
    uint256 tokenAmount
  ) external view returns (uint144);
  function computeAverageTokensForEth(
    address factory,
    address token,
    uint256 wethAmount
  ) external view returns (uint144);
  function computeAverageEthForTokens(
		address[] memory factories,
    address[] memory tokens,
    uint256[] memory tokenAmounts
  ) external view returns (uint144[] memory);
  function computeAverageTokensForEth(
		address[] memory factories,
    address[] memory tokens,
    uint256[] memory wethAmounts
  ) external view returns (uint144[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./BConst.sol";


contract BNum is BConst {
  function btoi(uint256 a) internal pure returns (uint256) {
    return a / BONE;
  }

  function bfloor(uint256 a) internal pure returns (uint256) {
    return btoi(a) * BONE;
  }

  function badd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "BiShares: Add overflow");
    return c;
  }

  function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
    (uint256 c, bool flag) = bsubSign(a, b);
    require(!flag, "BiShares: Sub overflow");
    return c;
  }

  function bsubSign(uint256 a, uint256 b)
    internal
    pure
    returns (uint256, bool)
  {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "BiShares: Mul overflow");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "BiShares: Mul overflow");
    uint256 c2 = c1 / BONE;
    return c2;
  }

  function bdiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "BiShares: Div zero");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "BiShares: Div overflow");
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "BiShares: Div overflow");
    uint256 c2 = c1 / b;
    return c2;
  }

  function bpowi(uint256 a, uint256 n) internal pure returns (uint256) {
    uint256 z = n % 2 != 0 ? a : BONE;
    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);
      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  function bpow(uint256 base, uint256 exp) internal pure returns (uint256) {
    require(base >= MIN_BPOW_BASE, "BiShares: Bpow base too low");
    require(base <= MAX_BPOW_BASE, "BiShares: Bpow base too high");
    uint256 whole = bfloor(exp);
    uint256 remain = bsub(exp, whole);
    uint256 wholePow = bpowi(base, btoi(whole));
    if (remain == 0) {
      return wholePow;
    }
    uint256 partialResult = bpowApprox(base, remain, BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint256 base,
    uint256 exp,
    uint256 precision
  ) internal pure returns (uint256) {
    uint256 a = exp;
    (uint256 x, bool xneg) = bsubSign(base, BONE);
    uint256 term = BONE;
    uint256 sum = term;
    bool negative = false;
    for (uint256 i = 1; term >= precision; i++) {
      uint256 bigK = i * BONE;
      (uint256 c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract BConst {
  uint256 internal constant WEIGHT_UPDATE_DELAY = 1 hours;
  uint256 internal constant WEIGHT_CHANGE_PCT = BONE / 100;
  uint256 internal constant BONE = 10**18;
  uint256 internal constant MIN_BOUND_TOKENS = 2;
  uint256 internal constant MAX_BOUND_TOKENS = 25;
  uint256 internal constant EXIT_FEE = 0;
  uint256 internal constant MIN_WEIGHT = BONE / 8;
  uint256 internal constant MAX_WEIGHT = BONE * 25;
  uint256 internal constant MAX_TOTAL_WEIGHT = BONE * 26;
  uint256 internal constant MIN_BALANCE = BONE / 10**12;
  uint256 internal constant INIT_POOL_SUPPLY = BONE * 100;
  uint256 internal constant MIN_BPOW_BASE = 1 wei;
  uint256 internal constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint256 internal constant BPOW_PRECISION = BONE / 10**10;
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