/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SetUsername {
    mapping(address => string) public userName;

    function setUserName(string calldata userName_) public {
        userName[msg.sender] = userName_;
    }
}