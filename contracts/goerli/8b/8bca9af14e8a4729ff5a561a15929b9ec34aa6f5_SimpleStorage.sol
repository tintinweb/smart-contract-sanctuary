/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    string storedData;

    function set(string x) public {
        storedData = x;
    }

    function get() public view returns (string ) {
        return storedData;
    }
}