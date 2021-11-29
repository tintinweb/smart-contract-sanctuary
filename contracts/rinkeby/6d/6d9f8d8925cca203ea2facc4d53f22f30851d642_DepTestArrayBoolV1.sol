//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepTestArrayBoolV1 {
    bool[] public varArrayBool;

    constructor(bool[] memory _varArrayBool) {
        varArrayBool = _varArrayBool;
    }
}