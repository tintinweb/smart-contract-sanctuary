// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    function getName() public pure returns(string memory) {
        return "This is the name";
    }
}


contract AFactory {
    address[] public contractAddresses;
    function createObject() public {
        contractAddresses.push(address(new A()));
    }
}