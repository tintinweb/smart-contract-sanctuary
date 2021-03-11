// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

contract MiyabiVault {

    event Lock(address indexed _from, uint _value);

    function lock() public payable {
        emit Lock(msg.sender, msg.value);
    }
}