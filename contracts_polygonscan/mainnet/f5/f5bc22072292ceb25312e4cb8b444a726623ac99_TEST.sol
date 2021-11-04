/**
 *Submitted for verification at polygonscan.com on 2021-11-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;




contract TEST {
    
    uint256 start;
    
    constructor() {
        start = block.number;
    }
    
    function getstart() public view returns (uint256){
        return start;
    }
    
    function istrue () public view returns (string memory) {
        uint256 end = block.number;
        if (start < end + 50) {
            return "YES"; }
        else {
            return "NO";
        }
        
    }
    
}