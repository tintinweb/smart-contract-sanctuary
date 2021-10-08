/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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
    address public owner;
    address[] public funders;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function fund() public payable {
        uint256 minUsd = 1; //50 * 10 ** 18; // in wei
        require(getConversionRate(msg.value) >= minUsd, "You need to spend more eth."); // second param is for revert message. revert sends money back to user and any unspent gas. 
        // msg is info about the person calling a contract or transaction
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
    
    function getVersion() public view returns(uint256) {
        // need ABI (address) of any interface you want to use in code. 
        // calling a contract that is of this interface type. the contract is deployed at below address.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }
    
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // convert gwei to wei
    }
    
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // wei to ether
        return ethAmountInUsd;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You're not the owner"); // run require statement
        _; // run rest of the code
    }
    
    function withdraw() payable onlyOwner public {
        msg.sender.transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
    
}