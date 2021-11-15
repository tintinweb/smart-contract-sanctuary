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
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {ISynthereumPoolGeneral} from '../common/interfaces/IPoolGeneral.sol';
import {
  ISynthereumPoolOnChainPriceFeedStorage
} from './interfaces/IPoolOnChainPriceFeedStorage.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {IRole} from '../../base/interfaces/IRole.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumRegistry
} from '../../core/registries/interfaces/IRegistry.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {EnumerableSet} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

/**
 * @notice Pool implementation is stored here to reduce deployment costs
 */

library SynthereumPoolOnChainPriceFeedLib {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolOnChainPriceFeedLib for ISynthereumPoolOnChainPriceFeedStorage.Storage;
  using SynthereumPoolOnChainPriceFeedLib for IDerivative;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeERC20 for IERC20;

  struct ExecuteMintParams {
    // Amount of synth tokens to mint
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) needed for mint
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral minted + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteRedeemParams {
    //Amount of synth tokens needed for redeem
    FixedPoint.Unsigned numTokens;
    // Amount of collateral that user will receive
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redeemed + fees
    FixedPoint.Unsigned totCollateralAmount;
  }

  struct ExecuteExchangeParams {
    // Amount of tokens to send
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) equivalent to synthetic token (exluding fees) to send
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redemeed + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Amount of synthetic token to receive
    FixedPoint.Unsigned destNumTokens;
  }

  //----------------------------------------
  // Events
  //----------------------------------------
  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid,
    address recipient
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);
  // We may omit the pool from event since we can recover it from the address of smart contract emitting event, but for query convenience we include it in the event
  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  // Check that derivative must be whitelisted in this pool
  modifier checkDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) {
    require(self.derivatives.contains(address(derivative)), 'Wrong derivative');
    _;
  }

  //----------------------------------------
  // External function
  //----------------------------------------

  /**
   * @notice Initializes a fresh on chain pool
   * @notice The derivative's collateral currency must be a Collateral Token
   * @notice `_startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param self Data type the library is attached to
   * @param _version Synthereum version of the pool
   * @param _finder Synthereum finder
   * @param _derivative The perpetual derivative
   * @param _startingCollateralization Collateralization ratio to use before a global one is set
   */
  function initialize(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    uint8 _version,
    ISynthereumFinder _finder,
    IDerivative _derivative,
    FixedPoint.Unsigned memory _startingCollateralization
  ) external {
    self.version = _version;
    self.finder = _finder;
    self.startingCollateralization = _startingCollateralization;
    self.collateralToken = getDerivativeCollateral(_derivative);
    self.syntheticToken = _derivative.tokenCurrency();
    self.priceIdentifier = _derivative.priceIdentifier();
    self.derivatives.add(address(_derivative));
    emit AddDerivative(address(this), address(_derivative));
  }

  /**
   * @notice Add a derivate to be linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function addDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.collateralToken == getDerivativeCollateral(derivative),
      'Wrong collateral of the new derivative'
    );
    require(
      self.syntheticToken == derivative.tokenCurrency(),
      'Wrong synthetic token'
    );
    require(
      self.derivatives.add(address(derivative)),
      'Derivative has already been included'
    );
    emit AddDerivative(address(this), address(derivative));
  }

  /**
   * @notice Remove a derivate linked to this pool
   * @param self Data type the library is attached to
   * @param derivative A perpetual derivative
   */
  function removeDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  ) external {
    require(
      self.derivatives.remove(address(derivative)),
      'Derivative not included'
    );
    emit RemoveDerivative(address(this), address(derivative));
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param self Data type the library is attached to
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.MintParams memory mintParams
  ) external returns (uint256 syntheticTokensMinted, uint256 feePaid) {
    FixedPoint.Unsigned memory totCollateralAmount =
      FixedPoint.Unsigned(mintParams.collateralAmount);
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    FixedPoint.Unsigned memory numTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        collateralAmount
      );
    require(
      numTokens.rawValue >= mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );
    checkParams(
      self,
      mintParams.derivative,
      mintParams.feePercentage,
      mintParams.expiration
    );
    self.executeMint(
      mintParams.derivative,
      ExecuteMintParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      ),
      mintParams.recipient
    );
    syntheticTokensMinted = numTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param self Data type the library is attached to
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.RedeemParams memory redeemParams
  ) external returns (uint256 collateralRedeemed, uint256 feePaid) {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemParams.numTokens);
    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );
    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);
    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);
    require(
      collateralAmount.rawValue >= redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );
    checkParams(
      self,
      redeemParams.derivative,
      redeemParams.feePercentage,
      redeemParams.expiration
    );
    self.executeRedeem(
      redeemParams.derivative,
      ExecuteRedeemParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount
      ),
      redeemParams.recipient
    );
    feePaid = feeAmount.rawValue;
    collateralRedeemed = collateralAmount.rawValue;
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolOnChainPriceFeed.ExchangeParams memory exchangeParams
  ) external returns (uint256 destNumTokensMinted, uint256 feePaid) {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeParams.numTokens);

    FixedPoint.Unsigned memory totCollateralAmount =
      calculateCollateralAmount(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        self.priceIdentifier,
        numTokens
      );

    FixedPoint.Unsigned memory feeAmount =
      totCollateralAmount.mul(self.fee.feePercentage);

    FixedPoint.Unsigned memory collateralAmount =
      totCollateralAmount.sub(feeAmount);

    FixedPoint.Unsigned memory destNumTokens =
      calculateNumberOfTokens(
        self.finder,
        IStandardERC20(address(self.collateralToken)),
        exchangeParams.destPool.getPriceFeedIdentifier(),
        collateralAmount
      );

    require(
      destNumTokens.rawValue >= exchangeParams.minDestNumTokens,
      'Number of destination tokens less than minimum limit'
    );
    checkParams(
      self,
      exchangeParams.derivative,
      exchangeParams.feePercentage,
      exchangeParams.expiration
    );

    self.executeExchange(
      exchangeParams.derivative,
      exchangeParams.destPool,
      exchangeParams.destDerivative,
      ExecuteExchangeParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        destNumTokens
      ),
      exchangeParams.recipient
    );

    destNumTokensMinted = destNumTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the deployer
   * @param self Data type the library is attached to
   * @param srcDerivative Derivative used by the source pool
   * @param derivative Derivative that this pool will use
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative srcDerivative,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external {
    self.checkPool(ISynthereumPoolGeneral(msg.sender), srcDerivative);
    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        collateralAmount,
        numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull Collateral Tokens from calling Pool contract
    self.pullCollateral(msg.sender, collateralAmount);

    // Mint new tokens with the collateral
    self.mintSynTokens(
      derivative,
      numTokens.mulCeil(targetCollateralization),
      numTokens
    );

    // Transfer new tokens back to the calling Pool where they will be sent to the user
    self.transferSynTokens(msg.sender, numTokens);
  }

  /**
   * @notice Liquidity provider withdraw collateral from the pool
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to withdraw
   */
  function withdrawFromPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount
  ) external {
    // Transfer the collateral from this pool to the LP sender
    self.collateralToken.safeTransfer(msg.sender, collateralAmount.rawValue);
  }

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.deposit(collateralAmount);
  }

  /**
   * @notice Start a withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param self Data type the library is attached to
   * @param derivative Derivative from which request collateral withdrawal
   * @param collateralAmount The amount of short margin to withdraw
   */
  function slowWithdrawRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  ) external checkDerivative(self, derivative) {
    derivative.requestWithdrawal(collateralAmount);
  }

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param self Data type the library is attached to
   * @param derivative Derivative from which collateral withdrawal was requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdrawPassedRequest();
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param self Data type the library is attached to
   * @param derivative Derivative from which fast withdrawal was requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount
  )
    external
    checkDerivative(self, derivative)
    returns (uint256 amountWithdrawn)
  {
    FixedPoint.Unsigned memory totalAmountWithdrawn =
      derivative.withdraw(collateralAmount);
    amountWithdrawn = liquidateWithdrawal(
      self,
      totalAmountWithdrawn,
      msg.sender
    );
  }

  /**
   * @notice Redeem tokens after derivative emergency shutdown
   * @param self Data type the library is attached to
   * @param derivative Derivative for which settlement is requested
   * @param liquidity_provider_role Lp role
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    bytes32 liquidity_provider_role
  ) external returns (uint256 amountSettled) {
    IERC20 tokenCurrency = self.syntheticToken;

    IERC20 collateralToken = self.collateralToken;

    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(tokenCurrency.balanceOf(msg.sender));

    //Check if sender is a LP
    bool isLiquidityProvider =
      IRole(address(this)).hasRole(liquidity_provider_role, msg.sender);

    // Make sure there is something for the user to settle
    require(
      numTokens.isGreaterThan(0) || isLiquidityProvider,
      'Account has nothing to settle'
    );

    if (numTokens.isGreaterThan(0)) {
      // Move synthetic tokens from the user to the pool
      // - This is because derivative expects the tokens to come from the sponsor address
      tokenCurrency.safeTransferFrom(
        msg.sender,
        address(this),
        numTokens.rawValue
      );

      // Allow the derivative to transfer tokens from the pool
      tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);
    }

    // Redeem the synthetic tokens for collateral
    derivative.settleEmergencyShutdown();

    // Amount of collateral that will be redeemed and sent to the user
    FixedPoint.Unsigned memory totalToRedeem;

    // If the user is the LP, send redeemed token collateral plus excess collateral
    if (isLiquidityProvider) {
      // Redeem LP collateral held in pool
      // Includes excess collateral withdrawn by a user previously calling `settleEmergencyShutdown`
      totalToRedeem = FixedPoint.Unsigned(
        collateralToken.balanceOf(address(this))
      );
    } else {
      // Otherwise, separate excess collateral from redeemed token value
      // Must be called after `emergencyShutdown` to make sure expiryPrice is set
      FixedPoint.Unsigned memory dueCollateral =
        numTokens.mul(derivative.emergencyShutdownPrice());

      totalToRedeem = FixedPoint.min(
        dueCollateral,
        FixedPoint.Unsigned(collateralToken.balanceOf(address(this)))
      );
    }
    amountSettled = totalToRedeem.rawValue;
    // Redeem the collateral for the underlying asset and transfer to the user
    collateralToken.safeTransfer(msg.sender, amountSettled);

    emit Settlement(
      msg.sender,
      address(this),
      numTokens.rawValue,
      amountSettled
    );
  }

  /**
   * @notice Update the fee percentage
   * @param self Data type the library is attached to
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );
    self.fee.feePercentage = _feePercentage;
    emit SetFeePercentage(_feePercentage.rawValue);
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param self Data type the library is attached to
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );
    uint256 totalActualFeeProportions;
    // Store the sum of all proportions
    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }
    self.fee.feeRecipients = _feeRecipients;
    self.fee.feeProportions = _feeProportions;
    self.totalFeeProportions = totalActualFeeProportions;
    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory startingCollateralRatio
  ) external {
    self.startingCollateralization = startingCollateralRatio;
  }

  //----------------------------------------
  //  Internal functions
  //----------------------------------------

  /**
   * @notice Execute mint of synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeMintParams Params for execution of mint (see ExecuteMintParams struct)
   * @param recipient Address to which send synthetic tokens minted
   */
  function executeMint(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteMintParams memory executeMintParams,
    address recipient
  ) internal {
    // Sending amount must be different from 0
    require(
      executeMintParams.collateralAmount.isGreaterThan(0),
      'Sending amount is equal to 0'
    );

    FixedPoint.Unsigned memory globalCollateralization =
      derivative.getGlobalCollateralizationRatio();

    // Target the starting collateralization ratio if there is no global ratio
    FixedPoint.Unsigned memory targetCollateralization =
      globalCollateralization.isGreaterThan(0)
        ? globalCollateralization
        : self.startingCollateralization;

    // Check that LP collateral can support the tokens to be minted
    require(
      self.checkCollateralizationRatio(
        targetCollateralization,
        executeMintParams.collateralAmount,
        executeMintParams.numTokens
      ),
      'Insufficient collateral available from Liquidity Provider'
    );

    // Pull user's collateral and mint fee into the pool
    self.pullCollateral(msg.sender, executeMintParams.totCollateralAmount);

    // Mint synthetic asset with collateral from user and liquidity provider
    self.mintSynTokens(
      derivative,
      executeMintParams.numTokens.mulCeil(targetCollateralization),
      executeMintParams.numTokens
    );

    // Transfer synthetic assets to the user
    self.transferSynTokens(recipient, executeMintParams.numTokens);

    // Send fees
    self.sendFee(executeMintParams.feeAmount);

    emit Mint(
      msg.sender,
      address(this),
      executeMintParams.totCollateralAmount.rawValue,
      executeMintParams.numTokens.rawValue,
      executeMintParams.feeAmount.rawValue,
      recipient
    );
  }

  /**
   * @notice Execute redeem of collateral
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param executeRedeemParams Params for execution of redeem (see ExecuteRedeemParams struct)
   * @param recipient Address to which send collateral tokens redeemed
   */
  function executeRedeem(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ExecuteRedeemParams memory executeRedeemParams,
    address recipient
  ) internal {
    // Sending amount must be different from 0
    require(
      executeRedeemParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeRedeemParams.numTokens
      );
    require(
      amountWithdrawn.isGreaterThan(executeRedeemParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );

    //Send net amount of collateral to the user that submited the redeem request
    self.collateralToken.safeTransfer(
      recipient,
      executeRedeemParams.collateralAmount.rawValue
    );
    // Send fees collected
    self.sendFee(executeRedeemParams.feeAmount);

    emit Redeem(
      msg.sender,
      address(this),
      executeRedeemParams.numTokens.rawValue,
      executeRedeemParams.collateralAmount.rawValue,
      executeRedeemParams.feeAmount.rawValue,
      recipient
    );
  }

  /**
   * @notice Execute exchange between synthetic tokens
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param destPool Pool of synthetic token to receive
   * @param destDerivative Derivative of the pool of synthetic token to receive
   * @param executeExchangeParams Params for execution of exchange (see ExecuteExchangeParams struct)
   * @param recipient Address to which send synthetic tokens exchanged
   */
  function executeExchange(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    ISynthereumPoolGeneral destPool,
    IDerivative destDerivative,
    ExecuteExchangeParams memory executeExchangeParams,
    address recipient
  ) internal {
    // Sending amount must be different from 0
    require(
      executeExchangeParams.numTokens.isGreaterThan(0),
      'Sending amount is equal to 0'
    );
    FixedPoint.Unsigned memory amountWithdrawn =
      redeemForCollateral(
        msg.sender,
        derivative,
        executeExchangeParams.numTokens
      );

    require(
      amountWithdrawn.isGreaterThan(executeExchangeParams.totCollateralAmount),
      'Collateral from derivative less than collateral amount'
    );
    self.checkPool(destPool, destDerivative);

    self.sendFee(executeExchangeParams.feeAmount);

    self.collateralToken.safeApprove(
      address(destPool),
      executeExchangeParams.collateralAmount.rawValue
    );
    // Mint the destination tokens with the withdrawn collateral
    destPool.exchangeMint(
      derivative,
      destDerivative,
      executeExchangeParams.collateralAmount.rawValue,
      executeExchangeParams.destNumTokens.rawValue
    );

    // Transfer the new tokens to the user
    destDerivative.tokenCurrency().safeTransfer(
      recipient,
      executeExchangeParams.destNumTokens.rawValue
    );

    emit Exchange(
      msg.sender,
      address(this),
      address(destPool),
      executeExchangeParams.numTokens.rawValue,
      executeExchangeParams.destNumTokens.rawValue,
      executeExchangeParams.feeAmount.rawValue,
      recipient
    );
  }

  /**
   * @notice Pulls collateral tokens from the sender to store in the Pool
   * @param self Data type the library is attached to
   * @param numTokens The number of tokens to pull
   */
  function pullCollateral(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  /**
   * @notice Mints synthetic tokens with the available collateral
   * @param self Data type the library is attached to
   * @param collateralAmount The amount of collateral to send
   * @param numTokens The number of tokens to mint
   */
  function mintSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeApprove(
      address(derivative),
      collateralAmount.rawValue
    );
    derivative.create(collateralAmount, numTokens);
  }

  /**
   * @notice Transfer synthetic tokens from the derivative to an address
   * @dev Refactored from `mint` to guard against reentrancy
   * @param self Data type the library is attached to
   * @param recipient The address to send the tokens
   * @param numTokens The number of tokens to send
   */
  function transferSynTokens(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    address recipient,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.syntheticToken.safeTransfer(recipient, numTokens.rawValue);
  }

  /**
   * @notice Redeem synthetic tokens for collateral from the derivative
   * @param tokenHolder Address of the user that redeems
   * @param derivative Derivative from which collateral is redeemed
   * @param numTokens The number of tokens to redeem
   * @return amountWithdrawn Collateral amount withdrawn by redeem execution
   */
  function redeemForCollateral(
    address tokenHolder,
    IDerivative derivative,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory amountWithdrawn) {
    IERC20 tokenCurrency = derivative.tokenCurrency();
    require(
      tokenCurrency.balanceOf(tokenHolder) >= numTokens.rawValue,
      'Token balance less than token to redeem'
    );

    // Move synthetic tokens from the user to the Pool
    // - This is because derivative expects the tokens to come from the sponsor address
    tokenCurrency.safeTransferFrom(
      tokenHolder,
      address(this),
      numTokens.rawValue
    );

    // Allow the derivative to transfer tokens from the Pool
    tokenCurrency.safeApprove(address(derivative), numTokens.rawValue);

    // Redeem the synthetic tokens for Collateral tokens
    amountWithdrawn = derivative.redeem(numTokens);
  }

  /**
   * @notice Send collateral withdrawn by the derivative to the LP
   * @param self Data type the library is attached to
   * @param collateralAmount Amount of collateral to send to the LP
   * @param recipient Address of a LP
   * @return amountWithdrawn Collateral amount withdrawn
   */
  function liquidateWithdrawal(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory collateralAmount,
    address recipient
  ) internal returns (uint256 amountWithdrawn) {
    amountWithdrawn = collateralAmount.rawValue;
    self.collateralToken.safeTransfer(recipient, amountWithdrawn);
  }

  /**
   * @notice Set the Pool fee structure parameters
   * @param self Data type the library is attached tfo
   * @param _feeAmount Amount of fee to send
   */
  function sendFee(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory _feeAmount
  ) internal {
    // Distribute fees
    // TODO Consider using the withdrawal pattern for fees
    for (uint256 i = 0; i < self.fee.feeRecipients.length; i++) {
      self.collateralToken.safeTransfer(
        self.fee.feeRecipients[i],
        // This order is important because it mixes FixedPoint with unscaled uint
        _feeAmount
          .mul(self.fee.feeProportions[i])
          .div(self.totalFeeProportions)
          .rawValue
      );
    }
  }

  //----------------------------------------
  //  Internal views functions
  //----------------------------------------

  /**
   * @notice Check fee percentage and expiration of mint, redeem and exchange transaction
   * @param self Data type the library is attached tfo
   * @param derivative Derivative to use
   * @param feePercentage Maximum percentage of fee that a user want to pay
   * @param expiration Expiration time of the transaction
   */
  function checkParams(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    IDerivative derivative,
    uint256 feePercentage,
    uint256 expiration
  ) internal view checkDerivative(self, derivative) {
    require(now <= expiration, 'Transaction expired');
    require(
      self.fee.feePercentage.rawValue <= feePercentage,
      'User fee percentage less than actual one'
    );
  }

  /**
   * @notice Get the address of collateral of a perpetual derivative
   * @param derivative Address of the perpetual derivative
   * @return collateral Address of the collateral of perpetual derivative
   */
  function getDerivativeCollateral(IDerivative derivative)
    internal
    view
    returns (IERC20 collateral)
  {
    collateral = derivative.collateralCurrency();
  }

  /**
   * @notice Get the global collateralization ratio of the derivative
   * @param derivative Perpetual derivative contract
   * @return The global collateralization ratio
   */
  function getGlobalCollateralizationRatio(IDerivative derivative)
    internal
    view
    returns (FixedPoint.Unsigned memory)
  {
    FixedPoint.Unsigned memory totalTokensOutstanding =
      derivative.totalTokensOutstanding();
    if (totalTokensOutstanding.isGreaterThan(0)) {
      return derivative.totalPositionCollateral().div(totalTokensOutstanding);
    } else {
      return FixedPoint.fromUnscaledUint(0);
    }
  }

  /**
   * @notice Check if a call to `mint` with the supplied parameters will succeed
   * @dev Compares the new collateral from `collateralAmount` combined with LP collateral
   *      against the collateralization ratio of the derivative.
   * @param self Data type the library is attached to
   * @param globalCollateralization The global collateralization ratio of the derivative
   * @param collateralAmount The amount of additional collateral supplied
   * @param numTokens The number of tokens to mint
   * @return `true` if there is sufficient collateral
   */
  function checkCollateralizationRatio(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    FixedPoint.Unsigned memory globalCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (bool) {
    // Collateral ratio possible for new tokens accounting for LP collateral
    FixedPoint.Unsigned memory newCollateralization =
      collateralAmount
        .add(FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this))))
        .div(numTokens);

    // Check that LP collateral can support the tokens to be minted
    return newCollateralization.isGreaterThanOrEqual(globalCollateralization);
  }

  /**
   * @notice Check if sender or receiver pool is a correct registered pool
   * @param self Data type the library is attached to
   * @param poolToCheck Pool that should be compared with this pool
   * @param derivativeToCheck Derivative of poolToCheck
   */
  function checkPool(
    ISynthereumPoolOnChainPriceFeedStorage.Storage storage self,
    ISynthereumPoolGeneral poolToCheck,
    IDerivative derivativeToCheck
  ) internal view {
    require(
      poolToCheck.isDerivativeAdmitted(address(derivativeToCheck)),
      'Wrong derivative'
    );
    IERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );
    ISynthereumFinder finder = self.finder;
    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');
    ISynthereumRegistry poolRegister =
      ISynthereumRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );
    require(
      poolRegister.isDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registred'
    );
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory numTokens
  ) internal view returns (FixedPoint.Unsigned memory collateralAmount) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    collateralAmount = numTokens.mul(priceRate).div(
      10**((uint256(18)).sub(decimalsOfCollateral))
    );
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral, using on-chain oracle
   * @param finder Synthereum finder
   * @param collateralToken Collateral token contract
   * @param priceIdentifier Identifier of price pair
   * @param numTokens Amount of collateral from which you want to calculate synthetic token amount
   * @return numTokens Amount of tokens after on-chain oracle conversion
   */
  function calculateNumberOfTokens(
    ISynthereumFinder finder,
    IStandardERC20 collateralToken,
    bytes32 priceIdentifier,
    FixedPoint.Unsigned memory collateralAmount
  ) internal view returns (FixedPoint.Unsigned memory numTokens) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(finder, priceIdentifier);
    uint256 decimalsOfCollateral = getCollateralDecimals(collateralToken);
    numTokens = collateralAmount
      .mul(10**((uint256(18)).sub(decimalsOfCollateral)))
      .div(priceRate);
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @param finder Synthereum finder
   * @param priceIdentifier Identifier of price pair
   * @return priceRate Latest rate of the pair
   */
  function getPriceFeedRate(ISynthereumFinder finder, bytes32 priceIdentifier)
    internal
    view
    returns (FixedPoint.Unsigned memory priceRate)
  {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
    priceRate = FixedPoint.Unsigned(priceFeed.getLatestPrice(priceIdentifier));
  }

  /**
   * @notice Retrun the number of decimals of collateral token
   * @param collateralToken Collateral token contract
   * @return decimals number of decimals
   */
  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint256 decimals)
  {
    decimals = collateralToken.decimals();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumDeployer} from '../../../core/interfaces/IDeployer.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolDeployment
} from '../../common/interfaces/IPoolDeployment.sol';
import {ISynthereumPoolGeneral} from '../../common/interfaces/IPoolGeneral.sol';

/**
 * @title Token Issuer Contract Interface
 */
interface ISynthereumPoolOnChainPriceFeed is ISynthereumPoolDeployment {
  // Describe fee structure
  struct Fee {
    // Fees charged when a user mints, redeem and exchanges tokens
    FixedPoint.Unsigned feePercentage;
    address[] feeRecipients;
    uint32[] feeProportions;
  }

  // Describe role structure
  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
  }

  struct MintParams {
    // Derivative to use
    IDerivative derivative;
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct RedeemParams {
    // Derivative to use
    IDerivative derivative;
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send collateral tokens redeemed
    address recipient;
  }

  struct ExchangeParams {
    // Derivative of source pool
    IDerivative derivative;
    // Destination pool
    ISynthereumPoolGeneral destPool;
    // Derivative of destination pool
    IDerivative destDerivative;
    // Amount of source synthetic tokens that user wants to use for exchanging
    uint256 numTokens;
    // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
    uint256 minDestNumTokens;
    // Maximum amount of fees in percentage that user is willing to pay
    uint256 feePercentage;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens exchanged
    address recipient;
  }

  /**
   * @notice Add a derivate to be controlled by this pool
   * @param derivative A perpetual derivative
   */
  function addDerivative(IDerivative derivative) external;

  /**
   * @notice Remove a derivative controlled by this pool
   * @param derivative A perpetual derivative
   */
  function removeDerivative(IDerivative derivative) external;

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(MintParams memory mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams memory redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams memory exchangeParams)
    external
    returns (uint256 destNumTokensMinted, uint256 feePaid);

  /**
   * @notice Called by a source TIC's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source TIC
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  /**
   * @notice Liquidity provider withdraw margin from the pool
   * @param collateralAmount The amount of margin to withdraw
   */
  function withdrawFromPool(uint256 collateralAmount) external;

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external;

  /**
   * @notice Start a slow withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param derivative Derivative from which collateral withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   */
  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external;

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param derivative Derivative from which collateral withdrawal is requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param derivative Derivative from which fast withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    returns (uint256 amountWithdrawn);

  /**
   * @notice Redeem tokens after contract emergency shutdown
   * @param derivative Derivative for which settlement is requested
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(IDerivative derivative)
    external
    returns (uint256 amountSettled);

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @param _fee Fee struct containing percentage, recipients and proportions
   */
  function setFee(Fee memory _fee) external;

  /**
   * @notice Update the fee percentage
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage) external;

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] memory _feeRecipients,
    uint32[] memory _feeProportions
  ) external;

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(uint256 startingCollateralRatio)
    external;

  /**
   * @notice Get all the derivatives associated to this pool
   * @return Return list of all derivatives
   */
  function getAllDerivatives() external view returns (IDerivative[] memory);

  /**
   * @notice Get the starting collateral ratio of the pool
   * @return startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function getStartingCollateralization()
    external
    view
    returns (uint256 startingCollateralRatio);

  /**
   * @notice Returns infos about fee set
   * @return fee Percentage and recipients of fee
   */
  function getFeeInfo() external view returns (Fee memory fee);

  /**
   * @notice Calculate the fees a user will have to pay to mint tokens with their collateral
   * @param collateralAmount Amount of collateral on which fees are calculated
   * @return fee Amount of fee that must be paid by the user
   */
  function calculateFee(uint256 collateralAmount)
    external
    view
    returns (uint256 fee);

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {ISynthereumPoolInteraction} from './IPoolInteraction.sol';
import {ISynthereumPoolDeployment} from './IPoolDeployment.sol';

interface ISynthereumPoolGeneral is
  ISynthereumPoolDeployment,
  ISynthereumPoolInteraction
{}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumPoolOnChainPriceFeed} from './IPoolOnChainPriceFeed.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {EnumerableSet} from '../../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumPoolOnChainPriceFeedStorage {
  struct Storage {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum version
    uint8 version;
    // Collateral token
    IERC20 collateralToken;
    // Synthetic token
    IERC20 syntheticToken;
    // Derivatives supported
    EnumerableSet.AddressSet derivatives;
    // Starting collateralization ratio
    FixedPoint.Unsigned startingCollateralization;
    // Fees
    ISynthereumPoolOnChainPriceFeed.Fee fee;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
    // Price identifier
    bytes32 priceIdentifier;
  }
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
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IDerivativeMain} from './IDerivativeMain.sol';
import {IDerivativeDeployment} from './IDerivativeDeployment.sol';

/**
 * @title Interface that a derivative MUST have in order to be used in the pools
 */
interface IDerivative is IDerivativeDeployment, IDerivativeMain {

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
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumRegistry
 */

interface ISynthereumRegistry {
  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken
   * @param collateralToken Collateral ERC20 token of the element deployed
   * @param version Version of the element deployed
   * @param element Address of the element deployed
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view returns (bool isElementDeployed);

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens() external view returns (string[] memory);

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view returns (uint8[] memory);

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 priceIdentifier)
    external
    view
    returns (uint256 price);
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

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant DerivativeFactory = 'DerivativeFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
import {EnumerableSet} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';

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
   * @notice Deploys a pool and links it with an already existing derivative
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
   * @notice Deploys a derivative and option to links it with an already existing pool
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

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
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
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  FixedPoint
} from '../../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerParty} from '../FeePayerParty.sol';

/**
 * @title Interface for interacting with the Derivatives contracts
 */
interface IDerivativeMain {
  /** @notice Deposit funds to a certain derivative contract with specified sponsor
   * @param sponsor Address of the sponsor to which the funds will be deposited
   * @param collateralAmount Amount of funds to be deposited
   */
  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  ) external;

  /** @notice Deposit funds to the derivative contract where msg sender is the sponsor
   * @param collateralAmount Amount of funds to be deposited
   */
  function deposit(FixedPoint.Unsigned memory collateralAmount) external;

  /** @notice Fast withdraw excess collateral from a derivative contract
   * @param collateralAmount Amount of funds to be withdrawn
   */
  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Request of slow withdraw of collateral from derivative changing GCR
   * @param collateralAmount Amount of funds to be withdrawn
   */
  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external;

  /** @notice Execute withdraw if a slow withdraw request has passed
   */
  function withdrawPassedRequest()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Cancel a slow withdraw request
   */
  function cancelWithdrawal() external;

  /** @notice Mint synthetic tokens
   * @param collateralAmount Amount of collateral to be locked
   * @param numTokens Amount of tokens to be minted based on collateralAmount
   */
  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external;

  /** @notice Redeem collateral by burning synthetic tokens
   * @param numTokens Amount of synthetic tokens to be burned to unlock collateral
   */
  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Burning an amount of synthetic tokens to increase GCR
   * @param numTokens Amount of synthetic tokens to be burned
   */
  function repay(FixedPoint.Unsigned memory numTokens) external;

  /** @notice Settles the withdraws from an emergency shutdown of a derivative
   */
  function settleEmergencyShutdown()
    external
    returns (FixedPoint.Unsigned memory amountWithdrawn);

  /** @notice Invokes an emergency shutdown of a derivative
   */
  function emergencyShutdown() external;

  /** @notice Remargin function
   */
  function remargin() external;

  /** @notice Allows withdrawing of excess ERC20 tokens
   * @param token The address of the ERC20 token
   */
  function trimExcess(IERC20 token)
    external
    returns (FixedPoint.Unsigned memory amount);

  /** @notice Gets the collateral locked by a certain sponsor
   * @param sponsor The address of the sponsor for which to return amount of collateral locked
   */
  function getCollateral(address sponsor)
    external
    view
    returns (FixedPoint.Unsigned memory collateralAmount);

  /** @notice Gets the address of the SynthereumFinder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /** @notice Gets the synthetic token symbol associated with the derivative
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);

  /** @notice Gets the price identifier associated with the derivative
   */
  function priceIdentifier() external view returns (bytes32 identifier);

  /** @notice Gets the total collateral locked in a derivative
   */
  function totalPositionCollateral()
    external
    view
    returns (FixedPoint.Unsigned memory totalCollateral);

  /** @notice Gets the total synthetic tokens minted through a derivative
   */
  function totalTokensOutstanding()
    external
    view
    returns (FixedPoint.Unsigned memory totalTokens);

  /** @notice Gets the price at which the emergency shutdown was performed
   */
  function emergencyShutdownPrice()
    external
    view
    returns (FixedPoint.Unsigned memory emergencyPrice);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
   * @notice Get the token currency of the derivative
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
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  AdministrateeInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/AdministrateeInterface.sol';
import {
  StoreInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/StoreInterface.sol';
import {
  FinderInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/FinderInterface.sol';
import {
  OracleInterfaces
} from '../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerPartyLib} from './FeePayerPartyLib.sol';
import {
  Testable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Testable.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

/**
 * @title FeePayer contract.
 * @notice Provides fee payment functionality for the PerpetualParty contracts.
 * contract is abstract as each derived contract that inherits `FeePayer` must implement `pfc()`.
 */
abstract contract FeePayerParty is AdministrateeInterface, Testable, Lockable {
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using FeePayerPartyLib for FeePayerData;
  using SafeERC20 for IERC20;

  struct FeePayerData {
    // The collateral currency used to back the positions in this contract.
    IERC20 collateralCurrency;
    // Finder contract used to look up addresses for UMA system contracts.
    FinderInterface finder;
    // Tracks the last block time when the fees were paid.
    uint256 lastPaymentTime;
    // Tracks the cumulative fees that have been paid by the contract for use by derived contracts.
    // The multiplier starts at 1, and is updated by computing cumulativeFeeMultiplier * (1 - effectiveFee).
    // Put another way, the cumulativeFeeMultiplier is (1 - effectiveFee1) * (1 - effectiveFee2) ...
    // For example:
    // The cumulativeFeeMultiplier should start at 1.
    // If a 1% fee is charged, the multiplier should update to .99.
    // If another 1% fee is charged, the multiplier should be 0.99^2 (0.9801).
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  FeePayerData public feePayerData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  // modifier that calls payRegularFees().
  modifier fees {
    // Note: the regular fee is applied on every fee-accruing transaction, where the total change is simply the
    // regular fee applied linearly since the last update. This implies that the compounding rate depends on the
    // frequency of update transactions that have this modifier, and it never reaches the ideal of continuous
    // compounding. This approximate-compounding pattern is common in the Ethereum ecosystem because of the
    // complexity of compounding data on-chain.
    payRegularFees();
    _;
  }
  modifier onlyThisContract {
    require(msg.sender == address(this), 'Caller is not this contract');
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs FeePayerParty contract. Called by child contracts
   * @param _collateralAddress ERC20 token that is used as the underlying collateral for the synthetic.
   * @param _finderAddress UMA protocol Finder used to discover other protocol contracts.
   * @param _timerAddress Contract that stores the current time in a testing environment.
   * Must be set to 0x0 for production environments that use live time.
   */
  constructor(
    address _collateralAddress,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    feePayerData.collateralCurrency = IERC20(_collateralAddress);
    feePayerData.finder = FinderInterface(_finderAddress);
    feePayerData.lastPaymentTime = getCurrentTime();
    feePayerData.cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
   * @param payer The address that pays the fees
   * @param amount Amount of fees to be paid
   */
  function payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    external
    onlyThisContract
  {
    _payFinalFees(payer, amount);
  }

  /**
   * @notice Gets the collateral currency of the derivative
   * @return Collateral currency
   */
  function collateralCurrency()
    public
    view
    virtual
    nonReentrantView()
    returns (IERC20)
  {
    return feePayerData.collateralCurrency;
  }

  /**
   * @notice Pays UMA DVM regular fees (as a % of the collateral pool) to the Store contract.
   * @dev These must be paid periodically for the life of the contract. If the contract has not paid its regular fee
   * in a week or more then a late penalty is applied which is sent to the caller. If the amount of
   * fees owed are greater than the pfc, then this will pay as much as possible from the available collateral.
   * An event is only fired if the fees charged are greater than 0.
   * @return totalPaid Amount of collateral that the contract paid (sum of the amount paid to the Store and caller).
   * This returns 0 and exit early if there is no pfc, fees were already paid during the current block, or the fee rate is 0.
   */
  function payRegularFees()
    public
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    StoreInterface store = _getStore();
    uint256 time = getCurrentTime();
    FixedPoint.Unsigned memory collateralPool = _pfc();
    totalPaid = feePayerData.payRegularFees(store, time, collateralPool);
    return totalPaid;
  }

  /**
   * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
   * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
   * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
   * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
   */
  function pfc()
    public
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return _pfc();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
  // charged for each price request. If payer is the contract, adjusts internal bookkeeping variables. If payer is not
  // the contract, pulls in `amount` of collateral currency.
  function _payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    internal
  {
    StoreInterface store = _getStore();
    feePayerData.payFinalFees(store, payer, amount);
  }

  function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

  // Get Store Contract to which fees will be paid
  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Store)
      );
  }

  // Calculate final fees to be paid
  function _computeFinalFees()
    internal
    view
    returns (FixedPoint.Unsigned memory finalFees)
  {
    StoreInterface store = _getStore();
    return store.computeFinalFee(address(feePayerData.collateralCurrency));
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that all financial contracts expose to the admin.
 */
interface AdministrateeInterface {
    /**
     * @notice Initiates the shutdown process, in case of an emergency.
     */
    function emergencyShutdown() external;

    /**
     * @notice A core contract method called independently or as a part of other financial contract transactions.
     * @dev It pays fees and moves money between margin accounts to make sure they reflect the NAV of the contract.
     */
    function remargin() external;

    /**
     * @notice Gets the current profit from corruption for this contract in terms of the collateral currency.
     * @dev This is equivalent to the collateral pool available from which to pay fees. Therefore, derived contracts are
     * expected to implement this so that pay-fee methods can correctly compute the owed fees as a % of PfC.
     * @return pfc value for equal to the current profit from corruption denominated in collateral currency.
     */
    function pfc() external view returns (FixedPoint.Unsigned memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/implementation/FixedPoint.sol";

/**
 * @title Interface that allows financial contracts to pay oracle fees for their use of the system.
 */
interface StoreInterface {
    /**
     * @notice Pays Oracle fees in ETH to the store.
     * @dev To be used by contracts whose margin currency is ETH.
     */
    function payOracleFees() external payable;

    /**
     * @notice Pays oracle fees in the margin currency, erc20Address, to the store.
     * @dev To be used if the margin currency is an ERC20 token rather than ETH.
     * @param erc20Address address of the ERC20 token used to pay the fee.
     * @param amount number of tokens to transfer. An approval for at least this amount must exist.
     */
    function payOracleFeesErc20(address erc20Address, FixedPoint.Unsigned calldata amount) external;

    /**
     * @notice Computes the regular oracle fees that a contract should pay for a period.
     * @param startTime defines the beginning time from which the fee is paid.
     * @param endTime end time until which the fee is paid.
     * @param pfc "profit from corruption", or the maximum amount of margin currency that a
     * token sponsor could extract from the contract through corrupting the price feed in their favor.
     * @return regularFee amount owed for the duration from start to end time for the given pfc.
     * @return latePenalty for paying the fee after the deadline.
     */
    function computeRegularFee(
        uint256 startTime,
        uint256 endTime,
        FixedPoint.Unsigned calldata pfc
    ) external view returns (FixedPoint.Unsigned memory regularFee, FixedPoint.Unsigned memory latePenalty);

    /**
     * @notice Computes the final oracle fees that a contract should pay at settlement.
     * @param currency token used to pay the final fee.
     * @return finalFee amount due.
     */
    function computeFinalFee(address currency) external view returns (FixedPoint.Unsigned memory);
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
pragma solidity ^0.6.0;

/**
 * @title Stores common interface names used throughout the DVM by registration in the Finder.
 */
library OracleInterfaces {
    bytes32 public constant Oracle = "Oracle";
    bytes32 public constant IdentifierWhitelist = "IdentifierWhitelist";
    bytes32 public constant Store = "Store";
    bytes32 public constant FinancialContractsAdmin = "FinancialContractsAdmin";
    bytes32 public constant Registry = "Registry";
    bytes32 public constant CollateralWhitelist = "CollateralWhitelist";
    bytes32 public constant OptimisticOracle = "OptimisticOracle";
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  StoreInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/StoreInterface.sol';
import {SafeERC20} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {FeePayerParty} from './FeePayerParty.sol';

/** @notice - A library to support FeePayerParty contract
 */
library FeePayerPartyLib {
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPartyLib for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;

  //----------------------------------------
  // Events
  //----------------------------------------

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  //----------------------------------------
  // External functions
  //----------------------------------------

  // Pays UMA DVM regular fees (as a % of the collateral pool) to the Store contract.
  // These must be paid periodically for the life of the contract. If the contract has not paid its regular fee
  // in a week or more then a late penalty is applied which is sent to the caller. If the amount of
  // fees owed are greater than the pfc, then this will pay as much as possible from the available collateral.
  // An event is only fired if the fees charged are greater than 0.
  function payRegularFees(
    FeePayerParty.FeePayerData storage feePayerData,
    StoreInterface store,
    uint256 time,
    FixedPoint.Unsigned memory collateralPool
  ) external returns (FixedPoint.Unsigned memory totalPaid) {
    // Exit early if there is no collateral from which to pay fees.
    if (collateralPool.isEqual(0)) {
      // Note: set the lastPaymentTime in this case so the contract is credited for paying during periods when it
      // has no locked collateral.
      feePayerData.lastPaymentTime = time;
      return totalPaid;
    }

    // Exit early if fees were already paid during this block.
    if (feePayerData.lastPaymentTime == time) {
      return totalPaid;
    }

    FixedPoint.Unsigned memory regularFee;
    FixedPoint.Unsigned memory latePenalty;

    (regularFee, latePenalty) = store.computeRegularFee(
      feePayerData.lastPaymentTime,
      time,
      collateralPool
    );
    feePayerData.lastPaymentTime = time;

    totalPaid = regularFee.add(latePenalty);
    if (totalPaid.isEqual(0)) {
      return totalPaid;
    }

    // If the effective fees paid as a % of the pfc is > 100%, then we need to reduce it and make the contract pay
    // as much of the fee that it can (up to 100% of its pfc). We'll reduce the late penalty first and then the
    // regular fee, which has the effect of paying the store first, followed by the caller if there is any fee remaining.
    if (totalPaid.isGreaterThan(collateralPool)) {
      FixedPoint.Unsigned memory deficit = totalPaid.sub(collateralPool);
      FixedPoint.Unsigned memory latePenaltyReduction =
        FixedPoint.min(latePenalty, deficit);
      latePenalty = latePenalty.sub(latePenaltyReduction);
      deficit = deficit.sub(latePenaltyReduction);
      regularFee = regularFee.sub(FixedPoint.min(regularFee, deficit));
      totalPaid = collateralPool;
    }

    emit RegularFeesPaid(regularFee.rawValue, latePenalty.rawValue);

    feePayerData.cumulativeFeeMultiplier._adjustCumulativeFeeMultiplier(
      totalPaid,
      collateralPool
    );

    if (regularFee.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeIncreaseAllowance(
        address(store),
        regularFee.rawValue
      );
      store.payOracleFeesErc20(
        address(feePayerData.collateralCurrency),
        regularFee
      );
    }

    if (latePenalty.isGreaterThan(0)) {
      feePayerData.collateralCurrency.safeTransfer(
        msg.sender,
        latePenalty.rawValue
      );
    }
    return totalPaid;
  }

  // Pays UMA Oracle final fees of `amount` in `collateralCurrency` to the Store contract. Final fee is a flat fee
  // charged for each price request. If payer is the contract, adjusts internal bookkeeping variables. If payer is not
  // the contract, pulls in `amount` of collateral currency.
  function payFinalFees(
    FeePayerParty.FeePayerData storage feePayerData,
    StoreInterface store,
    address payer,
    FixedPoint.Unsigned memory amount
  ) external {
    if (amount.isEqual(0)) {
      return;
    }

    // Pull the collateral from the payer.
    feePayerData.collateralCurrency.safeTransferFrom(
      payer,
      address(this),
      amount.rawValue
    );

    emit FinalFeesPaid(amount.rawValue);

    feePayerData.collateralCurrency.safeIncreaseAllowance(
      address(store),
      amount.rawValue
    );
    store.payOracleFeesErc20(address(feePayerData.collateralCurrency), amount);
  }

  //Call to the internal one (see _getFeeAdjustedCollateral)
  function getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
  }

  // Decrease rawCollateral by a fee-adjusted collateralToRemove amount. Fee adjustment scales up collateralToRemove
  // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
  // rawCollateral is decreased by less than expected. Because this method is usually called in conjunction with an
  // actual removal of collateral from this contract, return the fee-adjusted amount that the rawCollateral is
  // decreased by so that the caller can minimize error between collateral removed and rawCollateral debited.
  function removeCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToRemove,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory removedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToRemove._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.sub(adjustedCollateral).rawValue;
    removedCollateral = initialBalance.sub(
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
    );
  }

  // Increase rawCollateral by a fee-adjusted collateralToAdd amount. Fee adjustment scales up collateralToAdd
  // by dividing it by cumulativeFeeMultiplier. There is potential for this quotient to be floored, therefore
  // rawCollateral is increased by less than expected. Because this method is usually called in conjunction with an
  // actual addition of collateral to this contract, return the fee-adjusted amount that the rawCollateral is
  // increased by so that the caller can minimize error between collateral added and rawCollateral credited.
  // NOTE: This return value exists only for the sake of symmetry with _removeCollateral. We don't actually use it
  // because we are OK if more collateral is stored in the contract than is represented by rawTotalPositionCollateral.
  function addCollateral(
    FixedPoint.Unsigned storage rawCollateral,
    FixedPoint.Unsigned memory collateralToAdd,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external returns (FixedPoint.Unsigned memory addedCollateral) {
    FixedPoint.Unsigned memory initialBalance =
      rawCollateral._getFeeAdjustedCollateral(cumulativeFeeMultiplier);
    FixedPoint.Unsigned memory adjustedCollateral =
      collateralToAdd._convertToRawCollateral(cumulativeFeeMultiplier);
    rawCollateral.rawValue = rawCollateral.add(adjustedCollateral).rawValue;
    addedCollateral = rawCollateral
      ._getFeeAdjustedCollateral(cumulativeFeeMultiplier)
      .sub(initialBalance);
  }

  //Call to the internal one (see _convertToRawCollateral)
  function convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) external pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral._convertToRawCollateral(cumulativeFeeMultiplier);
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  // Scale the cumulativeFeeMultiplier by the ratio of fees paid to the current available collateral.
  function _adjustCumulativeFeeMultiplier(
    FixedPoint.Unsigned storage cumulativeFeeMultiplier,
    FixedPoint.Unsigned memory amount,
    FixedPoint.Unsigned memory currentPfc
  ) internal {
    FixedPoint.Unsigned memory effectiveFee = amount.divCeil(currentPfc);
    cumulativeFeeMultiplier.rawValue = cumulativeFeeMultiplier
      .mul(FixedPoint.fromUnscaledUint(1).sub(effectiveFee))
      .rawValue;
  }

  // Returns the user's collateral minus any fees that have been subtracted since it was originally
  // deposited into the contract. Note: if the contract has paid fees since it was deployed, the raw
  // value should be larger than the returned value.
  function _getFeeAdjustedCollateral(
    FixedPoint.Unsigned memory rawCollateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory collateral) {
    return rawCollateral.mul(cumulativeFeeMultiplier);
  }

  // Converts a user-readable collateral value into a raw value that accounts for already-assessed fees. If any fees
  // have been taken from this contract in the past, then the raw value will be larger than the user-readable value.
  function _convertToRawCollateral(
    FixedPoint.Unsigned memory collateral,
    FixedPoint.Unsigned memory cumulativeFeeMultiplier
  ) internal pure returns (FixedPoint.Unsigned memory rawCollateral) {
    return collateral.div(cumulativeFeeMultiplier);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./Timer.sol";

/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) internal {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    function setCurrentTime(uint256 time) external onlyIfTest {
        Timer(timerAddress).setCurrentTime(time);
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return now; // solhint-disable-line not-rely-on-time
        }
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer {
    uint256 private currentTime;

    constructor() public {
        currentTime = now; // solhint-disable-line not-rely-on-time
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external {
        currentTime = time;
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        return currentTime;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {IERC20} from '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../../../core/interfaces/IFinder.sol';

/** @title Interface for interacting with SelfMintingDerivativeDeployment contract
 */
interface ISelfMintingDerivativeDeployment {
  /** @notice Returns the address of the SynthereumFinder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /** @notice Returns the address of the collateralCurrency contract
   */
  function collateralCurrency() external view returns (IERC20 collateral);

  /** @notice Returns the address of the synthetic token contract
   */
  function tokenCurrency() external view returns (IERC20 syntheticCurrency);

  /** @notice Returns the synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);

  /** @notice Returns the version of the deployed self-minting derivative
   */
  function version() external view returns (uint8 selfMintingversion);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import {
  IDerivative
} from '../../../derivative/common/interfaces/IDerivative.sol';

interface ISynthereumPoolInteraction {
  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external;

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {
  ISynthereumPoolOnChainPriceFeedStorage
} from './interfaces/IPoolOnChainPriceFeedStorage.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {ISynthereumDeployer} from '../../core/interfaces/IDeployer.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {Strings} from '../../../@openzeppelin/contracts/utils/Strings.sol';
import {EnumerableSet} from '../../../@openzeppelin/contracts/utils/EnumerableSet.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {SynthereumPoolOnChainPriceFeedLib} from './PoolOnChainPriceFeedLib.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';
import {AccessControl} from '../../../@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title Token Issuer Contract
 * @notice Collects collateral and issues synthetic assets
 */
contract SynthereumPoolOnChainPriceFeed is
  AccessControl,
  ISynthereumPoolOnChainPriceFeedStorage,
  ISynthereumPoolOnChainPriceFeed,
  Lockable
{
  using FixedPoint for FixedPoint.Unsigned;
  using SynthereumPoolOnChainPriceFeedLib for Storage;

  //----------------------------------------
  // Constants
  //----------------------------------------

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  //----------------------------------------
  // Storage
  //----------------------------------------

  Storage private poolStorage;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Mint(
    address indexed account,
    address indexed pool,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Redeem(
    address indexed account,
    address indexed pool,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid,
    address recipient
  );

  event Exchange(
    address indexed account,
    address indexed sourcePool,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Settlement(
    address indexed account,
    address indexed pool,
    uint256 numTokens,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);
  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);
  // We may omit the pool from event since we can recover it from the address of smart contract emitting event, but for query convenience we include it in the event
  event AddDerivative(address indexed pool, address indexed derivative);
  event RemoveDerivative(address indexed pool, address indexed derivative);

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

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender),
      'Sender must be the liquidity provider'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `_startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param _derivative The perpetual derivative
   * @param _finder The Synthereum finder
   * @param _version Synthereum version
   * @param _roles The addresses of admin, maintainer, liquidity provider and validator
   * @param _startingCollateralization Collateralization ratio to use before a global one is set
   * @param _fee The fee structure
   */
  constructor(
    IDerivative _derivative,
    ISynthereumFinder _finder,
    uint8 _version,
    Roles memory _roles,
    uint256 _startingCollateralization,
    Fee memory _fee
  ) public nonReentrant {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, _roles.liquidityProvider);
    poolStorage.initialize(
      _version,
      _finder,
      _derivative,
      FixedPoint.Unsigned(_startingCollateralization)
    );
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------
  /**
   * @notice Add a derivate to be controlled by this pool
   * @param derivative A perpetual derivative
   */
  function addDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.addDerivative(derivative);
  }

  /**
   * @notice Remove a derivative controlled by this pool
   * @param derivative A perpetual derivative
   */
  function removeDerivative(IDerivative derivative)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.removeDerivative(derivative);
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the minter as fee
   */
  function mint(MintParams memory mintParams)
    external
    override
    nonReentrant
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    (syntheticTokensMinted, feePaid) = poolStorage.mint(mintParams);
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams memory redeemParams)
    external
    override
    nonReentrant
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    (collateralRedeemed, feePaid) = poolStorage.redeem(redeemParams);
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams memory exchangeParams)
    external
    override
    nonReentrant
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    (destNumTokensMinted, feePaid) = poolStorage.exchange(exchangeParams);
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registred in the PoolRegister contract
   * @param srcDerivative Derivative used by the source pool
   * @param derivative The derivative of the destination pool to use for mint
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   */
  function exchangeMint(
    IDerivative srcDerivative,
    IDerivative derivative,
    uint256 collateralAmount,
    uint256 numTokens
  ) external override nonReentrant {
    poolStorage.exchangeMint(
      srcDerivative,
      derivative,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens)
    );
  }

  /**
   * @notice Liquidity provider withdraw collateral from the pool
   * @param collateralAmount The amount of collateral to withdraw
   */
  function withdrawFromPool(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.withdrawFromPool(FixedPoint.Unsigned(collateralAmount));
  }

  /**
   * @notice Move collateral from Pool to its derivative in order to increase GCR
   * @param derivative Derivative on which to deposit collateral
   * @param collateralAmount The amount of collateral to move into derivative
   */
  function depositIntoDerivative(
    IDerivative derivative,
    uint256 collateralAmount
  ) external override onlyLiquidityProvider nonReentrant {
    poolStorage.depositIntoDerivative(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Start a slow withdrawal request
   * @notice Collateral can be withdrawn once the liveness period has elapsed
   * @param derivative Derivative from which the collateral withdrawal is requested
   * @param collateralAmount The amount of excess collateral to withdraw
   */
  function slowWithdrawRequest(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
  {
    poolStorage.slowWithdrawRequest(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Withdraw collateral after a withdraw request has passed it's liveness period
   * @param derivative Derivative from which collateral withdrawal was requested
   * @return amountWithdrawn Amount of collateral withdrawn by slow withdrawal
   */
  function slowWithdrawPassedRequest(IDerivative derivative)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.slowWithdrawPassedRequest(derivative);
  }

  /**
   * @notice Withdraw collateral immediately if the remaining collateral is above GCR
   * @param derivative Derivative from which fast withdrawal was requested
   * @param collateralAmount The amount of excess collateral to withdraw
   * @return amountWithdrawn Amount of collateral withdrawn by fast withdrawal
   */
  function fastWithdraw(IDerivative derivative, uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 amountWithdrawn)
  {
    amountWithdrawn = poolStorage.fastWithdraw(
      derivative,
      FixedPoint.Unsigned(collateralAmount)
    );
  }

  /**
   * @notice Redeem tokens after derivative emergency shutdown
   * @param derivative Derivative for which settlement is requested
   * @return amountSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(IDerivative derivative)
    external
    override
    nonReentrant
    returns (uint256 amountSettled)
  {
    amountSettled = poolStorage.settleEmergencyShutdown(
      derivative,
      LIQUIDITY_PROVIDER_ROLE
    );
  }

  /**
   * @notice Update the fee percentage
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Reset the starting collateral ratio - for example when you add a new derivative without collateral
   * @param startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function setStartingCollateralization(uint256 startingCollateralRatio)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setStartingCollateralization(
      FixedPoint.Unsigned(startingCollateralRatio)
    );
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of the Synthereum pool
   */
  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  /**
   * @notice Get all the derivatives associated to this pool
   * @return Return list of all derivatives
   */
  function getAllDerivatives()
    external
    view
    override
    returns (IDerivative[] memory)
  {
    EnumerableSet.AddressSet storage derivativesSet = poolStorage.derivatives;
    uint256 numberOfDerivatives = derivativesSet.length();
    IDerivative[] memory derivatives = new IDerivative[](numberOfDerivatives);
    for (uint256 j = 0; j < numberOfDerivatives; j++) {
      derivatives[j] = (IDerivative(derivativesSet.at(j)));
    }
    return derivatives;
  }

  /**
   * @notice Check if a derivative is in the withelist of this pool
   * @param derivative Perpetual derivative
   * @return isAdmitted Return true if in the withelist otherwise false
   */
  function isDerivativeAdmitted(address derivative)
    external
    view
    override
    returns (bool isAdmitted)
  {
    isAdmitted = poolStorage.derivatives.contains(address(derivative));
  }

  /**
   * @notice Get the starting collateral ratio of the pool
   * @return startingCollateralRatio Initial ratio between collateral amount and synth tokens
   */
  function getStartingCollateralization()
    external
    view
    override
    returns (uint256 startingCollateralRatio)
  {
    startingCollateralRatio = poolStorage.startingCollateralization.rawValue;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  /**
   * @notice Returns infos about fee set
   * @return fee Percentage and recipients of fee
   */
  function getFeeInfo() external view override returns (Fee memory fee) {
    fee = poolStorage.fee;
  }

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = poolStorage.priceIdentifier;
  }

  /**
   * @notice Calculate the fees a user will have to pay to mint tokens with their collateral
   * @param collateralAmount Amount of collateral on which fee is calculated
   * @return fee Amount of fee that must be paid
   */
  function calculateFee(uint256 collateralAmount)
    external
    view
    override
    returns (uint256 fee)
  {
    fee = FixedPoint
      .Unsigned(collateralAmount)
      .mul(poolStorage.fee.feePercentage)
      .rawValue;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @param _fee Fee struct containing percentage, recipients and proportions
   */
  function setFee(Fee memory _fee) public override onlyMaintainer nonReentrant {
    poolStorage.setFeePercentage(_fee.feePercentage);
    poolStorage.setFeeRecipients(_fee.feeRecipients, _fee.feeProportions);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
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
import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  SynthereumPoolOnChainPriceFeedCreator
} from './PoolOnChainPriceFeedCreator.sol';

contract SynthereumPoolOnChainPriceFeedFactory is
  SynthereumPoolOnChainPriceFeedCreator,
  IDeploymentSignature
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  address public synthereumFinder;

  bytes4 public override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------
  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   */
  constructor(address _synthereumFinder) public {
    synthereumFinder = _synthereumFinder;
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @notice Only Synthereum deployer can deploy a pool
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  ) public override returns (SynthereumPoolOnChainPriceFeed poolDeployed) {
    address deployer =
      ISynthereumFinder(synthereumFinder).getImplementationAddress(
        SynthereumInterfaces.Deployer
      );
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    poolDeployed = super.createPool(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
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
pragma experimental ABIEncoderV2;

import {IDerivative} from '../../derivative/common/interfaces/IDerivative.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPoolOnChainPriceFeed
} from './interfaces/IPoolOnChainPriceFeed.sol';
import {SynthereumPoolOnChainPriceFeed} from './PoolOnChainPriceFeed.sol';
import '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

contract SynthereumPoolOnChainPriceFeedCreator is Lockable {
  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice The derivative's collateral currency must be an ERC20
   * @notice The validator will generally be an address owned by the LP
   * @notice `startingCollateralization should be greater than the expected asset price multiplied
   *      by the collateral requirement. The degree to which it is greater should be based on
   *      the expected asset volatility.
   * @param derivative The perpetual derivative
   * @param finder The Synthereum finder
   * @param version Synthereum version
   * @param roles The addresses of admin, maintainer, liquidity provider
   * @param startingCollateralization Collateralization ratio to use before a global one is set
   * @param fee The fee structure
   * @return poolDeployed Pool contract deployed
   */
  function createPool(
    IDerivative derivative,
    ISynthereumFinder finder,
    uint8 version,
    ISynthereumPoolOnChainPriceFeed.Roles memory roles,
    uint256 startingCollateralization,
    ISynthereumPoolOnChainPriceFeed.Fee memory fee
  )
    public
    virtual
    nonReentrant
    returns (SynthereumPoolOnChainPriceFeed poolDeployed)
  {
    poolDeployed = new SynthereumPoolOnChainPriceFeed(
      derivative,
      finder,
      version,
      roles,
      startingCollateralization,
      fee
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {AccessControl} from '../../@openzeppelin/contracts/access/AccessControl.sol';

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

  //----------------------------------------
  // Storage
  //----------------------------------------

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {EnumerableMap} from '../../@openzeppelin/contracts/utils/EnumerableMap.sol';
import {AccessControl} from '../../@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControl
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => EnumerableMap.UintToAddressMap) private factories;

  //----------------------------------------
  // Events
  //----------------------------------------

  event AddFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event SetFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event RemoveFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------
  constructor(Roles memory _roles) public {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

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
  // External functions
  //----------------------------------------

  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external override onlyMaintainer {
    require(factory != address(0), 'Factory cannot be address 0');
    bool isNewVersion = factories[factoryType].set(version, factory);
    if (isNewVersion == true) {
      emit AddFactory(factoryType, version, factory);
    } else {
      emit SetFactory(factoryType, version, factory);
    }
  }

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version)
    external
    override
    onlyMaintainer
  {
    EnumerableMap.UintToAddressMap storage selectedFactories =
      factories[factoryType];
    address factoryToRemove = selectedFactories.get(version);
    selectedFactories.remove(version);
    RemoveFactory(factoryType, version, factoryToRemove);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    override
    returns (address factory)
  {
    factory = factories[factoryType].get(version);
  }

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfVerisonsOfFactory(bytes32 factoryType)
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = factories[factoryType].length();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfVerisonsOfFactory(bytes32 factoryType)
    external
    view
    returns (uint256 numberOfVersions);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

