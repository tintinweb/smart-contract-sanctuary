/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract Broccoinli {
  string public name = "Broccoinli";
  string public symbol = "BRO";
  uint8 public decimals = 0;

  uint256 public totalSupply = 100 * (uint256(10) ** decimals);
  mapping(address => int256) _balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  constructor() {
    _balanceOf[msg.sender] = int256(totalSupply);
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function balanceOf(address owner) public view returns (uint256 balance) {
    if (_balanceOf[owner] < 0) {
      return 0;
    }
    return uint256(_balanceOf[owner]);
  }

  function actualBalanceOf(address owner) public view returns (int256 balance) {
    return _balanceOf[owner];
  }

  function transfer(address to, uint256 value) public returns (bool success) {
    _balanceOf[msg.sender] -= int256(value);
    _balanceOf[to] += int256(value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool success) {
    require (value <= allowance[from][msg.sender]);
    _balanceOf[from] -= int256(value);
    _balanceOf[to] += int256(value);
    allowance[from][msg.sender] -= value;
    emit Transfer(from, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public returns (bool success) {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}