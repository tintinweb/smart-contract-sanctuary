// SPDX-License-Identifier: None
pragma solidity ^0.7.4;

interface Iblacksmith {
  function getPoolList() external view returns (address[] memory);
  function pools(address _lpToken) external view returns (uint256 weight, uint256 accRewardsPerToken, uint256 lastUpdatedAt);
  function updatePool(address _lpToken) external;
  function updatePools(uint256 _start, uint256 _end) external;
}

contract UpdateBlacksmithPools {
  Iblacksmith public blacksmith;

  constructor (address _blacksmith) {
    blacksmith = Iblacksmith(_blacksmith);
  }

  function viewPoolsToBeUpdated(uint256 minimumMins) external view returns (address[] memory) {
    address[] memory poolList = blacksmith.getPoolList();
    address[] memory toBeUpdated = new address[](poolList.length);
    uint256 counter = 0;
    for (uint256 i = 0; i < poolList.length; i++) {
      (uint256 weight, , uint256 lastUpdatedAt) = blacksmith.pools(poolList[i]);
      uint256 timePassed = (block.timestamp - lastUpdatedAt) / 60;
      if (weight > 0 && timePassed >= minimumMins) {
        toBeUpdated[counter] = poolList[i];
        counter++;
      }
    }
    return toBeUpdated;
  }

  /// @notice update pools with passed list
  function updateList(address[] calldata poolList) external {
    for (uint256 i = 0; i < poolList.length; i++) {
      blacksmith.updatePool(poolList[i]);
    }
  }

  /// @notice update any pool that is older than 30 mins
  function update() external {
    address[] memory poolList = blacksmith.getPoolList();
    for (uint256 i = 0; i < poolList.length; i++) {
      (uint256 weight, , uint256 lastUpdatedAt) = blacksmith.pools(poolList[i]);
      uint256 timePassed = (block.timestamp - lastUpdatedAt) / 60;
      if (weight > 0 && timePassed >= 30) {
        blacksmith.updatePool(poolList[i]);
      }
    }
  }

  /// @notice update any pool that is older than passed minimum time passed
  function updateMins(uint256 minTimePassed) external {
    address[] memory poolList = blacksmith.getPoolList();
    for (uint256 i = 0; i < poolList.length; i++) {
      (uint256 weight, , uint256 lastUpdatedAt) = blacksmith.pools(poolList[i]);
      uint256 timePassed = (block.timestamp - lastUpdatedAt) / 60;
      if (weight > 0 && timePassed >= minTimePassed) {
        blacksmith.updatePool(poolList[i]);
      }
    }
  }
}

