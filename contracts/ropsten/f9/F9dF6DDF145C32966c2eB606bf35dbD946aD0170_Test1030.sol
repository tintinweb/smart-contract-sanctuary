// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test1030 {
    string name;

    constructor(string memory _init) {
        name = _init;
    }

    function setName(string memory _new) public {
        name = _new;
    }

    function readName() public view returns (string memory) {
        return name;
    }
}