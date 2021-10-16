/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract SignalMonitor {
    // Store owner address
    address private owner;
    
    // Store how many events have ocurred
    uint public eventCount;
    
    // Constructore: store the owner's address
    constructor() {
        owner = msg.sender;
    }
    
    // Log the percentage reported in each event
    event Log(address sender, int indexed percentage);
    
    // Increase the eventCount and store the reported percentage in the log
    function increase (int percentage) public {
        require(msg.sender == owner, "Only the owner is authorized to report events");
        
        eventCount++;
        
        emit Log(msg.sender, percentage);
    }

    // Read the ammount of events
    function get() public view returns (uint) {
        return eventCount;
    }
}