/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

pragma solidity ^0.7.0;

contract MultipleByRatio {
    uint256 x;
    
    constructor() {
        x = 3;
    }
    
    function multiply(uint256 y) public view returns (uint256) {
        return x * y;
    }
}