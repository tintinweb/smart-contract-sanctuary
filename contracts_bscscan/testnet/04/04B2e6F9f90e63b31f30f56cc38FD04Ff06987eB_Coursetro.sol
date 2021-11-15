// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Coursetro {

    string fName;
    uint age;

    event Instructor(
        string  name,
        uint age
    );

    function setInstructor(string memory _fName, uint _age) public {
        fName = _fName;
        age = _age;
        emit Instructor(_fName, _age);
    }

    function getInstructor() view public returns (string memory, uint) {
        return (fName, age);
    }

}

