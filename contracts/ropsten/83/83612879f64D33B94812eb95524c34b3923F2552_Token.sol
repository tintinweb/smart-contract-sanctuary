pragma solidity ^0.7.3;

contract Token {
  string public name = "Danjiro Token";
  string public symbol = "DJRO";
  uint256 public totalSupply = 1000000;
  address public owner;

  mapping (address => uint256) balances;

  constructor() {
    balances[msg.sender] = totalSupply;
    owner = msg.sender;
  } 

  function transfer(address _to, uint256 _amount) external {
    require(balances[msg.sender] >= _amount, "Not enough tokens");

    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
  }

  function balanceOf(address _address) external view returns(uint256) {
    return balances[_address];
  }
}