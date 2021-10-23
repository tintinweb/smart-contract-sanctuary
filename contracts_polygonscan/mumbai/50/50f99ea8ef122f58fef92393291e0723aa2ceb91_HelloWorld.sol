/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string public message;
    
    constructor(string memory initMessage) public {
        message = initMessage;
    }
    
    function update(string memory newMessage) public {
        message = newMessage;
    }
}