pragma solidity ^0.4.24;

contract MessagingService {
    
    struct Message {
        address sender;
        string text;
    }
    
    struct Conversation {
        Message[] messages;
        address participant1;
        address participant2;
    }
    
    // A list of all of the conversations.
    uint32 public num_conversations = 0;
    mapping (uint32 => Conversation) public conversations;
    
    mapping (address => mapping (address => uint32)) public conversation_ids;
    
    constructor() public {
    }
    
    function send_message(address recipient, string text) public {
        require(recipient != msg.sender);

        uint32 conv_id = conversation_ids[msg.sender][recipient];

        bool new_conversation = (conv_id == 0);

        if (new_conversation) {
            num_conversations += 1;
            conv_id = num_conversations;
        }
        
        Conversation storage conv = conversations[conv_id];
        
        if (new_conversation) {
            conv.participant1 = msg.sender;
            conv.participant2 = recipient;

            conversation_ids[msg.sender][recipient] = conv_id;
            conversation_ids[recipient][msg.sender] = conv_id;
        }

        Message memory message;
        message.text = text;
        message.sender = msg.sender;
        conv.messages.push(message);
    }
}