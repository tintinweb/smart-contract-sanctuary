// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ExpenseTracker {
    int256 public balance = 1;

    Transaction[] public transaction;

    struct Transaction {
        address transactionOwner;
        string transactionDescription;
        int64 amount;
    }

    function addTransaction(string memory description, int64 amount) public {
        Transaction memory tx1 = Transaction(msg.sender, description, amount);
        transaction.push(tx1);
        balance += amount;
    }

    function transactionCount() public view returns (uint256) {
        return transaction.length;
    }
}