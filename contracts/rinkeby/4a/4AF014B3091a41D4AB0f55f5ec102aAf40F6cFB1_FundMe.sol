/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    constructor() public {
        // the owner will be us because a constructor will run immediately after being beployed
        owner = msg.sender;
    }
    
    function fund() public payable {
        // minimum amount multiplied by 10 to the 18 power because we get it in wei
        uint256 minimumUSD = 50 *10 **18;
        // require that the amount paid is greater that the minimum. will cause a revert if not met
        require(getConversionRate(msg.value)>= minimumUSD, "You need to spend higher than the minimum.");
        addressToAmountFunded[msg.sender] += msg.value;
        // will be redundent if someone funds more than once
        funders.push(msg.sender);
        
        // We want to use USD instead of Eth. How do we convert?
    }
    
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int price,,,
        ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }
    
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
    modifier onlyOwner {
        require(msg.sender==owner, "you are not the owner");
        _;
    }
    
    function withdraw() payable onlyOwner public {
        // withdrawing the entire balance
        msg.sender.transfer(address(this).balance);
        // resetting the funders array to show that each funder has a zero balance
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // resetting array
        funders = new address[](0);
    }
}