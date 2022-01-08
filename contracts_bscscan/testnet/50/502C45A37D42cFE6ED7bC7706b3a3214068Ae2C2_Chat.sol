// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct User {
    uint256 id;
    string name;
    address _address;
    int8 lng;
    int8 lat;
    bool exists;
}

struct Message {
    address from;
    address to;
    bytes content;
    uint256 id;
    uint256 timeStamp;
}

struct Room {
    address userA;
    address userB;
    bool exists;
    uint256 index;
}

contract Chat {
    address[] queue;
    mapping(address => User) Users;
    User[] public arrUser;
    mapping(address => mapping(address => Message[])) messagesUserToUser;
    address owner;
    
    constructor() {
        owner = msg.sender;
        genesisFirstUser();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function genesisFirstUser() private onlyOwner {
        address sender = msg.sender;
        Users[sender].exists = true;
        Users[sender]._address = sender;
        Users[sender].id = 1000;
        arrUser.push(Users[sender]);
    }

    function sendMessage(address target, bytes memory content) public returns(Message[] memory) {
        require(msg.sender != target);
        Message[] storage messages = messagesUserToUser[msg.sender][target];
        uint length = messages.length;
        uint256 id; 
        uint256 timeStamp = block.timestamp;

        if (length > 0) {
            id = messages[messages.length - 1].id + 1;
        } else {
            id = 1;
        }

        Message memory message = Message(
            msg.sender,
            target,
            content,
            id,
            timeStamp
        );
        messagesUserToUser[msg.sender][target].push(message);
        return messages;
    }

    function getMessagesBySender(address to)
        public
        view
        returns (Message[] memory)
    {
        return messagesUserToUser[msg.sender][to];
    }

    function getMessagesByTarget(address to)
        public
        view
        returns (Message[] memory)
    {
        return messagesUserToUser[to][msg.sender];
    }

    function setUser() public returns (bool _success) {
        address sender = msg.sender;
        require(!Users[sender].exists, "User is exists");
        Users[sender].exists = true;
        Users[sender]._address = sender;
        Users[sender].id = arrUser[arrUser.length - 1].id + 1;
        arrUser.push(Users[sender]);
        return true;
    }

    function getUser() public view returns (User memory) {
        User memory user = Users[msg.sender];
        return user;
    }
}