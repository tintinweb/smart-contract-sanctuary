// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

//anytime you want to interact with an already deployed smart contract you will need an ABI
// Interfaces compile down to an ABI
//Always need an ABI to interact with a contract

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;


    //when you are using payable functions, you should consider value field in deploy
    //it tells you how much ethereum, wei, gwei you want to sell.
    function fund() public payable {
        //msg.sender is the sender of the func call
        //msg.value is the value of how much they sender
        //they are generic
        addressToAmountFunded [msg.sender] += msg.value;

    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface  priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // (uint80 roundID, 
        // int price,
        // uint startedAt,
        // uint timeStamp,
        // uint80 answeredInRound)
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
        //3113.61077442
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount);
        return ethAmountInUSD;

    }
}

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