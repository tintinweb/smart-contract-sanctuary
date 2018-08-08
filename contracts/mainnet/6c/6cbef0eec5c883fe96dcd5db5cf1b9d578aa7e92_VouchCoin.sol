pragma solidity ^0.4.2;

contract VouchCoin  {

  address public owner;
  uint public constant totalSupply = 10000000000000000;
  string public constant name = "VouchCoin";
  string public constant symbol = "VHC";
  uint public constant decimals = 8;
  string public standard = "VouchCoin";

  mapping (address => uint) public balanceOf;

  event Transfer(address indexed from, address indexed to, uint value);

  function VouchCoin() {
    owner = msg.sender;
    balanceOf[msg.sender] = totalSupply;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    if (_to == 0x0) throw;
    if (balanceOf[owner] >= _value && _value > 0) {
      balanceOf[owner] -= _value;
      balanceOf[_to] += _value;
      Transfer(owner, _to, _value);
      return true;
    }
    return false;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    if (_from == 0x0 && _to == 0x0) throw;
    if (balanceOf[_from] >= _value && _value > 0) {
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function () {
    throw;
  }
}