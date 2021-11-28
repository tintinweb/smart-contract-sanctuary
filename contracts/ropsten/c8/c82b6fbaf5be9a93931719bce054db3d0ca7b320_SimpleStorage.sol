/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// simpleStorage.sol 에 저장

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}