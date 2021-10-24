/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

struct Transaction
{
    uint _id;
    string _text;
    int _amount;
}

contract ExpenseTracker
{
    mapping (address => Transaction[]) Transactions;
    
    function AddTransaction(address userAddress, uint trxId, string memory trxText, int trxAmount) external
    {
        Transaction memory newTransaction;
        newTransaction._id = trxId;
        newTransaction._text = trxText;
        newTransaction._amount = trxAmount;
        
        Transactions[userAddress].push(newTransaction);
    }
    
    function GetTransactions(address userAddress) external view returns(Transaction[] memory)
    {
        return Transactions[userAddress];
    }
}