pragma solidity ^0.4.25;
/**
 * Math operations with safety checks
 */
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract Token is SafeMath{

    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
    function burn(uint256 _value) returns (bool success){}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);


}



contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
       if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() Function
		if (_value <= 0) throw;
        if (balances[msg.sender] < _value) throw;           // Check if the sender has enough balance
        if (balances[_to] + _value < balances[_to]) throw; // Check for overflow
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                     // Subtract from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;                                // Prevent transfer to 0x0 address. Use burn() function
		if (_value <= 0) throw;
        if (balances[_from] < _value) throw;                 // Check if the sender has enough balance
        if (balances[_to] + _value < balances[_to]) throw;  // Check for overflow
        if (_value > allowed[_from][msg.sender]) throw;     // Check allowance
        balances[_from] = SafeMath.safeSub(balances[_from], _value);                           // Subtracting from the sender
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);                             // Add the same to the recipient
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
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
    /*Burn function*/
    function burn(uint256 _value) returns (bool success) {
        if (balances[msg.sender] < _value) throw;            // Check if the sender has enough balance
		if (_value <= 0) throw;
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                      // Subtract from the sender account
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;

}


contract HexanCoin is StandardToken {

    function () {
        throw;
    }

    string public name;
    uint8 public decimals;
    string public symbol;

    function HexanCoin(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balances[msg.sender] = initialSupply;               
        totalSupply = initialSupply;
        name = tokenName;
        decimals = decimalUnits;
        symbol = tokenSymbol;
    }


    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}