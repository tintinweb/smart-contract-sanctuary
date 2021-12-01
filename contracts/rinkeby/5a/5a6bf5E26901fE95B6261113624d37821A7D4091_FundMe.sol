// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    // using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmtFunded;
    address public owner;
    address[] public funders;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        // this is currently contract
        // require msg.sender is the owner
        require(msg.sender == owner, "You are not the owner of this contract");
        _;
    }

    function fund() public payable {
        // $50
        uint256 minUSD = 50 * 10**18;
        require(
            getConversationRate(msg.value) >= minUSD,
            "$50 min is required"
        );

        addressToAmtFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        // what eth -> usd conversion rate is
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmtFunded[funder] = 0;
        }
        // reset
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        // price feed rinkbey testnet chain
        // eth-usd rinkbey 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // address a = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        // 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // pad to 18 decimals wei, so add 10
        return uint256(answer * 10000000000);
    }

    // 10000000000
    function getConversationRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // to the 18th
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
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