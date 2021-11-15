// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract BSCTest {
    function balance() public view returns (uint256) {
        return msg.sender.balance;
    }
}

