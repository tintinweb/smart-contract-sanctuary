// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 
  ____  _       _ _     _           
 |  _ \(_) __ _(_) |__ | | ___  ___ 
 | | | | |/ _` | | '_ \| |/ _ \/ __|
 | |_| | | (_| | | |_) | |  __/\__ \
 |____/|_|\__, |_|_.__/|_|\___||___/
          |___/                     

 * Digibles DAO contract:
 * 1. Collects funds & allocates shares
 * 2. Keeps track of contributions with shares
 * 3. Allow the transfer of shares
 * 4. Allow proposals to be created, and voted on
 * 5. Allows executution of successful proposals
 */

contract DAO {

  struct Proposal {
    uint id;
    string name;
    string details;
    uint amount;
    address payable recipient;
    uint votes;
    uint votesFor;
    uint votesAgainst;
    uint end;
    bool executed;
  }

  mapping(address => bool) public investors;
  mapping(address => uint) public shares;
  mapping(address => mapping(uint => bool)) public votes;
  mapping(uint => Proposal) public proposals;
  uint public totalShares;
  uint public availableFunds;
  uint public contributionEnd;
  uint public nextProposalId;
  uint public voteTime;
  uint public quorum;
  address public admin;

  constructor() {
    // defaults
    admin = msg.sender;
    contributionEnd = block.timestamp + 86400;
    voteTime = 86400;
    quorum = 1;
  }

  function setup(
    uint _contributionTime, 
    uint _voteTime,
    uint _quorum) external onlyAdmin() {
    require(_quorum > 0 && _quorum < 100, 'quorum must be between 0 and 100');
    contributionEnd = block.timestamp + _contributionTime;
    voteTime = _voteTime;
    quorum = _quorum;
  }
  
  function contribute() payable external {
    require(block.timestamp < contributionEnd, 'cannot contribute after contributionEnd');
    investors[msg.sender] = true;
    shares[msg.sender] += msg.value;
    totalShares += msg.value;
    availableFunds += msg.value;
  }

  function redeemShare(uint amount) external {
    require(shares[msg.sender] >= amount, 'not enough shares');
    require(availableFunds >= amount, 'not enough available funds');
    shares[msg.sender] -= amount;
    availableFunds -= amount;
    payable(msg.sender).transfer(amount);
  }
    
  function transferShare(uint amount, address to) external {
    require(shares[msg.sender] >= amount, 'not enough shares');
    shares[msg.sender] -= amount;
    shares[to] += amount;
    investors[to] = true;
  }

  function createProposal(
    string memory name,
    string memory details,
    uint amount,
    address payable recipient) 
    public 
    onlyInvestors() {
    require(availableFunds >= amount, 'amount too big');
    proposals[nextProposalId] = Proposal(
      nextProposalId,
      name,
      details,
      amount,
      recipient,
      0,
      0,
      0,
      block.timestamp + voteTime,
      false
    );
    availableFunds -= amount;
    nextProposalId++;
  }

  function vote(uint proposalId, uint state) external onlyInvestors() {
    Proposal storage proposal = proposals[proposalId];
    require(votes[msg.sender][proposalId] == false, 'investor can only vote once for a proposal');
    require(block.timestamp < proposal.end, 'can only vote prior to proposal end date');
    votes[msg.sender][proposalId] = true;
    if (state == 0) {
        proposal.votesAgainst += shares[msg.sender];
    } else if (state == 1) {
        proposal.votesFor += shares[msg.sender];
    }
    proposal.votes += shares[msg.sender];
    uint256 s = shares[msg.sender];
    shares[msg.sender] -= s;
  }

  function executeProposal(uint proposalId) external onlyAdmin() {
    Proposal storage proposal = proposals[proposalId];
    require(block.timestamp >= proposal.end, 'cannot execute proposal before end date');
    require(proposal.executed == false, 'cannot execute proposal already executed');
    require((proposal.votes / totalShares) * 100 >= quorum, 'cannot execute proposal with votes # below quorum');
    _transferEther(proposal.amount, proposal.recipient);
  }

  function withdraw(uint amount, address payable to) external onlyAdmin() {
    _transferEther(amount, to);
  }
  
  function _transferEther(uint amount, address payable to) internal {
    require(amount <= availableFunds, 'not enough availableFunds');
    availableFunds -= amount;
    to.transfer(amount);
  }

  receive() external payable {
    availableFunds += msg.value;
  }

  modifier onlyInvestors() {
    require(investors[msg.sender] == true, 'only investors');
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin');
    _;
  }
}