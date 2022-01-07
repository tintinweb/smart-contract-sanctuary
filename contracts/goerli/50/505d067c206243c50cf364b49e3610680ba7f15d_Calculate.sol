/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0; //設定跟編譯器 相關的功能:對應語法的版本


  contract Calculate{


      int private result;


      function add(int a,int b) public returns (int c) {
        result=a+b ;
        c = result;

       }

      function min(int a,int b) public returns(int){
       result =a-b;
       return result;

       }

       function mul(int a,int b) public returns(int){
       result =a*b;
       return result;

       } 

       function div(int a,int b) public returns(int){
       result =a/ b;
       return result;

       }

       function getResult() public view returns (int){
       return result;
       
       }  

  }