pragma solidity ^0.4.0;
contract TestContract {

    struct Proposal {
        uint voteCount;
        uint id;
        string description;
    }

    address public owner;
    mapping (uint => Proposal) public proposals;

    constructor() public {
        owner = msg.sender;
    }

    function createProposal(uint id, string description) public {
        require(msg.sender == owner); // check that proposal creator is owner of contract
        
        Proposal memory proposal;
        proposal.id = id;
        proposal.description = description;
        proposals[id] = proposal; // creator can overwrite an old proposal with the same id
    }

    function vote(uint proposal) public {
        proposals[proposal].voteCount += 1;
    }
}