/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForTest {
    mapping(address => uint) votes;
    function getWin(address _addr) public view returns(address) {
        for(uint i = 0; i <= 100000; i++) {
            votes[_addr];
        }
        return _addr;
    }
}