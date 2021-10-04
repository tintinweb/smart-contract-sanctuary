/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract PaymentForwarder {
    event ForwarderDepositedWithParam(address from, address to, uint value, string externalReference);

    constructor() {
    }

    function forward(address receiver, string calldata externalReference) external payable {
        payable(receiver).transfer(msg.value);
        emit ForwarderDepositedWithParam(msg.sender, receiver, msg.value, externalReference);
    }
}