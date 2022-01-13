/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract AgniVisions {
    address public owner;
    uint256 public balance;
    event Received(address, uint);

    constructor() {
        owner = msg.sender;
    }

    receive() payable external {
        balance += msg.value;
        emit Received(msg.sender, msg.value);
    }
}