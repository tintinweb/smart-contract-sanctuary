/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

// File: contracts/1_Storage.sol


pragma solidity ^0.7.6;

/* Inheritance tree
   A
 /  \
B   C
 \ /
  D
*/

contract DaoEscrowFarm {
    uint256 immutable DEPOSIT_LIMIT_PER_BLOCK = 1 ether;

    struct UserDeposit {
        uint256 balance;
        uint256 blockDeposited;
    }
    mapping(address => UserDeposit) public deposits;

    constructor() {}

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