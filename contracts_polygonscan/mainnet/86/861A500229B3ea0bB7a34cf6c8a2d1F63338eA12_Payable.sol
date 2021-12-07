/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Payable {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function deposit() public payable {}

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}