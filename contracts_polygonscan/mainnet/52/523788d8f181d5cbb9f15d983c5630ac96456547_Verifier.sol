/**
 *Submitted for verification at polygonscan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Verifier {

    mapping (address => uint128) public hashmap;


    constructor(){
    }
    
    function getHash(address wallet) public view returns(uint128){
        return hashmap[wallet];
    }

    function setHash(uint128 hash) public {
        hashmap[msg.sender] = hash;
    }
}