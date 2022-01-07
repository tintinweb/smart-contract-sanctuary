// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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
    string content;
    uint id;
    uint256 timeStamp;
}

struct Room {
    address userA;
    address userB;
    bool exists;
    uint index;
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

    function sendMessage(address target, string memory content) public {
        address sender = msg.sender;
        require(sender != target);
        Message[] memory messages = messagesUserToUser[sender][target];
        uint id; 
        if (messages.length > 0) {
            id = messages[messages.length - 1].id + 1;
        } else {
            id = 1;
        }
        uint256 timeStamp = block.timestamp;
        Message memory message = Message(sender, target, content,id, timeStamp);
        messagesUserToUser[sender][target].push(message);
    }   

    function getMessagesBySender(address target) public view returns(Message[] memory) {
        address sender = msg.sender;
        return messagesUserToUser[sender][target];
    }

    function getMessagesByTarget(address target) public view returns(Message[] memory) {
        address sender = msg.sender;
        return messagesUserToUser[target][sender];
    }

    function setUser() public returns (bool _success) {
        address sender = msg.sender;
        require(!Users[sender].exists, "User is exists");
        Users[sender].exists = true;
        Users[sender]._address = sender;
        Users[sender].id = arrUser[arrUser.length-1].id + 1;
        arrUser.push(Users[sender]);
        return true;
    }

    function getUser() public view returns(User memory) {
        return Users[msg.sender];
    }
}