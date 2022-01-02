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

    event ChirpCityMessage(uint256 id, address indexed from);
    event ChirpCityMention(uint256 id, address indexed to);
    event ChirpCityReply(uint256 id, address indexed to);

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

        emit ChirpCityMessage(currentId, msg.sender);
        if (parentId != 0) {
            emit ChirpCityReply(currentId, messages[parentId].from);
        }
        for (uint8 i = 0; i < mentions.length; i++) {
            emit ChirpCityMention(currentId, mentions[i]);
        }
    }
}