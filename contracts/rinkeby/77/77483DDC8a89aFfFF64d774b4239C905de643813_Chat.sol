/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract Chat {
    struct Message {
        address sender;
        string text;
    }
    
    mapping(address => Message[]) public inboxes;
    
    event messageSent(address indexed sender, address indexed receiver, string text);
    
    function send(address _receiver, string calldata _text) external {
        require( _receiver != address(0) );
        
        Message memory message = Message(msg.sender, _text);
        inboxes[_receiver].push(message);
        emit messageSent(msg.sender, _receiver, _text);
    }
    
    function getInbox(address _receiver) view public returns(Message[] memory){
        return inboxes[_receiver];
    }
    
    function getMessageByIndex(address _receiver, uint index) view public returns(Message memory){
        return inboxes[_receiver][--index];
    }
}