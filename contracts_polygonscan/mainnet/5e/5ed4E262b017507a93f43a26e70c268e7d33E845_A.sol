// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract A{
    address owner;
    constructor () public {
        owner = msg.sender;
    }
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}