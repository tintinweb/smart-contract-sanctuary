/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity 0.5.1;

contract BchainMessengerContract {

    struct Message { 
        address senderText;
        string text;
    }
    
    uint256 MessageCount;
    mapping(uint => Message) public message_list;
    
    function sendText(string memory sentText) public {
        MessageCount+=1;
        message_list[MessageCount].senderText = msg.sender;
        message_list[MessageCount].text = sentText;
    }
}