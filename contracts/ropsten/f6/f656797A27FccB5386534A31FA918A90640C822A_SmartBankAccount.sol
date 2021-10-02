/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SmartBankAccount
 * @dev Store & Widthdraw money with 0.07% APY
 */
contract SmartBankAccount {
  uint256 totalContractBalance = 0;

  function getContractBalance() public view returns (uint256) {
    return totalContractBalance;
  }

  mapping(address => uint256) balances;
  mapping(address => uint256) depositTimestamps;

  function addBalance() public payable {
    balances[msg.sender] = msg.value;
    totalContractBalance = totalContractBalance + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
  }

  function getBalance(address userAddress) public view returns (uint256) {
    uint256 principal = balances[userAddress];
    uint256 timeElapsed = block.timestamp - depositTimestamps[userAddress]; // in senconds
    return
      principal +
      uint256((principal * 7 * timeElapsed) / (100 * 365 * 24 * 60 * 60)) +
      1; // 0.07% APY
  }

  function widthdraw() public payable {
    address payable widthdrawTo = payable(msg.sender);
    uint256 amountToTransfer = getBalance(msg.sender);
    widthdrawTo.transfer(amountToTransfer);
    totalContractBalance = totalContractBalance - amountToTransfer;
    balances[msg.sender] = 0;
  }

  function addMoneyToContract() public payable {
    totalContractBalance += msg.value;
  }
}