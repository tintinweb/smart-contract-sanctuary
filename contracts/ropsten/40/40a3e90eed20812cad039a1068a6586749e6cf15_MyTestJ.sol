pragma solidity ^0.4.0;

contract MyTestJ {
    string public name;
    
    constructor() public {
        name = "hello";
    }
    
    function setTheName(string _name) public {
        require(!(compareStrings(_name, "hello")), "plese not hello");
        name = _name;
    }
    
    function compareStrings (string a, string b) internal pure returns (bool) {
       return keccak256(a) == keccak256(b);
   }
}