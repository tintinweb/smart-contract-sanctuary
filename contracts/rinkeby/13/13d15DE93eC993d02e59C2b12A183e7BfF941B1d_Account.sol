/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Account {

    uint public balance;

    function addBalance() public {
        balance++;
    }
}