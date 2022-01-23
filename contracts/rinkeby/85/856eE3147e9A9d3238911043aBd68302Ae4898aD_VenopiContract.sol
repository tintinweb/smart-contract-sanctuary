// SPDX-License-Indetifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

contract VenopiContract{
    uint256 public amount;
    uint256 public payment_days;
    uint256 public percentage;
    uint256 public amount_paid;
    address public owner;

    constructor(uint256 _amount, uint256 _payment_days, uint256 _percentage) public{
        amount_paid = 0.0;
        amount = _amount;
        payment_days = _payment_days;
        percentage = _percentage;
        owner = msg.sender;
        
    }

    function paidAmount() public view returns(uint256){
        return amount_paid;
    }
    
    function balance() public view returns(uint256){
        
        return amount - amount_paid;
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1000000000000000000;
        return ethAmountInUSD;
    }

    function pay() public payable{
        uint256 minimumPayment = (amount * percentage) / 100;
        require(getConversionRate(msg.value) >= minimumPayment, "You need to spend more ETH!");
        amount_paid = msg.value;
    }

    modifier onlyOwner {
        require((msg.sender == owner), "Not Authorized.");
        
        _;
    }

    function withdraw() payable onlyOwner public{
        msg.sender.transfer(amount_paid);
        amount_paid = 0;
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