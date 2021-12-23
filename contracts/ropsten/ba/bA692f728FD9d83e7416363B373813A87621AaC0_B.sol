/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

//  Base contract X
contract X {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}

//  Base contract Y
contract Y {
    string public text;

    constructor(string memory _text) {
        text = _text;
    }
}

//  Contracts can inherit from multiple parent contracts.
//  two ways to initialize parent contract with parameters.

//  Pass the parameters here in the inheritance list.
contract B is X("Input to X"), Y("Input to Y") {

}

//  Pass the parameters here in the constructor, similar to function modifiers.
contract C is X, Y {
    constructor(string memory _name, string memory _text) X(_name) Y(_text) {}
}