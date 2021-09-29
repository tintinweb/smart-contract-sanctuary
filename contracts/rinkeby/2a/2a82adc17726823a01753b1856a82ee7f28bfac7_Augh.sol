/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// File: Test.sol


pragma solidity ^0.8.6;


contract Augh {
    struct Xnopyt {
        uint256 a;
        uint256 b;
    }
    
    mapping(uint256 => Xnopyt) public xnopyts;
    
    constructor(){}
    
    function setXnopyt(uint256 id, Xnopyt calldata newXnopyt) external {
        xnopyts[id] = newXnopyt;
    }
}