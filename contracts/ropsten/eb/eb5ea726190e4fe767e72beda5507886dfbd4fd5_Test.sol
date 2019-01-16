pragma solidity ^0.4.24;

contract Test {
    
    uint256 public number = 3;
    
    function () public {
        increaseNumber();
    }
    
    function increaseNumber() public {
        number++;
    }
    
}