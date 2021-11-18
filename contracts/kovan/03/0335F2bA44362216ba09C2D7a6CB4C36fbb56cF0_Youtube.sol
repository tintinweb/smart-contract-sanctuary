/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.9;



// File: Youtube.sol

contract Youtube {
    string public name = "YOUTUBE";
    uint256 public videoCount = 0;

    struct Video {
        uint256 _id;
        string _title;
        string _hash;
        address _author;
        uint256 _uploadTime;
        string _description;
        uint256 _likes;
        uint256 _commentCount;
    }

    struct Comment {
        address _author;
        string _comment;
        uint256 _datetime;
    }

    // video ID => video
    mapping(uint256 => Video) public videos;

    // video ID => comments of video
    mapping(uint256 => mapping(uint256 => Comment)) public comments;

    event VideoUplaoded(
        uint256 _id,
        string _hash,
        string _title,
        address _author
    );

    // add video to mapping
    function addVideo(
        uint256 _id,
        string memory _title,
        string memory _hash,
        string memory _description
    ) private {
        videos[_id] = Video(
            _id,
            _title,
            _hash,
            msg.sender,
            block.timestamp,
            _description,
            0,
            0
        );
    }

    function uploadVideo(
        string memory _title,
        string memory _videoHash,
        string memory _description
    ) public {
        // make sure the video title exists
        require(bytes(_title).length > 0);
        // make sure the video hash exists
        require(bytes(_videoHash).length > 0);

        addVideo(videoCount, _title, _videoHash, _description);

        emit VideoUplaoded(videoCount++, _videoHash, _title, msg.sender);
    }

    function addComment(uint256 _videoId, string memory _text) public {
        // Number of video comments
        uint256 commentId = videos[_videoId]._commentCount;
        // create and add comment
        comments[_videoId][commentId] = Comment(
            msg.sender,
            _text,
            block.timestamp
        );
        // update comment ID
        commentId++;
    }

    function likeVideo(uint256 _videoId) public {
        videos[_videoId]._likes++;
    }
}