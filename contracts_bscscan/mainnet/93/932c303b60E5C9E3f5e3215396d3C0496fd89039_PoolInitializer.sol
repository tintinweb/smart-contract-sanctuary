// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBisharesUniswapV2Oracle.sol";
import "../interfaces/IMarketCapSqrtController.sol";
import "../interfaces/IPoolInitializer.sol";


contract PoolInitializer is IPoolInitializer {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint32 internal constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 internal constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;
  uint256 internal constant TOKENS_MINTED = 1e20;
  address public immutable controller;
  mapping(address => uint256) internal _remainingDesiredAmounts;
  mapping(address => uint256) internal _credits;
  address[] internal _tokens;
  uint256 internal _totalCredit;
  bool internal _finished;
  address internal _poolAddress;
  bool internal _mutex;
  IBisharesUniswapV2Oracle public _poolOracle;

  function isFinished() external view override returns (bool) {
    return _finished;
  }

  function getTotalCredit() external view override returns (uint256) {
    return _totalCredit;
  }

  function getCreditOf(address account) external view override returns (uint256) {
    return _credits[account];
  }

  function getDesiredTokens() external view override returns (address[] memory) {
    return _tokens;
  }

  function getDesiredAmount(address token) external view override returns (uint256) {
    return _remainingDesiredAmounts[token];
  }

  function getDesiredAmounts(address[] memory tokens) external view override returns (uint256[] memory amounts) {
    amounts = new uint256[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      amounts[i] = _remainingDesiredAmounts[tokens[i]];
    }
  }

  function getCreditForTokens(
    address token,
    uint256 amountIn
  ) external view override returns (uint144 amountOut) {
    uint256 desiredAmount = _remainingDesiredAmounts[token];
    require(desiredAmount > 0, "BiShares: Desired amount is zero");
    if (amountIn > desiredAmount) {
      amountIn = desiredAmount;
    }
    amountOut = _poolOracle.computeAverageEthForTokens(
      token,
      amountIn,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
  }

  event TokensContributed(address from, address token, uint256 amount, uint256 credit);

  event TokensClaimed(address account, uint256 tokens);

  constructor(address controller_) {
    require(controller_ != address(0), "BiShares: Controller is zero address");
    controller = controller_;
  }

  function initialize(
    address poolAddress,
    address[] memory tokens,
    uint256[] memory amounts,
    IBisharesUniswapV2Oracle poolOracle
  ) external override _control_ returns (bool) {
    address zero = address(0);
    require(_poolAddress == zero, "BiShares: Already initialized");
    require(poolAddress != zero, "BiShares: Pool address is zero address");
    require(address(poolOracle) != zero, "BiShares: Pool oracle is zero address");
    _poolAddress = poolAddress;
    _poolOracle = poolOracle; 
    uint256 len = tokens.length;
    require(amounts.length == len, "BiShares: Invalid arrays length");
    _tokens = tokens;
    for (uint256 i = 0; i < len; i++) {
      _remainingDesiredAmounts[tokens[i]] = amounts[i];
    }
    return true;
  }

  function finish() external override _lock_ _not_finished_ returns (bool) {
    uint256 len = _tokens.length;
    address controller_ = controller;
    address[] memory tokens = new address[](len);
    uint256[] memory balances = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      address token = _tokens[i];
      tokens[i] = token;
      uint256 balance = IERC20(token).balanceOf(address(this));
      balances[i] = balance;
      IERC20(token).safeApprove(_poolAddress, balance);
      require(_remainingDesiredAmounts[token] == 0, "BiShares: Pending tokens is needed");
    }
    IMarketCapSqrtController(controller_).finishPreparedIndexPool(
      _poolAddress,
      tokens,
      balances
    );
    _finished = true;
    return true;
  }

  function claimTokens() external override _lock_ _finished_ returns (bool) {
    return _claimTokens(msg.sender);
  }

  function claimTokens(address account) external override _lock_ _finished_ returns (bool) {
    return _claimTokens(account);
  }

  function claimTokens(address[] memory accounts) external override _lock_ _finished_ returns (bool) {
    for (uint256 i = 0; i < accounts.length; i++) {
      _claimTokens(accounts[i]);
    }
    return true;
  }

  function contributeTokens(
    address token,
    uint256 amountIn,
    uint256 minimumCredit
  ) external override _lock_ _not_finished_ returns (uint256 credit) {
    address caller = msg.sender;
    uint256 desiredAmount = _remainingDesiredAmounts[token];
    require(desiredAmount > 0, "BiShares: Already contributed");
    if (amountIn > desiredAmount) {
      amountIn = desiredAmount;
    }
    credit = _poolOracle.computeAverageEthForTokens(
      token,
      amountIn,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    require(credit > 0 && amountIn > 0, "BiShares: Amounts too low");
    require(credit >= minimumCredit, "BiShares: Minimum credit");
    IERC20(token).safeTransferFrom(caller, address(this), amountIn);
    _remainingDesiredAmounts[token] = desiredAmount.sub(amountIn);
    _credits[caller] = _credits[caller].add(credit);
    _totalCredit = _totalCredit.add(credit);
    emit TokensContributed(caller, token, amountIn, credit);
  }

  function contributeTokens(
    address[] memory tokens,
    uint256[] memory amountsIn,
    uint256 minimumCredit
  ) external override _lock_ _not_finished_ returns (uint256 credit) {
    address caller = msg.sender;
    uint256 len = tokens.length;
    require(amountsIn.length == len, "BiShares: Invalid arrays length");
    credit = 0;
    for (uint256 i = 0; i < len; i++) {
      address token = tokens[i];
      uint256 amountIn = amountsIn[i];
      uint256 desiredAmount = _remainingDesiredAmounts[token];
      require(desiredAmount > 0, "BiShares: Already contributed");
      if (amountIn > desiredAmount) {
        amountIn = desiredAmount;
      }
      uint256 creditOut = _poolOracle.computeAverageEthForTokens(
        token,
        amountIn,
        SHORT_TWAP_MIN_TIME_ELAPSED,
        SHORT_TWAP_MAX_TIME_ELAPSED
      );
      require(creditOut > 0 && amountIn > 0, "BiShares: Amounts too low");
      IERC20(token).safeTransferFrom(caller, address(this), amountIn);
      _remainingDesiredAmounts[token] = desiredAmount.sub(amountIn);
      credit = credit.add(creditOut);
      emit TokensContributed(caller, token, amountIn, creditOut);
    }
    require(credit >= minimumCredit, "BiShares: Minimum credit");
    _credits[caller] = _credits[caller].add(credit);
    _totalCredit = _totalCredit.add(credit);
  }

  function updatePrices() external override returns (bool) {
    _poolOracle.updatePrices(_tokens);
    return true;
  }

  function _claimTokens(address account) internal returns (bool) {
    uint256 credit = _credits[account];
    require(credit > 0, "BiShares: Credit is zero");
    uint256 amountOut = (TOKENS_MINTED.mul(credit)).div(_totalCredit);
    _credits[account] = 0;
    IERC20(_poolAddress).safeTransfer(account, amountOut);
    emit TokensClaimed(account, amountOut);
    return true;
  }

  modifier _lock_ {
    require(!_mutex, "BiShares: Locked");
    _mutex = true;
    _;
    _mutex = false;
  }

  modifier _control_ {
    require(msg.sender == controller, "BiShares: Caller is not controller");
    _;
  }

  modifier _finished_ {
    require(_finished, "BiShares: Not finished");
    _;
  }

  modifier _not_finished_ {
    require(!_finished, "BiShares: Already finished");
    _;
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
      // counterfactual
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

import "./FixedPoint.sol";
import "./UniswapV2OracleLibrary.sol";
import "./UniswapV2Library.sol";


library PriceLibrary {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  struct PriceObservation {
    uint32 timestamp;
    uint224 priceCumulativeLast;
    uint224 ethPriceCumulativeLast;
  }

  struct TwoWayAveragePrice {
    uint224 priceAverage;
    uint224 ethPriceAverage;
  }

  function pairInitialized(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (bool) {
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token, weth);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();
    return reserve0 != 0 && reserve1 != 0;
  }

  function observePrice(
    address uniswapFactory,
    address tokenIn,
    address quoteToken
  ) internal view returns (uint32, uint224) {
    (address token0, address token1) = UniswapV2Library.sortTokens(tokenIn, quoteToken);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    if (token0 == tokenIn) {
      (uint256 price0Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice0(pair);
      return (blockTimestamp, uint224(price0Cumulative));
    } else {
      (uint256 price1Cumulative, uint32 blockTimestamp) = UniswapV2OracleLibrary.currentCumulativePrice1(pair);
      return (blockTimestamp, uint224(price1Cumulative));
    }
  }

  function observeTwoWayPrice(
    address uniswapFactory,
    address token,
    address weth
  ) internal view returns (PriceObservation memory) {
    (address token0, address token1) = UniswapV2Library.sortTokens(token, weth);
    IUniswapFactory factory = IUniswapFactory(uniswapFactory);
    address pair = factory.getPair(token0, token1);
    (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    if (token0 == token) {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price0Cumulative),
        ethPriceCumulativeLast: uint224(price1Cumulative)
      });
    } else {
      return PriceObservation({
        timestamp: blockTimestamp,
        priceCumulativeLast: uint224(price1Cumulative),
        ethPriceCumulativeLast: uint224(price0Cumulative)
      });
    }
  }

  function computeTwoWayAveragePrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (TwoWayAveragePrice memory) {
    uint32 timeElapsed = uint32(observation2.timestamp - observation1.timestamp);
    FixedPoint.uq112x112 memory priceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      timeElapsed
    );
    FixedPoint.uq112x112 memory ethPriceAverage = UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      timeElapsed
    );
    return TwoWayAveragePrice({
      priceAverage: priceAverage._x,
      ethPriceAverage: ethPriceAverage._x
    });
  }

  function computeAveragePrice(
    uint32 timestampStart,
    uint224 priceCumulativeStart,
    uint32 timestampEnd,
    uint224 priceCumulativeEnd
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      priceCumulativeStart,
      priceCumulativeEnd,
      uint32(timestampEnd - timestampStart)
    );
  }

  function computeAverageTokenPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.priceCumulativeLast,
      observation2.priceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  function computeAverageEthPrice(
    PriceObservation memory observation1,
    PriceObservation memory observation2
  ) internal pure returns (FixedPoint.uq112x112 memory) {
    return UniswapV2OracleLibrary.computeAveragePrice(
      observation1.ethPriceCumulativeLast,
      observation2.ethPriceCumulativeLast,
      uint32(observation2.timestamp - observation1.timestamp)
    );
  }

  function computeAverageEthForTokens(
    TwoWayAveragePrice memory prices,
    uint256 tokenAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.priceAverage).mul(tokenAmount).decode144();
  }

  function computeAverageTokensForEth(
    TwoWayAveragePrice memory prices,
    uint256 wethAmount
  ) internal pure returns (uint144) {
    return FixedPoint.uq112x112(prices.ethPriceAverage).mul(wethAmount).decode144();
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

interface IUniswapV2Pair {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
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

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./IBisharesUniswapV2Oracle.sol";


interface IPoolInitializer {
  function initialize(
    address poolAddress,
    address[] memory tokens,
    uint256[] memory amounts,
    IBisharesUniswapV2Oracle oracle
  ) external returns (bool);
  function finish() external returns (bool);
  function claimTokens() external returns (bool);
  function claimTokens(address account) external returns (bool);
  function claimTokens(address[] memory accounts) external returns (bool);
  function contributeTokens(
    address token,
    uint256 amountIn,
    uint256 minimumCredit
  ) external returns (uint256);
  function contributeTokens(
    address[] memory tokens,
    uint256[] memory amountsIn,
    uint256 minimumCredit
  ) external returns (uint256);
  function updatePrices() external returns (bool);

  function isFinished() external view returns (bool);
  function getTotalCredit() external view returns (uint256);
  function getCreditOf(address account) external view returns (uint256);
  function getDesiredTokens() external view returns (address[] memory);
  function getDesiredAmount(address token) external view returns (uint256);
  function getDesiredAmounts(address[] memory tokens) external view returns (uint256[] memory);
  function getCreditForTokens(address token, uint256 amountIn) external view returns (uint144);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./IBisharesUniswapV2Oracle.sol";


interface IMarketCapSqrtController {
  function categoryIndex() external view returns (uint256);
  function computeAverageMarketCap(address token, IBisharesUniswapV2Oracle oracle) external view returns (uint144);
  function computeAverageMarketCaps(
    address[] memory tokens,
    IBisharesUniswapV2Oracle oracle
  ) external view returns (uint144[] memory);
  function hasCategory(uint256 categoryID) external view returns (bool);
  function getLastCategoryUpdate(uint256 categoryID) external view returns (uint256);
  function isTokenInCategory(uint256 categoryID, address token) external view returns (bool);
  function getCategoryTokens(uint256 categoryID) external view returns (address[] memory);
  function getCategoryMarketCaps(uint256 categoryID) external view returns (uint144[] memory);
  function getTopCategoryTokens(uint256 categoryID, uint256 num) external view returns (address[] memory);

  event CategoryAdded(uint256 categoryID, bytes32 metadataHash);
  event CategorySorted(uint256 categoryID);
  event TokenAdded(address token, uint256 categoryID);
  event PoolInitialized(
    address pool,
    address unboundTokenSeller,
    uint256 categoryID,
    uint256 indexSize
  );
  event NewPoolInitializer(address pool, address initializer);

  function updateCategoryPrices(uint256 categoryID) external returns (bool[] memory pricesUpdated);
  function createCategory(
    bytes32 metadataHash,
    IBisharesUniswapV2Oracle oracle,
    address router
  ) external returns (bool);
  function addToken(uint256 categoryID, address token) external returns (bool);
  function addTokens(uint256 categoryID, address[] memory tokens) external returns (bool);
  function removeToken(uint256 categoryID, address token) external returns (bool);
  function orderCategoryTokensByMarketCap(uint256 categoryID) external returns (bool);
  function prepareIndexPool(
    uint256 categoryID,
    uint256 indexSize,
    uint256 initialWethValue,
    string memory name,
    string memory symbol
  ) external returns (address poolAddress, address initializerAddress);
  function finishPreparedIndexPool(
    address poolAddress,
    address[] memory tokens,
    uint256[] memory balances
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../lib/PriceLibrary.sol";
import "../lib/FixedPoint.sol";


interface IBisharesUniswapV2Oracle {
  function hasPriceObservationInWindow(address token, uint256 priceKey) external view returns (bool);
  function getPriceObservationInWindow(
    address token, uint256 priceKey
  ) external view returns (PriceLibrary.PriceObservation memory);
  function getPriceObservationsInRange(
    address token, uint256 timeFrom, uint256 timeTo
  ) external view returns (PriceLibrary.PriceObservation[] memory prices);
  function canUpdatePrice(address token) external view returns (bool);
  function canUpdatePrices(address[] memory tokens) external view returns (bool[] memory);
  function computeTwoWayAveragePrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice memory);
  function computeAverageTokenPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeAverageEthPrice(
    address token, uint256 minTimeElapsed, uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112 memory);
  function computeTwoWayAveragePrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (PriceLibrary.TwoWayAveragePrice[] memory);
  function computeAverageTokenPrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthPrices(
    address[] memory tokens,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (FixedPoint.uq112x112[] memory);
  function computeAverageEthForTokens(
    address token,
    uint256 tokenAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);
  function computeAverageTokensForEth(
    address token,
    uint256 wethAmount,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144);
  function computeAverageEthForTokens(
    address[] memory tokens,
    uint256[] memory tokenAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);
  function computeAverageTokensForEth(
    address[] memory tokens,
    uint256[] memory wethAmounts,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  ) external view returns (uint144[] memory);

  function updatePrice(address token) external returns (bool);
  function updatePrices(address[] memory tokens) external returns (bool[] memory);
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