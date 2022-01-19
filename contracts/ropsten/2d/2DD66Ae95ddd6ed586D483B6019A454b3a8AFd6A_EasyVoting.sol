/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract EasyVoting {
    // Declare vote parameter
    mapping (string => uint256) public votes;
    // Declare owner
    string [] public title;
    address public owner;
    constructor(){
        owner = msg.sender;
    }

    // Create title function
    function createTitle(string memory _title) public {
        require(owner == msg.sender, "Only owner can create title.");
        title.push(_title);
        votes[_title] = 0;
    }

    // Vote
    function vote(string memory _title) public {
        votes[_title] += 1;
    }

    function checkLength()public view returns(uint){
        return title.length;
    }
    
}