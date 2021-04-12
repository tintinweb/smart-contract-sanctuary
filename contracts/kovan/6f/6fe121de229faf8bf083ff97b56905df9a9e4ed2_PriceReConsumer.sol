/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/PriceConsumerV32.sol

pragma solidity ^0.6.7;


contract PriceConsumerV32 {
    AggregatorV3Interface internal priceFeed;
    
    constructor() public {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }
    
    function getThePrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timestamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// File: contracts/PriceReConsumer.sol

pragma solidity ^0.6.7;


contract PriceReConsumer {
    PriceConsumerV32 private pcv32;
    
    constructor() public {
        pcv32 = PriceConsumerV32(0x903c1a4123dE6804AA6e424Ae0976B40A5Ab2777);
    }
    
    function getThePrice() public view returns (int) {
        int price = pcv32.getThePrice();
        return price;
    }
}