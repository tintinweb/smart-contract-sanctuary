/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

//SPDX-License-Identifier: MIT
pragma solidity = 0.8.9;

contract Twitter{
    struct Tweet{
        string body;
        bytes32 hash;
        uint time;
        address tweeter;
    }
    Tweet [] public Tweets;
    uint private totalCounts = 0;
    mapping(bytes32 => uint) tweets;
    constructor(){}
    
    function createTweet(string memory _body) public returns(bool) {
        uint time = block.timestamp;
        bytes32 hash = keccak256(abi.encodePacked(_body,msg.sender,time));
        tweets[hash] = totalCounts;
        totalCounts += 1;
        Tweet memory temp;
        temp.body = _body;
        temp.hash = hash;
        temp.time = time;
        temp.tweeter = msg.sender;
        Tweets.push(temp);
        return true;
    }
 
    
    function getAllTweet() public view returns(Tweet [] memory){
        return Tweets;
    }
    
    function getTweet(bytes32 _hash) public view returns(Tweet memory){
        uint no = tweets[_hash];
        return Tweets[no];
    }
}