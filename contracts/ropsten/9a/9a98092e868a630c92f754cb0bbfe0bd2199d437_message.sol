pragma solidity ^0.4.23;
contract message {
    string public message;
    // int public num = 129;
    int public people = 0;
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
    function showMessage() public view returns(string){
        // message = &#39;abcd&#39;;
        return message;
    }
    function pay() public payable {
        people++;
    }
}