/**
 *Submitted for verification at polygonscan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IStrategy {
    function multiHarvest() external;
    function callReward() external view returns (uint256);
}

pragma solidity >=0.8.4;

contract BeefyMultiHarvest {

    function harvest (address[] memory strategies) external {
        
        require(msg.sender == tx.origin, "!EOA");

        for (uint256 i = 0; i < strategies.length; i++) {
            try IStrategy(strategies[i]).multiHarvest() {} catch {}
        }
    }
    
    function callReward (address[] memory strategies) external view returns (uint256[] memory rewards) {
        rewards = new uint256[](strategies.length);
        uint256 reward;
        
        for (uint256 i = 0; i < strategies.length; i++) {
            try IStrategy(strategies[i]).callReward() returns (uint256 _reward) {
                reward = _reward;
            } catch {
                reward = 0;
            }

            rewards[i] = reward;
        }
    }

}