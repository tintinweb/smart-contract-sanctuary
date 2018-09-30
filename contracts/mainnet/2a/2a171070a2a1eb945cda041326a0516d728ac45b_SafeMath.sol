pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @notice Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @notice Multiplies two numbers, throws on overflow.
  * @param a Multiplier
  * @param b Multiplicand
  * @return {"result" : "Returns product"}
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 result) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "Error: Unsafe multiplication operation!");
    return c;
  }

  /**
  * @notice Integer division of two numbers, truncating the quotient.
  * @param a Dividend
  * @param b Divisor
  * @return {"result" : "Returns quotient"}
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // @dev require(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // @dev require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @notice Subtracts two numbers, throws on underflow.
  * @param a Subtrahend
  * @param b Minuend
  * @return {"result" : "Returns difference"}
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256 result) {
    // @dev throws on overflow (i.e. if subtrahend is greater than minuend)
    require(b <= a, "Error: Unsafe subtraction operation!");
    return a - b;
  }

  /**
  * @notice Adds two numbers, throws on overflow.
  * @param a First addend
  * @param b Second addend
  * @return {"result" : "Returns summation"}
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 result) {
    uint256 c = a + b;
    require(c >= a, "Error: Unsafe addition operation!");
    return c;
  }
}