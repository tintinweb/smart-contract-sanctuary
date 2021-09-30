/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    mapping(address => uint256) public account;
    address priceFeedAddress;

    constructor(address _priceFeedAddress) {
        priceFeedAddress = _priceFeedAddress;
    }

    function fund() public payable {
        require(
            getConvertedToUSD(msg.value) >= (50 * (10**18)),
            "Minimum value id 50USD worth ETH is required"
        );
        account[msg.sender] += msg.value;
    }

    function getConvertedToUSD(uint256 _paidPrice)
        public
        view
        returns (uint256)
    {
        return (getCurrentprice() * _paidPrice) / (10**18);
    }

    function getCurrentprice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * 10**10;
    }
}