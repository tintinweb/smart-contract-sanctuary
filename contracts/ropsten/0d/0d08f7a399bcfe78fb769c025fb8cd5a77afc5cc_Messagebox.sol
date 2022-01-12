/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Messagebox {
    string[] public messages;
    mapping(address => bool) public isUser;
    event NewMessage(address indexed author, string message); // Event
    
    constructor ()  {
        messages.push("Hello World!");
        emit NewMessage(msg.sender, "Hello World!");
    }
    
    function setMessage(string memory _new_message) public payable {
        if(isUser[msg.sender]) { //primera vez es falso
            require(msg.value == 0.001 ether, "adding a new messages requires 0.001 ethers");
        }else {
            isUser[msg.sender] = true;  //registramos nuevo usuario
        }

        messages.push(_new_message);
        emit NewMessage(msg.sender, _new_message);
        
    }
    
    function getMessages() public view returns (string[] memory) {
        return messages;
    }
    
}