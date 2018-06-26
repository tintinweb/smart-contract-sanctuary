pragma solidity ^0.4.23;
contract messageBoard{
    string public message;
    int8 public num = 8;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
    
}