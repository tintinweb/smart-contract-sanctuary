/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.17;

contract ParmCoin {

    // core data types
    
    int a; // Default is int256
    uint b;
    string c;
    bool d;
    mapping(address => string) e; // JSON object
    mapping(uint256 => address) f; // JSON object - nft style
    mapping(address => uint256) g; // JSON object - balance style
    address private _owner;

    constructor(uint256 people) public { // This is run when deployed
        b = people;
        
    }
    
    function add(uint256 val) public {
        b += val;
    }
    
}