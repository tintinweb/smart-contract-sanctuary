pragma solidity ^0.4.16;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


 contract ERC20Interface {
     function totalSupply() constant returns (uint256 totalSupply);
     function balanceOf(address _owner) constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
     function approve(address _spender, uint256 _value) returns (bool success);
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
  
 contract MyToken is ERC20Interface {
      string public constant symbol = "FOD"; 
      string public constant name = "fodcreate";   
      uint8 public constant decimals = 18;
      uint256 _totalSupply = 2000000000000000000000000000; 
     
      address public owner;
  
      mapping(address => uint256) balances;
  
      mapping(address => mapping (address => uint256)) allowed;
  
      function MyToken() {
          owner = msg.sender;
          balances[owner] = _totalSupply;
      }
  
      function totalSupply() constant returns (uint256 totalSupply) {
         totalSupply = _totalSupply;
      }
  
      // What is the balance of a particular account?
      function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
      }
   
      // Transfer the balance from owner&#39;s account to another account
      function transfer(address _to, uint256 _amount) returns (bool success) {
         if (balances[msg.sender] >= _amount) {
            balances[msg.sender] = SafeMath.sub(balances[msg.sender],_amount);
            balances[_to] = SafeMath.add(balances[_to],_amount);
            
            return true;
         }
         
         return false;
      }
      
      function transferFrom(
          address _from,
          address _to,
         uint256 _amount
    ) returns (bool success) {
         require(_to != address(0));
    
         if (balances[_from] >= _amount) {
            balances[_from] = SafeMath.sub(balances[_from],_amount);
            balances[_to] = SafeMath.add(balances[_to],_amount);
            
            return true;
         }
         
         return false;
     }
  
     function approve(address _spender, uint256 _amount) returns (bool success) {
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
}