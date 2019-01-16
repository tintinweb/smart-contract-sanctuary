pragma solidity ^0.4.18;
contract Deployed {
    bytes32 public a = "Hello world";
    
    function setA(bytes32 _a) public returns (bytes32) {
        a = _a;
        return a;
    }
    
}