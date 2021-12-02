//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract GetPrice{

    address public priceFeedAddress;
    AggregatorV3Interface internal priceFeed;

    int public price;

    constructor(address _priceFeedAddress){
        priceFeedAddress = _priceFeedAddress;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,price,,,) = priceFeed.latestRoundData();
    }


    function hasPriceIncreased() external view returns(bool hasIt){
        (,int newPrice,,,) = priceFeed.latestRoundData();
        if(newPrice > price){
            hasIt = true;
        }else if(price >= newPrice){
            hasIt = false;
        }
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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