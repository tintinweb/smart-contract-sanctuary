/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.8.0;

contract HeyIsAnyoneOutTherePlzTalkToMe {
    // quarantine is pretty lonely
    // maybe we can chat via this contract
    // the events will help us see messages

    event Message(
        address indexed from,
        string message
    );

    function send(string memory message) public {
        emit Message(msg.sender, message);   
    }
}