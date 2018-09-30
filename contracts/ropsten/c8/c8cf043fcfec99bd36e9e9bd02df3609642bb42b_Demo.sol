pragma solidity ^0.4.24;


contract Demo {

    string public message;

    constructor() public {
        message = "";
    }

    function readMessage() public view returns(string){
        return message;
    }
    function writeMessage(string _msg) public{
        message = _msg;
    }


}