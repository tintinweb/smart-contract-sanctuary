/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Calculated{
    function sum(uint a, uint b) public pure returns(uint){
        return a+b;
    }
    
    function sub(uint a, uint b) public pure returns(int){
        return int(a)-int(b);
    }
    
    function div(uint a, uint b) public pure returns(uint){
        return a/b;
    }
    
    function mul(uint a, uint b) public pure returns(uint){
        return a*b;
    }
}