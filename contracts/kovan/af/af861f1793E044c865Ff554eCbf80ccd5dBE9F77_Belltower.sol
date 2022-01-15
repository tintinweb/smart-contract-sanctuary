/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.8.4;

contract Belltower {
    // Counter of how many times the bell has been rung;
    uint public bellRung;
    // Event for ringing a bell;
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    function ringTheBell() public {
        bellRung++;
        emit BellRung(bellRung, msg.sender);
    }
}