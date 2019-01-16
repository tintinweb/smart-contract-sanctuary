pragma solidity ^0.4.24;

contract test{
    address owner;
    string str;

    event event_setStr(string _str);
    event event_getStr(address _address);

    constructor() public {
        owner = msg.sender;
        str = "default_str";
    }
    function getOwner() view public returns(address) {
        return owner;
    }
    function getStr() public returns(string) {
        emit event_getStr(msg.sender);
        return str;
    }
    function setStr(string _str) public {
        emit event_setStr(_str);
        str = _str;
    }
}