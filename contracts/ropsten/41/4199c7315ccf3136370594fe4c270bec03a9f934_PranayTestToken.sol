/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Token {

    function balanceOf(address _owner) public virtual returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) public virtual returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success) {}

    function approve(address _spender, uint256 _value) public  virtual returns (bool success) {}

    function allowance(address _owner, address _spender) public virtual returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}



contract StandardToken is Token {
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
 

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

}

contract PranayTestToken is StandardToken {

    string public name;                 
    uint8 public decimals;                
    string public symbol;                
    string public version = 'V.1.0';   
    uint256  public totalSupply;


    constructor()  {
        balances[msg.sender] = 21000000;               
        totalSupply = 21000000;                      
        name = "PranayTestToken";                                  
        decimals = 0;                           
        symbol = "PBT";                             
    }

    function approveAndCall(address _spender, uint256 _value) public  returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
    
 
}