/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity 0.8.0;

// SPDX-License-Identifier: Unlicensed

contract expensetracker{
    
    mapping(string=>int) incomeDetail;
    mapping(string=>int) expenseDetail;

    int totalBalance;
    
    function currentBalance() external view returns(int) {
        return totalBalance;
    }
    
    function income(int amount, string memory detail) external {
        totalBalance += amount;
        incomeDetail[detail] += amount;
    }
    
    function expense(int amount, string memory detail) external {
        totalBalance -= amount;
        expenseDetail[detail] += amount;
        
    }
    
    function incomeHistory(string memory EnterDetail) external view returns(int) {
        return incomeDetail[EnterDetail];
    }
    
    function expenseHistory(string memory EnterDetail) external view returns(int) {
        return expenseDetail[EnterDetail];
    }
}