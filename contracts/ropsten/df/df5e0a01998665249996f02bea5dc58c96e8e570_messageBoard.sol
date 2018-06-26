pragma solidity ^0.4.23;
contract messageBoard{
    string public message;
    int public num = 8;
    int public people = 0;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
    function pay() public payable{
        people++;
    }
    
}