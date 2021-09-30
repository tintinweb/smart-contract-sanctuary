/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BellTower {
    // Counter of how many times the bell has been rung
    uint public bellRung;
    
    // Event for ringing the vell
    event BellRung(uint rangForTheNthTime, address whoRangIt);
    
    //Ring the bell
    function ringTheBell() public {
        bellRung++;
        
        emit BellRung(bellRung, msg.sender);
    }
}