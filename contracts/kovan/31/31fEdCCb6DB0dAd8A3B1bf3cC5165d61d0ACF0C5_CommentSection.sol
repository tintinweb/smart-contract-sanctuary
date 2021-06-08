/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract CommentSection {
    struct Comment {
        address author;
        string content;
        uint blockTimestamp;
    }

    Comment[] public comments;

    event AddedComment(Comment newComment);

    function addComment(string memory _comment) external {
        Comment memory newComment = Comment(msg.sender, _comment, block.timestamp);
        comments.push(newComment);
        emit AddedComment(newComment);
    }

    function getComments() public view returns (Comment[] memory) {
        return comments;
    }
}