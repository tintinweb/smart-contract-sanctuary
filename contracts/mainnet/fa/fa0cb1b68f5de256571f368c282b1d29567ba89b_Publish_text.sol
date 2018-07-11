pragma solidity ^0.4.7;

contract Publish_text {
 
    string public my_message;
    
    constructor(string message) public {
        my_message = message;
    }
    
}