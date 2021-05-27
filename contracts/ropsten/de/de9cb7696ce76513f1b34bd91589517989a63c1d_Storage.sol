/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/* AB First Contract

  set, get, increment, and decrement a number 
*/
contract Storage {
    uint256 public number = 10;
    address private owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // For testing purposes, only owner can set a new number but anyone can increment / decrement
    function setNumber(uint256 num) onlyOwner public {
        number = num;
    }

    function increment() public {
        number++;
    }

    function decrement() public {
        number--;
    }

    function getNumber() public view returns (uint256) {
        return number;
    }
}