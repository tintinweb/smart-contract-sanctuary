/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



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
    address[] public funders;
    address public owner;

    // constructor() public {
    //     owner = msg.sender;
    // }
    constructor() {
        owner = msg.sender;
    }

    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10**18;

        // if (msg.value < 50) {
        // revert?
        // }
        // 1 Gwei < $50
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
        // what the ETH -> USD conversion rate
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        // (
        // uint80 roundId,
        // int256 answer,
        // uint256 startedAt,
        // uint256 updatedAt,
        // uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000); // optional conversion
        // 4,5719.5869697
    }

    // 1000000000 Wei = 1 Gwei => returns 4555075288910 which then will be 0.000004555075288910; can check by 0.000004555075288910 * 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);

        _;
    }

    function withdraw() public payable onlyOwner {
        // only want the contract admin/owner
        // require msg.sender == owner
        // require(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}