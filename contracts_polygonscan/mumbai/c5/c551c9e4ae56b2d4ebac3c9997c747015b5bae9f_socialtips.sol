/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.19;

contract socialtips {

     address owner;    // current owner of the contract

    function Tipsocial() public {
        owner = msg.sender;
    }

    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function deposit(uint256 amount) public payable {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}