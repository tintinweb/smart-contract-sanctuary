//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    uint256 private greeting;

    // constructor(uint256 _greeting) {
    //     greeting = _greeting;
    // }

    function initialize(uint256 _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (uint256) {
        return greeting;
    }

    function setGreeting(uint256 _greeting) public {
        greeting = _greeting;
    }
}