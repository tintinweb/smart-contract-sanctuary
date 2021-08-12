/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity ^0.8.2;

contract Test {
    
    uint256 private unlocked = 1;
    uint256 private random1 = 1;
    uint256 private random2 = 1;
    
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 2;
        _;
        unlocked = 1;
    }
    
    modifier unlockedOnly() {
        require(unlocked == 1, "LOCKED");
        _;
    }
    
    function usesLock() public lock {
        random1 = block.timestamp;
    }
    
    function noLock() public unlockedOnly {
        random2 = block.timestamp;
    }
    
    function test() public returns (uint256 with, uint256 without) {
        uint256 tmp = gasleft();
        usesLock();
        with = tmp - gasleft();
        tmp = gasleft();
        noLock();
        without = tmp - gasleft();
    }
    
    // 10195 / 28988
    // 5044  / 26637
    
    // { "0": "uint256: with 10195", "1": "uint256: without 5044" }
    // { "0": "uint256: with 10195", "1": "uint256: without 5167" } 
    
}