/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT

// File contracts/interface/ICCFactory.sol

pragma solidity >=0.5.0 <0.8.0;

interface ICCFactory {
    function updater() external view returns (address);

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function feeToRate() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setFeeToRate(uint256) external;

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function pairFor(address tokenA, address tokenB) external view returns (address pair);

    function getReserves(address tokenA, address tokenB) external view returns (uint256 reserveA, uint256 reserveB);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
    
    function migrator() external view returns (address);
    
    function setMigrator(address) external;

}


// File contracts/interface/ICCPair.sol

pragma solidity >=0.5.0 <0.8.0;

interface ICCPair {
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

    function price(address token, uint256 baseDecimal) external view returns (uint256);

    function initialize(address, address) external;

    function updateFee() external;
}


// File contracts/interface/IOracle.sol

pragma solidity ^0.6.6;

interface IOracle {
    function factory() external pure returns (address);
    function update(address tokenA, address tokenB) external returns(bool);
    function updatePair(address pair) external returns(bool);
    function consult(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);
}


// File contracts/volumeMining/Oracle.sol


pragma solidity =0.6.6;



library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

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
    // int to 112bits precision fixed point number8890779i-78888
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
    // div like this can obtaion a fixed point number with 112 bits precision
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

library CCOracleLibrary {
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
        price0Cumulative = ICCPair(pair).price0CumulativeLast();
        price1Cumulative = ICCPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = ICCPair(pair).getReserves();
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

contract Oracle is IOracle {
    using FixedPoint for *;
    using SafeMath for uint;

    uint256 public constant PERIOD = 30 minutes;

    address public immutable override factory;
    
    struct Observation {
        uint32 blockTimestampLast;
        uint price0CumulativeLast;
        uint price1CumulativeLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    // mapping from pair address to a list of price observations of that pair
    mapping(address => Observation) private pairObservations;

    constructor(address _factory) public {
        require(_factory != address(0), "Oracle: Zero address");
        factory = _factory;
    }

    function getObservation(address tokenA, address tokenB) external view returns(uint32, uint, uint, uint224, uint224) {
        address pair = ICCFactory(factory).getPair(tokenA, tokenB);
        Observation storage observation = pairObservations[pair];
        return (
            observation.blockTimestampLast,
            observation.price0CumulativeLast,
            observation.price1CumulativeLast,
            observation.price0Average._x,
            observation.price1Average._x
        );
    }

    function updatePair(address pair) public override returns(bool) {
        // only exist pair can be updated
        if (pair == address(0)) {
            return false;
        }
        Observation storage observation = pairObservations[pair];
        // init create observation
        if (observation.blockTimestampLast == 0) {
            ICCPair _pair = ICCPair(pair);
            // if pair just created, priceCumulativeLast will be zero
            observation.price0CumulativeLast = _pair.price0CumulativeLast(); // fetch the current accumulated price value (1 / 0)
            observation.price1CumulativeLast = _pair.price1CumulativeLast(); // fetch the current accumulated price value (0 / 1)
            uint112 reserve0;
            uint112 reserve1;
            uint32 _blockTimestampLast;
            (reserve0, reserve1, _blockTimestampLast) = _pair.getReserves();
            observation.blockTimestampLast = _blockTimestampLast;
            require(reserve0 != 0 && reserve1 != 0, 'Oracle: NO_RESERVES'); // ensure that there's liquidity in the pair
            return true;
        }
        // get obsservation
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            CCOracleLibrary.currentCumulativePrices(pair);

        uint32 timeElapsed = blockTimestamp - observation.blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) {
            return false;
        }
        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        observation.price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - observation.price0CumulativeLast) / timeElapsed));
        observation.price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - observation.price1CumulativeLast) / timeElapsed));

        observation.price0CumulativeLast = price0Cumulative;
        observation.price1CumulativeLast = price1Cumulative;
        observation.blockTimestampLast = blockTimestamp;
        
        return true;
    }

    // If no one add liquidity in period, invoke this func manuall. Check if timestamp > lastTimestamp + PERIOD off chain before invoke can save gas
    function update(address tokenA, address tokenB) external override returns(bool) {
        address pair = ICCFactory(factory).getPair(tokenA, tokenB);
        return updatePair(pair);
    }
     // note this will always return 0 before update function has been called successfully for the second time.
    function consult(address tokenIn, uint amountIn, address tokenOut) external override view returns (uint amountOut) {
        address pair = ICCFactory(factory).pairFor(tokenIn, tokenOut);
        Observation storage observation = pairObservations[pair];
        (address token0, address token1) = ICCFactory(factory).sortTokens(tokenIn, tokenOut);
        if (tokenIn == token0) {
            amountOut = observation.price0Average.mul(amountIn).decode144();
        } else {
            require(tokenIn == token1, 'Oracle: INVALID_TOKEN');
            amountOut = observation.price1Average.mul(amountIn).decode144();
        }
    }
}