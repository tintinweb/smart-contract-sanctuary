//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


contract Greeter {
    string private greeting;
    string private _hello;

    constructor(string memory _greeting) {
        greeting = _greeting;
        _hello = "cuong";
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function hello() public view returns (string memory) {
        return _hello;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}