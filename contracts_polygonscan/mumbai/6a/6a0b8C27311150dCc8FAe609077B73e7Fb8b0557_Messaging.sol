pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/ERC721";

contract Messaging {

    uint256 public messageCount = 0;
    mapping(uint256 => Message) public messages;
    mapping(address => uint256[]) public receiverToMessages;

    struct Message {
        uint256 msg_id;
        address sender;
        address receiver;
        string uri;
        uint256 timestamp;
    }

    event MessageSent(
        uint256 msg_id,
        address receiver,
        string uri,
        uint256 timestamp
    );

    function sendMessage(
        string memory _uri,
        address _receiver
    ) public {
        messageCount++;

        messages[messageCount] = Message(
            messageCount,
            msg.sender,
            _receiver,
            _uri,
            block.timestamp
        );

        receiverToMessages[_receiver].push(messageCount);

        emit MessageSent(messageCount, _receiver, _uri, block.timestamp);
    }

    function allMessages(address _receiver) external view returns (Message[] memory) {
        Message[] memory list = new Message[](receiverToMessages[_receiver].length);

        for(uint256 i = 0; i < receiverToMessages[_receiver].length; i++) {
            list[i] = messages[receiverToMessages[_receiver][i]];
        }

        return list;
    }

    function messageURI(
        uint256 _msg_id
    ) external view returns (string memory uri) {
        return messages[_msg_id].uri;
    }
}