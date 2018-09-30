pragma solidity ^0.4.7;


contract test {
   
    uint256 public increment;
    
    constructor() public {
        increment = 0;
    }
    
    function increase() public {
        increment++;
    }
}