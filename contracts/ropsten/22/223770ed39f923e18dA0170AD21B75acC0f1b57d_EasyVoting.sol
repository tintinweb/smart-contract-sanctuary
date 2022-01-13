/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract EasyVoting {
    // Declare vote parameter
    mapping (string => uint256) public votes;

    // Declare owner
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    // Create title function
    function createTitle(string memory _title) public {
        require(owner == msg.sender, "Only owner can create title.");
        votes[_title] = 0;
    }

    // Vote
    function vote(string memory _title) public {
        votes[_title] += 1;
    }
    
}