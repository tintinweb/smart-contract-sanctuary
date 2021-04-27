/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.4;

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
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a uq112x112 into a uint with 18 decimals of precision
  function decode112with18(uq112x112 memory self) internal pure returns (uint) {
    // we only have 256 - 224 = 32 bits to spare, so scaling up by ~60 bits is dangerous
    // instead, get close to:
    //  (x * 1e18) >> 112
    // without risk of overflowing, e.g.:
    //  (x) / 2 ** (112 - lg(1e18))
    return uint(self._x) / 5192296858534827;
  }

  // returns a uq112x112 which represents the ratio of the numerator to the denominator
  // equivalent to encode(numerator).div(denominator)
  // function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
  //   require(denominator > 0, "DIV_BY_ZERO");
  //   return uq112x112((uint224(numerator) << 112) / denominator);
  // }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract OlympusBondingCalculator {
    using FixedPoint for *;
    using SafeMath for uint;
    using SafeMath for uint112;
    
    // gets constant product of LP token
    function _getKValue( address token_ ) internal view returns( uint k_ )  {
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( token_ ).getReserves();
        k_ = reserve0.mul( reserve1 ).div( 1e9 );
    }
    
    function valuation( address token_, uint amount_ ) external view returns ( uint ) {
        return _totalValuation( token_ )
            .mul( FixedPoint.fraction( amount_, IUniswapV2Pair( token_ ).totalSupply() )
            .decode112with18().div( 1e18 ) );
    }

    function _totalValuation( address token_ ) internal view returns ( uint ) {
        // *** When deposit amount is small does not pick up principle valuation *** \\
        return _getKValue( token_ ).sqrrt().mul(2);
    }

    function markdown( address token_ ) external view returns ( uint ) {
        ( uint reserve0, , ) = IUniswapV2Pair( token_ ).getReserves();
        return reserve0.mul( 2e9 ).div( _totalValuation( token_ ) );
    }
}