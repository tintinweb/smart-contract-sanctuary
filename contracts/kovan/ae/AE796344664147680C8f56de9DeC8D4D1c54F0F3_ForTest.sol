/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForTest {
    mapping(address => uint) votes;
    uint r;
    function getWin(address _addr) public returns(uint) {
        uint num = 100;
        uint i;
        for(i = 0; i <= num; i++) {
            uint a = votes[_addr];
        }
        r = i;
        return i;
    }
}