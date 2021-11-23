/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface INova {

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function mint(address account, uint96 amount) external ;
    function burn(address account, uint96 amount) external ;

    function getPriorVotes(address account, uint blockNumber) external view returns (uint96);
}


contract Governor {
    /// @notice The name of this contract
    string public constant name = "Nova Governor";

    bytes32 public immutable domainSeparator;

    /// @dev The maximum number of actions that can be included in a proposal
    uint constant MAX_ACTIONS = 10;
    
    uint constant VOTE_PERIOD = 7 days;  //  7 days

     /// @dev The delay before voting on a proposal may take place, once proposed
    uint constant VOTING_DELAY = 1;

    /// @dev The number of votes required in order for a voter to become a proposer
    uint constant PROPOSAL_THRESHOLD = 1;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { 
      return nova.totalSupply() / 2;
    } 

    /// @notice The address of the Nova governance token
    INova public nova;

    /// @notice The total number of proposals
    uint public proposalCount;

    struct Proposal {
        uint id;

        address proposer;

        // The timestamp that the proposal  execution
        uint eta;

        // the ordered list of target addresses for calls to be made
        address[] targets;

        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        // The ordered list of function signatures to be called
        string[] signatures;

        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        //  The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        //  The TimeStamp at which voting ends: votes must be cast prior to this timestap
        uint endTs;

        // Current number of votes in favor of this proposal
        uint forVotes;

        //   Current number of votes in opposition to this proposal
        uint againstVotes;

        uint members;

        //  Flag marking whether the proposal has been executed
        bool executed;

        string desc;

        //  Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    //  Ballot receipt record for a voter
    struct Receipt {
        //  Whether or not a vote has been cast
        bool hasVoted;

        bool support;

        uint96 votes;
    }

    //  Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Succeeded,
        Expired,
        Executed
    }

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endTs, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been executed
    event ProposalExecuted(uint id, uint eta);

    constructor(address _nova) public {
        nova = INova(_nova);
        domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));
    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        require(nova.getPriorVotes(msg.sender, block.number - 1) >= PROPOSAL_THRESHOLD, "Governor::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "Governor::propose: proposal function information arity mismatch");
        require(targets.length != 0, "Governor::propose: must provide actions");
        require(targets.length <= MAX_ACTIONS, "Governor::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "Governor::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "Governor::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = block.number + VOTING_DELAY ;
        uint endTs = block.timestamp + VOTE_PERIOD;

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endTs = endTs;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.members = nova.totalSupply();
        newProposal.executed = false;
        newProposal.desc = description;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endTs, description);
        return newProposal.id;
    }

    function execute(uint proposalId) public payable {
        require(state(proposalId) == ProposalState.Succeeded, "Governor::execute: only Succeeded proposal can be executed ");
        Proposal storage proposal = proposals[proposalId];
        proposal.eta = block.timestamp;
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            _executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i]);
        }
        emit ProposalExecuted(proposalId, block.timestamp);
    }

    function _executeTransaction(address target, uint value, string memory signature, bytes memory data) internal returns (bytes memory) {
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "_executeTransaction: Transaction execution reverted.");
        return returnData;
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Governor::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTs) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < ( proposal.members / 2)) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else {  // if (block.number > proposal.endBlock) 
            return ProposalState.Expired;
        } 
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Governor::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "Governor::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "Governor::_castVote: voter already voted");
        uint96 votes = nova.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes =  proposal.forVotes + votes;
        } else {
            proposal.againstVotes = proposal.againstVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

}