/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.8.4;

contract BellRung {
    
    uint public ringCounter;
    
    event Ring(uint count, address who);
    
    function ringBell() public {
        ringCounter++;
        emit Ring(ringCounter, msg.sender);
    }
    
}