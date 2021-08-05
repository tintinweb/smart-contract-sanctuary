/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.8.2;
contract Token {
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 926260000 * 10 ** 18;
    string public name = "Taino Token";
    string public symbol = "CEMI";
    uint public decimals = 18; 
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event approval (address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances [msg.sender] = totalSupply; 
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
        }
    function transfer(address to, uint value) public returns (bool) {
        require (balanceOf(msg.sender) >= value, 'balance too low');
        balances [to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     function transferFrom(address from, address to, uint value) public returns(bool) {
         require(balanceOf(from) >= value,     'balance to low');
         require(allowance[from][msg.sender] >= value, 'allowance too low');
          balances[to] += value;
          balances[from] -= value;
          emit Transfer(from, to, value);
          return true;
     }
    
    function approve(address spender, uint value) public returns(bool) {  
        allowance [msg.sender][spender] = value;
        emit approval(msg.sender, spender, value);
        return true;
    }
}