/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract RkTest2 {
    uint storedData2;

    function set(uint x) public {
        storedData2 = x;
    }

    function get() public view returns (uint) {
        return storedData2;
    }
    function increment() public {
        storedData2++;
    }
}