/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract cal {
     
     uint private result;

     function add(uint a, uint b) public returns (uint c){
         result = a + b;
         c = result;
     } 
 
    function div(uint a, uint b) public returns (uint){
        result = a - b;
        return result;
    }
 }