// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RegisterName {
    string public name;    
    address public owner;

    constructor() {
        owner = msg.sender;
        name = "Solange Gueiros";
    }
}