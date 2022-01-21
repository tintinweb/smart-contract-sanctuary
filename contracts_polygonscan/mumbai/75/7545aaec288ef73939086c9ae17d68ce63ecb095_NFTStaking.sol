/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.7;

contract NFTStaking {
    uint public blockNumber;
    bytes32 public blockHashNow;
    bytes32 public blockHashPrevious;
    uint public blockTimeStamp;

    mapping (address => uint256) public stakeTime;
    uint256 public rewardRatio;

    function getBlockData() public {
        blockNumber = block.number;
        blockHashNow = blockhash(blockNumber);
        blockHashPrevious = blockhash(blockNumber - 1);
        blockTimeStamp = block.timestamp;
    }    

    function setRewardRatio(uint256 _rewardRatio) public {
        rewardRatio = _rewardRatio;
    }

    function setStakeTime(address _NFTaddress) public {
        getBlockData();
        stakeTime[_NFTaddress] = blockTimeStamp;
    }

    function getNFTTime(address _NFTaddress) public view returns (uint256) {
        return stakeTime[_NFTaddress];
    }

    function calculateReward(address _NFTaddress) public returns (uint256, uint256) {
        getBlockData();
        return((blockTimeStamp - stakeTime[_NFTaddress]),(blockTimeStamp - stakeTime[_NFTaddress]) * rewardRatio);
    }

}