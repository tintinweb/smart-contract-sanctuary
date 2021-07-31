/**
 *Submitted for verification at polygonscan.com on 2021-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract test {
    
    struct PoolInfo {
        address strat; // Strategy address that will auto compound want tokens
        uint lastTimeHarvest;
        bool active;
        uint last5MinProfit;
        uint totalProfit;
    }
    
    PoolInfo[] public poolInfo;
    mapping(uint => PoolInfo) private pid;

    function addAddress(address _address) external {
        uint length = poolInfo.length; 
        pid[length] = PoolInfo(_address, 2154542445, true, 15447845454, 215465465465464666524);
        poolInfo.push(pid[length]);
    }
    
    function removeAddress(uint _pid) external {
        poolInfo[_pid].active = false;
    }
    
    function getStrat(uint _pid) public view returns (address) {
        return poolInfo[_pid].strat;
    }
    
    function getLastHarvested(uint _pid) public view returns (uint256) {
        return poolInfo[_pid].lastTimeHarvest;
    }
    
    function getLastProfit(uint _pid) public view returns (uint256) {
        return poolInfo[_pid].last5MinProfit;
    }
    
    function getTotalProfit(uint _pid) public view returns (uint256) {
        return poolInfo[_pid].totalProfit;
    }

}