/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: FundMe.sol

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) addressToAmount;
    address public owner;

    // AggregatorV3Interface public priceFeed;

    constructor() {
        owner = msg.sender;
        // priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
    }

    modifier onlyOwner() {
        owner = msg.sender;
        _;
    }

    function fund() public payable {
        uint256 minimumValue = 100;
        require(msg.value >= minimumValue, "not sufficient funds");
        addressToAmount[msg.sender] += msg.value;
    }

    function withdraw() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    // function getLatestPrice() public view returns (int256) {
    //     (
    //         uint80 roundID,
    //         int256 price,
    //         uint256 startedAt,
    //         uint256 timeStamp,
    //         uint80 answeredInRound
    //     ) = priceFeed.latestRoundData();
    //     return price;
    // }
}