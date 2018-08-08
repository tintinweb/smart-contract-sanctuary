pragma solidity ^0.4.11;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract SuretlyToken {

  string public constant standard = &#39;Token 0.1&#39;;
  string public constant name = "Suretly";
  string public constant symbol = "SUR";
  uint8 public constant decimals = 8;
  uint256 public totalSupply = 237614 * 100000000;

  address public owner;

  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event NewOwner(address _newOwner);
  event Burn(address indexed _from, uint256 _value);

  function SuretlyToken() {
    owner = msg.sender;
    balanceOf[owner] = totalSupply;
  }

  function replaceOwner(address _newOwner) returns (bool success) {
    assert(msg.sender == owner);
    owner = _newOwner;
    NewOwner(_newOwner);
    return true;
  }

  function transfer(address _to, uint256 _value) {
    require(_to != 0x0);
    require(_to != address(this));
    assert(!(balanceOf[msg.sender] < _value));
    assert(!(balanceOf[_to] + _value < balanceOf[_to]));
    balanceOf[msg.sender] -= _value;
    balanceOf[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(_to != 0x0);
    require(_to != address(this));
    assert(!(balanceOf[_from] < _value));
    assert(!(balanceOf[_to] + _value < balanceOf[_to]));
    assert(!(_value > allowance[_from][msg.sender]));
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    allowance[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
    tokenRecipient spender = tokenRecipient(_spender);
    if (approve(_spender, _value)) {
      spender.receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  function burn(uint256 _value) returns (bool success) {
    assert(!(balanceOf[msg.sender] < _value));
    balanceOf[msg.sender] -= _value;
    totalSupply -= _value;
    Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint256 _value) returns (bool success) {
    assert(!(balanceOf[_from] < _value));
    assert(!(_value > allowance[_from][msg.sender]));
    balanceOf[_from] -= _value;
    totalSupply -= _value;
    Burn(_from, _value);
    return true;
 }
}