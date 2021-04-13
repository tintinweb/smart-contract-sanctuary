/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.0;
contract RolloverExample {
    uint8 public myUint8;
    function decrement() public {
        myUint8--;
    }
    function increment() public {
        myUint8++;
    }
}