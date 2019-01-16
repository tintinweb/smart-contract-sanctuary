pragma solidity ^0.4.21;

contract ABC{
    constructor() public {
        
    }
    function plus(uint256 a, uint256 b) pure public returns(uint256){
        return a + b;
    }
}