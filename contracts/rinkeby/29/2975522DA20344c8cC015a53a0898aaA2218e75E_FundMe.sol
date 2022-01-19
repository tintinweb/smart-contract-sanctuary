/**
 *Submitted for verification at Etherscan.io on 2022-01-19
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

contract FundMe {
    mapping(address => uint256) public addressToAmount;
    address[] public funders;

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10**10);
    }

    function conversion(uint256 ethAmount) public returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 10**18;
        return ethAmountInUSD;
    }

    function fund() public payable {
        uint256 minUSD = 50 * 10**18;
        require(conversion(msg.value) >= minUSD, "Spend More ETH!");
        addressToAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    address payable public owner;

    constructor() public {
        //Constructor is called at the very beginning
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Wait a minute, who are YOU?");
        _;
    }

    function withdraw() public payable onlyOwner {
        owner.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmount[funder] = 0;
        }
        funders = new address[](0);
    }
}