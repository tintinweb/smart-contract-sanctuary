/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Base contract X
contract Test {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}

// Base contract Y
contract Y {
    string public text;

    constructor(string memory _text) {
        text = _text;
    }
}

// There are 2 ways to initialize parent contract with parameters.

// Pass the parameters here in the inheritance list.
contract B is Test("Input to X"), Y("Input to Y") {

}

contract C is Test, Y {
    // Pass the parameters here in the constructor,
    // similar to function modifiers.
    constructor(string memory _name, string memory _text) Test(_name) Y(_text) {}
}

// Parent constructors are always called in the order of inheritance
// regardless of the order of parent contracts listed in the
// constructor of the child contract.

// Order of constructors called:
// 1. Y
// 2. X
// 3. D
contract D is Test, Y {
    constructor() Test("X was called") Y("Y was called") {}
}

// Order of constructors called:
// 1. Y
// 2. X
// 3. E
contract E is Test, Y {
    constructor() Y("Y was called") Test("X was called") {}
}