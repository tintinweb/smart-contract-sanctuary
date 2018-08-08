pragma solidity ^0.4.2;

contract VouchCoin  {

  address public owner;
  uint public totalSupply;
  uint public initialSupply;
  string public name;
  uint public decimals;
  string public standard = "VouchCoin";

  mapping (address => uint) public balanceOf;

  event Transfer(address indexed from, address indexed to, uint value);

  function VouchCoin() {
    owner = msg.sender;
    balanceOf[msg.sender] = 10000000000000000;
    totalSupply = 10000000000000000;
    name = "VouchCoin";
    decimals = 8;
  }

  function balance(address user) public returns (uint) {
    return balanceOf[user];
  }

  function transfer(address _to, uint _value)  {
    if (_to == 0x0) throw;
    if (balanceOf[owner] < _value) throw;
    if (balanceOf[_to] + _value < balanceOf[_to]) throw;

    balanceOf[owner] -= _value;
    balanceOf[_to] += _value;
    Transfer(owner, _to, _value);
  }

  function () {
    throw;
  }
}