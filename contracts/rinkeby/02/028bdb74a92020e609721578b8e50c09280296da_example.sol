/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract example {

    uint public mintPrice = 1*10**16;
    bool public isActive = true;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function mint(uint amount) public payable {
        require(msg.value>=mintPrice*amount, "Price not met.");
    }

}