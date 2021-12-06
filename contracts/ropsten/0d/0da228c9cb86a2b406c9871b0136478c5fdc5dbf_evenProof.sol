/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract evenProof {
    event Deposit(
        address from,
        bytes32 _id,
        uint value 
    );

    function theEmiter(bytes32 _id) public payable {
        emit Deposit(msg.sender, _id, msg.value);
    }
}