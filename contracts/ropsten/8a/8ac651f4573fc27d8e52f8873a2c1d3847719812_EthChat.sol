/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.4.6;

contract EthChat {
    // This will allow all users to see new messages, while all messages are
    // already visible on the blockchain this will make it easier
    // for a user to detect incoming messages to any room. Unfortunately there
    // is no way to dynamically create events for specific rooms that users
    // can subscribe to. To maintain privacy, users can use encrypted rooms to
    // ensure that their messages cannot be decoded by people without keys.
    // Like everything else, a struct cannot be returned
    event NewMessage(string message, address user, uint timestamp, string roomName);

    address owner;

    struct Message {
        string message;
        address user;
        uint timestamp;
    }

    mapping(string => Message[]) roomNameToMessages;
    mapping(address => string) addressToUsername;

    function EthChat() public {
        owner = msg.sender;
    }

    // Send a message to a room and fire an event to be caught by the UI
    function sendMessage(string _msg, string _roomName) external {
        Message memory message = Message(_msg, msg.sender, block.timestamp);
        roomNameToMessages[_roomName].push(message);
        NewMessage(_msg, msg.sender, block.timestamp, _roomName);
    }

    // Functions for creating and fetching custom usernames. If a user updates
    // their username it will update for all of their messages
    function createUser(string _name) external {
        addressToUsername[msg.sender] = _name;
    }

    function getUsernameForAddress(address _user) external view returns (string) {
        return addressToUsername[_user];
    }

    // Currently, there is no support for returning nested lists, so the length
    // of messages needs to be fetched and then retrieved by index. This is not
    // fast but it is the most gas efficient method for storing and
    // fetching data. Ideally this only needs to be done once per room load
    function getMessageCountForRoom(string _roomName) external view returns (uint) {
        return roomNameToMessages[_roomName].length;
    }

    // There is no support for returning a struct to web3, so this needs to be
    // returned as multiple items. This will throw an error if the index is invalid
    function getMessageByIndexForRoom(string _roomName, uint _index) external view returns (string, address, uint) {
        Message memory message = roomNameToMessages[_roomName][_index];
        return (message.message, message.user, message.timestamp);
    }

    function kill() external {
        if (owner == msg.sender) {
            selfdestruct(owner);
        }
    }
}