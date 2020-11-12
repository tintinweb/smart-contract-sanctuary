pragma solidity ^0.6.6;

contract ABDKMathQuad {
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
  /**
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /**
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /**
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /**
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /**
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    if (x == 0) return bytes16 (0);
    else {
      uint256 result = x;

      uint256 msb = msb (result);
      if (msb < 112) result <<= 112 - msb;
      else if (msb > 112) result >>= msb - 112;

      result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

    if (exponent < 16383) return 0; // Underflow

    require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

    require (exponent <= 16638); // Overflow
    uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
      0x10000000000000000000000000000;

    if (exponent < 16495) result >>= 16495 - exponent;
    else if (exponent > 16495) result <<= exponent - 16495;

    return result;
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function addABDK (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) { 
        if (x == y) return x;
        else return NaN;
      } else return x; 
    } else if (yExponent == 0x7FFF) return y;
    else {
      bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
      else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
      else {
        int256 delta = int256 (xExponent) - int256 (yExponent);
  
        if (xSign == ySign) {
          if (delta > 112) return x;
          else if (delta > 0) ySignifier >>= delta;
          else if (delta < -112) return y;
          else if (delta < 0) {
            xSignifier >>= -delta;
            xExponent = yExponent;
          }
  
          xSignifier += ySignifier;
  
          if (xSignifier >= 0x20000000000000000000000000000) {
            xSignifier >>= 1;
            xExponent += 1;
          }
  
          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else {
            if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
            else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
            return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier)); 
          }
        } else {
          if (delta > 0) {
            xSignifier <<= 1;
            xExponent -= 1;
          } else if (delta < 0) {
            ySignifier <<= 1;
            xExponent = yExponent - 1;
          }

          if (delta > 112) ySignifier = 1;
          else if (delta > 1) ySignifier = (ySignifier - 1 >> delta - 1) + 1;
          else if (delta < -112) xSignifier = 1;
          else if (delta < -1) xSignifier = (xSignifier - 1 >> -delta - 1) + 1;

          if (xSignifier >= ySignifier) xSignifier -= ySignifier;
          else {
            xSignifier = ySignifier - xSignifier;
            xSign = ySign;
          }

          if (xSignifier == 0)
            return POSITIVE_ZERO;

          uint256 msb = msb (xSignifier);

          if (msb == 113) {
            xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            xExponent += 1;
          } else if (msb < 112) {
            uint256 shift = 112 - msb;
            if (xExponent > shift) {
              xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent -= shift;
            } else {
              xSignifier <<= xExponent - 1;
              xExponent = 0;
            }
          } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          if (xExponent == 0x7FFF)
            return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
          else return bytes16 (uint128 (
              (xSign ? 0x80000000000000000000000000000000 : 0) |
              (xExponent << 112) |
              xSignifier));
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function subABDK (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    return addABDK(x, y ^ 0x80000000000000000000000000000000);
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mulABDK (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) {
        if (x == y) return x ^ y & 0x80000000000000000000000000000000;
        else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
        else return NaN;
      } else {
        if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      }
    } else if (yExponent == 0x7FFF) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return y ^ x & 0x80000000000000000000000000000000;
    } else {
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      xSignifier *= ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      xExponent += yExponent;

      uint256 msb =
        xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
        xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
        msb (xSignifier);

      if (xExponent + msb < 16496) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb < 16608) { // Subnormal
        if (xExponent < 16496)
          xSignifier >>= 16496 - xExponent;
        else if (xExponent > 16496)
          xSignifier <<= xExponent - 16496;
        xExponent = 0;
      } else if (xExponent + msb > 49373) {
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else {
        if (msb > 112)
          xSignifier >>= msb - 112;
        else if (msb < 112)
          xSignifier <<= 112 - msb;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb - 16607;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function divABDK (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

    if (xExponent == 0x7FFF) {
      if (yExponent == 0x7FFF) return NaN;
      else return x ^ y & 0x80000000000000000000000000000000;
    } else if (yExponent == 0x7FFF) {
      if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
      else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
    } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
      if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
      else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
    } else {
      uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (yExponent == 0) yExponent = 1;
      else ySignifier |= 0x10000000000000000000000000000;

      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xExponent == 0) {
        if (xSignifier != 0) {
          uint shift = 226 - msb (xSignifier);

          xSignifier <<= shift;

          xExponent = 1;
          yExponent += shift - 114;
        }
      }
      else {
        xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
      }

      xSignifier = xSignifier / ySignifier;
      if (xSignifier == 0)
        return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
            NEGATIVE_ZERO : POSITIVE_ZERO;

      assert (xSignifier >= 0x1000000000000000000000000000);

      uint256 msb =
        xSignifier >= 0x80000000000000000000000000000 ? msb (xSignifier) :
        xSignifier >= 0x40000000000000000000000000000 ? 114 :
        xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

      if (xExponent + msb > yExponent + 16497) { // Overflow
        xExponent = 0x7FFF;
        xSignifier = 0;
      } else if (xExponent + msb + 16380  < yExponent) { // Underflow
        xExponent = 0;
        xSignifier = 0;
      } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
        if (xExponent + 16380 > yExponent)
          xSignifier <<= xExponent + 16380 - yExponent;
        else if (xExponent + 16380 < yExponent)
          xSignifier >>= yExponent - xExponent - 16380;

        xExponent = 0;
      } else { // Normal
        if (msb > 112)
          xSignifier >>= msb - 112;

        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        xExponent = xExponent + msb + 16269 - yExponent;
      }

      return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
          xExponent << 112 | xSignifier));
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
    uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
    uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
    else if (xExponent > 16397)
      return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
    else if (xExponent < 16255)
      return 0x3FFF0000000000000000000000000000;
    else {
      if (xExponent == 0) xExponent = 1;
      else xSignifier |= 0x10000000000000000000000000000;

      if (xExponent > 16367)
        xSignifier <<= xExponent - 16367;
      else if (xExponent < 16367)
        xSignifier >>= 16367 - xExponent;

      if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
        return POSITIVE_ZERO;

      if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        return POSITIVE_INFINITY;

      uint256 resultExponent = xSignifier >> 128;
      xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
      if (xNegative && xSignifier != 0) {
        xSignifier = ~xSignifier;
        resultExponent += 1;
      }

      uint256 resultSignifier = 0x80000000000000000000000000000000;
      if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
      if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
      if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
      if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
      if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
      if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
      if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
      if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
      if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
      if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
      if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
      if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
      if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
      if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
      if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
      if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
      if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
      if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
      if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
      if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
      if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
      if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
      if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
      if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
      if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
      if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
      if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
      if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
      if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
      if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
      if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
      if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
      if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
      if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
      if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
      if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
      if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
      if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
      if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
      if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
      if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
      if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
      if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
      if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
      if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
      if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
      if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
      if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
      if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
      if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
      if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
      if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
      if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
      if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
      if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
      if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
      if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
      if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
      if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
      if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
      if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
      if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
      if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
      if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

      if (!xNegative) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent += 0x3FFF;
      } else if (resultExponent <= 0x3FFE) {
        resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        resultExponent = 0x3FFF - resultExponent;
      } else {
        resultSignifier = resultSignifier >> resultExponent - 16367;
        resultExponent = 0;
      }

      return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    return pow_2 (mulABDK (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
  }
  
  function msb (uint256 x) private pure returns (uint256) {
    require (x > 0);

    uint256 result = 0;

    if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
    if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
    if (x >= 0x100000000) { x >>= 32; result += 32; }
    if (x >= 0x10000) { x >>= 16; result += 16; }
    if (x >= 0x100) { x >>= 8; result += 8; }
    if (x >= 0x10) { x >>= 4; result += 4; }
    if (x >= 0x4) { x >>= 2; result += 2; }
    if (x >= 0x2) result += 1; // No need to shift x anymore

    return result;
  }
  
  function totalSupplyAtTime (uint t) internal pure returns (bytes16 fin) {
      bytes16 xQuad = fromUInt(t);
      bytes16 xQuadSub = subABDK(xQuad, 0x4016e133800000000000000000000000);
      bytes16 exponent = mulABDK(xQuadSub, 0xbfea0c6f7a0b5ed8d36b4c7f34938583);
      bytes16 expExp = exp(exponent);
      bytes16 bottom = addABDK(0x3fff0000000000000000000000000000, expExp);
      bytes16 whole = divABDK(0x402a22db571485000000000000000000, bottom);
      fin = addABDK(whole, 0x401f73b9fbd700000000000000000000);
  }
  
}

contract SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
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
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    
}

contract ERC20wRebase is SafeMath, ABDKMathQuad {

  string public name;
  string public symbol;
  uint8 public decimals;
  address public _owner;
  uint private supplyTotal;
  uint private constant _decimals = 9;
  uint private constant uintMax = ~uint256(0);
  uint private constant tokensMax = 10**4 * 10**_decimals;
  uint private tokensInitial = 10**1 * 10**_decimals;
  uint internal unitsPerToken;
  uint private unitsTotal = uintMax - (uintMax % tokensMax);
  uint public tokensCurrent;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  constructor() public {
    name = "Azizos";
    symbol = "AZIZ";
    decimals = 9;
    supplyTotal = tokensMax;
    unitsPerToken = div(unitsTotal, supplyTotal);
    uint unitsInitial =  mul(unitsPerToken, tokensInitial);
    tokensCurrent = tokensInitial;
    balances[msg.sender] = unitsInitial;
    _owner = msg.sender;
    emit Transfer(address(0), msg.sender, tokensInitial);
  }

  function rebase(int supplyDelta) external onlyOwner returns (uint) {
    if (supplyDelta == 0) {
        emit RebaseEvent(supplyDelta);
        return supplyTotal;
    }
    
    if (supplyDelta < 0) {
        tokensCurrent = sub(tokensCurrent, div(mul(uint(-supplyDelta), tokensCurrent), supplyTotal));
        supplyTotal = sub(supplyTotal, uint(-supplyDelta));
    }
    
    if (supplyDelta > 0) {
        tokensCurrent = add(tokensCurrent, div(mul(uint(supplyDelta), tokensCurrent), supplyTotal));
        supplyTotal = add(supplyTotal, uint(supplyDelta));
    }

    unitsPerToken = div(unitsTotal, supplyTotal);

    emit RebaseEvent(supplyDelta);
    return supplyTotal;
  }

  function totalSupply() public view returns (uint) {
    return tokensCurrent;
  }
  
  function balanceOf(address who) public view returns (uint) {
    return div(balances[who], unitsPerToken);
  }

  function transfer(address to, uint value) public returns (bool) {
    uint unitValue = mul(value, unitsPerToken);
    balances[msg.sender] = sub(balances[msg.sender], unitValue);
    balances[to] = add(balances[to], unitValue);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function allowance(address owner_, address spender) public view returns (uint) {
    return allowed[owner_][spender];
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    allowed[from][msg.sender] = sub(allowed[from][msg.sender], value);

    uint unitValue = mul(value, unitsPerToken);
    balances[from] = sub(balances[from], unitValue);
    balances[to] = add(balances[to], unitValue);
    emit Transfer(from, to, value);

    return true;
  }

  function approve(address spender, uint value) public returns (bool) {
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function increaseAllowance(address spender, uint addedValue) public returns (bool) {
    allowed[msg.sender][spender] = add(allowed[msg.sender][spender], addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      allowed[msg.sender][spender] = 0;
    } else {
      allowed[msg.sender][spender] = sub(oldValue, subtractedValue);
    }
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  event RebaseEvent(int supplyDelta);

}

abstract contract TwinContract {
    
    function totalBalanceOf(address _of) virtual public view returns (uint256 amount);
    function mint(address unlocker, uint unlockAmount) virtual external returns (bool);
    function getRewardsGiven() virtual public view returns(uint);
    function rebase(int supplyDelta) virtual external returns (uint);
    function getTokensCurrent() virtual public view returns(uint);
    function getSupplyTotal() virtual public view returns (uint);
    function setTokensCurrent(uint newTokens) virtual external returns(uint);
    function getUnitsPerToken() virtual public view returns (uint);
    
}

abstract contract ThirdPartyContract {
    
    function transferFrom(address from, address to, uint256 value) virtual public returns (bool);
    function transfer(address to, uint value) virtual public returns (bool);
    
}

contract Azizos is ERC20wRebase {
  
  uint public totalValueTPT;
  uint public totalRewardsGivenTPT;
  
  address public twinAddress;
  TwinContract private twinContract;
  address public thirdPartyTokenAddress;
  ThirdPartyContract private thirdPartyContract;
  uint public lockingEnabledTime;
  bool public lockEnabled = false;

  event Mint(address mintee, uint amount);
  event Lock(address locker, uint lockAmount, uint duration);
  event Unlock(address unlocker);
  event UpdatePosition(address updater, int amountDelta, int timeDelta);
  event LockTPT(address locker, uint lockAmount, uint duration);
  event UnlockTPT(address unlocker);
  event UpdatePositionTPT(address updater, int amountDelta, int timeDelta);
  event EnableLock();
  event SetTwin(address twinAddress);
  event SetTPT(address tptAddress);
  event ChangeOwner(address newOwner);
  
  modifier onlyTwin() {
    require(msg.sender == twinAddress, "Ownable: caller is not the owner");
    _;
  }
  
  function setTwin(address addr) external onlyOwner returns (bool) {
    require(twinAddress == address(0), "TWIN_ALREADY_SET");
    twinAddress = addr;
    twinContract = TwinContract(addr);
    emit SetTwin(addr);
    return true;
  }
  
  function setTPT(address addr) external onlyOwner returns (bool) {
      thirdPartyTokenAddress = addr;
      thirdPartyContract = ThirdPartyContract(addr);
      emit SetTPT(addr);
      return true;
  }
  
  function changeOwner(address addr) external onlyOwner returns (bool) {
    _owner = addr;
    return true;
  }

  mapping(address => lockStruct) public locked;
  mapping(address => lockTPTStruct) public lockedTPT;
  
  struct lockStruct {
    uint amount;
    bytes16 percentSupplyLocked;
    uint unlockTime;
    bool punishmentFlag;
    uint confirmedReward;
    bytes16 supplyWhenLastModified;
  }
  
  struct lockTPTStruct {
    uint amount;
    uint value;
    uint unlockTime;
    bool punishmentFlag;
    uint confirmedReward;
    bytes16 supplyWhenLastModified;
  }
  
  function mint(address unlocker, uint unlockAmount) external onlyTwin returns (bool) {
    uint addedTokens = unlockAmount;
    uint addedUnits = mul(unitsPerToken, addedTokens);
    tokensCurrent = add(tokensCurrent, addedTokens);
    balances[unlocker] = add(balances[unlocker], addedUnits);
    emit Mint(unlocker, unlockAmount);
    return true;
  }
  
  function enableLocking() external onlyOwner returns (bool) {
    require(!lockEnabled, "LOCKING_ALREADY_ENABLED");
    lockEnabled = true;
    lockingEnabledTime = now;
    emit EnableLock();
    return lockEnabled;
  }
  
  function lock(uint amount, uint duration) public returns (bool) {
    require(locked[msg.sender].amount == 0, "POSITION_ALREADY_EXISTS");
    require(amount > 0, "INVALID_AMOUNT");
    require(duration > 0, "INVALID_DURATION");
    require(lockEnabled, "LOCKING_NOT_ENABLED_YET");
    uint unitAmount = mul(amount, unitsPerToken);
    uint unitsCurrent = mul(tokensCurrent, unitsPerToken);
    bytes16 percentSupplyLocked = divABDK(fromUInt(unitAmount), fromUInt(unitsCurrent));
    uint unlockTime = add(now, duration);
    locked[msg.sender] = lockStruct(unitAmount, percentSupplyLocked, unlockTime, false, 0, mulABDK(totalSupplyAtTime(sub(now, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60));
    transfer(address(this), amount);
    emit Lock(msg.sender, amount, duration);
    return true;
  }
  
  function lockTPT(uint amount, uint duration) public returns (bool) {
    require(lockedTPT[msg.sender].amount == 0, "POSITION_ALREADY_EXISTS");
    require(amount > 0, "INVALID_AMOUNT");
    require(duration > 0, "INVALID_DURATION");
    require(lockEnabled, "LOCKING_NOT_ENABLED_YET");
    uint value = mul(amount, mul(duration, duration));
    totalValueTPT = add(totalValueTPT, value);
    lockedTPT[msg.sender] = lockTPTStruct(amount, value, add(now, duration), false, 0, mulABDK(totalSupplyAtTime(sub(now, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60));
    thirdPartyContract.transferFrom(msg.sender, address(this), amount);
    emit LockTPT(msg.sender, amount, duration);
    return true;
  }

  function calculateUnlockReward(address unlocker, uint unlockTime, bool includeConfirmed) private view returns (uint reward) {
    bool pseudoFlag = false;
    if (locked[unlocker].punishmentFlag || locked[unlocker].unlockTime > unlockTime) {
      pseudoFlag = true;
    }
    int timeUnlockTimeDiff = int(unlockTime) - int(locked[unlocker].unlockTime);
    if (timeUnlockTimeDiff < 0) {
      timeUnlockTimeDiff = -timeUnlockTimeDiff;
    }
    uint minNowUnlockTime = (unlockTime + locked[unlocker].unlockTime) / 2 - uint(timeUnlockTimeDiff) / 2;
    require(minNowUnlockTime == unlockTime || minNowUnlockTime == locked[unlocker].unlockTime, "MIN_ERROR");
    reward = toUInt(mulABDK(subABDK(mulABDK(totalSupplyAtTime(sub(minNowUnlockTime, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60), locked[unlocker].supplyWhenLastModified), locked[unlocker].percentSupplyLocked));
    if (includeConfirmed) {
        reward = add(reward, locked[unlocker].confirmedReward);
    }
    reward = div(reward, 3);
    if (pseudoFlag) {
      reward = div(reward, 2);
    }
  }
  
  function calculateUnlockRewardTPT(address unlocker, uint unlockTime, bool includeConfirmed) private view returns (uint reward) {
    bool pseudoFlag = false;
    if(lockedTPT[unlocker].punishmentFlag || lockedTPT[unlocker].unlockTime > unlockTime) {
      pseudoFlag = true;
    }
    int timeUnlockTimeDiff = int(unlockTime) - int(lockedTPT[unlocker].unlockTime);
    if (timeUnlockTimeDiff < 0) {
      timeUnlockTimeDiff = -timeUnlockTimeDiff;
    }
    uint minNowUnlockTime = (unlockTime + lockedTPT[unlocker].unlockTime) / 2 - uint(timeUnlockTimeDiff) / 2;
    require(minNowUnlockTime == unlockTime || minNowUnlockTime == lockedTPT[unlocker].unlockTime, "MIN_ERROR");
    reward = toUInt(mulABDK(subABDK(mulABDK(totalSupplyAtTime(sub(minNowUnlockTime, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60), lockedTPT[unlocker].supplyWhenLastModified), divABDK(fromUInt(lockedTPT[unlocker].value), fromUInt(totalValueTPT))));
    if (includeConfirmed) {
        reward = add(reward, lockedTPT[unlocker].confirmedReward);
    }
    reward = toUInt(mulABDK(fromUInt(reward), subABDK(0x3fff0000000000000000000000000000, divABDK(fromUInt(totalRewardsGivenTPT), mulABDK(subABDK(totalSupplyAtTime(sub(now, lockingEnabledTime)), 0x40202a05f20000000000000000000000), 0x40d3c25c268497681c2650cb4be40d60)))));
    reward = toUInt(mulABDK(fromUInt(reward), 0x3ffe5555555555555555555555555555));
    if (pseudoFlag) {
      reward = div(reward, 2);
    }      
  }
  
  function updatePosition(int amountDelta, int durationDelta) public returns (bool) {
    require(locked[msg.sender].amount > 0, "NO_POSITION");

    uint confirmedReward = calculateUnlockReward(msg.sender, now, false) * 2;
    locked[msg.sender].confirmedReward = add(locked[msg.sender].confirmedReward, confirmedReward);

    uint unitsCurrent = mul(tokensCurrent, unitsPerToken);

    if (locked[msg.sender].unlockTime < now) {
        require (durationDelta > 0, "DURATION_DELTA_OF_EXPIRED_POSITION_MUST_BE_POSITIVE");
        require (amountDelta >= 0, "AMOUNT_DELTA_OF_EXPIRE_POSITION_MUST_BE_AT_LEAST_ZERO");
        bytes16 percentSupplyLocked = divABDK(fromUInt(locked[msg.sender].amount), fromUInt(unitsCurrent));
        locked[msg.sender].percentSupplyLocked = percentSupplyLocked;
        locked[msg.sender].unlockTime = now;
    }

    if (amountDelta > 0) {
      uint unitDelta = mul(uint(amountDelta), unitsPerToken);
      locked[msg.sender].amount = add(locked[msg.sender].amount, unitDelta);
      bytes16 percentSupplyLocked = divABDK(fromUInt(unitDelta), fromUInt(unitsCurrent));
      locked[msg.sender].percentSupplyLocked = addABDK(locked[msg.sender].percentSupplyLocked, percentSupplyLocked);
      transfer(address(this), uint(amountDelta));
    }
    
    if (amountDelta < 0) {
      uint unitDelta = mul(uint(-amountDelta), unitsPerToken);
      locked[msg.sender].amount = sub(locked[msg.sender].amount, unitDelta);
      bytes16 percentSupplyLocked = divABDK(fromUInt(unitDelta), fromUInt(unitsCurrent));
      locked[msg.sender].percentSupplyLocked = subABDK(locked[msg.sender].percentSupplyLocked, percentSupplyLocked);
      locked[msg.sender].punishmentFlag = true;
      this.transfer(msg.sender, uint(-amountDelta));
    }

    if (durationDelta < 0) {
      locked[msg.sender].unlockTime = sub(locked[msg.sender].unlockTime, uint(-durationDelta));
      locked[msg.sender].punishmentFlag = true;
    }

    if (durationDelta > 0) {
      locked[msg.sender].unlockTime = add(locked[msg.sender].unlockTime, uint(durationDelta));
    }
    
    locked[msg.sender].supplyWhenLastModified = mulABDK(totalSupplyAtTime(sub(now, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60);

    require(locked[msg.sender].amount > 0, "POSITION_AMOUNT_CANNOT_BE_NEGATIVE");
    require(locked[msg.sender].unlockTime > now, "UNLOCKTIME_MUST_BE_IN_FUTURE");
    
    emit UpdatePosition(msg.sender, amountDelta, durationDelta);
    return true;
  }
  
  function updatePositionTPT(int amountDelta, int durationDelta) public returns (bool) {
    require(lockedTPT[msg.sender].amount > 0, "NO_POSITION");
    
    uint confirmedReward = calculateUnlockRewardTPT(msg.sender, now, false) * 2;
    lockedTPT[msg.sender].confirmedReward = add(lockedTPT[msg.sender].confirmedReward, confirmedReward);

    if (lockedTPT[msg.sender].unlockTime < now) {
        require (durationDelta > 0, "DURATION_DELTA_OF_EXPIRED_POSITION_MUST_BE_POSITIVE");
        require (amountDelta >= 0, "AMOUNT_DELTA_OF_EXPIRE_POSITION_MUST_BE_AT_LEAST_ZERO");
        lockedTPT[msg.sender].unlockTime = now;
    }

    if (amountDelta > 0) {
      lockedTPT[msg.sender].amount = add(lockedTPT[msg.sender].amount, uint(amountDelta));
      uint timeUntilUnlock = sub(lockedTPT[msg.sender].unlockTime, now);
      uint value = mul(uint(amountDelta), mul(timeUntilUnlock, timeUntilUnlock));
      totalValueTPT = add(totalValueTPT, value);
      lockedTPT[msg.sender].value = add(lockedTPT[msg.sender].value, value);
      thirdPartyContract.transferFrom(msg.sender, address(this), uint(amountDelta));
    }
    
    if (amountDelta < 0) {
      lockedTPT[msg.sender].amount = sub(lockedTPT[msg.sender].amount, uint(-amountDelta));
      uint timeUntilUnlock = sub(lockedTPT[msg.sender].unlockTime, now);
      uint value = mul(uint(-amountDelta), mul(timeUntilUnlock, timeUntilUnlock));
      totalValueTPT = sub(totalValueTPT, value);
      lockedTPT[msg.sender].value = sub(lockedTPT[msg.sender].value, value);
      lockedTPT[msg.sender].punishmentFlag = true;
      thirdPartyContract.transfer(msg.sender, uint(-amountDelta));
    }

    if (durationDelta < 0) {
      lockedTPT[msg.sender].unlockTime = sub(lockedTPT[msg.sender].unlockTime, uint(-durationDelta));
      uint value = mul(lockedTPT[msg.sender].amount, mul(uint(-durationDelta), uint(-durationDelta)));
      totalValueTPT = sub(totalValueTPT, value);
      lockedTPT[msg.sender].value = sub(lockedTPT[msg.sender].value, value);
      lockedTPT[msg.sender].punishmentFlag = true;
    }

    if (durationDelta > 0) {
      lockedTPT[msg.sender].unlockTime = add(lockedTPT[msg.sender].unlockTime, uint(durationDelta));
      uint value = mul(lockedTPT[msg.sender].amount, mul(uint(durationDelta), uint(durationDelta)));
      totalValueTPT = add(totalValueTPT, value);
      lockedTPT[msg.sender].value = add(lockedTPT[msg.sender].value, value);
    }
    
    lockedTPT[msg.sender].supplyWhenLastModified = mulABDK(totalSupplyAtTime(sub(now, lockingEnabledTime)), 0x40d3c25c268497681c2650cb4be40d60);
    
    require(lockedTPT[msg.sender].amount > 0, "POSITION_AMOUNT_CANNOT_BE_NEGATIVE");
    require(lockedTPT[msg.sender].unlockTime > now, "UNLOCKTIME_MUST_BE_IN_FUTURE");
    
    emit UpdatePositionTPT(msg.sender, amountDelta, durationDelta);
    return true;
  }
  
  function unlock() public returns (bool success) {
    require(locked[msg.sender].amount > 0, "NO_POSITION");
    uint tokenAmount = div(locked[msg.sender].amount, unitsPerToken);
    this.transfer(msg.sender, tokenAmount);
    uint reward = calculateUnlockReward(msg.sender, now, true);
    uint rewardTokens = div(reward, twinContract.getUnitsPerToken());
    success = twinContract.mint(msg.sender, rewardTokens);
    locked[msg.sender] = lockStruct(0, bytes16(0), 0, false, 0, bytes16(0));
    require(success, "MINT_FAILED");
    emit Unlock(msg.sender);
  }
  
  function unlockTPT() public returns (bool success) {
    require(lockedTPT[msg.sender].amount > 0, "NO_POSITION");
    thirdPartyContract.transfer(msg.sender, lockedTPT[msg.sender].amount);
    uint reward = calculateUnlockRewardTPT(msg.sender, now, true);
    totalRewardsGivenTPT = add(reward, totalRewardsGivenTPT);
    uint rewardTokens = div(reward, twinContract.getUnitsPerToken());
    success = twinContract.mint(msg.sender, rewardTokens);
    totalValueTPT = sub(totalValueTPT, lockedTPT[msg.sender].value);
    lockedTPT[msg.sender] = lockTPTStruct(0, 0, 0, false, 0, bytes16(0));
    require(success, "MINT_FAILED");
    emit UnlockTPT(msg.sender);
  }
  
  function getRewardTokens(address addr, uint time) public view returns (uint) {
    require(locked[addr].amount > 0, "NO_POSITION");
    return div(calculateUnlockReward(addr, time, true), twinContract.getUnitsPerToken());
  }
  
  function getLockedTokens(address addr) public view returns (uint) {
    require(locked[addr].amount > 0, "NO_POSITION");
    return div(locked[addr].amount, unitsPerToken);   
  }
  
  function getRewardTokensTPT(address addr, uint time) public view returns (uint) {
    require(lockedTPT[addr].amount > 0, "NO_POSITION");
    return div(calculateUnlockRewardTPT(addr, time, true), twinContract.getUnitsPerToken());
  }
  
  function getUnitsPerToken() public view returns (uint) {
      return unitsPerToken;
  }

}