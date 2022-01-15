/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract WAVAX{
    uint public storedData;

    constructor(){
        storedData = 0;
    }

    function set(uint setValue) external {
        storedData = setValue;
    }

    function reset() external {
        storedData = 0;
    }
}