//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";



contract Fund_Me {
    
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    
    constructor() public{
        //msg.sender is who deploys this contract
        owner = msg.sender;
    }
    
    function fund() public payable {
        //msg.sender is the person paying the contract, the contract can retain an ETH balance
        addressToAmountFunded[msg.sender] += msg.value;
        
        uint256 minimumUSD = 1 * 10 ** 18;
        
        require(getConversionUSD(msg.value) >= minimumUSD, "you need to spend mo-money");
        //what is the ETH -> USD conversion rate?
        funders.push(msg.sender);
    }
    
    
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,)
         =priceFeed.latestRoundData();
        return uint256(answer * 100000000); 
    }
    
    function getConversionUSD(uint256 ethAmount) public view returns (uint256){
        
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ethPrice * ethAmount / 10000000000000000;
        return ethAmountInUSD;
    }
    
    function withdraw() payable onlyOwner public {
        //msg.sender is the withdraw requester, but it is required that it is the owner
        msg.sender.transfer(address(this).balance);
        
        //for loop example
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "you need to be the person who deployed the contract");
        //means run the require first, then run the rest of the code
        _;
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