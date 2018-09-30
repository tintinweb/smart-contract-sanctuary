pragma solidity ^0.4.24;


contract Demo {

    string public message;
    constructor() public {
        message = "";
    }
    function writeMessage(string _message) public {
        message = _message;
    }
    function readMessage() public view returns(string){
        return message;
    }
  
}