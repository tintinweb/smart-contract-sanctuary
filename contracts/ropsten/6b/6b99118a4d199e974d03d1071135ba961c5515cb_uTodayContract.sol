/**
 *Submitted for verification at Etherscan.io on 2021-02-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract uTodayContract {
    string private name;
    uint private age;
    
    function setName(string memory newName) public {
        name = newName;
    }
    
    function setAge(uint newAge) public {
        age = newAge;
    }
    
    function getName() public view returns (string memory) {
        return name;
    }
    
    function getAge() public view returns (uint) {
        return age;
    }
    
}