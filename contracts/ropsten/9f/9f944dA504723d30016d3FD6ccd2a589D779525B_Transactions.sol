//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Transactions{
    address public admin;
    mapping (address => string[]) public transaction;
    uint public totalMessages;

    constructor(){
    admin = msg.sender;
    }
    
function CreateMessage( string memory message) public returns(uint){
    // require(msg.sender == admin, 'only admin');
    transaction[msg.sender].push(message);
    totalMessages++ ;
    return totalMessages;
}
function ReadMessage(address Address) public view returns(string[] memory){
    return transaction[Address];
}

function updateMessage( uint id, string memory newMessage) public{
    require( admin == msg.sender, 'only admin');
    transaction[msg.sender][id] = newMessage;
}
function deleteMessage( uint id) public{
    require(msg.sender == admin, 'only admin');
    delete transaction[msg.sender][id] ;
    totalMessages--;
}
}