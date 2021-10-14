// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakeInterestRateModel {

  function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public returns(uint256) {

    return 1000000000000;
  }

  function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa) public returns(uint256) {

    return 1000000000000;
  }

}