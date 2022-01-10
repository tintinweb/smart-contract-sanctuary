// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "./AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public owner;
    uint256 public fundLimit = 5 ether;
    uint256 public totalFund = 0;
    uint256 public timeLimit = 0;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
        timeLimit = block.timestamp + 50000;
    }

    function fund() public payable {
        uint256 mimimumUSD = 100 * 10**18;
        require(block.timestamp < timeLimit, "funding period over");
        require(
            getConversionRate(msg.value) > mimimumUSD,
            "You need to spend more ETH!"
        );
        if (addressToAmountFunded[msg.sender] == 0) {
            funders.push(msg.sender);
        }
        addressToAmountFunded[msg.sender] += msg.value;

        totalFund += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 100 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;

        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public onlyOwner {
        require(
            block.timestamp > timeLimit,
            "Cant withraw, time still pending "
        );
        require(
            address(this).balance >= fundLimit - 1000,
            "Not enough eth to withdraw"
        );

        payable(msg.sender).transfer(address(this).balance);

        // for (
        //     uint256 funderIndex = 0;
        //     funderIndex < funders.length;
        //     funderIndex++
        // ) {
        //     address funder = funders[funderIndex];
        //     addressToAmountFunded[funder] = 0;
        // }
        // funders = new address[](0);
    }

    function returnFund() public {
        uint256 amount = addressToAmountFunded[msg.sender];
        require(amount > 0, "Not enough funds to withdraw");
        require(
            block.timestamp > timeLimit,
            "Cant withraw, time still pending "
        );
        require(
            address(this).balance < 2 * 10**18,
            "Fund goals done, Caannot withdraw"
        );

        payable(msg.sender).transfer(amount);
        addressToAmountFunded[msg.sender] = 0;
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