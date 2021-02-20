/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Governance {

  // The duration of voting on a proposal
  uint public constant votingPeriod = 86000;

  // Time since submission before the proposal can be executed
  uint public constant executionPeriod = 86000 * 2;

  // The required minimum number of votes in support of a proposal for it to succeed
  uint public constant quorumVotes = 5000e18;

  // The minimum number of votes required for an account to create a proposal
  uint public constant proposalThreshold = 100e18;

  IERC20 public votingToken;

  // The total number of proposals
  uint public proposalCount;

  // The record of all proposals ever proposed
  mapping (uint => Proposal) public proposals;

  // receipts[ProposalId][voter]
  mapping (uint => mapping (address => Receipt)) public receipts;

  // The time until which tokens used for voting will be locked
  mapping (address => uint) public voteLock;

  // Keeps track of locked tokens per address
  mapping(address => uint) public balanceOf;

  struct Proposal {
    // Unique id for looking up a proposal
    uint id;

    // Creator of the proposal
    address proposer;

    // The time at which voting starts
    uint startTime;

    // Current number of votes in favor of this proposal
    uint forVotes;

    // Current number of votes in opposition to this proposal
    uint againstVotes;

    // Queued transaction hash
    bytes32 txHash;

    bool executed;
  }

  // Ballot receipt record for a voter
  struct Receipt {
    // Whether or not a vote has been cast
    bool hasVoted;

    // Whether or not the voter supports the proposal
    bool support;

    // The number of votes the voter had, which were cast
    uint votes;
  }

  // Possible states that a proposal may be in
  enum ProposalState {
    Active,            // 0
    Defeated,          // 1
    PendingExecution,  // 2
    ReadyForExecution, // 3
    Executed           // 4
  }

  // If the votingPeriod is changed and the user votes again, the lock period will be reset.
  modifier lockVotes() {
    uint tokenBalance = votingToken.balanceOf(msg.sender);
    votingToken.transferFrom(msg.sender, address(this), tokenBalance);
    _mint(msg.sender, tokenBalance);
    voteLock[msg.sender] = block.timestamp + votingPeriod;
    _;
  }

  constructor(IERC20 _votingToken) {
      votingToken = _votingToken;
  }

  function state(uint proposalId) public view returns (ProposalState) {
    require(proposalCount >= proposalId && proposalId > 0, "Governance::state: invalid proposal id");
    Proposal storage proposal = proposals[proposalId];

    if (block.timestamp <= proposal.startTime + votingPeriod) {
      return ProposalState.Active;

    } else if (proposal.executed == true) {
      return ProposalState.Executed;

    } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
      return ProposalState.Defeated;

    } else if (block.timestamp < proposal.startTime + executionPeriod) {
      return ProposalState.PendingExecution;

    } else {
      return ProposalState.ReadyForExecution;
    }
  }

  function execute(uint _proposalId, address _target, bytes memory _data)
    public
    payable
    returns (bytes memory)
  {
    bytes32 txHash = keccak256(abi.encode(_target, _data));
    Proposal storage proposal = proposals[_proposalId];
    require(proposal.txHash == txHash, "Governance::execute: Invalid proposal");
    require(state(_proposalId) == ProposalState.ReadyForExecution, "Governance::execute: Cannot be executed");

    (bool success, bytes memory returnData) = _target.delegatecall(_data);
    require(success, "Governance::execute: Transaction execution reverted.");
    proposal.executed = true;

    return returnData;
  }

  function propose(address _target, bytes memory _data) public lockVotes returns (uint) {

    require(balanceOf[msg.sender] >= proposalThreshold, "Governance::propose: proposer votes below proposal threshold");

    bytes32 txHash = keccak256(abi.encode(_target, _data));

    proposalCount++;
    Proposal memory newProposal = Proposal({
      id:           proposalCount,
      proposer:     msg.sender,
      startTime:    block.timestamp,
      forVotes:     0,
      againstVotes: 0,
      txHash:       txHash,
      executed:     false
    });

    proposals[newProposal.id] = newProposal;

    return proposalCount;
  }

  function vote(uint _proposalId, bool _support) public lockVotes {

    require(state(_proposalId) == ProposalState.Active, "Governance::vote: voting is closed");
    Proposal storage proposal = proposals[_proposalId];
    Receipt storage receipt = receipts[_proposalId][msg.sender];
    require(receipt.hasVoted == false, "Governance::vote: voter already voted");

    uint votes = balanceOf[msg.sender];

    if (_support) {
      proposal.forVotes += votes;
    } else {
      proposal.againstVotes += votes;
    }

    receipt.hasVoted = true;
    receipt.support = _support;
    receipt.votes = votes;
  }

  function withdraw() public {
    require(block.timestamp > voteLock[msg.sender], "Governance::withdraw: wait until voteLock expiration");
    votingToken.transfer(msg.sender, balanceOf[msg.sender]);
    _burn(msg.sender, balanceOf[msg.sender]);
  }

  function _mint(address _account, uint _amount) internal {
    balanceOf[_account] += _amount;
  }

  function _burn(address _account, uint _amount) internal {
    balanceOf[_account] -= _amount;
  }
}