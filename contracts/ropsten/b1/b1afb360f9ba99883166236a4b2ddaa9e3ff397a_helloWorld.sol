pragma solidity ^0.4.0;

contract helloWorld {

    function sayHello() public returns (string) {
        return "Hello world!";
    }
    
    function sayAnything(string _wordsToSay) public returns (string) {
        return _wordsToSay;
    }
}