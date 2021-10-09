/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TransactionForwarder {
    event TransactionForwardedWithRef(address from, address to, uint value, string ref);

    constructor() {
    }

    function forward(address receiver, string calldata ref) external payable {
        payable(receiver).transfer(msg.value);
        emit TransactionForwardedWithRef(msg.sender, receiver, msg.value, ref);
    }
}