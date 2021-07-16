//SourceUnit: message.sol

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract MessageStorage {
    address public owner_wallet = 0xf8fcd3b4609020e386144716baebb059d0eb0b85;
    uint256 public msgCount = 0;
    mapping(uint256 => Message) public message;

    modifier onlyOwner() {
        require(msg.sender == owner_wallet);
        _;
    }

    struct Message{
        uint256 id;
        string text;
        string fileName;
        string fileType;
        string fileHash;
        string msgSize;
        string datetime;
    }

    function addMessage(string memory text, string memory fileName, string memory fileType, string memory fileHash, string memory msgSize, string memory datetime) payable public {
        message[msgCount] = Message(msgCount, text, fileName, fileType, fileHash, msgSize, datetime);
        msgCount += 1;
        sendCommission(owner_wallet);
    }

    function addMultipleMessages(string[] memory text, string[] memory fileName, string[] memory fileType, string[] memory fileHash, string[] memory msgSize, string memory datetime) public {
        for(uint i = 0; i< text.length; i++)
        {
            message[msgCount] = Message(msgCount, text[i], fileName[i], fileType[i], fileHash[i], msgSize[i], datetime);
            msgCount += 1;
        }
    }

    function getMessageCount() public view returns (uint256) {
        return msgCount;
    }

    function get(uint256 index) public view returns (Message memory){
        return message[index];
    }

    function sendCommission(address _address) public payable {
        _address.transfer(msg.value);
    }

    function setOwnerWallet(address _owner_wallet)  onlyOwner public {
        owner_wallet = _owner_wallet;
    }
    
    function getOwnerWallet() public view returns (address) {
        return owner_wallet;
    }
}