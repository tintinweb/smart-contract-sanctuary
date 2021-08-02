/**
 *Submitted for verification at Etherscan.io on 2021-07-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Counter {
    uint256 private _counter = 0;
    
    function get() public view returns(uint256) {
        return _counter;
    }
    
    function increase() public {
        _counter++;
    }
}