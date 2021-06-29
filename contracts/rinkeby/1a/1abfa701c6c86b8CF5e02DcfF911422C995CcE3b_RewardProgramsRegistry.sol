/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: RewardProgramsRegistry.sol

contract RewardProgramsRegistry {
    address[] public rewardPrograms;
    mapping(address => uint256) private rewardProgramIndices;

    address public evmScriptExecutor;

    constructor(address _evmScriptExecutor) {
        evmScriptExecutor = _evmScriptExecutor;
    }

    function addRewardProgram(address _rewardProgram) external {
        require(msg.sender == evmScriptExecutor, "FORBIDDEN");
        require(rewardProgramIndices[_rewardProgram] == 0, "REWARD_PROGRAM_ALREADY_ADDED");

        rewardPrograms.push(_rewardProgram);
        rewardProgramIndices[_rewardProgram] = rewardPrograms.length;
    }

    function removeRewardProgram(address _rewardProgram) external {
        require(msg.sender == evmScriptExecutor, "FORBIDDEN");
        require(rewardProgramIndices[_rewardProgram] > 0, "REWARD_PROGRAM_NOT_FOUND");

        uint256 index = rewardProgramIndices[_rewardProgram] - 1;
        uint256 lastIndex = rewardPrograms.length - 1;

        if (index != lastIndex) {
            address lastRewardProgram = rewardPrograms[lastIndex];
            rewardPrograms[index] = lastRewardProgram;
            rewardProgramIndices[lastRewardProgram] = index + 1;
        }

        rewardPrograms.pop();
        delete rewardProgramIndices[_rewardProgram];
    }

    function isRewardProgram(address _maybeRewardProgram) external view returns (bool) {
        return rewardProgramIndices[_maybeRewardProgram] > 0;
    }

    function getRewardPrograms() external view returns (address[] memory) {
        return rewardPrograms;
    }
}