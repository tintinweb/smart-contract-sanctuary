/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract SimplrStorage {

    // this wil be = 0
    string word;

    constructor(string memory message) {
        word = message;
    }

    function ShowMessage() public view returns (string memory)  {
        return word;
    }

}