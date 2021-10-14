/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract test{
    event Ev(uint256 u);
    uint256 public a;
    function setA(uint256 u) public{
        a = u;
        emit Ev(u);
    }
}