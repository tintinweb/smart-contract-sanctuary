//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface priceFeed;
    uint256 minFundAmountUSD = 50;
    uint256 decimalLength = 10**8;
    uint256 paddingLength = 10**12;
    uint256 ethToWei = 10**18;
    uint256 ethToGWei = 10**9;
    mapping(address => uint256) public addressToFundAmount;
    address owner;
    address[] funders;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        owner = msg.sender;
    }

    function fundMe() public payable {
        require(
            convertWeiToUSD(msg.value) >=
                minFundAmountUSD * decimalLength * paddingLength,
            "Minimum fund amount is not reached!"
        );
        addressToFundAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function convertWeiToUSD(uint256 weiAmount) public view returns (uint256) {
        return (weiAmount * getConversionRate()) / ethToWei;
    }

    function getConversionRate() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer) * paddingLength;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner of this contract!");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        reset();
    }

    function reset() internal {
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFundAmount[funders[i]] = 0;
        }
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