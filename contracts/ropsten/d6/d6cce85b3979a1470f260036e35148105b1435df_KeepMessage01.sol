//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract KeepMessage01 {
    string private greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function message() public view returns (string memory) {
        return greeting;
    }

    function setMessage(string memory _greeting) public {
        greeting = _greeting;
    }
}