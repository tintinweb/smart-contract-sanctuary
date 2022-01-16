// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

/*
ABI - Application Binary Inteface

The ABI tells solidity and other programming languages houw it can interact with another contract

Interface compile to an ABI
*/

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    // AggregatorV3Interface public priceFeed;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // set min value
        uint256 minValueUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minValueUSD,
            "You need to spend More ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        // What the ETH to USD conversion rate is
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    // Get the price in WEI
    // Second OPT is is USD
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10**10);
        // return uint256(answer / (10 ** 8));
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        // Price in WEI of One ETH
        uint256 ethPrice = getPrice();
        // One ETH in WEI multiplied by the amount of eth passed
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (10**18);
        // uint256 ethAmountInUsd = ethPrice * ethAmount;
        return ethAmountInUsd;
    }

    // Changes the behaviour of a function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAddress = funders[funderIndex];
            addressToAmountFunded[funderAddress] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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