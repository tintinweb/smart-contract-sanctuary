/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

contract ExpenseTracker 
{
    mapping (address => uint256) private income;
    mapping (address => uint256) private expense;
    mapping (address => uint256) private balance;
    
   
    struct expenseStruct
    {
        uint256 amount;
        string description;
    }
    
    
    mapping (address=> expenseStruct[] ) private expenseIncomeMapping;
    
    modifier onlyAccountHolder
    {
        require(income[msg.sender] != 0, "You are not an account holder");
        _;
    }
    
    modifier balanceCheck (uint256 _amount)
    {
        require(_amount < balance[msg.sender] , "Your Balance is low");
        _;
    }
    
    
    function getIncome() public view onlyAccountHolder returns (uint256)
    {
            return income[msg.sender];
    }
    
    function getExpense() public view onlyAccountHolder returns (uint256)
    {
            return expense[msg.sender];
    }
    
    function getBalance() public view onlyAccountHolder returns (uint256)
    {
            return balance[msg.sender];
    }
    
    function addIncome(uint256 _amount , string memory _description) public 
    {
        
        income[msg.sender] = income[msg.sender] + _amount;
        balance[msg.sender] = balance[msg.sender] + _amount;
        
        expenseIncomeMapping[msg.sender].push(expenseStruct(_amount,_description));
    }
    
    function addExpense(uint256 _amount ,string memory _description) public balanceCheck(_amount)
    {
        expense[msg.sender] = expense[msg.sender] + _amount;
        balance[msg.sender] = balance[msg.sender] - _amount;
        
        expenseIncomeMapping[msg.sender].push(expenseStruct(_amount,_description));
    }
    
    function getExpenseIncomeMapping() public view returns(expenseStruct[] memory)
    {
        return expenseIncomeMapping[msg.sender];
    }
}