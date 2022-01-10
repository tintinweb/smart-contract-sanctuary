/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface StubIERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract TestCondition {

    event Transfer(TransferInfo transferInfo, bytes data);

    struct TransferInfo {
        StubIERC20 token;
        address receiver;
        uint256 amount;
    }

    function transfer(TransferInfo calldata transferInfo, bytes calldata data) external {
        emit Transfer(transferInfo, data);
    }
}