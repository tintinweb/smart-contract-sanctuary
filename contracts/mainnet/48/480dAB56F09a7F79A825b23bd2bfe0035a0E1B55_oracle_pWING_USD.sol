/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// File: contracts/lib/math/SafeMath.sol

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

// File: contracts/lib/interfaces/IUniswapV2Factory.sol


pragma solidity >=0.6.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: contracts/lib/interfaces/IUniswapV2Pair.sol


pragma solidity >=0.6.0;

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

// File: contracts/lib/utils/Babylonian.sol


pragma solidity >=0.6.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
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

// File: contracts/lib/utils/FixedPoint.sol


pragma solidity >=0.6.0;


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
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

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

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// File: contracts/lib/oracle/UniswapV2OracleLibrary.sol


pragma solidity >=0.6.0;




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

// File: contracts/lib/oracle/AggregatorV3Interface.sol

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/Oracle_pWING_chainlink.sol

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;









/* 
*  This will be used with sushi pWING/ETH to get pWING/USDC price.
*  It will use a TWAP of 1 hr and chainlink sport price to determine of there is recent
*  change in price.  It chooses the lower price between spot and twap. 
*/
contract oracle_pWING_USD {
    using SafeMath for uint256;
    using FixedPoint for *;

    uint public constant HOURLY = 1 hours;  // 1 hour price updates

    uint PERIOD; //not used but needed for interface requirments since some oneTokens call update period

    struct UniswapPair {
        IUniswapV2Pair pair;
        address token0;
        address token1;
        uint price0CumulativeLast;
        uint price1CumulativeLast;
        uint32 blockTimestampLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
        uint PERIOD;
    }

    uint constant numUniswapPairs = 2;
    mapping (uint => UniswapPair) pairs;

    enum PairTypes{ pWING_ETH_HOURLY, ETH_USDC_HOURLY }

    address public pWING; 
    address public USDC; 
    address public WETH;

    address public owner;  //oneToken address
    uint256 public outputDecimals;

    address public spotOracle;
    uint256 public spotOracle_decimals;

    /*
     *  oneToken - will be the owner of this oracle which can run update
     *  factory - sushi factory - mainnet 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac
     *  pWING - pWING token
     *  USDC - USDC token
     *  WETH - WETH token
     *  chainlink - spotPrice - mainnet 0x134fE0a225Fb8e6683617C13cEB6B3319fB4fb82
     */
    constructor(
        address oneToken, 
        address factory, 
        address pWING_, 
        address USDC_,
        address WETH_, 
        uint256 outputDecimals_,
        address spotOracle_) 
        public {

            // spot check price oracle

            spotOracle = spotOracle_;
            spotOracle_decimals = AggregatorV3Interface(spotOracle)
                .decimals();


            IUniswapV2Pair _pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(pWING_, WETH_));
            uint112 reserve0;
            uint112 reserve1;
            uint32 blockTimestampLast;
         
            (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
            require(reserve0 != 0 && reserve1 != 0, 'oracle_pWING_WETH: NO_RESERVES');

            pairs[uint(PairTypes.pWING_ETH_HOURLY)] = UniswapPair(
                _pair,
                pWING_,
                WETH_,
                _pair.price0CumulativeLast(),
                _pair.price1CumulativeLast(),
                blockTimestampLast,
                FixedPoint.uq112x112(0),
                FixedPoint.uq112x112(0),
                HOURLY
            );

            _pair = IUniswapV2Pair(IUniswapV2Factory(factory).getPair(USDC_, WETH_));
            (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
            require(reserve0 != 0 && reserve1 != 0, 'oracle_USDC_WETH: NO_RESERVES');

            pairs[uint(PairTypes.ETH_USDC_HOURLY)] = UniswapPair(
                _pair,
                USDC_,
                WETH_,
                _pair.price0CumulativeLast(),
                _pair.price1CumulativeLast(),
                blockTimestampLast,
                FixedPoint.uq112x112(0),
                FixedPoint.uq112x112(0),
                HOURLY
            );

            pWING = pWING_;
            USDC = USDC_;
            WETH = WETH_;
            owner = oneToken;
            outputDecimals = outputDecimals_;
           
    }

    function changeInterval(uint256 period_) external {
        require(msg.sender == owner, "unauthorized");
        PERIOD = period_;
    }

    function update() external {
        for (uint i = 0; i < numUniswapPairs; i++) {
            (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(pairs[i].pair));
            uint32 timeElapsed = blockTimestamp - pairs[i].blockTimestampLast; // overflow is desired

            if (timeElapsed >= pairs[i].PERIOD || pairs[i].price0Average.mul(1).decode144() == uint(0)) {
                pairs[i].price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - pairs[i].price0CumulativeLast) / timeElapsed));
                pairs[i].price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - pairs[i].price1CumulativeLast) / timeElapsed));

                pairs[i].price0CumulativeLast = price0Cumulative;
                pairs[i].price1CumulativeLast = price1Cumulative;
                
                pairs[i].blockTimestampLast = blockTimestamp;
            }
        }
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(uint i, address token, uint amountIn) internal view returns (uint256) {
        uint256 amount;
        if (token == pairs[i].token0) {
            amount = pairs[i].price0Average.mul(amountIn).decode144();
        } else {
            require(token == pairs[i].token1, 'oracle_pWING_USDC: INVALID_TOKEN');
            amount = pairs[i].price1Average.mul(amountIn).decode144();
        }
       return amount;
    }

    function getHourlyPrice() public view returns (uint256) {
        uint256 pWING_ETH_HOURLY = consult(uint(PairTypes.pWING_ETH_HOURLY),WETH,10**18).div(10 ** 18);
        uint256 ETH_USDC_HOURLY = consult(uint(PairTypes.ETH_USDC_HOURLY),WETH,10**18).mul(10 ** 3);

        uint256 pWING_USDC_HOURLY = pWING_ETH_HOURLY.mul(ETH_USDC_HOURLY).div(10 ** 9);

        return pWING_USDC_HOURLY;

    }

    function getSpotPrice() public view returns (uint256) {
        (, int256 price, , , ) = AggregatorV3Interface(spotOracle)
            .latestRoundData();
        uint256 price_ = uint256(price);
        if (outputDecimals > spotOracle_decimals) {
            price_ = price_.mul(
                10**(outputDecimals - spotOracle_decimals)
            );
        }
        if (outputDecimals < spotOracle_decimals) {
            price_ = price_.div(
                10**(spotOracle_decimals - outputDecimals)
            );
        }
        return price_;
    }

    function getLatestPrice() public view returns (uint256) {
        uint256 pWING_USDC_HOURLY = getHourlyPrice(); 
        uint256 sport_price = getSpotPrice();

        if (pWING_USDC_HOURLY < sport_price) return pWING_USDC_HOURLY;

        return sport_price;
    }

}