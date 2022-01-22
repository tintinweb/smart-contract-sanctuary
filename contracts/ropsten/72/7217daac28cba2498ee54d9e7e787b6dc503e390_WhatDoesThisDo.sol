/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract WhatDoesThisDo {
    function dunno(uint foo) public payable {
        require(foo > 5, "Oopsy");
    }
}