/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// hevm: flattened sources of src/UniswapTwap.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later AND CC-BY-4.0
pragma solidity 0.8.9;

////// node_modules/@openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

////// node_modules/@openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

////// src/interfaces/IUniswapTWAP.sol

/* pragma solidity 0.8.9; */

interface IUniswapTWAP {
    function maxUpdateWindow() external view returns (uint);

    function getVaderPrice() external returns (uint);

    function syncVaderPrice() external;
}

////// src/interfaces/chainlink/IAggregatorV3.sol

/* pragma solidity 0.8.9; */

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

////// src/interfaces/uniswap/IUniswapV2Pair.sol
/* pragma solidity 0.8.9; */

interface IUniswapV2Pair {
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

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);
}

////// src/libraries/Babylonian.sol
/* pragma solidity 0.8.9; */

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint xx = x;
        uint r = 1;
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
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

////// src/libraries/BitMath.sol
/* pragma solidity 0.8.9; */

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

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
    function leastSignificantBit(uint x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
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

////// src/libraries/FullMath.sol
/* pragma solidity 0.8.9; */

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint x, uint y) internal pure returns (uint l, uint h) {
        uint mm = mulmod(x, y, type(uint).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint l,
        uint h,
        uint d
    ) private pure returns (uint) {
        uint pow2 = d & uint(-int(d));
        d /= pow2;
        l /= pow2;
        l += h * (uint(-int(pow2)) / pow2 + 1);
        uint r = 1;
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
        uint x,
        uint y,
        uint d
    ) internal pure returns (uint) {
        (uint l, uint h) = fullMul(x, y);

        uint mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}

////// src/libraries/FixedPoint.sol
/* pragma solidity 0.8.9; */

/* import "./FullMath.sol"; */
/* import "./Babylonian.sol"; */
/* import "./BitMath.sol"; */

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

    uint8 public constant RESOLUTION = 112;
    uint public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint private constant Q224 =
        0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint(x) << RESOLUTION);
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
    function mul(uq112x112 memory self, uint y)
        internal
        pure
        returns (uq144x112 memory)
    {
        uint z = 0;
        require(
            y == 0 || (z = self._x * y) / y == self._x,
            "FixedPoint::mul: overflow"
        );
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int y) internal pure returns (int) {
        uint z = FullMath.mulDiv(self._x, uint(y < 0 ? -y : y), Q112);
        require(z < 2**255, "FixedPoint::muli: overflow");
        return y < 0 ? -int(z) : int(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other)
        internal
        pure
        returns (uq112x112 memory)
    {
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
        require(
            upper <= type(uint112).max,
            "FixedPoint::muluq: upper overflow"
        );

        // this cannot exceed 256 bits, all values are 224 bits
        uint sum = uint(upper << RESOLUTION) +
            uppers_lowero +
            uppero_lowers +
            (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(other._x > 0, "FixedPoint::divuq: division by zero");
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint value = (uint(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
            return uq112x112(uint224(value));
        }

        uint result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint numerator, uint denominator)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint result = (numerator << RESOLUTION) / denominator;
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        } else {
            uint result = FullMath.mulDiv(numerator, Q112, denominator);
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
        require(self._x != 1, "FixedPoint::reciprocal: overflow");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self)
        internal
        pure
        returns (uq112x112 memory)
    {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return
            uq112x112(
                uint224(
                    Babylonian.sqrt(uint(self._x) << safeShiftBits) <<
                        ((112 - safeShiftBits) / 2)
                )
            );
    }
}

////// src/libraries/UniswapV2OracleLibrary.sol
/* pragma solidity 0.8.9; */

/* import "../interfaces/uniswap/IUniswapV2Pair.sol"; */
/* import "./FixedPoint.sol"; */

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
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint(FixedPoint.fraction(reserve1, reserve0)._x) *
                timeElapsed;
            // counterfactual
            price1Cumulative +=
                uint(FixedPoint.fraction(reserve0, reserve1)._x) *
                timeElapsed;
        }
    }
}

////// src/UniswapTwap.sol

/* pragma solidity 0.8.9; */

/* import "@openzeppelin/contracts/access/Ownable.sol"; */
/* import "./interfaces/chainlink/IAggregatorV3.sol"; */
/* import "./interfaces/uniswap/IUniswapV2Pair.sol"; */
/* import "./interfaces/IUniswapTWAP.sol"; */
/* import "./libraries/UniswapV2OracleLibrary.sol"; */
/* import "./libraries/FixedPoint.sol"; */

/**
 * @notice Return absolute value of |x - y|
 */
function abs(uint x, uint y) pure returns (uint) {
    if (x >= y) {
        return x - y;
    }
    return y - x;
}

contract UniswapTwap is IUniswapTWAP, Ownable {
    using FixedPoint for FixedPoint.uq112x112;
    using FixedPoint for FixedPoint.uq144x112;

    struct ExchangePair {
        uint nativeTokenPriceCumulative;
        FixedPoint.uq112x112 nativeTokenPriceAverage;
        uint lastMeasurement;
        uint updatePeriod;
        // true if token0 = vader
        bool isFirst;
    }

    event SetOracle(address oracle);

    // 1 Vader = 1e18
    uint private constant ONE_VADER = 1e18;
    // Denominator to calculate difference in Vader / ETH TWAP and spot price.
    uint private constant MAX_PRICE_DIFF_DENOMINATOR = 1e5;
    // max for maxUpdateWindow
    uint private constant MAX_UPDATE_WINDOW = 30 days;

    /* ========== STATE VARIABLES ========== */
    address public immutable vader;
    // Vader ETH pair
    IUniswapV2Pair public immutable pair;
    // Set to pairData.updatePeriod.
    // maxUpdateWindow is called by other contracts.
    uint public maxUpdateWindow;
    ExchangePair public pairData;
    IAggregatorV3 public oracle;
    // Numberator to calculate max allowed difference between Vader / ETH TWAP
    // and spot price.
    // maxPriceDiff must be initialized to MAX_PRICE_DIFF_DENOMINATOR and kept
    // until TWAP price is close to spot price for _updateVaderPrice to not fail.
    uint public maxPriceDiff = MAX_PRICE_DIFF_DENOMINATOR;

    constructor(
        address _vader,
        IUniswapV2Pair _pair,
        IAggregatorV3 _oracle,
        uint _updatePeriod
    ) {
        require(_vader != address(0), "vader = 0 address");
        vader = _vader;
        require(_oracle.decimals() == 8, "oracle decimals != 8");
        oracle = _oracle;
        pair = _pair;
        _addVaderPair(_vader, _pair, _updatePeriod);
    }

    /* ========== VIEWS ========== */
    /**
     * @notice Get Vader USD price calculated from Vader / ETH price from
     *         last update.
     **/
    function getStaleVaderPrice() external view returns (uint) {
        return _calculateVaderPrice();
    }

    /**
     * @notice Get ETH / USD price from Chainlink. 1 USD = 1e8.
     **/
    function getChainlinkPrice() public view returns (uint) {
        (uint80 roundID, int price, , , uint80 answeredInRound) = oracle
            .latestRoundData();
        require(answeredInRound >= roundID, "stale Chainlink price");
        require(price > 0, "chainlink price = 0");
        return uint(price);
    }

    /**
     * @notice Helper function to decode and return Vader / ETH TWAP price
     **/
    function getVaderEthPriceAverage() public view returns (uint) {
        return pairData.nativeTokenPriceAverage.mul(ONE_VADER).decode144();
    }

    /**
     * @notice Helper function to decode and return Vader / ETH spot price
     **/
    function getVaderEthSpotPrice() public view returns (uint) {
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        (uint vaderReserve, uint ethReserve) = pairData.isFirst
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        return
            FixedPoint
                .fraction(ethReserve, vaderReserve)
                .mul(ONE_VADER)
                .decode144();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
    * @notice Update Vader / ETH price and return Vader / USD price.
              This function will need to be executed at least twice to return
              sensible Vader / USD price.
    **/
    // NOTE: Fails until _updateVaderPrice is called atlease twice for
    // nativeTokenPriceAverage to be > 0
    function getVaderPrice() external returns (uint) {
        _updateVaderPrice();
        return _calculateVaderPrice();
    }

    /**
     * @notice Update Vader / ETH price.
     **/
    function syncVaderPrice() external {
        _updateVaderPrice();
    }

    /**
     * @notice Update Vader / ETH price.
     **/
    function _updateVaderPrice() private {
        uint timeElapsed = block.timestamp - pairData.lastMeasurement;
        // NOTE: save gas and re-entrancy protection.
        if (timeElapsed < pairData.updatePeriod) return;
        bool isFirst = pairData.isFirst;
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint currentMeasurement
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint priceCumulativeEnd = isFirst ? price0Cumulative : price1Cumulative;
        uint priceCumulativeStart = pairData.nativeTokenPriceCumulative;
        require(
            priceCumulativeEnd >= priceCumulativeStart,
            "price cumulative end < start"
        );
        unchecked {
            pairData.nativeTokenPriceAverage = FixedPoint.uq112x112(
                uint224(
                    (priceCumulativeEnd - priceCumulativeStart) / timeElapsed
                )
            );
        }
        pairData.nativeTokenPriceCumulative = priceCumulativeEnd;
        pairData.lastMeasurement = currentMeasurement;

        // check TWAP and spot price difference is not too big
        if (maxPriceDiff < MAX_PRICE_DIFF_DENOMINATOR) {
            // p = TWAP price
            // s = spot price
            // d = max price diff
            // D = MAX_PRICE_DIFF_DENOMINATOR
            // |p - s| / p <= d / D
            uint twapPrice = getVaderEthPriceAverage();
            uint spotPrice = getVaderEthSpotPrice();
            require(twapPrice > 0, "TWAP = 0");
            require(spotPrice > 0, "spot price = 0");
            // NOTE: if maxPriceDiff = 0, then this check will most likely fail
            require(
                (abs(twapPrice, spotPrice) * MAX_PRICE_DIFF_DENOMINATOR) /
                    twapPrice <=
                    maxPriceDiff,
                "price diff > max"
            );
        }
    }

    /**
     * @notice Calculates Vader price in USD, 1 USD = 1e18.
     **/
    function _calculateVaderPrice() private view returns (uint vaderUsdPrice) {
        // USD / ETH, 8 decimals
        uint usdPerEth = getChainlinkPrice();
        // ETH / Vader, 18 decimals
        uint ethPerVader = pairData
            .nativeTokenPriceAverage
            .mul(ONE_VADER)
            .decode144();
        // divide by 1e8 from Chainlink price
        vaderUsdPrice = (usdPerEth * ethPerVader) / 1e8;
        require(vaderUsdPrice > 0, "vader usd price = 0");
    }

    /**
     * @notice Initialize pairData.
     * @param _vader Address of Vader.
     * @param _pair Address of Vader / ETH Uniswap V2 pair.
     * @param _updatePeriod Amout of time that has to elapse before Vader / ETH
     *       TWAP can be updated.
     **/
    function _addVaderPair(
        address _vader,
        IUniswapV2Pair _pair,
        uint _updatePeriod
    ) private {
        require(_updatePeriod != 0, "update period = 0");
        bool isFirst = _pair.token0() == _vader;
        address nativeAsset = isFirst ? _pair.token0() : _pair.token1();
        require(nativeAsset == _vader, "unsupported pair");
        pairData.isFirst = isFirst;
        pairData.lastMeasurement = block.timestamp;
        _setUpdatePeriod(_updatePeriod);
        pairData.nativeTokenPriceCumulative = isFirst
            ? _pair.price0CumulativeLast()
            : _pair.price1CumulativeLast();
        // NOTE: pairData.nativeTokenPriceAverage = 0
    }

    /**
     * @notice Set Chainlink oracle.
     * @param _oracle Address of Chainlink price oracle.
     **/
    function setOracle(IAggregatorV3 _oracle) external onlyOwner {
        require(_oracle.decimals() == 8, "oracle decimals != 8");
        oracle = _oracle;
        emit SetOracle(address(_oracle));
    }

    /**
     * @notice Set updatePeriod.
     * @param _updatePeriod New update period for Vader / ETH TWAP
     **/
    function _setUpdatePeriod(uint _updatePeriod) private {
        require(_updatePeriod <= MAX_UPDATE_WINDOW, "update period > max");
        pairData.updatePeriod = _updatePeriod;
        maxUpdateWindow = _updatePeriod;
    }

    function setUpdatePeriod(uint _updatePeriod) external onlyOwner {
        _setUpdatePeriod(_updatePeriod);
    }

    /**
     * @notice Set maxPriceDiff.
     * @param _maxPriceDiff Numberator to calculate max allowed difference
     *        between Vader / ETH TWAP and spot price.
     **/
    function _setMaxPriceDiff(uint _maxPriceDiff) private {
        require(
            _maxPriceDiff <= MAX_PRICE_DIFF_DENOMINATOR,
            "price diff > max"
        );
        maxPriceDiff = _maxPriceDiff;
    }

    function setMaxPriceDiff(uint _maxPriceDiff) external onlyOwner {
        _setMaxPriceDiff(_maxPriceDiff);
    }

    /**
     * @notice Force update Vader TWAP price even if has deviated significantly
     *         from Vader / ETH spot price.
     */
    function forceUpdateVaderPrice() external onlyOwner {
        uint _maxPriceDiff = maxPriceDiff;
        _setMaxPriceDiff(MAX_PRICE_DIFF_DENOMINATOR);
        _updateVaderPrice();
        _setMaxPriceDiff(_maxPriceDiff);
    }
}