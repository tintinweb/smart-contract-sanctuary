/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract SimpleStorage {
    // State variable to store a number
    uint public num;

    // You need to send a transaction to write to a state variable.
    function set(uint _num) public {
        num = _num;
    }

    // You can read from a state variable without sending a transaction.
    function get() public view returns (uint) {
        return num;
    }
}