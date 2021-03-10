// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interfaces/INormalDistribution.sol";

import "../lib/FixidityLib.sol";
import "../lib/LogarithmLib.sol";
import "../interfaces/IBlackScholes.sol";

/**
 * @title BlackScholes
 * @author Pods Finance
 * @notice Black-Scholes calculus
 */
contract BlackScholes is IBlackScholes {
    using SafeMath for uint256;
    using FixidityLib for int256;
    using LogarithmLib for int256;

    INormalDistribution public immutable normalDistribution;

    uint8 public constant decimals = 18; // solhint-disable-line const-name-snakecase
    uint8 public constant precisionDecimals = 24; // solhint-disable-line const-name-snakecase

    uint256 public constant UNIT = 10**uint256(decimals);
    uint256 public constant PRECISION_UNIT = 10**uint256(precisionDecimals);

    uint256 public constant UNIT_TO_PRECISION_FACTOR = 10**uint256(precisionDecimals - decimals);

    constructor(address _normalDistribution) public {
        require(_normalDistribution != address(0), "BlackScholes: Invalid normalDistribution");
        normalDistribution = INormalDistribution(_normalDistribution);
    }

    /**
     * @notice Calculate call option price
     *
     * @param spotPrice Asset spot price
     * @param strikePrice Option strike price
     * @param sigma Annually volatility on the asset price
     * @param time Annualized time until maturity
     * @param riskFree The risk-free rate
     * @return call option price
     */
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) public override view returns (uint256) {
        (int256 d1, int256 d2) = _getZScores(_uintToInt(spotPrice), _uintToInt(strikePrice), sigma, time, riskFree);

        uint256 Nd1 = normalDistribution.getProbability(d1, precisionDecimals);
        uint256 Nd2 = normalDistribution.getProbability(d2, precisionDecimals);

        uint256 get = spotPrice.mul(Nd1).div(PRECISION_UNIT);
        uint256 pay = strikePrice.mul(Nd2).div(PRECISION_UNIT);

        if (pay > get) {
            // Negative numbers not allowed
            return 0;
        }

        return get.sub(pay);
    }

    /**
     * @notice Calculate put option price
     *
     * @param spotPrice Asset spot price
     * @param strikePrice Option strike price
     * @param sigma Annually volatility on the asset price
     * @param time Annualized time until maturity
     * @param riskFree The risk-free rate
     * @return put option price
     */
    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) public override view returns (uint256) {
        (int256 d1, int256 d2) = _getZScores(_uintToInt(spotPrice), _uintToInt(strikePrice), sigma, time, riskFree);

        uint256 Nd1 = normalDistribution.getProbability(_additiveInverse(d1), precisionDecimals);
        uint256 Nd2 = normalDistribution.getProbability(_additiveInverse(d2), precisionDecimals);

        uint256 get = strikePrice.mul(Nd2).div(PRECISION_UNIT);
        uint256 pay = spotPrice.mul(Nd1).div(PRECISION_UNIT);

        if (pay > get) {
            // Negative numbers not allowed
            return 0;
        }

        return get.sub(pay);
    }

    /**
     * @dev Get z-scores d1 and d2
     *
     ***********************************************************************************************
     * So = spotPrice                                                                             //
     * X  = strikePrice              ln( So / X ) + t ( r + ( σ² / 2 ) )                          //
     * σ  = sigma               d1 = --------------------------------------                       //
     * t  = time                               σ ( sqrt(t) )                                      //
     * r  = riskFree                                                                              //
     *                          d2 = d1 - σ ( sqrt(t) )                                           //
     ***********************************************************************************************
     *
     * @param spotPrice Asset spot price
     * @param strikePrice Option strike price
     * @param sigma Annually volatility on the asset price
     * @param time Annualized time until maturity
     * @param riskFree The risk-free rate
     */
    function _getZScores(
        int256 spotPrice,
        int256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) internal pure returns (int256 d1, int256 d2) {
        uint256 sigma2 = _normalized(sigma).mul(_normalized(sigma)) / PRECISION_UNIT;

        int256 A = _cachedLn(spotPrice.divide(strikePrice));
        int256 B = (_uintToInt(sigma2 / 2)).add(_normalized(riskFree)).multiply(_normalized(_uintToInt(time)));

        int256 n = A.add(B);

        uint256 sqrtTime = _sqrt(_normalized(time));
        uint256 d = sigma.mul(sqrtTime) / UNIT_TO_PRECISION_FACTOR;

        d1 = n.divide(_uintToInt(d));
        d2 = d1.subtract(_uintToInt(d));

        return (d1, d2);
    }

    /**
     * @dev Square root
     * @dev See the following for reference https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
     *
     * @param x The value
     * @return y The square root of x
     */
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x.add(1)) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z).add(z) / 2;
        }
    }

    /**
     * @dev Same as natural logarithm but hard-coded for known x values
     * @param x The value to be ln
     * @return ln of x
     */
    function _cachedLn(int256 x) internal pure returns (int256) {
        return LogarithmLib.ln(x);
    }

    /**
     * Normalizes uint numbers to precision uint
     */
    function _normalized(uint256 x) internal pure returns (uint256) {
        return x.mul(UNIT_TO_PRECISION_FACTOR);
    }

    /**
     * Normalizes int numbers to precision int
     */
    function _normalized(int256 x) internal pure returns (int256) {
        return _mulInt(x, int256(UNIT_TO_PRECISION_FACTOR));
    }

    /**
     * Safe math multiplications for Int.
     */

    function _mulInt(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(a == 0 || c / a == b, "BlackScholes: multInt overflow");
        return c;
    }

    /**
     * Convert uint256 to int256 taking in account overflow.
     */
    function _uintToInt(uint256 input) internal pure returns (int256) {
        int256 output = int256(input);
        require(output >= 0, "BlackScholes: casting overflow");
        return output;
    }

    /**
     * Return the additive inverse b of a number a
     */
    function _additiveInverse(int256 a) internal pure returns (int256 b) {
        b = -a;
        bool isAPositive = a > 0;
        bool isBPositive = b > 0;
        require(isBPositive != isAPositive, "BlackScholes: additiveInverse overflow");
    }
}

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface INormalDistribution {
    function getProbability(int256 z, uint256 decimals) external view returns (uint256);
}

// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.6.12;

/**
 * @title FixidityLib
 * @author Gadi Guy, Alberto Cuesta Canada
 * @notice This library provides fixed point arithmetic with protection against
 * overflow.
 * @dev Extracted from https://github.com/CementDAO/Fixidity/blob/master/contracts/FixidityLib.sol
 * All operations are done with int256 and the operands must have been created
 * with any of the newFrom* functions, which shift the comma digits() to the
 * right and check for limits.
 * When using this library be sure of using maxNewFixed() as the upper limit for
 * creation of fixed point numbers. Use maxFixedMul(), maxFixedDiv() and
 * maxFixedAdd() if you want to be certain that those operations don't
 * overflow.
 */
library FixidityLib {
    /**
     * @notice Number of positions that the comma is shifted to the right.
     */
    function digits() public pure returns (uint8) {
        return 24;
    }

    /**
     * @notice This is 1 in the fixed point units used in this library.
     * @dev Test fixed1() equals 10^digits()
     * Hardcoded to 24 digits.
     */
    function fixed1() public pure returns (int256) {
        return 1000000000000000000000000;
    }

    /**
     * @notice The amount of decimals lost on each multiplication operand.
     * @dev Test mulPrecision() equals sqrt(fixed1)
     * Hardcoded to 24 digits.
     */
    function mulPrecision() public pure returns (int256) {
        return 1000000000000;
    }

    /**
     * @notice Maximum value that can be represented in an int256
     * @dev Test maxInt256() equals 2^255 -1
     */
    function maxInt256() public pure returns (int256) {
        return 57896044618658097711785492504343953926634992332820282019728792003956564819967;
    }

    /**
     * @notice Minimum value that can be represented in an int256
     * @dev Test minInt256 equals (2^255) * (-1)
     */
    function minInt256() public pure returns (int256) {
        return -57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    /**
     * @notice Maximum value that can be converted to fixed point. Optimize for
     * @dev deployment.
     * Test maxNewFixed() equals maxInt256() / fixed1()
     * Hardcoded to 24 digits.
     */
    function maxNewFixed() public pure returns (int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Minimum value that can be converted to fixed point. Optimize for
     * deployment.
     * @dev Test minNewFixed() equals -(maxInt256()) / fixed1()
     * Hardcoded to 24 digits.
     */
    function minNewFixed() public pure returns (int256) {
        return -57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as an addition operator.
     * @dev Test maxFixedAdd() equals maxInt256()-1 / 2
     * Test add(maxFixedAdd(),maxFixedAdd()) equals maxFixedAdd() + maxFixedAdd()
     * Test add(maxFixedAdd()+1,maxFixedAdd()) throws
     * Test add(-maxFixedAdd(),-maxFixedAdd()) equals -maxFixedAdd() - maxFixedAdd()
     * Test add(-maxFixedAdd(),-maxFixedAdd()-1) throws
     */
    function maxFixedAdd() public pure returns (int256) {
        return 28948022309329048855892746252171976963317496166410141009864396001978282409983;
    }

    /**
     * @notice Maximum negative value that can be safely in a subtraction.
     * @dev Test maxFixedSub() equals minInt256() / 2
     */
    function maxFixedSub() public pure returns (int256) {
        return -28948022309329048855892746252171976963317496166410141009864396001978282409984;
    }

    /**
     * @notice Maximum value that can be safely used as a multiplication operator.
     * @dev Calculated as sqrt(maxInt256()*fixed1()).
     * Be careful with your sqrt() implementation. I couldn't find a calculator
     * that would give the exact square root of maxInt256*fixed1 so this number
     * is below the real number by no more than 3*10**28. It is safe to use as
     * a limit for your multiplications, although powers of two of numbers over
     * this value might still work.
     * Test multiply(maxFixedMul(),maxFixedMul()) equals maxFixedMul() * maxFixedMul()
     * Test multiply(maxFixedMul(),maxFixedMul()+1) throws
     * Test multiply(-maxFixedMul(),maxFixedMul()) equals -maxFixedMul() * maxFixedMul()
     * Test multiply(-maxFixedMul(),maxFixedMul()+1) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedMul() public pure returns (int256) {
        return 240615969168004498257251713877715648331380787511296;
    }

    /**
     * @notice Maximum value that can be safely used as a dividend.
     * @dev divide(maxFixedDiv,newFixedFraction(1,fixed1())) = maxInt256().
     * Test maxFixedDiv() equals maxInt256()/fixed1()
     * Test divide(maxFixedDiv(),multiply(mulPrecision(),mulPrecision())) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,multiply(mulPrecision(),mulPrecision())) throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDiv() public pure returns (int256) {
        return 57896044618658097711785492504343953926634992332820282;
    }

    /**
     * @notice Maximum value that can be safely used as a divisor.
     * @dev Test maxFixedDivisor() equals fixed1()*fixed1() - Or 10**(digits()*2)
     * Test divide(10**(digits()*2 + 1),10**(digits()*2)) = returns 10*fixed1()
     * Test divide(10**(digits()*2 + 1),10**(digits()*2 + 1)) = throws
     * Hardcoded to 24 digits.
     */
    function maxFixedDivisor() public pure returns (int256) {
        return 1000000000000000000000000000000000000000000000000;
    }

    /**
     * @notice Converts an int256 to fixed point units, equivalent to multiplying
     * by 10^digits().
     * @dev Test newFixed(0) returns 0
     * Test newFixed(1) returns fixed1()
     * Test newFixed(maxNewFixed()) returns maxNewFixed() * fixed1()
     * Test newFixed(maxNewFixed()+1) fails
     */
    function newFixed(int256 x) public pure returns (int256) {
        require(x <= maxNewFixed());
        require(x >= minNewFixed());
        return x * fixed1();
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this
     * library to a non decimal. All decimal digits will be truncated.
     */
    function fromFixed(int256 x) public pure returns (int256) {
        return x / fixed1();
    }

    /**
     * @notice Converts an int256 which is already in some fixed point
     * representation to a different fixed precision representation.
     * Both the origin and destination precisions must be 38 or less digits.
     * Origin values with a precision higher than the destination precision
     * will be truncated accordingly.
     * @dev
     * Test convertFixed(1,0,0) returns 1;
     * Test convertFixed(1,1,1) returns 1;
     * Test convertFixed(1,1,0) returns 0;
     * Test convertFixed(1,0,1) returns 10;
     * Test convertFixed(10,1,0) returns 1;
     * Test convertFixed(10,0,1) returns 100;
     * Test convertFixed(100,1,0) returns 10;
     * Test convertFixed(100,0,1) returns 1000;
     * Test convertFixed(1000,2,0) returns 10;
     * Test convertFixed(1000,0,2) returns 100000;
     * Test convertFixed(1000,2,1) returns 100;
     * Test convertFixed(1000,1,2) returns 10000;
     * Test convertFixed(maxInt256,1,0) returns maxInt256/10;
     * Test convertFixed(maxInt256,0,1) throws
     * Test convertFixed(maxInt256,38,0) returns maxInt256/(10**38);
     * Test convertFixed(1,0,38) returns 10**38;
     * Test convertFixed(maxInt256,39,0) throws
     * Test convertFixed(1,0,39) throws
     */
    function convertFixed(
        int256 x,
        uint8 _originDigits,
        uint8 _destinationDigits
    ) public pure returns (int256) {
        require(_originDigits <= 38 && _destinationDigits <= 38);

        uint8 decimalDifference;
        if (_originDigits > _destinationDigits) {
            decimalDifference = _originDigits - _destinationDigits;
            return x / (uint128(10)**uint128(decimalDifference));
        } else if (_originDigits < _destinationDigits) {
            decimalDifference = _destinationDigits - _originDigits;
            // Cast uint8 -> uint128 is safe
            // Exponentiation is safe:
            //     _originDigits and _destinationDigits limited to 38 or less
            //     decimalDifference = abs(_destinationDigits - _originDigits)
            //     decimalDifference < 38
            //     10**38 < 2**128-1
            require(x <= maxInt256() / uint128(10)**uint128(decimalDifference));
            require(x >= minInt256() / uint128(10)**uint128(decimalDifference));
            return x * (uint128(10)**uint128(decimalDifference));
        }
        // _originDigits == digits())
        return x;
    }

    /**
     * @notice Converts an int256 which is already in some fixed point
     * representation to that of this library. The _originDigits parameter is the
     * precision of x. Values with a precision higher than FixidityLib.digits()
     * will be truncated accordingly.
     */
    function newFixed(int256 x, uint8 _originDigits) public pure returns (int256) {
        return convertFixed(x, _originDigits, digits());
    }

    /**
     * @notice Converts an int256 in the fixed point representation of this
     * library to a different representation. The _destinationDigits parameter is the
     * precision of the output x. Values with a precision below than
     * FixidityLib.digits() will be truncated accordingly.
     */
    function fromFixed(int256 x, uint8 _destinationDigits) public pure returns (int256) {
        return convertFixed(x, digits(), _destinationDigits);
    }

    /**
     * @notice Converts two int256 representing a fraction to fixed point units,
     * equivalent to multiplying dividend and divisor by 10^digits().
     * @dev
     * Test newFixedFraction(maxFixedDiv()+1,1) fails
     * Test newFixedFraction(1,maxFixedDiv()+1) fails
     * Test newFixedFraction(1,0) fails
     * Test newFixedFraction(0,1) returns 0
     * Test newFixedFraction(1,1) returns fixed1()
     * Test newFixedFraction(maxFixedDiv(),1) returns maxFixedDiv()*fixed1()
     * Test newFixedFraction(1,fixed1()) returns 1
     * Test newFixedFraction(1,fixed1()-1) returns 0
     */
    function newFixedFraction(int256 numerator, int256 denominator) public pure returns (int256) {
        require(numerator <= maxNewFixed());
        require(denominator <= maxNewFixed());
        require(denominator != 0);
        int256 convertedNumerator = newFixed(numerator);
        int256 convertedDenominator = newFixed(denominator);
        return divide(convertedNumerator, convertedDenominator);
    }

    /**
     * @notice Returns the integer part of a fixed point number.
     * @dev
     * Test integer(0) returns 0
     * Test integer(fixed1()) returns fixed1()
     * Test integer(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test integer(-fixed1()) returns -fixed1()
     * Test integer(newFixed(-maxNewFixed())) returns -maxNewFixed()*fixed1()
     */
    function integer(int256 x) public pure returns (int256) {
        return (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Returns the fractional part of a fixed point number.
     * In the case of a negative number the fractional is also negative.
     * @dev
     * Test fractional(0) returns 0
     * Test fractional(fixed1()) returns 0
     * Test fractional(fixed1()-1) returns 10^24-1
     * Test fractional(-fixed1()) returns 0
     * Test fractional(-fixed1()+1) returns -10^24-1
     */
    function fractional(int256 x) public pure returns (int256) {
        return x - (x / fixed1()) * fixed1(); // Can't overflow
    }

    /**
     * @notice Converts to positive if negative.
     * Due to int256 having one more negative number than positive numbers
     * abs(minInt256) reverts.
     * @dev
     * Test abs(0) returns 0
     * Test abs(fixed1()) returns -fixed1()
     * Test abs(-fixed1()) returns fixed1()
     * Test abs(newFixed(maxNewFixed())) returns maxNewFixed()*fixed1()
     * Test abs(newFixed(minNewFixed())) returns -minNewFixed()*fixed1()
     */
    function abs(int256 x) public pure returns (int256) {
        if (x >= 0) {
            return x;
        } else {
            int256 result = -x;
            assert(result > 0);
            return result;
        }
    }

    /**
     * @notice x+y. If any operator is higher than maxFixedAdd() it
     * might overflow.
     * In solidity maxInt256 + 1 = minInt256 and viceversa.
     * @dev
     * Test add(maxFixedAdd(),maxFixedAdd()) returns maxInt256()-1
     * Test add(maxFixedAdd()+1,maxFixedAdd()+1) fails
     * Test add(-maxFixedSub(),-maxFixedSub()) returns minInt256()
     * Test add(-maxFixedSub()-1,-maxFixedSub()-1) fails
     * Test add(maxInt256(),maxInt256()) fails
     * Test add(minInt256(),minInt256()) fails
     */
    function add(int256 x, int256 y) public pure returns (int256) {
        int256 z = x + y;
        if (x > 0 && y > 0) assert(z > x && z > y);
        if (x < 0 && y < 0) assert(z < x && z < y);
        return z;
    }

    /**
     * @notice x-y. You can use add(x,-y) instead.
     * @dev Tests covered by add(x,y)
     */
    function subtract(int256 x, int256 y) public pure returns (int256) {
        return add(x, -y);
    }

    /**
     * @notice x*y. If any of the operators is higher than maxFixedMul() it
     * might overflow.
     * @dev
     * Test multiply(0,0) returns 0
     * Test multiply(maxFixedMul(),0) returns 0
     * Test multiply(0,maxFixedMul()) returns 0
     * Test multiply(maxFixedMul(),fixed1()) returns maxFixedMul()
     * Test multiply(fixed1(),maxFixedMul()) returns maxFixedMul()
     * Test all combinations of (2,-2), (2, 2.5), (2, -2.5) and (0.5, -0.5)
     * Test multiply(fixed1()/mulPrecision(),fixed1()*mulPrecision())
     * Test multiply(maxFixedMul()-1,maxFixedMul()) equals multiply(maxFixedMul(),maxFixedMul()-1)
     * Test multiply(maxFixedMul(),maxFixedMul()) returns maxInt256() // Probably not to the last digits
     * Test multiply(maxFixedMul()+1,maxFixedMul()) fails
     * Test multiply(maxFixedMul(),maxFixedMul()+1) fails
     */
    function multiply(int256 x, int256 y) public pure returns (int256) {
        if (x == 0 || y == 0) return 0;
        if (y == fixed1()) return x;
        if (x == fixed1()) return y;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        int256 x1 = integer(x) / fixed1();
        int256 x2 = fractional(x);
        int256 y1 = integer(y) / fixed1();
        int256 y2 = fractional(y);

        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        int256 x1y1 = x1 * y1;
        if (x1 != 0) assert(x1y1 / x1 == y1); // Overflow x1y1

        // x1y1 needs to be multiplied back by fixed1
        // solium-disable-next-line mixedcase
        int256 fixed_x1y1 = x1y1 * fixed1();
        if (x1y1 != 0) assert(fixed_x1y1 / x1y1 == fixed1()); // Overflow x1y1 * fixed1
        x1y1 = fixed_x1y1;

        int256 x2y1 = x2 * y1;
        if (x2 != 0) assert(x2y1 / x2 == y1); // Overflow x2y1

        int256 x1y2 = x1 * y2;
        if (x1 != 0) assert(x1y2 / x1 == y2); // Overflow x1y2

        x2 = x2 / mulPrecision();
        y2 = y2 / mulPrecision();
        int256 x2y2 = x2 * y2;
        if (x2 != 0) assert(x2y2 / x2 == y2); // Overflow x2y2

        // result = fixed1() * x1 * y1 + x1 * y2 + x2 * y1 + x2 * y2 / fixed1();
        int256 result = x1y1;
        result = add(result, x2y1); // Add checks for overflow
        result = add(result, x1y2); // Add checks for overflow
        result = add(result, x2y2); // Add checks for overflow
        return result;
    }

    /**
     * @notice 1/x
     * @dev
     * Test reciprocal(0) fails
     * Test reciprocal(fixed1()) returns fixed1()
     * Test reciprocal(fixed1()*fixed1()) returns 1 // Testing how the fractional is truncated
     * Test reciprocal(2*fixed1()*fixed1()) returns 0 // Testing how the fractional is truncated
     */
    function reciprocal(int256 x) public pure returns (int256) {
        require(x != 0);
        return (fixed1() * fixed1()) / x; // Can't overflow
    }

    /**
     * @notice x/y. If the dividend is higher than maxFixedDiv() it
     * might overflow. You can use multiply(x,reciprocal(y)) instead.
     * There is a loss of precision on division for the lower mulPrecision() decimals.
     * @dev
     * Test divide(fixed1(),0) fails
     * Test divide(maxFixedDiv(),1) = maxFixedDiv()*(10^digits())
     * Test divide(maxFixedDiv()+1,1) throws
     * Test divide(maxFixedDiv(),maxFixedDiv()) returns fixed1()
     */
    function divide(int256 x, int256 y) public pure returns (int256) {
        if (y == fixed1()) return x;
        require(y != 0);
        require(y <= maxFixedDivisor());
        return multiply(x, reciprocal(y));
    }
}

// SPDX-License-Identifier: APACHE 2.0
pragma solidity 0.6.12;

import "./FixidityLib.sol";

/**
 * @title LogarithmLib
 * @author Gadi Guy, Alberto Cuesta Canada
 * @notice This library extends FixidityLib with logarithm operations.
 * @dev Extracted from https://github.com/CementDAO/Fixidity/blob/master/contracts/LogarithmLib.sol
 */
library LogarithmLib {
    /**
     * @notice This is e in the fixed point units used in this library.
     * @dev 27182818284590452353602874713526624977572470936999595749669676277240766303535/fixed1()
     * Hardcoded to 24 digits.
     */
    function fixedE() public pure returns (int256) {
        return 2718281828459045235360287;
    }

    /**
     * @notice ln(1.5), hardcoded with the comma 24 positions to the right.
     */
    // solium-disable-next-line mixedcase
    function fixedLn1_5() public pure returns (int256) {
        return 405465108108164381978013;
    }

    /**
     * @notice ln(10), hardcoded with the comma 24 positions to the right.
     */
    function fixedLn10() public pure returns (int256) {
        return 2302585092994045684017991;
    }

    /**
     * @notice ln(x)
     * This function has a 1/50 deviation close to ln(-1),
     * 1/maxFixedMul() deviation at fixedE()**2, but diverges to 10x
     * deviation at maxNewFixed().
     * @dev
     * Test ln(0) fails
     * Test ln(-fixed1()) fails
     * Test ln(fixed1()) returns 0
     * Test ln(fixedE()) returns fixed1()
     * Test ln(fixedE()*fixedE()) returns ln(fixedE())+ln(fixedE())
     * Test ln(maxInt256) returns 176752531042786059920093411119162458112
     * Test ln(1) returns -82
     */
    function ln(int256 value) public pure returns (int256) {
        require(value >= 0);
        int256 v = value;
        int256 r = 0;
        while (v <= FixidityLib.fixed1() / 10) {
            v = v * 10;
            r -= fixedLn10();
        }
        while (v >= 10 * FixidityLib.fixed1()) {
            v = v / 10;
            r += fixedLn10();
        }
        while (v < FixidityLib.fixed1()) {
            v = FixidityLib.multiply(v, fixedE());
            r -= FixidityLib.fixed1();
        }
        while (v > fixedE()) {
            v = FixidityLib.divide(v, fixedE());
            r += FixidityLib.fixed1();
        }
        if (v == FixidityLib.fixed1()) {
            return r;
        }
        if (v == fixedE()) {
            return FixidityLib.fixed1() + r;
        }

        v = v - (3 * FixidityLib.fixed1()) / 2;
        r = r + fixedLn1_5();
        int256 m = (FixidityLib.fixed1() * v) / (v + 3 * FixidityLib.fixed1());
        r = r + 2 * m;
        // solium-disable-next-line mixedcase
        int256 m_2 = (m * m) / FixidityLib.fixed1();
        uint8 i = 3;
        while (true) {
            m = (m * m_2) / FixidityLib.fixed1();
            r = r + (2 * m) / int256(i);
            i += 2;
            if (i >= 3 + 2 * FixidityLib.digits()) break;
        }
        return r;
    }

    /**
     * @notice log_b(x).
     * *param int256 b Base in fixed point representation.
     * @dev Tests covered by ln(x) and divide(a,b)
     */
    // solium-disable-next-line mixedcase
    function log_b(int256 b, int256 x) public pure returns (int256) {
        if (b == FixidityLib.fixed1() * 10) return FixidityLib.divide(ln(x), fixedLn10());
        return FixidityLib.divide(ln(x), ln(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IBlackScholes {
    function getCallPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);

    function getPutPrice(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 sigma,
        uint256 time,
        int256 riskFree
    ) external view returns (uint256);
}