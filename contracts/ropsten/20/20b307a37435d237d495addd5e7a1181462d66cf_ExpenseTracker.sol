/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

contract ExpenseTracker{
    int256 income;
    int256 expense;
    int256 balance; 
    uint256 id;
    
    struct history {
        uint256 id;
        string Type;
        string cat;
        int256 amount;
    }
    
    history[] _history;
    
    function addIncome(int256 _income, string memory _cat) public{
        _history.push(history(id, 'INCOME', _cat, _income));
        id++;
        income += _income;
    }
    function showIncome() public view returns(int256){
        return income;
    }
    
    function addExpense(int256 _expense, string memory _cat) public{
        _history.push(history(id, 'EXPENSE', _cat, -_expense));
        id++;
        expense += _expense;
    }
    function showExpense() public view returns(int256){
        return expense;
    }
    
    function showBalance() public returns(int256) {
        balance = income -expense;
        return balance;
    }
    function totalEntries() public view returns(uint256){
        return _history.length;
    }
    
    function showHistory(uint256 _index) public view returns(uint256 _id, string memory _Type, string memory _Cat, int256 _amount) {
        history storage _totalHistory = _history[_index];
        _id = _totalHistory.id;
        _Type = _totalHistory.Type;
        _Cat = _totalHistory.cat;
        _amount = _totalHistory.amount;
    }
}