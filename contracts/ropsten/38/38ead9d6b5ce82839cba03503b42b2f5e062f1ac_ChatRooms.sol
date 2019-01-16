pragma solidity >=0.4.0 <0.6.0;

contract ChatRoom {
    bytes32 public name;
    address public owner;

    struct Settings {
        uint blocknumber;
        bytes32 name;
        bytes32 suggested;
        bool isValid;
        bool isApproved;
    }
    mapping(address => Settings) public settings;

    address[] public members;
    uint public membersTotal;

    struct Message {
        uint blocknumber;
        address member;
        string encrypted_texts_ipfs;
        bytes32 decrypted_text_hash;
    }
    Message[] public messages;
    uint public messagesTotal;

    constructor (bytes32 _name, address _owner) public {
        name = _name;
        owner = _owner;
        members.push(_owner);
        membersTotal = 1;
        settings[_owner] = Settings (block.number, &#39;owner&#39;, &#39;&#39;, true, true);
        messagesTotal = 0;
    }

    function addMember (bytes32 _name, address _addr) public {
        if (!settings[_addr].isValid) {
            membersTotal++;
            members.push(_addr);
            if (msg.sender == owner) {
                settings[_addr] = Settings (block.number, _name, &#39;&#39;, true, true);
            } else {
                settings[_addr] = Settings (block.number, &#39;&#39;, _name, true, false);
            }
        } else {
            if (msg.sender == owner) {
                settings[_addr].name = _name;
                settings[_addr].isApproved = true;
            } else {
                settings[_addr].suggested = _name;
            }
        }

    }

    function createMessage(string memory _encrypted_texts_ipfs, bytes32 _decrypted_text_hash) public {
        messages.push(Message(block.number, msg.sender, _encrypted_texts_ipfs, _decrypted_text_hash));
        messagesTotal++;
    }
}

contract ChatRooms {
    address[] public chatRooms;
    mapping (address => bytes32) public chatRoomsNames;
    uint public chatRoomsTotal;

    constructor () public {
        chatRoomsTotal = 0;
    }

    function createChatRoom (bytes32 _name) public {
        address newContract = address(new ChatRoom(_name, msg.sender));
        chatRoomsNames[newContract] = _name;
        chatRooms.push(newContract);
        chatRoomsTotal++;
    }
}