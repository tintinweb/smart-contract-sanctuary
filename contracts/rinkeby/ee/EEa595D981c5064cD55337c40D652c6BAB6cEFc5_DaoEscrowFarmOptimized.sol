/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;



// File: DaoEscrowFarmOptimized.sol

contract DaoEscrowFarmOptimized {
  uint256 immutable DEPOSIT_LIMIT_PER_BLOCK = 1 ether;

  struct UserDeposit {
    uint256 balance;
    uint256 blockDeposited;
  }

  mapping(address => UserDeposit) public deposits;

  constructor() public {}

  receive() external payable {
    require(msg.value <= DEPOSIT_LIMIT_PER_BLOCK, "TOO_MUCH_ETH");

    UserDeposit storage prev = deposits[msg.sender];

    uint256 maxDeposit = prev.blockDeposited == block.number
      ? DEPOSIT_LIMIT_PER_BLOCK - prev.balance
      : DEPOSIT_LIMIT_PER_BLOCK;

    if(msg.value > maxDeposit) {
      // refund user if they are above the max deposit allowed
      uint256 refundValue = msg.value - maxDeposit;
      
      (bool success,) = msg.sender.call{value: refundValue}("");
      require(success, "ETH_TRANSFER_FAIL");
    }
    else {
      prev.balance += msg.value;
      prev.blockDeposited = block.number;
    }

  }

  

  function withdraw(uint256 amount) external {
    UserDeposit storage prev = deposits[msg.sender];
    require(prev.balance >= amount, "NOT_ENOUGH_ETH");

    prev.balance -= amount;
    
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "ETH_TRANSFER_FAIL");
  }
}