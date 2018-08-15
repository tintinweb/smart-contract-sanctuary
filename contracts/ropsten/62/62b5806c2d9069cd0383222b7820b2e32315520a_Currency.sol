pragma solidity ^0.4.23;

contract Currency {
  mapping (address => uint256) public balances;

  event Transfer(address indexed from, address indexed to, uint tokens);

  constructor() public {
    balances[msg.sender] = 1000;
  }

  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
}