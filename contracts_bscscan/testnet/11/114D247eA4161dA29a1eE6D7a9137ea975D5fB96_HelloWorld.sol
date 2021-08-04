/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// We will be using Solidity version 0.5.3 
pragma solidity 0.5.3;

contract HelloWorld {
    string private message = "hello world";

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}