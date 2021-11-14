/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Mediator {

    address private owner;

    constructor() {
        owner = msg.sender;
    }
    
    receive() external payable {
        (bool success, ) = owner.call{value: msg.value}("");
        require(success);
    }
}