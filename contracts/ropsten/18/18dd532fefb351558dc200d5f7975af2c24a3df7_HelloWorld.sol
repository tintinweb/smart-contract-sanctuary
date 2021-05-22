/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.4;

contract HelloWorld {
    string public message;
    event messageEdited(string _newMsg);
    
    constructor(string memory _msg) {
        message = _msg;
    }
    
    function editMessage(string memory _msg) public {
        message = _msg;
        emit messageEdited(_msg);
    }
    
    function getMessage() public view returns(string memory) {
        return message;
    }
}