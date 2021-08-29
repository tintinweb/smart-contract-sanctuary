/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Calculator{
    
    uint c;
    
    function add(uint a, uint b) public {
        c = a + b;
    }
    
    function getResult() public view returns (uint x){
        return c;
    }
}