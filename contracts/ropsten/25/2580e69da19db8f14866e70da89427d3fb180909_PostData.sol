/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract PostData {
    struct Post {
        uint id;
        string text;
        uint uid;
        uint postedAt;
    }

    mapping(uint => Post) public posts;
    uint latestId;

    function createPost(uint _user, string memory _text) public returns(uint) {
        latestId ++;
        posts[latestId] = Post(latestId, _text, _user, block.timestamp);

        return latestId;    
    }

    function getPost(uint _id) view public returns(uint, string memory, uint){
        return (
            posts[_id].id,
            posts[_id].text,
            posts[_id].uid
        );
    }
}