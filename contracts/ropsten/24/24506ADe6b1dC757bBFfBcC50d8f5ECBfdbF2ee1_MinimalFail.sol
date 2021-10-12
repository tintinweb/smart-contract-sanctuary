/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract MinimalFail {

    address public anAddress;

    constructor() {
        anAddress = msg.sender;
    }


}