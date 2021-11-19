/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.7;

contract Messenger {
    event Message(string indexed message);
    
    string public lastMessage;
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) public {
        require(msg.sender == owner, "Messenger: not owner");
        
        owner = newOwner;
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "Messenger: not owner");
        lastMessage = message;
        emit Message(message);
    }
}