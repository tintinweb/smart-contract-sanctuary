/**
 *Submitted for verification at Etherscan.io on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Demo {

    event ValueChanged(address indexed owner, string oldValue, string newValue);

    string _value;

    constructor(string memory value) {
        _value = value;
    }

    function getValue() view public returns (string memory) {
        return _value;
    }

    function setValue(string memory value) public {
        _value = value;
        emit ValueChanged(msg.sender, _value, value);
    }
}