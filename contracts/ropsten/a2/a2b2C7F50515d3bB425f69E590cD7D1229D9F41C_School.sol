/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract School {
     string name;

    struct Class {
        string teacher;
        mapping(string => uint) scores;
    }
    mapping(string => Class) classes;

    function addClass(string calldata className, string calldata teacher) public {
        Class storage class = classes[className];
        class.teacher = teacher;
    }

    function addStudentScore(string calldata className, string calldata studentName, uint score) public {
       Class storage class = classes[className];
       class.scores[studentName] = score;
    }

    function getStudentScore(string calldata className, string calldata studentName) public view returns(uint) {
        // return classes[className].scores[studentName];
        Class storage class = classes[className];
        return class.scores[studentName];
    }


}