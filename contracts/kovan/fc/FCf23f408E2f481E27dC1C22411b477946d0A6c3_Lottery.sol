//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

contract Lottery {
    address payable[] public players;
    uint256 usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;

    constructor(address _priceFeedAddress) {
        usdEntryFee = 5 * (10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function enter() public payable {
        //$5 minimum to enter
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        return usdEntryFee / uint256(price);
    }

    function startLottery() public {}

    function endLottery() public {}
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