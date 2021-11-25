/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

pragma solidity ^0.8.10;
contract BellTower {
    // Number of Times You Have Rung This Bell
    uint public bellRung;
    
    // Event for ringing a bell
    event BellRung(uint rangNthTime, address whoRangIt);
    
    // ring the bell
    function ringBell() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}