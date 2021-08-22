/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;



// Part: IBetaInterestModel

interface IBetaInterestModel {
  /// @dev Returns the initial interest rate per year (times 1e18).
  function initialRate() external view returns (uint);

  /// @dev Returns the next interest rate for the market.
  /// @param prevRate The current interest rate.
  /// @param totalAvailable The current available liquidity.
  /// @param totalLoan The current outstanding loan.
  /// @param timePast The time past since last interest rate rebase in seconds.
  function getNextInterestRate(
    uint prevRate,
    uint totalAvailable,
    uint totalLoan,
    uint timePast
  ) external view returns (uint);
}

// Part: OpenZeppelin/[email protected]/Math

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: BetaInterestModelV1.sol

contract BetaInterestModelV1 is IBetaInterestModel {
  uint public immutable override initialRate;
  uint public immutable minRate;
  uint public immutable maxRate;
  uint public immutable adjustRate; // between 0 and 1e18, the higher the more aggressive

  constructor(
    uint _initialRate,
    uint _minRate,
    uint _maxRate,
    uint _adjustRate
  ) {
    require(_minRate < _maxRate, 'constructor/bad-min-max-rate');
    require(_adjustRate < 1e18, 'constructor/bad-adjust-rate');
    initialRate = _initialRate;
    minRate = _minRate;
    maxRate = _maxRate;
    adjustRate = _adjustRate;
  }

  /// @dev Returns the next interest rate for the market.
  /// @param prevRate The current interest rate.
  /// @param totalAvailable The current available liquidity.
  /// @param totalLoan The current outstanding loan.
  /// @param timePassed The time passed since last interest rate rebase in seconds.
  /// @notice At utilization 0-50%, the interest rate will decrease at half-per-day rate
  ///         At utilization 50-70%, the interest rate will decrease linearly from 0 to half-per-day rate
  ///         At utilization 70-80%, the interest rate will stay the same.
  ///         At utilization 80-100%, the interest rate will increase linearly from 0 to twice-per-day rate.
  function getNextInterestRate(
    uint prevRate,
    uint totalAvailable,
    uint totalLoan,
    uint timePassed
  ) external view override returns (uint) {
    uint totalLiquidity = totalAvailable + totalLoan;
    if (totalLiquidity == 0) {
      return prevRate;
    }
    uint utilRate = (totalLoan * 1e18) / totalLiquidity;
    uint cappedtimePassed = Math.min(timePassed, 1 days);
    uint multRate;
    if (utilRate < 0.5e18) {
      // utilization 0-50%, decrease at half-per-day rate
      multRate = 1e18 - (adjustRate * cappedtimePassed) / 1 days;
    } else if (utilRate < 0.7e18) {
      // utilization 50-70%, decrease linearly from 0 to half-per-day rate, depending on how far the utilization is from 70%
      uint downScale = (0.7e18 - utilRate) * 5; // *5 is equivalent to /0.2
      multRate = 1e18 - (adjustRate * downScale * cappedtimePassed) / 1 days / 1e18;
    } else if (utilRate < 0.8e18) {
      // utilization 70-80%, stay the same
      multRate = 1e18;
    } else {
      // utilization 80-100%, increase linearly from 0 to twice-per-day rate, depending on how far the utilization is from 80%
      uint upScale = (utilRate - 0.8e18) * 5; // *5 is equivalent to /0.2
      uint upMaxRate = 1e36 / (1e18 - adjustRate) - 1e18;
      multRate = 1e18 + (upMaxRate * upScale * cappedtimePassed) / 1 days / 1e18;
    }
    uint targetRate = (prevRate * multRate) / 1e18;
    return Math.min(Math.max(targetRate, minRate), maxRate);
  }
}