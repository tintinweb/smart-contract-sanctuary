/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

/* SPDX-License-Identifier: UNLICENSED */
pragma solidity 0.8.9;

contract First {
    string private message;

    constructor() {
        message = "This is my first contract";
    }

    function get() public view returns (string memory) {
        return message;
    }

}