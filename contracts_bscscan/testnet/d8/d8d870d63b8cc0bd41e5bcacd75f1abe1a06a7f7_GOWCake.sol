/**
 *Submitted for verification at BscScan.com on 2021-08-02
*/

// Create By https://dexmax.cc
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract GOWCake {
    address public addr;

    constructor() public {
        GOWCakeDividendTracker dividendTracker = new GOWCakeDividendTracker();
        addr = address(dividendTracker);
    }
}

contract GOWCakeDividendTracker {
    string public _name;
    constructor() public {
        _name = "BBB";
    }
}