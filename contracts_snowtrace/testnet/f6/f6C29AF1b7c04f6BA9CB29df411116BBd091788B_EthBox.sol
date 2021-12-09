/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract EthBox {
    struct Message {
        address sender;
        address payable receiver;
        string text;
        uint id;
        uint valueInWei;
        uint timestamp;
    }

    mapping(address => uint) private numOfMessagesAtAddress;
    mapping(address => mapping(uint => Message)) private addressToMessage;

    event NewMessage(
        uint id,
        address indexed sender,
        address indexed receiver,
        uint value,
        uint timestamp
    );

    function sendMessage(
        address payable _receiver,
        string memory _text,
        uint _timestamp
    ) public payable {
        uint _messageId = numOfMessagesAtAddress[_receiver] + 1;
        Message storage _receiverMessage = addressToMessage[_receiver][_messageId];

        _receiverMessage.sender = msg.sender;
        _receiverMessage.receiver = _receiver;
        _receiverMessage.text = _text;
        _receiverMessage.id = _messageId;
        _receiverMessage.timestamp = _timestamp;

        if (msg.value > 0) {
            _receiverMessage.valueInWei = msg.value;
            // Send the ether to the receiver
            sendEther(_receiver, msg.value);
        }

        numOfMessagesAtAddress[_receiver]++;

        emit NewMessage(
            _messageId,
            msg.sender,
            _receiver,
            msg.value,
            _timestamp
        );
    }

    // Function to transfer Ether from this contract to address from input
    function sendEther(address payable _to, uint _amount) private {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }

    function getNumOfMessages() public view returns (uint) {
        return numOfMessagesAtAddress[msg.sender];
    }

    function getOwnMessages(
        uint _startIndex,
        uint _count
    ) public view returns (Message[] memory) {
        Message[] memory _userMessages = new Message[](_count);

        for (; _startIndex < _count; _startIndex++) {
            _userMessages[_startIndex] = addressToMessage[msg.sender][_startIndex + 1];
        }

        return _userMessages;
    }
}