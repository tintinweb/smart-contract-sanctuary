/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract Message {
    string name;
    address owner;
    
    constructor() {
        name = "hold long profit grow - Allen";
        owner = msg.sender;
    }
    
    function setName (string calldata _name) public {
        require(msg.sender == owner);
        name = _name;
    }
    
    function getName() public view returns(string memory) {
        return name;
    }
    
}