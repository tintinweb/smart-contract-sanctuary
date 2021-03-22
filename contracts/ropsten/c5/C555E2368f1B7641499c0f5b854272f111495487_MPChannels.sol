/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity >=0.5.0;

contract MPChannels {
    struct Sid {
        mapping (uint => Receiver) receivers; //indexed by receivingPid
        mapping (uint => address) participants;
        uint participantsBlock;
    }
    struct Receiver {
        mapping (uint => Sender) senders; //indexed by sendingPid;
    }
    struct Sender {
        mapping (uint => string) messages; //indexed by the number of messages
    }
    mapping(string => Sid) sids;
    function sendMessage(string memory sid, string memory _message, uint _receivingPid, uint _sendingPid, uint _msgNum) public {
        if (sids[sid].participants[_sendingPid] != msg.sender) revert("Wrong sender");
      if (sha256(abi.encodePacked(sids[sid].receivers[_receivingPid].senders[_sendingPid].messages[_msgNum])) != sha256(abi.encodePacked(""))) revert ("Message existing");
        sids[sid].receivers[_receivingPid].senders[_sendingPid].messages[_msgNum] = _message;
    }
    function readMessage(string memory sid, uint _receivingPid, uint _sendingPid, uint _msgNum) public view returns (string memory, uint b) {
      //  if (bytes(sids[sid].receivers[_receivingPid].senders[_sendingPid].messages[_msgNum]).length == 0) revert("No message");
        return (sids[sid].receivers[_receivingPid].senders[_sendingPid].messages[_msgNum],block.number);
    }
    function setParticipants(string memory sid, address[] memory _participants) public {
        for (uint i = 1; i <= _participants.length; i++)
            sids[sid].participants[i] = _participants[i-1];
        sids[sid].participantsBlock = block.number;
    }
    //neded to check identity confirmation
    function getParticipantsBlock(string memory sid) public view returns (uint b) {
        return sids[sid].participantsBlock;
    }
    
}