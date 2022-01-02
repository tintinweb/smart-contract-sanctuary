// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

contract ChirpCity {
    struct Message {
        uint256 timestamp;
        uint256 parentId;
        address from;
        string body;
    }

    uint256 private currentId;
    mapping(uint256 => Message) public messages;

    event ChirpCityMessage(address indexed from, uint256 id);
    event ChirpCityMention(address indexed to, uint256 id);
    event ChirpCityReply(address indexed to, uint256 id);

    error MessageNotFound();
    error TooManyMentions();
    error MessageTooLong();

    function chirp(string calldata body, uint256 parentId, address[] calldata mentions) external {
        if (parentId != 0 && messages[parentId].from == address(0))
            revert MessageNotFound();

        if (mentions.length > 16)
            revert TooManyMentions();

        if (bytes(body).length > 256)
            revert MessageTooLong();

        currentId++;

        messages[currentId] = Message(block.timestamp, parentId, msg.sender, body);

        emit ChirpCityMessage(msg.sender, currentId);
        if (parentId != 0) {
            emit ChirpCityReply(messages[parentId].from, currentId);
        }
        for (uint8 i = 0; i < mentions.length; i++) {
            emit ChirpCityMention(mentions[i], currentId);
        }
    }
}