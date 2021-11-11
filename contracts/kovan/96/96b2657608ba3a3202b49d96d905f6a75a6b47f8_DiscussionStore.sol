/**
 *Submitted for verification at Etherscan.io on 2021-11-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


function compStr(string memory str1, string memory str2) pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
}

contract DiscussionStore {
    struct Discussion {
        bytes32[] children;
        string content;
        uint24 upvotes;
        uint24 downvotes;
    }
    mapping(bytes32 => Discussion) public discussions;

    function newDiscussion(bytes32 parentID, string memory content) public {
        if (parentID != "START") {
            require(!compStr(content, ""), "Invalid content");
        }
        Discussion storage parent = discussions[parentID];
        require(!compStr(parent.content, ""), "Invalid parent");

        Discussion memory discussion = Discussion({
            children: new bytes32[](0), 
            content: content, 
            upvotes: 0, 
            downvotes: 0
        });
        bytes32 ID = keccak256(abi.encodePacked(discussion.content, msg.sender, block.timestamp));
        require(!compStr(discussions[ID].content, ""), "Discussions already exists.");
        discussions[ID] = discussion;
        parent.children.push(ID);
    }
}