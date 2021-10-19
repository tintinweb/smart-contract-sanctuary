/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



contract Sign { 
    

    function getHash(address str) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(str));
    }
    
}