// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmount;
    address[] public funders;
    address public owner;
    AggregatorV3Interface internal priceFeed;

    constructor(address price_feed) {
        priceFeed = AggregatorV3Interface(price_feed);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        //modifiers execute the code written and the code of the function to wich they are attached where the _; is
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        //msg holds info about the interaction
        //msg .sender Ã¨ il caller della function , msg.value Ã¨ il valore di eth allegato alla transaction
        uint256 minimumFundingAmount = 5 * 10**18; // 5$ to wei

        uint256 usdSent = getConversionRate(uint256(msg.value));
        require(usdSent >= minimumFundingAmount, "You need to send more ETH!");
        addressToAmount[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    function getTotalFunded() public view returns (uint256, uint256) {
        uint256 numberOfFunders = funders.length;
        uint256 totalBalance = address(this).balance;
        return (numberOfFunders, totalBalance);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); //price in wei
    }

    function getConversionRate(uint256 _weiValue)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 usdSent = (_weiValue * ethPrice) / 1000000000000000000;
        return usdSent;
    }

    function withdraw() public payable onlyOwner {
        // msg.sender is the caller of the function, .transfer transfers TO the caller, the AMOUNT in eth in the brackets
        payable(owner).transfer(address(this).balance);
        //reset
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }
        funders = new address[](0);
    }

    //392441000000
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