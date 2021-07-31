/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract Counter {
    uint256 private count;
    function increment() public {
        count += 1;
    }
    function get() public view returns (uint256) {
        return count;
    }
}