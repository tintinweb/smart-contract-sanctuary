/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;



// File: Test.sol

contract Test {
    function test(uint256 a) public returns (uint){
         return a+1;
    }

    function test2(uint256 a) external returns (uint){
         return a*20;
    }
}