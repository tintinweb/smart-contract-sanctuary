/* SPDX-License-Identifier: MIT */
pragma solidity ^0.7.0;

import "./CarefulMath.sol";
import "./ExponentialStorage.sol";

/**
 * @title Exponential module for storing fixed-precision decimals.
 * @author Paul Razvan Berg
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 * Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is: `Exp({mantissa: 5100000000000000000})`.
 * @dev Forked from Compound
 * https://github.com/compound-finance/compound-protocol/blob/v2.6/contracts/Exponential.sol
 */
abstract contract Exponential is
    CarefulMath, /* no dependency */
    ExponentialStorage /* no dependency */
{
    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     * (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b.
     * NOTE: Returns an error if (`num` * 10e18) > MAX_INT, or if `denom` is zero.
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(a.mantissa, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        (MathError err1, uint256 rational) = divUInt(scaledNumerator, b.mantissa);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        return (MathError.NO_ERROR, Exp({ mantissa: rational }));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({ mantissa: 0 }));
        }

        /*
         * We add half the scale before dividing so that we get rounding instead of truncation.
         * See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
         * Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
         */
        (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({ mantissa: 0 }));
        }

        (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        /* The only possible error `div` is MathError.DIVISION_BY_ZERO but we control `expScale` and it's not zero. */
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({ mantissa: product }));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({ mantissa: result }));
    }
}
