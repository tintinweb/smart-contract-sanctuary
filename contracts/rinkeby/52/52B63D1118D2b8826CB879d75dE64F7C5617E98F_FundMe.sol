// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol"; //importing from NPM/Github

contract FundMe {
    //    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address payable[] public funders;
    address payable public owner;

    constructor() public {
        owner = payable(msg.sender); //the owner is the person who first deployed the contract
    }

    //function for funding the contract
    function fund() public payable {
        uint256 minimumUSD = 1 * 10**18; //in wei
        //if sb send less than 50 USD worth of ETH the execution will be stopped,
        //the sender will get their money back as well as any unspent gas
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "The amount of ETH you sent didn not meet the minimum amount required!"
        );
        addressToAmountFunded[payable(msg.sender)] += msg.value;
        funders.push(payable(msg.sender));
    }

    modifier onlyOwner() {
        //only the owner can withdraw fund from the contract address
        require(
            payable(msg.sender) == owner,
            "You do not have the authority to withdraw fund from the contract address!"
        );
        _; //run the rest of the code from here!
    }

    //function for withdrawing fund from the contract address
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
        funders = new address payable[](0); //set funders to a new blank address array after the fund has been withdrawn
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
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