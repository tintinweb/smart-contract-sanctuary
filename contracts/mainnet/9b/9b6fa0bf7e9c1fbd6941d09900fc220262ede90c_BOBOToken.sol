pragma solidity ^0.4.8;
contract BOBOToken {

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


  mapping( address => uint ) _balances;
  mapping( address => mapping( address => uint ) ) _approvals;
  uint256 public totalSupply=21000000;
  string public name="BOBOToken";
  uint8 public decimals=8;                
  string public symbol="BOBO";   

  function BOBOToken() {
        _balances[msg.sender] = totalSupply;               // Give the creator all initial tokens
  }

  function balanceOf( address _owner ) constant returns (uint balanbce) {
    return _balances[_owner];
  }

  function transfer( address _to, uint _value) returns (bool success) {
    if ( _balances[msg.sender] < _value ) {
      revert();
    }
    if ( !safeToAdd(_balances[_to], _value) ) {
      revert();
    }
    _balances[msg.sender] -= _value;
    _balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom( address _from, address _to, uint _value) returns (bool success) {
    // if you don&#39;t have enough balance, throw
    if ( _balances[_from] < _value ) {
      revert();
    }
    // if you don&#39;t have approval, throw
    if ( _approvals[_from][msg.sender] < _value ) {
      revert();
    }
    if ( !safeToAdd(_balances[_to], _value) ) {
      revert();
    }
    // transfer and return true
    _approvals[_from][msg.sender] -= _value;
    _balances[_from] -= _value;
    _balances[_to] += _value;
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint _value) returns (bool success) {
    // TODO: should increase instead
    _approvals[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return _approvals[_owner][_spender];
  }
  function safeToAdd(uint a, uint b) internal returns (bool) {
    return (a + b >= a);
  }
}