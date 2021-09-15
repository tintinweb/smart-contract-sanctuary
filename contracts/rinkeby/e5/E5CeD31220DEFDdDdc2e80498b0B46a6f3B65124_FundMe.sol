/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    
    
    
    address payable owner;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    
    modifier onlyOwner {
       require(msg.sender == owner, "Only the owner may withdraw.");
       _;
    }
    
    // modifier adequateFunds {
    //     require(getConversionRate(msg.value) >= minUSD, "Not enough Eth")
    //     _;
    // }
    
    
    function fund() public payable {
        
        
        // $50 - set amount to this
        uint256 minUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minUSD, "Not enough Eth");
        
        addressToAmountFunded[msg.sender] += msg.value; 
        funders.push(msg.sender);
        
        //what the ETH -> USD value is
        
        
    }
    
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface currentPrice = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 answer,,,) = currentPrice.latestRoundData();
        return uint256(answer * 10000000000);
    }
    
    
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }
    
    function withdrawFunds() payable onlyOwner public {
        owner.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex ++ ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
            
        }
        
        funders = new address[](0);
    }
    
}