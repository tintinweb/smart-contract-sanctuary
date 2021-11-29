//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepTestArrayIntV1 {
    int256[] public varArrayInt;

    constructor(int256[] memory _varArrayInt) {
        varArrayInt = _varArrayInt;
    }
}