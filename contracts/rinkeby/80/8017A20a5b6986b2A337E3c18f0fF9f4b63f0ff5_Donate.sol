// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract Donate {
    mapping(address => uint256) public supporters;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function makeDonation() public payable {
        require(
            isEnough(1, int256(msg.value)),
            "The minimum donation is 1 dollar!"
        );
        supporters[msg.sender] += msg.value;
    }

    function getRatio() public view returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return answer / (10**8);
    }

    function isEnough(int256 minDollars, int256 value)
        public
        view
        returns (bool)
    {
        if (value >= (minDollars * 10**18) / getRatio()) return true;
        return false;
    }

    function withdraw(int256 value) public payable {
        require(
            msg.sender == owner,
            "You must be the owner of the contract in order to withdraw funds!"
        );
        require(
            value <= int256(address(this).balance),
            "This contract has insufficient funds!"
        );
        msg.sender.transfer(uint256(value));
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
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