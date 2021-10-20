/**
 *Submitted for verification at BscScan.com on 2021-10-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line

contract NRGProtocol {
    //uint256 Energy_PER_MINERS_PER_SECOND=1;
    uint256 public NRGTIM=43200;//for final version should be seconds in a day.
   
    address public dev=address(0x75053E382513d0514585e913175306B2df3C685a);
    mapping (address => uint256) private nReactors;
    mapping (address => uint256) private userStake;
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
        userStake[msg.sender]+=(msg.value-devFee);
        stakeTimestamp[msg.sender]=block.number;
        nReactors[msg.sender]+=msg.value/reactorPrice;
        hodlingBonus[msg.sender]=1;
        latestActionIsWithdrawal[msg.sender]=false;
    }
   
    function checkEligible(address user) public view returns (bool) {
        if ((stakeTimestamp[user]+waitBlock)<(block.number)){
return true;
} else {
return false;}
    }
   
    function getReward() public {
       
        address payable requestor=payable(msg.sender);
       
        uint256 thisrate=getRate(msg.sender);
        uint256 finalReward = (block.number-stakeTimestamp[msg.sender]/(waitBlock))*(thisrate);
        if ((stakeTimestamp[msg.sender]+waitBlock)<(block.number)){
            if (latestActionIsWithdrawal[msg.sender]==false){
                uint256 rewardWithBonus=((thisrate/1000000000000)*(block.number-stakeTimestamp[msg.sender]/(waitBlock)))+finalReward;
                requestor.transfer(rewardWithBonus);
                latestActionIsWithdrawal[msg.sender]=true;
            } else {
                latestActionIsWithdrawal[msg.sender]=true;
                requestor.transfer(finalReward);

            }
            userStake[msg.sender]=0;
            nReactors[msg.sender]=0;
            hodlingBonus[msg.sender]=0;
        }
        stakeTimestamp[msg.sender]=block.number;
    }
}