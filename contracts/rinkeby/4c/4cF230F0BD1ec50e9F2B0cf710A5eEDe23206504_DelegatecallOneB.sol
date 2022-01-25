// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DelegatecallOneB {
    uint public num;
    address public sender;

    function setVars(uint _num) public payable {
        num = _num;
        sender = msg.sender;
    }
}