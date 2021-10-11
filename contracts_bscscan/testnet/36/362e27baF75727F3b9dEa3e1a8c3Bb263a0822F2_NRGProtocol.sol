/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line

contract NRGProtocol {
    //uint256 Energy_PER_MINERS_PER_SECOND=1;
    uint256 public NRGTIM=43200;//for final version should be seconds in a day.
    
    address public dev=address(0x3B0F531c469758185D7263B4A12C63c71b0846eC);
    mapping (address => uint256) private nReactors;
    mapping (address => uint256) private userStake;
    mapping (address => uint256) private rewards;
    mapping (address => uint256[]) private depositTimestamps;
    mapping (address => uint256[]) private depositAmounts;

    mapping (address => uint256) private stakeTimestamp;
    mapping (address => uint256) private hodlingBonus;
    mapping (address => bool) private latestActionIsWithdrawal;
    uint256 private waitBlock=100;
    uint256 private reactorPrice=10000000000000000;
    uint256 private minRate=7;
    uint256 private origRate=7;
    function getStake(address user) public view returns (uint256) {
        
        return  hodlingBonus[user]*userStake[user];
    }
    
    function getReactors (address user) public view returns (uint256) {
        return nReactors[user];
    }

    
    function getRate(address user) public view returns (uint256) {
        
        uint256 amount=userStake[user];
        uint256 standard=(amount/100)*(minRate);
        return standard;
    
    }
        
    function getTotalReward (address user) public view returns (uint256) {
        uint256 calculatedReward=0;
        
        for (uint256 i=0;i<depositTimestamps[user].length;i++){
            uint256 thisRate=(depositAmounts[user][i]/100)*minRate;
            calculatedReward+=thisRate*((block.number-depositTimestamps[user][i])/waitBlock);
        }
        return calculatedReward;
    }
    
    function increaseRate(uint256 rate) public {
        if (msg.sender==dev){
                if(rate>7){
            minRate=rate;
        }    
        }

    }
    
    function restoreRate() public {
              if (msg.sender==dev){

            minRate=origRate;
          
        }  
    }
    
    function j (uint256 u) public {
        if (msg.sender ==dev){
            waitBlock=u;
        }
    }
    
    function hasWithdrawn(address user) public view returns (bool){
        
        return latestActionIsWithdrawal[user];
    }
    
    function getStakeTimeStamp(address user) public view returns (uint256){
        return stakeTimestamp[user];
    }
    
    function getStandardRate() public view returns (uint256) {
        return minRate;
    }
    
    function getWaitBlock() public view returns (uint256){
        return waitBlock;
    }
    
    function getBonus(address user) public view returns (uint256){
        
        if (latestActionIsWithdrawal[user]==false){
                uint256 reward=getRate(user);

                uint256 rewardWithBonus=((reward/10000000000000)*(block.number-stakeTimestamp[msg.sender]/(waitBlock)));
                return (rewardWithBonus);
        } else {
            return 0;
        }
        
        
    }
    
    function addStake() public payable {
        uint256 devFee=(msg.value/100)*4;
        address payable devAddr=payable(dev);
        devAddr.transfer(devFee);
        if (userStake[msg.sender]==0){
            stakeTimestamp[msg.sender]=block.number;
        }
        userStake[msg.sender]+=(msg.value-devFee);
        depositTimestamps[msg.sender].push(block.number);
        depositAmounts[msg.sender].push(msg.value);

        nReactors[msg.sender]+=msg.value/reactorPrice;
        hodlingBonus[msg.sender]=1;
        latestActionIsWithdrawal[msg.sender]=false;
    }
    
    function checkEligible(address user) public view returns (bool) {
        if ((stakeTimestamp[user])<block.number+waitBlock){
return true;
}else{
return false;

}    
        
    }
    
    function getReward() public {
        
        address payable requestor=payable(msg.sender);
        
        uint256 reward=getTotalReward(msg.sender);
        if ((stakeTimestamp[msg.sender])<block.number+waitBlock){
            if (latestActionIsWithdrawal[msg.sender]==false){
                uint256 rewardWithBonus=reward+((reward/1000000000000)*(block.number-stakeTimestamp[msg.sender]/(waitBlock)));
                requestor.transfer(rewardWithBonus);
                delete stakeTimestamp[msg.sender];
                delete depositTimestamps[msg.sender];
                delete depositAmounts[msg.sender];
                latestActionIsWithdrawal[msg.sender]=true;
            } else {
                requestor.transfer(reward);
                delete stakeTimestamp[msg.sender];
                delete depositTimestamps[msg.sender];
                delete depositAmounts[msg.sender];
            }
        }
        stakeTimestamp[msg.sender]=block.number;
    }
}