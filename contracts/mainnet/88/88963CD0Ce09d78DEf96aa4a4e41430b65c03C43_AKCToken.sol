pragma solidity ^0.4.11;

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

contract AKCToken is ERC20Interface{
    string public standard = &#39;Token 1.0&#39;;
    string public constant name="Artwork File";
    string public constant symbol="AKC";
    uint8 public constant decimals=9;
    uint256 constant _totalSupply=1000000000000000000;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    address public owner;
    
    function AKCToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply; 
    }
    
    function totalSupply() constant returns (uint256 totalSupply) {
          return _totalSupply;
    }
    
    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner]; 
    }

    function transfer(address _to, uint256 _amount) returns (bool success)  {
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

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success){
        if (balances[_from] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]  && _amount <= allowed[_from][msg.sender]) 
        {
             balances[_from] -= _amount;
             balances[_to] += _amount;
             allowed[_from][msg.sender] -= _amount;
             Transfer(_from, _to, _amount);
             return true;
        } else {
             return false;
        }
    }

    function approve(address _spender, uint256 _value) returns (bool success){
         allowed[msg.sender][_spender] = _value;
         Approval(msg.sender, _spender, _value);
         return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}