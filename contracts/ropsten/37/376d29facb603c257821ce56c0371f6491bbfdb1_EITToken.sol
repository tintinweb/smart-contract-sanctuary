pragma solidity ^0.4.24;
contract Token {
    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

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

contract RegularToken is Token,SafeMath {

    function transfer(address _to, uint256 _value) returns (bool success){
        if (_to == 0x0) revert(&#39;Address cannot be 0x0&#39;); // Prevent transfer to 0x0 address. Use burn() instead
        if (_value <= 0) revert(&#39;_value must be greater than 0&#39;);
        if (balances[msg.sender] < _value) revert(&#39;Insufficient balance&#39;);// Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) revert(&#39;has overflows&#39;); // Check for overflows
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                     // Subtract from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) revert(&#39;Address cannot be 0x0&#39;); // Prevent transfer to 0x0 address. Use burn() instead
        if (_value <= 0)revert(&#39;_value must be greater than 0&#39;);
        if (balances[_from] < _value) revert(&#39;Insufficient balance&#39;);// Check if the sender has enough
        if (balances[_to] + _value < balances[_to]) revert(&#39;has overflows&#39;);  // Check for overflows
        if (_value > allowed[_from][msg.sender]) revert(&#39;not allowed&#39;);     // Check allowed
        balances[_from] = SafeMath.safeSub(balances[_from], _value);                           // Subtract from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);                             // Add the same to the recipient
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        if (_value <= 0) revert(&#39;_value must be greater than 0&#39;);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}


contract EITToken is RegularToken {

    uint256 public totalSupply = 5*10**27;
    uint256 constant public decimals = 18;
    string constant public name = "EightToken";
    string constant public symbol = "EIT";

    constructor() public{
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}