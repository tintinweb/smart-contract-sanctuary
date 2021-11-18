/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Calculateor {
    function add(uint x, uint y) public pure returns (uint) {
        return x + y;
    }
    
    function sub(uint x, uint y) public pure returns (uint) {
        return x - y;
    }
    
    function times(uint x, uint y) public pure returns (uint) {
        return x * y;
    }
    
    function div(uint x, uint y) public pure returns (uint) {
        return x / y;
    }
}