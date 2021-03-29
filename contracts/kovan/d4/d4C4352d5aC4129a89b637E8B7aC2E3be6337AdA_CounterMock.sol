/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract CounterMock {
    uint256 public count;

    function increase(uint256 step) public {
        require(step < 10, "Counter: increase step size should less then 10");
        count += step;
    }
}