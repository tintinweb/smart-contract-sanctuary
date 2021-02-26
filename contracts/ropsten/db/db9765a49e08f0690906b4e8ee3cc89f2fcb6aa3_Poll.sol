/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Poll
 * @dev Create a list which holds votes, and let users vote on one entry. Users can vote once.
 */
contract Poll {
   
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted option
    }

    address public chairperson;

    mapping(address => Voter) public voters;

    uint[] public options;

    constructor() {
        chairperson = msg.sender;
    }
    
    function pushNewOption() public {
        require(msg.sender == chairperson);
        options.push(0);
    }
    
    function getNumberofOptions() public view returns (uint numberofOptions_) {
        numberofOptions_ = options.length;
    }
    
    function vote(uint option) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = option;

        // If 'option' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        options[option] += 1;
    }

    function winningOption() public view
            returns (uint winningOption_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < options.length; p++) {
            if (options[p] > winningVoteCount) {
                winningVoteCount = options[p];
                winningOption_ = p;
            }
        }
    }

}