/**
 *Submitted for verification at polygonscan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IStrategy {

    function lastHarvest() external view returns (uint256);
    
}

pragma solidity ^0.8.4;

contract BeefyLastHarvestMulticall {

    function getLastHarvests(address[] calldata strategies) external view returns (uint256[] memory) {
        uint256[] memory lastHarvests = new uint256[](strategies.length);

        for (uint256 i = 0; i < strategies.length; i++) {
            lastHarvests[i] = IStrategy(strategies[i]).lastHarvest();
        }

        return lastHarvests;
    }
}