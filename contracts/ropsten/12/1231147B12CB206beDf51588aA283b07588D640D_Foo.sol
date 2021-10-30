/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-102 ===

    STATUS: complete
    DEPLOYED AT: 0x1231147B12CB206beDf51588aA283b07588D640D

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() with an arbitrary non-zero value;
    2. Call withdraw()
    
    EXPECTED OUTCOME:
    The balance of the smart contract transferred to the caller.
    
    ACTUAL OUTCOME:
    The withdraw() call fails.
    
    NOTES:
    None
*/

pragma solidity 0.4.22;

contract Foo {
    bool withdraws_activated;

    function deposit() payable returns (bool) {
        return true;
    }

    function Foo() {}
    
    function withdraw() public {
        require(withdraws_activated);
        msg.sender.transfer(this.balance);
    }

    constructor() {
        withdraws_activated = true;
    }
}