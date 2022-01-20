//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ACPIOne {
    uint256 public number;
    event APCIOneCreated(address newContract);

    address public owner;
    constructor(uint256 _number) {
        owner = msg.sender;
        number = _number;
        emit APCIOneCreated(address(this));
    }

}