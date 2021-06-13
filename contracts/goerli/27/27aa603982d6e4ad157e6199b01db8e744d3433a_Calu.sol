/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Calu {
    
    int private result;
    
    function Add(int a, int b) public returns(int c){
        result = a + b;
        c = result;
    }
    
    function Min(int a, int b) public returns(int c){
        result = a - b;
        c = result;
    }
    
    function getRsult() public view returns(int){
        return result;
    }
}