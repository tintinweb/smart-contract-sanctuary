// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MyStringStore {
    string public myString = "Hello World";

    event SetString(string value);
    event UpdateString(string oldValue, string newValue);

    function set(string memory x) public {
        myString = x;
        emit SetString(x);
    }

    function update(string memory newValue) public {
        string memory oldValue = myString;
        myString = newValue;
        emit UpdateString(oldValue, newValue);
    }
}