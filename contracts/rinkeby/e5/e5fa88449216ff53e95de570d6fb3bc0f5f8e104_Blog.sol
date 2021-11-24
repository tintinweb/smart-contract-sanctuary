/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Blog  {
    struct Message {
        address user;
        string text;
        uint256 timestamp;
    }

    Message[] public posts;

    function write(string calldata text) public {
        require(bytes(text).length < 1024, "Message needs to be a bit shorter");

        posts.push(Message(msg.sender, text, block.timestamp));
    }

    function retrieve(uint256 offset, uint256 limit) public view returns (Message[] memory data) {
        require(offset < posts.length, "Offset should be less than the posts number");

        if (limit > posts.length - offset) {
            limit = posts.length - offset;
        }

        data = new Message[](limit);
        for (uint256 i = 0; i < limit; i++) {
            data[i] = posts[offset + i];
        }

        return data;
    }

    function amount() public view returns (uint256 count) {
        return posts.length;
    }
}