/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// NOTE: Deploy this contract first
contract delegateCalled {
    // NOTE: storage layout must be the same as contract A
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}