/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string public message;
    
    constructor (string memory initMessage) public {
        message = initMessage;
    }
    
    function updateMessage (string memory newMessage) public {
        message = newMessage;
    }
}