/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Identity {
    string name;
    uint age;

    constructor() {
         name="Ajay";
         age=22;
    }
    function getName() public view returns(string memory) {
        return name;
    }

    function getAge() public view returns(uint) {
       return age; 
    }

    function setName(string memory _name) external {
        name = _name;
    }

    function setAge(uint _age) external {
        age = _age;
    }
}