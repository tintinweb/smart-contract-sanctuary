/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract helloworld {
    
    string public message;
    
    constructor(string memory initMessage) {
        
        message = initMessage;

    }
    
    function update(string memory newMessage) public {
        
        message = newMessage;
    }
    
    
}