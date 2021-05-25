/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract School {
    struct Instructor {
        string name;
        uint age;
    }

    mapping(address => Instructor) instructors;
    address[] instructorAddresses;

    function getInstructor(address _address) public view returns (string memory, uint) {
        return(instructors[_address].name, instructors[_address].age);
    }

    function setInstructor(address _address, string memory _name, uint _age) public {
        if (instructors[_address].age == 0) {
            instructorAddresses.push(_address);
        }

        instructors[_address].age = _age;
        instructors[_address].name = _name;
    }

    function getInstructorCount() public view returns (uint) {
        return instructorAddresses.length;
    }
}