// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function fund() public payable {
        uint256 minimumUSD = 5 * 10**18; // Convert to Wei
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You must send a minimum of $5."
        );

        // msg.sender   : sender of the function call
        // msg.value    : how much they sent
        addressToAmountFunded[msg.sender] += msg.value;

        // this contract now owns whatever funds have been sent
        funders.push(msg.sender);
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
        return uint256(answer); // Answer contains 8 decimals ( $4,103.88947859 = 410388947859 )
    }

    // 1 ETH = 1000000000 Gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 100000000;
        return ethAmountInUSD;
        // 18 decimals ( 0.000004103889478590 )
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not allowed to withdraw because you are not the owner of this contract."
        );
        _; // run rest of code
    }

    function withdraw() public payable onlyOwner {
        // this: current contract
        // balance: balance in ETH of specified address
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
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