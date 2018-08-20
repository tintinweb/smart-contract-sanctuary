pragma solidity ^0.4.0;
contract LiquidBallot {
    
    uint proposalCount;

    struct Proposal {
        uint id;
        string title;
        string uri;
        address proposer;
        uint proposalDate;
        uint expiryDate;
    }

    Proposal[] public proposals;

    constructor () public {
        proposalCount = 0;
    }
    
    function makeProposal(string title, string uri, uint duration) public {
        proposals.push(Proposal(
            proposalCount,
            title,
            uri,
            msg.sender,
            now,
            now + duration
        ));
    }

    function castVote(uint proposalId, bool value) public {
        //Stateless
    }
    
    function delegateVote(int256 proposalId, address delegatee) public {
        //Stateless
    }

}