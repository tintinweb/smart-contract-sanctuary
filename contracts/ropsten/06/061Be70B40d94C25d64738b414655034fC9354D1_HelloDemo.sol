pragma solidity >=0.4.22 <0.9.0;

contract HelloDemo {
    string private message = "hello demo";

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}