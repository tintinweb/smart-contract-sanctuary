/**
 *Submitted for verification at snowtrace.io on 2021-11-22
*/

//based on: https://github.com/Uniswap/uniswap-v2-periphery/tree/master/contracts/examples

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

interface IUniswapV2TWAP {
    function consult(address tokenA, address tokenB, address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
    function consultWithUpdate(address tokenA, address tokenB, address tokenIn, uint256 amountIn) external returns (uint256 amountOut);
}

interface IHauntedHouse {
    function updatePrice(address token, uint256 newPrice) external;
    function updatePrices(address[] calldata tokens, uint256[] calldata newPrices) external;
    function tokenList() external view returns (address[] memory);
}

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

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
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

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract TWAP_Oracle is Ownable {
    using FixedPoint for *;

    struct Observation {
        uint256 timestamp;
        uint256 price0CumulativeLast;
        uint256 price1CumulativeLast;
        FixedPoint.uq112x112 price0Average;
        FixedPoint.uq112x112 price1Average;
    }

    uint256 public constant PERIOD = 24 hours;
    //pangolin factory
    address public constant DEFAULT_FACTORY = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;

    //stored price/trading observations
    mapping(address => Observation) public observations;
    //used for tokens that need a factory other than the default
    mapping(address => mapping(address => address)) public factories;
    //used for mapping factories to their pair init code hashes, used for calculating token pairs
    mapping(address => bytes) public factoryInitCodes;

    constructor() public {
        //Pangolin
        setFactoryInitCode(0xefa94DE7a4656D787667C749f7E1223D71E9FD88, 
            hex'40231f6b438bce0797c9ada29b718a87ea0a5cea3fe9a771abdd76bd41a3e545');
        //TraderJoe
        setFactoryInitCode(0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10, 
            hex'0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91');
        //Lydia
        setFactoryInitCode(0xA52aBE4676dbfd04Df42eF7755F01A3c41f28D27, 
            hex'47cc4f3a5e7a237c464e09c6758ac645084f198b8f64eedc923317ac4481a10c');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                factoryInitCodes[factory] // init code hash
            ))));
    }

    // note this will always return 0 before update has been called successfully for the first time for the pair.
    function consult(address tokenA, address tokenB, address tokenIn, uint256 amountIn) public view returns (uint256 amountOut) {
        address factory = _getFactory(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        if (tokenIn == token0) {
            amountOut = observations[pair].price0Average.mul(amountIn).decode144();
        } else {
            require(tokenIn == token1, 'TWAP_Oracle: invalid tokenIn');
            amountOut = observations[pair].price0Average.mul(amountIn).decode144();
        }
    }

    function consultWithUpdate(address tokenA, address tokenB, address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        update(tokenA, tokenB);
        return consult(tokenA, tokenB, tokenIn, amountIn);
    }

    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function update(address tokenA, address tokenB) public {
        address factory = _getFactory(tokenA, tokenB);
        address pair = pairFor(factory, tokenA, tokenB);
        // we only want to commit updates once per period (i.e. windowSize / granularity)
        uint256 timeElapsed = block.timestamp - observations[pair].timestamp;
        if (timeElapsed > PERIOD) {
            (uint256 price0Cumulative, uint256 price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            // leave price as zero if this is the first observation
            if (timeElapsed < block.timestamp) {
                // overflow is desired, casting never truncates
                // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
                observations[pair].price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - observations[pair].price0CumulativeLast) / timeElapsed));
                observations[pair].price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - observations[pair].price1CumulativeLast) / timeElapsed));
            }
            observations[pair].timestamp = block.timestamp;
            observations[pair].price0CumulativeLast = price0Cumulative;
            observations[pair].price1CumulativeLast = price1Cumulative;
        }
    }

    function setFactoryInitCode(address factory, bytes memory initCode) public onlyOwner {
        factoryInitCodes[factory] = initCode;
    }

    function setFactory(address tokenA, address tokenB, address factory) external onlyOwner {
        factories[tokenA][tokenB] = factory;
        factories[tokenB][tokenA] = factory;
    }

    function massSetFactory(address[] calldata tokenAs, address[] calldata tokenBs, address factory) external onlyOwner {
        require(tokenAs.length == tokenBs.length, "input length mismatch");
        for (uint256 i = 0; i < tokenAs.length; i++) {
            factories[tokenAs[i]][tokenBs[i]] = factory;
            factories[tokenBs[i]][tokenAs[i]] = factory;
        }
    }

    function _getFactory(address tokenA, address tokenB) internal view returns(address) {
        if(factories[tokenA][tokenB] == address(0)) {
            return DEFAULT_FACTORY;
        } else {
            return factories[tokenA][tokenB];
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
}

contract CauldronPriceUpdater is Ownable {
    address constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    //whitelist of addresses that can call this contract
    mapping(address => bool) whitelist;
    //tracks is a token is an LP or not
    mapping(address => bool) lpTokens;
    //address of oracle to consult
    address public oracle;
    //address of HauntedHouse
    address public immutable hauntedHouse;
    event OracleSet();
    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "only callable by whitelisted addresses");
        _;
    }
    constructor(address _hauntedHouse, address _oracle) public {
        hauntedHouse = _hauntedHouse;
        setOracle(_oracle);
        whitelist[msg.sender] = true;
    }
    //VIEW FUNCTIONS
    function getTokenPriceView(address token) public view returns (uint256) {
        //NOTE: return value is SCALED UP by 1e18, as this is the input amount in consulting the oracle
        if (token != WAVAX) {
            return IUniswapV2TWAP(oracle).consult(token, WAVAX, token, 1e18);
        } else {
            return 1e18;
        }
    }
    function getPriceOfLPView(address lpToken) public view returns (uint256) {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();
        uint256 priceToken0 = getTokenPriceView(token0);
        uint256 priceToken1 = getTokenPriceView(token1);
        uint256 balanceToken0 = IERC20(token0).balanceOf(lpToken);
        uint256 balanceToken1 = IERC20(token1).balanceOf(lpToken);
        uint256 lpTVL = (priceToken0 * balanceToken0) + (priceToken1 * balanceToken1);
        return lpTVL / IUniswapV2Pair(lpToken).totalSupply();
    }
    //PUBLIC WRITE FUNCTIONS
    function getTokenPrice(address token) public returns (uint256) {
        //NOTE: return value is SCALED UP by 1e18, as this is the input amount in consulting the oracle
        if (token != WAVAX) {
            return IUniswapV2TWAP(oracle).consultWithUpdate(token, WAVAX, token, 1e18);
        } else {
            return 1e18;
        }
    }
    function getPriceOfLP(address lpToken) public returns (uint256) {
        address token0 = IUniswapV2Pair(lpToken).token0();
        address token1 = IUniswapV2Pair(lpToken).token1();
        uint256 priceToken0 = getTokenPrice(token0);
        uint256 priceToken1 = getTokenPrice(token1);
        uint256 balanceToken0 = IERC20(token0).balanceOf(lpToken);
        uint256 balanceToken1 = IERC20(token1).balanceOf(lpToken);
        uint256 lpTVL = (priceToken0 * balanceToken0) + (priceToken1 * balanceToken1);
        return lpTVL / IUniswapV2Pair(lpToken).totalSupply();
    }
    //OWNER-ONLY FUNCTIONS
    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }
    function modifyWhitelist(address[] calldata addresses, bool[] calldata statuses) external onlyOwner {
        require(addresses.length == statuses.length, "input length mismatch");
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = statuses[i];
        }
    }
    function addLPTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            lpTokens[tokens[i]] = true;
        }
    }
    function removeLPTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            lpTokens[tokens[i]] = false;
        }
    }
    //WHITELIST-ONLY FUNCTIONS
    function setPrice(address token) public onlyWhitelist {
        uint256 tokenPrice;
        if(lpTokens[token]) {
            tokenPrice = getPriceOfLP(token);
        } else {
            tokenPrice = getTokenPrice(token);
        }
        IHauntedHouse(hauntedHouse).updatePrice(token, tokenPrice);
    }
    function setPrices(address[] memory tokens) public onlyWhitelist {
        uint256[] memory tokenPrices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            if(lpTokens[tokens[i]]) {
                tokenPrices[i] = getPriceOfLP(tokens[i]);
            } else {
                tokenPrices[i] = getTokenPrice(tokens[i]);
            }
        }
        IHauntedHouse(hauntedHouse).updatePrices(tokens, tokenPrices);
    }
    function setAllPrices() external onlyWhitelist {
        address[] memory tokens = IHauntedHouse(hauntedHouse).tokenList();
        setPrices(tokens);
    }
}