/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;



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

//import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

//We want this contract to accept some type of payment

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address owner;

    //constructor - gets called when contract is deployed, immediately
    constructor() public {
        // Will get called as contract is deployed
        owner = msg.sender;
    }

    //payable keyword - this function can be used to pay for things.
    function fund() public payable {
        //Set minimum payable to $50 dollars
        uint256 minimumUSD = 50 * 10**18; //Don't forget we are using decimal places here

        // Like an if statement
        // Will check truthiness, if false, will revert the transaction
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!!!"
        );

        //msg.sender returns an address of the person making the function call
        // msg.value is the value sent
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    //Can run code automaticall
    //Auto condition
    modifier onlyOwner() {
        //Require msg.sender = owner
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //msg.sender calls the function
        //Transfer balance (rest) of funds to ourselves through address(this)
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            addressToAmountFunded[funders[funderIndex]] = 0;
        }

        funders = new address[](0);
    }

    function getDescription() public view returns (string memory) {
        return
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
                .description();
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
                .version();
    }

    function getDecimals() public view returns (uint8) {
        return
            AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
                .decimals();
    }

    //Let's accept ETH in terms of USD
    //Let's find ETH -> USD Conversion rate
    //We can use CHAIN LINK to get this external data. Modular decentralized oracle infrastructure.
    function getLatestPrice() public view returns (uint256) {
        //Establish feed to rinkby test net
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );

        (, int256 price, , , ) = priceFeed.latestRoundData();

        //Will return price with 8 decimals
        // Note that WEI has 18 decimals so let's convert
        return uint256(price * 10000000000);
    }

    //Convert some amount of WEI to USD
    // Default input
    //The inpute would be 1 ETH, which would get converted to USD
    function getConversionRate(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        //1 ETH = 10^18 WEI
        uint256 ethPrice = getLatestPrice(); //Return USD / 1 ETH to 18 decimals

        //The weiAmount should be reported by 18 decimal places so we must divide.
        uint256 ethAmountInUsd = ((ethPrice * weiAmount) / 1000000000000000000); // Will return to 18 decimal places

        //The number returned will have 18 decimal places
        return ethAmountInUsd;
    }
}