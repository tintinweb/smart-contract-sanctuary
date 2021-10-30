/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-103 ===

    STATUS: in progress
    DEPLOYED AT: 0x909f76fa6d9121302e0ff9F20EDaC7352135e621

    VULNERABILITY REPRODUCTION STEPS:
    1. Compile the contract using Solc 0.4.20 & deploy;
    2. Call deposit() with an arbitrary non-zero value;
    3. Call activate_withdraws()
    4. Call withdraw() and confirm its success;
    5. Compile the contract using Solc 0.4.1 & deploy;
    6. Repeat steps 2-3 and observe failure.
    
    EXPECTED OUTCOME:
    The user is able to withdraw deposited funds for all
    versions of Solidity compiler.
    
    ACTUAL OUTCOME:
    The user is not able to withdraw deposited funds. The 
    behavior of the smart contract is affected by the
    compiler version.
    
    NOTES:
    None.
*/


pragma solidity ^0.4.0;

library Bar {
    function status() public returns (bool) {
        return true;
    }
}

contract Foo {
    bool withdraw_activated;
    
    function deposit() public payable returns (bool) {
        return true;
    }
    
    function activate_withdraws() public payable {
        withdraw_activated = Bar.status();
    }

    function withdraw() public {
        if(withdraw_activated) {
            msg.sender.send(address(this).balance);    
        }
    }
}