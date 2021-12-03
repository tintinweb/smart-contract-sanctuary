/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Decentragram {
    uint256 userId;
    address owner;

    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (owner == msg.sender, "You are not the Owner");
        _;
    }

    struct User {
        string imageUri;
        string title;
        string description;
    }
    event userPost (
        string imageUri,
        string title,
        string description
    );

    mapping (uint256 => User) users;
    function addPost ( string memory _image, string memory _title, string memory _desc) public {
        userId++;
        users[userId] = User(_image, _title, _desc);
        emit userPost (_image, _title, _desc);
    }

    function getPost (uint256 _id) public view returns(User memory) {
        return users[_id];
    }

    function updatePost (User memory _updatePost, uint256 _index) onlyOwner public {
        users[_index] = _updatePost;  
    }
}

// ["oooo","0000", "999"]