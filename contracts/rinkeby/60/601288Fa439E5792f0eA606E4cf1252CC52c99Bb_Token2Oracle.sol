// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

contract Token2Oracle{
  uint256 public price;

  constructor(uint256 _price){
    price = _price * 10 ** decimals;
  }

    uint8 public decimals = 18; 

    function setPrice(uint256 _price)external{
      price = _price * 10 ** decimals;
    }

    function latestRoundData() external view returns (
      uint80 roundId,
      int answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ){
        answer = int(price);
    }
}