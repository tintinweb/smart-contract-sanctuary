/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;


contract FullName {
    
    string firstName = "";
    string lastName = "";
    
    constructor(string memory _firstName, string memory _lastName) {
        firstName = _firstName;
        lastName = _lastName;
    }
    
    function setFirstName(string memory _firstName) public {
        firstName = _firstName;
    }
    
    function setLastName(string memory _lastName) public {
        lastName = _lastName;
    }
    
    function getfirstName() public view returns (string memory) {
        return firstName;
    }
    
    function getLastName() public view returns (string memory) {
        return lastName;
    }
}