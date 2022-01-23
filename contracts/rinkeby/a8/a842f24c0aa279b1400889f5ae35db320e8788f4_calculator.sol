/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

contract calculator{

        int public x;
        int public result;

        function set_value(int  d1) public{
            x = d1;
            
        }
        function add() public returns(int ){
            
            result = x + result;
            return result;
        }   
          function subtract() public returns(int){
            
            result = x - result;
            return result;
        }   
          function multiply() public returns(int){
            
            result = x * result;
            return result;
        }   
          function division() public returns(int){
            
            result = x / result;
            return result;
        }   
        function reset() public returns(int){
            
            result = 0;
            return result;
        }   
   
    }