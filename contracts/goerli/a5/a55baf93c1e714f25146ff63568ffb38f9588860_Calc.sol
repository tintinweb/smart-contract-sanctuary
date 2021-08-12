/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.1 <0.8.0;

contract Calc {
    uint private result; 
    function add(uint a, uint b)public returns (uint){
        result = a + b;
        return result;
    }
    function min(uint a, uint b)public returns (uint){
        result = a - b;
        return result;
    }
    function mul(uint a, uint b)public returns (uint){
        result = a * b;
        return result;
    }
    function div(uint a, uint b)public returns (uint){
        result = a / b;
        return result;
    }
    
    function getResult()public view returns(uint){
        return result;
    }
    
}