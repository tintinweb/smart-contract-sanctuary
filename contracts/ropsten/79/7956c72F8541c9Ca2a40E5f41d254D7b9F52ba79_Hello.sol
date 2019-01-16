pragma solidity ^0.4.18;
contract Hello {
    string helloMsg;
    
    constructor(string msgArg) public {
        helloMsg = msgArg;
    }
    
    function sayHello() public constant returns (string) {
        return helloMsg;
    }
}