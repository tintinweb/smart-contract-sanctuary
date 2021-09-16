// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Investment{
    
    //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e is rinkeby address
    AggregatorV3Interface pricefeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    
    mapping(address=>uint) addressAmountFunded;
    address[] fundedAddress;

    address owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    function fundMe() public payable{
        
       //Funding minimum of 100 dollors
       uint minimumUSD = 100 * 10 ** 18;
       
       require(converthETHToUSD(msg.value) >= minimumUSD, "Funding number minimum amount is USD100");

       addressAmountFunded[msg.sender] += msg.value;
       fundedAddress.push(msg.sender);
    }
    
    
    function getFundedAddressAmount(address _fundAddress) view public returns(uint){
        return addressAmountFunded[_fundAddress];
    } 
    
    
    function getChainLinkABIVersion() view public returns(uint){
        return pricefeed.version();
    }
    
    
    function getChainLinkUsdDecimal() view public returns(uint){
        return pricefeed.decimals();
    }
    
    
    function getEthPriceInUsd() view public returns(uint){
        (,int256 answer,,,) = pricefeed.latestRoundData();
        return (uint256(answer) * (10 ** (18 - getChainLinkUsdDecimal())));
    }
    
    
    function converthETHToUSD(uint _amountOfEthInWei) public view returns(uint){
        uint256 ethInUsd = ((getEthPriceInUsd() * _amountOfEthInWei) /  (10 ** 18));
        return ethInUsd;
    }
    
    
    modifier onlyOwner(){
        require(owner == msg.sender, "You are not the owner of the contract");
        _;
    }
    
    function withdraw() public onlyOwner{
        
        payable(msg.sender).transfer(address(this).balance);
        
        
        //update the addressAmountFunded
        for(uint i=0; i<fundedAddress.length; i++){
            addressAmountFunded[fundedAddress[i]] = 0;
        }
        
        fundedAddress = new address[](0);
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}