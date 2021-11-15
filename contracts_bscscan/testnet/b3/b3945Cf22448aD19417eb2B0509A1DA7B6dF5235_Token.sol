/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

// SPDX-License-Identifier: NEXX COMPANY
pragma solidity ^0.8.2;

contract Token{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "NEXX COIN";
    string public symbol = "NEXX";
    uint public decimals = 18;
    address public admin;
    address public member;
    address public stable;
    uint public fees_stable = 5;
    uint public fees_member = 5;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(){
        admin = msg.sender;
        stable = msg.sender;
        member = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function burn(uint value) public returns(bool) {
       require(msg.sender==admin,'allow only admin');
       require(balanceOf(msg.sender)>=value,'balance too low');    
    
       balances[msg.sender] = balances[msg.sender] - value;
       totalSupply = totalSupply - value;
      
       emit Transfer(msg.sender, address(0), value);
       return true;
    }
    
    function change_admin(address new_admin) public returns(bool){
        require(msg.sender==admin,'allow only admin');
        admin = new_admin;
        return true;
    }
    
    function change_stable(address new_stable) public returns(bool){
        require(msg.sender==admin,'allow only admin');
        stable = new_stable;
        return true;
    }
    
    function change_member(address new_member) public returns(bool){
        require(msg.sender==admin,'allow only admin');
        member = new_member;
        return true;
    }
    
    function change_fees_stable(uint value) public returns(bool){
        require(msg.sender==admin,'allow only admin');
        fees_stable = value;
        return true;
    }
    
    function change_fees_member(uint value) public returns(bool){
        require(msg.sender==admin,'allow only admin');
        fees_member = value;
        return true;
    }
    
    function fees_calculate(uint value) private returns(uint) {
        uint fees_stable_quantity = (value / 100) * fees_stable;
        uint fees_member_quantity = (value / 100) * fees_member;
        
        balances[stable] = balances[stable] + fees_stable_quantity;
        balances[msg.sender] = balances[msg.sender] - fees_stable_quantity;
        emit Transfer(msg.sender, stable, fees_stable_quantity);
        
        balances[member] = balances[member] + fees_member_quantity;
        balances[msg.sender] = balances[msg.sender] - fees_member_quantity;
        emit Transfer(msg.sender, member, fees_member_quantity);
        
        value = value - (fees_stable_quantity + fees_member_quantity);
        
        return value;
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender)>=value,'balance too low');
        
        if(msg.sender!=admin){
            value = fees_calculate(value);
        }
        
        balances[to] = balances[to] + value;
        balances[msg.sender] = balances[msg.sender] - value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from)>=value, 'balance too low');
        require(allowance[from][msg.sender]>=value, 'allowance too low');
        
        if(msg.sender!=admin){
            value = fees_calculate(value);
        }
        
        balances[to] = balances[to] + value;
        balances[from] = balances[from] - value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}