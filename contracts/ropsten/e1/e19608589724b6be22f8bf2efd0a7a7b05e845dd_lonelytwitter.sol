/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.4.19;

contract lonelytwitter {

    event NewTwitter(uint tweetId, string name, string content);
  
    uint tweetId = 0;

    struct Tweet {
        uint tweetId;
        string name;
        string content;
    }

    Tweet[] public tweets;

    function _createTweet(string _name, string _content) private {
        tweets.push(Tweet(tweetId, _name, _content));
        tweetId++;
        NewTwitter(tweetId, _name, _content);
    }

    function createTweet(string _name, string _content) public {
        _createTweet(_name, _content);
    }

    function getTotalTweet() public view returns(uint256) {
    return tweets.length;
    }

    function getTweetDetail(uint _tweetId) public view returns (
    uint tweetId,
    string name,
    string content
    ) {
    Tweet storage _tweet = tweets[_tweetId];
    tweetId = _tweet.tweetId;
    name = _tweet.name;
    content = _tweet.content;
    }

}