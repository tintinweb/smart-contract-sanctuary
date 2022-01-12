/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.10;

contract Escrow {

    address agent; 
    mapping (address => uint256) public deposits;

    modifier onlyAgent() {
        require(msg.sender == agent);
        _;
    }

    constructor() public {
        agent = msg.sender;
    }

    function deposit(address payee) public onlyAgent payable {
        uint256 amount = msg.value; 
        deposits[payee] = deposits[payee] + amount;
    }

    function withdraw(address payable payee) public onlyAgent {
        uint256 payment = deposits[payee]; 
        deposits[payee] = 0; 
        payee.transfer(payment);
    }
}