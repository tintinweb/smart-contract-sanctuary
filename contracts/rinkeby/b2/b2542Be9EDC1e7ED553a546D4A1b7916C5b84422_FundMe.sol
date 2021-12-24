// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    // address payable public owner;
    address public owner;

    mapping(address => uint256) public addrToFunds;

    address[] public funders;

    // constructor() payable {
    //     owner = payable(msg.sender);
    // }

    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        addrToFunds[msg.sender] += (msg.value) ;
        funders.push(msg.sender);
        // how to convert eth to usd?

        // 50$
        uint256 minUsd = 50 * (10 ** 10);
        require(getConversionRate(msg.value) >= minUsd, "you need to spend more eth!"); // will revert
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * (10 ** 8)); //4,053.79080711
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethpr = getPrice();
        uint256 ethInUsd = (ethpr * ethAmount)  / (10 ** 18);
        return ethInUsd; // 4,053.790807
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // function withdraw() payable public {
    //     // get the amount of Ether stored in this contract
    //     uint amount = address(this).balance;

    //     // send all Ether to owner
    //     // Owner can receive Ether since the address of owner is payable
    //     (bool success, ) = owner.call{value: amount}("");
    //     require(success, "Failed to send Ether");
    // }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 fIndex = 0;fIndex < funders.length; fIndex++) {
            address funder = funders[fIndex];
            addrToFunds[funder] = 0;
        }
        funders = new address[](0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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