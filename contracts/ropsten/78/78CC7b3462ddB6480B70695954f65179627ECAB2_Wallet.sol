/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Wallet {
  mapping(address => uint256) private wallets;

  receive() external payable {
    wallets[msg.sender] += msg.value;
  }

  function withdraw(address payable _to, uint256 _amount) external {
    require(_amount <= wallets[msg.sender], "Not enought money.");

    wallets[msg.sender] -= _amount;
    _to.transfer(_amount);
  }

  function getBalance() external view returns (uint256) {
    return wallets[msg.sender];
  }
}