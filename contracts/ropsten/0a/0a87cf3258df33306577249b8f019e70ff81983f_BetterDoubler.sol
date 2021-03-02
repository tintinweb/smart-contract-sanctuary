/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract BetterDoubler {
    
    address payable owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        if (msg.sender != owner) {
            msg.sender.transfer(msg.value*2);
        }
    }
}