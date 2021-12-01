/**
 *Submitted for verification at Etherscan.io on 2021-12-01
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-109 ===

    STATUS: [complete]
    DEPLOYED AT: 0xa41FcDcFd7dbB22E48ff954Cd5A5EFB3D4CDe18B

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() with some ether
    2. Call setBalance() with 0, 135
    3. Call kamikaze() with 135
    
    EXPECTED OUTCOME:
    The passcode 135 is not correct so contract will
    not self destructs

    ACTUAL OUTCOME:
    The password is changed and the contract self destructs

    NOTES:
*/

pragma solidity ^0.4.19;

contract StoragePointer {
    struct Bank {
        uint256 balance;
    }

    function kamikaze(uint256 pcode) public {
        require(password == pcode);
        selfdestruct(msg.sender);
    }

    uint256 public password = 12354;

    mapping(uint256 => Bank) banks;

    function setBalance(uint256 index, uint256 balance) public {
        Bank storage bank;
        bank.balance = balance;
    }

    function deposit() public payable {

    }
}