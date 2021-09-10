/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity 0.8.7;

contract Message{
    
    string public message;
    uint public highestBid;
    
    event Broadcast(address addr, uint amt, string message);
    
    constructor() public {
        message = "Initial Message";
        highestBid = 0;
    }
    
    function transfer(string memory newMessage) payable public {
        message = newMessage;
        highestBid = msg.value;
        emit Broadcast(msg.sender, msg.value, newMessage);
    }
    
    function getHighestBid() public view returns(uint){
        return highestBid;
    }
    
}