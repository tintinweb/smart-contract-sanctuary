/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Callee {

    constructor() {}

    /// 0x9ea40c3e
    event Called(address indexed from);

    /// 0xef5fb05b
    function sayHello() public returns (string memory) {
        emit Called(msg.sender);
        return "Hello, World!";  // doesnt get sent back
    }

    /// 0x5d40af9c
    function sayHelloFrom(address from) public {
        emit Called(from);
    }
}