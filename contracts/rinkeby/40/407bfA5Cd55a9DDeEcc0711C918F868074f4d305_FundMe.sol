/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public addToAmountFunded;
    uint256 public minusd = 50 * 10**18;
    address[] funders;
    address public ownner;

    constructor() public {
        ownner = msg.sender;
    }

    function fund() public payable {
        require(
            convertionrate(msg.value) >= minusd,
            "U need to send more ETH!"
        );
        funders.push(msg.sender);
        addToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface agg = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return agg.decimals();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface agg = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        (, int256 answer, , , ) = agg.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function convertionrate(uint256 ethamount) public view returns (uint256) {
        return (getPrice() * ethamount) / 1000000000000000000;
    }

    modifier onlyownner() {
        require(msg.sender == ownner, "you are not wonner");
        _;
    }

    function withdraw() public payable onlyownner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 fundersindex = 0;
            fundersindex < funders.length;
            fundersindex++
        ) {
            addToAmountFunded[funders[fundersindex]] = 0;
        }

        funders = new address[](0);
    }
}