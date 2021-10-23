/**
 *Submitted for verification at Etherscan.io on 2021-10-22
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
    Tweet [] public tweets;
    mapping(bytes32 => uint) hashtoindex;
    constructor(){}
    event Tweeting(string body, bytes32 hash, uint time, address indexed tweeter);
    function createTweet(string memory _body) public returns(bool success){
        uint time = block.timestamp;
        bytes32 hash = keccak256(abi.encodePacked(_body,msg.sender,time));
        hashtoindex[hash] = tweets.length;
        Tweet memory _temporaryTweet;
        _temporaryTweet.body = _body;
        _temporaryTweet.hash = hash;
        _temporaryTweet.time = time;
        _temporaryTweet.tweeter = msg.sender;
        tweets.push(_temporaryTweet);
        emit Tweeting(_temporaryTweet.body, _temporaryTweet.hash,_temporaryTweet.time,_temporaryTweet.tweeter);
        return true;
    }
    function getAllTweets() public view returns(Tweet [] memory){
        return tweets;
    }
    function getTweetByUser(address _senter) public view returns(Tweet [] memory){
        uint totalCounts;
        for(uint a = 0; a <= tweets.length-1; a++){
            if(tweets[a].tweeter == _senter){
                totalCounts += 1;
            }
        }
        Tweet [] memory _tweet = new Tweet[](totalCounts);
        uint j;
        for(uint a = 0; a <= tweets.length-1; a++){
            if(tweets[a].tweeter == _senter){
                _tweet[j] = tweets[a];
                j += 1;
            }
        }
        return _tweet;
    }
}