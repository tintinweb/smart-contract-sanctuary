/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract cal {
    int private result;
    
    function add(int a, int b ) public returns (int){
    result = a + b;
    return result;
}
}