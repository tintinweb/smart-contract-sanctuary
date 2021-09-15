/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

contract HelloWorld {
    
    string public name = 'Hello Contracts';
    
    event HelloScotchy(string _name);
    
    function getName()public view returns (string memory){
        return name;
    }
    
    constructor(string memory newName) public {
        name = newName;
    }
    
    function setName(string memory _name) public returns (string memory)  {
        name = _name;
        emit HelloScotchy(_name);
        return name;
    }
    
}