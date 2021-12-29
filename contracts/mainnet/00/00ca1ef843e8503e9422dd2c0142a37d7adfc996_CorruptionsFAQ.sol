/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: Unlicense

/*
    This is a space for break the fourth wall and explain the project
    more plainly. No puzzles or anything here. :) If subgraphed and
    mirrored to a website it should serve as a decent FAQ/explainer.
*/

pragma solidity^0.8.1;

contract CorruptionsFAQ {
    event Record(string indexed topic, string indexed content);
    event Revoke(string indexed topic);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function record(string memory topic, string memory content) public {
        // in the event of "re-recording", this is basically an edit or update
        require(msg.sender == owner, "CorruptionsFAQ: not owner");
        emit Record(topic, content);
    }

    function revoke(string memory topic) public {
        // revoking is basically deleting
        require(msg.sender == owner, "CorruptionsFAQ: not owner");
        emit Revoke(topic);
    }
}