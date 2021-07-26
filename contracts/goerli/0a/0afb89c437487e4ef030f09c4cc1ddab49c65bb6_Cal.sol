/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Cal{
        
        int private result;
        
    function Add (int a, int b) public returns (int){
        result = a +b;
        return result;
    }
    
    function Sub (int a,int b) private returns (int){
        result = a-b;
        return result;
    }
    
    function show_result () public view returns (int){
        return result;
    }
}