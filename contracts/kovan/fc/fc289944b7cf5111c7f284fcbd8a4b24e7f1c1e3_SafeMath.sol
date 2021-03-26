/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        uint d;
        d = a - b;
        c = a + b;
        require(c >= a);
    }
}