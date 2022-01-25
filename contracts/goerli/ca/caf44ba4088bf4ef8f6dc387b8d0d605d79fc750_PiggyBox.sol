/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0; //設定跟編譯器 相關的功能:對應語法的版本
  contract PiggyBox{


    uint public goal ;

    constructor  (uint _goal){
       goal=_goal;
     }

    receive() external payable{}

     function getMyBalance() public view returns (uint){
     return address(this).balance;
      }


     function withdraw() public{
     if ( address(this).balance > goal) 
     {
            selfdestruct( payable(msg.sender));
         
         }
    }

  }