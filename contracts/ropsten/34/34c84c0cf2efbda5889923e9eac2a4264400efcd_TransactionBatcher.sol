/**
 *Submitted for verification at Etherscan.io on 2021-10-03
*/

/// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

/// By Saga Reserve

contract TransactionBatcher {
    function batchSend(address[] calldata targets, uint[] calldata values, bytes[] calldata datas) public payable {
        for (uint i = 0; i < targets.length; i++) {
            targets[i].call{value: values[i]}(datas[i]);
        }
    }
}