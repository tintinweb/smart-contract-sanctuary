/**
 *Submitted for verification at Etherscan.io on 2021-10-02
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
    

// track funders
address[] public funders;

    address public owner;

    
    // adding an owner via a constructor
    constructor() public {
        owner = msg.sender;
    }
    
    
    // only owner modifier
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // accept payable
    
    
    // who send us stuff 
    
    mapping (address => uint256) public addressToFunderMap;
    
    // check for min USD
    function isBelowThreshold(uint256 _value, uint256 threshold) public returns (bool) {
        return _value <= threshold;
    } 
    
    function fund() public payable {
        require(getConversionRate(msg.value) >= 50 * 10 ** 18, "Spend more ETH");
        // msg - function
        // sender - caller address 
        // value - value send
        addressToFunderMap[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    // only owner
    function withdraw() payable onlyOwner  public {
        // require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
        // reset everyone balance
        for(uint256 funderIndex = 0; funderIndex > funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToFunderMap[funder] = 0;
            // funders.pop();
        }
        
        delete funders;
    }
    
    
    // getting external data with Chainlink
    // price data
    
    // ETH to USD conversion rate
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // convert  to  ETH
        return uint256(answer * 10000000000);
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountUsd = (ethPrice * ethAmount) / 10000000000000000000 ;
        return ethAmountUsd;
    }
    
    function destroy() onlyOwner public {
    selfdestruct(payable(owner));
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(payable(_recipient));
  }
}