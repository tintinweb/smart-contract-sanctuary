// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract Wallet {
    address payable immutable owner;
    constructor () payable {
        owner = msg.sender;
    }

    receive() external payable {
    }

    function transfer(address payable _target, uint _value) external payable {
       require(msg.sender == owner, "403");
       _target.transfer(_value);
    }
}