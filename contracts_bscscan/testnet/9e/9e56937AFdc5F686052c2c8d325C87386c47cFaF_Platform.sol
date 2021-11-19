/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.9;



// File: Platform.sol

contract Platform {
    string public name = "PLT";
    uint256 public fileCount = 0;

    struct File {
        uint256 _id;
        string _title;
        string _hash;
        address _author;
        uint256 _uploadTime;
        string _description;
        uint256 _likeCount;
        uint256 _commentCount;
    }

    struct Comment {
        address _author;
        string _comment;
        uint256 _datetime;
    }

    // File ID => File
    mapping(uint256 => File) public Files;

    // File ID => comments of File
    mapping(uint256 => mapping(uint256 => Comment)) public comments;

    event FileUplaoded(
        uint256 _id,
        string _hash,
        string _title,
        address _author
    );

    // add File to mapping
    function addFile(
        uint256 _id,
        string memory _title,
        string memory _hash,
        string memory _description
    ) private {
        Files[_id] = File(
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

    function uploadFile(
        string memory _title,
        string memory _FileHash,
        string memory _description
    ) public {
        // make sure the File title exists
        require(bytes(_title).length > 0);
        // make sure the File hash exists
        require(bytes(_FileHash).length > 0);

        addFile(fileCount, _title, _FileHash, _description);

        emit FileUplaoded(fileCount++, _FileHash, _title, msg.sender);
    }

    function addComment(uint256 _FileId, string memory _text) public {
        // # file comments
        uint256 commentId = Files[_FileId]._commentCount;
        // create and add comment
        comments[_FileId][commentId] = Comment(
            msg.sender,
            _text,
            block.timestamp
        );
        // update comment ID
        Files[_FileId]._commentCount++;
    }

    function likeFile(uint256 _FileId) public {
        Files[_FileId]._likeCount++;
    }
}