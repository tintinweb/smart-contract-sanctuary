/**
 *Submitted for verification at Etherscan.io on 2021-12-06
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

// File: fund.sol

contract fund {
    struct info {
        address funderaddress;
        uint256 fund_amount;
    }
    address owner;

    constructor() {
        owner = msg.sender;
    }

    info[] public info_array;

    uint256 public totalfund;

    address ethAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

    mapping(address => uint256) public Fundupdater;

    function Fund() public payable {
        require(msg.value < getPrice(ethAddress));
        info_array.push(info(msg.sender, msg.value));
        totalfund += msg.value;

        Fundupdater[msg.sender] += msg.value;
    }

    function getPrice(address _address) public view returns (uint256) {
        AggregatorV3Interface eth_price = AggregatorV3Interface(_address);
        (, int256 answer, , , ) = eth_price.latestRoundData();
        return uint256(answer * 10000000000);
    }

    modifier onlyowner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }
}