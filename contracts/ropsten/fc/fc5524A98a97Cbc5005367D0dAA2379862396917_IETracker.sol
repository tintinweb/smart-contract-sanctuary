/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IETracker {
    
        int private income;
        int private expense;
        mapping (string => mapping(string => int)) trax;
        event traxHistory(string, string, int);
        
            function addEntry (string memory _detail, int _amount) public {
            require(_amount != 0,"Empty input");
            require(bytes(_detail).length > 0,"Empty input");
            string memory traxType;
            
            if (_amount > 0){
                traxType = "Income";
                income = income + _amount;
            }
            
            else {
                traxType = "Expnese"; 
                expense = expense + _amount;
            }   
            
            emit traxHistory(traxType, _detail, _amount);
            trax[traxType][_detail] = _amount;
            
        }
        
    
        function getBalance()public view returns(int balance){
            balance = income + expense;
        }
        
        function getIncome()public view returns(int){
         return income;  
        }
        
        function getExpense()public view returns(int){
         return expense;  
        }
}