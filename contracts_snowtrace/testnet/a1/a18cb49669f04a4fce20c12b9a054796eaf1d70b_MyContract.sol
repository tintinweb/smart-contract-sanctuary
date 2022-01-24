/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
    // State
    uint256 mycount;
    // Events
    event UpdateCount(uint256);
    // Functions
    function myfunc(uint256 _incValue) public {
        mycount = mycount + _incValue;
        emit UpdateCount(_incValue);
    }
}