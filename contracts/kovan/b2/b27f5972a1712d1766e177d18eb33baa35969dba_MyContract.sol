/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract MyContract {
    
    uint256 a = 0;

    function Add(uint256 _n) public {
        a += _n;
    }
    
}