/**
 *Submitted for verification at BscScan.com on 2022-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

contract test{
    uint public a;
    event _num(uint a);


    function num(uint _a,uint _b) public {
        a=_a+_b;
        emit _num (a);
    } 
}