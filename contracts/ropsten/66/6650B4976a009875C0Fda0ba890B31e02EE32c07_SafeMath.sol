/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

contract SafeMath {
    
    function safeAdd(uint a, uint b) public pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns(uint c) {
        c = a - b;
        require(a >= b);
    }
    function safeMul(uint a, uint b) public pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
    function safeDivEuclidienne(uint a, uint b) public pure returns(uint c, uint d) {
        require(b > 0);
        c = a % b;
        d = a / d;
        require(d < a);
    }
    function safeMod(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a % b;
        require(c <= a);
    }
}