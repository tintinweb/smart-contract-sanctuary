/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;


contract ethPool {
    
    event customerDeposit(uint256 amt);
    event rewardsAdded(uint256 amt);
    event customerWithdrawal(uint256 amt);
    
    address private teamAddress;
    uint256 rewardBalance;
    uint256 totalBalance;
    uint256 rewardPerEth;
    uint256 totalRewardPerEth;
    uint multiplier;
    mapping(address=>uint) providers;
    mapping(address=>uint) rewards;

    constructor(){
        teamAddress = msg.sender;
        rewardBalance = 0;
        multiplier = 100000000;
    }


    
    function depositEth() public payable {
        require(msg.value >0,"Deposit amount has to be more than 0");  
        providers[msg.sender] += msg.value;
        rewards[msg.sender] = totalRewardPerEth;
        totalBalance += msg.value;
        emit customerDeposit(msg.value);
    }
    
    function addRewards() public payable {
        require(msg.sender == teamAddress,"Only team can deposit rewards"); 
        require(msg.value > 0,"Deposit amount has to be more than 0");  
        rewardBalance += msg.value;
        rewardPerEth = ((msg.value*multiplier)/totalBalance); 
        totalRewardPerEth += rewardPerEth; 
        emit rewardsAdded(msg.value);
    }
    
    function withdrawEthBalance(uint256 amount) public payable {
        require(amount > 0,"Deposit amount has to be more than 0");  
        require(amount < providers[msg.sender],"Cannot withdraw more than you have");
        uint256 rewardAmount = ((totalRewardPerEth - rewards[msg.sender])*amount/multiplier);
        uint256 withdrawAmount = amount + rewardAmount;
        providers[msg.sender] -= amount;
        totalBalance -= amount;
        rewardBalance-= rewardAmount;
        payable(msg.sender).transfer(withdrawAmount);
        emit customerWithdrawal(withdrawAmount);
    }
    
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }
        
    function getUserBalance(address user) public view returns (uint) {
        return providers[user];
    }
        
    function getRewardBalance() public view returns (uint) {
        return rewardBalance;
    }     
            
            
    function getTotalBalance() public view returns (uint) {
        return totalBalance;
    }    
     	
}