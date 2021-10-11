/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



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

// Contract to accept some type of payment
contract FundMe {
    AggregatorV3Interface internal priceFeed;

    address owner;

    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     *
     */
    constructor() public {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    // "payable" means that this function can be use to pay for things
    // Specifically, payable with ETH/Ethereum
    function fund() public payable {
        uint256 minimumUsd = 50 * 10**18; // USD converted to Gwei

        require(
            getConversionRate(msg.value) >= minimumUsd,
            "You need to spend more ETH!"
        ); // Checks the "truethyness" of the condition

        // msg.sender = address who initiate / run the contract
        // msg.value = the amount that the address used to pay
        addressToAmountFunded[msg.sender] += msg.value; // wei will be use as msg.value
        funders.push(msg.sender);
    }

    // used to add prerequisite to a function
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the contract owner!");
        _; // Run the code after the require
    }

    // This will withdraw all the funds from your address
    function withdraw() public payable onlyOwner {
        // .transfer() is used to transfer ETH/s from one address to another
        // accepts one parameter
        payable(msg.sender).transfer(address(this).balance); // address(this) refers to the address of the contract (FundMe)

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; // Store an address to variable

            addressToAmountFunded[funder] = 0; // Reset the msg.value of a specific msg.sender
        }

        funders = new address[](0); // Resets the value of the array
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price * 10000000000;
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = uint256(getLatestPrice());
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }
}