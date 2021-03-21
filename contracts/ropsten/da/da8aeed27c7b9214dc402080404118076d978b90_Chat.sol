/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity ^0.6.0;

contract Chat {
    string messages = "[]";
    
    function getMessages() public view returns(string memory) {
        return messages;
    }

    function setMessages(string memory _messages) public {
        messages = _messages;
    }

}