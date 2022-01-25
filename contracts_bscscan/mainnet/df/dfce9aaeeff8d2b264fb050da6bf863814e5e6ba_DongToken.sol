/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.2;

contract DongToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint public maxSupply = 5000000000;
    uint public totalSupply;
    string public name = "DongCoin";
    string public symbol = "DONG";
    address public minter;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        minter = msg.sender;
    }
    
    function mint(address receiver, uint amount) public {
     require(msg.sender==minter,"Only owner can call this function");
     require(totalSupply < maxSupply);
     balances[receiver] += amount;
     totalSupply +=amount;
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'Insufficient Balance');
        balances[to] += value;
        balances[msg.sender] -= value;
       emit Transfer(msg.sender, to, value);
        return true;
    }
  
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(msg.sender==from,"Insufficient Balance");
        require(balances[from] >= value, 'Insufficient Balance');
        require(allowance[from][msg.sender] >= value, 'Insufficient Balance');
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