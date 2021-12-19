/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

/**
 *Submitted by Amin Mirkouei for verification at BscScan.com on 12/19/2021
*/

/**
  
    Renewable & Environmental Decisions (RED) Token
   
    Our research focuses on the sustainable design and manufacturing, cyber-physical control and optimization, 
    and operations research across food-energy-water systems, particularly renewable fuels, green chemicals, 
    and rare earth elements. Our project team aims to maintain many research opportunities that can positively impact 
    all segments of food-energy-water systems (FEWS). In brief, we have been working and planning to undertake more 
    innovative research in the following Research Thrusts:
    Thrust 1. Renewable Materials and Energy Production from Various Waste Streams
    Thrust 2. Precision Agriculture, Soil-Plant Health Improvement, and Food Processing
    Thrust 3. Sustainable Aquaculture and Water Treatment
        
    Raised funds will go to the development of renewable materials and sustainable technologies to address 
    food-energy-water systems on low-income communities.

    Tokenomics
    Initial Supply 10,000,000,000
    20% to help develop Renewable & Environmental Decisions (RED) & Marketing
    2% Distributed to holders
    10% Added to liquidity

 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

contract RED {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000000 * 10 ** 18;
    string public name = "Renewable & Environmental Decisions (RED)";
    string public symbol = "RED";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}