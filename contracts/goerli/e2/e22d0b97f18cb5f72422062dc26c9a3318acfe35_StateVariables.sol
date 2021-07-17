/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity < 0.7.0;

contract StateVariables {
    string name;
    address owner;
    
    constructor() public{
        name = "unknown";
        owner = msg.sender;
    }
    
    function setName(string memory newName) public returns(string memory) {
        if (msg.sender == owner) {
            name = newName;
        } else {
            revert("only owner!");
        }
    }
    
    function getName() public view returns(string memory) {
        return name;
    }
}