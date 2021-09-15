/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

pragma solidity ^0.4.0;
contract TestContract {

    struct Proposal {
        uint voteCount;
        string description;
    }

    address public owner;
    Proposal[] public proposals;

    constructor ()  public {
        owner = msg.sender;
    }

    function createProposal(string description) public {
        Proposal memory p;
        p.description = description;
        proposals.push(p);
    }

    function vote(uint proposal) public {
        proposals[proposal].voteCount += 1;
    }
}