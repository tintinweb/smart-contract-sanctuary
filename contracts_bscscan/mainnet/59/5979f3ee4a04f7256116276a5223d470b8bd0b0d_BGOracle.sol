/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.6.0;

interface IUniswapV2Pair {
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

pragma solidity >=0.4.0;

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
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

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
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
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
}

pragma solidity >=0.5.0;


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

pragma solidity ^0.6.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity =0.6.6;


contract BGOracle {
    
    using FixedPoint for *;
    uint public constant PERIOD = 24 hours;
    
    IUniswapV2Pair public iUniswapV2Pair;
    IUniswapV2Factory iUniswapV2Factory;
    uint32  public blockTimestampLast;

    struct oraclePairInfo {
        address token0;
        address token1;
        uint price0CumulativeLast;
        uint price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }
    mapping (address => oraclePairInfo) oraclePairMapping;    
    address[] _pairs;

    constructor(address factory) public {
        iUniswapV2Factory = IUniswapV2Factory(factory);
    }

    function setPairInfo(address tokenA, address tokenB) public  {
        address _pair = iUniswapV2Factory.getPair(tokenA, tokenB);
        iUniswapV2Pair = IUniswapV2Pair(_pair);
        oraclePairMapping[_pair].token0 = iUniswapV2Pair.token0();
        oraclePairMapping[_pair].token1 = iUniswapV2Pair.token1();
        oraclePairMapping[_pair].price0CumulativeLast = iUniswapV2Pair.price0CumulativeLast(); 
        oraclePairMapping[_pair].price1CumulativeLast = iUniswapV2Pair.price1CumulativeLast();
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = iUniswapV2Pair.getReserves();
        oraclePairMapping[_pair].blockTimestampLast = blockTimestampLast;
        _pairs.push(_pair);
        // require(reserve0 != 0 && reserve1 != 0, 'ExampleOracleSimple: NO_RESERVES');
    }

    function update(address _pair) external {
        iUniswapV2Pair = IUniswapV2Pair(_pair);
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(iUniswapV2Pair));
        uint32 timeElapsed = blockTimestamp - oraclePairMapping[_pair].blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        require(timeElapsed >= PERIOD, 'ExampleOracleSimple: PERIOD_NOT_ELAPSED');

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        oraclePairMapping[_pair].price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - oraclePairMapping[_pair].price0CumulativeLast) / timeElapsed));
        oraclePairMapping[_pair].price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - oraclePairMapping[_pair].price1CumulativeLast) / timeElapsed));
    
        oraclePairMapping[_pair].price0CumulativeLast = price0Cumulative;
        oraclePairMapping[_pair].price1CumulativeLast = price1Cumulative;
        oraclePairMapping[_pair].blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _pair, address token, uint amountIn) external view returns (uint amountOut) {
        if (token == oraclePairMapping[_pair].token0) {
            amountOut = oraclePairMapping[_pair].price0Average.mul(amountIn).decode144();
        } else {
            require(token == oraclePairMapping[_pair].token1, 'ExampleOracleSimple: INVALID_TOKEN');
            amountOut = oraclePairMapping[_pair].price1Average.mul(amountIn).decode144();
        }
    }
    
    function getBlockLastTimeStamp(address _pair) public view returns(uint32) {
        return oraclePairMapping[_pair].blockTimestampLast;
    }
}