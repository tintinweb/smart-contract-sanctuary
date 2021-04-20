/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity >=0.6.6 < 0.8.0;
contract Greetings { 
    string public message; 
    constructor(string memory initialMessage) public {
        
        message = initialMessage; 
    } 
    function setMessage(string memory newMessage) public {
        message = newMessage; 
    }
}