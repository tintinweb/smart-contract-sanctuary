/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherStore {
    
    function checkIDValidity2(uint256 id) public pure returns(bool) {
        if (id >= 58000) return false;
        uint256 base;
        if (id < 1000) {
            base = id / 100;
            if (6 <= base) return false;
        } else if (id < 10000) {
            base = ((id / 10) % 100) / 10;
            if (6 <= base) return false;
        } else {
            base = (id / 100) % 10;
            if (6 <= base) return false;
        }
        return true;
    }



    function checkIDValidity(uint256 id) public pure returns(bool) {
        
        if(id >= uint256(58000)) return false;
        
        uint8 nStart;
        uint8 nEnd;
        
        if(id < 7000) {
            nStart = 0;
            nEnd = 7;
        } else if(id >= 7000 && id < 19000) {
            nStart = 7;
            nEnd = 19;
        } else if(id >= 19000 && id < 29000) {
            nStart = 19;
            nEnd = 29;
        } else if(id >= 29000 && id < 41000) {
            nStart = 29;
            nEnd = 41;
        } else if(id >= 41000 && id < 58000) {
            nStart = 41;
            nEnd = 58;
        }
        
        for(uint8 n = nStart; n < nEnd; n++) {
            uint256 base = n*1000; // This will give, 0, 1000, 2000...
            uint256 prohibitedFrom = base + 600; // This will give 600, 1600...
            uint256 prohibitedTo = base + 999; // This will give 999, 1999, 2999...
            if(id >= prohibitedFrom) {
                if(id <= prohibitedTo) return false;
            }
        }
        
        return true;
    }



}