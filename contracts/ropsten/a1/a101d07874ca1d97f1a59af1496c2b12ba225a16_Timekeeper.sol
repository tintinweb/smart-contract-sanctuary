/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Timekeeper {

    mapping (address => bool) public winners;

    function submitTime(uint256 time) external {
        if (time == block.timestamp) {
            winners[msg.sender] = true;
        }
    }

}