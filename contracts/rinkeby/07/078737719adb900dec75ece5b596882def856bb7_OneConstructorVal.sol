/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract DoesNothing {
    uint256 public stateVar = 50;
}

contract OneConstructorVal {
    string public stateVar;
    constructor(string memory val) {
        stateVar = val;
    }
}