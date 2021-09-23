/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;



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

// Part: PriceFeed

contract PriceFeed {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Rinkeby Nework
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
    }

    /**
     * Returns the latest price
     * Price from Chainlink is with implied decimal of 8
     * Return price has been adjusted by 10 ** 10 to make this consistent with wei/Ether definition

     */

    // this function will generate warning as this should be a pure function
    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10**10);

        // hardcode a value for testing .... (EHT/USD = 2650.00)
        // return uint256(265000000000 * 10**10);
    }
}

// File: FundMe.sol

contract FundMe {
    address public owner;
    mapping(address => uint256) public addressToFundMap;
    address[] public funders;
    PriceFeed internal pf;
    uint8 internal constant MIN_FUND = 50; // minimum amount for fund in USD

    constructor() public {
        owner = msg.sender;
        pf = new PriceFeed();
    }

    function fund() public payable {
        require(msg.sender != owner, "Owner cannot contribute fund!");
        require(
            (msg.value / 10**18) * (pf.getPrice() / 10**18) >= MIN_FUND,
            "Fund is less than minimum"
        );
        if (addressToFundMap[msg.sender] == 0) {
            funders.push(msg.sender); // only add new funder
        }
        addressToFundMap[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        // if you want to clear the map :
        for (uint256 i; i < funders.length; i++) {
            addressToFundMap[funders[i]] = 0;
        }

        // if you want to clear the array of funders :
        funders = new address[](0);
    }
}