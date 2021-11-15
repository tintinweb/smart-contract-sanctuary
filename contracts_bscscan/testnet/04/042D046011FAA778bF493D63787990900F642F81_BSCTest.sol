// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract BSCTest {
    function balance(address x) public view returns (uint256) {
        return x.balance;
    }
}

