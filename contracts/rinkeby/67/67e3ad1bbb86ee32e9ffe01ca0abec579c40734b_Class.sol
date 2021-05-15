// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Class {

    string name;
    string teacher_name;

    function store(string memory _name,string memory _teacher_name) public {
        name = _name;
        teacher_name = _teacher_name;
    }

}