/**
 *Submitted for verification at polygonscan.com on 2021-09-24
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.7;


contract TokenBonds {
    
    
    uint256 internal totalBonds;
    uint256 internal secondsInDay = 86400; // Seconds in 1 day for determining daily ROI %.
    mapping (address => uint256) internal userBonds;
    mapping (address => uint256) internal stakeStartTime;
    mapping (address => bool) internal hasBonds;
    address dev;
    
    
    constructor() {
        dev = msg.sender;
    }
    
    
    function BuyBonds() public payable {
        require(msg.value >= 1 gwei, "Message value must be at least 1 gwei.");
        uint256 devFee = (msg.value / 100) * 5; // devFee is 5% by default.
        payable(dev).transfer(devFee);
        stakeStartTime[msg.sender] = block.timestamp;
        hasBonds[msg.sender] = true;
        totalBonds += userBonds[msg.sender];
        userBonds[msg.sender] += msg.value / BondPrice();
    }
    
    
    function ClaimReward() public {
        uint reward = CalculateReward(msg.sender);
        if (hasBonds[msg.sender]) {
            payable(msg.sender).transfer(reward);
        }
    }
    
    
    function CompoundReward() public {
        uint reward = CalculateReward(msg.sender);
        if (hasBonds[msg.sender]) {
            stakeStartTime[msg.sender] = block.timestamp;
            userBonds[msg.sender] += (reward + (reward/20)) / BondPrice(); // 5% more bonds for compounding than for buying upfront.
        }   
    }
    
    
    function CalculateReward(address _address) internal view returns(uint256) {
        _address = msg.sender;
        uint elapsedTime = block.timestamp - stakeStartTime[_address];
        uint reward = ((address(this).balance/100)*5) * (userBonds[_address]/totalBonds) * (elapsedTime/secondsInDay); // 5% daily by default.
        return reward;
    }
    
    
    function BondPrice() public view returns(uint256) {
        uint baseBondPrice = 1 gwei;
        return baseBondPrice + (address(this).balance / 100000 gwei);
    }
    
    
    function ViewMyBonds() public view returns(uint256) {
        return userBonds[msg.sender];
    }
    
    
    function ViewMyReward() public view returns(uint256) {
        return CalculateReward(msg.sender);
    }
    
    
    function ViewContractBalance() public view returns(uint256) {
        return address(this).balance;   
    }
    
    
    function HowManyBonds(uint256 amount) public view returns(uint256) {
        return amount / BondPrice();
    }
    
    
}