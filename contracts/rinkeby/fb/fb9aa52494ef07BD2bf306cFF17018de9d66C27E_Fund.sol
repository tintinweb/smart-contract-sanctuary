// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract Fund {

    mapping(address => uint256) private addressToFunding;
    address[] public funders;
    address public owner;

    //contructor
    constructor() public {
        owner = msg.sender;
    }

    //Payable functions are functions were the sender can send currency 
    //msg.sender and msg.value are predefined variables. 
    //msg.sender refers to the address of the sender while msg.value refers to the amount sent
    function fundMe() public payable {       
        uint minimum = 1 * (10 ** 18);
        require(getEthToUsd(msg.value) >= minimum, "Value lower than minimum required threshold");
        addressToFunding[msg.sender] += msg.value;
        funders.push(msg.sender); 
    }

    function checkBalance() public view returns (uint256) {
        return addressToFunding[msg.sender];
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //https://docs.chain.link/docs/ethereum-addresses/
        return priceFeed.version();
    }
    
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    function getEthToUsd(uint256 amount) public view returns (uint256) {
        uint256 ethToUsdRate = getPrice();
        uint256 convertedAmt = ethToUsdRate * amount / (10**9);
        return convertedAmt;
    }

    function withdrawAll() public payable {
        require((msg.sender == owner), "Unauthorized Transaction: You are not the owner of this contract");
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFunding[funders[i]] = 0;
        }
    }

    modifier onlyOwner {    //Modifiers change the way a function operates
        require(owner == msg.sender, "Unauthorized Transaction: You are not the owner of this contract");
        _;                  //The _ symbol represents that all other operations will occurs after this symbol
    }

    function withdraw(uint256 amount) public onlyOwner payable {
        //require(owner == msg.sender, "Unauthorized Transaction: You are not the owner of this contract");
        require(amount <= address(this).balance, "Error: Insufficient balance for withdrawal");
        msg.sender.transfer(amount);
        addressToFunding[msg.sender] -= amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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