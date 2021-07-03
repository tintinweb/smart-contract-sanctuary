/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
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
// File: oracle.sol
pragma solidity 0.6.12;
interface Oracle {
    function setPrice() external;
    function getPrice() external view returns(int);
}
contract oracle {
    AggregatorV3Interface internal priceFeed;
    constructor() public {
        priceFeed=AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    }
    int public oneTokenPrice;
    function setPrice() public {
        (, int price, , ,) = priceFeed.latestRoundData();
            oneTokenPrice=price;
    }
    function getPrice() public view returns(int) {
        return oneTokenPrice;
    }
}