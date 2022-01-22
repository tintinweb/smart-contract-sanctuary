/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract socialtips {

    address owner;    // current owner of the contract

    function socialTips() public  {
        owner = msg.sender;
    }

    function withdraw() public payable {
        require(owner == msg.sender);
        address(this).balance;
    }

    function depositTips(uint256 amount) public payable {
        require(msg.value == amount);
    }

    function getTipBalance() public view returns (uint256) {
        return address(this).balance;
    }
}