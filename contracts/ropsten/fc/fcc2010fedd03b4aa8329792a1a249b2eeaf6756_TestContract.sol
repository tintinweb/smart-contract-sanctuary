pragma solidity ^0.5.2;
contract TestContract {

    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;

    constructor () public {
        owner = msg.sender;
    }

    function createProposal(string memory description) public {
        Proposal memory p;
        p.description = description;
        proposals.push(p);
    }

    function vote(uint proposal) public {
        uint maxVote = 5;
        uint currentVote = proposals[proposal].voteCount;
        if (currentVote < maxVote){
            proposals[proposal].voteCount += 1;
        }
            
        }
}