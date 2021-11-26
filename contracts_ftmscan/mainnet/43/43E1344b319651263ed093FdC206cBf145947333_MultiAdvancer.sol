// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFarmingPool {
    function advance() external;
}

contract MultiAdvancer {
    function advanceMany(address[] calldata farmingPoolList) external {
        uint256 count = farmingPoolList.length;
        for (uint256 i = 0; i < count; i++) {
            IFarmingPool(farmingPoolList[i]).advance();
        }
    }
}