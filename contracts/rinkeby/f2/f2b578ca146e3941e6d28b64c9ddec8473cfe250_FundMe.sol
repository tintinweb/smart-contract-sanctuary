/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

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

// File: contracts/FundMe.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract FundMe{

    address addressForWisthdraw=0x2223ec329437C4eDC1B0F9F5679428C25a5cd4c1;

    //https://eth-converter.com/
    //1eth = 1000000000 gwei
    //uint256 internal divide = 1000000000 * 1000000000;
    uint256 internal toWei = 10 ** 18;

    mapping(address=> uint256) public addressToAmountFunded;

    error NotEnoughEther();

    function fund() public payable{
        // 50$
        uint256 minimumUSD = 50 * toWei;
        if(getConversionRate(msg.value) < minimumUSD) revert NotEnoughEther();
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint amount = addressToAmountFunded[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        addressToAmountFunded[msg.sender] = 0;
        payable(addressForWisthdraw).transfer(amount);
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
         (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // what the ETH => USD conversion rate ?
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / toWei;
        return ethAmountInUsd;
    }
}