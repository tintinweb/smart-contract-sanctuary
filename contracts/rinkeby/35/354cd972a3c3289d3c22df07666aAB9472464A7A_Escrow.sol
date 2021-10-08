/**
 *Submitted for verification at Etherscan.io on 2021-10-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Escrow {
    address public depositor;
    address payable public recipient;
    address public arbiter;
    
    constructor(address _arbiter, address payable _recipient) payable {
        arbiter = _arbiter;
        recipient = _recipient;
        depositor = msg.sender;
    }
    
    function releaseFunds() external {
        require(msg.sender == arbiter);
        recipient.transfer(address(this).balance);
    }
    
}