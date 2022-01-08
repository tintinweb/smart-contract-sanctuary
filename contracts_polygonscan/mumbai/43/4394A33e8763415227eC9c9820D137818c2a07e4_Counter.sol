/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Counter {
    uint public count = 0;

    function incrementCount() public returns(uint) {
        count++;
        return count;
    }
}