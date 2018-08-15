pragma solidity ^0.4.24;

contract Test {
    uint public aa;
    
    constructor(uint _a) public {
        aa = _a;
    }
    
    function SetA(uint _a) public {
        aa = _a;
    }
}