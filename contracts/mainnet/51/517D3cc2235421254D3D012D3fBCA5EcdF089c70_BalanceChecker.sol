// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BalanceChecker {
    function checkBalance(address account) public view returns (uint256) {
        return account.balance;
    }
}