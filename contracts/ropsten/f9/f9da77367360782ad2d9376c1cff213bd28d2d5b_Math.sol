/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Math {
    
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function Sub(uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(a >= b);
    }
    
    function Mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    
    function Div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function DivEucl(uint a, uint b) public pure returns (uint c, uint d) {
        require(b > 0);
        c = a / b;
        d = a % b;
    }
    
    function Mod(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a % b;
    }
}