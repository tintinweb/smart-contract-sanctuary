/**
 *Submitted for verification at BscScan.com on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract TokenAX{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allownance;
    
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "Atomex";
    string public symbol = "AX";
    uint public decimals = 18;
    
    constructor(){
        balances[msg.sender] = totalSupply;
    }
    
    event Transfer(address indexed from, address indexed to, uint _value);
    event Approve(address indexed _owner, address indexed _spender, uint _value);
    
    function balanceOf(address _owner) public view returns(uint){
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public returns(bool){
        require(balanceOf(msg.sender) >= _value, 'balance too low');
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _value) public returns(bool){
          require(balanceOf(_from) >= _value, 'balance too low');
          require(allownance[_from][msg.sender] >= _value, 'allownance too low');
          balances[_to] += _value;
          balances[_from] -= _value;
          emit Transfer(_from,_to, _value);
          return true;
    }
    
    function approve(address _spender, uint value) public returns(bool){
        allownance[msg.sender][_spender] = value;
        emit Approve(msg.sender, _spender, value);
        return true;
    }
}