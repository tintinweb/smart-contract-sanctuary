/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

//SPDX-License-Identifier:UNLICENSED


pragma solidity 0.8.7;

contract expensetracker {

    int public balance = 1;

    Transaction[] public transaction;

    struct Transaction {
        address transactionOwner;
        string transactionDescription;
        int64 amount;
    }

    function addTransaction(string memory _description, int64 _amount) public {
        Transaction memory addTrans = Transaction(msg.sender, _description, _amount);
        transaction.push(addTrans);
        balance += _amount;
    }

    function getTransactionCount() public view returns(uint) {
        return transaction.length;
    }
}