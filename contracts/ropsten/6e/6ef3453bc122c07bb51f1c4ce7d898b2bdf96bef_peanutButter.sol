/**
 *Submitted for verification at Etherscan.io on 2021-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


contract peanutButter {
    Jelly jelly;

    constructor(address _jelly) {
        jelly = Jelly(_jelly);
    }

    function callJelly() public {
        jelly.log();
    }
}

contract Jelly {
    event Log(string message);

    function log() public {
        emit Log("Jelly function was called");
    }
}