/**
 *Submitted for verification at polygonscan.com on 2021-12-09
*/

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


interface IChildERC20 {
    /**
    * @dev Create a Chainlink request to retrieve number of locked tokens from Stellar API, find the target
    * data, then multiply by 1000000000000000000 (to remove decimal places from data).
    */
    function requestLockedTokenData() external returns (bytes32 requestId);

    /**
    * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
}

contract ProofOfReserveKeeper is KeeperCompatibleInterface {
    uint public immutable interval;
    uint public lastTimeStamp;
    uint public reserveAddress;
    address _proofOfReserveAddress;
    uint lastSupply = 0;

    constructor(uint updateInterval, address proofOfReserveAddress_) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        _proofOfReserveAddress = proofOfReserveAddress_;
    }

    function checkUpkeep(bytes calldata /* checkData */) external override view returns (bool, bytes memory) {
        uint totalSupply = IChildERC20(_proofOfReserveAddress).totalSupply();
        bool upKeepNeeded = lastSupply != totalSupply && (block.timestamp - lastTimeStamp) > interval;
        return (upKeepNeeded, bytes(""));
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        lastTimeStamp = block.timestamp;
        lastSupply = IChildERC20(_proofOfReserveAddress).totalSupply();
        IChildERC20(_proofOfReserveAddress).requestLockedTokenData();
    }
}