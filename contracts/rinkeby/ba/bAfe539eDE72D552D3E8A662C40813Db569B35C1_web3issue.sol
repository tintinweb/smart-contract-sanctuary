/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract web3issue{
    address public creator;
    string public name;
    constructor() public {
        creator= msg.sender;
        name = "Kankan";
    }
}