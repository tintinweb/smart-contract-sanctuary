/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.8.4;

/**
  * @title Compound's InterestRateModel which always returns 0
  * @author Fei Protocol
  */
contract ZeroInterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint, uint, uint) external pure returns (uint) {
      return 0;
    }

    /**
      * @notice Calculates the current supply interest rate per block
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint, uint, uint, uint) external pure returns (uint) {
      return 0;
    }
}