/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint256 public value;

    function set(uint256 amount) public {
        value += amount;
    }

    // function get() public view returns (uint256) {
    //     return storedData;
    // }
}