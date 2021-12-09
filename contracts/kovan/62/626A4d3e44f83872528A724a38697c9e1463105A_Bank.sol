/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



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

// File: Bank.sol

contract Bank {
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) private addressToValue;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    function paying() public payable {
        addressToValue[msg.sender] += msg.value;
    }

    function getValue() public view returns (uint256) {
        return addressToValue[msg.sender];
    }

    function getContractMoney() public view returns (uint256) {
        return address(this).balance;
    }

    function getEthInUsd() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function withdraw(uint256 _value) public payable {
        if (_value > addressToValue[msg.sender]) {
            revert("You dont have so match money");
        }
        payable(msg.sender).send(_value);
    }
}