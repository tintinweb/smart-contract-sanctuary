/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


contract Test {
    uint256 loopCount = 100000;
    uint256 count;
    uint256 timeStart;
    uint256 timeEnd;
    
    function start() public {
        timeStart = now;
        for (uint i; i < loopCount; i++) {
            count ++;
        }
        timeEnd = now;
    }
    
    function set_loop_count(uint256 value) public {
        loopCount = value;
    }
    
    function show_count() public view returns(uint256) {
        return count;
    }
    
    function show_timer() public view returns(uint256, uint256) {
        return (timeEnd, timeStart);
    }
}