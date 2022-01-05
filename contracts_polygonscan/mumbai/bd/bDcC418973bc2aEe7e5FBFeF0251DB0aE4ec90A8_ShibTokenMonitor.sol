// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface ITokenPriceFeed {
    function latestRoundData() external 
        returns(uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function requestValue() external;
}

/// @title Token Monitor Contract
/// @author jaxcoder
/// @notice Handles triggering the oracle to update the price
/// @dev this only tells the price feed oracle to update the round
contract ShibTokenMonitor is KeeperCompatibleInterface {
    // Interface
    ITokenPriceFeed private _tokenPriceFeed;

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;

    mapping(uint256 => uint256) public answers;

    constructor(uint updateInterval, address priceFeedAddress) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;

      _tokenPriceFeed = ITokenPriceFeed(priceFeedAddress);
    }

    /// @dev determines whether or not to perform the price check
    function checkUpkeep
    (
        bytes calldata checkData
    ) 
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // check the interval to see if we need to check the price
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        
        return (upkeepNeeded, performData);
    }

    /// @dev performs the price check
    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        _tokenPriceFeed.requestValue();
    }   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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