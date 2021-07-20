/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

contract Bank {

  uint private clientCount;
  mapping (address => uint) private balances;
  address public owner;

  event LogDepositMade(address indexed accountAddress, uint amount);

  constructor() public payable {
    require(msg.value == 3 ether, "30 ether initial funding required");
    owner = msg.sender;
    clientCount = 0;
  }

  function enroll() public returns (uint) {
    if (clientCount < 3) {
      clientCount++;
      balances[msg.sender] = 1 ether;
    }
    return balances[msg.sender];
  }

  function deposit() public payable returns (uint) {
    balances[msg.sender] += msg.value;
    emit LogDepositMade(msg.sender, msg.value);
    return balances[msg.sender];
  }

  function withdraw(uint withdrawAmount) public returns (uint remainingBalance) {
    if (withdrawAmount <= balances[msg.sender]) {
      balances[msg.sender] -= withdrawAmount;
      payable(msg.sender).transfer(withdrawAmount);
    }
    return balances[msg.sender];
  }

  function balance() public view returns (uint) {
    return balances[msg.sender];
  }

  function depositsBalance() public view returns (uint) {
    return address(this).balance;
  }
}