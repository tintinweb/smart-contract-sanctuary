pragma solidity ^0.4.23;


contract Token {
  
    address owner;
  
    uint256 public totalSupply = 1000000000000000000000000;
    string public name = "Test Token 1";
    string public symbol = "TT1";
    uint8 public decimals = 18;
    
    mapping (address => mapping (address => uint256)) allowed;
    mapping(address => uint256) balances;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() public {
      balances[msg.sender] = totalSupply;
      owner = msg.sender;
    }
  
    function transfer(address _to, uint256 _value) public returns (bool) {
      if (_to == address(0)) {
        return false;
      }
      if (_value > balances[msg.sender]) {
        return false;
      }
      
      balances[msg.sender] = balances[msg.sender] - _value;
      balances[_to] = balances[_to] + _value;
      emit Transfer(msg.sender, _to, _value);
      return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256) {
      return balances[_owner];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      if (_to == address(0)) {
        return false;
      }
      if (_value > balances[_from]) {
        return false;
      }
      if (_value > allowed[_from][msg.sender]) {
        return false;
      }

      balances[_from] = balances[_from] -_value;
      balances[_to] = balances[_to] + _value;
      allowed[_from][msg.sender] = allowed[_from][msg.sender] + _value;
      emit Transfer(_from, _to, _value);
      return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
      allowed[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);
      return true;
    }
    

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
  
}