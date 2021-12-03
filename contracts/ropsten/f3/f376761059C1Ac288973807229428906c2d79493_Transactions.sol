//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Transactions{
    address public admin;
    mapping (address => string[]) public transaction;
    uint public totalMessages;

    constructor(){
    admin = msg.sender;
    }
    
function CreateMessage(address Address, string memory message) public returns(uint){
    // require(msg.sender == admin, 'only admin');
    transaction[Address].push(message);
    totalMessages++ ;
    return totalMessages;
}
function ReadMessage(address Address) public view returns(string[] memory){
    return transaction[Address];
}

function updateMessage(address Address, uint id, string memory newMessage) public{
    require( admin == msg.sender, 'only admin');
    transaction[Address][id] = newMessage;
}
function deleteMessage(address Address, uint id) public{
    require(msg.sender == admin, 'only admin');
    delete transaction[Address][id] ;
    totalMessages--;
}
}