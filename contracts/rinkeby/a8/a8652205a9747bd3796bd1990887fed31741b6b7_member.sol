/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract member {
    ContractA _a;

    constructor(address _sender) {
        _a = ContractA(_sender);
    }

    function callA() public {
        _a.log();
    }
}

contract ContractA {
    event Log(string message);

    function log() public {
        emit Log("ContractA was called");
    }
}