pragma solidity ^0.4.11;

contract C {
    uint256 a;
    function setA(uint256 _a) public {
        a = _a;
    }
    
    function getA() constant public returns(uint256)  {
        return a;
    }
    
}