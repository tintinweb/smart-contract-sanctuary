//SourceUnit: ABDKMathQuad.sol

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt (int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt (bytes16 x) internal pure returns (int256) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16638); // Overflow
        if (exponent < 16383) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16495) result >>= 16495 - exponent;
        else if (exponent > 16495) result <<= exponent - 16495;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
            return -int256 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int256 (result);
        }
    }

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
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128 (int256 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint256 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128 (bytes16 x) internal pure returns (int256) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16510); // Overflow
        if (exponent < 16255) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16367) result >>= 16367 - exponent;
        else if (exponent > 16367) result <<= exponent - 16367;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
            return -int256 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int256 (result);
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64 (int128 x) internal pure returns (bytes16) {
        if (x == 0) return bytes16 (0);
        else {
            // We rely on overflow behavior here
            uint256 result = uint128 (x > 0 ? x : -x);

            uint256 msb = msb (result);
            if (msb < 112) result <<= 112 - msb;
            else if (msb > 112) result >>= msb - 112;

            result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
            if (x < 0) result |= 0x80000000000000000000000000000000;

            return bytes16 (uint128 (result));
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    function to64x64 (bytes16 x) internal pure returns (int128) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        require (exponent <= 16446); // Overflow
        if (exponent < 16319) return 0; // Underflow

        uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

        if (exponent < 16431) result >>= 16431 - exponent;
        else if (exponent > 16431) result <<= exponent - 16431;

        if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
            require (result <= 0x80000000000000000000000000000000);
            return -int128 (result); // We rely on overflow behavior here
        } else {
            require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (result);
        }
    }

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple (bytes32 x) internal pure returns (bytes16) {
        bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

        uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
        uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFFF) {
            if (significand > 0) return NaN;
            else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        }

        if (exponent > 278526)
            return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
        else if (exponent < 245649)
            return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
        else if (exponent < 245761) {
            significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
            exponent = 0;
        } else {
            significand >>= 124;
            exponent -= 245760;
        }

        uint128 result = uint128 (significand | exponent << 112);
        if (negative) result |= 0x80000000000000000000000000000000;

        return bytes16 (result);
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple (bytes16 x) internal pure returns (bytes32) {
        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

        uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = msb (result);
                result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 245649 + msb;
            }
        } else {
            result <<= 124;
            exponent += 245760;
        }

        result |= exponent << 236;
        if (uint128 (x) >= 0x80000000000000000000000000000000)
            result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

        return bytes32 (result);
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble (bytes8 x) internal pure returns (bytes16) {
        uint256 exponent = uint64 (x) >> 52 & 0x7FF;

        uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

        if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
        else if (exponent == 0) {
            if (result > 0) {
                uint256 msb = msb (result);
                result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                exponent = 15309 + msb;
            }
        } else {
            result <<= 60;
            exponent += 15360;
        }

        result |= exponent << 112;
        if (x & 0x8000000000000000 > 0)
            result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble (bytes16 x) internal pure returns (bytes8) {
        bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

        uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
        uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        if (exponent == 0x7FFF) {
            if (significand > 0) return 0x7FF8000000000000; // NaN
            else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
        }

        if (exponent > 17406)
            return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
        else if (exponent < 15309)
            return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
        else if (exponent < 15361) {
            significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
            exponent = 0;
        } else {
            significand >>= 60;
            exponent -= 15360;
        }

        uint64 result = uint64 (significand | exponent << 52);
        if (negative) result |= 0x8000000000000000;

        return bytes8 (result);
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN (bytes16 x) internal pure returns (bool) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity (bytes16 x) internal pure returns (bool) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign (bytes16 x) internal pure returns (int8) {
        uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        if (absoluteX == 0) return 0;
        else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
        else return 1;
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign. 
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
        uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

        uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

        require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

        // Not infinities of the same sign
        require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

        if (x == y) return 0;
        else {
            bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
            bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

            if (negativeX) {
                if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
                else return -1;
            } else {
                if (negativeY) return 1;
                else return absoluteX > absoluteY ? int8 (1) : -1;
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything. 
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
        if (x == y) {
            return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
            0x7FFF0000000000000000000000000000;
        } else return false;
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
    function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
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
                    else if (delta > 0) ySignifier >>= uint256 (delta);
                    else if (delta < -112) return y;
                    else if (delta < 0) {
                        xSignifier >>= uint256 (-delta);
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
                    else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
                    else if (delta < -112) xSignifier = 1;
                    else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

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
    function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
        return add (x, y ^ 0x80000000000000000000000000000000);
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
    function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
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
    function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
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
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg (bytes16 x) internal pure returns (bytes16) {
        return x ^ 0x80000000000000000000000000000000;
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs (bytes16 x) internal pure returns (bytes16) {
        return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt (bytes16 x) internal pure returns (bytes16) {
        if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
        else {
            uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return POSITIVE_ZERO;

                bool oddExponent = xExponent & 0x1 == 0;
                xExponent = xExponent + 16383 >> 1;

                if (oddExponent) {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 113;
                    else {
                        uint256 msb = msb (xSignifier);
                        uint256 shift = (226 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= shift - 112 >> 1;
                    }
                } else {
                    if (xSignifier >= 0x10000000000000000000000000000)
                        xSignifier <<= 112;
                    else {
                        uint256 msb = msb (xSignifier);
                        uint256 shift = (225 - msb) & 0xFE;
                        xSignifier <<= shift;
                        xExponent -= shift - 112 >> 1;
                    }
                }

                uint256 r = 0x10000000000000000000000000000;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1;
                r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                uint256 r1 = xSignifier / r;
                if (r1 < r) r = r1;

                return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2 (bytes16 x) internal pure returns (bytes16) {
        if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
        else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO;
        else {
            uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
            if (xExponent == 0x7FFF) return x;
            else {
                uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) xExponent = 1;
                else xSignifier |= 0x10000000000000000000000000000;

                if (xSignifier == 0) return NEGATIVE_INFINITY;

                bool resultNegative;
                uint256 resultExponent = 16495;
                uint256 resultSignifier;

                if (xExponent >= 0x3FFF) {
                    resultNegative = false;
                    resultSignifier = xExponent - 0x3FFF;
                    xSignifier <<= 15;
                } else {
                    resultNegative = true;
                    if (xSignifier >= 0x10000000000000000000000000000) {
                        resultSignifier = 0x3FFE - xExponent;
                        xSignifier <<= 15;
                    } else {
                        uint256 msb = msb (xSignifier);
                        resultSignifier = 16493 - msb;
                        xSignifier <<= 127 - msb;
                    }
                }

                if (xSignifier == 0x80000000000000000000000000000000) {
                    if (resultNegative) resultSignifier += 1;
                    uint256 shift = 112 - msb (resultSignifier);
                    resultSignifier <<= shift;
                    resultExponent -= shift;
                } else {
                    uint256 bb = resultNegative ? 1 : 0;
                    while (resultSignifier < 0x10000000000000000000000000000) {
                        resultSignifier <<= 1;
                        resultExponent -= 1;

                        xSignifier *= xSignifier;
                        uint256 b = xSignifier >> 255;
                        resultSignifier += b ^ bb;
                        xSignifier >>= 127 + b;
                    }
                }

                return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
                resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln (bytes16 x) internal pure returns (bytes16) {
        return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
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
        return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     *         of x
     */
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
}

//SourceUnit: AvalonFactory.sol

pragma solidity ^0.5.8;

import './AvalonFee.sol';
import './Recommend.sol';
import './SwapTokenExchange.sol';
import './SwapStatistics.sol';
import './FixedSupplyToken.sol';


contract AvalonFactory {

    event NewExchange(address indexed token, address indexed exchange);

    address _usdtAddress;
    RecommendInterface _recommendInc;
    AvalonFee _avalonFee;
    SwapStatistics _statistics;

    mapping(address => address) tokenExchangeMap;
    mapping(string => address) symbolTokenMap;
    mapping(string => address) nameTokenMap;
    mapping(address => address) exchangeTokenMap;
    address [] exchanges;
    address [] tokens;
    address _contractOwner;


    modifier OwnerOnly() {
        require(_contractOwner == msg.sender);
        _;
    }

    constructor(address usdtAddress, address userAddress) public {
        require(usdtAddress != address(0), "FACTROY:ERR00001");
        _usdtAddress = usdtAddress;
        _recommendInc = new Recommend(2, userAddress);
        _avalonFee = new AvalonFee(userAddress);
        _statistics = new SwapStatistics();
        _contractOwner = msg.sender;
    }

    function createExchange(string memory _symbol, string memory _name, uint8 _decimals, uint256 _total) public returns (address payable){
        require(_total <= 100000000000, "FACTROY:ERR00004");
        require(_decimals <= 8, "FACTROY:ERR00005");
        require(symbolTokenMap[_symbol] == address(0), "FACTROY:ERR00002");
        require(nameTokenMap[_name] == address(0), "FACTROY:ERR00003");
        FixedSupplyToken fixedSupplyToken = new FixedSupplyToken(_symbol, _name, _decimals, _total, msg.sender);
        address token = address(fixedSupplyToken);
        SwapTokenExchange exchange = new SwapTokenExchange(_recommendInc, AvalonFactory(address(this)), _avalonFee, _statistics, ITRC20(token), ITRC20(_usdtAddress), msg.sender);
        tokenExchangeMap[token] = address(exchange);
        exchangeTokenMap[address(exchange)] = token;
        symbolTokenMap[fixedSupplyToken.symbol()] = token;
        nameTokenMap[fixedSupplyToken.name()] = token;
        exchanges.push(address(exchange));
        tokens.push(address(token));
        _statistics.AddAuthAddress(address(exchange));
        emit NewExchange(token, address(exchange));
        return address(exchange);
    }

    function createExchangeByAddress(address payable tokenAddress, address settingAddress) public OwnerOnly returns (address payable){
        FixedSupplyToken fixedSupplyToken = FixedSupplyToken(tokenAddress);
        address token = address(fixedSupplyToken);
        SwapTokenExchange exchange = new SwapTokenExchange(_recommendInc, AvalonFactory(address(this)), _avalonFee, _statistics, ITRC20(token), ITRC20(_usdtAddress), settingAddress);
        tokenExchangeMap[token] = address(exchange);
        exchangeTokenMap[address(exchange)] = token;
        symbolTokenMap[fixedSupplyToken.symbol()] = token;
        nameTokenMap[fixedSupplyToken.name()] = token;
        exchanges.push(address(exchange));
        tokens.push(address(token));
        _statistics.AddAuthAddress(address(exchange));
        emit NewExchange(token, address(exchange));
        return address(exchange);
    }

    function getExchange(address token) external view returns (address){
        return tokenExchangeMap[token];
    }

    function getToken(address exchange) external view returns (address){
        return exchangeTokenMap[exchange];
    }

    function getTokenBySymbol(string calldata _symbol) external view returns (address){
        return symbolTokenMap[_symbol];
    }

    function getTokenByName(string calldata _name) external view returns (address){
        return nameTokenMap[_name];
    }

    function getTokens() public view returns (address [] memory _tokens){
        return tokens;
    }

    function getExchanges() public view returns (address []  memory _exchanges){
        return exchanges;
    }


    function getAvalonFee() external view returns (address){
        return address(_avalonFee);
    }

    function getStatistics() external view returns (address){
        return address(_statistics);
    }

    function getRecommend() external view returns (address){
        return address(_recommendInc);
    }

    function getUsdtAddress() external view returns (address){
        return address(_usdtAddress);
    }

}


//SourceUnit: AvalonFee.sol

pragma solidity ^0.5.8;

contract AvalonFee {

    address public _ava_fee_address;

    uint256 public exchangeFee = 30;
    uint256 public liquidityFee = 30;

    constructor(address _feeAddress) public {
        _ava_fee_address = _feeAddress;
    }

    function getExchangeFee() public view returns (uint256) {
        return exchangeFee;
    }

    function getLiquidityFee() public view returns (uint256) {
        return liquidityFee;
    }

    function feeAddress() public view returns (address){
        return _ava_fee_address;
    }


}


//SourceUnit: FixedSupplyToken.sol

/**
 *Submitted for verification at Etherscan.io on 2019-05-09
*/

pragma solidity ^0.5.8;

import "./SafeMath.sol";


interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// TRC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ITRC20, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;



    constructor(string memory _symbol,string memory _name,uint8 _decimals,uint256 _total,address _owner) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        owner = _owner;
        _totalSupply = _total * (10 ** uint(decimals));
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept TRX
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent TRC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyTRC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ITRC20(tokenAddress).transfer(owner, tokens);
    }
}


//SourceUnit: Recommend.sol

pragma solidity ^0.5.8;


interface RecommendInterface {
    function RecommendList( address _owner, uint256 depth ) external view returns (address[] memory list);
    function GetIntroducer( address _owner ) external view returns (address);
    function ShortCodeToAddress( bytes6 shortCode ) external view returns (address);
    function AddressToShortCode( address _addr ) external view returns (bytes6);
    function TeamMemberTotal( address _addr ) external view returns (uint256);
    function API_BindEx(address _owner, bytes6 _invShortCode, bytes6 shortCode) external;
}


contract Recommend is RecommendInterface {

    uint256 private _recommendDepthLimit = 15;
    mapping(address => address) _recommerMapping;
    mapping(address => mapping(uint256 => address[])) _recommerList;
    mapping(address => uint256) _recommerCountMapping;
    mapping(bytes6 => address) _shortCodeMapping;
    mapping(address => bytes6) _addressShotCodeMapping;


    event Bind_Event(address indexed _owner, address indexed _recommer, bytes6 indexed _shortCode);


    constructor(uint256 depth, address rAddress) public {
        _recommendDepthLimit = depth;
        address rootAddr = rAddress;
        bytes6 rootCode = 0x303030303030;
        internalBind(rootAddr, address(0xFF), rootCode);
    }


    // 首码
    function internalBind(address a, address r, bytes6 code) internal returns (bool) {
        _recommerMapping[a] = r;
        address parent = r;
        for (uint i = 0; i < _recommendDepthLimit; i++) {
            _recommerList[parent][i].push(a);
            _recommerCountMapping[parent] ++;
            parent = _recommerMapping[parent];
            if (parent == address(0x0)) {
                break;
            }
        }
        _shortCodeMapping[code] = a;
        _addressShotCodeMapping[a] = code;
        emit Bind_Event(a, r, code);

        return true;
    }

    function GetDepth() external view returns (uint256 depth) {
        return _recommendDepthLimit;
    }


    function GetIntroducer(address _owner) external view returns (address) {
        return _recommerMapping[_owner];
    }

    function RecommendList(address _owner, uint256 depth) external view returns (address[] memory list) {
        return _recommerList[_owner][depth];
    }

    function ShortCodeToAddress(bytes6 shortCode) external view returns (address) {
        return _shortCodeMapping[shortCode];
    }

    function AddressToShortCode(address _addr) external view returns (bytes6) {
        return _addressShotCodeMapping[_addr];
    }

    function TeamMemberTotal(address _addr) external view returns (uint256) {
        return _recommerCountMapping[_addr];
    }

    function API_BindEx(address _owner, bytes6 _invShortCode, bytes6 shortCode) external {
        require(_shortCodeMapping[shortCode] == address(0x0), "RECOMMEND:ERR00001");
        require(_addressShotCodeMapping[_owner] == bytes6(0x0), "RECOMMEND:ERR00002");

        address _recommer = _shortCodeMapping[_invShortCode];
        require(_recommer != address(0x0), "RECOMMEND:ERR00003");
        require(_recommer != _owner, "RECOMMEND:ERR00004");
        require(_recommerMapping[_owner] == address(0x0), "RECOMMEND:ERR00005");
        require(_recommerMapping[_recommer] != address(0x0), "RECOMMEND:ERR00006");


        _shortCodeMapping[shortCode] = _owner;
        _addressShotCodeMapping[_owner] = shortCode;

        uint256 ssize;
        address safeAddr = _owner;
        assembly {
            ssize := extcodesize(safeAddr)
        }
        require(ssize == 0, "RECOMMEND:ERR00007");
        _recommerMapping[_owner] = _recommer;
        address parent = _recommer;
        for (uint i = 0; i < _recommendDepthLimit; i++) {
            _recommerList[parent][i].push(_owner);
            _recommerCountMapping[parent] ++;
            parent = _recommerMapping[parent];
            if (parent == address(0x0)) {
                break;
            }
        }
        emit Bind_Event(_owner, _recommer, shortCode);
    }
}

//SourceUnit: ReentrancyGuard.sol

pragma solidity ^0.5.8;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
        _;
        // By storing the original value once again, a refund is triggered (see
        _notEntered = true;
    }
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.8;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath#mul: OVERFLOW");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath#sub: UNDERFLOW");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath#add: OVERFLOW");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
        return a % b;
    }


    function chinaTime(uint256 a) internal pure returns (uint256){
        uint256 b = mod(a,1 days);
        uint256 c = sub(mul(div(a, 1 days), 1 days), 8 hours);
        
        if (b >= 16 hours) {
            return add(c , 1 days);
        } else {
            return c;
        }
    }

}

//SourceUnit: SwapStatistics.sol

pragma solidity ^0.5.8;

import "./SafeMath.sol";
import "./ABDKMathQuad.sol";

contract InternalModule {


    mapping(address => bool) _authAddress;

    address public _contractOwner;

    address public _managerAddress;

    constructor() public {
        _contractOwner = msg.sender;
        _managerAddress = msg.sender;
    }

    modifier OwnerOnly() {
        require(_contractOwner == msg.sender);
        _;
    }

    modifier ManagerOnly() {
        require(msg.sender == _managerAddress);
        _;
    }


    modifier APIMethod() {
        bool exist = _authAddress[msg.sender];
        require(exist);
        _;
    }

    function SetRoundManager(address rmaddr) external OwnerOnly {
        _managerAddress = rmaddr;
    }

    function SetOwnerManager(address omaddr) external OwnerOnly {
        _contractOwner = omaddr;
    }

    function AddAuthAddress(address _addr) external ManagerOnly {
        _authAddress[_addr] = true;
    }

    function DelAuthAddress(address _addr) external ManagerOnly {
        _authAddress[_addr] = false;
    }


}


contract SwapStatistics is InternalModule {

    using SafeMath for uint256;

    struct KLine {
        uint256 startTime;
        uint256 endTime;
        uint256 openAAmount;
        uint256 openBAmount;
        uint256 closeAAmount;
        uint256 closeBAmount;
    }

    mapping(address => KLine []) tokenKline;


    function API_addKline(address tokenAddress, uint256 tokenAAmount, uint256 tokenBAmount) APIMethod public {
        uint256 openTime = uint256(block.timestamp).chinaTime();
        KLine [] storage kline = tokenKline[tokenAddress];
        if (kline.length == 0) {
            //没有交易
            kline.push(KLine(openTime, block.timestamp, tokenAAmount, tokenBAmount, tokenAAmount, tokenBAmount));
        } else {
            KLine storage k = kline[kline.length - 1];
            if (k.startTime == openTime) {
                k.endTime = block.timestamp;
                k.closeAAmount = tokenAAmount;
                k.closeBAmount = tokenBAmount;
            } else {
                kline.push(KLine(openTime, block.timestamp, k.closeAAmount, k.closeBAmount, tokenAAmount, tokenBAmount));
            }
        }
    }

    function API_getThatDayKline(address tokenAddress) public view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 openAAmount,
        uint256 openBAmount,
        uint256 closeAAmount,
        uint256 closeBAmount,
        uint256 state
    ){
        uint256 openTime = block.timestamp.chinaTime();
        KLine [] storage kline = tokenKline[tokenAddress];
        if (kline.length == 0) {
            return (0, 0, 0, 0, 0, 0, 0);
        } else {
            KLine memory k = kline[kline.length - 1];
            if (k.startTime == openTime) {
                return (k.startTime, k.endTime, k.openAAmount, k.openBAmount, k.closeAAmount, k.closeBAmount, 1);
            } else {
                return (openTime, openTime, k.closeAAmount, k.closeBAmount, k.closeAAmount, k.closeBAmount, 2);
            }
        }
    }


    function API_getKline(address tokenAddress, uint256 offset, uint256 size) public view returns (
        uint256 len,
        uint256 time,
        uint256 totalCount,
        uint256 [] memory startTime,
        uint256 [] memory endTime,
        uint256 [] memory openAAmount,
        uint256 [] memory openBAmount,
        uint256 [] memory closeAAmount,
        uint256 [] memory closeBAmount
    ){
        require(offset >= 0);
        require(size > 0);

        KLine [] storage kline = tokenKline[tokenAddress];

        uint256 lrSize = kline.length;
        if (size > lrSize) {
            size = lrSize;
        }

        {
            len = 0;
            startTime = new uint256[](size);
            endTime = new uint256[](size);
            openAAmount = new uint256[](size);
            openBAmount = new uint256[](size);
            closeAAmount = new uint256[](size);
            closeBAmount = new uint256[](size);
        }

        if (lrSize == 0 || offset > (lrSize - 1)) {
            return (len, block.timestamp, lrSize, startTime, endTime, openAAmount, openBAmount, closeAAmount, closeBAmount);
        }

        uint256 i = lrSize - 1 - offset;
        uint256 iMax = 0;
        if (offset <= (lrSize - size)) {
            iMax = lrSize - size - offset;
        }

        while (i >= 0 && i >= iMax) {
            KLine memory kk = kline[i];
            startTime[len] = kk.startTime;
            endTime[len] = kk.endTime;
            openAAmount[len] = kk.openAAmount;
            openBAmount[len] = kk.openBAmount;
            closeAAmount[len] = kk.closeAAmount;
            closeBAmount[len] = kk.closeBAmount;
            len = len + 1;
            if (i == 0) {
                break;
            }
            i--;
        }
        return (len, block.timestamp, lrSize, startTime, endTime, openAAmount, openBAmount, closeAAmount, closeBAmount);
    }

}


//SourceUnit: SwapTokenExchange.sol

pragma solidity ^0.5.8;

import "./Recommend.sol";
import "./ReentrancyGuard.sol";
import "./AvalonFactory.sol";
import "./FixedSupplyToken.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./AvalonFee.sol";
import "./SwapStatistics.sol";
import "./ABDKMathQuad.sol";


contract SwapTokenExchangeInterface {


    event TokenPurchaseBuy(address indexed buyer, uint256 indexed tokenb_sold, uint256 indexed tokena_bought);
    event TokenPurchaseSell(address indexed buyer, uint256 indexed tokenb_sold, uint256 indexed tokena_bought);
    event TokenConvertPurchase(address indexed buyer, uint256 indexed tokenb_sold, uint256 indexed tokena_bought);
    event TokenConvertPurchaseIncomeEvent(address indexed buyer, address indexed projectAddress, uint256 indexed income);
    event AddLiquidity(address indexed provider, uint256 indexed tokena_amount, uint256 indexed tokenb_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed tokena_sold, uint256 indexed tokenb_amount);
    event Snapshot(address indexed operator, uint256 indexed tokena_balance, uint256 indexed tokenb_balance);
    event InvitationRewardEvent(address indexed form, address indexed to, uint256 indexed amount);
    event AddLiquidityReleaseRepoPoolAmountEvent(address indexed sender, uint256 indexed amount);
    event ProjectPartyRepurchaseEvent(uint256 indexed repurchaseAmount, uint256 indexed destroyAmount);
    event TokenSellFeeEvent(address indexed form, uint256 indexed fee);
    event TokenBuyFeeEvent(address indexed form, uint256 indexed fee);
    event TokenConvertPurchaseIncomeFeeEvent(address indexed form, uint256 indexed fee);
    event AddLiquidityFeeEvent(address indexed form, uint256 indexed fee);
    event ReceiveLiquidityRewardEvent(address indexed form, uint256 indexed amount);
    event ReceiveTeamRewardEvent(address indexed teamAddress, uint256 indexed amount);


    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256);

    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256);

    function getTokenAToTokenBInputPrice(uint256 _tokenAAmount) public view returns (uint256);

    function getTokenAToTokenBOutputPrice(uint256 _tokenBAmount) public view returns (uint256);

    function getTokenBToTokenAInputPrice(uint256 _tokenBAmount) public view returns (uint256);

    function getTokenBToTokenAOutputPrice(uint256 _tokenAAmount) public view returns (uint256);

    function tokenAToTokenBSwapInput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public returns (uint256);

    function tokenAToTokenBSwapOutput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline) public returns (uint256);

    function tokenBToTokenASwapInput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline) public returns (uint256);

    function tokenBToTokenASwapOutput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public returns (uint256);


    function addLiquidity(uint256 min_liquidity, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public returns (uint256);

    function firstAddLiquidity(
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _upDown,
        uint256 [] memory rewardParam,
        uint256 [] memory _teamParam,
        address _teamRewardAddress,
        uint256 [] memory _LiquidityReleaseParam,
        address _LiquidityReleaseIncomeAddress) public returns (uint256);

    function getUserLiquidityRecord(uint256 offset, uint256 size, address owner) public view returns (
        uint256 len,
        uint256 [] memory idx,
        uint256 [] memory tokenAAmount,
        uint256 [] memory tokenBAmount,
        uint256 [] memory liquidityMinted,
        uint256 [] memory createTime,
        uint256 [] memory awardAmount,
        bool [] memory over
    );

    function removeLiquidity(uint256 idx, uint256 tokenAMinAmount, uint256 tokenBMinAmount, uint256 deadline) public returns (uint256, uint256);

    function projectPartyRepurchaseState() public view returns (bool _state, uint256 _repurchaseAmount, uint256 _destroyAmount);

    function getExchangeStopState() public view returns (bool _state, bool _limit, uint256 _tokenAMax, uint256 _tokenBMax);

    function getExchangeDownStopState() public view returns (bool _state, bool _limit, uint256 _tokenAMax, uint256 _tokenBMax);
}


contract SwapTeamManager {

    using SafeMath for uint256;

    uint256 internal teamStartTime;
    uint256 internal teamEndTime;
    uint256 internal teamLaseTime;
    uint256 internal teamRewardAmount;
    uint256 internal teamRewardTotalAmount;
    address internal teamRewardAddress;
    uint256 internal teamCycle;
    uint256 internal teamEachAmount;

    function API_UpdateTeamRewardSetting(
        uint256 _teamRewardAmount,
        uint256 _teamStartTime,
        uint256 _teamEndTime,
        uint256 _teamCycle,
        address _teamRewardAddress
    ) internal returns (bool){
        if (teamRewardTotalAmount == 0 &&
        _teamRewardAmount > 0 &&
        _teamRewardAddress != address(0) &&
        _teamCycle > 0 && _teamEndTime > _teamStartTime
        ) {
            teamStartTime = _teamStartTime;
            teamEndTime = _teamEndTime;
            teamLaseTime = _teamStartTime;
            teamRewardAmount = _teamRewardAmount;
            teamRewardTotalAmount = _teamRewardAmount;
            teamRewardAddress = _teamRewardAddress;
            teamCycle = _teamCycle;
            teamEachAmount = _teamRewardAmount.div((_teamEndTime.sub(_teamStartTime)).div(_teamCycle));
            require(teamEachAmount > 0, "MANAGER:ERR00003");
            return true;
        } else {
            return false;
        }
    }

    function API_GetTeamRewardSetting() public view returns (
        uint256 _teamRewardTotalAmount,
        uint256 _teamStartTime,
        uint256 _teamEndTime,
        uint256 _teamLaseTime,
        uint256 _teamRewardAmount,
        uint256 _teamEachAmount,
        address _teamRewardAddress,
        uint256 _teamCycle) {
        _teamStartTime = teamStartTime;
        _teamEndTime = teamEndTime;
        _teamLaseTime = teamLaseTime;
        _teamRewardAmount = teamRewardAmount;
        _teamRewardAddress = teamRewardAddress;
        _teamRewardTotalAmount = teamRewardTotalAmount;
        _teamCycle = teamCycle;
        _teamEachAmount = teamEachAmount;
    }

    function API_WithDrawTeamRewardAmount() public view returns (address _withdrawAddress, uint256 _amount, uint256 _time){
        if (teamRewardAmount == 0) {
            return (teamRewardAddress, 0, 0);
        }
        uint256 time = block.timestamp;
        uint256 releaseAmount = block.timestamp.sub(teamStartTime).div(teamCycle).mul(teamEachAmount);
        if (releaseAmount >= teamRewardTotalAmount) {
            releaseAmount = teamRewardTotalAmount;
        }
        uint256 releaseTotal = teamRewardTotalAmount.sub(teamRewardAmount);
        uint256 _val = releaseAmount.sub(releaseTotal);
        return (teamRewardAddress, _val, time);
    }

    function API_WithDrawTeamReward() internal returns (address _withdrawAddress, uint256 _amount){
        (address withdrawAddress, uint256 amount,uint256 _time) = API_WithDrawTeamRewardAmount();
        require(amount > 0, "MANAGER:ERR00004");
        teamRewardAmount = teamRewardAmount.sub(amount);
        teamLaseTime = _time;
        require(teamRewardAmount >= 0, "MANAGER:ERR00005");
        return (withdrawAddress, amount);
    }

}


contract SwapUpDownManager {

    using SafeMath for uint256;


    uint256 internal oldUpDown;
    uint256 internal upDown;
    uint256 internal upDownStartTime;
    uint256 internal upDownSettingCount = 3;

    function API_getUpDown() public view returns (uint256 _upDown, uint256 _upDownStartTime, uint256 _upDownSettingCount, uint256 currentUpDown) {
        return (upDown, upDownStartTime, upDownSettingCount, API_GetCurrentUpDown());
    }

    function API_GetCurrentUpDown() public view returns (uint256){
        if (block.timestamp >= upDownStartTime) {
            return upDown;
        } else {
            return oldUpDown;
        }
    }

}


contract SwapLiquidityReleaseManager {

    using SafeMath for uint256;
    uint256 internal LiquidityReleaseTotalAmount;
    uint256 internal LiquidityReleaseRemainderAmount;
    uint256 internal LiquidityReleaseThatDayAmount;
    uint256 internal LiquidityReleaseSingleUserAmount;

    uint256 internal LiquidityReleaseInvProp;
    uint256 internal LiquidityReleaseIncomeProp;
    address internal LiquidityReleaseIncomeAddress;
    uint256 internal LiquidityReleaseIncomeAmount;
    uint256 internal LiquidityReleaseBuyAmount;


    uint256 internal LiquidityReleaseRepurchaseCycle;
    uint256 internal LiquidityReleaseRepurchaseLastTime;
    uint256 internal LiquidityReleaseRepurchaseProp;
    uint256 internal LiquidityReleaseRepoPool;
    uint256 internal LiquidityReleasePartyRepurchaseAmount;
    uint256 internal LiquidityReleasePartyRepurchaseDestroyAmount;
    uint256 internal LiquidityReleasePartyRepurchaseLastDestroyAmount;
    uint256 internal LiquidityReleasePartyLastRepurchaseAmount;
    uint256 internal LiquidityReleasePartyLastRepurchaseTime;


    mapping(address => mapping(uint256 => uint256)) internal liquidityReleaseSingleUserAmountRecord;
    mapping(uint256 => uint256) internal liquidityReleaseThatDayAmountRecord;


    function API_AddLiquidityReleaseSingleUserAmountRecord(bool introducerBind, uint256 feeProp, address userAddress, uint256 tokenAAmount, uint256 tokenBAmount) internal returns (
        uint256 incomeAmount,
        uint256 invAmount,
        uint256 feeAmount
    ){
        uint256 time = uint256(block.timestamp).chinaTime();
        liquidityReleaseThatDayAmountRecord[time] = liquidityReleaseThatDayAmountRecord[time].add(tokenAAmount);
        liquidityReleaseSingleUserAmountRecord[userAddress][time] = liquidityReleaseSingleUserAmountRecord[userAddress][time].add(tokenAAmount);
        LiquidityReleaseRemainderAmount = LiquidityReleaseRemainderAmount.sub(tokenAAmount);
        LiquidityReleaseBuyAmount = LiquidityReleaseBuyAmount.add(tokenBAmount);

        uint256 fee = tokenBAmount.mul(feeProp).div(uint256(10000));
        uint256 inv = uint256(0);
        uint256 remainder = tokenBAmount.sub(fee);
        if (introducerBind) {
            inv = remainder.mul(LiquidityReleaseInvProp).div(uint256(10000));
            remainder = remainder.sub(inv);
        }

        uint256 income = remainder.mul(LiquidityReleaseIncomeProp).div(uint256(10000));
        LiquidityReleaseIncomeAmount = LiquidityReleaseIncomeAmount.add(income);
        LiquidityReleaseRepoPool = LiquidityReleaseRepoPool.add(remainder.sub(income));
        return (income, inv, fee);
    }

    function API_AddLiquidityLiquidityReleaseRepoPool(uint256 token) internal {
        LiquidityReleaseRepoPool = LiquidityReleaseRepoPool.add(token);
    }


    function API_UpdateLiquidityReleaseSetting(
        uint256 _LiquidityReleaseTotalAmount,
        uint256 _LiquidityReleaseThatDayAmount,
        uint256 _LiquidityReleaseSingleUserAmount,
        uint256 _LiquidityReleaseRepurchaseCycle,
        uint256 _LiquidityReleaseRepurchaseProp,
        uint256 _LiquidityReleaseIncomeProp,
        uint256 _LiquidityReleaseInvProp,
        address _LiquidityReleaseIncomeAddress
    ) internal returns (bool){
        if (LiquidityReleaseTotalAmount == 0
        && _LiquidityReleaseTotalAmount > 0
        && _LiquidityReleaseThatDayAmount > 0
        && _LiquidityReleaseSingleUserAmount > 0
        && _LiquidityReleaseRepurchaseCycle >= 1
        && _LiquidityReleaseRepurchaseProp > 0 && _LiquidityReleaseRepurchaseProp <= 10000
        && _LiquidityReleaseIncomeProp >= 0 && _LiquidityReleaseIncomeProp <= 10000
        && _LiquidityReleaseInvProp >= 0 && _LiquidityReleaseInvProp <= 2000
            && _LiquidityReleaseIncomeAddress != address(0)
        ) {
            LiquidityReleaseTotalAmount = _LiquidityReleaseTotalAmount;
            LiquidityReleaseRemainderAmount = _LiquidityReleaseTotalAmount;
            LiquidityReleaseThatDayAmount = _LiquidityReleaseThatDayAmount;
            LiquidityReleaseSingleUserAmount = _LiquidityReleaseSingleUserAmount;
            LiquidityReleaseRepurchaseCycle = _LiquidityReleaseRepurchaseCycle;
            LiquidityReleaseRepurchaseLastTime = uint256(block.timestamp).chinaTime().add(uint256(18 hours));
            LiquidityReleaseRepurchaseProp = _LiquidityReleaseRepurchaseProp;
            LiquidityReleaseIncomeProp = _LiquidityReleaseIncomeProp;
            LiquidityReleaseInvProp = _LiquidityReleaseInvProp;
            LiquidityReleaseIncomeAddress = _LiquidityReleaseIncomeAddress;
            return true;
        } else {
            return false;
        }
    }


    function API_GetLiquidityReleaseAmountUsed(address userAddress) public view returns (uint256, uint256, uint256){
        if (LiquidityReleaseRemainderAmount == 0) {
            return (0, 0, 0);
        } else {
            uint256 maxLReleaseAmount = LiquidityReleaseRemainderAmount;
            uint256 time = uint256(block.timestamp).chinaTime();
            uint256 userAmount = LiquidityReleaseSingleUserAmount.sub(liquidityReleaseSingleUserAmountRecord[userAddress][time]);
            uint256 thatDayAmount = LiquidityReleaseThatDayAmount.sub(liquidityReleaseThatDayAmountRecord[time]);
            return (maxLReleaseAmount, userAmount, thatDayAmount);
        }
    }


    function API_GetLiquidityReleaseSingleUserThatDayMaxAmount(address userAddress) public view returns (uint256){
        if (LiquidityReleaseRemainderAmount == 0) {
            return 0;
        } else {
            uint256 maxLReleaseAmount = LiquidityReleaseRemainderAmount;
            uint256 time = uint256(block.timestamp).chinaTime();
            uint256 userAmount = LiquidityReleaseSingleUserAmount.sub(liquidityReleaseSingleUserAmountRecord[userAddress][time]);
            uint256 thatDayAmount = LiquidityReleaseThatDayAmount.sub(liquidityReleaseThatDayAmountRecord[time]);

            uint256 min = maxLReleaseAmount;
            if (userAmount < min) {
                min = userAmount;
            }
            if (thatDayAmount < min) {
                min = thatDayAmount;
            }
            return min;
        }
    }


    function API_GetLiquidityReleaseConvertSetting() public view returns (
        uint256 _LiquidityReleaseTotalAmount,
        uint256 _LiquidityReleaseRemainderAmount,
        uint256 _LiquidityReleaseThatDayAmount,
        uint256 _LiquidityReleaseSingleUserAmount,
        uint256 _LiquidityReleasePartyRepurchaseLastDestroyAmount,
        uint256 _LiquidityReleasePartyLastRepurchaseAmount,
        uint256 _LiquidityReleasePartyLastRepurchaseTime

    ){
        return (
        LiquidityReleaseTotalAmount,
        LiquidityReleaseRemainderAmount,
        LiquidityReleaseThatDayAmount,
        LiquidityReleaseSingleUserAmount,
        LiquidityReleasePartyRepurchaseLastDestroyAmount,
        LiquidityReleasePartyLastRepurchaseAmount,
        LiquidityReleasePartyLastRepurchaseTime
        );
    }


    function API_GetLiquidityReleaseRepurchaseSetting() public view returns (
        uint256 _LiquidityReleaseRepurchaseCycle,
        uint256 _LiquidityReleaseRepurchaseLastTime,
        uint256 _LiquidityReleaseRepurchaseProp,
        uint256 _LiquidityReleaseIncomeProp,
        address _LiquidityReleaseIncomeAddress,
        uint256 _LiquidityReleaseIncomeAmount,
        uint256 _LiquidityReleaseBuyAmount,
        uint256 _LiquidityReleaseRepoPool,
        uint256 _LiquidityReleasePartyRepurchaseAmount,
        uint256 _LiquidityReleasePartyRepurchaseDestroyAmount,
        uint256 _LiquidityReleaseInvProp
    ){
        return (
        LiquidityReleaseRepurchaseCycle,
        LiquidityReleaseRepurchaseLastTime,
        LiquidityReleaseRepurchaseProp,
        LiquidityReleaseIncomeProp,
        LiquidityReleaseIncomeAddress,
        LiquidityReleaseIncomeAmount,
        LiquidityReleaseBuyAmount,
        LiquidityReleaseRepoPool,
        LiquidityReleasePartyRepurchaseAmount,
        LiquidityReleasePartyRepurchaseDestroyAmount,
        LiquidityReleaseInvProp
        );
    }


}


contract SwapLiquidityManager {
    using SafeMath for uint256;

    uint256 internal _LiquidityRewardAmount;
    uint256 internal _LiquidityRewardTotalAmount;
    uint256 internal _LiquidityRewardCycle;
    uint256 internal _LiquidityRewardProp;
    uint256 internal _LiquidityInviteRewardMode;
    uint256 internal _LiquidityInviteRewardProp;
    uint256 internal _LiquidityInviteLevel2RewardProp;

    function API_UpdateLiquidityRewardSetting(
        uint256 _rewardAmount,
        uint256 _rewardCycle,
        uint256 _rewardProp,
        uint256 _inviteRewardProp,
        uint256 _level2RewardProp,
        uint256 _rewardMode
    ) internal returns (bool){
        if (_LiquidityRewardTotalAmount == 0 && _LiquidityRewardAmount == 0
        && _rewardAmount > 0 && _rewardCycle > 0 && (_rewardProp > 0)
        && (_rewardMode == 1)
        && (_inviteRewardProp >= 0)
            && (_level2RewardProp >= 0)
        ) {
            _LiquidityInviteRewardMode = _rewardMode;
            _LiquidityRewardCycle = _rewardCycle;
            _LiquidityRewardAmount = _rewardAmount;
            _LiquidityRewardTotalAmount = _rewardAmount;
            _LiquidityRewardProp = _rewardProp;
            _LiquidityInviteRewardProp = _inviteRewardProp;
            _LiquidityInviteLevel2RewardProp = _level2RewardProp;
            return true;
        } else {
            return false;
        }
    }

    function API_SendLiquidityRewardAmount(uint256 _sendAmount) internal returns (uint256 sendAmount) {
        if (_LiquidityRewardAmount >= _sendAmount) {
            sendAmount = _sendAmount;
        } else {
            sendAmount = _LiquidityRewardAmount;
        }
        _LiquidityRewardAmount = _LiquidityRewardAmount.sub(sendAmount);
    }

    function API_GetLiquidityRewardSetting() public view returns (
        uint256 _rewardAmount,
        uint256 _rewardCycle,
        uint256 _rewardProp,
        uint256 _inviteRewardProp,
        uint256 _level2RewardProp,
        uint256 _rewardMode,
        uint256 _rewardTotalAmount) {
        return (_LiquidityRewardAmount, _LiquidityRewardCycle, _LiquidityRewardProp, _LiquidityInviteRewardProp, _LiquidityInviteLevel2RewardProp, _LiquidityInviteRewardMode, _LiquidityRewardTotalAmount);
    }


}


contract SwapTokenExchange is SwapTokenExchangeInterface, ReentrancyGuard, SwapUpDownManager, SwapLiquidityReleaseManager, SwapLiquidityManager, SwapTeamManager {


    struct LiquidityRecord {
        uint256 idx;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
        uint256 liquidityMinted;
        uint256 createTime;
        uint256 awardAmount;
        bool over;
    }

    RecommendInterface recommendInterface;
    AvalonFactory avalonFactory;
    AvalonFee avalonFee;
    ITRC20 tokenA;
    ITRC20 tokenB;
    SwapStatistics swapStatistics;
    using TransferHelper for address;
    using SafeMath for uint;

    bool public firstLiquiditySetting = false;
    address public _settingAddress;

    uint256 public _token_a_balance = 0;
    uint256 public _token_b_balance = 0;

    uint256 public _LiquidityTotalSupply;
    mapping(address => LiquidityRecord[]) userLiquidityRecord;

    string public name;
    string public symbol;




    constructor(
        RecommendInterface _recommendInterface,
        AvalonFactory _avalonFactory,
        AvalonFee _avalonFee,
        SwapStatistics _swapStatistics,
        ITRC20 _tokenA,
        ITRC20 _tokenB,
        address sAddress
    ) public {
        recommendInterface = _recommendInterface;
        avalonFactory = _avalonFactory;
        avalonFee = _avalonFee;
        tokenA = _tokenA;
        tokenB = _tokenB;
        swapStatistics = _swapStatistics;
        name = "AVA SWAP V1";
        symbol = "AVA-SWAP-V1";
        _settingAddress = sAddress;
    }

    function() external payable {
        revert();
    }


    modifier isBindCode() {
        require(recommendInterface.GetIntroducer(msg.sender) != address(0), "EXCHANGE:ERR00002");
        _;
    }

    // 校验是否是管理
    modifier checkManagerOnly() {
        require(msg.sender == _settingAddress, "MANAGER:ERR00001");
        _;
    }




    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "EXCHANGE:ERRTX003");
        uint256 numerator = input_amount.mul(output_reserve);
        uint256 denominator = input_reserve.add(input_amount);
        return numerator.div(denominator);
    }

    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
        require(input_reserve > 0 && output_reserve > 0, "EXCHANGE:ERRTX003");
        uint256 numerator = input_reserve.mul(output_amount);
        uint256 denominator = (output_reserve.sub(output_amount));
        return (numerator.div(denominator)).add(1);
    }


    function getTokenAToTokenBInputPrice(uint256 _tokenAAmount) public view returns (uint256) {
        require(_tokenAAmount > 0, "EXCHANGE:ERRTX003");
        return getInputPrice(_tokenAAmount, _token_a_balance, _token_b_balance);
    }


    function getTokenAToTokenBOutputPrice(uint256 _tokenBAmount) public view returns (uint256) {
        require(_tokenBAmount > 0, "EXCHANGE:ERRTX003");
        return getOutputPrice(_tokenBAmount, _token_a_balance, _token_b_balance);
    }

    function getTokenBToTokenAInputPrice(uint256 _tokenBAmount) public view returns (uint256) {
        require(_tokenBAmount > 0, "EXCHANGE:ERRTX003");
        return getInputPrice(_tokenBAmount, _token_b_balance, _token_a_balance);
    }


    function getTokenBToTokenAOutputPrice(uint256 _tokenAAmount) public view returns (uint256) {
        require(_tokenAAmount > 0, "EXCHANGE:ERRTX003");
        return getOutputPrice(_tokenAAmount, _token_b_balance, _token_a_balance);
    }


    function tokenAToTokenBSwapInput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public nonReentrant isBindCode returns (uint256)  {
        (bool _state, bool _limit, uint256 _tokenAMax,) = getExchangeDownStopState();
        require(_state == false, "EXCHANGE:ERR00001");
        return tokenAToTokenBInput(_tokenAAmount, _tokenBAmount, deadline, msg.sender, msg.sender, _limit, _tokenAMax);
    }


    function tokenAToTokenBSwapOutput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline) public nonReentrant isBindCode returns (uint256) {
        (bool _state, bool _limit, ,uint256 _tokenBMax) = getExchangeDownStopState();
        require(_state == false, "EXCHANGE:ERR00001");
        return tokenAToTokenBOutput(_tokenBAmount, _tokenAAmount, deadline, msg.sender, msg.sender, _limit, _tokenBMax);
    }

    function tokenBToTokenASwapInput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline) public nonReentrant isBindCode returns (uint256) {
        (bool _state, bool _limit,, uint256 _tokenBMax) = getExchangeStopState();
        if (_state) {
            return convertTokenBToTokenASwapInPut(_tokenBAmount, _tokenAAmount, deadline, msg.sender);
        } else {
            return tokenBToTokenAInput(_tokenBAmount, _tokenAAmount, deadline, msg.sender, msg.sender, _limit, _tokenBMax);
        }
    }


    function tokenBToTokenASwapOutput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public nonReentrant isBindCode returns (uint256) {
        (bool _state, bool _limit, uint256 _tokenAMax,) = getExchangeStopState();
        if (_state) {
            return convertTokenBToTokenASwapOutPut(_tokenAAmount, _tokenBAmount, deadline, msg.sender);
        } else {
            return tokenBToTokenAOutput(_tokenAAmount, _tokenBAmount, deadline, msg.sender, msg.sender, _limit, _tokenAMax);
        }
    }


    function tokenAToTokenBInput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline, address buyer, address recipient, bool limit, uint256 _tokenAMax) private returns (uint256) {
        require(deadline >= block.timestamp && _tokenAAmount > 0 && _tokenBAmount > 0, "EXCHANGE:ERRTX004");

        // 有跌停限制
        if (limit) {
            require(_tokenAAmount <= _tokenAMax, "EXCHANGE:ERRTX007");
        }

        uint256 tokens_bought = getInputPrice(_tokenAAmount, _token_a_balance, _token_b_balance);
        require(tokens_bought >= _tokenBAmount, "EXCHANGE:ERRTX005");


        uint256 buyAmount = tokens_bought;
        uint256 feeAmount = tokens_bought.mul(avalonFee.getExchangeFee()).div(10000);
        if (feeAmount > 0 && feeAmount < tokens_bought) {
            buyAmount = tokens_bought.sub(feeAmount);
            require(address(tokenB).safeTransfer(avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX002");
            emit TokenSellFeeEvent(buyer, feeAmount);
        }

        require(address(tokenA).safeTransferFrom(buyer, address(this), _tokenAAmount), "EXCHANGE:ERRTX001");
        require(address(tokenB).safeTransfer(address(recipient), buyAmount), "EXCHANGE:ERRTX002");

        _token_a_balance = _token_a_balance.add(_tokenAAmount);
        _token_b_balance = _token_b_balance.sub(tokens_bought);
        swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
        emit TokenPurchaseSell(buyer, _tokenAAmount, buyAmount);
        emit Snapshot(buyer, _token_a_balance, _token_b_balance);

        projectPartyRepurchaseInner();
        return tokens_bought;
    }


    function tokenAToTokenBOutput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline, address buyer, address recipient, bool limit, uint256 _tokenBMax) private returns (uint256) {
        require(deadline >= block.timestamp && _tokenBAmount > 0 && _tokenAAmount > 0, "EXCHANGE:ERRTX004");

        // 有跌停限制
        if (limit) {
            require(_tokenBAmount <= _tokenBMax, "EXCHANGE:ERRTX007");
        }

        uint256 tokenA_sold = getOutputPrice(_tokenBAmount, _token_a_balance, _token_b_balance);
        require(_tokenAAmount >= tokenA_sold, "EXCHANGE:ERRTX005");

        uint256 feeAmount = _tokenBAmount.mul(avalonFee.getExchangeFee()).div(10000);
        uint256 buyAmount = _tokenBAmount;
        if (feeAmount > 0 && feeAmount < _tokenBAmount) {
            buyAmount = _tokenBAmount.sub(feeAmount);
            require(address(tokenB).safeTransfer(avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX002");
            emit TokenSellFeeEvent(buyer, feeAmount);
        }

        require(address(tokenA).safeTransferFrom(buyer, address(this), tokenA_sold), "EXCHANGE:ERRTX001");
        require(address(tokenB).safeTransfer(recipient, buyAmount), "EXCHANGE:ERRTX002");
        // 扣除手续费
        _token_a_balance = _token_a_balance.add(tokenA_sold);
        _token_b_balance = _token_b_balance.sub(_tokenBAmount);
        swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
        emit TokenPurchaseSell(buyer, tokenA_sold, buyAmount);
        emit Snapshot(buyer, _token_a_balance, _token_b_balance);
        projectPartyRepurchaseInner();
        return tokenA_sold;
    }


    function tokenBToTokenAInput(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline, address buyer, address recipient, bool limit, uint256 _tokenBMax) private returns (uint256) {
        require(deadline >= block.timestamp && _tokenBAmount > 0 && _tokenAAmount > 0, "EXCHANGE:ERRTX004");
        uint256 feeAmount = _tokenBAmount.mul(avalonFee.getExchangeFee()).div(10000);
        uint256 exchangeAmount = _tokenBAmount;
        if (feeAmount > 0 && feeAmount < _tokenBAmount) {
            exchangeAmount = _tokenBAmount.sub(feeAmount);
            require(address(tokenB).safeTransferFrom(buyer, avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX001");
            emit TokenBuyFeeEvent(buyer, feeAmount);
        }

        //涨停限制
        if (limit) {
            require(exchangeAmount <= _tokenBMax, "EXCHANGE:ERRTX007");
        }

        uint256 wei_bought = getInputPrice(exchangeAmount, _token_b_balance, _token_a_balance);
        require(wei_bought >= _tokenAAmount, "EXCHANGE:ERRTX005");

        require(address(tokenB).safeTransferFrom(buyer, address(this), exchangeAmount), "EXCHANGE:ERRTX001");
        require(address(tokenA).safeTransfer(recipient, wei_bought), "EXCHANGE:ERRTX002");


        _token_b_balance = _token_b_balance.add(exchangeAmount);
        _token_a_balance = _token_a_balance.sub(wei_bought);
        swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
        emit TokenPurchaseBuy(buyer, wei_bought, _tokenBAmount);
        emit Snapshot(buyer, _token_a_balance, _token_b_balance);

        projectPartyRepurchaseInner();
        return wei_bought;
    }


    function tokenBToTokenAOutput(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline, address buyer, address recipient, bool _limit, uint256 _tokenAMax) private returns (uint256) {
        require(deadline >= block.timestamp && _tokenAAmount > 0, "EXCHANGE:ERRTX004");
        if (_limit) {
            require(_tokenAAmount <= _tokenAMax, "EXCHANGE:ERRTX007");
        }
        uint256 tokens_sold = getOutputPrice(_tokenAAmount, _token_b_balance, _token_a_balance);


        uint256 feeAmount = tokens_sold.mul(avalonFee.getExchangeFee()).div(10000);
        uint256 exchangeAmount = tokens_sold;
        if (feeAmount > 0 && feeAmount < tokens_sold) {
            exchangeAmount = tokens_sold.add(feeAmount);
            require(address(tokenB).safeTransferFrom(buyer, avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX001");
            emit TokenBuyFeeEvent(buyer, feeAmount);
        }
        require(_tokenBAmount >= exchangeAmount, "EXCHANGE:ERRTX005");


        require(address(tokenB).safeTransferFrom(buyer, address(this), tokens_sold), "EXCHANGE:ERRTX001");
        require(address(tokenA).safeTransfer(recipient, _tokenAAmount), "EXCHANGE:ERRTX002");

        _token_b_balance = _token_b_balance.add(tokens_sold);
        _token_a_balance = _token_a_balance.sub(_tokenAAmount);

        swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
        emit TokenPurchaseBuy(buyer, _tokenAAmount, exchangeAmount);
        emit Snapshot(buyer, _token_a_balance, _token_b_balance);

        projectPartyRepurchaseInner();
        return tokens_sold;
    }


    function convertTokenBToTokenASwapOutPut(uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline, address recipient) private returns (uint256){
        uint256 maxAmount = API_GetLiquidityReleaseSingleUserThatDayMaxAmount(msg.sender);
        require(maxAmount > 0, "EXCHANGE:ERR00009");
        require(deadline >= block.timestamp && _tokenAAmount > 0 && _tokenBAmount > 0, "EXCHANGE:ERRTX004");
        require(_tokenAAmount <= maxAmount, "EXCHANGE:ERR00010");


        (,,,,uint256 closeAAmount, uint256 closeBAmount,) = swapStatistics.API_getThatDayKline(address(tokenA));

        uint256 tokens_sold = ABDKMathQuad.toUInt(
            ABDKMathQuad.mul(ABDKMathQuad.fromUInt(_tokenAAmount),
            ABDKMathQuad.div(ABDKMathQuad.fromUInt(closeBAmount), ABDKMathQuad.fromUInt(closeAAmount)))
        );
        require(tokens_sold > 0, "EXCHANGE:ERRTX008");


        uint256 feeAmount = tokens_sold.mul(avalonFee.getExchangeFee()).div(10000);
        uint256 exchangeAmount = tokens_sold;
        if (feeAmount > 0 && feeAmount < tokens_sold) {
            exchangeAmount = tokens_sold.add(feeAmount);
            require(address(tokenB).safeTransferFrom(msg.sender, avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX001");
            emit TokenBuyFeeEvent(msg.sender, feeAmount);
        }

        // tokens sold is always > 0
        require(_tokenBAmount >= exchangeAmount, "EXCHANGE:ERRTX005");


        require(address(tokenB).safeTransferFrom(msg.sender, address(this), tokens_sold), "EXCHANGE:ERRTX001");
        require(address(tokenA).safeTransfer(recipient, _tokenAAmount), "EXCHANGE:ERRTX002");


        sendLiquidityReleaseAmount(_tokenAAmount, tokens_sold);
        emit TokenConvertPurchase(msg.sender, _tokenAAmount, exchangeAmount);
        return _tokenAAmount;
    }

    function convertTokenBToTokenASwapInPut(uint256 _tokenBAmount, uint256 _tokenAAmount, uint256 deadline, address recipient) private returns (uint256){
        uint256 maxAmount = API_GetLiquidityReleaseSingleUserThatDayMaxAmount(msg.sender);
        require(maxAmount > 0, "EXCHANGE:ERR00009");
        require(deadline >= block.timestamp && _tokenBAmount > 0 && _tokenAAmount > 0, "EXCHANGE:ERRTX004");

        uint256 exchangeAmount = _tokenBAmount;

        {
            uint256 feeAmount = _tokenBAmount.mul(avalonFee.getExchangeFee()).div(10000);
            if (feeAmount > 0 && feeAmount < _tokenBAmount) {
                exchangeAmount = _tokenBAmount.sub(feeAmount);
                require(address(tokenB).safeTransferFrom(msg.sender, avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX001");
                emit TokenBuyFeeEvent(msg.sender, feeAmount);
            }
        }

        (,,,,uint256 closeAAmount, uint256 closeBAmount,) = swapStatistics.API_getThatDayKline(address(tokenA));


        uint256 wei_bought = ABDKMathQuad.toUInt(
            ABDKMathQuad.mul(ABDKMathQuad.fromUInt(exchangeAmount),
            ABDKMathQuad.div(ABDKMathQuad.fromUInt(closeAAmount), ABDKMathQuad.fromUInt(closeBAmount)))
        );
        require(wei_bought > 0, "EXCHANGE:ERRTX008");
        require(wei_bought >= _tokenAAmount, "EXCHANGE:ERRTX005");
        require(wei_bought <= maxAmount, "EXCHANGE:ERR00010");

        require(address(tokenB).safeTransferFrom(msg.sender, address(this), exchangeAmount), "EXCHANGE:ERRTX001");
        require(address(tokenA).safeTransfer(recipient, wei_bought), "EXCHANGE:ERRTX002");

        sendLiquidityReleaseAmount(wei_bought, exchangeAmount);
        emit TokenConvertPurchase(msg.sender, wei_bought, _tokenBAmount);
        return wei_bought;
    }

    function sendLiquidityReleaseAmount(uint256 tokenAAmount, uint256 tokenBAmount) private {
        address introducer = recommendInterface.GetIntroducer(msg.sender);
        bool introducerBind = introducer != address(0) && introducer != address(0xFF);
        (uint256 incomeAmount,uint256 invAmount,uint256 feeAmount) = API_AddLiquidityReleaseSingleUserAmountRecord(introducerBind,
            avalonFee.getLiquidityFee(), msg.sender, tokenAAmount, tokenBAmount);

        if (feeAmount > 0) {
            require(address(tokenB).safeTransfer(avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX002");
            emit TokenConvertPurchaseIncomeFeeEvent(LiquidityReleaseIncomeAddress, feeAmount);
        }

        if (invAmount > 0 && introducerBind) {
            require(address(tokenB).safeTransfer(introducer, invAmount), "EXCHANGE:ERRTX002");
            emit InvitationRewardEvent(msg.sender, introducer, invAmount);
        }

        if (incomeAmount > 0) {
            require(address(tokenB).safeTransfer(LiquidityReleaseIncomeAddress, incomeAmount), "EXCHANGE:ERRTX002");
            emit TokenConvertPurchaseIncomeEvent(msg.sender, LiquidityReleaseIncomeAddress, incomeAmount);
        }

    }


    function getUserLiquidityRecord(uint256 offset, uint256 size, address owner) public view returns (
        uint256 len,
        uint256 [] memory idx,
        uint256 [] memory tokenAAmount,
        uint256 [] memory tokenBAmount,
        uint256 [] memory liquidityMinted,
        uint256 [] memory createTime,
        uint256 [] memory awardAmount,
        bool [] memory over
    ){
        require(offset >= 0);
        require(size > 0);
        LiquidityRecord [] storage lr = userLiquidityRecord[owner];

        uint256 lrSize = lr.length;
        if (size > lrSize) {
            size = lrSize;
        }
        len = 0;
        idx = new uint256[](size);
        tokenAAmount = new uint256[](size);
        tokenBAmount = new uint256[](size);
        liquidityMinted = new uint256[](size);
        createTime = new uint256[](size);
        awardAmount = new uint256[](size);
        over = new bool[](size);

        if (lrSize == 0 || offset > (lrSize - 1)) {
            return (len, idx, tokenAAmount, tokenBAmount, liquidityMinted, createTime, awardAmount, over);
        }
        uint256 i = lrSize - 1 - offset;
        uint256 iMax = 0;
        if (offset <= (lrSize - size)) {
            iMax = lrSize - size - offset;
        }

        while (i >= 0 && i >= iMax) {
            LiquidityRecord memory kk = lr[i];
            idx[len] = kk.idx;
            tokenAAmount[len] = kk.tokenAAmount;
            tokenBAmount[len] = kk.tokenBAmount;
            liquidityMinted[len] = kk.liquidityMinted;
            createTime[len] = kk.createTime;
            awardAmount[len] = kk.awardAmount;
            over[len] = kk.over;
            len = len + 1;
            if (i == 0) {
                break;
            }
            i--;
        }
        return (len, idx, tokenAAmount, tokenBAmount, liquidityMinted, createTime, awardAmount, over);
    }


    function addLiquidity(uint256 min_liquidity, uint256 _tokenAAmount, uint256 _tokenBAmount, uint256 deadline) public nonReentrant isBindCode returns (uint256) {
        require(deadline > block.timestamp && _tokenAAmount > 0 && _tokenBAmount > 0 && firstLiquiditySetting, 'EXCHANGE:ERRTX004');
        uint256 total_liquidity = _LiquidityTotalSupply;
        if (total_liquidity == 0) {
            require(_tokenBAmount >= uint256(100000000), "EXCHANGE:ERRTX004");
            (
            ,
            ,
            ,
            ,
            uint256 closeAAmount,
            uint256 closeBAmount,
            ) = swapStatistics.API_getThatDayKline(address(tokenA));
            require(
                ABDKMathQuad.cmp(
                    ABDKMathQuad.abs(
                        ABDKMathQuad.sub(
                            ABDKMathQuad.div(ABDKMathQuad.fromUInt(_tokenBAmount), ABDKMathQuad.fromUInt(_tokenAAmount)),
                            ABDKMathQuad.div(ABDKMathQuad.fromUInt(closeBAmount), ABDKMathQuad.fromUInt(closeAAmount))
                        )
                    ),
                    ABDKMathQuad.div(ABDKMathQuad.fromUInt(uint256(1)), ABDKMathQuad.fromUInt(uint256(1000000)))
                ) < int8(0), "EXCHANGE:ERRTX005"
            );

            require(address(tokenA).safeTransferFrom(msg.sender, address(this), _tokenAAmount), "EXCHANGE:ERRTX001");
            require(address(tokenB).safeTransferFrom(msg.sender, address(this), _tokenBAmount), "EXCHANGE:ERRTX001");

            _token_a_balance = _token_a_balance.add(_tokenAAmount);
            _token_b_balance = _token_b_balance.add(_tokenBAmount);
            _LiquidityTotalSupply = _tokenAAmount;
            userLiquidityRecord[msg.sender].push(
                LiquidityRecord(
                    userLiquidityRecord[msg.sender].length,
                    _tokenAAmount, _tokenBAmount, _tokenAAmount, block.timestamp, 0, false
                )
            );
            emit AddLiquidity(msg.sender, _tokenAAmount, _tokenBAmount);
            emit Snapshot(msg.sender, _token_a_balance, _token_b_balance);
            return _tokenBAmount;
        } else {
            require(min_liquidity > 0, "EXCHANGE:ERR00013");
            uint256 token_amount = (_tokenAAmount.mul(_token_b_balance).div(_token_a_balance)).add(1);
            uint256 feeAmount = token_amount.mul(avalonFee.getLiquidityFee()).div(10000);
            if (feeAmount > 0) {
                require(address(tokenB).safeTransferFrom(msg.sender, avalonFee.feeAddress(), feeAmount), "EXCHANGE:ERRTX001");
                emit AddLiquidityFeeEvent(msg.sender, feeAmount);
            }
            uint256 liquidity_minted = _tokenAAmount.mul(total_liquidity).div(_token_a_balance);
            require(_tokenBAmount >= token_amount.add(feeAmount) && liquidity_minted >= min_liquidity, "EXCHANGE:ERRTX005");

            require(address(tokenA).safeTransferFrom(msg.sender, address(this), _tokenAAmount), "EXCHANGE:ERRTX001");
            require(address(tokenB).safeTransferFrom(msg.sender, address(this), token_amount), "EXCHANGE:ERRTX001");


            _token_a_balance = _token_a_balance.add(_tokenAAmount);
            _token_b_balance = _token_b_balance.add(token_amount);
            _LiquidityTotalSupply = total_liquidity.add(liquidity_minted);
            userLiquidityRecord[msg.sender].push(
                LiquidityRecord(
                    userLiquidityRecord[msg.sender].length,
                    _tokenAAmount, token_amount, liquidity_minted, block.timestamp, 0, false
                )
            );

            emit AddLiquidity(msg.sender, _tokenAAmount, token_amount);
            emit Snapshot(msg.sender, _token_a_balance, _token_b_balance);
            return liquidity_minted;
        }

    }

    function firstAddLiquidity(
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _upDown,
        uint256 [] memory rewardParam,
        uint256 [] memory _teamParam,
        address _teamRewardAddress,
        uint256 [] memory _LiquidityReleaseParam,
        address _LiquidityReleaseIncomeAddress) public checkManagerOnly nonReentrant isBindCode returns (uint256){

        require(
            address(avalonFactory) != address(0)
            && _tokenAAmount > uint256(0)
            && _tokenBAmount >= uint256(100000000) // 100USDT
            && address(tokenB) != address(0)
            && address(tokenA) != address(0)
            && firstLiquiditySetting == false
            && _LiquidityTotalSupply == 0, "EXCHANGE:ERR00004");

        require(address(tokenA).safeTransferFrom(msg.sender, address(this), _tokenAAmount), "EXCHANGE:ERRTX001");
        require(address(tokenB).safeTransferFrom(msg.sender, address(this), _tokenBAmount), "EXCHANGE:ERRTX001");


        _token_a_balance = _token_a_balance.add(_tokenAAmount);
        _token_b_balance = _token_b_balance.add(_tokenBAmount);
        _LiquidityTotalSupply = _tokenAAmount;
        userLiquidityRecord[msg.sender].push(
            LiquidityRecord(
                userLiquidityRecord[msg.sender].length,
                _tokenAAmount, _tokenBAmount, _tokenAAmount, block.timestamp, 0, false
            )
        );
        if (_upDown > 0) {
            API_UpdateUpDownInner(_upDown);
        } else {
            API_UpdateUpDownInner(500);
        }

        if (rewardParam.length == 6 && API_UpdateLiquidityRewardSetting(rewardParam[0], rewardParam[1], rewardParam[2], rewardParam[3], rewardParam[4], rewardParam[5])) {
            require(address(tokenA).safeTransferFrom(msg.sender, address(this), rewardParam[0]), "EXCHANGE:ERRTX001");
        }
        if (_teamParam.length == 4 && API_UpdateTeamRewardSetting(_teamParam[0], _teamParam[1], _teamParam[2], _teamParam[3], _teamRewardAddress)) {
            require(address(tokenA).safeTransferFrom(msg.sender, address(this), _teamParam[0]), "EXCHANGE:ERRTX001");
        }
        if (_LiquidityReleaseParam.length == 7 && API_UpdateLiquidityReleaseSetting(_LiquidityReleaseParam[0], _LiquidityReleaseParam[1], _LiquidityReleaseParam[2], _LiquidityReleaseParam[3], _LiquidityReleaseParam[4], _LiquidityReleaseParam[5], _LiquidityReleaseParam[6], _LiquidityReleaseIncomeAddress)) {
            require(address(tokenA).safeTransferFrom(msg.sender, address(this), _LiquidityReleaseParam[0]), "EXCHANGE:ERRTX001");
        }
        firstLiquiditySetting = true;
        swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
        emit AddLiquidity(msg.sender, _tokenAAmount, _tokenBAmount);
        emit Snapshot(msg.sender, _token_a_balance, _token_b_balance);
        return _tokenBAmount;
    }


    function removeLiquidity(uint256 idx, uint256 tokenAMinAmount, uint256 tokenBMinAmount, uint256 deadline) public nonReentrant returns (uint256, uint256) {
        require(deadline > block.timestamp && idx >= 0, "EXCHANGE:ERR00005");
        LiquidityRecord storage record = userLiquidityRecord[msg.sender][idx];
        require(record.liquidityMinted > 0 && record.over == false &&
            (_LiquidityRewardCycle == 0 || block.timestamp.sub(record.createTime) >= _LiquidityRewardCycle.mul(1 days)), "EXCHANGE:ERR00012");
        uint256 amount = record.liquidityMinted;

        uint256 total_liquidity = _LiquidityTotalSupply;
        require(total_liquidity > 0, "EXCHANGE:ERR00006");
        uint256 a_amount = amount.mul(_token_a_balance).div(total_liquidity);
        uint256 b_amount = amount.mul(_token_b_balance).div(total_liquidity);
        require(a_amount >= tokenAMinAmount && b_amount >= tokenBMinAmount, "EXCHANGE:ERR00007");
        _LiquidityTotalSupply = total_liquidity.sub(amount);


        require(address(tokenA).safeTransfer(msg.sender, a_amount), "EXCHANGE:ERRTX002");
        require(address(tokenB).safeTransfer(msg.sender, b_amount), "EXCHANGE:ERRTX002");

        _token_a_balance = _token_a_balance.sub(a_amount);
        _token_b_balance = _token_b_balance.sub(b_amount);
        record.over = true;
        receiveLiquidityRewards(msg.sender, idx);
        emit RemoveLiquidity(msg.sender, a_amount, b_amount);
        emit Snapshot(msg.sender, _token_a_balance, _token_b_balance);
        return (a_amount, b_amount);
    }

    function receiveLiquidityRewards(address _address, uint256 _idx) private {
        if (_LiquidityRewardAmount > 0 && _LiquidityRewardCycle > 0 && _LiquidityRewardProp > 0) {
            LiquidityRecord storage record = userLiquidityRecord[_address][_idx];
            require(record.createTime > 0 && block.timestamp >= record.createTime, "EXCHANGE:ERR00008");
            uint256 _sendAmount = API_SendLiquidityRewardAmount(block.timestamp.sub(record.createTime)
            .div(_LiquidityRewardCycle.mul(1 days))
            .mul(record.tokenAAmount.mul(_LiquidityRewardProp).div(10000)));
            if (_sendAmount > 0) {
                record.awardAmount = _sendAmount;
                require(address(tokenA).safeTransfer(_address, _sendAmount), "EXCHANGE:ERRTX002");
                emit ReceiveLiquidityRewardEvent(_address, _sendAmount);
                if (_LiquidityInviteRewardMode == 1) {
                    address introducer = recommendInterface.GetIntroducer(_address);
                    if (introducer != address(0) && introducer != address(0xFF) && _LiquidityInviteRewardProp > 0) {
                        uint256 introducerAmount = API_SendLiquidityRewardAmount(_sendAmount.mul(_LiquidityInviteRewardProp).div(10000));
                        if (introducerAmount > 0) {
                            require(address(tokenA).safeTransfer(introducer, introducerAmount), "EXCHANGE:ERRTX002");
                            emit InvitationRewardEvent(_address, introducer, introducerAmount);
                        }
                    }
                }
            }
        }
    }


    function projectPartyRepurchaseState() public view returns (bool _state, uint256 _repurchaseAmount, uint256 _destroyAmount) {
        if (LiquidityReleaseRepurchaseProp > 0
        && LiquidityReleaseRepurchaseCycle > 0
            && block.timestamp >= LiquidityReleaseRepurchaseLastTime.add(LiquidityReleaseRepurchaseCycle.mul(uint256(1 days)))) {
            uint256 repurchaseAmount = LiquidityReleaseRepoPool.mul(LiquidityReleaseRepurchaseProp).div(10000);
            (bool _exchangeStopState, bool _limit,, uint256 _tokenBMax) = getExchangeStopState();
            if (!_exchangeStopState) {
                if (_limit && repurchaseAmount >= _tokenBMax) {
                    repurchaseAmount = _tokenBMax;
                }
                if (repurchaseAmount > 0) {
                    uint256 wei_bought = getInputPrice(repurchaseAmount, _token_b_balance, _token_a_balance);
                    if (wei_bought > 0) {
                        return (true, repurchaseAmount, wei_bought);
                    }
                }
            }
            return (true, 0, 0);
        }
        return (false, 0, 0);
    }


    function projectPartyRepurchaseInner() private {
        (bool _state, uint256 _repurchaseAmount, uint256 _destroyAmount) = projectPartyRepurchaseState();
        if (_state) {
            LiquidityReleaseRepurchaseLastTime = block.timestamp.chinaTime().add(18 hours);
            LiquidityReleasePartyRepurchaseLastDestroyAmount = _destroyAmount;
            LiquidityReleasePartyLastRepurchaseAmount = _repurchaseAmount;
            LiquidityReleasePartyLastRepurchaseTime = block.timestamp;
            if (_repurchaseAmount > 0 && _destroyAmount > 0) {
                _token_b_balance = _token_b_balance.add(_repurchaseAmount);
                _token_a_balance = _token_a_balance.sub(_destroyAmount);
                LiquidityReleaseRepoPool = LiquidityReleaseRepoPool.sub(_repurchaseAmount);
                LiquidityReleasePartyRepurchaseAmount = LiquidityReleasePartyRepurchaseAmount.add(_repurchaseAmount);
                LiquidityReleasePartyRepurchaseDestroyAmount = LiquidityReleasePartyRepurchaseDestroyAmount.add(_destroyAmount);

                swapStatistics.API_addKline(address(tokenA), _token_a_balance, _token_b_balance);
                require(address(tokenA).safeTransfer(address(0), _destroyAmount), "EXCHANGE:ERRTX002");
                emit ProjectPartyRepurchaseEvent(_repurchaseAmount, _destroyAmount);
                emit TokenPurchaseBuy(address(0), _destroyAmount, _repurchaseAmount);
                emit Snapshot(address(0), _token_a_balance, _token_b_balance);
            }
        }
    }

    function getExchangeStopState() public view returns (bool _state, bool _limit, uint256 _tokenAMax, uint256 _tokenBMax){
        (
        ,
        ,
        uint256 openAAmount,
        uint256 openBAmount,
        uint256 closeAAmount,
        uint256 closeBAmount,
        uint256 state
        ) = swapStatistics.API_getThatDayKline(address(tokenA));
        uint256 _up = API_GetCurrentUpDown();
        if (_up > 0 && state != 0) {
            bytes16 openPrice = ABDKMathQuad.div(ABDKMathQuad.fromUInt(openBAmount), ABDKMathQuad.fromUInt(openAAmount));
            bytes16 closePrice = ABDKMathQuad.div(ABDKMathQuad.fromUInt(closeBAmount), ABDKMathQuad.fromUInt(closeAAmount));
            // 比较 closePrice <= openPrice
            if (ABDKMathQuad.cmp(closePrice, openPrice) > int8(0)) {
                // 比较涨跌幅
                if (ABDKMathQuad.cmp(ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.sub(closePrice, openPrice), ABDKMathQuad.fromInt(10000)), openPrice), ABDKMathQuad.fromUInt(_up)) >= int8(0)) {
                    return (true, false, 0, 0);
                }
            }
            bytes16 maxPrice = ABDKMathQuad.div(ABDKMathQuad.mul(openPrice, ABDKMathQuad.add(ABDKMathQuad.fromUInt(10000),
                ABDKMathQuad.add(
                    ABDKMathQuad.fromUInt(_up),
                    ABDKMathQuad.div(ABDKMathQuad.fromUInt(uint(1)), ABDKMathQuad.fromUInt(uint256(100000000)))
                )
                )), ABDKMathQuad.fromUInt(10000));
            if (ABDKMathQuad.cmp(maxPrice, ABDKMathQuad.fromUInt(uint(1))) >= int8(0)) {
                // max a = x- sqrt(xy/p)
                uint256 maxAAmount = ABDKMathQuad.toUInt(
                    ABDKMathQuad.sub(
                        ABDKMathQuad.fromUInt(_token_a_balance),
                        ABDKMathQuad.sqrt(
                            ABDKMathQuad.div(
                                ABDKMathQuad.mul(
                                    ABDKMathQuad.fromUInt(_token_a_balance),
                                    ABDKMathQuad.fromUInt(_token_b_balance)
                                ),
                                maxPrice
                            )
                        )
                    )
                ).add(1);
                uint256 maxBAmount = maxAAmount.mul(_token_b_balance).div(_token_a_balance.sub(maxAAmount)).add(1);
                return (false, true, maxAAmount, maxBAmount);
            } else {
                // max b = sqrt (pxy) - y
                uint256 maxBAmount = ABDKMathQuad.toUInt(
                    ABDKMathQuad.sub(
                        ABDKMathQuad.sqrt(
                            ABDKMathQuad.mul(
                                ABDKMathQuad.mul(
                                    maxPrice, ABDKMathQuad.fromUInt(_token_a_balance)
                                )
                            , ABDKMathQuad.fromUInt(_token_b_balance)
                            )
                        ),
                        ABDKMathQuad.fromUInt(_token_b_balance)
                    )
                ).add(1);
                uint256 maxAAmount = maxBAmount.mul(_token_a_balance).div(_token_b_balance.add(maxBAmount));
                return (false, true, maxAAmount, maxBAmount);
            }

        } else {
            return (false, false, 0, 0);
        }
    }

    function getExchangeDownStopState() public view returns (bool _state, bool _limit, uint256 _tokenAMax, uint256 _tokenBMax){
        (
        ,
        ,
        uint256 openAAmount,
        uint256 openBAmount,
        uint256 closeAAmount,
        uint256 closeBAmount,
        uint256 state
        ) = swapStatistics.API_getThatDayKline(address(tokenA));
        uint256 _up = API_GetCurrentUpDown();
        if (_up > 0 && state != 0) {
            bytes16 openPrice = ABDKMathQuad.div(ABDKMathQuad.fromUInt(openBAmount), ABDKMathQuad.fromUInt(openAAmount));
            bytes16 closePrice = ABDKMathQuad.div(ABDKMathQuad.fromUInt(closeBAmount), ABDKMathQuad.fromUInt(closeAAmount));
            if (ABDKMathQuad.cmp(openPrice, closePrice) > int8(0)) {
                if (ABDKMathQuad.cmp(ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.sub(closePrice, openPrice), ABDKMathQuad.fromInt(10000)), openPrice), ABDKMathQuad.neg(ABDKMathQuad.fromUInt(_up))) <= int8(0)) {
                    return (true, false, 0, 0);
                }
            }
            bytes16 minPrice = ABDKMathQuad.div(
                ABDKMathQuad.mul(
                    openPrice,
                    ABDKMathQuad.sub(
                        ABDKMathQuad.fromUInt(10000),
                        ABDKMathQuad.add(
                            ABDKMathQuad.fromUInt(_up),
                            ABDKMathQuad.div(ABDKMathQuad.fromUInt(uint(1)), ABDKMathQuad.fromUInt(uint256(100000000)))
                        )
                    )
                ),
                ABDKMathQuad.fromUInt(10000));

            if (ABDKMathQuad.cmp(minPrice, ABDKMathQuad.fromUInt(uint(1))) >= int8(0)) {
                // max a =  sqrt(xy/p) - x
                uint256 maxAAmount = ABDKMathQuad.toUInt(
                    ABDKMathQuad.sub(
                        ABDKMathQuad.sqrt(
                            ABDKMathQuad.div(
                                ABDKMathQuad.mul(
                                    ABDKMathQuad.fromUInt(_token_a_balance),
                                    ABDKMathQuad.fromUInt(_token_b_balance)
                                ),
                                minPrice
                            )
                        ),
                        ABDKMathQuad.fromUInt(_token_a_balance)
                    )
                ).add(1);
                uint256 maxBAmount = maxAAmount.mul(_token_b_balance).div(_token_a_balance.add(maxAAmount));
                return (false, true, maxAAmount, maxBAmount);
            } else {
                // max b = y - sqrt (pxy)
                uint256 maxBAmount = ABDKMathQuad.toUInt(
                    ABDKMathQuad.sub(
                        ABDKMathQuad.fromUInt(_token_b_balance),
                        ABDKMathQuad.sqrt(
                            ABDKMathQuad.mul(
                                ABDKMathQuad.mul(
                                    minPrice, ABDKMathQuad.fromUInt(_token_a_balance)
                                )
                            , ABDKMathQuad.fromUInt(_token_b_balance)
                            )
                        )
                    )
                ).add(1);
                uint256 maxAAmount = maxBAmount.mul(_token_a_balance).div(_token_b_balance.sub(maxBAmount)).add(1);
                return (false, true, maxAAmount, maxBAmount);
            }


        } else {
            return (false, false, 0, 0);
        }
    }


    function API_AddLiquidityReleaseRepoPool(uint256 tokenAmount) public nonReentrant checkManagerOnly {
        require(LiquidityReleaseRepurchaseProp > 0 && LiquidityReleaseRepurchaseCycle > 0, "EXCHANGE:ERR00011");
        API_AddLiquidityLiquidityReleaseRepoPool(tokenAmount);
        require(address(tokenB).safeTransferFrom(msg.sender, address(this), tokenAmount), "EXCHANGE:ERRTX001");
        emit AddLiquidityReleaseRepoPoolAmountEvent(msg.sender, tokenAmount);
    }


    function API_ReceiveTeamReward() public nonReentrant checkManagerOnly returns (address withdrawAddress, uint256 amount){
        (address _withdrawAddress, uint256 _amount) = API_WithDrawTeamReward();
        require(address(tokenA).safeTransfer(_withdrawAddress, _amount), "EXCHANGE:ERRTX002");
        emit ReceiveTeamRewardEvent(_withdrawAddress, _amount);
        return (_withdrawAddress, _amount);
    }


    function API_UpdateUpDown(uint256 _upDown) public nonReentrant checkManagerOnly {
        require(upDownSettingCount < 3, "MANAGER:ERR00002");
        API_UpdateUpDownInner(_upDown);
    }

    function API_UpdateUpDownInner(uint256 _upDown) private {
        require(_upDown >= 1 && _upDown <= 2000 && upDownSettingCount > 0 && _upDown > upDown, "MANAGER:ERR00002");
        oldUpDown = API_GetCurrentUpDown();
        upDown = _upDown;
        upDownStartTime = uint256(block.timestamp).chinaTime().add(uint256(1 days));
        upDownSettingCount = upDownSettingCount.sub(uint256(1));
    }


    function tokenAddress() public view returns (address a, address b) {
        return (address(tokenA), address(tokenB));
    }

    function factoryAddress() public view returns (address) {
        return address(avalonFactory);
    }

    function recommendAddress() public view returns (address) {
        return address(recommendInterface);
    }

}

//SourceUnit: TransferHelper.sol

pragma solidity ^0.5.8;


pragma solidity ^0.5.8;

// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}