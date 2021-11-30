/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Data {

    uint public number = 0;

    function setNumber(uint _nbr) external {
        number = _nbr;
    }
}