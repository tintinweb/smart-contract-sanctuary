/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PaymentForwarder {
    event PaymentForwardedWithRef(address from, address to, uint value, string ref);

    constructor() {
    }

    function forward(address receiver, string calldata ref) external payable {
        payable(receiver).transfer(msg.value);
        emit PaymentForwardedWithRef(msg.sender, receiver, msg.value, ref);
    }
}