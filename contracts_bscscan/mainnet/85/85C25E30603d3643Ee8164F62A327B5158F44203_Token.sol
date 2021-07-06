/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balences;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply =1000 * 10 ** 18;
    string public name = "autoken";
    string public symbol = "autoken";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint valur);
    
    constructor(){
        balences[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner)public view returns(uint){
        return balences[owner];
    }
    
    function transfer(address to, uint value)public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance to low');
        balences[to] += value;
        balences[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from,address to, uint value) public returns(bool) {
     require(balanceOf(from) >= value,'balance too low');
     require(allowance[from][msg.sender] >= value, 'allowance too low');
     balences[to] += value;
     balences[from] -= value;
     emit Transfer(from, to, value);
     return true;
    }
        
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}