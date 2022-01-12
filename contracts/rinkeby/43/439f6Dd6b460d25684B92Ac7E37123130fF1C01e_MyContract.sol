// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    string private name;

    constructor() {
        name = "Test Name";
    }

    function changeName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}