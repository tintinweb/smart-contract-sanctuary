/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Hello {
    struct Student {
        uint8 id;
        string name;
        uint8 age;
    }
    
    Student public david;
    
    constructor() {
        david = Student(1, "david", 30);
    }
    
    function getDavidId() public view returns (uint8) {
        return david.id;
    }
    
    function getDavid() public view returns (Student memory) {
        return david;
    }
}