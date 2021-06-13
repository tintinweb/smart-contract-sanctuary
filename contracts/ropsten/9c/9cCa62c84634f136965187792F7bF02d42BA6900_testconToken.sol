/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : LLLO
// Name          : Live Code Stream Token
// Total supply  : 100000
// Decimals      : 2
// Owner Account : {{Owner Account}}
//
// Enjoy.
//
// (c) by Juan Cruz Martinez 2020. MIT Licence.
// ----------------------------------------------------------------------------

contract testconToken {

    uint256 value;

    constructor (uint256 _p) {
        value = _p;
    }

    function setP(uint256 _n) payable public {
        value = _n;
    }

    function setNP(uint256 _n) public {
        value = _n;
    }

    function get () view public returns (uint256) {
        return value;
    }
}