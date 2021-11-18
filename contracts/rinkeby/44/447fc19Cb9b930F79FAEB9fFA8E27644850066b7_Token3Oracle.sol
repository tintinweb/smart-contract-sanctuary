// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

contract Token3Oracle {
  uint256 public price;

  constructor(uint256 _price){
    price = _price;
  }

    function setPrice(uint256 _price)external{
      price = _price;
    }

    function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ){
        answer = int256(price);
    }
}