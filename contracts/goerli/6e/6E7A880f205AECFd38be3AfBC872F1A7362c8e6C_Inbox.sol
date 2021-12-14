/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

/// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.9;
 
contract Inbox {
    string public message;
    
    constructor(string memory initialMessage) {
        message = initialMessage;
    }
    
    function setMessage(string memory newMessage) public {
        message = newMessage;
    }


    event eventadd(address indexed _from, uint256 a, uint256 b, uint256 c);
    function add(uint256 a, uint256 b)public returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        emit eventadd(msg.sender,a,b,c);
        return c;

      }
}