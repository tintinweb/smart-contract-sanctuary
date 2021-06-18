/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity 0.5.1;

// 
// Part of the Ethereum Project (hossein fathi)
// ECommerce Security Course in Tarbiat Modares University
// Taught by Sadegh Dorri Nogoorani ([email protected])
// 
//
contract Messenger{
    address owner;
    string[] messages;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function add(string memory newMessage) public{
        require(msg.sender == owner);
        messages.push(newMessage);
    }
    
    function count() view public returns(uint) {
        return messages.length;
    }
    
    function getMessage(uint index) view public returns(string memory){
        return messages[index];
    }
}