/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.4;

contract TestContract {
    
    uint256 public value;
    
    function increment(uint256 amount) public {
        value += amount;
    }
}