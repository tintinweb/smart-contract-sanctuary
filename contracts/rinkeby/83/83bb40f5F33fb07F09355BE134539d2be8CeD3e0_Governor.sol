//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface TokenInterface {
    function getVotes(address _account, uint _timestamp) external returns (uint);
    function blacklist(address _account) external;
}

contract Governor {
    string public name;
    address public chairperson;
    uint public quorum; // Minimun number of votes in support of a proposal required for a vote to succeed
    uint public minTotalVotes; // Minimun number of total votes for a proposal required for a vote to succeed;
    uint public votingDelay; // The delay before voting on a proposal may take place, once proposed
    uint public votingPeriod; // The duration of voting on a proposal, in blocks
    uint public proposalCount; // Total number of proposals
    TokenInterface public token; // Interface of ERC20 token


    struct Proposal {
        uint id; // Unique id for looking up a proposal
        address proposer; // Creator of the proposal
        address[] targets; // Ordered list of target addresses for calls to be made
        string description;
        uint voteStart; // Time at which voting begins
        uint voteEnd; // Time at which voting ends
        uint forVotes; // Current number of votes in favor of this proposal
        uint againstVotes; // Current number of votes in opposition to this proposal
        bool canceled; // Flag marking whether the proposal has been canceled
        bool executed; // Flag marking whether the proposal has been executed
        mapping (address => Receipt) receipts; // Receipts of ballots for the entire set of voters
    }

    // Ballot receipt record for a voter
    struct Receipt {
        bool hasVoted; // Whether or not a vote has been cast
        bool support; // Whether or not the voter supports the proposal
        uint votes; // The number of votes the voter had, which were cast
    }

    // Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Executed
    }

    mapping (uint => Proposal) public proposals; // The official record of all proposals ever proposed

    // An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, string description, uint voteStart, uint voteEnd);

    // An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    // An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    // An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(
        string memory _name,
        address _chairperson,
        uint _quorum,
        uint _minTotalVotes,
        uint _votingDelay,
        uint _votingPeriod,
        address _token) {
        name = _name;
        chairperson = _chairperson;
        quorum = _quorum;
        minTotalVotes = _minTotalVotes;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        token = TokenInterface(_token);
    }
    
    modifier onlyChairperson () {
        require(msg.sender == chairperson, 'Governor: access restricted to chairperson only');
        _;
    }

    function proposeBlacklist(address[] memory targets) public {
        _propose(targets, 'Blacklist these addresses');
    }

    function _propose(
        address[] memory targets, 
        string memory description) internal returns (uint) {
        require(targets.length != 0, "Governor::propose: must provide actions");

        uint voteStart = block.timestamp + votingDelay;
        uint voteEnd = voteStart + votingPeriod;

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.targets = targets;
        proposal.description = description;
        proposal.voteStart = voteStart;
        proposal.voteEnd = voteEnd;

        emit ProposalCreated(proposal.id, proposal.proposer, targets, description, voteStart, voteEnd);
        return proposal.id;
    }

    function executeBlacklist(uint proposalId) public payable onlyChairperson {
        require(state(proposalId) == ProposalState.Succeeded, "Governor::execute: proposal has not been passed");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        _execute(proposal.targets);
        emit ProposalExecuted(proposalId);
    }
    
    function _execute (address[] memory _targets) internal {
            for (uint i = 0; i < _targets.length; i++) {
                token.blacklist(_targets[i]);
            }
    }

    function cancel(uint proposalId) public onlyChairperson {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "Governor::cancel: cannot cancel executed proposal");
        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        (uint forVotes, uint againstVotes) = (proposal.forVotes, proposal.againstVotes);
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.voteStart) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.voteEnd) {
            return ProposalState.Active;
        } else if (forVotes <= againstVotes || forVotes < quorum || forVotes + againstVotes < minTotalVotes) {
            return ProposalState.Defeated;
        } else if (forVotes > againstVotes && forVotes >= quorum && forVotes + againstVotes >= minTotalVotes) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } 
    }

    function voteBlacklist(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint votes = token.getVotes(voter, proposal.voteStart);
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }
    
    function proposalVotes(uint proposalId) public view returns (uint, uint) {
        Proposal storage proposal = proposals[proposalId];
        return (proposal.againstVotes, proposal.forVotes);
    }
    
    function setMinVotes(uint _minTotalVotes) public onlyChairperson {
        minTotalVotes = _minTotalVotes;
    }
    
    function setQuorum(uint _quorum) public onlyChairperson {
        quorum = _quorum;
    }
    
    function setDelay(uint _votingDelay) public onlyChairperson {
        votingDelay = _votingDelay;
    }
    
    function setPeriod(uint _votingPeriod) public onlyChairperson {
        votingPeriod = _votingPeriod;
    }
    
    function setChairperson(address _chairperson) public onlyChairperson {
        chairperson = _chairperson;
    }

}