/**
 *Submitted for verification at Etherscan.io on 2021-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MemeFarmingProtocol {
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    
    mapping (address => uint256) public lastClaim;
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public tokenPrice;

    constructor() {
        name = "Meme Farming Protocol";
        symbol = "MEP";
        totalSupply = 0;
        tokenPrice = 1000000000;

        balanceOf[address(this)] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= (_value + 1)); // always left 1 token
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function buyTokens() payable public returns (uint amount) {
        amount = msg.value / tokenPrice;
        
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        
        emit Transfer(address(this), msg.sender, amount);
        
        lastClaim[msg.sender] = block.timestamp;

        return amount;
    }

    function sellTokens(uint amount) public returns (uint revenue) {
        require(balanceOf[msg.sender] >= (amount + 1)); // always left 1 token
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        revenue = amount * tokenPrice;
        
        require(payable(address(msg.sender)).send(revenue));
        
        emit Transfer(msg.sender, address(this), amount);

        return revenue;
    }
    
    function claimFaucet() public returns (uint revenue) {
        require(balanceOf[msg.sender] == 0); // only to zero accounts
        
        revenue = 1000000;
        
        balanceOf[msg.sender] += revenue;
        totalSupply += revenue;
        lastClaim[msg.sender] = block.timestamp;
        
        emit Transfer(address(this), msg.sender, revenue);
        
        return revenue;
    }
    
    function estimateYield() view public returns(uint revenue) {
        uint256 claimPeriod = 43200; // 12 hours in seconds
        uint256 rewardPercent = (balanceOf[msg.sender] / totalSupply) * 100; // % of total supply
        
        if (rewardPercent == 0) {
            rewardPercent = 1; // 1% by default
        }
        
        revenue = ((block.timestamp - lastClaim[msg.sender]) / claimPeriod) * ((balanceOf[msg.sender] * rewardPercent) / 100);
        
        return revenue;
    }
    
    function farmYield() public returns (uint revenue) {
        uint minStake = 1000000; // 1M tokens
        require(balanceOf[msg.sender] >= minStake);
        
        uint256 claimPeriod = 43200; // 12 hours in seconds
        require(block.timestamp - lastClaim[msg.sender] > claimPeriod);
        
        uint256 rewardPercent = (balanceOf[msg.sender] / totalSupply) * 100; // % of total supply
        
        if (rewardPercent == 0) {
            rewardPercent = 1; // 1% by default
        }
        
        revenue = ((block.timestamp - lastClaim[msg.sender]) / claimPeriod) * ((balanceOf[msg.sender] * rewardPercent) / 100);
        
        balanceOf[msg.sender] += revenue;
        totalSupply += revenue;
        lastClaim[msg.sender] = block.timestamp;
        
        emit Transfer(address(this), msg.sender, revenue);
        
        return revenue;
    }
}