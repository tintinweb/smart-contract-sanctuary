/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity 0.4.21;

contract Linked {
    // User profile
    struct User {
        bytes32 name;
        bytes32 occupation;
        string bio;
    }

    // The structure of a message
    struct Message {
        string content;
        address writtenBy;
        uint256 timestamp;
    }

    // Each address is linked to a user with name, occupation and bio
    mapping(address => User) public userInfo;

    // Each address is linked to several follower addresses
    mapping(address => address[]) public userFollowers;

    // The messages that each address has written
    mapping(address => Message[]) public userMessages;

    // All the messages ever written
    Message[] public messages;

    // Sets the profile of a user
    function setProfile(bytes32 _name, bytes32 _occupation, string _bio) public {
        User memory user = User(_name, _occupation, _bio);
        userInfo[msg.sender] = user;
    }

    // Adds a new message
    function writeMessage(string _content) public {
        Message memory message = Message(_content, msg.sender, now);
        userMessages[msg.sender].push(message);
        messages.push(message);
    }

    // Follows a new user
    function followUser(address _user) public {
        userFollowers[msg.sender].push(_user);
    }

    // Unfollows a user
    function unfollowUser(address _user) public {
        for(uint i = 0; i < userFollowers[msg.sender].length; i++) {
            if(userFollowers[msg.sender][i] == _user) {
                delete userFollowers[msg.sender][i];
            }
        }
    }
}