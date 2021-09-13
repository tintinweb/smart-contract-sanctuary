pragma solidity ^0.8.0;

import "./IOtherPunksConfiguration.sol";

contract OtherPunksConfiguration is IOtherPunksConfiguration {
    uint88 public constant hardDifficultyTarget = 5731203885580;
    uint256 public constant hardDifficultyTargetDeadline = 13940346; // ~December 31st 2021
    mapping(uint32 => uint88) public difficultyTargets;

    constructor() {
        difficultyTargets[0] = 0x10d1bb46ccf3ab000;
        difficultyTargets[100] = 0x8f863e4991a5800;
        difficultyTargets[500] = 5731203885580;
        difficultyTargets[2000] = 1146240777116;
        difficultyTargets[3000] = 573120388558;
        difficultyTargets[4000] = 191040129519;
        difficultyTargets[6000] = 57312038855;
        difficultyTargets[10000] = 16631;
    }

    function getDifficultyTargetAtIndex(uint32 index)
        external
        view
        override
        returns (uint88)
    {
        return difficultyTargets[index];
    }

    function getHardDifficultyTarget() external pure override returns (uint88) {
        return hardDifficultyTarget;
    }

    function getHardDifficultyBlockNumberDeadline()
        external
        pure
        override
        returns (uint256)
    {
        return hardDifficultyTargetDeadline;
    }

    function getBlockNumber() external view override returns (uint256) {
        return block.number;
    }

    function getBlockHash(uint256 blockNumber)
        external
        view
        override
        returns (uint256)
    {
        return uint256(blockhash(blockNumber));
    }
}