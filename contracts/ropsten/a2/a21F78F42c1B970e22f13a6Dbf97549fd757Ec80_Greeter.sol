//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.4;

contract Greeter {
    string private id;
    string private text;
    string private message;
    string private greeting = "";

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}

