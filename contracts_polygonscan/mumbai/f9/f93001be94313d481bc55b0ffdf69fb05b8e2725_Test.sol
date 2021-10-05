/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


contract Test {
    uint256 count;
    uint256 timer_start;
    uint256 timer_end;
    
    function start() public {
        timer_start = now;
        for (uint i; i < 1000000; i++) {
            count ++;
        }
        timer_end = now;
    }
    
    function show_count() public view returns(uint256) {
        return count;
    }
    
    function show_timer() public view returns(uint256, uint256) {
        return (timer_end, timer_start);
    }
}