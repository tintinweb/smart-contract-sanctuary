/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity =0.8.6;

contract Inbox {
    string public message;
    
    constructor(string memory _initialMessage) {
        message = _initialMessage;
    }
    
    function setMessage(string memory _message) public {
        message = _message;
    }
    
    
}