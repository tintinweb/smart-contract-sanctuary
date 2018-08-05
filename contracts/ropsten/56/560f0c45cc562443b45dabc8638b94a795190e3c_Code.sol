pragma solidity ^0.4.24;

contract Code {
    uint public testVar;
    function setTestVar(uint x) public {
        require(x == 1);
        testVar = x;
    }
}