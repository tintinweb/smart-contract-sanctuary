/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

contract MiyabiVault {

    event Lock(address indexed _from, address _to, uint _value);

    function lock(address _to) public payable {
        emit Lock(msg.sender, _to, msg.value);
    }
}