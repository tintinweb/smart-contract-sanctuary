pragma solidity ^0.4.14;
contract Ownable {
  address public owner;
  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

contract TUDOR is Ownable {
  string public constant name = "TUDOR";
  string public constant symbol = "TDR";
  uint8 public constant decimals = 18;
  uint256 public totalSupply;
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  function TUDOR() {
    balances[msg.sender] = 100000000000000000000000000;
    totalSupply = 100000000000000000000000000;
  }
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
  
  function transfer(address _to, uint256 _amount) returns (bool success) {
    if (balances[msg.sender] >= _amount 
      && _amount > 0
      && balances[_to] + _amount > balances[_to]) {
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(msg.sender, _to, _amount);
        return true;
    } else {
      return false;
    }
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
           Transfer(_from, _to, _amount);
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
  
  function issueCoins(uint256 _value, address _to) onlyOwner returns (bool) {        
        balances[_to] += _value;
        totalSupply += _value;
        Transfer(0, owner, _value);
        return true;
    }


  function chargebackCoins(uint256 _value, address _to) onlyOwner returns (bool) {
    if ((balances[_to] - _value) < 0)
            throw;

    balances[_to] -= _value;
    totalSupply -= _value;
    Transfer(0, owner, 0);
    return true;
    }

}