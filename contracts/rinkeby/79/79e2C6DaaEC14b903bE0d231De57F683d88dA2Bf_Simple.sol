// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract Simple {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
}