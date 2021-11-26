/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract MyContract {
    uint a = 2;
    uint b = 2;

    function add() external view returns (uint) {
        return a + b;
    }
}