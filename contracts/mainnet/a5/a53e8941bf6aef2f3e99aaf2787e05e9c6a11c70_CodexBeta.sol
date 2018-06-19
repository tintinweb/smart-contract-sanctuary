pragma solidity ^0.4.16;
 
contract CodexBeta {
    struct MyCode {
        string code;
    }
    event Record(string code);
    function record(string code) public {
        registry[msg.sender] = MyCode(code);
    }
    mapping (address => MyCode) public registry;
}