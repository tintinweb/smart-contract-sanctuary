// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

contract FakePriceOracleProxy {

  function getUnderlyingPrice(address cToken) public returns(uint256) {

    return 10;
  }

}