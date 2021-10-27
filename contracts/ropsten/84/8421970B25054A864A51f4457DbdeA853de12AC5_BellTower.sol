/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract BellTower {
    uint public bellRung;
    event BellRung(uint rangForNthTime, address whoRangIt);
    
    function ringTheBell() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}