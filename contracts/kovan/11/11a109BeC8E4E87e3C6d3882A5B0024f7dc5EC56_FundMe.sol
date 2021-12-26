/**
 *Submitted for verification at Etherscan.io on 2021-12-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;



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
    AggregatorV3Interface internal priceFeed;

    address[] public funders;
    address public owner;

    uint256 public balanceOfOwner;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        owner = msg.sender;
        balanceOfOwner = address(this).balance;
    }

    mapping(address => uint256) public addressOfFunders;

    function fund() public payable {
        // uint256 fundedAmountInUsd = getConversionRate("wei", msg.value);
        // require(fundedAmountInUsd >= 10, "money too low");
        addressOfFunders[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price / 100000000);
    }

    function getConversionRate(string memory typeOfEth, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 ethPriceInDolz = getLatestPrice();
        if (
            keccak256(abi.encodePacked(typeOfEth)) ==
            keccak256(abi.encodePacked("gwei"))
        ) {
            amount = amount / 100000000;
        } else if (
            keccak256(abi.encodePacked(typeOfEth)) ==
            keccak256(abi.encodePacked("wei"))
        ) {
            amount = amount / 1000000000000000000;
        } else if (
            keccak256(abi.encodePacked(typeOfEth)) ==
            keccak256(abi.encodePacked("eth"))
        ) {
            amount = amount / 1;
        }

        uint256 amountInDolz = amount * ethPriceInDolz;
        return amountInDolz;
    }

    modifier onlyAuthorised() {
        require(msg.sender == owner, "you are not authorized to withdraw");
        _;
    }

    function withdraw() public payable onlyAuthorised {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressOfFunders[funder] = 0;
        }
        funders = new address[](0);
    }
}