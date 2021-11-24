/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract testRestart {

      uint256 s_timeLock = 1609455600;
mapping(address => uint256) public s_lastDay;

   function reset() public returns  (uint256) {
        uint256 numDays;
        if ((block.timestamp - s_timeLock) % 24 hours > 0) {
            numDays = ((block.timestamp - s_timeLock) / 24 hours) + 1;
        } else {
            numDays = (block.timestamp - s_timeLock) / 24 hours;
        }
           require(s_lastDay[msg.sender] < numDays, "Not ready yet");
        s_lastDay[msg.sender] = numDays;
        return s_lastDay[msg.sender]; 
    }

    
    }