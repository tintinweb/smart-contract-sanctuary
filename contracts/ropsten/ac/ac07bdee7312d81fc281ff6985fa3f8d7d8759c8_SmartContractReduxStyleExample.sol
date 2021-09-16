/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

contract SmartContractReduxStyleExample {
    address public owner;
    int public count;

    event Increment(address caller, int value);
    event Decrement(address caller, int value);

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    function increment(int x) public {
        unchecked { count += x; }
        emit Increment(msg.sender, x);
    }

    function decrement(int x) public {
        unchecked { count -= x; }
        emit Decrement(msg.sender, x);
    }

    receive() external payable {
        
    }
}