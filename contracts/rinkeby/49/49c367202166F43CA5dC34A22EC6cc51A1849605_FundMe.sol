pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    //we wont be able to loop over the keys to dynamically access all values, so we also store keys in an array
    address[] addresses;
    mapping(address => uint256) public addressAmountFunded;
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18; //10 to the power 18 as we're working in wei
        require(conversion(msg.value) >= minimumUSD, "value to low, need 50 bucks worth");

        addressAmountFunded[msg.sender] += msg.value;
        addresses.push(msg.sender);
    }
    
    function resetBalance() public {
        for(uint256 i = 0; i < addresses.length; i++) {
            addressAmountFunded[addresses[i]] = 0;
        }
        addresses = new address[](0);
    }
    
    function getVersion() public view returns(uint256) {
        //there are hundreds of aggregators and they all implement this interface
        //we have to grab the contract we need which is eth -> usd - https://docs.chain.link/docs/ethereum-addresses/
        //we grab the contract by supplying the memory address or ABI
        AggregatorV3Interface agg = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return agg.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface agg = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        //commas here are just variables we're ignoring that are returned in the tuple
        ( ,int256 answer,,, ) = agg.latestRoundData();
        //we like to have anything to do with eth at 18 decimal places so we work with wei
        //as the 'answer' is to 8 decimal places (the api documentation told us that), we only have to multiply 
        //the below by 10 decimals
        return uint256(answer * 10000000000);
    }
    
    function conversion(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        //18 decimals
        return (ethPrice * ethAmount) / 1000000000000000000;
        // if we send 1000000000 gwei (1 eth)
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    //modifier are almost like middleware or rules to apply
    //the _; is a bit more like calling next()
    //could also put _; above the require statement and it would execute the function first
    modifier onlyOwner {
        //owner set in constructor
        require(msg.sender == owner);
        _;
    }
    
    //see above for onlyOwner
    function withdraw() public onlyOwner payable {
        msg.sender.transfer(address(this).balance);
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