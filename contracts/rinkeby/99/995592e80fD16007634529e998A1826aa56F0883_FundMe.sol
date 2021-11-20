// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFound;
    address public owner;
    address[] public funders;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can withdraw balance!");
        _;
    }

    function fund() public payable {
        uint256 minimumUsd = 50 * (10**18); // usd in 18 int decimals

        // msg.value is ether in wei (1e18 value)
        require(
            weiToUsd18Digits(msg.value) >= minimumUsd,
            "You need pay USD 50 (in ETHER) or more!"
        );
        addressToAmountFound[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        resetFunders();
    }

    function resetFunders() private {
        for (uint256 i = 0; i < funders.length; i++) {
            addressToAmountFound[funders[i]] = 0;
        }
        funders = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        // https://docs.chain.link/docs/ethereum-addresses/
        address priceAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceAddress);
        return priceFeed.version();
    }

    function getEtherPriceInUsd() public view returns (uint256) {
        address priceAddress = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceAddress);

        (, int256 answer, , , ) = priceFeed.latestRoundData(); // usd in 8 int digits

        return uint256(answer * 10000000000); // usd in 18 int digits
    }

    function weiToUsd18Digits(uint256 weiAmount) public view returns (uint256) {
        uint256 oneWeiUdsPrice = getEtherPriceInUsd(); // 1 usd in 18 decimals (wei like)
        uint256 weiAmountInUsd = (oneWeiUdsPrice * weiAmount) / (10**18); // div for normalize in 1e18

        return weiAmountInUsd;
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