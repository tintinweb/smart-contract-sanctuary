/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Forward {

    function forward(address payable _address) public payable {
        _address.transfer(msg.value);
    }
}