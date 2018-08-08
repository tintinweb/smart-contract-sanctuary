pragma solidity ^0.4.13;

contract SpareCurrencyToken {
  string public constant name = "SpareCurrencyToken";
  string public constant symbol = "SCT";
  uint8 public constant decimals = 18;
  
  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  function SpareCurrencyToken() {
    balances[msg.sender] = 51000000000000000000000000;
    totalSupply = 51000000000000000000000000;
  }

  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount 
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        return true;
    } else {
      return false;
    }
}


  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function transferFrom(
       address _from,
       address _to,
       uint256 _amount
   ) returns (bool success) {
       if (balances[_from] >= _amount
           && allowed[_from][msg.sender] >= _amount
           && _amount > 0
           && balances[_to] + _amount > balances[_to]) {
           balances[_from] -= _amount;
           allowed[_from][msg.sender] -= _amount;
           balances[_to] += _amount;
           return true;
      } else {
           return false;
       }
  }
  
  function approve(address _spender, uint256 _value) returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}