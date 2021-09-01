/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

/*
SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

contract Note1 {
    string public publicNote;
    string public secretNote;
    string public permNote;
    address public owner;
    
    constructor(string memory _publicNote, string memory _secretNote, string memory _permNote) {
        owner = msg.sender;
        publicNote = _publicNote;
        secretNote = _secretNote;
        permNote = _permNote;
    }
    
    function changePublicNote(string memory _newPNote) public {
        publicNote = _newPNote;
    }
    
    function changeSecret(string memory _newSecret) public {
        require(msg.sender == owner, 'only owner can change secret');
        secretNote = _newSecret;
    }
}