/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

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
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

interface IFireBirdPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

  function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

  function getSwapFee() external view returns (uint32);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(
    address,
    address,
    uint32,
    uint32
  ) external;
}

library Babylonian {
  function sqrt(uint256 y) internal pure returns (uint256 z) {
    if (y > 3) {
      z = y;
      uint256 x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
    // else z = 0
  }
}

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

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = uint256(1) << RESOLUTION;
  uint256 private constant Q224 = Q112 << RESOLUTION;

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  // divide a UQ112x112 by a uint112, returning a UQ112x112
  function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
    require(x != 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112(self._x / uint224(x));
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
    uint256 z;
    require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
    return uq144x112(z);
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
    require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
    return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // take the reciprocal of a UQ112x112
  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
    return uq112x112(uint224(Q224 / self._x));
  }

  // square root of a UQ112x112
  function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
  }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IFireBirdPair(pair).price0CumulativeLast();
    price1Cumulative = IFireBirdPair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IFireBirdPair(pair).getReserves();
    if (blockTimestampLast != blockTimestamp) {
      // subtraction overflow is desired
      uint32 timeElapsed = blockTimestamp - blockTimestampLast;
      uint32 tokenWeight0;
      uint32 tokenWeight1;
      try IFireBirdPair(pair).getTokenWeights() returns (uint32 _tokenWeight0, uint32 _tokenWeight1) {
        tokenWeight0 = _tokenWeight0;
        tokenWeight1 = _tokenWeight1;
      } catch {
        tokenWeight0 = 50;
        tokenWeight1 = 50;
      }

      uint112 mReserve0 = reserve0 * tokenWeight1;
      uint112 mReserve1 = reserve1 * tokenWeight0;
      // addition overflow is desired
      // counterfactual
      price0Cumulative += uint256(FixedPoint.fraction(mReserve1, mReserve0)._x) * timeElapsed;
      // counterfactual
      price1Cumulative += uint256(FixedPoint.fraction(mReserve0, mReserve1)._x) * timeElapsed;
    }
  }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0, "ds-math-division-by-zero");
    c = a / b;
  }
}

interface ISwapFeeReward {
  function swap(
    address account,
    address input,
    address output,
    uint256 amount,
    address pair
  ) external returns (bool);

  function pairsListLength() external view returns (uint256);

  function pairsList(uint256 index)
    external
    view
    returns (
      address,
      uint256,
      bool
    );
}

contract Oracle is Ownable {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  address public priceUpdater;
  uint256 public constant CYCLE = 15 minutes;

  // mapping from pair address to a list of price observations of that pair
  mapping(address => Observation) public pairObservations;
  ISwapFeeReward public swapFeeReward;
  uint256 public lastTimeAutoUpdate;

  modifier onlyPriceUpdater() {
    require(msg.sender == priceUpdater, "Oracle: only priceUpdater");
    _;
  }

  constructor(address priceUpdater_) public {
    priceUpdater = priceUpdater_;
  }

  function setSwapFeeReward(ISwapFeeReward _swapFeeReward) external onlyOwner {
    swapFeeReward = _swapFeeReward;
  }

  function changePriceUpdater(address priceUpdater_) external onlyOwner {
    priceUpdater = priceUpdater_;
  }

  function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
    require(tokenA != tokenB, "FirebirdFactory: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "FirebirdFactory: ZERO_ADDRESS");
  }

  function autoUpdate() public onlyPriceUpdater {
    uint256 timeElapsed = block.timestamp - lastTimeAutoUpdate;
    require(timeElapsed >= CYCLE, "Oracle: PERIOD_NOT_ELAPSED");
    ISwapFeeReward _swapFeeReward = swapFeeReward;

    uint256 pairLength = _swapFeeReward.pairsListLength();
    for (uint256 i = 0; i < pairLength; i++) {
      (address pair, , ) = _swapFeeReward.pairsList(i);
      try this.update(pair) {} catch {}
    }
    lastTimeAutoUpdate = block.timestamp;
  }

  function update(address pair) external {
    require(msg.sender == priceUpdater || msg.sender == address(this), "Oracle: Price can update only price updater address");

    Observation storage observation = pairObservations[pair];
    uint256 timeElapsed = block.timestamp - observation.timestamp;
    require(timeElapsed >= CYCLE, "Oracle: PERIOD_NOT_ELAPSED");
    (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    observation.timestamp = block.timestamp;
    observation.price0Cumulative = price0Cumulative;
    observation.price1Cumulative = price1Cumulative;
  }

  function computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed));
    amountOut = priceAverage.mul(amountIn).decode144();
  }

  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    address pair
  ) external view returns (uint256 amountOut) {
    Observation storage observation = pairObservations[pair];

    if (pairObservations[pair].price0Cumulative == 0 || pairObservations[pair].price1Cumulative == 0) {
      return 0;
    }

    uint256 timeElapsed = block.timestamp - observation.timestamp;
    if (timeElapsed > 12 hours) {
      //price of out date
      return 0;
    }
    (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, ) = sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return computeAmountOut(observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
    } else {
      return computeAmountOut(observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
    }
  }
}