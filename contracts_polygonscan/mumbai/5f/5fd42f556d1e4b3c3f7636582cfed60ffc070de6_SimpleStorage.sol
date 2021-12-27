/**
 *Submitted for verification at polygonscan.com on 2021-12-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SimpleStorage {
    uint num;

    function set(uint _num) public {
        num = _num;
    }

    function get() public view returns (uint) {
        return num;
    }
}