/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;
contract A {
    uint public b;
    function saveB(uint _b) public {
        b = _b;
    }
}