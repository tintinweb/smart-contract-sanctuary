/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint constant secretNumber = 5;

contract secret {
    uint internal _secretNumber;
    constructor(){
        _secretNumber = secretNumber;
    }
    function returnSecretNumber() external view returns (uint) {
        return _secretNumber;
    }
}