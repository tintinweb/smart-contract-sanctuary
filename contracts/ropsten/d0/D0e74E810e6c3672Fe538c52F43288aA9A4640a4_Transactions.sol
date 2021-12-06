//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Transactions{
    address public admin= msg.sender;
    mapping (address => string[]) public transaction;
    uint public totalMessages;
    
function CreateMessage( string memory message) public{
    // require(msg.sender == admin, 'only admin');
    transaction[msg.sender].push(message);
    totalMessages++ ;
}
function ReadMessage(address Address) public view returns(string[] memory){
    return transaction[Address];
}

function updateMessage( uint id, string memory newMessage) public{
    // require( msg.sender == admin, 'only admin');
    transaction[msg.sender][id] = newMessage;
}
function deleteMessage( uint id) public{
    // require(msg.sender == admin, 'only admin');
    delete transaction[msg.sender][id] ;
    totalMessages--;
    
}
}