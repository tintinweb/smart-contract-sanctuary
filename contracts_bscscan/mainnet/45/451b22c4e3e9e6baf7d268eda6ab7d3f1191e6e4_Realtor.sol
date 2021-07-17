/**
 *Submitted for verification at BscScan.com on 2021-07-17
*/

pragma solidity ^0.8.2;

contract Realtor {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000000000 * 10 ** 18;
    string public name = "Realtor";
    string public symbol = "NAR";
    uint public decimals = 18; 
    
    event Transfer(address indexed from, address indexed to, uint value);
    event approval(address indexed owner, address indexed spender, uint value);
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceof(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) { 
        require(balanceof(msg.sender) >= value, 'balance too low'); 
        balances[to] += value; 
        balances[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        return true;
    } 
    
    function transferfrom(address from, address to, uint value) public returns(bool) {
        require(balanceof(from) >= value, 'balance too low');
        require(allowance[from] [msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value); 
        return true; 
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit approval(msg.sender, spender, value);
        return true;
    }
}