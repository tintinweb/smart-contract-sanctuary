pragma solidity ^0.8.0;

contract Chat {

    string public name = "My Chat app";

    struct Message {
        string message;
        uint256 timestamp;
    }

    struct Participant {
        address participant1;
        address participant2;
    }

    mapping(string => mapping(address => Message[])) public chats;

    mapping(string => Participant) public participants;

    mapping(address => string[]) public rooms;

    mapping(address => mapping(address => string)) roomData;

    event MessageInfo(address indexed from, address indexed to, string message, uint256 timestamp);

    function sendMessage(address _to, string memory _message, string memory roomId) public returns (bool success) {
        if (participants[roomId].participant1 != msg.sender || participants[roomId].participant2 != msg.sender) {
            roomData[msg.sender][_to] = roomId;
            rooms[msg.sender].push(roomId);
            participants[roomId] = Participant({participant1 : msg.sender, participant2 : _to});
        }

        chats[roomId][msg.sender].push(Message({message : _message, timestamp : block.timestamp}));
        emit MessageInfo(msg.sender, _to, _message, block.timestamp);
        return true;
    }


}