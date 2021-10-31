/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract expenseTraker {
    
    int totalIncome;
    int totalExpenses;
    int balance;
  
    function viewIncome () public view returns (int){
        return(totalIncome);
    }
    
    function viewExpense () public view returns (int){
        return(totalExpenses);
    }
    
    function viewBalance () public view returns (int){
        return(balance);
    }
    
    event eventTrx(string, string item, int amount);

       function addTransaction(string memory description, int amount) public {
        if (amount > 0) {
            totalIncome = totalIncome + amount;
            balance = totalIncome - totalExpenses;
            emit eventTrx("Income", description, amount);
        }
        else (totalExpenses = totalExpenses + amount);
        balance = totalIncome + totalExpenses;
        emit eventTrx("Expense", description, amount);
    }
}