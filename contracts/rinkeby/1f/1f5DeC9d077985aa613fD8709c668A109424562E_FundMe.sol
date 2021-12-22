/**
 *Submitted for verification at Etherscan.io on 2021-12-22
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

//Fund is used to accept payment
//1 Eth = 10^9 Gwei = 10^18Wei
//msg.value and msg.sender are keywords in solidity
//Interfaces are used in a contract to tell solidity what funcions are available in another contract.
//Interfaces compile down to ABI
// Application Binary Interface thus is the main point of communication that tells other solidity and other progamming languages what functions are available
//


contract FundMe{
    // using SafeMathChainlink for uint256;
    address public owner;
    constructor() public{
       owner = msg.sender;  //Sets owner to contract creator
    }
    
    
    mapping(address=> uint256) public addressToAmountFunded;
    address[] public funders;
      
      
    function fund() public payable{
        //$50
        uint256 minimumUsd = 50 * 10 ** 18;// convert to wei dollar
        
        require(getConversionRate(msg.value)>=minimumUsd,"You need to spend more eth");
        addressToAmountFunded[msg.sender] +=msg.value;
        funders.push(msg.sender);
        //Get ETH to USD conversion rate using an oracle
    }
    
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
      
          (,int price,,,) =  priceFeed.latestRoundData();
        return uint256(price * 10000000000); //return swei dollar(Divide by 10^18 to get  actual doller value)
        
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsed = ethAmount * ethPrice /1000000000000000000;
        return ethAmountInUsed; //returns wei dollar
    }
    
    //Used to change the behaviour of a function in a declarative way
    modifier onlyOwner{
        require(msg.sender == owner);
        _; //The rest  of the code runs here. can be placed anywhere in the function
    }
    
    function withdraw() payable onlyOwner public {
        //transfer is used to send money from one address to another
        //This function withdraws all funds in contract to owner
        payable(msg.sender).transfer(address(this).balance);
        
        for(uint256 i=0; i<funders.length;i++){
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        
    }
    
    
  
}