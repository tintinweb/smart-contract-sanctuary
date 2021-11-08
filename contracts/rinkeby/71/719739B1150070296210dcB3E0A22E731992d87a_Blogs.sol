/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Blogs{
    
    event OnSubmit(address from, uint timestamp, string message);
    address owner;
    
    struct Post {
        address Sender;
        string Message;
        uint Timestamp;
    }
    
    Post[] posts;
    
    // Initial Function
    constructor() payable {
        // Set owner address on deploy
        owner = msg.sender;
    }
    
    // Post to blockchain (memory) and send ether to owner :D (Dev-fee)
    function post(string calldata message) public payable {
        // Check message length
        require(bytes(message).length > 0, "Message cannot be empty");
        // Set ether amount
        uint amount = 0.001 ether;
        require(msg.value > amount, "Not allowed amount");
        // Set current block time
        uint timestamp = block.timestamp;
        // Push to posts struct array
        posts.push(Post(msg.sender, message, timestamp));
        // Broadcast event to client
        emit OnSubmit(msg.sender, timestamp, message);
    }
    
    // Get all posts from blockchain (memory)
    function get() public view returns (Post[] memory) {
        // Return contract memory variable
        return posts;
    }
}