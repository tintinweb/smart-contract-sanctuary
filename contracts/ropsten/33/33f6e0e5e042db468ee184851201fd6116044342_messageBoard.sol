pragma solidity ^0.4.23;

contract messageBoard{
    string public message;
    uint public num = 123;
    uint public people = 0;
    
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
    function showMessage() public view{
        message = "abcd";
    }
    function pay() public payable {
        people++;
    }
}