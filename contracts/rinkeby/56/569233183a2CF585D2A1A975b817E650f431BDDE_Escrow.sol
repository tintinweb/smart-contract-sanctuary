/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Escrow {
    address public depositor; //this is the person paying
    address public arbiter; //this is the trusted person
    address payable public recipient; // this is who is paid
    
    constructor(address _arbiter, address payable _recipient) payable {
        arbiter = _arbiter;
        recipient = _recipient;
        depositor = msg.sender; //whoever calls this function
    }
    
    // this is what will be called by the arbiter, once all parties
    // are happy :)
    function releaseFunds() public {
        require(msg.sender == arbiter);
        recipient.transfer(address(this).balance);
    }
    
}