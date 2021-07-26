/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForTest {
    mapping(address => uint) votes;
    function getWin(address _addr) public view returns(uint) {
        uint num = 1000000;
        uint i;
        for(i = 0; i <= num; i++) {
            uint a = votes[_addr];
        }
        return i;
    }
}