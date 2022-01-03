/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Messenger {
    address payable owner;
    uint public fee;

    struct MessageObject {
        address sender;
        string author;
        string message;
        uint donation;
    }

    MessageObject[] public messages;

    event MessageSent(address indexed _sender, string _author, string _text);

    constructor(uint _fee) {
        owner = payable(msg.sender);
        fee = _fee;
    }

    modifier ownerOnly() {
        require (msg.sender == owner, 'Unathorized access');
        _;
    }

    modifier evenFee() {
        require(msg.value % 2 == 0, 'Fee must be even');
        _;
    }

    modifier requireFee() {
        require(msg.value >= fee, 'Fee is too low');
        _;
    }

    function setFee(uint _fee) public payable ownerOnly evenFee {
        fee = _fee;
    }

    function withdraw() public ownerOnly {
        owner.transfer(address(this).balance);
    }

    function sendMessage(string memory _messageAuthor, string memory _messageText) public payable evenFee requireFee {
        require(bytes(_messageAuthor).length > 0, 'Author cannot be empty');
        require(bytes(_messageText).length > 0, 'Message cannot be empty');

        MessageObject memory messageObj = MessageObject(msg.sender, _messageAuthor, _messageText, msg.value);
        messages.push(messageObj);
        emit MessageSent(msg.sender, _messageAuthor, _messageText);
    }

    function getAllMessages() public view returns(MessageObject[] memory) {
        return messages;
    }

    function getTotalMessages() public view returns(uint) {
        return messages.length;
    }
}