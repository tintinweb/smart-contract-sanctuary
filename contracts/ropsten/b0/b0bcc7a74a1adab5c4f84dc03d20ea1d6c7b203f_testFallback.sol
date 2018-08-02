pragma solidity ^0.4.24;

contract testFallback {
    uint256 public increment;
    
    function() public payable {
        increment = increment + 1;    
    }
    
    function incrementValue() public {
        increment = increment + 1;
    }
}