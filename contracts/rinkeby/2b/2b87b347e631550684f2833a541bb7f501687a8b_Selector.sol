/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Selector {
    
    constructor() {} 
    function calculateSelector() public pure returns (bytes4) {
        
        return  bytes4(keccak256('name()')) ^ bytes4(keccak256('symbol()')) ^ bytes4(keccak256('tokenURI(uint256)'));
    
    }
}