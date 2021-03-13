/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IUniswapV2ERC20 {
    function decimals() external pure returns (uint8);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
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
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}

library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;

  function decode112with18(uq112x112 memory self) internal pure returns (uint) {
    return uint(self._x) / 5192296858534827;
  }

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
}

library UniswapV2OracleLibrary {
    using FixedPoint for *;

    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

interface ITWAPOracle {
  function uniV2CompPairAddressForLastEpochUpdateBlockTimstamp( address ) external returns ( uint32 );
  function priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp( address tokenToPrice_, address tokenForPriceComparison_, uint epochPeriod_ ) external returns ( uint32 );
  function pricedTokenForPricingTokenForEpochPeriodForPrice( address, address, uint ) external returns ( uint );
  function pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice( address, address, uint ) external returns ( uint );
  function updateTWAP( address uniV2CompatPairAddressToUpdate_, uint eopchPeriodToUpdate_ ) external returns ( bool );
}

interface ITimeConstants {

  function SECOND() external returns ( uint) ;
  function MINUTE() external returns ( uint );
  function HOUR() external returns ( uint );
  function HOURS8() external returns ( uint );
  function DAY() external returns ( uint );
  function WEEK() external returns ( uint );
}

contract TimeConstants is ITimeConstants {
  uint public constant override SECOND = 1 seconds;
  uint public constant override MINUTE = 1 minutes;
  uint public constant override HOUR = 1 hours;
  uint public constant override HOURS8 = 8 hours;
  uint public constant override DAY = 1 days;
  uint public constant override WEEK = 1 weeks;
}

 contract UniV2CompatiableTWAPOracle is ITWAPOracle, TimeConstants {

  using FixedPoint for *;
  using SafeMath for uint256;

  mapping( address => uint32 ) override public uniV2CompPairAddressForLastEpochUpdateBlockTimstamp;

  mapping( address => mapping( address => mapping( uint => uint32 ) ) ) override public priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp;

  mapping( address => mapping( address => mapping( uint => uint ) ) ) override public pricedTokenForPricingTokenForEpochPeriodForPrice;

  mapping( address => mapping( address => mapping( uint => uint ) ) ) override public pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice;

  function getTWAP( address token0_, address token1_, uint priceEpochPeriod_ ) external view returns ( uint epochTWAP_, uint32 blockTimestamp_ ) {
    epochTWAP_ = pricedTokenForPricingTokenForEpochPeriodForPrice[token0_][token1_][priceEpochPeriod_];
    blockTimestamp_ = priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp[token0_][token1_][priceEpochPeriod_];
  }

  function getPreviousEpochTWAP( address token0_, address token1_, uint epochPeriod_) external view returns ( uint previousEpochTWAP_ ) {
    previousEpochTWAP_ = pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice[token0_][token1_][epochPeriod_];
  }

  function getTWAPRange( address token0_, address token1_, uint epochPeriod_ ) external view returns ( uint epochTWAP_, uint previousEpochTWAP_, uint32 blockTimestamp_ ) {
    epochTWAP_ = pricedTokenForPricingTokenForEpochPeriodForPrice[token0_][token1_][epochPeriod_];
    previousEpochTWAP_ = pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice[token0_][token1_][epochPeriod_];
    blockTimestamp_ = priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp[token0_][token1_][epochPeriod_];
  }

  function updateTWAP( address uniV2CompatPairAddressToUpdate_, uint eopchPeriodToUpdate_ ) external override returns ( bool ) {

    // We must retrieve thne entire tuple as UniswapV2Pair does not expose the blockTimestamp directly.
    (uint price0Cumulative_, uint price1Cumulative_, uint32 uniV2PairLastBlockTimestamp_) =
            UniswapV2OracleLibrary.currentCumulativePrices(address(uniV2CompatPairAddressToUpdate_));

    uint32 timeElapsed_ = _calculateElapsedTimeSinceLastUpdate( uniV2PairLastBlockTimestamp_, uniV2CompPairAddressForLastEpochUpdateBlockTimstamp[uniV2CompatPairAddressToUpdate_] );

    if( timeElapsed_ >= eopchPeriodToUpdate_ ) {

      address token0_ = IUniswapV2Pair(uniV2CompatPairAddressToUpdate_).token0();
      address token1_ = IUniswapV2Pair(uniV2CompatPairAddressToUpdate_).token1();

      uint token0LastTWAP_ = pricedTokenForPricingTokenForEpochPeriodForPrice
        [token0_]
        [token1_]
        [eopchPeriodToUpdate_];

      pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice
        [token0_]
        [token1_]
        [eopchPeriodToUpdate_] = token0LastTWAP_;

      uint token0EpochTWAP_ = _calculateTWAP( price0Cumulative_, token0LastTWAP_, timeElapsed_ );

      uint token1LastTWAP_ = pricedTokenForPricingTokenForEpochPeriodForPrice
        [token1_]
        [token0_]
        [eopchPeriodToUpdate_];

      pricedTokenForPricingTokenForEpochPeriodForLastEpochPrice
        [token1_]
        [token0_]
        [eopchPeriodToUpdate_] = token1LastTWAP_;

      uint token1EpochTWAP_ = _calculateTWAP( price1Cumulative_, token1LastTWAP_, timeElapsed_ );

      pricedTokenForPricingTokenForEpochPeriodForPrice
        [token1_]
        [token0_]
        [eopchPeriodToUpdate_] = token1EpochTWAP_;

      uniV2CompPairAddressForLastEpochUpdateBlockTimstamp[uniV2CompatPairAddressToUpdate_] = uniV2PairLastBlockTimestamp_;
      priceTokenAddressForPricingTokenAddressForLastEpochUpdateBlockTimstamp[token0_][token1_][eopchPeriodToUpdate_] = uniV2PairLastBlockTimestamp_;
    }

    return true;
  }

  function _calculateElapsedTimeSinceLastUpdate( uint32 uniV2PairLastBlockTimestamp_, uint32 epochLastTimestamp_ ) internal view returns ( uint32 ) {
    return uniV2PairLastBlockTimestamp_ - epochLastTimestamp_; // overflow is desired
  }

  function _calculateTWAP( uint currentCumulativePrice_, uint lastCumulativePrice_, uint32 timeElapsed_ ) internal view returns ( uint ) {
    return FixedPoint.uq112x112( uint224( ( currentCumulativePrice_ - lastCumulativePrice_) / timeElapsed_) ).decode112with18().div(1e8);
  }
}