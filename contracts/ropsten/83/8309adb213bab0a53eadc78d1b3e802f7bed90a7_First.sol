pragma solidity ^0.4.24;

contract First {
    uint256 public counter;
    
    constructor() public {
        counter = 0x00000001;
    }
    
    function Increment() public returns (uint256 old) {
        old = counter;
        counter = counter + 1;
    }
}