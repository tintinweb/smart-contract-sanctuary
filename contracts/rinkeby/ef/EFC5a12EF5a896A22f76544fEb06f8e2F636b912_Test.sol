/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;


contract Test {
    
    mapping (uint32 => mapping(address => bool)) userAddr2; 
    

    
   
    
    function addNew(uint32 raceId,address[] memory users) external {
         for (uint i = 0; i < users.length; i++) {
            userAddr2[raceId][users[i]] = true;
        }
    }
    function getWhiteList2(uint32 raceId,address test) external view returns(bool) {
        return userAddr2[raceId][test];
    } 
}