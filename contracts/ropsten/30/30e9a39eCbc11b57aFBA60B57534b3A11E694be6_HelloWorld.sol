/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract HelloWorld {
    string saySomething;

    constructor() {
        saySomething = "Hello World!";
    }

    function speak() public view returns (string memory) {
        return saySomething;
    }
}