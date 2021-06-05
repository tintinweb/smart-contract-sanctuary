/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Test {
    uint256 public constant MAX = ~uint256(0);
    uint256 public _tTotal = 1000000000 * 10**6 * 10**18;
    uint256 public _rTotal = (MAX - (MAX % _tTotal));
}