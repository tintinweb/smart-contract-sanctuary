// SPDX-License-Identifier: MIT
// 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

pragma solidity ^0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    uint256 currentAmount;
    address public owner;
    uint256 answer;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    function fundMe() public payable {
        uint256 minimumUSD = 50 * 10**18;
        // Make sure that the amount sent by user must be greater than 50 USD
        // But both the amount sent by user and 50 USD are in wei units.
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );
        // addressToAmountFunded[msg.sender] = address(msg.sender).balance - msg.value;
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // The current version of this priceFeed will be returned.
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // The address in this method is the price feed address of ETH/USD
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
        /* answer holds the currrent value of USD that corresponds to ETH (in GWEI), i.e,
         2,482.55877123 USD = 1 ETH
         248255877123 GWEI = 2,482.55877123 USD

        answer stores 248255877123 GWEI

        answer * 10000000000 = 2482558771230000000000
        i.e, = 2482558771230000000000 WEI = 2,482.55877123 USD

         Because we want our return value to be in WEI, we multiply answer by 10000000000 
         */
    }

    function getConversionRate(uint256 etherAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        return (etherAmount * ethPrice) / 1000000000000000000;

        // Output: 2533894899860

        /*
      Note that solidity does not return number with decimal point. So, The actual value is this;
      0.000002533894899860 dollars

      /what solidity does is that it will return the dollar value in wei.

      */
    }

    function getEtherAmount() public view returns (uint256) {
        return currentAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ETH can only be withdrawn by the owner");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // initializing the address array
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