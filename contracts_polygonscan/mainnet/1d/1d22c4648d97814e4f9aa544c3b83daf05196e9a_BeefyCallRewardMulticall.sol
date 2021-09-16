/**
 *Submitted for verification at polygonscan.com on 2021-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

interface IStrategy {
    function callReward() external view returns (uint256);
}

pragma solidity >=0.8.4;

contract BeefyCallRewardMulticall {

    struct Result {
        address strategy;
        uint256 reward;
    }

    function callReward(address[] memory strategies) public view returns (uint256[] memory rewards) {
        uint256 reward;
        
        for(uint256 i = 0; i < strategies.length; i++) {
            try IStrategy(strategies[i]).callReward() returns (uint256 _reward) {
                reward = _reward;
            } catch {
                reward = 0;
            }

            rewards[i] = reward;
        }
    }

}