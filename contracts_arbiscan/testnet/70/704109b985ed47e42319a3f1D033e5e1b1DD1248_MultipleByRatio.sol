/**
 *Submitted for verification at arbiscan.io on 2021-11-10
*/

pragma solidity ^0.7.0;

contract MultipleByRatio {
    uint256 x;
    
    constructor() {
        x = 100;
    }
    
    function multiply(uint256 y) public view returns (uint256) {
        return x * y;
    }
    
    function add(uint256 y) public view returns (uint256) {
        return x + y;
    }
}