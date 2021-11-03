/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

//SPDX-License-Identifier: IMT

//Name: Muhammad Irfan
//Roll No: PIAIC1337739
//Quarter 3 Assignment 6

pragma solidity ^0.8.0;

contract ExpenseTracker {
    
    int private balance = 0;
    
    struct Transaction {
        address transactionOwner;
        string transactionDescription;
        int amount;
    }
    
    Transaction[] private transaction;

    function addTransaction(string memory description , int amount) public {
        Transaction memory enterTransaction = Transaction(msg.sender,description,amount);
        transaction.push(enterTransaction);
        balance += amount;
    }
    
    function deleteTransaction(uint _Index) public returns (string memory Result){
        require(transaction.length >= _Index, "Transaction does not exist.");
        
        string memory success = "Transaction Deleted Successfully";
        
        balance -= transaction[_Index].amount;
        delete transaction[_Index];
        
        for (uint i = _Index; i < transaction.length; i++ ){
            transaction[_Index] = transaction[transaction.length - 1];    
        }
        
        transaction.pop();
        
        return success;
    }
    
    function countTransaction () public view returns (uint){
        return transaction.length;
    }

    function currentBalance() public view returns (int){
        return balance;
    }
    
    function getTransactions() public view returns (Transaction[] memory){
        return transaction;
    }
    
    
}