pragma solidity ^0.4.24;

import &#39;./IERC20.sol&#39;;

contract Token is IERC20 {
    
    
    uint public constant _totalSupply = 97660000000000000000000000;
    string public constant name = "MOCD";                   
    uint8 public constant decimals = 18;               
    string public constant symbol = "MOCD";               
 
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    function Token()  {
        balances[msg.sender] = _totalSupply; 
    }
        
     function totalSupply() constant returns (uint256 totalSupply){
     return _totalSupply;
  }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
        
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
     
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(_to != 0x0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns 
    (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value; 
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success)   
    { 
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}