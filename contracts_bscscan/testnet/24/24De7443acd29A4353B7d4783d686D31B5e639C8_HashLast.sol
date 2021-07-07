/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HashLast {
    bytes32 constant public zero = bytes32(0);
    
    function hashLast(uint256 n) public  view returns (uint8) {
        return uint8(blockhash(n)[31]) % 16;
    }
    
    function hash(uint256 n) public view returns (bytes32) {
        return blockhash(n);
    }
}