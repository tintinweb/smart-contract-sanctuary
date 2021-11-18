// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

contract EthOracle {
  uint256 public price;

  constructor(uint256 _price){
    price = _price*(10**18);
  }

    function setPrice(uint256 _price)external{
      price = _price*(10**18);
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