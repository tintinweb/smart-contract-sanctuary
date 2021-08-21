/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HelloWorld {
    // Product property
    string public name = 'Tot Nattapon';
    uint256 public age = 25;
    
    // Authorization
    // address public owner;
    
    constructor() {
        // owner = msg.sender;
    }
    
    function updateName(string memory newName) public {
        // require(owner == msg.sender, "sender is not owner!");
        name = newName;
    }
}