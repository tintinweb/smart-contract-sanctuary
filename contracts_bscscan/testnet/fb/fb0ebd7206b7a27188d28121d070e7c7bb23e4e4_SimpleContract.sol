/**
 *Submitted for verification at BscScan.com on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

contract SimpleContract {
    uint private data;

    function updateData(uint _data) public {
        data = _data;
    }

    function readData() public view returns (uint) {
        return data;
    }
}