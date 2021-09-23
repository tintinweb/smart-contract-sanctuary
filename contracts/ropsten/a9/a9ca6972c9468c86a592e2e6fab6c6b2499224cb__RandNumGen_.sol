/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract RandNumGen {
    function randInt(uint n) external view returns (uint) {
        return (uint160(address(this)) + block.number) % n;    
    }
}




































contract _RandNumGen_ {
    uint public var620495566;
    
    constructor() {
        var620495566 = 1234567;
    }
    
    function randInt(uint32 n) external view returns (uint) {
        return var620495566 % n; 
    }
    
    function setSeed(uint newSeed) external {
        var620495566 = newSeed;
    }
}