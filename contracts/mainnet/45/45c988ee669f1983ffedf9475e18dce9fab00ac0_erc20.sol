pragma solidity ^0.4.24;


/**
 * Math operations with safety checks
 */
contract SafeMath {

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
    
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
/*  ERC 20 token */
contract erc20 is Token, SafeMath {

    // metadata
    string  public  name;
    string  public  symbol;
    uint256 public  decimals;
    uint256 public totalSupply;
    
    function erc20(string _name, string _symbol, uint256 _totalSupply, uint256 _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = formatDecimals(_totalSupply);
        balances[msg.sender] = totalSupply;
    }
    
    
    // transfer
    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;
    }

    
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] +_value > balances[_to] ) {
            balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                     
            balances[_to] = SafeMath.safeAdd(balances[_to], _value); 
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] +_value > balances[_to]) {
            balances[_from] = SafeMath.safeSub(balances[_from], _value);                          
            balances[_to] = SafeMath.safeAdd(balances[_to], _value);                            
            allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);

            return true;
        } else {
            return false;
        }
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}