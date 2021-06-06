/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
contract SampleContract {

uint private value;

constructor (uint _initValue) {
    value=_initValue;
}
function getValue() view public returns (uint) {
    return value;
}
function increasevalue(uint delta) public {
    value=value+delta;
}
}