// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol"; //brownie cofig ymal tells where the source code is

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        // When you deploy the contract msg.sender is the owner of the contract.
        owner = msg.sender; // owner is the owner of the contract

        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minUSD = 1 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minUSD * precision) / price;
    }

    function fund() public payable {
        // declared payable can receive ether into the contract.
        // $1
        uint256 minUSD = 1 * 10**18;
        require(
            getConverstionRate(msg.value) >= minUSD,
            "You need to spend more ETH!"
        ); // if msg.value < minUSD revert back money received

        // msg send and value are the key words
        // msg.sender(address) function indicated the sender of the current message or (current call)
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        // what the ETH -> USD conversion rate
    }

    function getVersion() public view returns (uint256) {
        // https://docs.chain.link/docs/ethereum-addresses/

        // --- movded following to constructor for both local and remote
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // --- movded following to constructor for both local and remote
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10);
        // to make things consis with 18 decimal,  answer has 8 decimal, wei has 18 decimal
    }

    // convert wei to usd
    function getConverstionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        // like decorate in python, to change function behaveor
        require(msg.sender == owner, "You are not the contract owner");
        _;
        // run require check, then rest of code as indicated as _;
    }

    // withdraw money from contact
    function withdraw() public payable onlyOwner {
        // only people deploy the contract and withdraw money from the contract
        // require(msg.sender == owner, "You are not the contract owner");

        // 'this' is the address of contract
        msg.sender.transfer(address(this).balance);

        // reset all funders donation to 0
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funderAddress = funders[funderIndex];
            addressToAmountFunded[funderAddress] = 0;
        }
        funders = new address[](0); // reset funders array after withdraw all funds
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