/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;
contract Contract {
    // storage variable
    uint x;

    function changeX(uint _x) external {
        // SSTORE
        x = _x;
    }
}