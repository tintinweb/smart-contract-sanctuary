/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    
    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowances;
    address public minter;
    uint256 public totalSupply;
    uint256 public maxsupply;
    uint256 public initsupply;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    
    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        maxsupply = 1000000;
        initsupply = 50000;
        balances[msg.sender] = initsupply;
        totalSupply = initsupply;
    }
    
    
    
    function minterChange(address owner) public returns (bool) {
        //if(msg.sender != minter) return;
        require(msg.sender  == minter, "Not a minter, cannot change the minter");
        minter  = owner;
        emit MintershipTransfer(msg.sender, owner);
        
        return true;
        
    }
    
    function mint(address account, uint256 amount) public returns (bool){
        require(msg.sender  == minter, "Not a minter");
        require(totalSupply <= maxsupply - amount, "Too much to mint");

        totalSupply += amount;
        balances[account] += amount;
        
        return true;
        
    }
    
    function burn(address account, uint256 amount) public returns (bool){
        require(msg.sender  == minter, "Not a minter");
        require(balances[account] >= amount, "Not enough balance to burn");

        totalSupply -= amount;
        balances[account] -= amount;
        
        return true;
        
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public {
        //Allow spender (number 2) to take addedValue from address msg.sender (number 1) but not an actual increase.
        //Alolow[1][2]=5
        allowances[msg.sender][spender] += addedValue;
    }
    
    function decreaseAllowance(address spender, uint256 subValue) public returns (bool){
        require(allowances[msg.sender][spender] >= subValue, "Allowance is smaller than subValue");
        //Decrease allowance to take from msg.sender for ex. from 10 to 7
        allowances[msg.sender][spender] -= subValue;
        
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount + 1);
        balances[recipient] += amount;
        balances[msg.sender] -= amount + 1;
        balances[minter] += 1;
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        //Number 2 (msg.sender) transfer from number 1 (sender) to number 3 (recipient) amount 5
        //Number 1 allows number 2 to transfer 5
        require(balances[sender] >= amount + 1);
        require(allowances[sender][msg.sender] >= amount + 1); 
        balances[sender] -= amount + 1;
        balances[recipient] += amount;
        balances[minter] += 1;
        allowances[sender][msg.sender] -= amount + 1;
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    
    
    
  
}