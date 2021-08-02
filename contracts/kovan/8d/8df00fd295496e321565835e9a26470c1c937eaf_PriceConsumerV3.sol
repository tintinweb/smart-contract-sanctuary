/**
 *Submitted for verification at Etherscan.io on 2021-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

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

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

contract PriceConsumerV3 is KeeperCompatibleInterface {
    AggregatorV3Interface internal priceFeed;

    // public counter variable
    uint256 public counter;

    // use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable interval;
    uint256 public lastTimeStamp;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );

        // ChainLink keepers
        interval = 60;
        lastTimeStamp = block.timestamp;

        counter = 0;
    }

    function getETHPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getETHHistoricalPrice(uint80 roundsBack)
        public
        view
        returns (uint256, int256)
    {
        (uint80 roundId, , , , ) = priceFeed.latestRoundData();
        uint80 historicalRoundId = roundId - roundsBack;
        (, int256 price, , uint256 timeStamp, ) = priceFeed.getRoundData(
            historicalRoundId
        );
        require(timeStamp > 0, "Round not complete");
        return (timeStamp, price);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;

        performData;
    }
}