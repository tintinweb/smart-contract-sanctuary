/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Storage {

    uint256 public number;

    function store(uint256 num) public {
        number = num;
    }

}