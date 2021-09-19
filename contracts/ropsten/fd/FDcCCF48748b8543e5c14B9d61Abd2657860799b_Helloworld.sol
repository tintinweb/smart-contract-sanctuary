/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract Helloworld {

    string message = "hello";
    address payable owner;
    constructor() {
        owner = payable(msg.sender);
    }
    
    function close() public { 
        selfdestruct(owner); 
    }
    
    function getMessage() public view returns(string memory) {
        return message;
    }
    function setMessage(string memory  newMessage ) public payable {
        require(msg.value >= 1 gwei); // for payable
        message = newMessage;
    }
}