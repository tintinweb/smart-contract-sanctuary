/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Messenger {

    struct Message{
        address sender;
        string content;
    }

    // Mapping containing received messages
    mapping(address => Message[]) messages;

    event MessageSent(address indexed _from, address indexed _to, uint256 _id);

    function send(address to, string calldata message) external {

        // avoid sending empty messages
        require(bytes(message).length > 0, "Message cannot be empty.");

        // get current length to log message id
        uint256 _id = messages[to].length;
        
        // push message to messages array
        messages[to].push( Message(
            msg.sender,
            message
        ) );

        emit MessageSent(msg.sender, to, _id);
    }
    
    function messageContent(address account, uint _id) external view returns (string memory) {
        return messages[account][_id].content;
    }

    function messageSender(address account, uint _id) external view returns (address) {
        return messages[account][_id].sender;
    }

    function messagesReceived(address account) external view returns (uint) {
        return messages[account].length;
    }

}