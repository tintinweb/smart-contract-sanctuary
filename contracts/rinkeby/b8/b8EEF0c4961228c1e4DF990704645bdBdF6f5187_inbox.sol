/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.4.25;

contract inbox{
    string public message;
    
    constructor (string initialMessage) public {
        message=initialMessage;
    }
    
    function setMessage(string newMessage) public {
        message=newMessage;
    }
    
}