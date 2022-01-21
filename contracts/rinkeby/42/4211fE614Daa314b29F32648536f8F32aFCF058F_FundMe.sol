/**
 *Submitted for verification at Etherscan.io on 2022-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



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

// File: fundMe.sol

contract FundMe {
    
    AggregatorV3Interface public priceFeed;
    mapping(address => uint256) public addressToAmoundFunded;
    address owner;

    constructor(address _priceFeed) {
        // connect with Chainlink on the right network
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        // set contract's owner
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        // require at least 100 USD of funding
        require(msg.value * getConversionRate(msg.value) >= 100 * 10 ** 18, "You need to send at least 100 USD worth of ETH");
        // map the sender of funds to the value funded
        addressToAmoundFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner payable {
        // transfer all funds in the contract to the contact's owner
        address payable payableOwner = payable(owner);
        payableOwner.transfer(address(this).balance);
    }

    function getEthPrice() public view returns(uint256) {
        // get the ETH price in USD from Chainlink (with 18 decimals)
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10 ** 10);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        // get the USD value of any amount of ETH (wei) sent (with 18 decimals)
        uint256 ethPrice = getEthPrice();
        uint256 usdValue = (ethAmount * ethPrice) / (10 ** 18);
        return usdValue;
    }

}