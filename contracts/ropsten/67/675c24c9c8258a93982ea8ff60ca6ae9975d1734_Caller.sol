/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Caller {

    function storeAction(address addr) external {
        Callee c = Callee(addr);
        c.storeValue(100);
    }
}

abstract contract Callee {
    function storeValue(uint value) external virtual;
}