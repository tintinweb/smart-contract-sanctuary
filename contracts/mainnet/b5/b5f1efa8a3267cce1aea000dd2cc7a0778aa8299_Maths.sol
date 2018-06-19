pragma solidity ^0.4.21;

/**
 * @title Maths
 * A library to make working with numbers in Solidity hurt your brain less.
 */
library Maths {
  /**
   * @dev Adds two addends together, returns the sum
   * @param addendA the first addend
   * @param addendB the second addend
   * @return sum the sum of the equation (e.g. addendA + addendB)
   */
  function plus(
    uint256 addendA,
    uint256 addendB
  ) public pure returns (uint256 sum) {
    sum = addendA + addendB;
  }

  /**
   * @dev Subtracts the minuend from the subtrahend, returns the difference
   * @param minuend the minuend
   * @param subtrahend the subtrahend
   * @return difference the difference (e.g. minuend - subtrahend)
   */
  function minus(
    uint256 minuend,
    uint256 subtrahend
  ) public pure returns (uint256 difference) {
    assert(minuend >= subtrahend);
    difference = minuend - subtrahend;
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function mul(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    if (factorA == 0 || factorB == 0) return 0;
    product = factorA * factorB;
    assert(product / factorA == factorB);
  }

  /**
   * @dev Multiplies two factors, returns the product
   * @param factorA the first factor
   * @param factorB the second factor
   * @return product the product of the equation (e.g. factorA * factorB)
   */
  function times(
    uint256 factorA,
    uint256 factorB
  ) public pure returns (uint256 product) {
    return mul(factorA, factorB);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function div(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    quotient = dividend / divisor;
    assert(quotient * divisor == dividend);
  }

  /**
   * @dev Divides the dividend by divisor, returns the truncated quotient
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   */
  function dividedBy(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient) {
    return div(dividend, divisor);
  }

  /**
   * @dev Divides the dividend by divisor, returns the quotient and remainder
   * @param dividend the dividend
   * @param divisor the divisor
   * @return quotient the quotient of the equation (e.g. dividend / divisor)
   * @return remainder the remainder of the equation (e.g. dividend % divisor)
   */
  function divideSafely(
    uint256 dividend,
    uint256 divisor
  ) public pure returns (uint256 quotient, uint256 remainder) {
    quotient = div(dividend, divisor);
    remainder = dividend % divisor;
  }

  /**
   * @dev Returns the lesser of two values.
   * @param a the first value
   * @param b the second value
   * @return result the lesser of the two values
   */
  function min(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a <= b ? a : b;
  }

  /**
   * @dev Returns the greater of two values.
   * @param a the first value
   * @param b the second value
   * @return result the greater of the two values
   */
  function max(
    uint256 a,
    uint256 b
  ) public pure returns (uint256 result) {
    result = a >= b ? a : b;
  }

  /**
   * @dev Determines whether a value is less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isLessThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a < b;
  }

  /**
   * @dev Determines whether a value is equal to or less than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than or equal to b
   */
  function isAtMost(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a <= b;
  }

  /**
   * @dev Determines whether a value is greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is greater than b
   */
  function isGreaterThan(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a > b;
  }

  /**
   * @dev Determines whether a value is equal to or greater than another.
   * @param a the first value
   * @param b the second value
   * @return isTrue whether a is less than b
   */
  function isAtLeast(uint256 a, uint256 b) public pure returns (bool isTrue) {
    isTrue = a >= b;
  }
}