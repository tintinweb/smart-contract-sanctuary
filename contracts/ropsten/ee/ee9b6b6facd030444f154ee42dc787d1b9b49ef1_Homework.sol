/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;contract Homework {

    mapping(address => string) public submitters;

    function store(string memory BSON340115) public {
        submitters[msg.sender] = BSON340115;
    }

}