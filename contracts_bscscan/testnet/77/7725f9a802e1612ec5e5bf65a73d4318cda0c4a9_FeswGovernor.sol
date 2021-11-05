/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// Root file: contracts\FeswGovernor.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

contract FeswGovernor {
    /// @notice The name of this contract
    string public constant name = "Feswap Governor";
    
    uint public constant QUORUM_VOTES               = 40_000_000e18;        // 4% of Fesw
    uint public constant PROPOSAL_THRESHOLD         = 10_000_000e18;        // 1% of Fesw
    uint public constant PROPOSAL_MAX_OPERATIONS    = 10;                   // 10 actions
    uint public constant VOTING_PERIOD              = 7 days;               // 7 days

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint public quorumVotes;

    /// @notice The number of votes required in order for a voter to become a proposer
    uint public proposalThreshold;

    /// @notice The maximum number of actions that can be included in a proposal
    uint public proposalMaxOperations;

    /// @notice The duration of voting on a proposal, in blocks
    uint public votingPeriod;

    /// @notice The address of the Feswap Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the Feswap governance token
    FeswaInterface public Feswa;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        // Unique id for looking up a proposal
        uint id;

        // Creator of the proposal
        address proposer;

        // the ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;        
        uint startBlockTime;

        // The block at which voting ends: votes must be cast prior to this block
        uint endBlockTime;

        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        // Current number of votes in favor of this proposal
        uint forVotes;

        // Current number of votes in opposition to this proposal
        uint againstVotes;

        // Flag marking whether the proposal has been canceled
        bool canceled;

        // Flag marking whether the proposal has been executed
        bool executed;
    }
    
    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;

        // Whether or not the voter supports the proposal
        bool support;

        // The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice Receipts of ballots for the entire set of voters
    mapping (uint => mapping (address => Receipt)) public receipts;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, 
                          uint startBlockTime, uint endBlockTime, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(address timelock_, address Feswa_) {
        timelock                = TimelockInterface(timelock_);
        Feswa                   = FeswaInterface(Feswa_);
        quorumVotes             = QUORUM_VOTES;
        proposalThreshold       = PROPOSAL_THRESHOLD;
        proposalMaxOperations   = PROPOSAL_MAX_OPERATIONS;
        votingPeriod            = VOTING_PERIOD;
    }

    function config(uint quorumVotes_, uint proposalThreshold_, uint proposalMaxOperations_, uint votingPeriod_) public {
        require(msg.sender == address(timelock), "FeswGovernor:: Not Timelock");
        if (quorumVotes != 0)           quorumVotes = quorumVotes_;
        if (proposalThreshold != 0)     proposalThreshold = proposalThreshold_;
        if (proposalMaxOperations != 0) proposalMaxOperations = proposalMaxOperations_;
        if (votingPeriod != 0)          votingPeriod = votingPeriod_;
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(Feswa.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold, "FeswGovernor::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "FeswGovernor::propose: proposal function information arity mismatch");
        require(targets.length != 0, "FeswGovernor::propose: must provide actions");
        require(targets.length <= proposalMaxOperations, "FeswGovernor::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "FeswGovernor::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "FeswGovernor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlockTime = block.timestamp;
        uint endBlockTime = add256(startBlockTime, votingPeriod);

        proposalCount++;
        Proposal memory newProposal;
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = block.number;
        newProposal.startBlockTime = startBlockTime;
        newProposal.endBlockTime = endBlockTime;
        
        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlockTime, endBlockTime, description);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "FeswGovernor::queue: proposal can only be queued if it is succeeded");

        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), 
                    "FeswGovernor::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "FeswGovernor::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value:proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        require(state(proposalId) != ProposalState.Executed, "FeswGovernor::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        require(Feswa.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold, "FeswGovernor::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return receipts[proposalId][voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "FeswGovernor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startBlockTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endBlockTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "FeswGovernor::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "FeswGovernor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[proposalId][voter];
        require(receipt.hasVoted == false, "FeswGovernor::_castVote: voter already voted");
        uint96 votes = Feswa.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface FeswaInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}