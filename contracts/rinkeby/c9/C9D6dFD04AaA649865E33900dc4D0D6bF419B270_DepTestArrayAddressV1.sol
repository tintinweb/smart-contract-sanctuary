//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DepTestArrayAddressV1 {
    address[] public varArrayAddress;

    constructor(address[] memory _varArrayAddress) {
        varArrayAddress = _varArrayAddress;
    }
}