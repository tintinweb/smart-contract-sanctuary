/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

pragma solidity ^0.8.2;

contract FToken {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000000  * 10 ** 9;
    string public name = "FToken";
    string public symbol = "FTKN";
    uint public decimals = 9;    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'BALANCE_TOO_LOW');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'BALANCE_TOO_LOW');
        require(allowance[from][msg.sender] >= value, 'ALLOWANCE_TOO_LOW');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(to,from,value);
        return true;
        
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }
    
}