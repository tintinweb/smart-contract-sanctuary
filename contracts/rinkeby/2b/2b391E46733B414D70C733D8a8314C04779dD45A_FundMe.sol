// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunding;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * (10**18);
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to send more ETH!"
        );
        addressToAmountFunding[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * (10**10));
    }

    // this funcion converts ETH to USD value
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // Divide by 10^18 because we want price for ether not gwei
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / (10**18);
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        // Reset all funders to 0 funds
        for (
            uint256 funder_index = 0;
            funder_index < funders.length;
            funder_index++
        ) {
            addressToAmountFunding[funders[funder_index]] = 0;
        }
        // Initialize the funders array to a new empty array
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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