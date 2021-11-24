// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";
import "../interfaces/IBisharesUniswapV2Oracle.sol";

contract BisharesUniswapV2Oracle is IBisharesUniswapV2Oracle {
  using PriceLibrary for address;
  using PriceLibrary for PriceLibrary.PriceObservation;
  using PriceLibrary for PriceLibrary.TwoWayAveragePrice;
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  address internal immutable _weth;

  constructor(address weth) {
    require(weth != address(0), "BiShares: WETH is zero address");
    _weth = weth;
  }

  function computeTwoWayAveragePrice(
		address factory,
    address token
  ) external view override returns (PriceLibrary.TwoWayAveragePrice memory) {
    return _getTwoWayPrice(factory, token);
  }

  function computeAverageTokenPrice(
		address factory,
    address token
  ) external view override returns (FixedPoint.uq112x112 memory priceAverage) {
    return _getTokenPrice(factory, token);
  }

  function computeAverageEthPrice(
		address factory,
    address token
  ) external view override returns (FixedPoint.uq112x112 memory priceAverage) {
    return _getEthPrice(factory, token);
  }

  function computeTwoWayAveragePrices(
		address[] memory factories,
    address[] memory tokens
  ) external view override returns (PriceLibrary.TwoWayAveragePrice[] memory prices) {
		uint256 len = factories.length;
		require(tokens.length == len, "BiShares: computeTwoWayAveragePrices: Invalid arrays length");
    prices = new PriceLibrary.TwoWayAveragePrice[](len);
    for (uint256 i = 0; i < len; i++) {
      prices[i] = _getTwoWayPrice(factories[i], tokens[i]);
    }
  }

  function computeAverageTokenPrices(
		address[] memory factories,
    address[] memory tokens
  ) external view override returns (FixedPoint.uq112x112[] memory averagePrices) {
		uint256 len = factories.length;
		require(tokens.length == len, "BiShares: computeAverageTokenPrices: Invalid arrays length");
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getTokenPrice(factories[i], tokens[i]);
    }
  }

  function computeAverageEthPrices(
		address[] memory factories,
    address[] memory tokens
  ) external view override returns (FixedPoint.uq112x112[] memory averagePrices) {
		uint256 len = factories.length;
		require(tokens.length == len, "BiShares: computeAverageEthPrices: Invalid arrays length");
    averagePrices = new FixedPoint.uq112x112[](len);
    for (uint256 i = 0; i < len; i++) {
      averagePrices[i] = _getEthPrice(factories[i], tokens[i]);
    }
  }

  function computeAverageEthForTokens(
    address factory,
		address token,
    uint256 tokenAmount
  ) external view override returns (uint144) {
    FixedPoint.uq112x112 memory tokenPrice = _getTokenPrice(factory, token);
    return tokenPrice.mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
		address factory,
    address token,
    uint256 wethAmount
  ) external view override returns (uint144) {
    FixedPoint.uq112x112 memory ethPrice = _getEthPrice(factory, token);
    return ethPrice.mul(wethAmount).decode144();
  }

  function computeAverageEthForTokens(
		address[] memory factories,
    address[] memory tokens,
    uint256[] memory tokenAmounts
  ) external view override returns (uint144[] memory averageValuesInWETH) {
		uint256 len = factories.length;
		require(
      tokens.length == len && tokenAmounts.length == len,
      "BiShares::computeAverageEthForTokens: Invalid arrays length"
    );
    averageValuesInWETH = new uint144[](len);
    for (uint256 i = 0; i < len; i++) {
      averageValuesInWETH[i] = _getTokenPrice(
				factories[i],
        tokens[i]
      ).mul(tokenAmounts[i]).decode144();
    }
  }

  function computeAverageTokensForEth(
		address[] memory factories,
    address[] memory tokens,
    uint256[] memory wethAmounts
  ) external view override returns (uint144[] memory averageValuesInWETH) {
		uint256 len = factories.length;
		require(
      tokens.length == len && wethAmounts.length == len,
      "BiShares::computeAverageTokensForEth: Invalid arrays length"
    );
    averageValuesInWETH = new uint144[](len);
    for (uint256 i = 0; i < len; i++) {
      averageValuesInWETH[i] = _getEthPrice(
				factories[i],
        tokens[i]
      ).mul(wethAmounts[i]).decode144();
    }
  }

  function _getTwoWayPrice(
		address factory,
    address token
  ) internal view returns (PriceLibrary.TwoWayAveragePrice memory) {
    if (token == _weth) return PriceLibrary.TwoWayAveragePrice(
      FixedPoint.encode(1)._x,
      FixedPoint.encode(1)._x
    );
    PriceLibrary.PriceObservation memory current = factory.observeTwoWayPrice(token, _weth);
    return PriceLibrary.TwoWayAveragePrice({
      priceAverage: current.priceCumulativeLast,
      ethPriceAverage: current.ethPriceCumulativeLast
    });
  }

  function _getTokenPrice(
		address factory,
    address token
  ) internal view returns (FixedPoint.uq112x112 memory) {
    if (token == _weth) return FixedPoint.fraction(1, 1);
    (, uint224 priceCumulativeEnd) = factory.observePrice(token, _weth, false);
    return FixedPoint.uq112x112(priceCumulativeEnd);
  }

  function _getEthPrice(
		address factory,
    address token
  ) internal view returns (FixedPoint.uq112x112 memory) {
    if (token == _weth) return FixedPoint.fraction(1, 1);
    (, uint224 priceCumulativeEnd) = factory.observePrice(_weth, token, true);
    return FixedPoint.uq112x112(priceCumulativeEnd);
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