/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    
    uint private a = 0;
    
    function f_a() public view returns(uint){
        return a + 100;
    }
    
    function f_b() external returns(uint){
        a ++;
        return a;
    }
    
}