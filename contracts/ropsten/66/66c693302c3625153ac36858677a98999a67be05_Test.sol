pragma solidity ^0.4.0;

contract Test {
    // member variables
    int counter = 0;
    function test() public pure returns(string) { 
        return "hello world!";
    }
    string public message;
    function set(string m) public {
        message = m;
    }
}