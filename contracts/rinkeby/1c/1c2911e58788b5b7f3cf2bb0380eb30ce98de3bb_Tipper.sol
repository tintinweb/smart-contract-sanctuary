/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Tipper {
    address payable public owner;
    uint public property;

    constructor() {
        owner = payable(msg.sender);
        property = 3;
    }

    function sendTransaction(address receiver, uint ownerTip, uint receiverAmount) public payable {
        owner.transfer(ownerTip);
        payable(receiver).transfer(receiverAmount);
    }
}