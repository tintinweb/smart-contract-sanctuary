/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000000 * 10 ** 6;
    string public name = "test";
    string public symbol = "tst";
    uint public decimals = 6;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event charityFund(address indexed from, address, uint value);
    event developmentFund(address indexed from, address, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        uint finalValue = (value / 25) * 24;
        uint developmentValue = value / 100;
        uint charityValue = value / 100;
        emit Transfer(msg.sender, to, finalValue);
        emit developmentFund(msg.sender,  0x9af284dd2d183B5bFFFab0B8A91667d27a36701c, developmentValue);
        emit charityFund(msg.sender, 0xC808c7ca0C208602d2890f3Ad41db5cA9763a9Bc, charityValue);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance to low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value)public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    
    
}