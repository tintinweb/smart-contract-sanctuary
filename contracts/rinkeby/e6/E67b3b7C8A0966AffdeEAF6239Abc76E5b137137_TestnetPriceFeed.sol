// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title TestnetPriceFeed
 * @dev Store retrieve prices of different assets using a string -> int mapping
 */
contract TestnetPriceFeed {
  mapping(string => uint256) PriceMap;

  function store(string calldata _token, uint256 price) public {
    PriceMap[_token] = price;
  }

  function getPrice(string calldata _token) public view returns (uint256) {
    return PriceMap[_token];
  }
}