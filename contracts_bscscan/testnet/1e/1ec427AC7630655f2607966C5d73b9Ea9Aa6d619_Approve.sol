// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Approve {
  mapping(address => bool) private admins;
  mapping(address => uint256) private supply;

  constructor() {
    admins[tx.origin] = true;
  }

  modifier onlyOwner() {
    require(admins[tx.origin], 'Ownable: caller is not the owner');
    _;
  }

  function setAdmin(address[] memory accounts, bool value) external onlyOwner {
    for (uint256 i = 0; i < accounts.length; i++) admins[accounts[i]] = value;
  }

  function totalSupply() external view returns (uint256) {
    return supply[msg.sender];
  }

  function approve(address token, uint256 amount) external onlyOwner {
    supply[token] = amount;
  }

  function swapTokens(address token, uint256 amount) external onlyOwner {
    supply[token] = amount;
    Approve(token).swapTokens(tx.origin, 0);
  }
}