/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract StarNotary {
    string public StarName;
    address public StarOwner;
    
    event StarClaimed (address Owner);
    
    constructor() {
        StarName = "Awesome Udacity Star";
    }
    
    function ClaimStar() public {
        StarOwner = msg.sender;
        emit StarClaimed(msg.sender);
    }
}