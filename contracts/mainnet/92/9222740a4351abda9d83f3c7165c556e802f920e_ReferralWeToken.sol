pragma solidity ^0.4.13;

contract Receiver {
  function tokenFallback(address from, uint value, bytes data);
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

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      revert();
    }
  }
}

contract StandardToken is ERC20, SafeMath {
  event Transfer(address indexed from, address indexed to, uint indexed value, bytes data);

  event Minted(address receiver, uint amount);

  mapping(address => uint) balances;

  mapping (address => mapping (address => uint)) allowed;

  modifier onlyPayloadSize(uint size) {
     if(msg.data.length != size + 4) {
       revert();
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success) {
      bytes memory _empty;

      return transfer(_to, _value, _empty);
  }

  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);

    if (isContract(_to)) {
      Receiver(_to).tokenFallback(msg.sender, _value, _data);
    }

    return true;
  }

  function isContract( address _addr ) private returns (bool) {
    uint length;
    _addr = _addr;
    assembly { length := extcodesize(_addr) }
    return (length > 0);
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {

    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}



contract BurnableToken is StandardToken {

  address public constant BURN_ADDRESS = 0;

  event Burned(address burner, uint burnedAmount);

  function burn(uint burnAmount) public {
    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner], burnAmount);
    totalSupply = safeSub(totalSupply, burnAmount);
    Burned(burner, burnAmount);
  }
}


contract ReferralWeToken is BurnableToken {

  string public name;
  string public symbol;
  uint public decimals;
  address public owner;

  modifier onlyOwner() {
    if(msg.sender != owner) revert();
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function ReferralWeToken(address _owner, uint _totalSupply) public {
    name = "refwttoken";
    symbol = "RefWT";
    decimals = 0;
    totalSupply = _totalSupply;

    balances[_owner] = totalSupply;

    owner = _owner;
  }
}