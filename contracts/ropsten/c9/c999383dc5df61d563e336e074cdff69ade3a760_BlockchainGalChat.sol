pragma solidity ^0.4.19;


contract BlockchainGalChat {

    string[] messages;
    uint256 lastIndex;

    event MessageWritten(string msg_);

    constructor() public {
        messages.push("Contract created");
        lastIndex = 0;
    }

    function getNumberOfMessages() public view returns (uint){
        return messages.length;
    }

    function getMessage(uint msgIndex_) public view returns(string){
        return messages[msgIndex_];
    }

    function storeMsg(string msg_) public {
        messages.push(msg_);
        lastIndex++;
        emit MessageWritten(msg_);
    }


}