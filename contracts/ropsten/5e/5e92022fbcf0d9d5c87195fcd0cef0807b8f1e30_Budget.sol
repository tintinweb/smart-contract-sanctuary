/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Budget{
    
    int expence = 0;
    int income  = 0;
    int balance = 0;
    event transaction (string _desc, int _amount );
    
  
    function addIncome(string memory _desc ,int _amount)public {
       emit transaction(_desc , _amount);
       income +=  _amount  ;
      
    }
    function getIncome()public view returns (int) {
               return income;
    }
    function addexpence(string memory _desc, int _amount)public {
     emit transaction(_desc , _amount);
       expence +=  _amount  ;
      
    }
    function getexpence()public view returns (int) {
        return expence;
    }
    function getBalance()public view returns(int){
      return  income - expence;
    }
}