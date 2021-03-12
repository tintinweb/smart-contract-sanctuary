/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;


contract JobFactoryBasic {
    string private contactEmail;
    
    constructor(string memory _contactEmail) {
        contactEmail = _contactEmail;
    }
    
    function getEmail() public view returns (string memory) {
        return contactEmail;
    }
    
}