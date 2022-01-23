/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: GPL-3.0

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

// File: fund_me.sol

contract MyFactory {
    mapping(address => int256) public senderAddress;
    address[] public senderAddressArray;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function getConversion(uint256 amount) public view returns (uint256) {
        uint256 _amount = (uint256(getPrice()) * amount) / 1000000000000000000;
        return _amount;
    }

    function fund() public payable {
        int256 sentAmount = (getPrice() * int256(msg.value)) /
            1000000000000000000;
        require(
            sentAmount >= (50 * 10**8),
            "You need to send more ETH to complete this transaction."
        );
        senderAddress[msg.sender] += sentAmount;
        senderAddressArray.push(msg.sender);
    }

    function getPrice() public view returns (int256) {
        AggregatorV3Interface price = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 answer, , , ) = price.latestRoundData();
        return answer;
    }

    function withdraw() public payable {
        require(msg.sender == owner, "Only owner can withdraw!");
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 msgsenderindex = 0;
            msgsenderindex < senderAddressArray.length;
            msgsenderindex++
        ) {
            senderAddress[senderAddressArray[msgsenderindex]] = 0;
        }
    }
}