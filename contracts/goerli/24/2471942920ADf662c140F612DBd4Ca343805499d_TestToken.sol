/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestToken {
  uint constant _totalSupply = type(uint256).max;
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) approvals;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  constructor() {
    balances[address(0)] = _totalSupply;
    emit Transfer(address(0), address(0), _totalSupply);
  }

  function name() public pure returns (string memory) {
    return 'TestToken';
  }

  function symbol() public pure returns (string memory) {
    return 'TT';
  }

  function decimals() public pure returns (uint8) {
    return 4;
  }

  function totalSupply() public pure returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint) {
    return balances[owner];
  }

  function transfer(address to, uint value) public returns (bool) {
    require(balances[msg.sender] >= value, 'Insufficient balance');
    balances[msg.sender] -= value;
    balances[to] += value;
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint value) public returns (bool) {
    require(approvals[from][msg.sender] >= value, 'Insuffient approval');
    require(balances[from] >= value, 'Insufficient balance');
    balances[from] -= value;
    balances[to] += value;
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint value) public returns (bool) {
    approvals[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function allowance(address owner, address spender) public view returns (uint) {
    return approvals[owner][spender];
  }

  function mint(uint amount) public {
    require(amount <= 10**12, 'Can only mint up to 10**12 tokens at once');
    require(balances[address(0)] >= amount, 'Insuffient funds');
    balances[address(0)] -= amount;
    balances[msg.sender] += amount;
    emit Transfer(address(0), msg.sender, amount);
  }
}