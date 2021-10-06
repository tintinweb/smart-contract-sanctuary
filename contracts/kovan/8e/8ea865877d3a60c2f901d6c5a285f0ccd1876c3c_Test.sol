/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Test {
    uint[] public temp = [1, 2, 3];
    
    function test0() external view returns (uint) {
        return temp.length;
    }
    
    function clearArray() external {
        temp.pop();
    }
    
    function add(uint a) external {
        temp.push(a);
    }
}