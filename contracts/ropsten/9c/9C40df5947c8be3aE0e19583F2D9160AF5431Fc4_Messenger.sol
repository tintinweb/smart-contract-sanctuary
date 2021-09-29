/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.0;

contract Messenger {

    struct Message{
        address sender;
        string message;
    }

    // Mapping containing received messages
    mapping(address => Message[]) messages;

    event MessageSent(address indexed _from, address indexed _to);

    function send(address to, string calldata message) external {
        emit MessageSent(msg.sender, to);
        messages[to].push( Message(
            msg.sender,
            message
        ) );
    }

    function getMessages() external view returns (Message[] memory) {
        return messages[msg.sender];
    }

    function messageContent(uint x) external view returns (string memory) {
        return messages[msg.sender][x].message;
    }

    function messageSender(uint x) external view returns (address) {
        return messages[msg.sender][x].sender;
    }

    function messagesReceived() external view returns (uint) {
        return messages[msg.sender].length;
    }

}