/**
 *Submitted for verification at Etherscan.io on 2020-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

contract PointlessWasteOfSpace{
    
    event PointlessEvent(string message);
    
    constructor() public {
        emit PointlessEvent("There is no point in deploying this contract. Seriously...");
    }
}