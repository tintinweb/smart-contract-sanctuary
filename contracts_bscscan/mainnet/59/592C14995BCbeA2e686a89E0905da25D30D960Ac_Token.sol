/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/* 
Where we revolutionise the fitness rewarding system with cryptocurrency.

Our idea starts with providing a sophisticated and algorithmic cardio-distance tracking platform that converts speed, distance, time and burnt calories into Ranypto (RPO) Tokens. 
Ranypto encompasses the idea of technology and fitness combined, where the new era of the fitness industry is rewarded with digital currencies, thus, changes the perception of fitness and active lifestyle altogether. 

Learn more about project by visiting:
www.ranypto.com

You are more than welcome to join our telegram group below:
https://t.me/+uQ5VYO2LvapmOTll

*/



pragma solidity ^0.8.10;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000 * 10 ** 18;
    string public name = "Ranypto";
    string public symbol = "RPO";
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