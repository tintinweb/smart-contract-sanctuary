/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Web3Actions {

    event HelloWorld(address indexed _recipient);

    function hello(address recipient) public {
        emit HelloWorld(recipient);
    }
}