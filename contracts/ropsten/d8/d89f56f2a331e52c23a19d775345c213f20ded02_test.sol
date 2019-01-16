pragma solidity ^0.4.24;

contract test{
    address owner;
    string str;

    constructor() public {
        owner = msg.sender;
        str = "default_str";
    }
    function getOwner() view public returns(address) {
        return owner;
    }
    function getStr() view public returns(string) {
        return str;
    }
    function setStr(string _str) public {
        str = _str;
    }
}