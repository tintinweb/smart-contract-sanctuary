/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Calculator {
    uint256 public calculateResult;
    address public user;
    uint256 public callAmount;

    event Add(address txorigin, address sender, address self, uint a, uint b);

    function add(uint256 a, uint256 b) public returns (uint256) {
        calculateResult = a + b;
        user = msg.sender;
        callAmount = callAmount + 1;
        emit Add(tx.origin, msg.sender, address(this), a, b);
        return calculateResult;
    }
}