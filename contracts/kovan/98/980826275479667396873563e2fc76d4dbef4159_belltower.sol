/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.8.4;

contract belltower{
    
    //bell counter for how many times it has been rung
    uint public bellRung;

    //event for ringing the bell
    event BellRung(uint rangForNthTime, address whoRangIt);

    //increases bell count
    function ringTheBell() public {
        bellRung++;
    
        emit BellRung(bellRung, msg.sender);
        
    }
    
    
}