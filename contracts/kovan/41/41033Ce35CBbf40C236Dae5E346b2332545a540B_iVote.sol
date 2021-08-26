/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

contract iVote {

    address public inec;

    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }

    mapping(address => bool) public voted;

    mapping(uint => Candidate) public candidates;

    uint public candidatesCount;

    event VotedEvent (
        uint indexed _candidateId
    );

    constructor() public{
        inec = msg.sender;
    }


    function addCandidate(string memory _name) public {
        require(msg.sender == inec, "YOU'RE NOT THE ELECTORAL OFFICIAL!");
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    // function removeCandidate(uint _id) public {
    //     require(msg.sender == inec, "YOU'RE NOT THE ELECTORAL OFFICIAL!");
    //     candidatesCount --;
    //     candidates[_id] = Candidate(null, _id, 0);
    // }

    function vote(uint _candidateId) public {
        require(msg.sender != inec, "ELECTORAL OFFICIAL CANNOT VOTE");
        require(!voted[msg.sender], "VOTED ALREADY");
        require(_candidateId > 0 && _candidateId <= candidatesCount);
        voted[msg.sender] = true;
        candidates[_candidateId].voteCount ++;

        emit VotedEvent(_candidateId);
    }



}