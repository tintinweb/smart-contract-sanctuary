pragma solidity ^0.4.24;

contract Test {
    uint public a;
    
    constructor(uint _a) public {
        a = _a;
    }
    
    function SetA(uint _a) public {
        a = _a;
    }
}