/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
// pragma experimental ABIEncoderV2;

contract Finance {
    uint public totalSupply;

    constructor(uint _totalSupply) public {
        totalSupply = _totalSupply;
    }
}