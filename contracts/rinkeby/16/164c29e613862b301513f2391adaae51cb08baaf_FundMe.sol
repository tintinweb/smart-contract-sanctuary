/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 < 0.9.0;

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

contract FundMe {
    
    //Map for addresses to values of txns
    mapping(address => uint256) public addressToAmountFunded;
    
    /*
    Keyword "payable", this function can be used to pay eth, payable with eth.
    These are red buttons in deployment ui
    This function will keep track of who is paying
    
    "msg" is a INHERENT keyword that is included with every transaction, its a global variable
    In it are various fxns:
      
    msg.data — The complete calldata which is a non-modifiable, non-persistent area where function arguments are stored and behave mostly like memory
    msg.gas — Returns the available gas remaining for a current transaction (you can learn more about gas in Ethereum here)
    msg.sig — The first four bytes of the calldata for a function that specifies the function to be called (i.e., it’s function identifier)
    msg.value — The amount of wei sent with a message to a contract (wei is a denomination of ETH)
    msg.sender — The address of the sender. If its a contract it will be a contract address 
    
    The reason why wei and gwei exist is because decimals dont work in solidity...so we have to return a value thats multiplied by ten to some number
    
    There are no chainlink nodes on simulated JS VMS, so you need to be on a testnet when using chainlink
    */
    function fund() public payable {
        
        addressToAmountFunded[msg.sender] += msg.value;
        
        //what the ETH -> USD conversion rate
        
    }
    
    function getVersion() public view returns (uint256) {
        
        //We have a contract that has these functions defined on the interface located at this address
        //REMEMBER: You are using an address you got from rinkeby, that means you need to deploy on an injected web3 with wallet on rinkeby
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        return priceFeed.version();
        
    }
    
    function getPrice() public view returns (uint256) {
        
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        //Since latestRoundData returns a tuple you have to set up a tuple
        //If a value is returned and u dont need it, just leave it as a blank
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        
        //Once the tuple is set up and filled you can directly reference the vars within it
        return uint256(answer);
        
    }
    
    
}