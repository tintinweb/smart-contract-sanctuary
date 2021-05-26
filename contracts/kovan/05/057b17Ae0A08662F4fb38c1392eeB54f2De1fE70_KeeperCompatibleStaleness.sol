/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: KeeperCompatibleInterface

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: KeeperCompatibleStaleness.sol

contract KeeperCompatibleStaleness is KeeperCompatibleInterface {
    
    uint public immutable interval;
    
    mapping(AggregatorV3Interface => bool) public staleFlag;
    
    constructor(uint updateInterval) public {
        interval = updateInterval;
    }
    
    /**
     * Set `upkeepNeeded` to `true` if the Price Feed is stale to indicate that 
     * the keeper should call `performUpkeep`
     * Set `performData` the data needed to pass to the contract when
     * checking for upkeep
     */
    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = checkIfStale(abi.decode(checkData, (AggregatorV3Interface)));
        performData = checkData;
    }

    /**
     * Perform an upkeep that raises a flag to indicate that
     * the Price Feed is stale
     */
    function performUpkeep(bytes calldata performData) external override {
        raiseFlag(abi.decode(performData, (AggregatorV3Interface)));
    }

    /**
     * Check if the Price Feed hasn't been updated for
     * a defined interval
     */
    function checkIfStale(AggregatorV3Interface priceFeed) public view returns (bool) {
        (,,,uint timeStamp,) = priceFeed.latestRoundData();
        return (block.timestamp - timeStamp) > interval;
    }

    /**
     * Set a flag to `true` if the Price Feed is stale
     * and the flag hasn't been raised yet
     */
    function raiseFlag(AggregatorV3Interface priceFeed) public {
        require(checkIfStale(priceFeed), "Not stale");
        require(!staleFlag[priceFeed], "Already flagged");
        staleFlag[priceFeed] = true;
    }
    
    /**
     * Set a flag to `false` if the Price Feed is not stale anymore
     * and the Price Feed is currently flagged
     */
    function lowerFlag(AggregatorV3Interface priceFeed) public {
        require(!checkIfStale(priceFeed), "Still stale");
        require(staleFlag[priceFeed], "Not flagged");
        staleFlag[priceFeed] = false;
    }
}