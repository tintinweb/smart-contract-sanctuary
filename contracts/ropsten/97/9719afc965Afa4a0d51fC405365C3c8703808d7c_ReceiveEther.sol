/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReceiveEther{

    address public MyAddress;

    constructor(){
        MyAddress = msg.sender;
    }
}