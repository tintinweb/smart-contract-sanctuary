/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

pragma solidity >=0.7.0 <0.9.0;

contract Signaling { 
    event Message(address indexed _from, address indexed _to, string _type, string _message);

    function sendMessage(address to, string memory messageType, string memory message) public {
        emit Message(msg.sender, to, messageType, message);
    }
}