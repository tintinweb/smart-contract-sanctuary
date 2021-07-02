/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    string name;
    uint8 age;
    
    constructor (string memory _name, uint8 _age) {
        name = _name;
        age = _age;
    }
    
    function getName() public view returns (string memory) {
        return name;
    }
    
    function getAge() public view returns (uint8) {
        return age;
    }
    
}