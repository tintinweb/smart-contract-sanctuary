/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.22;

contract Foo {
    bool withdraws_activated;
    
    function Foo() public {
        withdraws_activated = true;
    }
    
    function deposit() payable returns (bool) {
        address(this).transfer(msg.value);
        return true;
    }
    
    function withdraw() public {
        if(withdraws_activated) {
            msg.sender.transfer(this.balance);
        }
    }
    
    constructor() {}
}