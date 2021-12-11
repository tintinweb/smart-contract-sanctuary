// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Store {
    event ItemSet(string key, string value);

    string public version;
    mapping (string => string) public items;

    constructor(string memory _version) public {
        version = _version;
    }

    function setItem(string memory key, string memory value) external {
        items[key] = value;
        emit ItemSet(key, value);
    }
}