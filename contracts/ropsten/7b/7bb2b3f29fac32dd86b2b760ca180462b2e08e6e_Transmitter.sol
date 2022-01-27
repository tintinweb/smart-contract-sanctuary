/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

pragma solidity ^0.8.7;

contract Transmitter {
    event TransmitMessage(address _from, string _message);
    event Received(address _from, uint256 _value);

    function sendMessage(string memory message) public payable {
        require(msg.value >= 10000000000000000, "[ERROR]: Missing required amount for transmission...");
        emit TransmitMessage(msg.sender, message);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external {}
}