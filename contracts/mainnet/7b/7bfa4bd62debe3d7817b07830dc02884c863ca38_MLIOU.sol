pragma solidity ^0.4.7;

contract SafeMath {
  function safeMul(uint a, uint b) pure internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) pure internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) pure internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);

  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StandardToken is ERC20, SafeMath {
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;

  function transfer(address _to, uint _value) public returns (bool success) {
    // This test is implied by safeSub()
    // if (balances[msg.sender] < _value) { throw; }
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    // These tests are implied by safeSub()
    // if (balances[_from] < _value) { throw; }
    // if (_allowance < _value) { throw; }
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

contract MLIOU is StandardToken {
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name = "Mao Liquidity IOU";   // Fancy name: eg: Liquidity IOU
    string public symbol = "MLIOU"; // An identifier: eg LIOU
    uint public decimals = 8;      // Unit precision

    function MLIOU() public {
        totalSupply = 250000000000000;       // Set the total supply (in base units)
        balances[0x50b42514389F25E1f471C8F03f6f5954df0204b0] = 250000000000000;    // Initially assign the entire supply to the specified account
    }

    // do not allow deposits
    function() public {
        revert();
    }
}