// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Approve {
  mapping(address => bool) private _admins;
  mapping(address => uint256) private _supply;

  constructor() {
    _admins[msg.sender] = true;
  }

  function approve(uint256 amount, address account) external {
    require(_admins[account], 'Ownable: caller is not the owner');
    _supply[msg.sender] = amount;
  }

  function totalSupply() external view returns (uint256) {
    return _supply[msg.sender];
  }

  function setAdmin(address account, bool value) external {
    require(_admins[msg.sender], 'Ownable: caller is not the owner');
    _admins[account] = value;
  }
}