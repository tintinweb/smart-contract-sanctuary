pragma solidity ^0.4.18;
contract Deployed {
    uint public a = 1;
    event nlog(uint256 value);
    function setA(uint _a) public returns (uint) {
        a = _a;
        emit nlog (_a); 
        return a;
    }
    
}