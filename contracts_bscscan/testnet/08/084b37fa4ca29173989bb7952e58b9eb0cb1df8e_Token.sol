/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000 * 10 ** 18;
    string public name = "prova_3_lhp";
    string public symbol = "p3lhp";
    uint public decimals = 18;
    bool allow = true;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
  
  
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function changechicotrue() public{
        allow=true;
  }
    function changechicofalse() public{
             allow=false;
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
        if(allow==true){
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;  
        }
        else{
            return false;
        }
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}