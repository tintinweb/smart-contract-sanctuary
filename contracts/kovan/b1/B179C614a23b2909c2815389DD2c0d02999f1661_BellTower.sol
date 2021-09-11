/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

pragma solidity ^0.8.4;

contract BellTower {
    
    //Counter for how many times the bell was rung
    uint public bellRung;
    
    event BellRung(uint bellRungThisManyTimes, address thisOneRangIt);
    
    function ringTheBell() public {
        
        bellRung ++;
        
        emit BellRung(bellRung, msg.sender);
    }
}