/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;



// Part: IExternalOracle

interface IExternalOracle {
  /// @dev Returns the price in terms of ETH for the given token, multiplifed by 2**112.
  function getETHPx(address token) external view returns (uint);
}

// File: MockExternalOracle.sol

contract MockExternalOracle is IExternalOracle {
  mapping(address => uint) public prices;

  function getETHPx(address token) external view override returns (uint) {
    return prices[token];
  }

  function setETHPrice(address token, uint price) external returns (uint) {
    prices[token] = price;
  }
}