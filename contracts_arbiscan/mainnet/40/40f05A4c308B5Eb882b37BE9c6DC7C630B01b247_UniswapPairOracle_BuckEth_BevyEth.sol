/**
 *Submitted for verification at arbiscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

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


pragma solidity 0.6.11;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity 0.6.11;

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // Less efficient than the CREATE2 method below
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairForCreate2(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))); // this matches the CREATE2 in UniswapV2Factory.createPair
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


pragma solidity 0.6.11;

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle {
    using FixedPoint for *;
    
    address owner_address;
    address timelock_address;

    uint public PERIOD = 3600; // 1 hour TWAP (time-weighted average price)
    uint public CONSULT_LENIENCY = 120; // Used for being able to consult past the period end
    bool public ALLOW_STALE_CONSULTS = false; // If false, consult() will fail if the TWAP is stale

    address public immutable wethAddress;
    IUniswapV2Factory public immutable factoryAddress;
    
    address public immutable BuckAddress;
    IUniswapV2Pair public immutable BuckEthPair;
    address public immutable BuckEthPairToken0;
    address public immutable BuckEthPairToken1;
    
    uint    public BuckEthPairPrice0CumulativeLast;
    uint    public BuckEthPairPrice1CumulativeLast;
    uint32  public BuckEthPairBlockTimestampLast;
    FixedPoint.uq112x112 public BuckEthPairPrice0Average;
    FixedPoint.uq112x112 public BuckEthPairPrice1Average;
    
    address public immutable BevyAddress;
    IUniswapV2Pair public immutable BevyEthPair;
    address public immutable BevyEthPairToken0;
    address public immutable BevyEthPairToken1;
    
    uint    public BevyEthPairPrice0CumulativeLast;
    uint    public BevyEthPairPrice1CumulativeLast;
    uint32  public BevyEthPairBlockTimestampLast;
    FixedPoint.uq112x112 public BevyEthPairPrice0Average;
    FixedPoint.uq112x112 public BevyEthPairPrice1Average;

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    constructor(address factory, address buck, address bevy, address weth, address _owner_address, address _timelock_address) public {
        wethAddress = weth;
        factoryAddress = IUniswapV2Factory(factory);
        BuckAddress = buck;
        BevyAddress = bevy;
        
        // BUCK-ETH
        IUniswapV2Pair _BuckEthPair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, buck, weth));
        BuckEthPair = _BuckEthPair;
        BuckEthPairToken0 = _BuckEthPair.token0();
        BuckEthPairToken1 = _BuckEthPair.token1();
        BuckEthPairPrice0CumulativeLast = _BuckEthPair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        BuckEthPairPrice1CumulativeLast = _BuckEthPair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 BuckEthPairReserve0;
        uint112 BuckEthPairReserve1;
        (BuckEthPairReserve0, BuckEthPairReserve1, BuckEthPairBlockTimestampLast) = _BuckEthPair.getReserves();
        require(BuckEthPairReserve0 != 0 && BuckEthPairReserve1 != 0, 'UniswapPairOracle BUCK/ETH: NO_RESERVES'); // Ensure that there's liquidity in the pair
        
        // BEVY-ETH
        IUniswapV2Pair _BevyEthPair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, bevy, weth));
        BevyEthPair = _BevyEthPair;
        BevyEthPairToken0 = _BevyEthPair.token0();
        BevyEthPairToken1 = _BevyEthPair.token1();
        BevyEthPairPrice0CumulativeLast = _BevyEthPair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        BevyEthPairPrice1CumulativeLast = _BevyEthPair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 BevyEthPairReserve0;
        uint112 BevyEthPairReserve1;
        (BevyEthPairReserve0, BevyEthPairReserve1, BevyEthPairBlockTimestampLast) = _BevyEthPair.getReserves();
        require(BevyEthPairReserve0 != 0 && BevyEthPairReserve1 != 0, 'UniswapPairOracle BEVY/ETH: NO_RESERVES'); // Ensure that there's liquidity in the pair

        owner_address = _owner_address;
        timelock_address = _timelock_address;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setTimelock(address _timelock_address) external onlyByOwnerOrGovernance {
        timelock_address = _timelock_address;
    }

    function setPeriod(uint _period) external onlyByOwnerOrGovernance {
        PERIOD = _period;
    }

    function setConsultLeniency(uint _consult_leniency) external onlyByOwnerOrGovernance {
        CONSULT_LENIENCY = _consult_leniency;
    }

    function setAllowStaleConsults(bool _allow_stale_consults) external onlyByOwnerOrGovernance {
        ALLOW_STALE_CONSULTS = _allow_stale_consults;
    }

    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view returns (bool) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsedBuckEth = blockTimestamp - BuckEthPairBlockTimestampLast; // Overflow is desired
        uint32 timeElapsedBevyEth = blockTimestamp - BevyEthPairBlockTimestampLast; // Overflow is desired
        return (timeElapsedBuckEth >= PERIOD && timeElapsedBevyEth >= PERIOD);
    }
    
    function uniV2SpotAssetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut
    ) public view returns (uint256 amountOut) {
        if (_tokenIn == wethAddress) {
            return _uniV2SpotEthToAsset(_amountIn, _tokenOut);
        } else if (_tokenOut == wethAddress) {
            return _uniV2SpotAssetToEth(_tokenIn, _amountIn);
        } else {
            uint256 ethAmount = _uniV2SpotAssetToEth(_tokenIn, _amountIn);
            return _uniV2SpotEthToAsset(ethAmount, _tokenOut);
        }
    }

    function _uniV2SpotAssetToEth(
        address _tokenIn,
        uint256 _amountIn
    ) internal view returns (uint256 ethAmountOut) {
        (uint256 tokenInReserve, uint256 ethReserve) = UniswapV2Library.getReserves(address(factoryAddress), _tokenIn, wethAddress);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_amountIn, tokenInReserve, ethReserve);
    }

    function _uniV2SpotEthToAsset(
        uint256 _ethAmountIn,
        address _tokenOut
    ) internal view returns (uint256 amountOut) {
        (uint256 ethReserve, uint256 tokenOutReserve) = UniswapV2Library.getReserves(address(factoryAddress), wethAddress, _tokenOut);
        // No slippage--just spot pricing based on current reserves
        return UniswapV2Library.quote(_ethAmountIn, ethReserve, tokenOutReserve);
    }

    function update() external {
        // BUCK-ETH
        (uint BuckEthPairPrice0Cumulative, uint BuckEthPairPrice1Cumulative, uint32 BuckEthPairBlockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(BuckEthPair));
        uint32 BuckEthPairTimeElapsed = BuckEthPairBlockTimestamp - BuckEthPairBlockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(BuckEthPairTimeElapsed >= PERIOD, 'UniswapPairOracle BUCK/ETH: PERIOD_NOT_ELAPSED');

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        BuckEthPairPrice0Average = FixedPoint.uq112x112(uint224((BuckEthPairPrice0Cumulative - BuckEthPairPrice0CumulativeLast) / BuckEthPairTimeElapsed));
        BuckEthPairPrice1Average = FixedPoint.uq112x112(uint224((BuckEthPairPrice1Cumulative - BuckEthPairPrice1CumulativeLast) / BuckEthPairTimeElapsed));

        BuckEthPairPrice0CumulativeLast = BuckEthPairPrice0Cumulative;
        BuckEthPairPrice1CumulativeLast = BuckEthPairPrice1Cumulative;
        BuckEthPairBlockTimestampLast = BuckEthPairBlockTimestamp;
        
        // BEVY-ETH
        (uint BevyEthPairPrice0Cumulative, uint BevyEthPairPrice1Cumulative, uint32 BevyEthPairBlockTimestamp) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(BevyEthPair));
        uint32 BevyEthPairTimeElapsed = BevyEthPairBlockTimestamp - BevyEthPairBlockTimestampLast; // Overflow is desired

        // Ensure that at least one full period has passed since the last update
        require(BevyEthPairTimeElapsed >= PERIOD, 'UniswapPairOracle BEVY/ETH: PERIOD_NOT_ELAPSED');

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        BevyEthPairPrice0Average = FixedPoint.uq112x112(uint224((BevyEthPairPrice0Cumulative - BevyEthPairPrice0CumulativeLast) / BevyEthPairTimeElapsed));
        BevyEthPairPrice1Average = FixedPoint.uq112x112(uint224((BevyEthPairPrice1Cumulative - BevyEthPairPrice1CumulativeLast) / BevyEthPairTimeElapsed));

        BevyEthPairPrice0CumulativeLast = BevyEthPairPrice0Cumulative;
        BevyEthPairPrice1CumulativeLast = BevyEthPairPrice1Cumulative;
        BevyEthPairBlockTimestampLast = BevyEthPairBlockTimestamp;
    }
    
    // Note this will always return 0 before update has been called successfully for the first time.
    function assetToAsset(address tokenIn, uint amountIn, address tokenOut, uint32 twapPeriod) external view returns (uint amountOutTwap, uint amountOutSpot) {
        twapPeriod;
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        
        if(tokenOut == BuckAddress){
            // BUCK-ETH
            
            uint32 BuckEthPairTimeElapsed = blockTimestamp - BuckEthPairBlockTimestampLast; // Overflow is desired
    
            // Ensure that the price is not stale
            require((BuckEthPairTimeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS, 'UniswapPairOracle BUCK/ETH: PRICE_IS_STALE_NEED_TO_CALL_UPDATE');
    
            if (tokenIn == BuckEthPairToken0) {
                amountOutTwap = BuckEthPairPrice0Average.mul(amountIn).decode144();
            } else {
                require(tokenIn == BuckEthPairToken1, 'UniswapPairOracle BUCK/ETH: INVALID_TOKEN');
                amountOutTwap = BuckEthPairPrice1Average.mul(amountIn).decode144();
            }
            
        } else if(tokenOut == BevyAddress){
            // BEVY-ETH
            
            uint32 BevyEthPairTimeElapsed = blockTimestamp - BevyEthPairBlockTimestampLast; // Overflow is desired
    
            // Ensure that the price is not stale
            require((BevyEthPairTimeElapsed < (PERIOD + CONSULT_LENIENCY)) || ALLOW_STALE_CONSULTS, 'UniswapPairOracle BEVY/ETH: PRICE_IS_STALE_NEED_TO_CALL_UPDATE');
    
            if (tokenIn == BevyEthPairToken0) {
                amountOutTwap = BevyEthPairPrice0Average.mul(amountIn).decode144();
            } else {
                require(tokenIn == BevyEthPairToken1, 'UniswapPairOracle BEVY/ETH: INVALID_TOKEN');
                amountOutTwap = BevyEthPairPrice1Average.mul(amountIn).decode144();
            }
        }
        
        amountOutSpot = uniV2SpotAssetToAsset(tokenIn, amountIn, tokenOut);
        
    }

}


pragma solidity 0.6.11;

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle_BuckEth_BevyEth is UniswapPairOracle {
    constructor(address factory, address buck, address bevy, address weth, address owner_address, address timelock_address) 
    UniswapPairOracle(factory, buck, bevy, weth, owner_address, timelock_address) 
    public {}
}