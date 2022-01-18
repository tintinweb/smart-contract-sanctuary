// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Festivus {

uint256 public someNumber;

function initialize(uint256 thatNumber_) public {

    someNumber = thatNumber_;
}

function getNumber() public view returns (uint256) {
    return someNumber;
}

    
}