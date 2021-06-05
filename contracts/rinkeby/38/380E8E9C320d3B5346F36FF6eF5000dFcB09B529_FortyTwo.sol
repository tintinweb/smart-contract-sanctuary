/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract FortyTwo {
    uint public value = 42;

    function setValue(uint _value) external {
        value = _value;
    }
}