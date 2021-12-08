//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public address2AmountFunded;
    address public owner;
    address[] public funders;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        owner = msg.sender;
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getLatestPrice() public view returns (int256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function getConversionRate(uint256 ethAmount) public view returns (int256) {
        int256 ethPrice = getLatestPrice();
        int256 ethAmount2USD = ethPrice * ethPrice;
        return ethAmount2USD;
    }

    function fund() public payable {
        int256 minPay = 50 * 10**16;
        require(getConversionRate(msg.value) > minPay, "Minimo de 50");
        address2AmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //msg.sender.transfer(address (this).balance);
        payable(address(msg.sender)).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            address2AmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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