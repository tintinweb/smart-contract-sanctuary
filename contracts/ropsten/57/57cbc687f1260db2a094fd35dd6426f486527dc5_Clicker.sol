/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Clicker {
    uint8 public clicks;

    constructor() {
        clicks = 0;
    }

    function click() public {
        clicks += 1;
    }
}