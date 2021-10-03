/**
 *Submitted for verification at polygonscan.com on 2021-10-02
*/

pragma solidity ^ 0.5.10;


contract Token {
    string public message;
    
    constructor(string memory initMessage) public {
        message = initMessage;
    }
    
    function update(string memory newMessage) public {
        message = newMessage;
    }
    
}