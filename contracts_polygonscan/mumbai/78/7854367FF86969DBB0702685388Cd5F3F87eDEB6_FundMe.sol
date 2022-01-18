// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    // address private proxyEthUsd;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
        // Address came from https://docs.chain.link/docs/ethereum-addresses/
        // proxyEthUsd = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        // Address came from https://docs.chain.link/docs/matic-addresses/
        // proxyEthUsd = 0x0715A7794a1dc8e42615F059dD6e406A6594651A;
    }

    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10 ** 18;
        
        require(getConversionRate(msg.value) >=minimumUSD, "You need to spend more ETH");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }


    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sender is not the owner");
        _;
    }

    function withdraw() payable onlyOwner public {
        uint256 contractBalance = address(this).balance;
        payable(msg.sender).transfer(contractBalance);

        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];

            addressToAmountFunded[funder] = 0;            
        }
        funders = new address[](0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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