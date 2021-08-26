/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// File: contracts/libraries/SafeMath.sol

pragma solidity ^0.7.6;

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

// File: @uniswap/lib/contracts/libraries/FullMath.sol

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity >=0.4.0;

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

// File: @uniswap/lib/contracts/libraries/Babylonian.sol


pragma solidity >=0.4.0;

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

// File: @uniswap/lib/contracts/libraries/BitMath.sol

pragma solidity >=0.5.0;

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

// File: @uniswap/lib/contracts/libraries/FixedPoint.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: contracts/libraries/UniswapV2Library.sol

pragma solidity ^0.7.6;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
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

// File: contracts/UniswapV2OracleInterface.sol

pragma solidity ^0.7.6;

interface UniswapV2OracleInterface{
    function update() external;
    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

// File: contracts/InverseFutures.sol

pragma solidity ^0.7.6;
//pragma abicoder v2;
//import './libraries/OracleLibrary.sol';

//import './libraries/PoolAddress.sol';





/**
* The Pair is like ETH/USD, price is quoted as ETH/USD. collateral is in ETH, and PnL is in ETH. There may be helper views to 
* provide PnL in USD also for reporting purpose.
*/

contract InverseFutures {
    using SafeMath for uint256;

    address owner;

    enum PoolAction{NONE, ADD_BASE_CCY_TO_POOL, REMOVE_BASE_CCY_FROM_POOL, ADD_QUOTE_CCY_TO_POOL, REMOVE_QUOTE_CCY_FROM_POOL}
    enum Direction{LONG, SHORT}
    
    mapping(address => UniswapV2OracleInterface) public oracleByPair;
    mapping(address => address[2]) public tokensForPair;
    
    //This is essentially the Position of each Trader, including the Contract's initial position
    mapping(address => mapping(address => int256[2])) public vAmmPoolByPair;
    mapping(address => uint256) public vAmmConstantProductByPair;
    mapping(address => mapping(address => uint256)) public marginByPairByTrader;
    mapping(address => uint256) public marginByTrader;
    
    constructor(address _owner){
        owner = _owner;
    }
    
    /*function getPrice(address pool, uint32 period) public view returns (int24 timeWeightedAverageTick){
        return OracleLibrary.consult(pool, period);
    }
    function getPoolAddress(address factory, address tokenA, address tokenB, uint24 fee) public pure returns (address poolAddress){
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }*/
    function updatePrice(UniswapV2OracleInterface oracle) public {
        oracle.update();
    }
    /*function getPrice(UniswapOracle oracle) public view returns (FixedPoint.uq112x112 memory price0Average, FixedPoint.uq112x112 memory price1Average) {
        price0Average = FixedPoint.uq112x112(uint224(oracle.price0Average()));
        price1Average = FixedPoint.uq112x112(uint224(oracle.price1Average()));
    }*/
    function oracleConsult(address pair, address token1, uint amount1) external view returns (uint amountOut){
        amountOut = oracleByPair[pair].consult(token1, amount1);
    }
    function getPairAddress(address factory, address tokenA, address tokenB) external pure returns (address pairAddress){
        pairAddress = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }
    //TODO Cant call this locally, because mock is not there
    function addPair(address factory, address tokenA, address tokenB, uint256 tokenAInit, uint256 tokenBInit) external {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        tokensForPair[pair][0] = tokenA;
        tokensForPair[pair][1] = tokenB;
        //addInstrument(pair, tokenAInit, tokenBInit);
        require(vAmmPoolByPair[pair][address(this)][0] == 0 && vAmmPoolByPair[pair][address(this)][1]==0, 'Pair Already added');

        vAmmPoolByPair[pair][address(this)][0] = int256(tokenAInit);
        vAmmPoolByPair[pair][address(this)][1] = int256(tokenBInit);
        vAmmConstantProductByPair[pair] = tokenAInit.mul(tokenBInit);

    }
    /*function addInstrument(address pair, uint256 tokenAInit, uint256 tokenBInit) internal {
        require(vAmmPoolByPair[pair][address(this)][0] == 0 && vAmmPoolByPair[pair][address(this)][1]==0, 'Pair Already added');

        vAmmPoolByPair[pair][address(this)][0] = int256(tokenAInit);
        vAmmPoolByPair[pair][address(this)][1] = int256(tokenBInit);
        vAmmConstantProductByPair[pair] = tokenAInit.mul(tokenBInit);

        //oracleByPair[pair] = new UniswapOracle(uniswapFactory, tokenA, tokenB);
        //updatePrice(oracleByPair[pair]);
        
    }*/
    // e.g. USD / ETH, Margin is in ETH , Long means Buying USDC, selling ETH, means ADD_QUOTE_CCY_TO_POOL. Short === REMOVE_QUOTE_CCY_TO_POOL
    //TODO -- non-ETH Base ccy and therefore collateral
    function openPosition(address pair, uint8 leverage, Direction direction) external payable{
        //address pair = UniswapV2Library.pairFor(uniswapFactory, tokenA, tokenB);
        //updatePrice(oracleByPair[pair]);
        uint256 margin = msg.value;
        int256 quoteAmount = getQuoteAmountAndUpdatePool(pair, margin.mul(leverage), direction);
        marginByTrader[msg.sender] = marginByTrader[msg.sender].add(margin);
        //Margin by Pair is not being used, just added if needed for any book keeping reporting purposes
        marginByPairByTrader[pair][msg.sender] = marginByPairByTrader[pair][msg.sender].add(margin);
        
        //Update trader position 
        vAmmPoolByPair[pair][msg.sender][0] =  direction == Direction.LONG ? vAmmPoolByPair[pair][msg.sender][0] + int256(margin*(leverage)) : vAmmPoolByPair[pair][msg.sender][0] - int256(margin*(leverage));
        vAmmPoolByPair[pair][msg.sender][1] =  vAmmPoolByPair[pair][msg.sender][1] + quoteAmount;
    }
    function getQuoteAmountAndUpdatePool(address pair, uint256 baseAmount, Direction direction) internal returns (int256 quoteAmountChangedInPool){
        //address pair = UniswapV2Library.pairFor(uniswapFactory, tokenA, tokenB);
        int256 quoteAmountBefore = vAmmPoolByPair[pair][address(this)][1];
        if (direction == Direction.LONG){
            vAmmPoolByPair[pair][address(this)][0] = vAmmPoolByPair[pair][address(this)][0] - int256((baseAmount));
            vAmmPoolByPair[pair][address(this)][1] = int256(vAmmConstantProductByPair[pair])/ vAmmPoolByPair[pair][address(this)][0];
        }
        else {
            vAmmPoolByPair[pair][address(this)][0] = vAmmPoolByPair[pair][address(this)][0] + int256((baseAmount));
            vAmmPoolByPair[pair][address(this)][1] = int256(vAmmConstantProductByPair[pair]) / vAmmPoolByPair[pair][address(this)][0];
        }
        quoteAmountChangedInPool =  quoteAmountBefore - (vAmmPoolByPair[pair][address(this)][1]);
        
    }
    function closePosition(address pair) external {
        //address pair = UniswapV2Library.pairFor(uniswapFactory, tokenA, tokenB);
        //updatePrice(oracleByPair[pair]);

        int256 positionBaseAmount = vAmmPoolByPair[pair][msg.sender][0];
        int256 positionQuoteAmount = vAmmPoolByPair[pair][msg.sender][1];
        int256 currentBaseAmountInPool = vAmmPoolByPair[pair][address(this)][0];
        vAmmPoolByPair[pair][address(this)][1] = int256(vAmmPoolByPair[pair][address(this)][1]) + positionQuoteAmount;
        vAmmPoolByPair[pair][address(this)][0] = int256(vAmmConstantProductByPair[pair]) / vAmmPoolByPair[pair][address(this)][1] ;
        int256 changeInBaseAmount = positionBaseAmount < 0 ? vAmmPoolByPair[pair][address(this)][0] - currentBaseAmountInPool : currentBaseAmountInPool - vAmmPoolByPair[pair][address(this)][0];
        //Trader PnL is Buy - Sell in the Quote Ccy, i.e. ETH in case of USDC/ETH
        vAmmPoolByPair[pair][msg.sender][0] = 0;
        vAmmPoolByPair[pair][msg.sender][1] = 0;
        int256 traderPnL = positionQuoteAmount > 0 ? positionBaseAmount - changeInBaseAmount : positionBaseAmount + changeInBaseAmount; //positionQuoteAmount will be -ve for Long
        marginByPairByTrader[pair][msg.sender] = uint256(int256(marginByPairByTrader[pair][msg.sender]) + traderPnL);
        marginByTrader[msg.sender] = uint256(int256(marginByTrader[msg.sender]) + traderPnL);
    }
    function closePartial(address pair, uint16 partialCloseBasisPoints) external {
        require(partialCloseBasisPoints <= 10000, 'Cant square more than 100%');
        int256 oldTraderBase = vAmmPoolByPair[pair][msg.sender][0];
        int256 oldTraderQuote = vAmmPoolByPair[pair][msg.sender][1];
        require(oldTraderQuote != 0, 'No position to square off');
        int256 quoteAmountBeingCovered = oldTraderQuote * partialCloseBasisPoints/10000;
        int256 oldPoolBase = vAmmPoolByPair[pair][address(this)][0];
        
        PoolAction baseSidePoolActionForCover;
        oldTraderBase > 0 ?  baseSidePoolActionForCover = PoolAction.ADD_BASE_CCY_TO_POOL : baseSidePoolActionForCover = PoolAction.REMOVE_BASE_CCY_FROM_POOL;
        
        
        vAmmPoolByPair[pair][address(this)][1] = int256(vAmmPoolByPair[pair][address(this)][1]) + quoteAmountBeingCovered;
        vAmmPoolByPair[pair][address(this)][0] = int256(vAmmConstantProductByPair[pair]) / vAmmPoolByPair[pair][address(this)][1];

        int256 poolBaseDelta = oldTraderBase > 0 ? vAmmPoolByPair[pair][address(this)][0] - oldPoolBase : oldPoolBase - vAmmPoolByPair[pair][address(this)][0]; 
        int256 newTraderBase = oldTraderBase > 0 ? oldTraderBase - poolBaseDelta : oldTraderBase + poolBaseDelta;
        vAmmPoolByPair[pair][msg.sender][0] = newTraderBase;
        vAmmPoolByPair[pair][msg.sender][1] = oldTraderQuote - quoteAmountBeingCovered; 
    }
    function withdrawAll() external {
        uint256 withdrawable = marginByTrader[msg.sender];
        require(withdrawable > 0, 'Nothing to withdraw');
        marginByTrader[msg.sender] = 0;
        msg.sender.transfer(withdrawable);
    }
    function withdraw(uint256 amount) external {
        require(marginByTrader[msg.sender] >= amount, 'Not enough to withdraw');
        marginByTrader[msg.sender] = marginByTrader[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }
    modifier isOwner() {
        require(msg.sender == owner, 'Must be owner');
        _;
    }
}