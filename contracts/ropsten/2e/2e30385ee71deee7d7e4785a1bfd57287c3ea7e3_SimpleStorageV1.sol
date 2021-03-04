/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SimpleStorageV1 {
    uint storedData;

    event Change(string message, uint newVal);

    function getName() pure public returns (string memory) {
        return "SimpleStorageV1";
    }

    function set(uint x) public {
//        emit Change("set", x);
        storedData = x;
    }

    function get() view public returns (uint retVal) {
        return storedData;
    }
}