pragma solidity ^0.4.18;
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value)  public returns (bool ok);
  function transferFrom(address from, address to, uint value)  public returns (bool ok);
  function approve(address spender, uint value)  public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
pragma solidity ^0.4.18;
library SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
pragma solidity ^0.4.18;
contract StandardToken is ERC20 {
  using SafeMath for uint256; 
  modifier onlyPayloadSize(uint size) {
     require(msg.data.length >= size + 4);
     _;
  }
  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) public returns (bool success){
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].safeSub(_value);
    balances[_to] = balances[_to].safeAdd(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) public returns (bool success) {
    require(_from != address(0));
    require(_to != address(0));
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].safeAdd(_value);
    balances[_from] = balances[_from].safeSub(_value);
    allowed[_from][msg.sender] = _allowance.safeSub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  function approve(address _spender, uint _value) public returns (bool success) {
    require(_spender != address(0));
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    require(_owner != address(0));
    require(_spender != address(0));
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].safeAdd(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }	
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(_spender != address(0));
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.safeSub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}
pragma solidity ^0.4.18;
contract OdinCoin is StandardToken {
    string public constant name = "ODIN TOKEN";
    string public constant symbol = "ODIN";
    uint8 public constant decimals = 0;
    uint256 public constant totalSupply = 200000000;

    function OdinCoin(address reserve) public {
        balances[reserve] = totalSupply;
    }
}