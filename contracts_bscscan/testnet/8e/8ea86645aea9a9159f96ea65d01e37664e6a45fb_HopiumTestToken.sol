/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT

// Current Version of solidity
pragma solidity ^0.8.2;

// Main coin information
contract HopiumTestToken {
    // Initialize addresses mapping
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    // Token Supply and Info
    uint public totalSupply = 1000 * 10 ** 18;
    string public name = "Hopium Test Token";
    string public symbol = "HTT";
    uint public decimals = 18;
    uint public lastDayTime = 1630713600;
    address[] public usersTapped;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    // Event executed only once upon deploying the contract
    constructor() {
        // Give initial faucet tap to address to start contract
        balances[msg.sender] = totalSupply;
    }
    
    // Check balances
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    // Transfering coins function
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
    
    function mint(address to) public returns (bool) {
        // Initialize wallet checking variables
        bool userCheck = false;
        // Check if daily Faucet list needs to be reset
        if (block.timestamp >= lastDayTime + 86400) {
            lastDayTime = lastDayTime + 86400;
            delete usersTapped;
        }
        // Check if wallet is on daily Facuet list
        for (uint i = 0; i < usersTapped.length; i++) {
            if (usersTapped[i] == to) {
                userCheck = true;
                break;
            }
        }
        require(userCheck == false, 'Wallet already claimed today');
        // Add 1000 HOP to wallet
        usersTapped.push(to);
        uint256 amount = 1000 * 10 ** 18;
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }
    
}