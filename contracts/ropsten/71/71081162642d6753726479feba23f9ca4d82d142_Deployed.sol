pragma solidity ^0.4.18;
contract Deployed {
    uint public a = 1;
    
    function setA(uint _a) public returns (uint) {
        a = _a;
        return a;
    }
    
}