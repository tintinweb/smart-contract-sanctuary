//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepTestArrayStringV1 {
    string[] public varArrayString;

    constructor(string[] memory _varArrayString) {
        varArrayString = _varArrayString;
    }
}