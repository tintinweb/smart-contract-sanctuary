/**
 *Submitted for verification at BscScan.com on 2021-12-31
*/

pragma solidity 0.6.12;


// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/CarefulMath.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
  * @title Careful Math
  * @author Compound
  * @notice Derived from OpenZeppelin's SafeMath library
  *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
  */
contract CarefulMath {

    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
    * @dev Multiplies two numbers, returns an error on overflow.
    */
    function mulUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function divUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
    * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
    */
    function subUInt(uint a, uint b) internal pure returns (MathError, uint) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
    * @dev Adds two numbers, returns an error on overflow.
    */
    function addUInt(uint a, uint b) internal pure returns (MathError, uint) {
        uint c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
    * @dev add a and b and then subtract c
    */
    function addThenSubUInt(uint a, uint b, uint c) internal pure returns (MathError, uint) {
        (MathError err0, uint sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Exponential.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint num, uint denom) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        (MathError error, uint result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint scalar) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (MathError, uint) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint scalar) pure internal returns (MathError, Exp memory) {
        (MathError err0, uint descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint scalar, Exp memory divisor) pure internal returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint scalar, Exp memory divisor) pure internal returns (MathError, uint) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {

        (MathError err0, uint doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint a, uint b) pure internal returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(Exp memory a, Exp memory b, Exp memory c) pure internal returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) pure internal returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerInterface.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

interface IComptroller {

    /*** Assets You Are In ***/

    /**
     * PIGGY-MODIFY:
     * @notice Add assets to be included in account liquidity calculation
     * @param pTokens The list of addresses of the cToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered
     */
    function enterMarkets(address[] calldata pTokens) external returns (uint[] memory);

    /**
     * PIGGY-MODIFY:
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param pTokenAddress The address of the asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(address pTokenAddress) external returns (uint);

    /*** Policy Hooks ***/

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param pToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(
        address pToken,
        address minter,
        uint mintAmount
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param pToken Asset being minted
     * @param minter The address minting the tokens
     * @param mintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(
        address pToken,
        address minter,
        uint mintAmount,
        uint mintTokens
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param pToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of cTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(
        address pToken,
        address redeemer,
        uint redeemTokens
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param pToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(
        address pToken,
        address redeemer,
        uint redeemAmount,
        uint redeemTokens
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param pToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(
        address pToken,
        address borrower,
        uint borrowAmount
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param pToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(
        address pToken,
        address borrower,
        uint borrowAmount
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param pToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param pToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address pToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the liquidation should be allowed to occur
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param pTokenCollateral Asset which was used as collateral and will be seized
     * @param pTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external;

    /**
     * PIGGY-MODIFY:
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param pToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of pTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external returns (uint);

    /**
     * PIGGY-MODIFY:
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param pToken Asset being transferred
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of pTokens to transfer
     */
    function transferVerify(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * PIGGY-MODIFY:
    * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
    * @dev Used in liquidation (called in cToken.liquidateBorrowFresh)
    * @param pTokenBorrowed The address of the borrowed cToken
    * @param pTokenCollateral The address of the collateral cToken
    * @param repayAmount The amount of cTokenBorrowed underlying to convert into cTokenCollateral tokens
    * @return (errorCode, number of cTokenCollateral tokens to be seized in a liquidation)
    */
    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint repayAmount
    ) external view returns (uint, uint);
}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/InterestRateModel.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
  * @title wepiggy's IInterestRateModel Interface
  * @author wepiggy
  */
interface IInterestRateModel {
    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external view returns (uint);

}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

contract PTokenStorage {
    /**
     * @notice Indicator that this is a PToken contract (for inspection)
     */
    bool public constant isPToken = true;

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @dev
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @dev
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @dev
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @dev
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @dev
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @dev
     * @notice Contract which oversees inter-pToken operations
     */
    IComptroller public comptroller;

    /**
     * @dev
     * @notice Model which tells what the current interest rate should be
     */
    IInterestRateModel public interestRateModel;

    /**
     * @dev
     * @notice Initial exchange rate used when minting the first PTokens (used when totalSupply = 0)
     */
    uint256 internal initialExchangeRateMantissa;

    /**
     * @dev
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @dev
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @dev
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @dev
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @dev
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @dev
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    /**
     * @dev
     * @notice Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @dev
     * @notice Approved token transfer amounts on behalf of others
     */
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    address public migrator;

    uint256 public minInterestAccumulated;

}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

abstract contract IPToken is PTokenStorage {
    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows, uint256 totalReserves);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens, uint256 totalSupply, uint256 accountTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 totalSupply, uint256 accountTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows, uint256 interestBalancePrior);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows, uint256 interestBalancePrior);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address pTokenCollateral, uint256 seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    event NewMigrator(address oldMigrator, address newMigrator);

    event NewMinInterestAccumulated(uint256 oldMinInterestAccumulated, uint256 newMinInterestAccumulated);

    /*** User Interface ***/

    function transfer(address dst, uint256 amount) external virtual returns (bool);

    function transferFrom(address src, address dst, uint256 amount) external virtual returns (bool);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function allowance(address owner, address spender) external virtual view returns (uint256);

    function balanceOf(address owner) external virtual view returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function getAccountSnapshot(address account) external virtual view returns (uint256, uint256, uint256, uint256);

    function borrowRatePerBlock() external virtual view returns (uint256);

    function supplyRatePerBlock() external virtual view returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function borrowBalanceStored(address account) public virtual view returns (uint256);

    function exchangeRateCurrent() public virtual returns (uint256);

    function exchangeRateStored() public virtual view returns (uint256);

    function getCash() external virtual view returns (uint256);

    function accrueInterest() public virtual returns (uint256);

    function seize(address liquidator, address borrower, uint256 seizeTokens) external virtual returns (uint256);

    /*** Admin Functions ***/

    function _setComptroller(IComptroller newComptroller) public virtual returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external virtual returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external virtual returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel) public virtual returns (uint256);

    function _setMigrator(address newMigrator) public virtual returns (uint256);

    function _setMinInterestAccumulated(uint _minInterestAccumulated) public virtual returns (uint256);
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/ErrorReporter.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        BAD_INPUT,
        COMPTROLLER_REJECTION,
        COMPTROLLER_CALCULATION_ERROR,
        INTEREST_RATE_MODEL_ERROR,
        INVALID_ACCOUNT_PAIR,
        INVALID_CLOSE_AMOUNT_REQUESTED,
        INVALID_COLLATERAL_FACTOR,
        MATH_ERROR,
        MARKET_NOT_FRESH,
        MARKET_NOT_LISTED,
        TOKEN_INSUFFICIENT_ALLOWANCE,
        TOKEN_INSUFFICIENT_BALANCE,
        TOKEN_INSUFFICIENT_CASH,
        TOKEN_TRANSFER_IN_FAILED,
        TOKEN_TRANSFER_OUT_FAILED
    }

    /*
     * Note: FailureInfo (but not Error) is kept in alphabetical order
     *       This is because FailureInfo grows significantly faster, and
     *       the order of Error has some meaning, while the order of FailureInfo
     *       is entirely arbitrary.
     */
    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED,
        ACCRUE_INTEREST_BORROW_RATE_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED,
        ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED,
        ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED,
        BORROW_INTEREST_BALANCE_CALCULATION_FAILED,
        BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        BORROW_ACCRUE_INTEREST_FAILED,
        BORROW_CASH_NOT_AVAILABLE,
        BORROW_FRESHNESS_CHECK,
        BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        BORROW_MARKET_NOT_LISTED,
        BORROW_COMPTROLLER_REJECTION,
        LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED,
        LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED,
        LIQUIDATE_COLLATERAL_FRESHNESS_CHECK,
        LIQUIDATE_COMPTROLLER_REJECTION,
        LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED,
        LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX,
        LIQUIDATE_CLOSE_AMOUNT_IS_ZERO,
        LIQUIDATE_FRESHNESS_CHECK,
        LIQUIDATE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_REPAY_BORROW_FRESH_FAILED,
        LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED,
        LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED,
        LIQUIDATE_SEIZE_COMPTROLLER_REJECTION,
        LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER,
        LIQUIDATE_SEIZE_TOO_MUCH,
        MINT_ACCRUE_INTEREST_FAILED,
        MINT_COMPTROLLER_REJECTION,
        MINT_EXCHANGE_CALCULATION_FAILED,
        MINT_EXCHANGE_RATE_READ_FAILED,
        MINT_FRESHNESS_CHECK,
        MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        MINT_TRANSFER_IN_FAILED,
        MINT_TRANSFER_IN_NOT_POSSIBLE,
        REDEEM_ACCRUE_INTEREST_FAILED,
        REDEEM_COMPTROLLER_REJECTION,
        REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED,
        REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED,
        REDEEM_EXCHANGE_RATE_READ_FAILED,
        REDEEM_FRESHNESS_CHECK,
        REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED,
        REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED,
        REDEEM_TRANSFER_OUT_NOT_POSSIBLE,
        REDUCE_RESERVES_ACCRUE_INTEREST_FAILED,
        REDUCE_RESERVES_ADMIN_CHECK,
        REDUCE_RESERVES_CASH_NOT_AVAILABLE,
        REDUCE_RESERVES_FRESH_CHECK,
        REDUCE_RESERVES_VALIDATION,
        REPAY_BEHALF_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_ACCRUE_INTEREST_FAILED,
        REPAY_BORROW_INTEREST_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_COMPTROLLER_REJECTION,
        REPAY_BORROW_FRESHNESS_CHECK,
        REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED,
        REPAY_BORROW_TRANSFER_IN_NOT_POSSIBLE,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COMPTROLLER_OWNER_CHECK,
        SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED,
        SET_INTEREST_RATE_MODEL_FRESH_CHECK,
        SET_INTEREST_RATE_MODEL_OWNER_CHECK,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_ORACLE_MARKET_NOT_LISTED,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED,
        SET_RESERVE_FACTOR_ADMIN_CHECK,
        SET_RESERVE_FACTOR_FRESH_CHECK,
        SET_RESERVE_FACTOR_BOUNDS_CHECK,
        TRANSFER_COMPTROLLER_REJECTION,
        TRANSFER_NOT_ALLOWED,
        TRANSFER_NOT_ENOUGH,
        TRANSFER_TOO_MUCH,
        ADD_RESERVES_ACCRUE_INTEREST_FAILED,
        ADD_RESERVES_FRESH_CHECK,
        ADD_RESERVES_TRANSFER_IN_NOT_POSSIBLE
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// https://github.com/compound-finance/compound-protocol/blob/master/contracts/CToken.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

/**
 * @title WePiggy's PToken Contract
 * @notice Abstract base for PTokens
 * @author Compound
 */
abstract contract PToken is IPToken, Exponential, TokenErrorReporter, OwnableUpgradeSafe {

    /**
     * @notice Initialize the money market
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ EIP-20 name of this token
     * @param symbol_ EIP-20 symbol of this token
     * @param decimals_ EIP-20 decimal precision of this token
     */
    function init(IComptroller comptroller_,
        IInterestRateModel interestRateModel_,
        uint initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_) public onlyOwner {
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        // Set the comptroller
        uint err = _setComptroller(comptroller_);
        require(err == uint(Error.NO_ERROR), "setting comptroller failed");

        // Initialize block number and borrow index (block number mocks depend on comptroller being set)
        accrualBlockNumber = getBlockNumber();
        borrowIndex = mantissaOne;

        // Set the interest rate model (depends on block number / borrow index)
        err = _setInterestRateModelFresh(interestRateModel_);
        require(err == uint(Error.NO_ERROR), "setting interest rate model failed");

        name = name_;
        symbol = symbol_;
        decimals = decimals_;

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferTokens(address spender, address src, address dst, uint tokens) internal returns (uint) {
        /* Fail if transfer not allowed */
        uint allowed = comptroller.transferAllowed(address(this), src, dst, tokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.TRANSFER_COMPTROLLER_REJECTION, allowed);
        }

        /* Do not allow self-transfers */
        if (src == dst) {
            return fail(Error.BAD_INPUT, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        /* Get the allowance, infinite for the account owner */
        uint startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint(- 1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        MathError mathErr;
        uint allowanceNew;
        uint srcTokensNew;
        uint dstTokensNew;

        (mathErr, allowanceNew) = subUInt(startingAllowance, tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ALLOWED);
        }

        (mathErr, srcTokensNew) = subUInt(accountTokens[src], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_NOT_ENOUGH);
        }

        (mathErr, dstTokensNew) = addUInt(accountTokens[dst], tokens);
        if (mathErr != MathError.NO_ERROR) {
            return fail(Error.MATH_ERROR, FailureInfo.TRANSFER_TOO_MUCH);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != uint(- 1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);

        comptroller.transferVerify(address(this), src, dst, tokens);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        return transferTokens(msg.sender, msg.sender, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint256 amount) external override nonReentrant returns (bool) {
        return transferTokens(msg.sender, src, dst, amount) == uint(Error.NO_ERROR);
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external override view returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint) {
        Exp memory exchangeRate = Exp({mantissa : exchangeRateCurrent()});
        (MathError mErr, uint balance) = mulScalarTruncate(exchangeRate, accountTokens[owner]);
        require(mErr == MathError.NO_ERROR, "balance could not be calculated");
        return balance;
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (possible error, token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account) external override view returns (uint, uint, uint, uint) {
        uint cTokenBalance = accountTokens[account];
        uint borrowBalance;
        uint exchangeRateMantissa;

        MathError mErr;

        (mErr, borrowBalance) = borrowBalanceStoredInternal(account);
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        (mErr, exchangeRateMantissa) = exchangeRateStoredInternal();
        if (mErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0, 0, 0);
        }

        return (uint(Error.NO_ERROR), cTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     */
    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external override view returns (uint) {
        return interestRateModel.getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external override view returns (uint) {
        return interestRateModel.getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactorMantissa);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external override nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external override nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return borrowBalanceStored(account);
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) public override view returns (uint) {
        (MathError err, uint result) = borrowBalanceStoredInternal(account);
        require(err == MathError.NO_ERROR, "borrowBalanceStored: borrowBalanceStoredInternal failed");
        return result;
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowBalanceStoredInternal(address account) internal view returns (MathError, uint) {
        /* Note: we do not assert that the market is up to date */
        MathError mathErr;
        uint principalTimesIndex;
        uint result;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        (mathErr, principalTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, result) = divUInt(principalTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, result);
    }

    /**
     * @notice Return the borrow interest balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return (error code, the calculated balance or 0 if error code is non-zero)
     */
    function borrowInterestBalancePriorInternal(address account) internal view returns (MathError, uint) {

        MathError mathErr;
        uint interestTimesIndex;
        uint principalTimesIndex;
        uint interestAmountPrior;

        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot storage borrowSnapshot = accountBorrows[account];

        if (borrowSnapshot.principal == 0) {
            return (MathError.NO_ERROR, 0);
        }
        (mathErr, interestTimesIndex) = mulUInt(borrowSnapshot.principal, borrowIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        if (borrowSnapshot.interestIndex == 0) {
            return (MathError.NO_ERROR, 0);
        }
        (mathErr, principalTimesIndex) = divUInt(interestTimesIndex, borrowSnapshot.interestIndex);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        (mathErr, interestAmountPrior) = subUInt(principalTimesIndex, borrowSnapshot.principal);
        if (mathErr != MathError.NO_ERROR) {
            return (mathErr, 0);
        }

        return (MathError.NO_ERROR, interestAmountPrior);
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override nonReentrant returns (uint) {
        require(accrueInterest() == uint(Error.NO_ERROR), "accrue interest failed");
        return exchangeRateStored();
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() public override view returns (uint) {
        (MathError err, uint result) = exchangeRateStoredInternal();
        require(err == MathError.NO_ERROR, "exchangeRateStored: exchangeRateStoredInternal failed");
        return result;
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return (error code, calculated exchange rate scaled by 1e18)
     */
    function exchangeRateStoredInternal() internal view returns (MathError, uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return (MathError.NO_ERROR, initialExchangeRateMantissa);
        } else {
            /*
             * Otherwise:
             *  exchangeRate = (totalCash + totalBorrows - totalReserves) / totalSupply
             */
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            Exp memory exchangeRate;
            MathError mathErr;

            (mathErr, cashPlusBorrowsMinusReserves) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            (mathErr, exchangeRate) = getExp(cashPlusBorrowsMinusReserves, _totalSupply);
            if (mathErr != MathError.NO_ERROR) {
                return (mathErr, 0);
            }

            return (MathError.NO_ERROR, exchangeRate.mantissa);
        }
    }

    /**
     * @notice Get cash balance of this cToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external override view returns (uint) {
        return getCashPrior();
    }

    /**
    * @notice Applies accrued interest to total borrows and reserves
    * @dev This function is copy form accrueInterest.
    */
    function accrueInterestSnapshot() public view returns (uint[] memory) {

        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */
        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        uint[] memory res = new uint[](6);

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa : borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return res;
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return res;
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return res;
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa : reserveFactorMantissa}), interestAccumulated, reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return res;
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return res;
        }

        res[0] = currentBlockNumber;
        res[1] = cashPrior;
        res[2] = interestAccumulated;
        res[3] = totalBorrowsNew;
        res[4] = totalReservesNew;
        res[5] = borrowIndexNew;

        return res;
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() public override returns (uint) {
        /* Remember the initial block number */
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return uint(Error.NO_ERROR);
        }

        /* Read the previous values out of storage */
        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRateMantissa <= borrowRateMaxMantissa, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        (MathError mathErr, uint blockDelta) = subUInt(currentBlockNumber, accrualBlockNumberPrior);
        require(mathErr == MathError.NO_ERROR, "could not calculate block delta");

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        (mathErr, simpleInterestFactor) = mulScalar(Exp({mantissa : borrowRateMantissa}), blockDelta);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_SIMPLE_INTEREST_FACTOR_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, interestAccumulated) = mulScalarTruncate(simpleInterestFactor, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_ACCUMULATED_INTEREST_CALCULATION_FAILED, uint(mathErr));
        }

        // if interestAccumulated < minInterestAccumulated, set interestAccumulated = minInterestAccumulated
        (mathErr,) = subUInt(interestAccumulated, minInterestAccumulated);
        if (mathErr != MathError.NO_ERROR) {
            interestAccumulated = minInterestAccumulated;
        }

        (mathErr, totalBorrowsNew) = addUInt(interestAccumulated, borrowsPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_BORROWS_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, totalReservesNew) = mulScalarTruncateAddUInt(Exp({mantissa : reserveFactorMantissa}), interestAccumulated, reservesPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_TOTAL_RESERVES_CALCULATION_FAILED, uint(mathErr));
        }

        (mathErr, borrowIndexNew) = mulScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.ACCRUE_INTEREST_NEW_BORROW_INDEX_CALCULATION_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender supplies assets into the market and receives cTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintInternal(uint mintAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
        }
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        return mintFresh(msg.sender, mintAmount, 0);
    }

    function mintInternalForMigrate(uint mintAmount, uint mintTokens) internal nonReentrant returns (uint, uint) {
        require(msg.sender == migrator, "mintInternalForMigrate: caller is not the migrator");

        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.MINT_ACCRUE_INTEREST_FAILED), 0);
        }
        // mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        return mintFresh(msg.sender, mintAmount, mintTokens);
    }

    struct MintLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint mintTokens;
        uint totalSupplyNew;
        uint accountTokensNew;
        uint actualMintAmount;
    }

    /**
     * @notice User supplies assets into the market and receives cTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual mint amount.
     */
    function mintFresh(address minter, uint mintAmount, uint mintTokens) internal returns (uint, uint) {

        /* Fail if mint not allowed */
        if (mintTokens == 0) {
            uint allowed = comptroller.mintAllowed(address(this), minter, mintAmount);
            if (allowed != 0) {
                return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.MINT_COMPTROLLER_REJECTION, allowed), 0);
            }
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.MINT_FRESHNESS_CHECK), 0);
        }

        MintLocalVars memory vars;

        if (mintTokens == 0) {
            (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
            if (vars.mathErr != MathError.NO_ERROR) {
                return (failOpaque(Error.MATH_ERROR, FailureInfo.MINT_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr)), 0);
            }
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `doTransferIn` for the minter and the mintAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  `doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the cToken holds an additional `actualMintAmount`
         *  of cash.
         */
        vars.actualMintAmount = doTransferIn(minter, mintAmount);

        if (mintTokens == 0) {
            /*
             * We get the current exchange rate and calculate the number of cTokens to be minted:
             *  mintTokens = actualMintAmount / exchangeRate
             */

            (vars.mathErr, vars.mintTokens) = divScalarByExpTruncate(vars.actualMintAmount, Exp({mantissa : vars.exchangeRateMantissa}));
            require(vars.mathErr == MathError.NO_ERROR, "MINT_EXCHANGE_CALCULATION_FAILED");
        } else {
            vars.mintTokens = mintTokens;
        }


        /*
         * We calculate the new total supply of cTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = addUInt(totalSupply, vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_TOTAL_SUPPLY_CALCULATION_FAILED");

        (vars.mathErr, vars.accountTokensNew) = addUInt(accountTokens[minter], vars.mintTokens);
        require(vars.mathErr == MathError.NO_ERROR, "MINT_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED");

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[minter] = vars.accountTokensNew;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, vars.actualMintAmount, vars.mintTokens, vars.totalSupplyNew, vars.accountTokensNew);
        emit Transfer(address(this), minter, vars.mintTokens);

        /* We call the defense hook */
        comptroller.mintVerify(address(this), minter, vars.actualMintAmount, vars.mintTokens);

        return (uint(Error.NO_ERROR), vars.actualMintAmount);
    }

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of cTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemInternal(uint redeemTokens) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(msg.sender, redeemTokens, 0);
    }

    /**
     * @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming cTokens
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlyingInternal(uint redeemAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted redeem failed
            return fail(Error(error), FailureInfo.REDEEM_ACCRUE_INTEREST_FAILED);
        }
        // redeemFresh emits redeem-specific logs on errors, so we don't need to
        return redeemFresh(msg.sender, 0, redeemAmount);
    }

    struct RedeemLocalVars {
        Error err;
        MathError mathErr;
        uint exchangeRateMantissa;
        uint redeemTokens;
        uint redeemAmount;
        uint totalSupplyNew;
        uint accountTokensNew;
    }

    /**
     * @notice User redeems cTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of cTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming cTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemFresh(address payable redeemer, uint redeemTokensIn, uint redeemAmountIn) internal returns (uint) {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        RedeemLocalVars memory vars;

        /* exchangeRate = invoke Exchange Rate Stored() */
        (vars.mathErr, vars.exchangeRateMantissa) = exchangeRateStoredInternal();
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_RATE_READ_FAILED, uint(vars.mathErr));
        }

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             *  redeemAmount = redeemTokensIn x exchangeRateCurrent
             */
            vars.redeemTokens = redeemTokensIn;

            (vars.mathErr, vars.redeemAmount) = mulScalarTruncate(Exp({mantissa : vars.exchangeRateMantissa}), redeemTokensIn);
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_TOKENS_CALCULATION_FAILED, uint(vars.mathErr));
            }
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             *  redeemAmount = redeemAmountIn
             */

            (vars.mathErr, vars.redeemTokens) = divScalarByExpTruncate(redeemAmountIn, Exp({mantissa : vars.exchangeRateMantissa}));
            if (vars.mathErr != MathError.NO_ERROR) {
                return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_EXCHANGE_AMOUNT_CALCULATION_FAILED, uint(vars.mathErr));
            }

            vars.redeemAmount = redeemAmountIn;
        }

        /* Fail if redeem not allowed */
        uint allowed = comptroller.redeemAllowed(address(this), redeemer, vars.redeemTokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REDEEM_COMPTROLLER_REJECTION, allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDEEM_FRESHNESS_CHECK);
        }

        /*
         * We calculate the new total supply and redeemer balance, checking for underflow:
         *  totalSupplyNew = totalSupply - redeemTokens
         *  accountTokensNew = accountTokens[redeemer] - redeemTokens
         */
        (vars.mathErr, vars.totalSupplyNew) = subUInt(totalSupply, vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_TOTAL_SUPPLY_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountTokensNew) = subUInt(accountTokens[redeemer], vars.redeemTokens);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.REDEEM_NEW_ACCOUNT_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /* Fail gracefully if protocol has insufficient cash */
        if (getCashPrior() < vars.redeemAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDEEM_TRANSFER_OUT_NOT_POSSIBLE);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the redeemer and the redeemAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken has redeemAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(redeemer, vars.redeemAmount);

        /* We write previously calculated values into storage */
        totalSupply = vars.totalSupplyNew;
        accountTokens[redeemer] = vars.accountTokensNew;

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), vars.redeemTokens);
        emit Redeem(redeemer, vars.redeemAmount, vars.redeemTokens, vars.totalSupplyNew, vars.accountTokensNew);

        /* We call the defense hook */
        comptroller.redeemVerify(address(this), redeemer, vars.redeemAmount, vars.redeemTokens);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrowInternal(uint borrowAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return fail(Error(error), FailureInfo.BORROW_ACCRUE_INTEREST_FAILED);
        }
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        return borrowFresh(msg.sender, borrowAmount);
    }

    struct BorrowLocalVars {
        MathError mathErr;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint interestBalancePrior; //interest balance before now.
    }

    /**
      * @notice Users borrow assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrowFresh(address payable borrower, uint borrowAmount) internal returns (uint) {
        /* Fail if borrow not allowed */
        uint allowed = comptroller.borrowAllowed(address(this), borrower, borrowAmount);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.BORROW_COMPTROLLER_REJECTION, allowed);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.BORROW_FRESHNESS_CHECK);
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (getCashPrior() < borrowAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.BORROW_CASH_NOT_AVAILABLE);
        }

        BorrowLocalVars memory vars;

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowsNew = accountBorrows + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        (vars.mathErr, vars.interestBalancePrior) = borrowInterestBalancePriorInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_INTEREST_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.accountBorrowsNew) = addUInt(vars.accountBorrows, borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        (vars.mathErr, vars.totalBorrowsNew) = addUInt(totalBorrows, borrowAmount);
        if (vars.mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED, uint(vars.mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We invoke doTransferOut for the borrower and the borrowAmount.
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken borrowAmount less of cash.
         *  doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        doTransferOut(borrower, borrowAmount);

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, vars.accountBorrowsNew, vars.totalBorrowsNew, vars.interestBalancePrior);

        /* We call the defense hook */
        comptroller.borrowVerify(address(this), borrower, borrowAmount);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowInternal(uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BORROW_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, msg.sender, repayAmount);
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowBehalfInternal(address borrower, uint repayAmount) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted borrow failed
            return (fail(Error(error), FailureInfo.REPAY_BEHALF_ACCRUE_INTEREST_FAILED), 0);
        }
        // repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        return repayBorrowFresh(msg.sender, borrower, repayAmount);
    }

    struct RepayBorrowLocalVars {
        Error err;
        MathError mathErr;
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint totalBorrowsNew;
        uint actualRepayAmount;
        uint interestBalancePrior;
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of undelrying tokens being returned
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function repayBorrowFresh(address payer, address borrower, uint repayAmount) internal returns (uint, uint) {
        /* Fail if repayBorrow not allowed */
        uint allowed = comptroller.repayBorrowAllowed(address(this), payer, borrower, repayAmount);
        if (allowed != 0) {
            return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.REPAY_BORROW_COMPTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.REPAY_BORROW_FRESHNESS_CHECK), 0);
        }

        RepayBorrowLocalVars memory vars;

        /* We remember the original borrowerIndex for verification purposes */
        vars.borrowerIndex = accountBorrows[borrower].interestIndex;

        (vars.mathErr, vars.interestBalancePrior) = borrowInterestBalancePriorInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_INTEREST_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* We fetch the amount the borrower owes, with accumulated interest */
        (vars.mathErr, vars.accountBorrows) = borrowBalanceStoredInternal(borrower);
        if (vars.mathErr != MathError.NO_ERROR) {
            return (failOpaque(Error.MATH_ERROR, FailureInfo.REPAY_BORROW_ACCUMULATED_BALANCE_CALCULATION_FAILED, uint(vars.mathErr)), 0);
        }

        /* If repayAmount == -1, repayAmount = accountBorrows */
        if (repayAmount == uint(- 1)) {
            vars.repayAmount = vars.accountBorrows;
        } else {
            vars.repayAmount = repayAmount;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the payer and the repayAmount
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken holds an additional repayAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        vars.actualRepayAmount = doTransferIn(payer, vars.repayAmount);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        (vars.mathErr, vars.accountBorrowsNew) = subUInt(vars.accountBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_ACCOUNT_BORROW_BALANCE_CALCULATION_FAILED");

        (vars.mathErr, vars.totalBorrowsNew) = subUInt(totalBorrows, vars.actualRepayAmount);
        require(vars.mathErr == MathError.NO_ERROR, "REPAY_BORROW_NEW_TOTAL_BALANCE_CALCULATION_FAILED");

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = vars.accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = vars.totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, vars.actualRepayAmount, vars.accountBorrowsNew, vars.totalBorrowsNew, vars.interestBalancePrior);

        /* We call the defense hook */
        comptroller.repayBorrowVerify(address(this), payer, borrower, vars.actualRepayAmount, vars.borrowerIndex);

        return (uint(Error.NO_ERROR), vars.actualRepayAmount);
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowInternal(address borrower, uint repayAmount, IPToken pTokenCollateral) internal nonReentrant returns (uint, uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_BORROW_INTEREST_FAILED), 0);
        }

        error = pTokenCollateral.accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            return (fail(Error(error), FailureInfo.LIQUIDATE_ACCRUE_COLLATERAL_INTEREST_FAILED), 0);
        }

        // liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
        return liquidateBorrowFresh(msg.sender, borrower, repayAmount, pTokenCollateral);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this cToken to be liquidated
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @return (uint, uint) An error code (0=success, otherwise a failure, see ErrorReporter.sol), and the actual repayment amount.
     */
    function liquidateBorrowFresh(address liquidator, address borrower, uint repayAmount, IPToken pTokenCollateral) internal returns (uint, uint) {
        /* Fail if liquidate not allowed */
        uint allowed = comptroller.liquidateBorrowAllowed(address(this), address(pTokenCollateral), liquidator, borrower, repayAmount);
        if (allowed != 0) {
            return (failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_COMPTROLLER_REJECTION, allowed), 0);
        }

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_FRESHNESS_CHECK), 0);
        }

        /* Verify pTokenCollateral market's block number equals current block number */
        if (pTokenCollateral.accrualBlockNumber() != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.LIQUIDATE_COLLATERAL_FRESHNESS_CHECK), 0);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return (fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_LIQUIDATOR_IS_BORROWER), 0);
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_ZERO), 0);
        }

        /* Fail if repayAmount = -1 */
        if (repayAmount == uint(- 1)) {
            return (fail(Error.INVALID_CLOSE_AMOUNT_REQUESTED, FailureInfo.LIQUIDATE_CLOSE_AMOUNT_IS_UINT_MAX), 0);
        }


        /* Fail if repayBorrow fails */
        (uint repayBorrowError, uint actualRepayAmount) = repayBorrowFresh(liquidator, borrower, repayAmount);
        if (repayBorrowError != uint(Error.NO_ERROR)) {
            return (fail(Error(repayBorrowError), FailureInfo.LIQUIDATE_REPAY_BORROW_FRESH_FAILED), 0);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint amountSeizeError, uint seizeTokens) = comptroller.liquidateCalculateSeizeTokens(address(this), address(pTokenCollateral), actualRepayAmount);
        require(amountSeizeError == uint(Error.NO_ERROR), "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        /* Revert if borrower collateral token balance < seizeTokens */
        require(pTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        // If this is also the collateral, run seizeInternal to avoid re-entrancy, otherwise make an external call
        uint seizeError;
        if (address(pTokenCollateral) == address(this)) {
            seizeError = seizeInternal(address(this), liquidator, borrower, seizeTokens);
        } else {
            seizeError = pTokenCollateral.seize(liquidator, borrower, seizeTokens);
        }

        /* Revert if seize tokens fails (since we cannot be sure of side effects) */
        require(seizeError == uint(Error.NO_ERROR), "token seizure failed");

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(pTokenCollateral), seizeTokens);

        /* We call the defense hook */
        comptroller.liquidateBorrowVerify(address(this), address(pTokenCollateral), liquidator, borrower, actualRepayAmount, seizeTokens);

        return (uint(Error.NO_ERROR), actualRepayAmount);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another cToken during the process of liquidation.
     *  Its absolutely critical to use msg.sender as the borrowed cToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seize(address liquidator, address borrower, uint seizeTokens) external override nonReentrant returns (uint) {
        return seizeInternal(msg.sender, liquidator, borrower, seizeTokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another CToken.
     *  Its absolutely critical to use msg.sender as the seizer cToken and not a parameter.
     * @param seizerToken The contract seizing the collateral (i.e. borrowed cToken)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of cTokens to seize
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function seizeInternal(address seizerToken, address liquidator, address borrower, uint seizeTokens) internal returns (uint) {
        /* Fail if seize not allowed */
        uint allowed = comptroller.seizeAllowed(address(this), seizerToken, liquidator, borrower, seizeTokens);
        if (allowed != 0) {
            return failOpaque(Error.COMPTROLLER_REJECTION, FailureInfo.LIQUIDATE_SEIZE_COMPTROLLER_REJECTION, allowed);
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            return fail(Error.INVALID_ACCOUNT_PAIR, FailureInfo.LIQUIDATE_SEIZE_LIQUIDATOR_IS_BORROWER);
        }

        MathError mathErr;
        uint borrowerTokensNew;
        uint liquidatorTokensNew;

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        (mathErr, borrowerTokensNew) = subUInt(accountTokens[borrower], seizeTokens);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_DECREMENT_FAILED, uint(mathErr));
        }

        (mathErr, liquidatorTokensNew) = addUInt(accountTokens[liquidator], seizeTokens);
        if (mathErr != MathError.NO_ERROR) {
            return failOpaque(Error.MATH_ERROR, FailureInfo.LIQUIDATE_SEIZE_BALANCE_INCREMENT_FAILED, uint(mathErr));
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accountTokens[borrower] = borrowerTokensNew;
        accountTokens[liquidator] = liquidatorTokensNew;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, seizeTokens);

        /* We call the defense hook */
        comptroller.seizeVerify(address(this), seizerToken, liquidator, borrower, seizeTokens);

        return uint(Error.NO_ERROR);
    }


    /*** Admin Functions ***/

    /**
      * @notice Sets a new comptroller for the market
      * @dev Admin function to set a new comptroller
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setComptroller(IComptroller newComptroller) public onlyOwner override returns (uint) {
        IComptroller oldComptroller = comptroller;
        // Ensure invoke comptroller.isComptroller() returns true
        // require(newComptroller.isComptroller(), "marker method returned false");

        // Set market's comptroller to newComptroller
        comptroller = newComptroller;

        // Emit NewComptroller(oldComptroller, newComptroller)
        emit NewComptroller(oldComptroller, newComptroller);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
      * @dev Admin function to accrue interest and set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactor(uint newReserveFactorMantissa) external override nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reserve factor change failed.
            return fail(Error(error), FailureInfo.SET_RESERVE_FACTOR_ACCRUE_INTEREST_FAILED);
        }
        // _setReserveFactorFresh emits reserve-factor-specific logs on errors, so we don't need to.
        return _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
      * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
      * @dev Admin function to set a new reserve factor
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setReserveFactorFresh(uint newReserveFactorMantissa) internal onlyOwner returns (uint) {
        // Verify market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_RESERVE_FACTOR_FRESH_CHECK);
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > reserveFactorMaxMantissa) {
            return fail(Error.BAD_INPUT, FailureInfo.SET_RESERVE_FACTOR_BOUNDS_CHECK);
        }

        uint oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring from msg.sender
     * @param addAmount Amount of addition to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReservesInternal(uint addAmount) internal nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.ADD_RESERVES_ACCRUE_INTEREST_FAILED);
        }

        // _addReservesFresh emits reserve-addition-specific logs on errors, so we don't need to.
        (error,) = _addReservesFresh(addAmount);
        return error;
    }

    /**
     * @notice Add reserves by transferring from caller
     * @dev Requires fresh interest accrual
     * @param addAmount Amount of addition to reserves
     * @return (uint, uint) An error code (0=success, otherwise a failure (see ErrorReporter.sol for details)) and the actual amount added, net token fees
     */
    function _addReservesFresh(uint addAmount) internal returns (uint, uint) {
        // totalReserves + actualAddAmount
        uint totalReservesNew;
        uint actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            return (fail(Error.MARKET_NOT_FRESH, FailureInfo.ADD_RESERVES_FRESH_CHECK), actualAddAmount);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call doTransferIn for the caller and the addAmount
         *  Note: The cToken must handle variations between ERC-20 and ETH underlying.
         *  On success, the cToken holds an additional addAmount of cash.
         *  doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *  it returns the amount actually transferred, in case of a fee.
         */

        actualAddAmount = doTransferIn(msg.sender, addAmount);

        totalReservesNew = totalReserves + actualAddAmount;

        /* Revert on overflow */
        require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");

        // Store reserves[n+1] = reserves[n] + actualAddAmount
        totalReserves = totalReservesNew;

        /* Emit NewReserves(admin, actualAddAmount, reserves[n+1]) */
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        /* Return (NO_ERROR, actualAddAmount) */
        return (uint(Error.NO_ERROR), actualAddAmount);
    }


    /**
     * @notice Accrues interest and reduces reserves by transferring to admin
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReserves(uint reduceAmount) external override nonReentrant returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted reduce reserves failed.
            return fail(Error(error), FailureInfo.REDUCE_RESERVES_ACCRUE_INTEREST_FAILED);
        }
        // _reduceReservesFresh emits reserve-reduction-specific logs on errors, so we don't need to.
        return _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice Reduces reserves by transferring to admin
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _reduceReservesFresh(uint reduceAmount) internal onlyOwner returns (uint) {
        // totalReserves - reduceAmount
        uint totalReservesNew;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.REDUCE_RESERVES_FRESH_CHECK);
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (getCashPrior() < reduceAmount) {
            return fail(Error.TOKEN_INSUFFICIENT_CASH, FailureInfo.REDUCE_RESERVES_CASH_NOT_AVAILABLE);
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            return fail(Error.BAD_INPUT, FailureInfo.REDUCE_RESERVES_VALIDATION);
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;
        // We checked reduceAmount <= totalReserves above, so this should never revert.
        require(totalReservesNew <= totalReserves, "reduce reserves unexpected underflow");

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        doTransferOut(payable(owner()), reduceAmount);

        emit ReservesReduced(owner(), reduceAmount, totalReservesNew);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModel(IInterestRateModel newInterestRateModel) public override returns (uint) {
        uint error = accrueInterest();
        if (error != uint(Error.NO_ERROR)) {
            // accrueInterest emits logs on errors, but on top of that we want to log the fact that an attempted change of interest rate model failed
            return fail(Error(error), FailureInfo.SET_INTEREST_RATE_MODEL_ACCRUE_INTEREST_FAILED);
        }
        // _setInterestRateModelFresh emits interest-rate-model-update-specific logs on errors, so we don't need to.
        return _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setInterestRateModelFresh(IInterestRateModel newInterestRateModel) internal onlyOwner returns (uint) {

        // Used to store old model for use in the event that is emitted on success
        IInterestRateModel oldInterestRateModel;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != getBlockNumber()) {
            return fail(Error.MARKET_NOT_FRESH, FailureInfo.SET_INTEREST_RATE_MODEL_FRESH_CHECK);
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        //        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);

        return uint(Error.NO_ERROR);
    }

    function _setMigrator(address newMigrator) public onlyOwner override returns (uint) {
        address oldMigrator = migrator;

        // Set market's comptroller to newComptroller
        migrator = newMigrator;

        // Emit NewComptroller(oldComptroller, newComptroller)
        emit NewMigrator(oldMigrator, newMigrator);

        return uint(Error.NO_ERROR);
    }

    function _setMinInterestAccumulated(uint _minInterestAccumulated) public onlyOwner override returns (uint256){
        uint oldMinInterestAccumulated = minInterestAccumulated;

        minInterestAccumulated = _minInterestAccumulated;

        emit NewMinInterestAccumulated(oldMinInterestAccumulated, _minInterestAccumulated);

        return uint(Error.NO_ERROR);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying owned by this contract
     */
    function getCashPrior() internal virtual view returns (uint);

    /**
     * @dev Performs a transfer in, reverting upon failure. Returns the amount actually transferred to the protocol, in case of a fee.
     *  This may revert due to insufficient balance or insufficient allowance.
     */
    function doTransferIn(address from, uint amount) internal virtual returns (uint);

    /**
     * @dev Performs a transfer out, ideally returning an explanatory error code upon failure tather than reverting.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     */
    function doTransferOut(address payable to, uint amount) internal virtual;


    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true;
        // get a gas-refund post-Istanbul
    }
}

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

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/PriceOracle.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a asset
     * @param _pToken The asset to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(PToken _pToken) external view returns (uint);
}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/ComptrollerStorage.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

contract ComptrollerStorage {

    //PIGGY-MODIFY:Copy and modify from ComptrollerV1Storage

    /**
     * @notice Oracle which gives the price of any given asset
     */
    IPriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint256 public maxAssets;

    /**
     * PIGGY-MODIFY:
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => PToken[]) public accountAssets;

    /**
     * PIGGY-MODIFY: Copy and modify from ComptrollerV2Storage
     */
    struct Market {
        // @notice Whether or not this market is listed
        bool isListed;

        // @notice Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value. Must be between 0 and 1, and stored as a mantissa.
        uint256 collateralFactorMantissa;

        // @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        // @notice Whether or not this market receives WPC
        bool isMinted;
    }

    /**
     * @notice Official mapping of pTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public pTokenMintGuardianPaused;
    mapping(address => bool) public pTokenBorrowGuardianPaused;
    bool public distributeWpcPaused;


    //PIGGY-MODIFY: Copy and modify from ComptrollerV4Storage

    // @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow cap could disable borrowing on the given market.
    address public borrowCapGuardian;

    // @notice Borrow caps enforced by borrowAllowed for each cToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(address => uint256) public borrowCaps;


    //PIGGY-MODIFY: Copy and modify from ComptrollerV3Storage
    /// @notice A list of all markets
    PToken[] public allMarkets;

}

interface IPiggyDistribution {

    function distributeMintWpc(address pToken, address minter, bool distributeAll) external;

    function distributeRedeemWpc(address pToken, address redeemer, bool distributeAll) external;

    function distributeBorrowWpc(address pToken, address borrower, bool distributeAll) external;

    function distributeRepayBorrowWpc(address pToken, address borrower, bool distributeAll) external;

    function distributeSeizeWpc(address pTokenCollateral, address borrower, address liquidator, bool distributeAll) external;

    function distributeTransferWpc(address pToken, address src, address dst, bool distributeAll) external;

}

interface IPiggyBreeder {
    function stake(uint256 _pid, uint256 _amount) external;

    function unStake(uint256 _pid, uint256 _amount) external;

    function claim(uint256 _pid) external;

    function emergencyWithdraw(uint256 _pid) external;
}

contract PiggyDistribution is IPiggyDistribution, Exponential, OwnableUpgradeSafe {

    IERC20 public piggy;

    IPiggyBreeder public piggyBreeder;

    Comptroller public comptroller;

    //PIGGY-MODIFY: Copy and modify from ComptrollerV3Storage

    struct WpcMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The portion of compRate that each market currently receives
    mapping(address => uint) public wpcSpeeds;

    /// @notice The WPC market supply state for each market
    mapping(address => WpcMarketState) public wpcSupplyState;

    /// @notice The WPC market borrow state for each market
    mapping(address => WpcMarketState) public wpcBorrowState;

    /// @notice The WPC borrow index for each market for each supplier as of the last time they accrued WPC
    mapping(address => mapping(address => uint)) public wpcSupplierIndex;

    /// @notice The WPC borrow index for each market for each borrower as of the last time they accrued WPC
    mapping(address => mapping(address => uint)) public wpcBorrowerIndex;

    /// @notice The WPC accrued but not yet transferred to each user
    mapping(address => uint) public wpcAccrued;

    /// @notice The threshold above which the flywheel transfers WPC, in wei
    uint public constant wpcClaimThreshold = 0.001e18;

    /// @notice The initial WPC index for a market
    uint224 public constant wpcInitialIndex = 1e36;

    bool public enableWpcClaim;
    bool public enableDistributeMintWpc;
    bool public enableDistributeRedeemWpc;
    bool public enableDistributeBorrowWpc;
    bool public enableDistributeRepayBorrowWpc;
    bool public enableDistributeSeizeWpc;
    bool public enableDistributeTransferWpc;


    /// @notice Emitted when a new WPC speed is calculated for a market
    event WpcSpeedUpdated(PToken indexed pToken, uint newSpeed);

    /// @notice Emitted when WPC is distributed to a supplier
    event DistributedSupplierWpc(PToken indexed pToken, address indexed supplier, uint wpcDelta, uint wpcSupplyIndex);

    /// @notice Emitted when WPC is distributed to a borrower
    event DistributedBorrowerWpc(PToken indexed pToken, address indexed borrower, uint wpcDelta, uint wpcBorrowIndex);

    event StakeTokenToPiggyBreeder(IERC20 token, uint pid, uint amount);

    event ClaimWpcFromPiggyBreeder(uint pid);

    event EnableState(string action, bool state);

    function initialize(IERC20 _piggy, IPiggyBreeder _piggyBreeder, Comptroller _comptroller) public initializer {

        piggy = _piggy;
        piggyBreeder = _piggyBreeder;
        comptroller = _comptroller;

        enableWpcClaim = false;
        enableDistributeMintWpc = false;
        enableDistributeRedeemWpc = false;
        enableDistributeBorrowWpc = false;
        enableDistributeRepayBorrowWpc = false;
        enableDistributeSeizeWpc = false;
        enableDistributeTransferWpc = false;

        super.__Ownable_init();
    }

    function distributeMintWpc(address pToken, address minter, bool distributeAll) public override(IPiggyDistribution) {
        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");
        if (enableDistributeMintWpc) {
            updateWpcSupplyIndex(pToken);
            distributeSupplierWpc(pToken, minter, distributeAll);
        }
    }

    function distributeRedeemWpc(address pToken, address redeemer, bool distributeAll) public override(IPiggyDistribution) {
        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");
        if (enableDistributeRedeemWpc) {
            updateWpcSupplyIndex(pToken);
            distributeSupplierWpc(pToken, redeemer, distributeAll);
        }
    }

    function distributeBorrowWpc(address pToken, address borrower, bool distributeAll) public override(IPiggyDistribution) {

        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");

        if (enableDistributeBorrowWpc) {
            Exp memory borrowIndex = Exp({mantissa : PToken(pToken).borrowIndex()});
            updateWpcBorrowIndex(pToken, borrowIndex);
            distributeBorrowerWpc(pToken, borrower, borrowIndex, distributeAll);
        }


    }

    function distributeRepayBorrowWpc(address pToken, address borrower, bool distributeAll) public override(IPiggyDistribution) {

        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");

        if (enableDistributeRepayBorrowWpc) {
            Exp memory borrowIndex = Exp({mantissa : PToken(pToken).borrowIndex()});
            updateWpcBorrowIndex(pToken, borrowIndex);
            distributeBorrowerWpc(pToken, borrower, borrowIndex, distributeAll);
        }

    }

    function distributeSeizeWpc(address pTokenCollateral, address borrower, address liquidator, bool distributeAll) public override(IPiggyDistribution) {

        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");

        if (enableDistributeSeizeWpc) {
            updateWpcSupplyIndex(pTokenCollateral);
            distributeSupplierWpc(pTokenCollateral, borrower, distributeAll);
            distributeSupplierWpc(pTokenCollateral, liquidator, distributeAll);
        }

    }

    function distributeTransferWpc(address pToken, address src, address dst, bool distributeAll) public override(IPiggyDistribution) {

        require(msg.sender == address(comptroller) || msg.sender == owner(), "only comptroller or owner");

        if (enableDistributeTransferWpc) {
            updateWpcSupplyIndex(pToken);
            distributeSupplierWpc(pToken, src, distributeAll);
            distributeSupplierWpc(pToken, dst, distributeAll);
        }

    }

    function _stakeTokenToPiggyBreeder(IERC20 token, uint pid) public onlyOwner {
        uint amount = token.balanceOf(address(this));
        token.approve(address(piggyBreeder), amount);
        piggyBreeder.stake(pid, amount);
        emit StakeTokenToPiggyBreeder(token, pid, amount);
    }

    function _claimWpcFromPiggyBreeder(uint pid) public onlyOwner {
        piggyBreeder.claim(pid);
        emit ClaimWpcFromPiggyBreeder(pid);
    }

    function setWpcSpeedInternal(PToken pToken, uint wpcSpeed) internal {
        uint currentWpcSpeed = wpcSpeeds[address(pToken)];
        if (currentWpcSpeed != 0) {
            // note that WPC speed could be set to 0 to halt liquidity rewards for a market
            Exp memory borrowIndex = Exp({mantissa : pToken.borrowIndex()});
            updateWpcSupplyIndex(address(pToken));
            updateWpcBorrowIndex(address(pToken), borrowIndex);
        } else if (wpcSpeed != 0) {

            require(comptroller.isMarketListed(address(pToken)), "wpc market is not listed");

            if (comptroller.isMarketMinted(address(pToken)) == false) {
                comptroller._setMarketMinted(address(pToken), true);
            }

            if (wpcSupplyState[address(pToken)].index == 0 && wpcSupplyState[address(pToken)].block == 0) {
                wpcSupplyState[address(pToken)] = WpcMarketState({
                index : wpcInitialIndex,
                block : safe32(block.number, "block number exceeds 32 bits")
                });
            }

            if (wpcBorrowState[address(pToken)].index == 0 && wpcBorrowState[address(pToken)].block == 0) {
                wpcBorrowState[address(pToken)] = WpcMarketState({
                index : wpcInitialIndex,
                block : safe32(block.number, "block number exceeds 32 bits")
                });
            }

        }

        if (currentWpcSpeed != wpcSpeed) {
            wpcSpeeds[address(pToken)] = wpcSpeed;
            emit WpcSpeedUpdated(pToken, wpcSpeed);
        }

    }

    /**
     * @notice Accrue WPC to the market by updating the supply index
     * @param pToken The market whose supply index to update
     */
    function updateWpcSupplyIndex(address pToken) internal {
        WpcMarketState storage supplyState = wpcSupplyState[pToken];
        uint supplySpeed = wpcSpeeds[pToken];
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = PToken(pToken).totalSupply();
            uint wpcAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(wpcAccrued, supplyTokens) : Double({mantissa : 0});
            Double memory index = add_(Double({mantissa : supplyState.index}), ratio);
            wpcSupplyState[pToken] = WpcMarketState({
            index : safe224(index.mantissa, "new index exceeds 224 bits"),
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Accrue WPC to the market by updating the borrow index
     * @param pToken The market whose borrow index to update
     */
    function updateWpcBorrowIndex(address pToken, Exp memory marketBorrowIndex) internal {
        WpcMarketState storage borrowState = wpcBorrowState[pToken];
        uint borrowSpeed = wpcSpeeds[pToken];
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(PToken(pToken).totalBorrows(), marketBorrowIndex);
            uint wpcAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(wpcAccrued, borrowAmount) : Double({mantissa : 0});
            Double memory index = add_(Double({mantissa : borrowState.index}), ratio);
            wpcBorrowState[pToken] = WpcMarketState({
            index : safe224(index.mantissa, "new index exceeds 224 bits"),
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Calculate WPC accrued by a supplier and possibly transfer it to them
     * @param pToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute WPC to
     */
    function distributeSupplierWpc(address pToken, address supplier, bool distributeAll) internal {
        WpcMarketState storage supplyState = wpcSupplyState[pToken];
        Double memory supplyIndex = Double({mantissa : supplyState.index});
        Double memory supplierIndex = Double({mantissa : wpcSupplierIndex[pToken][supplier]});
        wpcSupplierIndex[pToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = wpcInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = PToken(pToken).balanceOf(supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(wpcAccrued[supplier], supplierDelta);
        wpcAccrued[supplier] = grantWpcInternal(supplier, supplierAccrued, distributeAll ? 0 : wpcClaimThreshold);
        emit DistributedSupplierWpc(PToken(pToken), supplier, supplierDelta, supplyIndex.mantissa);
    }


    /**
     * @notice Calculate WPC accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param pToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute WPC to
     */
    function distributeBorrowerWpc(address pToken, address borrower, Exp memory marketBorrowIndex, bool distributeAll) internal {
        WpcMarketState storage borrowState = wpcBorrowState[pToken];
        Double memory borrowIndex = Double({mantissa : borrowState.index});
        Double memory borrowerIndex = Double({mantissa : wpcBorrowerIndex[pToken][borrower]});
        wpcBorrowerIndex[pToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(PToken(pToken).borrowBalanceStored(borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(wpcAccrued[borrower], borrowerDelta);
            wpcAccrued[borrower] = grantWpcInternal(borrower, borrowerAccrued, distributeAll ? 0 : wpcClaimThreshold);
            emit DistributedBorrowerWpc(PToken(pToken), borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }


    /**
     * @notice Transfer WPC to the user, if they are above the threshold
     * @dev Note: If there is not enough WPC, we do not perform the transfer all.
     * @param user The address of the user to transfer WPC to
     * @param userAccrued The amount of WPC to (possibly) transfer
     * @return The amount of WPC which was NOT transferred to the user
     */
    function grantWpcInternal(address user, uint userAccrued, uint threshold) internal returns (uint) {
        if (userAccrued >= threshold && userAccrued > 0 && enableWpcClaim == true) {
            uint wpcRemaining = piggy.balanceOf(address(this));
            uint _amountSend = mul_(userAccrued, 1000);
            if (_amountSend <= wpcRemaining) {
                piggy.transfer(user, _amountSend);
                return 0;
            }
        }
        return userAccrued;
    }

    /**
     * @notice Claim all the wpc accrued by holder in all markets
     * @param holder The address to claim WPC for
     */
    function claimWpc(address holder) public {
        claimWpc(holder, comptroller.getAllMarkets());
    }

    /**
     * @notice Claim all the comp accrued by holder in the specified markets
     * @param holder The address to claim WPC for
     * @param pTokens The list of markets to claim WPC in
     */
    function claimWpc(address holder, PToken[] memory pTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimWpc(holders, pTokens, true, true);
    }

    /**
     * @notice Claim all wpc accrued by the holders
     * @param holders The addresses to claim WPC for
     * @param pTokens The list of markets to claim WPC in
     * @param borrowers Whether or not to claim WPC earned by borrowing
     * @param suppliers Whether or not to claim WPC earned by supplying
     */
    function claimWpc(address[] memory holders, PToken[] memory pTokens, bool borrowers, bool suppliers) public {
        require(enableWpcClaim, "Claim is not enabled");

        for (uint i = 0; i < pTokens.length; i++) {
            PToken pToken = pTokens[i];
            require(comptroller.isMarketListed(address(pToken)), "market must be listed");
            if (borrowers == true) {
                Exp memory borrowIndex = Exp({mantissa : pToken.borrowIndex()});
                updateWpcBorrowIndex(address(pToken), borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerWpc(address(pToken), holders[j], borrowIndex, true);
                }
            }
            if (suppliers == true) {
                updateWpcSupplyIndex(address(pToken));
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierWpc(address(pToken), holders[j], true);
                }
            }
        }

    }

    /*** WPC Distribution Admin ***/

    function _setWpcSpeed(PToken pToken, uint wpcSpeed) public onlyOwner {
        setWpcSpeedInternal(pToken, wpcSpeed);
    }

    function _setEnableWpcClaim(bool state) public onlyOwner {
        enableWpcClaim = state;
        emit EnableState("enableWpcClaim", state);
    }

    function _setEnableDistributeMintWpc(bool state) public onlyOwner {
        enableDistributeMintWpc = state;
        emit EnableState("enableDistributeMintWpc", state);
    }

    function _setEnableDistributeRedeemWpc(bool state) public onlyOwner {
        enableDistributeRedeemWpc = state;
        emit EnableState("enableDistributeRedeemWpc", state);
    }

    function _setEnableDistributeBorrowWpc(bool state) public onlyOwner {
        enableDistributeBorrowWpc = state;
        emit EnableState("enableDistributeBorrowWpc", state);
    }

    function _setEnableDistributeRepayBorrowWpc(bool state) public onlyOwner {
        enableDistributeRepayBorrowWpc = state;
        emit EnableState("enableDistributeRepayBorrowWpc", state);
    }

    function _setEnableDistributeSeizeWpc(bool state) public onlyOwner {
        enableDistributeSeizeWpc = state;
        emit EnableState("enableDistributeSeizeWpc", state);
    }

    function _setEnableDistributeTransferWpc(bool state) public onlyOwner {
        enableDistributeTransferWpc = state;
        emit EnableState("enableDistributeTransferWpc", state);
    }

    function _setEnableAll(bool state) public onlyOwner {
        _setEnableDistributeMintWpc(state);
        _setEnableDistributeRedeemWpc(state);
        _setEnableDistributeBorrowWpc(state);
        _setEnableDistributeRepayBorrowWpc(state);
        _setEnableDistributeSeizeWpc(state);
        _setEnableDistributeTransferWpc(state);
        _setEnableWpcClaim(state);
    }

    function _transferWpc(address to, uint amount) public onlyOwner {
        _transferToken(address(piggy), to, amount);
    }

    function _transferToken(address token, address to, uint amount) public onlyOwner {
        IERC20 erc20 = IERC20(token);

        uint balance = erc20.balanceOf(address(this));
        if (balance < amount) {
            amount = balance;
        }

        erc20.transfer(to, amount);
    }

    function pendingWpcAccrued(address holder, bool borrowers, bool suppliers) public view returns (uint256){
        return pendingWpcInternal(holder, borrowers, suppliers);
    }

    function pendingWpcInternal(address holder, bool borrowers, bool suppliers) internal view returns (uint256){

        uint256 pendingWpc = wpcAccrued[holder];

        PToken[] memory pTokens = comptroller.getAllMarkets();
        for (uint i = 0; i < pTokens.length; i++) {
            address pToken = address(pTokens[i]);
            uint tmp = 0;
            if (borrowers == true) {
                tmp = pendingWpcBorrowInternal(holder, pToken);
                pendingWpc = add_(pendingWpc, tmp);
            }
            if (suppliers == true) {
                tmp = pendingWpcSupplyInternal(holder, pToken);
                pendingWpc = add_(pendingWpc, tmp);
            }
        }

        return pendingWpc;
    }

    function pendingWpcBorrowInternal(address borrower, address pToken) internal view returns (uint256){
        if (enableDistributeBorrowWpc && enableDistributeRepayBorrowWpc) {
            Exp memory marketBorrowIndex = Exp({mantissa : PToken(pToken).borrowIndex()});
            WpcMarketState memory borrowState = pendingWpcBorrowIndex(pToken, marketBorrowIndex);

            Double memory borrowIndex = Double({mantissa : borrowState.index});
            Double memory borrowerIndex = Double({mantissa : wpcBorrowerIndex[pToken][borrower]});
            if (borrowerIndex.mantissa > 0) {
                Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
                uint borrowerAmount = div_(PToken(pToken).borrowBalanceStored(borrower), marketBorrowIndex);
                uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
                return borrowerDelta;
            }
        }
        return 0;
    }

    function pendingWpcBorrowIndex(address pToken, Exp memory marketBorrowIndex) internal view returns (WpcMarketState memory){
        WpcMarketState memory borrowState = wpcBorrowState[pToken];
        uint borrowSpeed = wpcSpeeds[pToken];
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint borrowAmount = div_(PToken(pToken).totalBorrows(), marketBorrowIndex);
            uint wpcAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(wpcAccrued, borrowAmount) : Double({mantissa : 0});
            Double memory index = add_(Double({mantissa : borrowState.index}), ratio);
            borrowState = WpcMarketState({
            index : safe224(index.mantissa, "new index exceeds 224 bits"),
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState = WpcMarketState({
            index : borrowState.index,
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
        return borrowState;
    }

    function pendingWpcSupplyInternal(address supplier, address pToken) internal view returns (uint256){
        if (enableDistributeMintWpc && enableDistributeRedeemWpc) {
            WpcMarketState memory supplyState = pendingWpcSupplyIndex(pToken);
            Double memory supplyIndex = Double({mantissa : supplyState.index});
            Double memory supplierIndex = Double({mantissa : wpcSupplierIndex[pToken][supplier]});
            if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
                supplierIndex.mantissa = wpcInitialIndex;
            }
            Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
            uint supplierTokens = PToken(pToken).balanceOf(supplier);
            uint supplierDelta = mul_(supplierTokens, deltaIndex);
            return supplierDelta;
        }
        return 0;
    }

    function pendingWpcSupplyIndex(address pToken) internal view returns (WpcMarketState memory){
        WpcMarketState memory supplyState = wpcSupplyState[pToken];
        uint supplySpeed = wpcSpeeds[pToken];
        uint blockNumber = block.number;
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));

        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint supplyTokens = PToken(pToken).totalSupply();
            uint wpcAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(wpcAccrued, supplyTokens) : Double({mantissa : 0});
            Double memory index = add_(Double({mantissa : supplyState.index}), ratio);
            supplyState = WpcMarketState({
            index : safe224(index.mantissa, "new index exceeds 224 bits"),
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState = WpcMarketState({
            index : supplyState.index,
            block : safe32(blockNumber, "block number exceeds 32 bits")
            });
        }
        return supplyState;
    }

    function _setPiggy(address _piggy) public onlyOwner {
        piggy = IERC20(_piggy);
    }

    function _resetWpcSupplyState(address[] memory pTokens) public onlyOwner {

        for (uint i = 0; i < pTokens.length; i++) {
            address pToken = pTokens[i];
            wpcSupplyState[pToken] = WpcMarketState({
            index : wpcInitialIndex,
            block : safe32(block.number, "block number exceeds 32 bits")
            });
        }

    }

}

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Comptroller.sol
//Copyright 2020 Compound Labs, Inc.
//Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

//PIGGY-MODIFY: Modified some methods and fields according to WePiggy's business logic
contract Comptroller is ComptrollerStorage, IComptroller, ComptrollerErrorReporter, Exponential, OwnableUpgradeSafe {

    // @notice Emitted when an admin supports a market
    event MarketListed(PToken pToken);

    // @notice Emitted when an account enters a market
    event MarketEntered(PToken pToken, address account);

    // @notice Emitted when an account exits a market
    event MarketExited(PToken pToken, address account);

    // @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint oldCloseFactorMantissa, uint newCloseFactorMantissa);

    // @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(PToken pToken, uint oldCollateralFactorMantissa, uint newCollateralFactorMantissa);

    // @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint oldLiquidationIncentiveMantissa, uint newLiquidationIncentiveMantissa);

    // @notice Emitted when maxAssets is changed by admin
    event NewMaxAssets(uint oldMaxAssets, uint newMaxAssets);

    // @notice Emitted when price oracle is changed
    event NewPriceOracle(IPriceOracle oldPriceOracle, IPriceOracle newPriceOracle);

    // @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    // @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    // @notice Emitted when an action is paused on a market
    event ActionPaused(PToken pToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a pToken is changed
    event NewBorrowCap(PToken indexed pToken, uint newBorrowCap);

    /// @notice Emitted when borrow cap guardian is changed
    event NewBorrowCapGuardian(address oldBorrowCapGuardian, address newBorrowCapGuardian);

    event NewPiggyDistribution(IPiggyDistribution oldPiggyDistribution, IPiggyDistribution newPiggyDistribution);

    /// @notice Emitted when mint cap for a pToken is changed
    event NewMintCap(PToken indexed pToken, uint newMintCap);

    // closeFactorMantissa must be strictly greater than this value
    uint internal constant closeFactorMinMantissa = 0.05e18;

    // closeFactorMantissa must not exceed this value
    uint internal constant closeFactorMaxMantissa = 0.9e18;

    // No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18;

    // liquidationIncentiveMantissa must be no less than this value
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18;

    // liquidationIncentiveMantissa must be no greater than this value
    uint internal constant liquidationIncentiveMaxMantissa = 1.5e18;

    // for distribute wpc
    IPiggyDistribution piggyDistribution;

    mapping(address => uint256) public mintCaps;

    function initialize() public initializer {

        //setting the msg.sender as the initial owner.
        super.__Ownable_init();
    }


    /*** Assets You Are In ***/

    function enterMarkets(address[] memory pTokens) public override(IComptroller) returns (uint[] memory)  {
        uint len = pTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            PToken pToken = PToken(pTokens[i]);
            results[i] = uint(addToMarketInternal(pToken, msg.sender));
        }

        return results;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param pToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(PToken pToken, address borrower) internal returns (Error) {
        Market storage marketToJoin = markets[address(pToken)];

        // market is not listed, cannot join
        if (!marketToJoin.isListed) {
            return Error.MARKET_NOT_LISTED;
        }

        // already joined
        if (marketToJoin.accountMembership[borrower] == true) {
            return Error.NO_ERROR;
        }

        // no space, cannot join
        if (accountAssets[borrower].length >= maxAssets) {
            return Error.TOO_MANY_ASSETS;
        }

        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(pToken);

        emit MarketEntered(pToken, borrower);

        return Error.NO_ERROR;
    }

    function exitMarket(address pTokenAddress) external override(IComptroller) returns (uint) {
        PToken pToken = PToken(pTokenAddress);

        // Get sender tokensHeld and amountOwed underlying from the pToken
        (uint oErr, uint tokensHeld, uint amountOwed,) = pToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed");

        // Fail if the sender has a borrow balance
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        // Fail if the sender is not permitted to redeem all of their tokens
        uint allowed = redeemAllowedInternal(pTokenAddress, msg.sender, tokensHeld);
        if (allowed != 0) {
            return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
        }

        Market storage marketToExit = markets[address(pToken)];

        // Return true if the sender is not already ‘in’ the market
        if (!marketToExit.accountMembership[msg.sender]) {
            return uint(Error.NO_ERROR);
        }

        // Set pToken account membership to false
        delete marketToExit.accountMembership[msg.sender];

        // Delete pToken from the account’s list of assets
        // load into memory for faster iteration
        PToken[] memory userAssetList = accountAssets[msg.sender];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == pToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        PToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(pToken, msg.sender);

        return uint(Error.NO_ERROR);
    }


    /**
    * @notice Returns the assets an account has entered
    * @param account The address of the account to pull assets for
    * @return A dynamic list with the assets the account has entered
    */
    function getAssetsIn(address account) external view returns (PToken[] memory) {
        PToken[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param pToken The pToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, PToken pToken) external view returns (bool) {
        return markets[address(pToken)].accountMembership[account];
    }

    /*** Policy Hooks ***/

    function mintAllowed(address pToken, address minter, uint mintAmount) external override(IComptroller) returns (uint){

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!pTokenMintGuardianPaused[pToken], "mint is paused");

        //Shh - currently unused. It's written here to eliminate compile-time alarms.
        minter;
        mintAmount;

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        uint mintCap = mintCaps[pToken];
        if (mintCap != 0) {
            uint totalSupply = PToken(pToken).totalSupply();
            uint exchangeRate = PToken(pToken).exchangeRateStored();
            (MathError mErr, uint balance) = mulScalarTruncate(Exp({mantissa : exchangeRate}), totalSupply);
            require(mErr == MathError.NO_ERROR, "balance could not be calculated");
            (MathError mathErr, uint nextTotalMints) = addUInt(balance, mintAmount);
            require(mathErr == MathError.NO_ERROR, "total mint amount overflow");
            require(nextTotalMints < mintCap, "market mint cap reached");
        }

        if (distributeWpcPaused == false) {
            piggyDistribution.distributeMintWpc(pToken, minter, false);
        }

        return uint(Error.NO_ERROR);
    }

    function mintVerify(address pToken, address minter, uint mintAmount, uint mintTokens) external override(IComptroller) {

        //Shh - currently unused. It's written here to eliminate compile-time alarms.
        pToken;
        minter;
        mintAmount;
        mintTokens;

    }

    function redeemAllowed(address pToken, address redeemer, uint redeemTokens) external override(IComptroller) returns (uint){

        uint allowed = redeemAllowedInternal(pToken, redeemer, redeemTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        if (distributeWpcPaused == false) {
            piggyDistribution.distributeRedeemWpc(pToken, redeemer, false);
        }

        return uint(Error.NO_ERROR);
    }

    /**
    * PIGGY-MODIFY:
    * @notice Checks if the account should be allowed to redeem tokens in the given market
    * @param pToken The market to verify the redeem against
    * @param redeemer The account which would redeem the tokens
    * @param redeemTokens The number of pTokens to exchange for the underlying asset in the market
    * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
    */
    function redeemAllowedInternal(address pToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[pToken].accountMembership[redeemer]) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, PToken(pToken), redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    function redeemVerify(address pToken, address redeemer, uint redeemAmount, uint redeemTokens) external override(IComptroller) {
        //Shh - currently unused. It's written here to eliminate compile-time alarms.
        pToken;
        redeemer;
        redeemAmount;
        redeemTokens;
    }

    function borrowAllowed(address pToken, address borrower, uint borrowAmount) external override(IComptroller) returns (uint) {

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!pTokenBorrowGuardianPaused[pToken], "borrow is paused");

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!markets[pToken].accountMembership[borrower]) {

            // only pTokens may call borrowAllowed if borrower not in market
            require(msg.sender == pToken, "sender must be pToken");

            // attempt to add borrower to the market
            Error err = addToMarketInternal(PToken(msg.sender), borrower);
            if (err != Error.NO_ERROR) {
                return uint(err);
            }

            // it should be impossible to break the important invariant
            assert(markets[pToken].accountMembership[borrower]);
        }

        if (oracle.getUnderlyingPrice(PToken(pToken)) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        uint borrowCap = borrowCaps[pToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = PToken(pToken).totalBorrows();
            (MathError mathErr, uint nextTotalBorrows) = addUInt(totalBorrows, borrowAmount);
            require(mathErr == MathError.NO_ERROR, "total borrows overflow");
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, PToken(pToken), 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        //distribute wpc
        if (distributeWpcPaused == false) {
            piggyDistribution.distributeBorrowWpc(pToken, borrower, false);
        }

        return uint(Error.NO_ERROR);

    }

    function borrowVerify(address pToken, address borrower, uint borrowAmount) external override(IComptroller) {
        //Shh - currently unused. It's written here to eliminate compile-time alarms.
        pToken;
        borrower;
        borrowAmount;
    }

    function repayBorrowAllowed(address pToken, address payer, address borrower, uint repayAmount) external override(IComptroller) returns (uint) {

        if (!markets[pToken].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        payer;
        borrower;
        repayAmount;

        //distribute wpc
        if (distributeWpcPaused == false) {
            piggyDistribution.distributeRepayBorrowWpc(pToken, borrower, false);
        }

        return uint(Error.NO_ERROR);
    }

    function repayBorrowVerify(address pToken, address payer, address borrower, uint repayAmount, uint borrowerIndex) external override(IComptroller) {

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        pToken;
        payer;
        borrower;
        repayAmount;
        borrowerIndex;
    }

    function liquidateBorrowAllowed(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external override(IComptroller) returns (uint){

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        liquidator;

        if (!markets[pTokenBorrowed].isListed || !markets[pTokenCollateral].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint borrowBalance = PToken(pTokenBorrowed).borrowBalanceStored(borrower);
        (MathError mathErr, uint maxClose) = mulScalarTruncate(Exp({mantissa : closeFactorMantissa}), borrowBalance);
        if (mathErr != MathError.NO_ERROR) {
            return uint(Error.MATH_ERROR);
        }
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    function liquidateBorrowVerify(
        address pTokenBorrowed,
        address pTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens
    ) external override(IComptroller) {

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        pTokenBorrowed;
        pTokenCollateral;
        liquidator;
        borrower;
        repayAmount;
        seizeTokens;

    }

    function seizeAllowed(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external override(IComptroller) returns (uint){
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        seizeTokens;

        if (!markets[pTokenCollateral].isListed || !markets[pTokenBorrowed].isListed) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (PToken(pTokenCollateral).comptroller() != PToken(pTokenBorrowed).comptroller()) {
            return uint(Error.COMPTROLLER_MISMATCH);
        }

        //distribute wpc
        if (distributeWpcPaused == false) {
            piggyDistribution.distributeSeizeWpc(pTokenCollateral, borrower, liquidator, false);
        }

        return uint(Error.NO_ERROR);
    }

    function seizeVerify(
        address pTokenCollateral,
        address pTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens
    ) external override(IComptroller) {

        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        pTokenCollateral;
        pTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;
    }

    function transferAllowed(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external override(IComptroller) returns (uint){
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused, "transfer is paused");

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        uint allowed = redeemAllowedInternal(pToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        //distribute wpc
        if (distributeWpcPaused == false) {
            piggyDistribution.distributeTransferWpc(pToken, src, dst, false);
        }

        return uint(Error.NO_ERROR);
    }

    function transferVerify(
        address pToken,
        address src,
        address dst,
        uint transferTokens
    ) external override(IComptroller) {
        // Shh - currently unused. It's written here to eliminate compile-time alarms.
        pToken;
        src;
        dst;
        transferTokens;
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `pTokenBalance` is the number of pTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint pTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, PToken(0), 0, 0);
        return (uint(err), liquidity, shortfall);
    }


    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, PToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address pTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, PToken(pTokenModify), redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }


    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param account The account to determine liquidity for
     * @param pTokenModify The market to hypothetically redeem/borrow in
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral pToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        PToken pTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars;
        uint oErr;
        MathError mErr;

        // For each asset the account is in
        PToken[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {
            PToken asset = assets[i];

            // Read the balances and exchange rate from the pToken
            (oErr, vars.pTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(account);
            if (oErr != 0) {// semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa : markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa : vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa : vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> usd (normalized price value)
            // pTokenPrice = oraclePrice * exchangeRate
            (mErr, vars.tokensToDenom) = mulExp3(vars.collateralFactor, vars.exchangeRate, vars.oraclePrice);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // sumCollateral += tokensToDenom * pTokenBalance
            (mErr, vars.sumCollateral) = mulScalarTruncateAddUInt(vars.tokensToDenom, vars.pTokenBalance, vars.sumCollateral);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);
            if (mErr != MathError.NO_ERROR) {
                return (Error.MATH_ERROR, 0, 0);
            }

            // Calculate effects of interacting with pTokenModify
            if (asset == pTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                (mErr, vars.sumBorrowPlusEffects) = mulScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
                if (mErr != MathError.NO_ERROR) {
                    return (Error.MATH_ERROR, 0, 0);
                }
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    function liquidateCalculateSeizeTokens(
        address pTokenBorrowed,
        address pTokenCollateral,
        uint actualRepayAmount
    ) external override(IComptroller) view returns (uint, uint) {
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = oracle.getUnderlyingPrice(PToken(pTokenBorrowed));
        uint priceCollateralMantissa = oracle.getUnderlyingPrice(PToken(pTokenCollateral));
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
        * Get the exchange rate and calculate the number of collateral tokens to seize:
        *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
        *  seizeTokens = seizeAmount / exchangeRate
        *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
        *
        * Note: reverts on error
        */
        uint exchangeRateMantissa = PToken(pTokenCollateral).exchangeRateStored();

        uint seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;
        MathError mathErr;

        (mathErr, numerator) = mulExp(liquidationIncentiveMantissa, priceBorrowedMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, denominator) = mulExp(priceCollateralMantissa, exchangeRateMantissa);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, ratio) = divExp(numerator, denominator);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        (mathErr, seizeTokens) = mulScalarTruncate(ratio, actualRepayAmount);
        if (mathErr != MathError.NO_ERROR) {
            return (uint(Error.MATH_ERROR), 0);
        }

        return (uint(Error.NO_ERROR), seizeTokens);

    }

    /*** Admin Functions ***/

    /**
      * @notice Sets a new price oracle for the comptroller
      * @dev Admin function to set a new price oracle
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function _setPriceOracle(IPriceOracle newOracle) public onlyOwner returns (uint) {

        // Track the old oracle for the comptroller
        IPriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the closeFactor used when liquidating borrows
      * @dev Admin function to set closeFactor
      * @param newCloseFactorMantissa New close factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCloseFactor(uint newCloseFactorMantissa) external onlyOwner returns (uint) {

        Exp memory newCloseFactorExp = Exp({mantissa : newCloseFactorMantissa});
        Exp memory lowLimit = Exp({mantissa : closeFactorMinMantissa});
        if (lessThanOrEqualExp(newCloseFactorExp, lowLimit)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        Exp memory highLimit = Exp({mantissa : closeFactorMaxMantissa});
        if (lessThanExp(highLimit, newCloseFactorExp)) {
            return fail(Error.INVALID_CLOSE_FACTOR, FailureInfo.SET_CLOSE_FACTOR_VALIDATION);
        }

        uint oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a market
      * @dev Admin function to set per-market collateralFactor
      * @param pToken The market to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(PToken pToken, uint newCollateralFactorMantissa) external onlyOwner returns (uint) {

        // Verify market is listed
        Market storage market = markets[address(pToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa : newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa : collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(pToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(pToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets maxAssets which controls how many markets can be entered
      * @dev Admin function to set maxAssets
      * @param newMaxAssets New max assets
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setMaxAssets(uint newMaxAssets) external onlyOwner returns (uint) {

        uint oldMaxAssets = maxAssets;
        maxAssets = newMaxAssets;
        emit NewMaxAssets(oldMaxAssets, newMaxAssets);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets liquidationIncentive
      * @dev Admin function to set liquidationIncentive
      * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setLiquidationIncentive(uint newLiquidationIncentiveMantissa) external onlyOwner returns (uint) {

        // Check de-scaled min <= newLiquidationIncentive <= max
        Exp memory newLiquidationIncentive = Exp({mantissa : newLiquidationIncentiveMantissa});
        Exp memory minLiquidationIncentive = Exp({mantissa : liquidationIncentiveMinMantissa});
        if (lessThanExp(newLiquidationIncentive, minLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        Exp memory maxLiquidationIncentive = Exp({mantissa : liquidationIncentiveMaxMantissa});
        if (lessThanExp(maxLiquidationIncentive, newLiquidationIncentive)) {
            return fail(Error.INVALID_LIQUIDATION_INCENTIVE, FailureInfo.SET_LIQUIDATION_INCENTIVE_VALIDATION);
        }

        // Save current value for use in log
        uint oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Add the market to the markets mapping and set it as listed
      * @dev Admin function to set isListed and add support for the market
      * @param pToken The address of the market (token) to list
      * @return uint 0=success, otherwise a failure. (See enum Error for details)
      */
    function _supportMarket(PToken pToken) external onlyOwner returns (uint) {

        if (markets[address(pToken)].isListed) {
            return fail(Error.MARKET_ALREADY_LISTED, FailureInfo.SUPPORT_MARKET_EXISTS);
        }

        markets[address(pToken)] = Market({isListed : true, isMinted : false, collateralFactorMantissa : 0});

        _addMarketInternal(address(pToken));

        emit MarketListed(pToken);

        return uint(Error.NO_ERROR);
    }

    function _addMarketInternal(address pToken) internal onlyOwner {
        for (uint i = 0; i < allMarkets.length; i ++) {
            require(allMarkets[i] != PToken(pToken), "market already added");
        }
        allMarkets.push(PToken(pToken));
    }

    /**
      * @notice Set the given borrow caps for the given pToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
      * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
      * @param pTokens The addresses of the markets (tokens) to change the borrow caps for
      * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
      */
    function _setMarketBorrowCaps(PToken[] calldata pTokens, uint[] calldata newBorrowCaps) external {
        require(msg.sender == owner() || msg.sender == borrowCapGuardian, "only owner or borrow cap guardian can set borrow caps");

        uint numMarkets = pTokens.length;
        uint numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for (uint i = 0; i < numMarkets; i++) {
            borrowCaps[address(pTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(pTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian) external onlyOwner {

        // Save current value for inclusion in log
        address oldBorrowCapGuardian = borrowCapGuardian;

        // Store borrowCapGuardian with value newBorrowCapGuardian
        borrowCapGuardian = newBorrowCapGuardian;

        // Emit NewBorrowCapGuardian(OldBorrowCapGuardian, NewBorrowCapGuardian)
        emit NewBorrowCapGuardian(oldBorrowCapGuardian, newBorrowCapGuardian);
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public onlyOwner returns (uint) {

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint(Error.NO_ERROR);
    }

    function _setMintPaused(PToken pToken, bool state) public returns (bool) {
        require(markets[address(pToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == owner(), "only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "only owner can unpause");

        pTokenMintGuardianPaused[address(pToken)] = state;
        emit ActionPaused(pToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(PToken pToken, bool state) public returns (bool) {
        require(markets[address(pToken)].isListed, "cannot pause a market that is not listed");
        require(msg.sender == pauseGuardian || msg.sender == owner(), "only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "only owner can unpause");

        pTokenBorrowGuardianPaused[address(pToken)] = state;
        emit ActionPaused(pToken, "Borrow", state);
        return state;
    }

    function _setTransferPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == owner(), "only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "only owner can unpause");

        transferGuardianPaused = state;
        emit ActionPaused("Transfer", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == owner(), "only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "only owner can unpause");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _setDistributeWpcPaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == owner(), "only pause guardian and owner can pause");
        require(msg.sender == owner() || state == true, "only owner can unpause");

        distributeWpcPaused = state;
        emit ActionPaused("DistributeWpc", state);
        return state;
    }

    /**
     * @notice Sets a new price piggyDistribution for the comptroller
     * @dev Admin function to set a new piggy distribution
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPiggyDistribution(IPiggyDistribution newPiggyDistribution) public onlyOwner returns (uint) {

        IPiggyDistribution oldPiggyDistribution = piggyDistribution;

        piggyDistribution = newPiggyDistribution;

        emit NewPiggyDistribution(oldPiggyDistribution, newPiggyDistribution);

        return uint(Error.NO_ERROR);
    }

    function getAllMarkets() public view returns (PToken[] memory){
        return allMarkets;
    }

    function isMarketMinted(address pToken) public view returns (bool){
        return markets[pToken].isMinted;
    }

    function isMarketListed(address pToken) public view returns (bool){
        return markets[pToken].isListed;
    }

    function _setMarketMinted(address pToken, bool status) public {

        require(msg.sender == address(piggyDistribution) || msg.sender == owner(), "only PiggyDistribution or owner can update");

        markets[pToken].isMinted = status;
    }

    function _setMarketMintCaps(PToken[] calldata pTokens, uint[] calldata newMintCaps) external onlyOwner {

        uint numMarkets = pTokens.length;
        uint numMintCaps = newMintCaps.length;

        require(numMarkets != 0 && numMarkets == numMintCaps, "invalid input");

        for (uint i = 0; i < numMarkets; i++) {
            mintCaps[address(pTokens[i])] = newMintCaps[i];
            emit NewBorrowCap(pTokens[i], newMintCaps[i]);
        }
    }


}