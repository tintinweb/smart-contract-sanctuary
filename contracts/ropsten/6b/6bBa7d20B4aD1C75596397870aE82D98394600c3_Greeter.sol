//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract Greeter {
    string private greeting;
    event UpdateGreeting(string old);
    //event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
        emit UpdateGreeting(greeting);
    }
}

