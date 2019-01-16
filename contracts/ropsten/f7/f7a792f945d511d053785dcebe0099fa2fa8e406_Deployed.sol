pragma solidity ^0.4.18;
contract Deployed {
    string public a = "Hello world";
    
    function setA(string _a) public returns (string) {
        a = _a;
        return a;
    }
    
}