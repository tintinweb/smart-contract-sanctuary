/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

interface IBrc20 {
  function balanceOf(address account) view external returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);
}

contract Brc20 is IBrc20 {
  string public name;
  string public symbol;
  uint public totalSupply;

  constructor(string memory _name, string memory _symbol) {
    totalSupply = 1;
    name = _name;
    symbol = _symbol;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return 0xCAFE; // useless
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    return true; // useless
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return 0xBEEF; // useless but tasty
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    return true; // useless
  }
}