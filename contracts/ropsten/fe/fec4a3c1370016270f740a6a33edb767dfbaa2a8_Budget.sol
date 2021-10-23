/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity 0.8.0;

contract Budget{
    
    uint256 private expence;
    uint256 private income;
    uint256 private balance;
    
  
    function addIncome(uint256 incomes)public {
       income +=  incomes  ;
      
    }
    function getIncome()public view returns (uint256) {
        return income;
    }
    function addexpence(uint256 expences)public {
       expence +=  expences  ;
      
    }
    function getexpence()public view returns (uint256) {
        return expence;
    }
    function getBalance()public view returns(uint256){
      return  income - expence;
    }
}