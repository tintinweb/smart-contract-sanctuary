pragma solidity ^0.4.23;

contract helloworld {
    string content;

    constructor(string _str) public {
        content = _str;
    }

    function getContent() constant public returns (string) {
        return content;
    }
}