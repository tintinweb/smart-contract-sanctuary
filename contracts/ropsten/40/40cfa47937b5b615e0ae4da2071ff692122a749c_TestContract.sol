pragma solidity ^0.4.24;
contract TestContract {

    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;
    uint constant maxVote = 2;

    constructor() public{
        owner = msg.sender;
    }

    function createProposal(string description) public{
        Proposal memory p;
        p.description = description;
        proposals.push(p);
    }

    function vote(uint proposal) public {
        if (proposals[proposal].voteCount < maxVote)
        proposals[proposal].voteCount += 1;
    }
}