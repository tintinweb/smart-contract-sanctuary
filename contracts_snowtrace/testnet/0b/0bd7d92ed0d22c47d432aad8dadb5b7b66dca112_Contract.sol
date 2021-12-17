/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-16
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

contract Contract {

    uint256 public oi = 0;
    string public changeme = "asd";

    constructor(uint256 _oi, string memory _changeme) {
        oi = _oi;
        changeme = _changeme;
    }
}