/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

// SPDX-License-Identifier: MIT

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

    AggregatorV3Interface public priceFeed;
    address[] public funders;
    address public owner;


    constructor (address _priceFeed) public {
        //address kovan_ethusd = 0x9326BFA02ADD2366b30bacB125260Af641031331;
        // address rinkeby_ethusd = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;

    function fund () public payable {
        int256 minimumUSD = 50;
        int256 minimumETH = minimumUSD * 10 ** 18;
        // if (msg.value <  minimumETH) ...
        // Bug HERE uint256 -> int256 .. need to think in a better solution.
        require(getConversionRate(int256(msg.value)) >= minimumETH, "You need to spend more eth!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public view returns (int256) {
        (,int256 price,,,) = priceFeed.latestRoundData();
        // 18 - decimals() = 10
        return price * 10 ** 10;
    }

    // function getConversionRate2(int256 amount) public view returns (int256) {
    //     (,int256 price,,,) = priceFeed.latestRoundData();

    //     // Fetch decimals
    //     uint8 decimals = priceFeed.decimals();

    //     // Normalize to 18 decimal places (aka converting to WEI)
    //     price = price * 10 ** uint8(18) - decimals;

    //     // In wei
    //     int256 weiAmountInUsd = price * amount;

    //     // In ETH
    //     int256 ethAmountInUsd = weiAmountInUsd / (10 ** 18);

    //     return ethAmountInUsd;
    // }

    function getConversionRate(int256 ethAmount) public view returns (int256) {
        // Get the latest value
        (,int256 price,,,) = priceFeed.latestRoundData();

        // Fetch decimals
        uint8 decimals = priceFeed.decimals();

        // Normalize to 18 decimal places
        price = price * uint128(10) ** (uint8(18) - decimals);
        int256 ethPrice = getPrice();
        int256 ethAmountInUsd = (ethPrice * ethAmount) / (10 ** 18);
        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the bosses");
        _;
    }

    function withdraw() payable onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}