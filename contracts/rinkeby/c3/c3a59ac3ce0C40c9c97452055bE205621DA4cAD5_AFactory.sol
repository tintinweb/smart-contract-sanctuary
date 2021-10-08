// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    function getName() public pure returns(string memory) {
        return "This is the name";
    }
}


contract AFactory {
    function createObject() public returns (address objectAddress) {
        address theObj = address(new A());
        return theObj;
    }
}