pragma solidity ^0.4.24;

contract token{
    mapping (address => uint256) balances;
    
      constructor(uint initialSupply) payable public{
   
        balances[msg.sender] =initialSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
     function transfer(address _to, uint256 _value) public payable returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
 }