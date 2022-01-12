/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Email{

    //every email will have specific ID
    uint256 public messageId = 0;
    // mapping to for recievers to register
    mapping (address => bytes) public recievers;

    event Msg_Recieved(address to, address from, bytes data, uint256 id);

    // it will register a user who is calling this method
    function register(bytes calldata publickey) public {
        recievers[msg.sender] = publickey;
    }

    function sendMessage(address to, bytes calldata data) public {
        messageId = messageId + 1;
        emit Msg_Recieved(to, msg.sender, data, messageId-1);
    }
}