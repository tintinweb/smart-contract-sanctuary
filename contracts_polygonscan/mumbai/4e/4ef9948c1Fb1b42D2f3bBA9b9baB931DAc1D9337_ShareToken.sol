//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ShareToken {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {
        uint256 value = msg.value / 2;
        owner.transfer(value);
    }
}