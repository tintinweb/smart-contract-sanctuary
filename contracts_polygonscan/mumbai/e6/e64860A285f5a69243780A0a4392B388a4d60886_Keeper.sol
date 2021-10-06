/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

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

// File: contracts/interfaces/IProofOfReserve.sol

pragma solidity ^0.8.0;

interface IProofOfReserve {
    /**
    * @dev Create a Chainlink request to retrieve number of locked tokens from Stellar API, find the target
    * data, then multiply by 1000000000000000000 (to remove decimal places from data).
    */
    function requestLockedTokenData() external returns (bytes32 requestId);
}

// File: contracts/Keeper.sol

pragma solidity ^0.8.7;



contract Keeper is KeeperCompatibleInterface {

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public lastTimeStamp;
    address public proofOfReserveAddress = 0x6418C521AF9Fb0374BBEd65b8d244e42F63C32AD;


    constructor(uint updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }

    function checkUpkeep(bytes calldata checkData) public override returns (bool, bytes memory) {
        bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        return (upkeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        IProofOfReserve(proofOfReserveAddress).requestLockedTokenData();
    }
}