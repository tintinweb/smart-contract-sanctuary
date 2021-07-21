/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

pragma solidity ^0.4.2;
    
// A simple smart contract
contract HelloWorld {
    string message = "Hello World";
    
    function getMessage() public constant returns(string) {
        return message;
    }
    
    function setMessage(string newMessage) public {
        message = newMessage;
    }
}