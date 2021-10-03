/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct RewardInfo {
    address rewardToken;
    uint256 stakingRewardsDuration;
    uint256 periodFinish;
    uint256 rewardRate;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    uint256 rewardBalance;
}

interface IMoonpotGateManager {
    
    function rewardTokenLength() external view returns (uint256);
    function rewardInfo(uint256) external view returns (RewardInfo memory);
}

contract MoonpotPrizeEndingMulticall {
    address pots;
    
    constructor() {
        pots = 0x3Fcca8648651E5b974DD6d3e50F61567779772A8;
    }
    
    function getPotsEndingTime (address[] calldata moonpots) external view returns (RewardInfo[] memory) {
        RewardInfo[] memory results = new RewardInfo[](moonpots.length);
        for (uint i = 0; i < moonpots.length; i++) {
            IMoonpotGateManager pot = IMoonpotGateManager(moonpots[i]);
            uint256 potRewardLength = pot.rewardTokenLength();
            
            for (uint j = 0; j < potRewardLength; j++) {
                RewardInfo memory potReward = pot.rewardInfo(j);
                if (pots == potReward.rewardToken) {
                    results[i] = potReward;
                    break;
                }
            }
        }
        
        return results;
    }

}