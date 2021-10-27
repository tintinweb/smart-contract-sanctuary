/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Budget{
    
    uint256 private expence;
    uint256 private income;
    uint256 private balance;
    
  
    function addIncome(uint256 _incomes)public {
       income +=  _incomes  ;
      
    }
    function getIncome()public view returns (uint256) {
        return income;
    }
    function addexpence(uint256 _expences)public {
       expence +=  _expences  ;
      
    }
    function getexpence()public view returns (uint256) {
        return expence;
    }
    function getBalance()public view returns(uint256){
      return  income - expence;
    }
}