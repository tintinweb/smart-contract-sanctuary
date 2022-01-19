/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {

    address[] public add;

    function count(address[] calldata data)public{
        
        add = data;
    }

}