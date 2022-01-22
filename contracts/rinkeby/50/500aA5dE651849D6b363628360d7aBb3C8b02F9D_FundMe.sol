// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //NOTE: public visibility specifier unnecessary when using compile but complains on "Final argument must be a dict of transaction parameters that " using brownie run
    constructor() {
        address _priceFeed = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        priceFeed = AggregatorV3Interface(_priceFeed); //ASK: How did we know we had to pass the priceFeed for the constructor?
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18; //ASK: why multiply with 10^18?, min 50 ether?
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ether"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPriceWithoutDecimals() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //was price for wei / (10 ** 8)
        uint8 decimals = priceFeed.decimals();
        //NOTE: typecasting needed
        return (uint256(price) * 10**decimals);
        //Assumption is that the latestRoundData value is the USD value for the ether with 10 ** - decimal places
    }

    //REM: rememnber the uinque nature of this being
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPriceInWei = getPriceWithoutDecimals(); //This should be for the highest denomination of eth 10**18
        uint256 ethAmountInUsd = (ethPriceInWei * ethAmount) /
            1000000000000000000;
        return ethAmountInUsd;
    }

    //Don't know the use case for this one
    function getEntranceFee() public returns (uint256) {
        // minimum usd
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPriceWithoutDecimals();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //NOTE: compiler setting to payable
        payable(msg.sender).transfer(address(this).balance); //Remember address(this).balance
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            addressToAmountFunded[funder] = 0;
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