// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "../../../../../@openzeppelin/contracts/math/SafeMath.sol";
import "../../../../../@openzeppelin/contracts/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  FinderInterface
} from '../../../../@jarvis-network/uma-core/contracts/oracle/interfaces/FinderInterface.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface IDerivativeMain {
  struct FeePayerData {
    IERC20 collateralCurrency;
    FinderInterface finder;
    uint256 lastPaymentTime;
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  struct PositionManagerData {
    ISynthereumFinder synthereumFinder;
    IERC20 tokenCurrency;
    bytes32 priceIdentifier;
    uint256 withdrawalLiveness;
    FixedPoint.Unsigned minSponsorTokens;
    FixedPoint.Unsigned emergencyShutdownPrice;
    uint256 emergencyShutdownTimestamp;
    address excessTokenBeneficiary;
  }

  struct GlobalPositionData {
    FixedPoint.Unsigned totalTokensOutstanding;
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  function feePayerData() external view returns (FeePayerData memory data);

  function positionManagerData()
    external
    view
    returns (PositionManagerData memory data);

  function globalPositionData()
    external
    view
    returns (GlobalPositionData memory data);

  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  ) external;

  function deposit(FixedPoint.Unsigned memory collateralAmount) external;

  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external;

  function withdrawPassedRequest()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function cancelWithdrawal() external;

  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external;

  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function repay(FixedPoint.Unsigned memory numTokens) external;

  function settleEmergencyShutdown()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  function emergencyShutdown() external;

  function remargin() external;

  function trimExcess(IERC20 token)
    external
    returns (FixedPoint.Unsigned memory amount);

  function getCollateral(address sponsor)
    external
    view
    returns (FixedPoint.Unsigned memory collateralAmount);

  function totalPositionCollateral()
    external
    view
    returns (FixedPoint.Unsigned memory totalCollateral);

  function emergencyShutdownPrice()
    external
    view
    returns (FixedPoint.Unsigned memory emergencyPrice);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Provides addresses of the live contracts implementing certain interfaces.
 * @dev Examples are the Oracle or Store interfaces.
 */
interface FinderInterface {
    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
     * @param implementationAddress address of the deployed contract that implements the interface.
     */
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the deployed contract that implements the interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControl
} from '../../@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControl {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory _roles) public {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {ISynthereumDeployer} from './interfaces/IDeployer.sol';
import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {ISynthereumPoolRegistry} from './interfaces/IPoolRegistry.sol';
import {ISelfMintingRegistry} from './interfaces/ISelfMintingRegistry.sol';
import {ISynthereumManager} from './interfaces/IManager.sol';
import {IERC20} from '../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IDeploymentSignature} from './interfaces/IDeploymentSignature.sol';
import {
  ISynthereumPoolDeployment
} from '../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {
  IDerivativeDeployment
} from '../derivative/common/interfaces/IDerivativeDeployment.sol';
import {
  IExtendedDerivativeDeployment
} from '../derivative/common/interfaces/IExtendedDerivativeDeployment.sol';
import {
  ISelfMintingDerivativeDeployment
} from '../derivative/self-minting/common/interfaces/ISelfMintingDerivativeDeployment.sol';
import {IRole} from '../base/interfaces/IRole.sol';
import {SynthereumInterfaces} from './Constants.sol';
import {Address} from '../../@openzeppelin/contracts/utils/Address.sol';
import {
  EnumerableSet
} from '../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  Lockable
} from '../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {
  AccessControl
} from '../../@openzeppelin/contracts/access/AccessControl.sol';

contract SynthereumDeployer is ISynthereumDeployer, AccessControl, Lockable {
  using Address for address;
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 private constant ADMIN_ROLE = 0x00;

  bytes32 private constant POOL_ROLE = keccak256('Pool');

  bytes32 private constant MINTER_ROLE = keccak256('Minter');

  bytes32 private constant BURNER_ROLE = keccak256('Burner');

  struct Roles {
    address admin;
    address maintainer;
  }

  ISynthereumFinder public synthereumFinder;

  event PoolDeployed(
    uint8 indexed poolVersion,
    address indexed derivative,
    address indexed newPool
  );
  event DerivativeDeployed(
    uint8 indexed derivativeVersion,
    address indexed pool,
    address indexed newDerivative
  );
  event SelfMintingDerivativeDeployed(
    uint8 indexed selfMintingDerivativeVersion,
    address indexed selfMintingDerivative
  );

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  constructor(ISynthereumFinder _synthereumFinder, Roles memory _roles) public {
    synthereumFinder = _synthereumFinder;
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative, true);
    setDerivativeRoles(derivative, pool, false);
    setSyntheticTokenRoles(derivative);
    ISynthereumPoolRegistry poolRegistry = getPoolRegistry();
    poolRegistry.registerPool(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISynthereumPoolDeployment pool)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    pool = deployPool(
      factoryVersioning,
      poolVersion,
      derivative,
      poolParamsData
    );
    checkPoolDeployment(pool, poolVersion);
    checkPoolAndDerivativeMatching(pool, derivative, true);
    setPoolRole(derivative, pool);
    ISynthereumPoolRegistry poolRegistry = getPoolRegistry();
    poolRegistry.registerPool(
      pool.syntheticTokenSymbol(),
      pool.collateralToken(),
      poolVersion,
      address(pool)
    );
    emit PoolDeployed(poolVersion, address(derivative), address(pool));
  }

  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (IDerivativeDeployment derivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    derivative = deployDerivative(
      factoryVersioning,
      derivativeVersion,
      derivativeParamsData
    );
    checkDerivativeRoles(derivative);
    if (address(pool) != address(0)) {
      checkPoolAndDerivativeMatching(pool, derivative, false);
      checkPoolRegistration(pool);
      setDerivativeRoles(derivative, pool, false);
    } else {
      setDerivativeRoles(derivative, pool, true);
    }
    setSyntheticTokenRoles(derivative);
    emit DerivativeDeployed(
      derivativeVersion,
      address(pool),
      address(derivative)
    );
  }

  function deployOnlySelfMintingDerivative(
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  )
    external
    override
    onlyMaintainer
    nonReentrant
    returns (ISelfMintingDerivativeDeployment selfMintingDerivative)
  {
    ISynthereumFactoryVersioning factoryVersioning = getFactoryVersioning();
    selfMintingDerivative = deploySelfMintingDerivative(
      factoryVersioning,
      selfMintingDerVersion,
      selfMintingDerParamsData
    );
    checkSelfMintingDerivativeDeployment(
      selfMintingDerivative,
      selfMintingDerVersion
    );
    address tokenCurrency = address(selfMintingDerivative.tokenCurrency());
    addSyntheticTokenRoles(tokenCurrency, address(selfMintingDerivative));
    ISelfMintingRegistry selfMintingRegistry = getSelfMintingRegistry();
    selfMintingRegistry.registerSelfMintingDerivative(
      selfMintingDerivative.syntheticTokenSymbol(),
      selfMintingDerivative.collateralCurrency(),
      selfMintingDerVersion,
      address(selfMintingDerivative)
    );
    emit SelfMintingDerivativeDeployed(
      selfMintingDerVersion,
      address(selfMintingDerivative)
    );
  }

  function deployDerivative(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 derivativeVersion,
    bytes memory derivativeParamsData
  ) internal returns (IDerivativeDeployment derivative) {
    address derivativeFactory =
      factoryVersioning.getDerivativeFactoryVersion(derivativeVersion);
    bytes memory derivativeDeploymentResult =
      derivativeFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(derivativeFactory),
          derivativeParamsData
        ),
        'Wrong derivative deployment'
      );
    derivative = IDerivativeDeployment(
      abi.decode(derivativeDeploymentResult, (address))
    );
  }

  function deployPool(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 poolVersion,
    IDerivativeDeployment derivative,
    bytes memory poolParamsData
  ) internal returns (ISynthereumPoolDeployment pool) {
    address poolFactory = factoryVersioning.getPoolFactoryVersion(poolVersion);
    bytes memory poolDeploymentResult =
      poolFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(poolFactory),
          bytes32(uint256(address(derivative))),
          poolParamsData
        ),
        'Wrong pool deployment'
      );
    pool = ISynthereumPoolDeployment(
      abi.decode(poolDeploymentResult, (address))
    );
  }

  function deploySelfMintingDerivative(
    ISynthereumFactoryVersioning factoryVersioning,
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  ) internal returns (ISelfMintingDerivativeDeployment selfMintingDerivative) {
    address selfMintingDerFactory =
      factoryVersioning.getSelfMintingFactoryVersion(selfMintingDerVersion);
    bytes memory selfMintingDerDeploymentResult =
      selfMintingDerFactory.functionCall(
        abi.encodePacked(
          getDeploymentSignature(selfMintingDerFactory),
          selfMintingDerParamsData
        ),
        'Wrong self-minting derivative deployment'
      );
    selfMintingDerivative = ISelfMintingDerivativeDeployment(
      abi.decode(selfMintingDerDeploymentResult, (address))
    );
  }

  function setDerivativeRoles(
    IDerivativeDeployment derivative,
    ISynthereumPoolDeployment pool,
    bool isOnlyDerivative
  ) internal {
    IRole derivativeRoles = IRole(address(derivative));
    if (!isOnlyDerivative) {
      derivativeRoles.grantRole(POOL_ROLE, address(pool));
    }
    derivativeRoles.grantRole(ADMIN_ROLE, address(getManager()));
    derivativeRoles.renounceRole(ADMIN_ROLE, address(this));
  }

  function setSyntheticTokenRoles(IDerivativeDeployment derivative) internal {
    IRole tokenCurrency = IRole(address(derivative.tokenCurrency()));
    if (
      !tokenCurrency.hasRole(MINTER_ROLE, address(derivative)) ||
      !tokenCurrency.hasRole(BURNER_ROLE, address(derivative))
    ) {
      addSyntheticTokenRoles(address(tokenCurrency), address(derivative));
    }
  }

  function addSyntheticTokenRoles(address tokenCurrency, address derivative)
    internal
  {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](2);
    bytes32[] memory roles = new bytes32[](2);
    address[] memory accounts = new address[](2);
    contracts[0] = tokenCurrency;
    contracts[1] = tokenCurrency;
    roles[0] = MINTER_ROLE;
    roles[1] = BURNER_ROLE;
    accounts[0] = derivative;
    accounts[1] = derivative;
    manager.grantSynthereumRole(contracts, roles, accounts);
  }

  function setPoolRole(
    IDerivativeDeployment derivative,
    ISynthereumPoolDeployment pool
  ) internal {
    ISynthereumManager manager = getManager();
    address[] memory contracts = new address[](1);
    bytes32[] memory roles = new bytes32[](1);
    address[] memory accounts = new address[](1);
    contracts[0] = address(derivative);
    roles[0] = POOL_ROLE;
    accounts[0] = address(pool);
    manager.grantSynthereumRole(contracts, roles, accounts);
  }

  function getFactoryVersioning()
    internal
    view
    returns (ISynthereumFactoryVersioning factoryVersioning)
  {
    factoryVersioning = ISynthereumFactoryVersioning(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.FactoryVersioning
      )
    );
  }

  function getPoolRegistry()
    internal
    view
    returns (ISynthereumPoolRegistry poolRegistry)
  {
    poolRegistry = ISynthereumPoolRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.PoolRegistry
      )
    );
  }

  function getSelfMintingRegistry()
    internal
    view
    returns (ISelfMintingRegistry selfMintingRegister)
  {
    selfMintingRegister = ISelfMintingRegistry(
      synthereumFinder.getImplementationAddress(
        SynthereumInterfaces.SelfMintingRegistry
      )
    );
  }

  function getManager() internal view returns (ISynthereumManager manager) {
    manager = ISynthereumManager(
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
    );
  }

  function getDeploymentSignature(address deploymentContract)
    internal
    view
    returns (bytes4 signature)
  {
    signature = IDeploymentSignature(deploymentContract).deploymentSignature();
  }

  function checkDerivativeRoles(IDerivativeDeployment derivative)
    internal
    view
  {
    address[] memory derivativeAdmins = derivative.getAdminMembers();
    require(derivativeAdmins.length == 1, 'The derivative must have one admin');
    require(
      derivativeAdmins[0] == address(this),
      'The derivative admin must be the deployer'
    );
    address[] memory derivativePools = derivative.getPoolMembers();
    require(derivativePools.length == 0, 'The derivative must have no pools');
  }

  function checkPoolDeployment(ISynthereumPoolDeployment pool, uint8 version)
    internal
    view
  {
    require(
      pool.synthereumFinder() == synthereumFinder,
      'Wrong finder in pool deployment'
    );
    require(pool.version() == version, 'Wrong version in pool deployment');
  }

  function checkPoolAndDerivativeMatching(
    ISynthereumPoolDeployment pool,
    IDerivativeDeployment derivative,
    bool isPoolLinked
  ) internal view {
    require(
      pool.collateralToken() == derivative.collateralCurrency(),
      'Wrong collateral matching'
    );
    require(
      pool.syntheticToken() == derivative.tokenCurrency(),
      'Wrong synthetic token matching'
    );
    if (isPoolLinked) {
      require(
        pool.isDerivativeAdmitted(address(derivative)),
        'Pool doesnt support derivative'
      );
    }
  }

  function checkPoolRegistration(ISynthereumPoolDeployment pool) internal view {
    ISynthereumPoolRegistry poolRegistry = getPoolRegistry();
    require(
      poolRegistry.isPoolDeployed(
        pool.syntheticTokenSymbol(),
        pool.collateralToken(),
        pool.version(),
        address(pool)
      ),
      'Pool not registred'
    );
  }

  function checkSelfMintingDerivativeDeployment(
    ISelfMintingDerivativeDeployment selfMintingDerivative,
    uint8 version
  ) internal view {
    require(
      selfMintingDerivative.synthereumFinder() == synthereumFinder,
      'Wrong finder in self-minting deployment'
    );
    require(
      selfMintingDerivative.version() == version,
      'Wrong version in self-minting deployment'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumPoolDeployment
} from '../../synthereum-pool/common/interfaces/IPoolDeployment.sol';
import {
  IDerivativeDeployment
} from '../../derivative/common/interfaces/IDerivativeDeployment.sol';
import {
  ISelfMintingDerivativeDeployment
} from '../../derivative/self-minting/common/interfaces/ISelfMintingDerivativeDeployment.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

/**
 * @title Provides interface with functions of Synthereum deployer
 */
interface ISynthereumDeployer {
  /**
   * @notice Deploys derivative and pool linking the contracts together
   * @param derivativeVersion Version of derivative contract
   * @param poolVersion Version of the pool contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param poolParamsData Input params of pool constructor
   * @return derivative Derivative contract deployed
   * @return pool Pool contract deployed
   */
  function deployPoolAndDerivative(
    uint8 derivativeVersion,
    uint8 poolVersion,
    bytes calldata derivativeParamsData,
    bytes calldata poolParamsData
  )
    external
    returns (IDerivativeDeployment derivative, ISynthereumPoolDeployment pool);

  /**
   * @notice Deploys pool and links it with an already existing derivative
   * @param poolVersion Version of the pool contract
   * @param poolParamsData Input params of pool constructor
   * @param derivative Existing derivative contract to link with the new pool
   * @return pool Pool contract deployed
   */
  function deployOnlyPool(
    uint8 poolVersion,
    bytes calldata poolParamsData,
    IDerivativeDeployment derivative
  ) external returns (ISynthereumPoolDeployment pool);

  /**
   * @notice Deploys derivative and links it with an already existing pool
   * @param derivativeVersion Version of the derivative contract
   * @param derivativeParamsData Input params of derivative constructor
   * @param pool Existing pool contract to link with the new derivative
   * @return derivative Derivative contract deployed
   */
  function deployOnlyDerivative(
    uint8 derivativeVersion,
    bytes calldata derivativeParamsData,
    ISynthereumPoolDeployment pool
  ) external returns (IDerivativeDeployment derivative);

  function deployOnlySelfMintingDerivative(
    uint8 selfMintingDerVersion,
    bytes calldata selfMintingDerParamsData
  ) external returns (ISelfMintingDerivativeDeployment selfMintingDerivative);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /**
   * @notice Set the address of a version of a pool factory
   * @param version uint8 of the version index
   * @param poolFactory address of the pool factory
   */
  function setPoolFactory(uint8 version, address poolFactory) external;

  /**
   * @notice Remove the address of a version of a pool factory
   * @param version uint8 of the version index
   */
  function removePoolFactory(uint8 version) external;

  /**
   * @notice Set the address of a version of a perpetual derivative factory
   * @param version uint8 of the version index
   * @param derivativeFactory address of the pool factory
   */
  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external;

  /**
   * @notice Remove the address of a version of a perpetual derivative factory
   * @param version uint8 of the version index
   */
  function removeDerivativeFactory(uint8 version) external;

  function setSelfMintingFactory(uint8 version, address selfMintingFactory)
    external;

  function removeSelfMintingFactory(uint8 version) external;

  /**
   * @notice Returns the address of a version of pool factory if exists, otherwise revert
   * @param version uint8 of the version index
   */
  function getPoolFactoryVersion(uint8 version)
    external
    view
    returns (address poolFactory);

  /**
   * @notice Returns the number of existing versions of pool factory
   */
  function numberOfVerisonsOfPoolFactory()
    external
    view
    returns (uint256 numberOfVersions);

  /**
   * @notice Returns the address of a version of perpetual derivative factory if exists, otherwise revert
   * @param version uint8 of the version index
   */
  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    returns (address derivativeFactory);

  /**
   * @notice Returns the number of existing versions of perpetual derivative factory
   */
  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    returns (uint256 numberOfVersions);

  function getSelfMintingFactoryVersion(uint8 version)
    external
    view
    returns (address selfMintingFactory);

  function numberOfVerisonsOfSelfMintingFactory()
    external
    view
    returns (uint256 numberOfVersions);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumPoolRegistry
 */
interface ISynthereumPoolRegistry {
  /**
   * @notice Allow the deployer to register a pool just deployed
   * @param syntheticTokenSymbol Symbol of the syntheticToken
   * @param collateralToken Collateral ERC20 token of the pool deployed
   * @param poolVersion Version of the pool deployed
   * @param pool Address of the pool deployed
   */
  function registerPool(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 poolVersion,
    address pool
  ) external;

  /**
   * @notice Returns if a particular pool exists or not
   * @param poolSymbol Synthetic token symbol of the pool
   * @param collateral ERC20 contract of collateral currency
   * @param poolVersion Version of the pool
   * @param pool Contract of the pool to check
   * @return isDeployed Returns true if a particular pool exists, otherwiise false
   */
  function isPoolDeployed(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion,
    address pool
  ) external view returns (bool isDeployed);

  /**
   * @notice Returns all the pools with partcular symbol, collateral and verion
   * @param poolSymbol Synthetic token symbol of the pool
   * @param collateral ERC20 contract of collateral currency
   * @param poolVersion Version of the pool
   * @return List of all pools
   */
  function getPools(
    string calldata poolSymbol,
    IERC20 collateral,
    uint8 poolVersion
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the collateral used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISelfMintingRegistry {
  function registerSelfMintingDerivative(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external;

  function isSelfMintingDerivativeDeployed(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion,
    address selfMintingDerivative
  ) external view returns (bool isDeployed);

  function getSelfMintingDerivatives(
    string calldata selfMintingDerivativeSymbol,
    IERC20 collateral,
    uint8 selfMintingVersion
  ) external view returns (address[] memory);

  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';

interface ISynthereumManager {
  /**
   * @notice Allow to add roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which give the grant
   */
  function grantSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to revoke roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which revoke the grant
   */
  function revokeSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external;

  /**
   * @notice Allow to call emergency shutdown in derivative contracts
   * @param derivatives Derivate contracts to shutdown
   */
  function emergencyShutdown(IDerivative[] calldata derivatives) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Provides signature of function for deployment
 */
interface IDeploymentSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the deployment of a contract in a factory
   * @return signature returns signature of the deployment function
   */
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {IRole} from '../../../base/interfaces/IRole.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumPoolDeployment {
  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of this Synthereum pool
   */
  function version() external view returns (uint8 poolVersion);

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);

  function isDerivativeAdmitted(address derivative)
    external
    view
    returns (bool isAdmitted);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Interface that a derivative MUST have in order to be included in the deployer
 */
interface IDerivativeDeployment {
  /**
   * @notice Gets the collateral currency of the derivative
   * @return collateral Collateral currency
   */
  function collateralCurrency() external view returns (IERC20 collateral);

  /**
   * @notice Get emergency shutdown price
   * @return syntheticCurrency Synthetic token
   */
  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Accessor method for the list of members with admin role
   * @return array of addresses with admin role
   */

  function getAdminMembers() external view returns (address[] memory);

  /**
   * @notice Accessor method for the list of members with pool role
   * @return array of addresses with pool role
   */

  function getPoolMembers() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

interface IExtendedDerivativeDeployment is IDerivativeDeployment {
  /**
   * @notice Add admin to DEFAULT_ADMIN_ROLE
   * @param admin address of the Admin.
   */
  function addAdmin(address admin) external;

  /**
   * @notice Add TokenSponsor to POOL_ROLE
   * @param pool address of the TokenSponsor pool.
   */
  function addPool(address pool) external;

  /**
   * @notice Admin renounce to DEFAULT_ADMIN_ROLE
   */
  function renounceAdmin() external;

  /**
   * @notice TokenSponsor pool renounce to POOL_ROLE
   */
  function renouncePool() external;

  /**
   * @notice Add admin and pool to DEFAULT_ADMIN_ROLE and POOL_ROLE
   * @param adminAndPool address of admin/pool.
   */
  function addAdminAndPool(address adminAndPool) external;

  /**
   * @notice Admin and TokenSponsor pool renounce to DEFAULT_ADMIN_ROLE and POOL_ROLE
   */
  function renounceAdminAndPool() external;

  /**
   * @notice Add derivative as minter of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenMinter(address derivative) external;

  /**
   * @notice Add derivative as burner of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenBurner(address derivative) external;

  /**
   * @notice Add derivative as admin of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenAdmin(address derivative) external;

  /**
   * @notice Add derivative as admin, minter and burner of synthetic token
   * @param derivative address of the derivative
   */
  function addSyntheticTokenAdminAndMinterAndBurner(address derivative)
    external;

  /**
   * @notice This contract renounce to be minter of synthetic token
   */
  function renounceSyntheticTokenMinter() external;

  /**
   * @notice This contract renounce to be burner of synthetic token
   */
  function renounceSyntheticTokenBurner() external;

  /**
   * @notice This contract renounce to be admin of synthetic token
   */
  function renounceSyntheticTokenAdmin() external;

  /**
   * @notice This contract renounce to be admin, minter and burner of synthetic token
   */
  function renounceSyntheticTokenAdminAndMinterAndBurner() external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IERC20
} from '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../../core/interfaces/IFinder.sol';

interface ISelfMintingDerivativeDeployment {
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  function collateralCurrency() external view returns (IERC20 collateral);

  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  function syntheticTokenSymbol() external view returns (string memory symbol);

  function version() external view returns (uint8 selfMintingversion);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Access role interface
 */
interface IRole {
  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

  /**
   * @dev Returns the number of accounts that have `role`. Can be used
   * together with {getRoleMember} to enumerate all bearers of a role.
   */
  function getRoleMemberCount(bytes32 role) external view returns (uint256);

  /**
   * @dev Returns one of the accounts that have `role`. `index` must be a
   * value between 0 and {getRoleMemberCount}, non-inclusive.
   *
   */
  function getRoleMember(bytes32 role, uint256 index)
    external
    view
    returns (address);

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   */
  function getRoleAdmin(bytes32 role) external view returns (bytes32);

  /**
   * @dev Grants `role` to `account`.
   *
   * - the caller must have ``role``'s admin role.
   */
  function grantRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from `account`.
   *
   * - the caller must have ``role``'s admin role.
   */
  function revokeRole(bytes32 role, address account) external;

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * - the caller must be `account`.
   */
  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant SelfMintingController = 'SelfMintingController';
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 */
contract Lockable {
    bool private _notEntered;

    constructor() internal {
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
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a `nonReentrant()` state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every `nonReentrant()` method.
    // On entry into a function, `_preEntranceCheck()` should always be called to check if the function is being re-entered.
    // Then, if the function modifies state, it should call `_postEntranceSet()`, perform its logic, and then call `_postEntranceReset()`.
    // View-only methods can simply call `_preEntranceCheck()` to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivativeMain} from './IDerivativeMain.sol';
import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

interface IDerivative is IDerivativeDeployment, IDerivativeMain {}

